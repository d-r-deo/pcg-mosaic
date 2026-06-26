# Whole-Body RNN Movement Decoder

Code for training and evaluating the recurrent neural network (RNN) movement decoder used to make **Figure 3** of *A mosaic of whole-body representations on the human precentral gyrus.* The architecture follows Willett et al. (2023, *Nature*), with code adapted from [`cffan/neural_seq_decoder`](https://github.com/cffan/neural_seq_decoder), modified from CTC sequence decoding to single-trial movement classification (cross-entropy on the mean of the per-step readout).

The workflow is three notebooks:

1. **`01_format_data.ipynb`** — turns the raw participant `.mat` files into five cross-validation pickle files.
2. **`02_train_rnns.ipynb`** — trains RNN models.
3. **`03_evaluate_rnns.ipynb`** — loads trained models, averages held-out predictions across seeds, writes `.mat` / `.pkl` / `.csv` outputs and the Figure 3a heatmap.

## Folder contents

| File | Purpose |
| --- | --- |
| `01_format_data.ipynb` | Builds the five formatted train/test fold files. |
| `02_train_rnns.ipynb` | Trains RNN models in series on a single GPU. |
| `03_evaluate_rnns.ipynb` | Evaluates held-out predictions, makes the heatmap and example confusion matrix. |
| `whole_body_pipeline.py` | Shared formatting, evaluation, and metadata utilities. |
| `neural_decoder_trainer.py` | RNN training loop and model loading. |
| `model.py` | GRU decoder architecture. |
| `dataset.py` | PyTorch dataset wrapper for the formatted pickle files. |
| `augmentations.py` | Input Gaussian smoothing helper. |
| `conf/config.yaml` | Hyperparameter configuration (loss, optimizer, model dims, augmentation). |
| `environment.yml`, `requirements.txt` | Conda / pip dependency specs. |
| `outputs/` | Created on first run; holds `formatted_data/`, `training/`, `evaluation/`. |

## Data and output paths

By default the pipeline reads from and writes to paths relative to this folder:

- **Input** — `../../../../Data/` (the project's top-level `Data/` directory).
- **Output** — `outputs/` next to this README.

Both defaults are defined in `whole_body_pipeline.py` (`RAW_DATA_DIR`, `OUTPUT_DIR`). Override them at the notebook level if your data lives elsewhere.

The workflow creates three output subfolders:

| Output folder | Contents |
| --- | --- |
| `outputs/formatted_data/` | Pickled fold files `all_fold_0_4sec.pkl` through `all_fold_4_4sec.pkl`. |
| `outputs/training/` | Per-`fold`/`seed` model folders, each containing `modelWeights`, `trainingStats`, and a `done` marker file when complete. |
| `outputs/evaluation/` | Held-out summary `.mat`, `.pkl`, `.csv`, plus the heatmap PNG/SVG and example confusion matrix. |

## Environment setup

Two options. Either works; pick whichever fits your machine.

**Conda (recommended for local single-GPU and most cluster environments):**

```bash
conda env create -f environment.yml
conda activate pcg-rnn-analysis
```

**Pip:**

```bash
pip install -r requirements.txt
```

## How to run

### 1. Format the data

```text
01_format_data.ipynb
```

What it does:

- Loads each participant `.mat` from `RAW_DATA_DIR`, transparently handling both v7 (`scipy.io.loadmat`) and v7.3 (`mat73`) files.
- Accepts only the 20 arrays listed in `ARRAY_ORDER`. This single check excludes both `BAD_ARRAYS` (`T17-m1`, `T17-m2`, `T11-d2`, `C2-d1`) **and** the per-participant `*Sorted` arrays.
- Excludes raw cue IDs 47 and 48 (T16's `EYES Up/Down`, T17's `HUM Hi/Low`).
- Pulls a fixed 4-second window: `goCue` to `goCue + 200` bins at 20 ms per bin.
- Generates five reproducible folds with `RANDOM_SEED = 0`.

### 2. Train the RNNs

```text
02_train_rnns.ipynb
```

Trains the RNN movement decoder serially on a single GPU. The first cell exposes a `DEMO_MODE` toggle:

- **`DEMO_MODE = True` (default)** — trains **5 folds × 3 seed = 15 models** in series. Useful for verifying the pipeline runs end-to-end without committing large compute resources. Produces all the downstream outputs, but the per-cell accuracy may be some percentage points below the published numbers because seed averaging is part of the published methodology.
- **`DEMO_MODE = False`** — trains **5 folds × 10 seeds = 50 models**. Required to reproduce Figure 3 more closely. 

The training loop skips runs whose `done` marker exists, so re-running picks up where it left off after an interruption. Each per-`(fold, seed)` directory under `outputs/training/` holds:

- `modelWeights` — best-test-accuracy state dict
- `trainingStats` — pickled per-eval-step loss / accuracy history
- `done` — completion marker (presence means the full `nBatch` loop finished)

Each run writes its outputs to:

```text
outputs/training/fold_<fold>_4sec/seed=<seed>/
  modelWeights      ← torch.save state dict
  trainingStats     ← per-eval-step loss / accuracy history (pickled)
```

The final cell of the notebook verifies all 50 runs produced both files.

### 3. Evaluate held-out accuracy

```text
03_evaluate_rnns.ipynb
```

- Loads held-out predictions for all folds and seeds.
- Averages across the seeds.
- Computes per-(array × movement-category) classification accuracy and per-condition accuracy.
- Marks heatmap cells whose binomial-test p > 0.05 against chance with a red ×.
- Writes summary `.mat` / `.pkl` / `.csv` files and the Figure 3a heatmap.
- Produces the example per-array confusion matrix shown in Figure 3b.

## Training configuration

Defaults live in `conf/config.yaml`. The values match those used to produce the published figures.

| Setting | Value |
| --- | --- |
| Loss | Cross-entropy classification loss |
| RNN | Bidirectional GRU |
| Hidden units | 512 |
| Layers | 5 |
| Batch size | 64 |
| Training batches | 15 000 |
| Input features | 96 (zero-padded for 64-electrode arrays) |
| Classes | 46 |
| Gaussian smoothing width | 2.0 |
| White noise SD | 1.2 |
| Kernel length | 32 |
| Stride length | 4 |