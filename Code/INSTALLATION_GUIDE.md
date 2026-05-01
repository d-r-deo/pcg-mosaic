# Installation Guide — pcg-mosaic

Companion installation instructions for the [pcg-mosaic](https://github.com/d-r-deo/pcg-mosaic) repository, accompanying the paper [*A mosaic of whole-body representations on the human precentral gyrus.*](https://doi.org/10.1101/2024.09.14.613041)

For a project overview, see the top-level [`README.md`](../README.md).

## System Requirements

**General**

- **MATLAB** R2025b or later
- **Python** 3.9.23 or later (required for the cvPCA extended data figure)

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

## Installation

1. **Clone the repository** from [https://github.com/d-r-deo/pcg-mosaic](https://github.com/d-r-deo/pcg-mosaic) and save it locally.
2. **Download the dataset** from the [data repository](https://datadryad.org).
3. **Place all participant `.mat` files** (`T5.mat`, `T11.mat`, `T12.mat`, `T12_control.mat`, `T15.mat`, `T16.mat`, `T17.mat`, `C1.mat`, `C2.mat`) directly inside the `Data/` folder of the cloned repository. Each file contains both multi-unit threshold-crossing data and sorted-unit data within a single data structure (see `Data/README.md` for the full schema).

## Running the MATLAB analyses

1. **Open MATLAB** and set the working directory to the top-level project folder (the one containing `mainFigs.m`).
2. **Run the analysis scripts in order:**
   ```matlab
   mainFigs           % generates all main figures
   extendedDataFigs   % generates selected extended data figures
   ```
   Outputs are written into `Data/MainFigs/` and `Data/ExtDataFigs/`.

## Running the Python cvPCA notebook

The cvPCA Python code reproduces Extended Data Figure 3a and lives in `Code/Utils/Python/cvPCA`.

1. **Create the conda environment** from `Code/Utils/Python/cvPCA/environment.yml`. Step-by-step instructions are provided at the top of the `Mosaic_cvPCA.ipynb` notebook.
2. **Activate the environment** and launch Jupyter.
3. **Open `Mosaic_cvPCA.ipynb`** with `Code/Utils/Python/cvPCA` as the working directory and run all cells. The corresponding extended data figure is generated within the notebook.

## Running the Python RNN notebook [FORTHCOMING]
