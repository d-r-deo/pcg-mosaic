import torch
from torch.utils.data import Dataset


class MovementDataset(Dataset):
    """Dataset for the whole-body single-label movement decoder.

    The formatted pickle files keep the legacy keys from the speech decoder
    (``sentenceDat``, ``phonemes``, and ``phoneLens``) so old model-loading
    code remains compatible.
    """

    def __init__(self, data, transform=None):
        self.data = data
        self.transform = transform
        self.n_days = len(data)
        self.n_trials = sum([len(d["sentenceDat"]) for d in data])

        self.neural_feats = []
        self.labels = []
        self.neural_time_bins = []
        self.label_lens = []
        self.array_indices = []
        for day in range(self.n_days):
            for trial in range(len(data[day]["sentenceDat"])):
                self.neural_feats.append(data[day]["sentenceDat"][trial])
                self.labels.append(data[day]["phonemes"][trial])
                self.neural_time_bins.append(data[day]["sentenceDat"][trial].shape[0])
                self.label_lens.append(data[day]["phoneLens"][trial])
                self.array_indices.append(day)

        self.phone_seqs = self.labels
        self.phone_seq_lens = self.label_lens
        self.days = self.array_indices

    def __len__(self):
        return self.n_trials

    def __getitem__(self, idx):
        neural_feats = torch.tensor(self.neural_feats[idx], dtype=torch.float32)

        if self.transform:
            neural_feats = self.transform(neural_feats)

        return (
            neural_feats,
            torch.tensor(self.labels[idx], dtype=torch.int32),
            torch.tensor(self.neural_time_bins[idx], dtype=torch.int32),
            torch.tensor(self.label_lens[idx], dtype=torch.int32),
            torch.tensor(self.array_indices[idx], dtype=torch.int64),
        )


SpeechDataset = MovementDataset
