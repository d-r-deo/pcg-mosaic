# Neural Data from "A mosaic of whole-body representations on the human precentral gyrus" (Deo et al., 2026)

## Overview

Neural data were collected from **eight participants** while each performed a text-cued instructed delay task. 

During the **instructed delay** period, a red square and text appeared in the center of a computer monitor indicating to the participant that they should prepare to make the specified movement. The instructed delay period lasted a random amount of time. After the delay period, the square turned **green**, indicating the **movement** period, at which point the participant made the movement as immediately as possible.

Each participant was asked to:

- Continue *attempting* the movement, if they could not overtly move the body part; or
- Hold the *posture* of the completed movement, if they were able to overtly move the body part,

until the text changed to **"Return,"** at which point the participant relaxed and returned to a neutral posture.

All movement cues appeared in randomized order. The ranges of delay and movement periods may differ for each participant, as they were chosen based on each participant's comfort level.

---

## Data Details

For each experiment with a given participant, data were collected in a series of blocks. **Neural data between blocks was not recorded.** Data can be loaded with MATLAB or Python (`scipy.io.loadmat`).

### Dataset Fields

Each participant's dataset contains the following fields:

| Field | Dimensions | Description |
| --- | --- | --- |
| `tx` | *T* × *F* | Binned threshold crossing counts (20 ms bins). *T* = number of 20 ms time steps in the experiment; *F* = number of features (multi-unit channels concatenated with sorted units from spike-sorted data). |
| `tx_blkMeanSub` | *T* × *F* | Block-wise mean-removed threshold crossing counts (20 ms bins). Same dimensions as `tx`. |
| `blockNum` | *T* × 1 | Block number at each time step. Gaps in recordings occur at block transitions (neural activity between blocks was not recorded). |
| `trialCue` | *R* × 1 | Movement condition for each trial (see *Movement Condition Numbering* below). *R* = number of trials. |
| `goCue` | *R* × 1 | Row indices into the time dimension (e.g., rows of `tx`) marking the transition from 'delay' to 'move'. |
| `state` | *T* × 1 | Trial state at each time step: `0` = Delay, `1` = Go, `2` = Return. |
| `stateNames` | 1 × 3 cell | String names for the trial states (`0` = Delay, `1` = Go, `2` = Return). |
| `cueList` | 46 × 1 cell | Movement condition names (strings). The index of each name corresponds to a `trialCue` number (e.g., if `trialCue(1) = 3`, then trial 1 was *HEAD – Turn Down*). |
| `binWidth` | scalar | Bin size in seconds (`0.02` = 20 ms). |
| `chanSets` | 1 × *C* cell | Each cell contains a vector of electrode-channel or sorted-unit indices for a particular array/feature set. *C* = number of array/feature sets. |
| `chanSetNames` | 1 × *C* cell | Corresponding names for each array/feature set in `chanSets`. |
| `hemisphere` | string | Hemisphere of the brain where electrodes were located. |
| `details` | string | Brief details about the dataset (participant ID, date of experiment, block numbers included). |
| `sorted` | *T* × *S* | Binned threshold crossing counts (20 ms bins) of sorted units only. *S* = number of sorted units. |
| `sortedChanIDs` | 1 × *S* | Mapping from each sorted unit (column of `sorted`) to the electrode channel on which it was detected (see `chanSets` for the array a sorted unit belongs to). |

---

## Dataset Names and Repetitions

| Dataset | Repetitions per movement condition |
| --- | --- |
| T5  | 22 |
| T11 | 12 |
| T12 | 20 |
| T15 | 7–8 |
| T16 | 13–14 |
| T17 | 15–16 |
| C1  | 14 |
| C2  | 12–13 |

### T12_control — Supplementary Control Dataset

`T12_control` is a special dataset from a control experiment performed with participant T12. During this control experiment, T12 performed a limited set of movements restricted to all four limbs. See `T12_control.neural.cueList` for the full list of movements used in this control experiment.

`T12_control` contains two sub-structures:

- **`T12_control.neural`** — A data structure with the same fields as those described in *Data Details*.
- **`T12_control.opticalFlow`** — An accompanying data structure quantifying movement of the hands and feet using optical-flow analysis.

The `opticalFlow` sub-structure has the same fields as the core data, with the following additions:

| Field | Dimensions | Description |
| --- | --- | --- |
| `opticalFlow` | *M* × 4 | Optical-flow movement quantification. *M* = number of movie frames; 4 = number of effectors (right hand, left hand, right foot, left foot, in that order). |
| `columnOrder` | 4 × 1 cell | String names of the effectors corresponding to each column of `opticalFlow`. |

> **Note:** The `goCue` within the `opticalFlow` sub-structure is indexed relative to the `opticalFlow` matrix (not the neural data).

---

## Movement Condition Numbering Scheme

| # | Condition | # | Condition |
| --: | --- | --: | --- |
| 1  | Do Nothing               | 24 | MOUTH – Open |
| 2  | EYEBROWS – Raise         | 25 | NOSE – Wrinkle |
| 3  | HEAD – Turn Down         | 26 | RIGHT ANKLE – Down |
| 4  | HEAD – Turn Left         | 27 | RIGHT ANKLE – Left |
| 5  | HEAD – Turn Right        | 28 | RIGHT ANKLE – Right |
| 6  | HEAD – Turn Up           | 29 | RIGHT ANKLE – Up |
| 7  | LEFT ANKLE – Down        | 30 | RIGHT ARM – Raise Left |
| 8  | LEFT ANKLE – Left        | 31 | RIGHT ARM – Raise Right |
| 9  | LEFT ANKLE – Right       | 32 | RIGHT HAND – Close |
| 10 | LEFT ANKLE – Up          | 33 | RIGHT HAND – Open |
| 11 | LEFT ARM – Raise Left    | 34 | RIGHT LEG – Raise Left |
| 12 | LEFT ARM – Raise Right   | 35 | RIGHT LEG – Raise Right |
| 13 | LEFT HAND – Close        | 36 | RIGHT TOES – Curl |
| 14 | LEFT HAND – Open         | 37 | RIGHT TOES – Open |
| 15 | LEFT LEG – Raise Left    | 38 | RIGHT WRIST – Down |
| 16 | LEFT LEG – Raise Right   | 39 | RIGHT WRIST – Left |
| 17 | LEFT TOES – Curl         | 40 | RIGHT WRIST – Right |
| 18 | LEFT TOES – Open         | 41 | RIGHT WRIST – Up |
| 19 | LEFT WRIST – Down        | 42 | SPEAK – "Ban" |
| 20 | LEFT WRIST – Left        | 43 | SPEAK – "Bat" |
| 21 | LEFT WRIST – Right       | 44 | SPEAK – "Can" |
| 22 | LEFT WRIST – Up          | 45 | SPEAK – "Cat" |
| 23 | LIPS – Pucker            | 46 | TONGUE – Out |

### Dataset-Specific Additional Conditions

**T16 dataset** includes two additional movement conditions:

| # | Condition |
| --: | --- |
| 47 | EYES – Up |
| 48 | EYES – Down |

**T17 dataset** includes two additional movement conditions:

| # | Condition |
| --: | --- |
| 47 | HUM – Hi |
| 48 | HUM – Low |
