# pcg-mosaic

Code from the paper [*A mosaic of whole-body representations on the human precentral gyrus.*](https://www.nature.com/articles/s41586-026-10653-x) 

<img width="6379" height="3965" alt="Mosaic_thumbnail" src="https://github.com/user-attachments/assets/4d0b0e9b-8d97-4e7c-bfb0-aa20dfcfb109" />

## Overview

This repository accompanies the [paper](https://www.nature.com/articles/s41586-026-10653-x), [preprint](https://doi.org/10.1101/2024.09.14.613041) and the associated [dataset](https://doi.org/10.5061/dryad.mpg4f4rg5). The code reproduces all main figures and selected extended data figures reported in the paper.

The repository is a mix of MATLAB and Python:

- **Top-level MATLAB scripts** — `mainFigs.m` and `extendedDataFigs.m` — drive the analyses end-to-end.
- **`Code/`** — contains the installation guide (`INSTALLATION_GUIDE.md`) and a `Utils/` folder of helper functions (tuning analyses, classifiers, plotting utilities, colormaps, etc.).
- **`Code/Utils/Python/`** — contains Jupyter notebooks and yaml files for the cross-validated PCA analysis and RNN decoder used in Extended Data Figure 3 and Figure 3, respectively.
- **`Data/`** — destination for the eight participant `.mat` files and the `T12_control.mat` control dataset (downloaded separately from [Data Dryad](https://doi.org/10.5061/dryad.mpg4f4rg5) and [DABI](https://dabi.loni.usc.edu/projects/K1KK0H4SRS11), see below). Generated figures and intermediate results are written into `Data/MainFigs/` and `Data/ExtDataFigs/`.

A full description of the data structure (fields, dimensions, movement-condition numbering, etc.) is provided in `Data/README.md`. Each participant file contains both multi-unit threshold-crossing data and sorted-unit data within a single data structure.

## Getting Started

1. **Clone this repository** and download the datasets from [Data Dryad](https://doi.org/10.5061/dryad.mpg4f4rg5) and [DABI](https://dabi.loni.usc.edu/projects/K1KK0H4SRS11).
2. **Place all participant `.mat` files** (`T5.mat`, `T11.mat`, `T12.mat`, `T12_control.mat`, `T15.mat`, `T16.mat`, `T17.mat`, `C1.mat`, `C2.mat`) directly inside the `Data/` folder.
3. **Open MATLAB** and set the working directory to the top-level project folder (the one containing `mainFigs.m`).
4. **Run the analysis scripts in order:**
   ```matlab
   mainFigs           % generates all main figures
   extendedDataFigs   % generates selected extended data figures
   ```
   Outputs are written into `Data/MainFigs/` and `Data/ExtDataFigs/`.
5. **Run the Python cvPCA notebook** to generate Extended Data Figure 3a:
   - Create the conda environment from `Code/Utils/Python/cvPCA/environment.yml` 
   - Open `Code/Utils/Python/cvPCA/Mosaic_cvPCA.ipynb` with that folder as the working directory and run all cells.
6. **Run the Python RNN notebook** to generate Main Figure 3 [FORTHCOMING]:
   - For now, `mainFigs.m` will implement a naive Bayes classifier for Figure 3.

See `Code/INSTALLATION_GUIDE.md` for additional installation details and dependency information.

## System Requirements

**General**

- **MATLAB** R2025b or later
- **Python** 3.9.23 or later (only required for the cvPCA extended data figure)

**Python dependencies**

The Python code is split across two analyses, each with its own conda environment.

- **cvPCA** (managed via `Code/Utils/Python/cvPCA/environment.yml`)
  - Channels:
    - `conda-forge`
    - `defaults`
  - Conda packages:
    - `python=3.9`
    - `numpy (tested with 2.0.2)`
    - `scipy (tested with 1.13.1)`
    - `scikit-learn (tested with 1.6.1)`
    - `matplotlib (tested with 3.9.4)`
    - `jupyter (tested with 1.1.1)`
    - `pip`
  - pip packages:
    - `mat73 (tested with 0.65)`

- **RNN** [FORTHCOMING]

Typical installation time on a standard desktop is 5–30 minutes if MATLAB and/or Python are not already installed.
