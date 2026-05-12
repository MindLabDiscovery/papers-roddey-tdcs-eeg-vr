# papers-roddey-tdcs-eeg-vr

Analysis code accompanying:

> **[Paper title — fill in]**
> [First author], [authors], [senior author].
> [Journal — fill in], [Year — fill in].
> DOI: [fill in once available]

This repository contains the MATLAB scripts used to generate the figures
in the manuscript above. It is intended to make the analyses transparent
and to allow readers with appropriate data access to reproduce the
reported results.

## Status

🚧 **In preparation** — code and figure scripts under active revision.

## What's in this repository

| File | What it does |
|------|--------------|
| `EEGlab_preprocessingCHECK.m` | Diagnostic / QC visualization of the EEG preprocessing pipeline. Loads a pre-computed `pipeline.mat` and plots time-domain traces and Welch power spectra at each of the eight preprocessing stages (raw import → downsample → high-pass filter → notch filter → epoch → ICA artifact removal → bad-channel interpolation → Artifact Subspace Reconstruction) for visual QC of a single subject/channel. |
| `fig_02_kinematics_win_nr.m` | Generates Figure 2 panels — 3D reach trajectories for example subjects, per-subject kinematic line plots, group-average kinematic line plots, and bar plots across 13 kinematic metrics (movement duration, reaction time, hand-path length, velocities, accelerations, jerk, IOC, accuracy). Writes ANOVA-ready data tables to disk for use in GraphPad. Groups: chronic stroke (stim / sham) and healthy control (stim / sham). |
| `fig_03_raw_data_final.m` | Generates Figure 3 panels — raw EEG epochs aligned to task events. |
| `fig_04_gamma_pow_coh_win_nr_gamma_final.m` | Generates Figure 4 panels — gamma-band power and inter-hemispheric coherence with linear regressions against behavioral metrics. |

## Requirements

- **MATLAB R2022b or newer** (older versions likely work; not tested)
- **MATLAB toolboxes:**
  - Statistics and Machine Learning Toolbox
  - Signal Processing Toolbox
- **External toolbox:**
  - [EEGLAB](https://sccn.ucsd.edu/eeglab/) — required for the preprocessing-check
    script. Tested with version [fill in].

## Data

The data used in this study are **not redistributed with this repository**.
They include identifiable clinical recordings collected under IRB protocol
pro00087153 at the Medical University of South Carolina and are governed
by a data-use agreement.

**Researchers with appropriate IRB approval at their institution can
request the dataset** by contacting Terry Roddey
(roddeyt@musc.edu) with:

- IRB approval number and a copy of the approved protocol
- A brief description of the planned analysis
- A signed data-use agreement (template available on request)

## Before you run anything: update the file paths

**Every script in this repository contains hardcoded absolute file paths
to the original analysis machines** (Windows paths like `I:\MIND\...` and
`D:\Box Sync\...`). These paths will not work on any other machine.

Before running a script, search for `pro00087153` or any `I:\` / `D:\`
string and replace it with the path to your local copy of the data.
On macOS or Linux, also flip the backslashes (`\`) to forward slashes
(`/`).

The expected per-subject folder structure is:

```
<data_root>/
  pro00087153_00XX/
    analysis/
      EEGlab/
        pipeline.mat                ← used by EEGlab_preprocessingCHECK.m
      S1-VR_preproc/
        pro00087153_00XX_S1-VRdata_preprocessed.mat
      S2-metrics/
        pro00087153_00XX_S2-Metrics.mat
```

## Reproducing the figures

Each script is self-contained: open MATLAB, edit the paths near the top of
the script, then run it. Each script generates one or more MATLAB figure
windows. Save figures manually (`File → Save As`) or by adding `saveas` or
`exportgraphics` calls.

### Figure 2 (`fig_02_kinematics_win_nr.m`)

Reproduces the kinematics panels. Requires the per-subject
`S2-Metrics.mat` files and a single preprocessed VR data file for the 3D
trajectory panels (subject 5). The script also writes
`gp_anova2_*.txt` files containing the data tables used for the
mixed-design ANOVAs reported in the paper. Reported in the manuscript:
n = 5 chronic stroke stim, n = 5 chronic stroke sham, n = 6 healthy control
stim, n = 5 healthy control sham.

### Figure 3 (`fig_03_raw_data_final.m`)

Reproduces the raw-data illustration panels. Requires preprocessed EEG.

### Figure 4 (`fig_04_gamma_pow_coh_win_nr_gamma_final.m`)

Reproduces the gamma power and coherence panels with linear regressions
against kinematic outcomes.

### Preprocessing QC (`EEGlab_preprocessingCHECK.m`)

This script is a **visualization tool, not the preprocessing pipeline
itself**. It assumes that the preprocessing pipeline has already been run
and a `pipeline.mat` file has been saved, containing the EEG data at each
preprocessing stage. The script plots time-domain traces and Welch power
spectra at each stage for visual inspection. Edit `subject`, `channel`,
and `protocolfolder` at the top of the script.

The preprocessing pipeline that produces `pipeline.mat` consists of, in
order:

1. Import from EDF
2. Downsample to 256 Hz
3. High-pass filter (0.5 Hz)
4. Notch filter (line noise)
5. Epoch around task events
6. Independent Component Analysis (ICA) artifact removal
7. Bad-channel detection and interpolation
8. Artifact Subspace Reconstruction (ASR)

The pipeline itself uses EEGLAB; see [other lab repository — fill in if
applicable] for the pipeline scripts.

## Known limitations

- **Hardcoded paths:** all four scripts contain absolute paths to
  internal lab drives. You must edit these before running.
- **Subject lists hardcoded:** group membership (chronic stroke vs.
  healthy control, stim vs. sham) is hardcoded as character arrays of
  participant IDs at the top of each script. If you analyse a different
  cohort, edit these lists.
- **No top-level `setup.m`:** scripts must be run from the repo root, and
  each script handles its own path setup.
- **No automated tests:** the figures are validated by visual inspection
  against the published manuscript figures.

## Citation

If you use this code or build on these analyses, please cite the paper:

> [Full citation — fill in once published]

A machine-readable citation will be added in `CITATION.cff` for each
tagged release.

## License

Released under the GNU General Public License v3.0. See `LICENSE`.

The license covers code only. The data are governed separately under the
data-use agreement.

## Contact

- **Code questions and bug reports:** open an issue on this repository
- **Data access:** Terry Roddey (roddeyt@musc.edu)
- **Senior author / corresponding:** [Name, email]
- **Affiliation:** MIND Lab, Medical University of South Carolina

## Acknowledgments

This work was supported by [funding sources — grant numbers].

