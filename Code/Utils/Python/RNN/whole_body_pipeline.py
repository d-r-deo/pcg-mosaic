"""Shared utilities for the whole-body RNN movement decoder.

This is the public-release adaptation of the pipeline used to make Figure 3 of
*A mosaic of whole-body representations on the human precentral gyrus*. The
implementation follows Willett et al. (2023, *Nature*) — see
https://github.com/cffan/neural_seq_decoder — adapted from CTC sequence
decoding to single-trial movement classification.

The functions here cover three steps:

1. ``format_all_folds`` builds the five cross-validation pickle files that the
   training notebook (`02_train_rnns.ipynb`) consumes.
2. ``collect_seed_predictions`` and ``movement_set_accuracy`` /
   ``condition_accuracy`` load the trained models and produce held-out
   predictions for evaluation.
3. ``evaluate_seeds`` and ``save_evaluation_outputs`` wrap the per-seed
   accuracy calculation into the .mat / .pkl / .csv artefacts that the figures
   in the manuscript are built from.

Differences from the internal NPTL pipeline this is derived from:

- Data is loaded from the published participant `.mat` files, which nest all
  fields under a ``DataMat`` struct and ship as either v7 (scipy.io.loadmat)
  or v7.3 (mat73) — :func:`load_participant` handles both transparently.
- ``goCue`` is converted from 1-indexed MATLAB time to 0-indexed Python time at
  load.
- ``trialCue`` stays 1-indexed at load time; the formatting code converts it to
  the 0-indexed decoder label (``raw_cue - 1``).
- Each participant file now contains both multi-unit threshold-crossing arrays
  (e.g. ``T5-d1``) and sorted-unit arrays (e.g. ``T5-d1Sorted``). The
  ``*Sorted`` arrays are excluded automatically because they are not part of
  the published ``ARRAY_ORDER`` set.
- ``BAD_ARRAYS`` is kept for documentation only; arrays not in
  ``ARRAY_ORDER`` (including the bad arrays) are skipped at the
  membership-check step in :func:`format_all_folds`.
"""

from __future__ import annotations

import csv
import pickle
from pathlib import Path

import numpy as np
import scipy.io


# ---------------------------------------------------------------------------
# Default paths — relative to this file so the public release works out of the
# box. ``RAW_DATA_DIR`` walks up to the project root and into ``Data/``;
# ``OUTPUT_DIR`` writes back under the RNN folder itself.
# ---------------------------------------------------------------------------
RNN_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = RNN_DIR.parents[3]                   # Code/Utils/Python/RNN → project root
RAW_DATA_DIR = PROJECT_ROOT / "Data"
OUTPUT_DIR = RNN_DIR / "outputs"


# ---------------------------------------------------------------------------
# Dataset definitions
# ---------------------------------------------------------------------------
PARTICIPANTS = ["C1", "C2", "T11", "T12", "T15", "T16", "T17", "T5"]

# Bad arrays are listed for reference, but no longer used as a filter directly.
# Arrays are accepted into the analysis only if they appear in ARRAY_ORDER,
# which excludes both bad arrays and any *Sorted (per-unit) arrays.
BAD_ARRAYS = ["T17-m1", "T17-m2", "T11-d2", "C2-d1"]

# Cue IDs 47 (EYES Up for T16, HUM Hi for T17) and 48 (EYES Down / HUM Low)
# are participant-specific extras not part of the standard 46-condition set.
EXCLUDED_RAW_CUES = {47, 48}

WINDOW_BINS = 200
BIN_WIDTH_SECONDS = 0.02
N_FOLDS = 5
N_INPUT_FEATURES = 96
RANDOM_SEED = 0

MOVEMENT_SET_LABELS = [
    "all",
    "speech",
    "face",
    "head",
    "right arm",
    "right leg",
    "left arm",
    "left leg",
]

# These are decoder class indices (raw trialCue - 1).
MOVEMENT_SETS = [
    np.arange(1, 46, dtype=np.int32),
    np.array([41, 42, 43, 44], dtype=np.int32),
    np.array([1, 22, 23, 24, 45], dtype=np.int32),
    np.array([2, 3, 4, 5], dtype=np.int32),
    np.array([29, 30, 31, 32, 37, 38, 39, 40], dtype=np.int32),
    np.array([25, 26, 27, 28, 33, 34, 35, 36], dtype=np.int32),
    np.array([10, 11, 12, 13, 18, 19, 20, 21], dtype=np.int32),
    np.array([6, 7, 8, 9, 14, 15, 16, 17], dtype=np.int32),
]

# Canonical 20-array spatial order used in Figure 3a and downstream evaluation.
ARRAY_ORDER = [
    "C2-d2",
    "C1-d1",
    "C1-d2",
    "T17-d1",
    "T5-d1",
    "T5-d2",
    "T17-d2",
    "T16-d1",
    "T16-d2",
    "T11-d1",
    "T15-m1",
    "T16-m1",
    "T15-v1",
    "T12-v1",
    "T15-v2",
    "T17-v1",
    "T12-v2",
    "T15-v3",
    "T17-v2",
    "T16-v1",
]


# ---------------------------------------------------------------------------
# Data-format helpers
# ---------------------------------------------------------------------------
def matlab_string(value) -> str:
    """Coerce a 1×1 char/object cell from MATLAB into a Python string."""
    arr = np.asarray(value)
    while isinstance(arr, np.ndarray) and arr.size == 1:
        arr = arr.item()
    if isinstance(arr, bytes):
        return arr.decode("utf-8")
    return str(arr)


def _normalize_cell_array(value) -> np.ndarray:
    """Return a (1, n) object ndarray regardless of source loader format.

    scipy.io.loadmat gives back a (1, n) ndarray of dtype=object already.
    mat73 returns a Python list. We coerce to the same (1, n) layout so the
    rest of the pipeline can use ``arr[0, idx]`` uniformly.
    """
    if isinstance(value, np.ndarray) and value.dtype == object and value.ndim == 2 and value.shape[0] == 1:
        return value
    arr = list(value) if not isinstance(value, list) else value
    out = np.empty((1, len(arr)), dtype=object)
    for i, item in enumerate(arr):
        out[0, i] = item
    return out


def load_participant(participant: str, raw_data_dir: Path = RAW_DATA_DIR) -> dict:
    """Load a participant .mat file into a flat dict the pipeline understands.

    Handles both v7 (scipy.io.loadmat) and v7.3 (mat73) files. After this
    function returns:

    - ``goCue`` is 0-indexed Python time (subtract-1 applied at load).
    - ``trialCue`` is left as raw 1-indexed cue (EXCLUDED_RAW_CUES filtering
      and the ``raw_cue - 1`` label conversion in :func:`format_split` expect
      this convention).
    - ``chanSets`` / ``chanSetNames`` are normalised to (1, n_arrays)
      object ndarrays so callers can use ``arr[0, idx]`` regardless of loader.
    """
    path = Path(raw_data_dir) / f"{participant}.mat"
    try:
        raw = scipy.io.loadmat(path)
        dm = raw["DataMat"][0, 0]
        data = {name: dm[name] for name in dm.dtype.names}
    except NotImplementedError:
        import mat73
        raw = mat73.loadmat(path)
        data = dict(raw["DataMat"])

    data["goCue"] = (np.asarray(data["goCue"]).reshape(-1, 1) - 1).astype(np.int32)
    data["trialCue"] = np.asarray(data["trialCue"]).reshape(-1, 1).astype(np.int32)
    data["chanSets"] = _normalize_cell_array(data["chanSets"])
    data["chanSetNames"] = _normalize_cell_array(data["chanSetNames"])
    return data


# ---------------------------------------------------------------------------
# Fold construction
# ---------------------------------------------------------------------------
def build_test_folds(
    raw_data_dir: Path = RAW_DATA_DIR,
    participants: list[str] = PARTICIPANTS,
    n_folds: int = N_FOLDS,
    random_seed: int = RANDOM_SEED,
) -> list[list[np.ndarray]]:
    """Generate the same per-participant random fold splits used in the paper."""
    rng = np.random.default_rng(random_seed)
    all_test_folds = []

    for participant in participants:
        data = load_participant(participant, raw_data_dir)
        n_trials = data["goCue"].shape[0]
        shuffled = rng.permutation(n_trials).astype(np.int32)
        fold_size = int(np.floor(len(shuffled) / n_folds))

        fold_test = []
        for fold_idx in range(n_folds):
            start = fold_idx * fold_size
            if fold_idx == n_folds - 1:
                test_idx = shuffled[start:]
            else:
                test_idx = shuffled[start : start + fold_size]
            fold_test.append(test_idx.astype(np.int32))
        all_test_folds.append(fold_test)

    return all_test_folds


def format_trial_window(
    neural: np.ndarray,
    go_cue: int,
    window_bins: int = WINDOW_BINS,
) -> np.ndarray:
    loop_idx = np.arange(go_cue, go_cue + window_bins).astype(np.int32)
    return neural[loop_idx, :]


def prepare_neural_features(
    data: dict,
    array_idx: int,
    n_input_features: int = N_INPUT_FEATURES,
    trailing_pad_bins: int = 400,
) -> np.ndarray:
    """Pull one array's block-mean-subtracted TX, zero-pad channels to 96."""
    channel_idx = (
        np.asarray(data["chanSets"][0, array_idx]).squeeze().astype(np.int64) - 1
    )
    neural = data["tx_blkMeanSub"][:, channel_idx]

    if neural.shape[1] < n_input_features:
        pad_width = n_input_features - neural.shape[1]
        neural = np.concatenate([neural, np.zeros((neural.shape[0], pad_width))], axis=1)
    elif neural.shape[1] > n_input_features:
        raise ValueError(
            f"Expected at most {n_input_features} features, got {neural.shape[1]}."
        )

    neural = np.concatenate([neural, np.zeros((trailing_pad_bins, n_input_features))], axis=0)
    neural[np.isnan(neural)] = 0
    return neural


def format_split(
    data: dict,
    neural: np.ndarray,
    trial_idx: np.ndarray,
    window_bins: int = WINDOW_BINS,
    excluded_raw_cues: set[int] = EXCLUDED_RAW_CUES,
) -> dict:
    labels = []
    windows = []
    label_lens = []

    for idx in trial_idx:
        raw_cue = int(data["trialCue"][idx, 0])
        if raw_cue in excluded_raw_cues:
            continue

        windows.append(format_trial_window(neural, int(data["goCue"][idx, 0]), window_bins))
        labels.append(np.array([raw_cue - 1], dtype=np.int32))
        label_lens.append(1)

    return {"sentenceDat": windows, "phonemes": labels, "phoneLens": label_lens}


def format_all_folds(
    output_dir: Path = OUTPUT_DIR / "formatted_data",
    raw_data_dir: Path = RAW_DATA_DIR,
    participants: list[str] = PARTICIPANTS,
    array_order: list[str] = ARRAY_ORDER,
    n_folds: int = N_FOLDS,
    random_seed: int = RANDOM_SEED,
    window_bins: int = WINDOW_BINS,
    n_input_features: int = N_INPUT_FEATURES,
) -> list[Path]:
    """Build the 5 cross-validation pickle files used by the training notebook.

    Arrays are accepted only if their name appears in ``array_order`` — this
    excludes both ``BAD_ARRAYS`` and the per-participant ``*Sorted`` arrays
    in one step.
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    all_test_folds = build_test_folds(raw_data_dir, participants, n_folds, random_seed)
    output_paths = []

    for fold_idx in range(n_folds):
        save_data = {
            "train": [],
            "test": [],
            "metadata": {
                "participants": participants,
                "array_order": array_order,
                "bad_arrays_excluded_by_membership": BAD_ARRAYS,
                "excluded_raw_cues": sorted(EXCLUDED_RAW_CUES),
                "window_bins": window_bins,
                "window_seconds": window_bins * BIN_WIDTH_SECONDS,
                "bin_width_seconds": BIN_WIDTH_SECONDS,
                "random_seed": random_seed,
                "n_folds": n_folds,
                "array_list": [],
            },
        }

        for participant_idx, participant in enumerate(participants):
            data = load_participant(participant, raw_data_dir)
            n_arrays = data["chanSets"].shape[1]
            n_trials = data["goCue"].shape[0]
            test_idx = all_test_folds[participant_idx][fold_idx]
            train_idx = np.setdiff1d(np.arange(n_trials, dtype=np.int32), test_idx)

            for array_idx in range(n_arrays):
                array_name = matlab_string(data["chanSetNames"][0, array_idx])
                if array_name not in array_order:
                    continue

                neural = prepare_neural_features(data, array_idx, n_input_features)
                save_data["metadata"]["array_list"].append(array_name)
                save_data["train"].append(format_split(data, neural, train_idx, window_bins))
                save_data["test"].append(format_split(data, neural, test_idx, window_bins))

        validate_formatted_data(save_data)
        output_path = output_dir / f"all_fold_{fold_idx}_4sec.pkl"
        with output_path.open("wb") as handle:
            pickle.dump(save_data, handle, protocol=pickle.HIGHEST_PROTOCOL)
        output_paths.append(output_path)

    return output_paths


def validate_formatted_data(save_data: dict) -> None:
    for split in ("train", "test"):
        for array_idx, array_data in enumerate(save_data[split]):
            if len(array_data["sentenceDat"]) == 0:
                raise ValueError(f"No trials for {split} array index {array_idx}.")
            neural = np.concatenate(array_data["sentenceDat"], axis=0)
            labels = np.concatenate(array_data["phonemes"], axis=0)
            if np.any(np.isnan(neural)):
                raise ValueError(f"NaNs found in {split} array index {array_idx}.")
            if np.min(labels) < 0 or np.max(labels) >= 46:
                raise ValueError(
                    f"Labels out of decoder range in {split} array index {array_idx}: "
                    f"{np.min(labels)} to {np.max(labels)}."
                )


# ---------------------------------------------------------------------------
# Evaluation
# ---------------------------------------------------------------------------
def load_array_list(dataset_path: Path) -> list[str]:
    with Path(dataset_path).open("rb") as handle:
        data = pickle.load(handle)
    metadata = data.get("metadata", {})
    if "array_list" in metadata:
        return list(metadata["array_list"])
    return [f"array_{idx}" for idx in range(len(data["test"]))]


def ordered_array_indices(array_list: list[str], array_order: list[str] = ARRAY_ORDER) -> np.ndarray:
    missing = [array_name for array_name in array_order if array_name not in array_list]
    if missing:
        raise ValueError(f"Array order contains arrays missing from formatted data: {missing}")
    return np.array([array_list.index(array_name) for array_name in array_order], dtype=np.int32)


def collect_seed_predictions(
    fold_dataset_paths: list[Path],
    training_dir: Path,
    seed: int,
    batch_size: int = 64,
    device: str = "cuda",
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    import torch

    from neural_decoder_trainer import getDatasetLoaders, loadModel

    all_scores = []
    all_labels = []
    all_arrays = []

    for fold_idx, dataset_path in enumerate(fold_dataset_paths):
        _, test_loader, loaded_data = getDatasetLoaders(str(dataset_path), batch_size)
        model_dir = Path(training_dir) / f"fold_{fold_idx}_4sec" / f"seed={seed}"
        if not (model_dir / "modelWeights").exists():
            raise FileNotFoundError(f"Missing model weights: {model_dir / 'modelWeights'}")
        model = loadModel(str(model_dir), nInputLayers=len(loaded_data["test"]), device=device)
        model.eval()

        with torch.no_grad():
            for neural, labels, _, _, array_idx in test_loader:
                neural = neural.to(device)
                array_idx = array_idx.to(device)
                pred = model.forward(neural, array_idx)
                scores = torch.mean(pred, dim=1)[:, 1:].cpu().numpy()

                all_scores.append(scores)
                all_labels.append(labels[:, 0].numpy())
                all_arrays.append(array_idx.cpu().numpy())

    return (
        np.concatenate(all_scores, axis=0),
        np.concatenate(all_labels, axis=0),
        np.concatenate(all_arrays, axis=0),
    )


def movement_set_accuracy(
    scores: np.ndarray,
    labels: np.ndarray,
    arrays: np.ndarray,
    n_arrays: int,
    movement_sets: list[np.ndarray] = MOVEMENT_SETS,
    mode: str = "subset",
) -> tuple[np.ndarray, np.ndarray]:
    accuracy = np.full((n_arrays, len(movement_sets)), np.nan)
    n_trials = np.zeros((n_arrays, len(movement_sets)), dtype=np.int32)
    full_prediction = np.argmax(scores, axis=1)

    for array_idx in range(n_arrays):
        for movement_idx, class_idx in enumerate(movement_sets):
            class_idx = np.asarray(class_idx, dtype=np.int32)
            mask = (arrays == array_idx) & np.isin(labels, class_idx)
            n_trials[array_idx, movement_idx] = int(np.sum(mask))
            if n_trials[array_idx, movement_idx] == 0:
                continue

            if mode == "full":
                prediction = full_prediction[mask]
            elif mode == "subset":
                subset_scores = scores[np.ix_(mask, class_idx)]
                prediction = class_idx[np.argmax(subset_scores, axis=1)]
            else:
                raise ValueError("mode must be 'subset' or 'full'.")

            accuracy[array_idx, movement_idx] = np.mean(prediction == labels[mask])

    return accuracy, n_trials


def condition_accuracy(
    scores: np.ndarray,
    labels: np.ndarray,
    arrays: np.ndarray,
    n_arrays: int,
    condition_labels: np.ndarray | None = None,
) -> tuple[np.ndarray, np.ndarray]:
    if condition_labels is None:
        condition_labels = np.arange(scores.shape[1], dtype=np.int32)

    prediction = np.argmax(scores, axis=1)
    accuracy = np.full((n_arrays, len(condition_labels)), np.nan)
    n_trials = np.zeros((n_arrays, len(condition_labels)), dtype=np.int32)

    for array_idx in range(n_arrays):
        for condition_idx, label in enumerate(condition_labels):
            mask = (arrays == array_idx) & (labels == label)
            n_trials[array_idx, condition_idx] = int(np.sum(mask))
            if n_trials[array_idx, condition_idx] > 0:
                accuracy[array_idx, condition_idx] = np.mean(prediction[mask] == label)

    return accuracy, n_trials


def evaluate_seeds(
    formatted_data_dir: Path = OUTPUT_DIR / "formatted_data",
    training_dir: Path = OUTPUT_DIR / "training",
    seeds: range = range(10),
    n_folds: int = N_FOLDS,
    batch_size: int = 64,
    device: str = "cuda",
    mode: str = "subset",
) -> dict:
    seeds = list(seeds)
    fold_dataset_paths = [
        Path(formatted_data_dir) / f"all_fold_{fold_idx}_4sec.pkl"
        for fold_idx in range(n_folds)
    ]
    array_list = load_array_list(fold_dataset_paths[0])
    n_arrays = len(array_list)

    seed_movement_accuracy = []
    seed_condition_accuracy = []
    seed_overall_accuracy = []
    seed_trial_counts = None
    condition_trial_counts = None

    for seed in seeds:
        scores, labels, arrays = collect_seed_predictions(
            fold_dataset_paths, training_dir, seed, batch_size, device
        )
        movement_acc, movement_trials = movement_set_accuracy(
            scores, labels, arrays, n_arrays, mode=mode
        )
        cond_acc, cond_trials = condition_accuracy(scores, labels, arrays, n_arrays)

        seed_movement_accuracy.append(movement_acc)
        seed_condition_accuracy.append(cond_acc)
        seed_overall_accuracy.append(np.mean(np.argmax(scores, axis=1) == labels))
        seed_trial_counts = movement_trials
        condition_trial_counts = cond_trials

    seed_movement_accuracy = np.stack(seed_movement_accuracy, axis=0)
    seed_condition_accuracy = np.stack(seed_condition_accuracy, axis=0)
    order_idx = ordered_array_indices(array_list)

    return {
        "array_list": array_list,
        "array_order": ARRAY_ORDER,
        "array_order_idx": order_idx,
        "movement_set_labels": MOVEMENT_SET_LABELS,
        "movement_sets": MOVEMENT_SETS,
        "mode": mode,
        "seeds": np.array(seeds, dtype=np.int32),
        "seed_movement_accuracy": seed_movement_accuracy,
        "movement_accuracy_mean": np.nanmean(seed_movement_accuracy, axis=0),
        "movement_accuracy_sem": np.nanstd(seed_movement_accuracy, axis=0, ddof=1)
        / np.sqrt(seed_movement_accuracy.shape[0]),
        "movement_trial_counts": seed_trial_counts,
        "condition_labels": np.arange(46, dtype=np.int32),
        "seed_condition_accuracy": seed_condition_accuracy,
        "condition_accuracy_mean": np.nanmean(seed_condition_accuracy, axis=0),
        "condition_accuracy_sem": np.nanstd(seed_condition_accuracy, axis=0, ddof=1)
        / np.sqrt(seed_condition_accuracy.shape[0]),
        "condition_trial_counts": condition_trial_counts,
        "seed_overall_accuracy": np.array(seed_overall_accuracy),
    }


def save_evaluation_outputs(results: dict, output_dir: Path) -> None:
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    ordered = results["array_order_idx"]
    mat_dict = {
        "arrayOrder": np.array(results["array_order"], dtype=object),
        "movementSetLabels": np.array(results["movement_set_labels"], dtype=object),
        "movementAccuracyMean": results["movement_accuracy_mean"][ordered, :],
        "movementAccuracySEM": results["movement_accuracy_sem"][ordered, :],
        "movementTrialCounts": results["movement_trial_counts"][ordered, :],
        "conditionLabels": results["condition_labels"],
        "conditionAccuracyMean": results["condition_accuracy_mean"][ordered, :],
        "conditionAccuracySEM": results["condition_accuracy_sem"][ordered, :],
        "conditionTrialCounts": results["condition_trial_counts"][ordered, :],
        "seedOverallAccuracy": results["seed_overall_accuracy"],
        "seeds": results["seeds"],
    }
    scipy.io.savemat(output_dir / f"rnn_classification_accuracy_{results['mode']}.mat", mat_dict)

    with (output_dir / "evaluation_results.pkl").open("wb") as handle:
        pickle.dump(results, handle, protocol=pickle.HIGHEST_PROTOCOL)

    write_matrix_csv(
        output_dir / f"movement_set_accuracy_mean_{results['mode']}.csv",
        results["movement_accuracy_mean"][ordered, :],
        results["array_order"],
        results["movement_set_labels"],
    )
    write_matrix_csv(
        output_dir / "condition_accuracy_mean.csv",
        results["condition_accuracy_mean"][ordered, :],
        results["array_order"],
        [str(x) for x in results["condition_labels"]],
    )


def write_matrix_csv(path: Path, matrix: np.ndarray, row_labels: list[str], col_labels: list[str]) -> None:
    with Path(path).open("w", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["array"] + list(col_labels))
        for label, row in zip(row_labels, matrix):
            writer.writerow([label] + [f"{value:.6g}" if np.isfinite(value) else "" for value in row])
