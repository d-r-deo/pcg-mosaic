# Installation Guide — pcg-mosaic

Companion installation instructions for the [pcg-mosaic](https://github.com/d-r-deo/pcg-mosaic) repository, accompanying the paper [*A mosaic of whole-body representations on the human precentral gyrus.*](https://www.nature.com/articles/s41586-026-10653-x)

For a project overview, see the top-level [`README.md`](../README.md).

## System Requirements

**General**

- **MATLAB** R2025b or later
- **Python** 3.9.23 or 3.12.1

**Python dependencies**

The Python code is split across two analyses, each with its own conda environment.

- **cvPCA** (managed via `Code/Utils/Python/cvPCA/environment.yml`)
  - Channels:
    - `conda-forge`
    - `defaults`
  - Conda packages:
    - `python=3.9`
    - `numpy`
    - `scipy`
    - `scikit-learn`
    - `matplotlib`
    - `jupyter`
    - `pip`
  - pip packages:
    - `mat73`

- **RNN** (managed via `Code/Utils/Python/RNN/environment.yml`)
  - Channels:
    - `conda-forge`
    - `pytorch`
    - `defaults`
  - Conda packages:
    - `python=3.12.1`
    - `numpy`
    - `scipy`
    - `matplotlib`
    - `pyyaml`
    - `pytorch`
    - `jupyter`
    - `ipykernel`
    - `pip`
  - pip packages:
    - `mat73`
    - `hydra-core`

Typical installation time on a standard desktop is 5–30 minutes if MATLAB and/or Python are not already installed.

## Installation

1. **Clone the repository** from [https://github.com/d-r-deo/pcg-mosaic](https://github.com/d-r-deo/pcg-mosaic) and save it locally.
2. **Download the dataset** from [Data Dryad](https://doi.org/10.5061/dryad.mpg4f4rg5) and [DABI](https://dabi.loni.usc.edu/projects/K1KK0H4SRS11).
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

## Running the Python RNN notebooks

The RNN Python code reproduces Figure 3 and lives in `Code/Utils/Python/RNN`.
1. **Create the conda environment** from `Code/Utils/Python/RNN/environment.yml`.
2. **Activate the environment** and launch Jupyter.
3. **Open `01_format_data.ipynb`, `02_train_rnns.ipynb`, and `03_evaluate_rnns.ipynb`** with `Code/Utils/Python/RNN` as the working directory and run each notebook in order.

