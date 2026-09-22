# Does Supplying a Directory of Qualified Racial Minority Candidates Boost Organizational Diversity? A Field Experiment

[Author names withheld for double-blind review]

Replication package for a field experiment testing whether reducing the search costs of finding
qualified racial minority candidates increases their representation as invited speakers in
academic seminars. The study randomized 1,881 seminars across five departments (Chemistry,
Physics, Mathematics, Computer Science, and Mechanical Engineering) during the 2024-25 academic
year at the department level, and analyzed outcomes at the seminar level. A supplemental
online experiment examines belief updating and diversity salience following a STEM faculty
nomination task. Its final analyses and sensitivity results appear in Tables S13 and S14.

This repository archives the replication files: field-study data and code, aggregate
online-study data and code, figures, the Online Appendix, and preregistration links.

## Repository structure

- `code/`: R scripts and R Markdown files that build the analysis datasets and produce every
  table and figure in the paper and Online Appendix.
  - `01_prepare_final_data.R`: builds `data/final_data.csv` and `data/supplemental_data.csv`
    from the raw inputs in `data/raw/`.
  - `02_manuscript_analysis.Rmd`: produces the main manuscript tables (Tables 1-4) and
    associated results, reading `data/final_data.csv`.
  - `03_supplemental_analysis.Rmd`: produces the Online Appendix tables (S1-S12) and Extended
    Tables (E1-E16), reading `data/supplemental_data.csv`.
  - `04_online_study_analysis.R`: reproduces the supplemental online study's belief model
    (Table S13) and two salience measures in the main and sensitivity samples (Table S14)
    from aggregate condition moments, using only base R.
  - `code/tables/`: rendered PDF and Excel output from the two Rmd files above.
  - `code/tables/online_study/`: Tables S13 and S14 as CSVs, plus full-precision coefficients,
    contrasts, model summaries, and condition descriptives.
  - `code/figures/`: the paper's figures, and the Python scripts that build them.
- `data/`: analysis datasets (`final_data.csv`, `supplemental_data.csv`) and the raw inputs used
  to build them (`data/raw/`).
  - `data/online_study/`: aggregate input and documentation for the online experiment.
    No participant-level online responses or identifiers are included. The aggregate data
    reproduce the reported condition-only OLS models, with the limitations described there.
- `codebook.md`: full variable documentation for `final_data.csv` and `supplemental_data.csv`.
- `Online Appendix.docx` / `Online Appendix.pdf`: the paper's Online Appendix.
- `Preregistration.pdf`: the study's pre-registration (AsPredicted template, registered
  June 23, 2024, before any data collection).
- `extended_tables/`: the paper's Extended Tables (E1-E16) as a standalone PDF and Excel
  workbook. These are extracted from the full supplemental output (`code/tables/`), where the
  same tables appear alongside the Online Appendix tables.

## How to run the replication

Developed and tested under R 4.5.2. Any recent R 4.x installation should work, since the code
relies on standard CRAN packages rather than anything version-pinned.

Required R packages: `tidyverse`, `broom`, `car`, `estimatr`, `kableExtra`, `lmtest`,
`modelsummary`, `openxlsx`, `parallel`, `sandwich`, `systemfit`. Install with:

```r
install.packages(c("tidyverse", "broom", "car", "estimatr", "kableExtra", "lmtest",
                    "modelsummary", "openxlsx", "sandwich", "systemfit"))
```

Run the scripts in this order, from the `code/` directory:

1. `01_prepare_final_data.R`: builds the analysis datasets from the raw data. Takes a few
   minutes to run.
2. `02_manuscript_analysis.Rmd`: knit this to produce the main manuscript tables. Takes several
   minutes.
3. `03_supplemental_analysis.Rmd`: knit this to produce the Online Appendix tables. Takes about
   12 minutes.

To reproduce the supplemental online results, run `Rscript code/04_online_study_analysis.R`
from the repository root. This script is independent of the field-study pipeline and requires
only base R. It writes Tables S13 and S14 and the supporting numerical CSVs.

The online experiment was fielded September 21, 2026, with 600 recruited participants,
599 recorded randomized respondents, and 554 valid belief responses. Its main analyses use
the valid-belief sample. Salience sensitivity analyses use all 599 recorded respondents.
The online preregistration is [AsPredicted #312433](https://aspredicted.org/hc3jy8.pdf), distinct from the field preregistration
at the repository root. See `data/online_study/README.md` for sample accounting, methods,
provenance, the preregistration, and the limits of aggregate reproduction.

The figure scripts in `code/figures/scripts/` build PowerPoint files, and the PNG and PDF figures
in `code/figures/` were exported from those PowerPoint files by hand rather than rendered
programmatically, so running the scripts alone will not reproduce the image files directly.

## Codebook

See `codebook.md` for a full description of every variable in `data/final_data.csv` and
`data/supplemental_data.csv`. Both files contain 1,686 rows, one per seminar with speaker data.

## License

Code in this repository is released under the MIT License (see `LICENSE`). Data and materials
(the datasets in `data/`, the Online Appendix, and the figures) are released under a
[Creative Commons Attribution 4.0 International license](https://creativecommons.org/licenses/by/4.0/) (CC-BY-4.0).

## Citation

[Placeholder: add once the paper has a DOI or accepted citation format]
