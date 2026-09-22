# Codebook

## Replication Package Directory

```
code/
├── 01_prepare_final_data.R          Constructs analysis datasets from raw inputs
├── 02_manuscript_analysis.Rmd       Main manuscript tables and results
├── 03_supplemental_analysis.Rmd     Online Appendix (S1-S12) and Extended Tables (E1-E16)
├── tables/                          Generated table outputs
│   ├── 02_manuscript_analysis.pdf
│   ├── 03_supplemental_analysis.pdf
│   ├── All_Analysis_Tables.xlsx
│   └── Supplemental_Analysis_Tables.xlsx
└── figures/                         Generated figure outputs
    ├── figure_1.png                 Overview of the experimental procedure
    ├── figure_2.png                 Treatment effects on speaker diversity
    ├── figure_3.png                 Decomposition of treatment effects
    ├── figure_s1–s4.png             Experimental materials (screenshots)
    ├── figure_s5.png                Treatment effects by discipline
    └── scripts/                     Figure generation scripts
        ├── figure_1.py              (builds figure_1.pptx; PNG/PDF exported via PowerPoint)
        ├── figure_2.py
        ├── figure_3.py
        └── figure_s5.py
data/
├── final_data.csv                   Main analysis dataset (105 variables)
├── supplemental_data.csv            Extended analysis dataset (128 variables)
├── excluded_seminars.csv            Seminars excluded from analysis
├── initial_seminar_sample.csv       Full randomized sample
└── raw/                             Raw input files used by 01_prepare_final_data.R
```

## Variable Documentation

The supplemental online experiment is documented separately in
`data/online_study/README.md`. Its `condition_moments.csv` contains condition sample sizes,
means, and standard deviations sufficient to reproduce the five ordinary OLS models in
Tables S13 and S14. No individual online-study responses are released. The documentation
below describes the field-study datasets. The online experiment was preregistered as
[AsPredicted #312433](https://aspredicted.org/hc3jy8.pdf), “STEM Faculty Belief Updating and Salience.”

This codebook documents all variables in `data/final_data.csv` (manuscript analysis) and `data/supplemental_data.csv` (supplemental analysis). Variables marked with **(S)** appear only in `supplemental_data.csv`; all others appear in both files.

Both files contain **1,686 rows** (one per seminar with speaker data).

Sample definition:
- Included seminars = `seminar_id` values present in `data/raw/speaker_demographics.csv`
- Excluded seminars = `data/raw/seminar_metadata.csv` minus that set
- Canonical exclusion file written by pipeline: `data/excluded_seminars.csv`

---

## Identification

| Variable | Type | Description |
|---|---|---|
| `seminar_id` | character | Unique seminar identifier |
| `university` | character | University name |
| `discipline` | character | Academic discipline (Chemistry, Computer Science, Mathematics, Mechanical Engineering, Physics) |
| `department` | character | Department identifier (university-discipline format from treatment assignment) |
| `department_std` | character | Standardized department identifier (university + "-" + discipline) |
| `condition` | character | Treatment group label ("treatment" or "control") |

## Treatment Assignment

| Variable | Type | Description |
|---|---|---|
| `treatment` | integer (0/1) | Treatment indicator: 1 = treatment, 0 = control |

## Stratification Controls

### Bin Indicators (one-hot encoded; reference category: (17,28])

Bins are defined by the number of seminars per department.

| Variable | Type | Description |
|---|---|---|
| `bin_0_1` | integer (0/1) | Department has [0,1] seminars |
| `bin_1_3` | integer (0/1) | Department has (1,3] seminars |
| `bin_3_5` | integer (0/1) | Department has (3,5] seminars |
| `bin_5_7` | integer (0/1) | Department has (5,7] seminars |
| `bin_7_11` | integer (0/1) | Department has (7,11] seminars |
| `bin_11_17` | integer (0/1) | Department has (11,17] seminars |

### Batch Indicators (one-hot encoded; reference category: batch 10)

| Variable | Type | Description |
|---|---|---|
| `batch_1` – `batch_9` | integer (0/1) | Email batch assignment indicators (9 dummies) |

## Main Speaker Outcomes

All percentages use `total_speakers` as the denominator (0 speakers → 0%).

| Variable | Type | Description |
|---|---|---|
| `total_speakers` | integer | Total number of speakers in the seminar (all speakers receive demographic classification via face/name analysis, so this also serves as the denominator for all percentage outcomes) |
| `pct_urm` | numeric (0–100) | Percentage of speakers who are URM (Black, Hispanic, or Native American) |
| `num_urm` | integer | Count of URM speakers |
| `has_any_urm` | integer (0/1) | 1 if at least one URM speaker |
| `pct_black` | numeric (0–100) | Percentage of speakers who are Black |
| `num_black` | integer | Count of Black speakers |
| `has_any_black` | integer (0/1) | 1 if at least one Black speaker |
| `pct_hispanic` | numeric (0–100) | Percentage of speakers who are Hispanic/Latino |
| `num_hispanic` | integer | Count of Hispanic speakers |
| `has_any_hispanic` | integer (0/1) | 1 if at least one Hispanic speaker |

## Semester-Specific Outcomes

Fall = July 1 – December 31, 2024; Spring = January 1 – June 30, 2025. Percentages use semester-specific speaker counts as denominators.

| Variable | Type | Description |
|---|---|---|
| `fall_pct_black` | numeric (0–100) | Pct Black speakers in fall semester |
| `fall_num_black` | integer | Count of Black speakers in fall |
| `has_any_black_fall` | integer (0/1) | 1 if any Black speaker in fall |
| `spring_pct_black` | numeric (0–100) | Pct Black speakers in spring semester |
| `spring_num_black` | integer | Count of Black speakers in spring |
| `has_any_black_spring` | integer (0/1) | 1 if any Black speaker in spring |
| `fall_pct_urm` | numeric (0–100) | Pct URM speakers in fall |
| `fall_num_urm` | integer | Count of URM speakers in fall |
| `has_any_urm_fall` | integer (0/1) | 1 if any URM speaker in fall |
| `spring_pct_urm` | numeric (0–100) | Pct URM speakers in spring |
| `spring_num_urm` | integer | Count of URM speakers in spring |
| `has_any_urm_spring` | integer (0/1) | 1 if any URM speaker in spring |
| `fall_pct_hispanic` | numeric (0–100) | Pct Hispanic speakers in fall |
| `fall_num_hispanic` | integer | Count of Hispanic speakers in fall |
| `has_any_hispanic_fall` | integer (0/1) | 1 if any Hispanic speaker in fall |
| `spring_pct_hispanic` | numeric (0–100) | Pct Hispanic speakers in spring |
| `spring_num_hispanic` | integer | Count of Hispanic speakers in spring |
| `has_any_hispanic_spring` | integer (0/1) | 1 if any Hispanic speaker in spring |

## Engagement / Compliance

| Variable | Type | Description |
|---|---|---|
| `accessed_database` | integer (0/1) | Treatment group: 1 if department accessed the URM faculty database |
| `accessed_dept_database` | integer (0/1) | Control group: 1 if department accessed the departmental database |
| `db_access_combined` | integer (0/1) | Combined access indicator (treatment → `accessed_database`, control → `accessed_dept_database`) |
| `bitly_clicked` | integer (0/1) | 1 if email link was clicked for this seminar |
| `bitly_click_count` | integer | Number of times the email link was clicked |

## Database-Attribution Outcomes (Black)

These variables decompose Black speaker representation into speakers found through the URM database versus other channels.

| Variable | Type | Description |
|---|---|---|
| `num_black_from_db` | integer | Count of Black speakers matched to the URM database (capped at `num_black`) |
| `pct_black_from_db` | numeric (0–100) | Pct of speakers who are Black and from the database |
| `has_any_black_from_db` | integer (0/1) | 1 if any Black speaker matched to the database |
| `num_black_not_from_db` | integer | Count of Black speakers not matched to the database |
| `pct_black_not_from_db` | numeric (0–100) | Pct of speakers who are Black but not from the database |

## Database-Attribution Outcomes (Hispanic, URM) **(S)**

| Variable | Type | Description |
|---|---|---|
| `num_hispanic_from_db` | integer | Count of Hispanic speakers matched to the database |
| `pct_hispanic_from_db` | numeric (0–100) | Pct Hispanic speakers from the database |
| `has_any_hispanic_from_db` | integer (0/1) | 1 if any Hispanic speaker from the database |
| `num_hispanic_not_from_db` | integer | Count of Hispanic speakers not from the database |
| `pct_hispanic_not_from_db` | numeric (0–100) | Pct Hispanic speakers not from the database |
| `num_urm_from_db` | integer | Count of URM speakers matched to the database |
| `pct_urm_from_db` | numeric (0–100) | Pct URM speakers from the database |
| `has_any_urm_from_db` | integer (0/1) | 1 if any URM speaker from the database |
| `num_urm_not_from_db` | integer | Count of URM speakers not from the database |
| `pct_urm_not_from_db` | numeric (0–100) | Pct URM speakers not from the database |

## Treatment Decomposition: Peer Window

These variables decompose Black speaker counts by whether the speaker's institution falls within the host department's peer window (+/- 20 rank positions in the discipline-specific U.S. News rankings).

| Variable | Type | Description |
|---|---|---|
| `num_black_inpeer` | integer | Count of Black speakers from institutions within the host's peer window |
| `pct_black_inpeer` | numeric (0–100) | Pct of speakers who are Black and within the peer window |
| `num_black_outside` | integer | Count of Black speakers from outside the peer window (includes unranked) |
| `pct_black_outside` | numeric (0–100) | Pct of speakers who are Black and outside the peer window |
| `num_hispanic_inpeer` | integer | Count of Hispanic speakers from institutions within the host's peer window |
| `pct_hispanic_inpeer` | numeric (0–100) | Pct of speakers who are Hispanic and within the peer window |
| `num_hispanic_outside` | integer | Count of Hispanic speakers from outside the peer window (includes unranked) |
| `pct_hispanic_outside` | numeric (0–100) | Pct of speakers who are Hispanic and outside the peer window |
| `num_urm_inpeer` | integer | Count of URM speakers from institutions within the host's peer window |
| `pct_urm_inpeer` | numeric (0–100) | Pct of speakers who are URM and within the peer window |
| `num_urm_outside` | integer | Count of URM speakers from outside the peer window (includes unranked) |
| `pct_urm_outside` | numeric (0–100) | Pct of speakers who are URM and outside the peer window |

## Treatment Decomposition: Rank Direction

These variables decompose Black speaker counts by the rank direction of the speaker's institution relative to the host department in the U.S. News discipline rankings. The four categories are mutually exclusive and exhaustive: `num_black_above + num_black_below + num_black_host_inst + num_black_unranked = num_black`.

| Variable | Type | Description |
|---|---|---|
| `num_black_above` | integer | Count of Black speakers from higher-ranked institutions than host |
| `pct_black_above` | numeric (0–100) | Pct of speakers who are Black and from higher-ranked institutions |
| `num_black_below` | integer | Count of Black speakers from lower-ranked institutions than host |
| `pct_black_below` | numeric (0–100) | Pct of speakers who are Black and from lower-ranked institutions |
| `num_black_host_inst` | integer | Count of Black speakers from the host institution |
| `pct_black_host_inst` | numeric (0–100) | Pct of speakers who are Black and from the host institution |
| `num_black_unranked` | integer | Count of Black speakers from institutions not in U.S. News rankings |
| `pct_black_unranked` | numeric (0–100) | Pct of speakers who are Black and from unranked institutions |

## Department Characteristics

| Variable | Type | Description |
|---|---|---|
| `total_faculty` | integer | Total faculty count in the department (2024–2025) |
| `black_faculty` | integer | Count of Black faculty in the department |
| `frac_black_faculty` | numeric (0–1) | Fraction of faculty who are Black |
| `frac_hispanic_faculty` | numeric (0–1) | Fraction of faculty who are Hispanic |
| `frac_urm_faculty` | numeric (0–1) | Fraction of faculty who are URM |
| `frac_women_faculty` | numeric (0–1) | Fraction of faculty who are women |
| `frac_native_faculty` | numeric (0–1) | Fraction of faculty who are Native American (= `frac_urm` − `frac_black` − `frac_hispanic`, floored at 0) |
| `black_faculty_quartile` | integer (1–4) | Quartile of `frac_black_faculty` across departments **(S)** |

## Rankings and Peer Departments

| Variable | Type | Description |
|---|---|---|
| `dept_ranking` | numeric | US News discipline-specific ranking; if missing, replaced with overall university ranking |
| `missing_dept_rank` | integer (0/1) | 1 if discipline-specific US News department ranking is missing (even when `dept_ranking` is filled via overall ranking fallback) |
| `total_peer_departments` | integer | Number of peer departments eligible for inclusion in the database: starts at +/-20 rank positions (discipline-specific 2024 US News), expanded near boundaries to ensure >=40 peers, and further expanded one position above/below until >=20 URM faculty are available |
| `total_urm_peer_faculty` | integer | Count of URM faculty across the eligible peer departments (from discipline-specific URM databases) |

## Recipient Demographics

Computed from included email-recipient files. Fractions are proportions (0–1).

Missingness convention:
- `frac_dept_chair_*` is `NA` when a department has no `department_chair` recipient rows.
- `frac_seminar_organizer_*` is `NA` when a department has no `seminar_contact`/`faculty` recipient rows.

| Variable | Type | Description |
|---|---|---|
| `num_recipients` | integer | Number of email recipients in the department |
| `frac_recipients_female` | numeric (0–1) | Fraction of recipients who are female |
| `frac_recipients_urm` | numeric (0–1) | Fraction of recipients who are URM |
| `frac_recipients_black` | numeric (0–1) | Fraction of recipients who are Black |
| `frac_recipients_hispanic` | numeric (0–1) | Fraction of recipients who are Hispanic |
| `frac_dept_chair_female` | numeric (0–1) | Fraction of dept chairs who are female |
| `frac_dept_chair_urm` | numeric (0–1) | Fraction of dept chairs who are URM |
| `frac_dept_chair_black` | numeric (0–1) | Fraction of dept chairs who are Black |
| `frac_dept_chair_hispanic` | numeric (0–1) | Fraction of dept chairs who are Hispanic |
| `frac_seminar_organizer_female` | numeric (0–1) | Fraction of seminar organizers who are female |
| `frac_seminar_organizer_urm` | numeric (0–1) | Fraction of seminar organizers who are URM |
| `frac_seminar_organizer_black` | numeric (0–1) | Fraction of seminar organizers who are Black |
| `frac_seminar_organizer_hispanic` | numeric (0–1) | Fraction of seminar organizers who are Hispanic |
| `pct_hispanic_recipients` | numeric (0–100) | Percentage of recipients who are Hispanic |

## Supplemental Variables **(S)**

Variables below are only in `supplemental_data.csv`. They include discipline indicators, complement counts, and organizer demographics used in extended analyses.

| Variable | Type | Description |
|---|---|---|
| `num_non_urm` | integer | Count of non-URM speakers (`total_speakers` − `num_urm`) |
| `num_non_black` | integer | Count of non-Black speakers (`total_speakers` − `num_black`) |
| `pct_non_black` | numeric (0–100) | Pct of speakers who are not Black |
| `disc_chemistry` | integer (0/1) | 1 if discipline is Chemistry |
| `disc_computer_science` | integer (0/1) | 1 if discipline is Computer Science |
| `disc_mathematics` | integer (0/1) | 1 if discipline is Mathematics |
| `disc_mechanical_engineering` | integer (0/1) | 1 if discipline is Mechanical Engineering |
| `disc_physics` | integer (0/1) | 1 if discipline is Physics |
| `n_seminars` | integer | Number of seminars per department (set to 1 per row) |
| `any_black_organizer` | integer (0/1) | 1 if any seminar organizer is Black |
| `any_urm_organizer` | integer (0/1) | 1 if any seminar organizer is URM |
| `any_hispanic_organizer` | integer (0/1) | 1 if any seminar organizer is Hispanic |

---

## Raw Data Files

### `data/raw/seminar_metadata.csv` (1,881 rows)

Universe of seminar series identified for the experiment.

| Column | Description |
|---|---|
| `seminar_id` | Unique seminar identifier |
| `university` | Host university |
| `discipline` | Academic discipline |
| `department` | Department identifier |
| `condition` | Treatment/control assignment |

### `data/raw/speaker_demographics.csv` (23,456 rows)

Speaker-level demographics linked to seminars.

| Column | Description |
|---|---|
| `seminar_id` | Seminar the speaker appeared in |
| `combined_race` | Classified race/ethnicity |
| `combined_gender` | Classified gender |
| `has_demographics` | 1 if demographic data available |
| `phd_graduation_year` | PhD graduation year (if available) |
| `date` | Date of talk |
| `rank` | Academic rank (professor, associate, assistant, post-doc, grad student, non-academic) |
| `name` | Speaker name |
| `affiliation` | Speaker's institutional affiliation |
| `speaker_id` | Unique speaker identifier |

### `data/raw/treatment_assignment.csv` (568 rows)

Randomization file mapping departments to treatment conditions.

| Column | Description |
|---|---|
| `department` | Department identifier |
| `bin_category` | Randomization stratum (bin by number of seminars) |
| `condition` | Treatment or control |

### `data/raw/email_batch_assignment.csv` (1,881 rows)

Email batch assignment for staggered rollout.

| Column | Description |
|---|---|
| `seminar_id` | Seminar identifier |
| `batch_number` | Email batch (1–10) |

### `data/raw/department_faculty.csv` (568 rows)

Department-level faculty demographics from IPEDS and manual collection (2024–2025).

| Column | Description |
|---|---|
| `University` | University name |
| `Department` | Department/discipline |
| `Total Faculty Count (2024-2025)` | Total faculty |
| `URM (Black Latino NativeAmerican) Faculty Count (2024-2025)` | URM faculty count |
| `Black Faculty Count` | Black faculty count |
| `Hispanic/Latino Faculty Count` | Hispanic/Latino faculty count |
| `Women Faculty Count (2024-2025)` | Women faculty count |

### `data/raw/department_rankings.csv` (146 rows)

U.S. News discipline-specific and overall university rankings.

| Column | Description |
|---|---|
| `university` | University name |
| `physics_rank` – `me_rank` | Discipline-specific rankings |
| `general_rank` | Overall university ranking |
| `missing_physics` – `missing_me` | Flags for missing discipline rankings |

### `data/raw/email_click_tracking.csv` (1,686 rows)

Email link click data (compliance/first-stage measure).

| Column | Description |
|---|---|
| `seminar_id` | Seminar identifier |
| `clicked` | 1 if email link was clicked |
| `click_count` | Number of clicks |

### `data/raw/database_full_responses.csv` (338 rows)

Database interaction logs from users who accessed the tool.

| Column | Description |
|---|---|
| `utm_campaign` | Campaign identifier linking to department |
| `condition` | Treatment or control |
| `facultyShown` | Faculty profiles displayed |
| `peerCounts` | Peer department counts shown |

### `data/raw/database_seminar_engagement.csv` (937 rows)

Individual recipient engagement with the database tool.

| Column | Description |
|---|---|
| `recipient_id` | Email recipient identifier |
| `seminar_id` | Seminar identifier |
| `condition` | Treatment or control |

### `data/raw/speaker_database_matches.csv` (1,686 rows)

Seminar-level counts of speakers matched to URM databases, with mechanism decompositions.

| Column | Description |
|---|---|
| `seminar_id` | Seminar identifier |
| `black_from_db`, `hispanic_from_db`, `urm_from_db` | Counts of speakers matched to the database by race/ethnicity |
| `n_black_inpeer`, `n_black_outside` | Black speakers inside/outside peer window |
| `n_black_above`, `n_black_below`, `n_black_host_inst` | Black speakers by rank direction relative to host |
| `n_black_top_*`, `n_black_bot_*`, `n_nonblack_top_*`, `n_nonblack_bot_*` | Counts at top/bottom N of rankings (N = 10, 20, 50) |

### `data/raw/email_recipient_counts.csv` (568 rows)

Number of email recipients per department.

| Column | Description |
|---|---|
| `department` | Department identifier |
| `num_recipients` | Count of email recipients |

### `data/raw/email_recipient_demographics.csv` (1,586 rows)

Individual-level demographics of email recipients.

| Column | Description |
|---|---|
| `department` | Department identifier |
| `contact_type` | Role (department_chair, seminar_contact, faculty) |
| `is_female` | 1 if female |
| `is_black` | 1 if Black |
| `is_hispanic` | 1 if Hispanic |
| `is_urm` | 1 if URM |

### `data/raw/urm_faculty_databases/` (5 files, 550 profiles total)

The URM faculty databases used in the treatment intervention, one per STEM discipline: `chemistry.csv` (108), `computer_science.csv` (94), `mathematics.csv` (105), `mechanical_engineering.csv` (131), `physics.csv` (112).

All share the same schema:

| Column | Description |
|---|---|
| `Schools` | Institution name |
| `Department` | Department |
| `Link` | Profile URL |
| `Race` | Race/ethnicity |
| `Gender` | Gender |
| `Name` | Faculty name |
| `Title` | Academic title |
| `Website` | Personal website |
| `Photo.Link` | Photo URL |
| `Research.Area` | Research area |

### `data/excluded_seminars.csv` (195 rows)

Seminars excluded from the analysis sample (1,881 initial − 1,686 analysis). Same schema as `seminar_metadata.csv`.

### `data/initial_seminar_sample.csv` (1,881 rows)

Full initial sample of seminar series identified for the experiment.

| Column | Description |
|---|---|
| `seminar_id` | Seminar identifier |
| `university` | University name |
| `discipline` | Discipline |
| `seminar_name` | Name of the seminar series |
| `seminar_link` | URL to the seminar webpage |
