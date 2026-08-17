# Does Supplying a Directory of Qualified Racial Minority Candidates Boost Organizational Diversity? A Field Experiment

Jose A. Cervantez, Katherine L. Milkman, and McKenzie Preston

Replication package for a field experiment testing whether reducing the search costs of finding
qualified racial minority candidates increases their representation as invited speakers in
academic seminars. The study randomized 1,881 seminars across five departments (Chemistry,
Physics, Mathematics, Computer Science, and Mechanical Engineering) during the 2024-25 academic
year at the department level, and analyzed outcomes at the seminar level.

Full data and code are also archived on OSF: https://osf.io/adg4p/

## Repository structure

- `code/`: R scripts and R Markdown files that build the analysis datasets and produce every
  table and figure in the paper and Online Appendix.
  - `01_prepare_final_data.R`: builds `data/final_data.csv` and `data/supplemental_data.csv`
    from the raw inputs in `data/raw/`.
  - `02_manuscript_analysis.Rmd`: produces the main manuscript tables (Tables 1-4) and
    associated results, reading `data/final_data.csv`.
  - `03_supplemental_analysis.Rmd`: produces the Online Appendix tables (S1-S12) and Extended
    Tables (E1-E16), reading `data/supplemental_data.csv`.
  - `code/tables/`: rendered PDF and Excel output from the two Rmd files above.
  - `code/figures/`: the paper's figures, and the Python scripts that build them.
- `data/`: analysis datasets (`final_data.csv`, `supplemental_data.csv`) and the raw inputs used
  to build them (`data/raw/`).
- `codebook.md`: full variable documentation for `final_data.csv` and `supplemental_data.csv`.
- `Online Appendix.docx` / `Online Appendix.pdf`: the paper's Online Appendix.

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
