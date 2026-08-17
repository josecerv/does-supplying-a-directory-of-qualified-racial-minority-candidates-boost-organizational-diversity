# ============================================================================
# prepare_final_data.R
# Purpose: Construct final_data.csv and supplemental_data.csv from included sources
# Usage: source("01_prepare_final_data.R") from replication/code/
# Inputs:
#   - ../data/raw/*.csv
# Outputs:
#   - ../data/final_data.csv
#   - ../data/supplemental_data.csv
#   - ../data/excluded_seminars.csv (derived transparency file)
# ============================================================================

library(tidyverse)

cat("=== prepare_final_data.R ===\n")
cat("Working directory:", getwd(), "\n")

raw_dir <- "../data/raw"
out_final <- "../data/final_data.csv"
out_supplemental <- "../data/supplemental_data.csv"
recipient_demo_file <- file.path(raw_dir, "email_recipient_demographics.csv")

required_files <- c(
  file.path(raw_dir, "seminar_metadata.csv"),
  file.path(raw_dir, "speaker_demographics.csv"),
  file.path(raw_dir, "treatment_assignment.csv"),
  file.path(raw_dir, "email_batch_assignment.csv"),
  file.path(raw_dir, "department_faculty.csv"),
  file.path(raw_dir, "department_rankings.csv"),
  file.path(raw_dir, "email_click_tracking.csv"),
  file.path(raw_dir, "database_full_responses.csv"),
  file.path(raw_dir, "database_seminar_engagement.csv"),
  file.path(raw_dir, "speaker_database_matches.csv"),
  file.path(raw_dir, "urm_faculty_databases", "chemistry.csv"),
  file.path(raw_dir, "urm_faculty_databases", "computer_science.csv"),
  file.path(raw_dir, "urm_faculty_databases", "mathematics.csv"),
  file.path(raw_dir, "urm_faculty_databases", "mechanical_engineering.csv"),
  file.path(raw_dir, "urm_faculty_databases", "physics.csv"),
  file.path(raw_dir, "email_recipient_counts.csv"),
  recipient_demo_file
)

missing_required <- required_files[!file.exists(required_files)]
if (length(missing_required) > 0) {
  stop("Missing required files:\n", paste("  -", missing_required, collapse = "\n"))
}

normalize_text <- function(x) {
  str_squish(ifelse(is.na(x), "", x))
}

parse_date_flexible <- function(x) {
  d1 <- suppressWarnings(as.Date(x, format = "%m/%d/%Y"))
  d2 <- suppressWarnings(as.Date(x, format = "%m/%d/%Y %H:%M"))
  d3 <- suppressWarnings(as.Date(x, format = "%Y-%m-%d"))
  coalesce(d1, d2, d3)
}

is_nonempty_json <- function(x) {
  y <- normalize_text(x)
  y != "" & y != "[]"
}

safe_mean <- function(x) {
  if (all(is.na(x))) return(NA_real_)
  mean(x, na.rm = TRUE)
}

normalize_department_key <- function(x) {
  x %>%
    str_replace("^University of Wisconsin-Madis-", "University of Wisconsin-Madison-") %>%
    str_replace("^University of Wisconsin Madi-", "University of Wisconsin-Madison-") %>%
    str_replace("^Oklahoma State University-Physics$", "Oklahoma State University-Stillwater-Physics") %>%
    str_replace("^Oklahoma State University-Chemistry$", "Oklahoma State University-Stillwater-Chemistry") %>%
    str_replace("^University of Nebraska Lincoln-Physics$", "University of Nebraska-Lincoln-Physics")
}

# ============================================================================
# STEP 1: Core seminar + speaker data
# ============================================================================
cat("\n--- Step 1: Load seminar metadata and speaker demographics ---\n")

seminar_meta <- read_csv(
  file.path(raw_dir, "seminar_metadata.csv"),
  col_types = cols(.default = col_character()),
  locale = locale(encoding = "UTF-8")
) %>%
  transmute(
    seminar_id = normalize_text(seminar_id),
    university = normalize_text(university),
    discipline = normalize_text(discipline),
    department = normalize_text(department),
    condition = normalize_text(condition)
  ) %>%
  distinct()

speakers <- read_csv(
  file.path(raw_dir, "speaker_demographics.csv"),
  col_types = cols(.default = col_character()),
  locale = locale(encoding = "UTF-8")
) %>%
  mutate(
    seminar_id = normalize_text(seminar_id),
    combined_race = tolower(normalize_text(combined_race)),
    combined_gender = tolower(normalize_text(combined_gender)),
    has_demographics = tolower(normalize_text(has_demographics)) == "true",
    phd_graduation_year = as.numeric(phd_graduation_year),
    rank = tolower(normalize_text(rank)),
    date_parsed = parse_date_flexible(date)
  )

cat("  seminar_metadata rows:", nrow(seminar_meta), "\n")
cat("  speaker_demographics rows:", nrow(speakers), "\n")

seminars_with_speakers <- speakers %>%
  distinct(seminar_id)

# ============================================================================
# STEP 2: Canonical sample and exclusions
# ============================================================================
cat("\n--- Step 2: Canonical sample and exclusions ---\n")

canonical_excluded <- seminar_meta %>%
  anti_join(seminars_with_speakers, by = "seminar_id")

cat("  Canonical excluded seminar IDs:", nrow(canonical_excluded), "\n")

data_dir <- "../data"
write_csv(
  canonical_excluded,
  file.path(data_dir, "excluded_seminars.csv"),
  na = ""
)
cat("  Wrote ../data/excluded_seminars.csv\n")

# ============================================================================
# STEP 3: Seminar-level speaker outcomes
# ============================================================================
cat("\n--- Step 3: Speaker aggregation ---\n")

speaker_agg <- speakers %>%
  group_by(seminar_id) %>%
  summarise(
    total_speakers = n(),
    num_black = sum(combined_race == "black", na.rm = TRUE),
    num_hispanic = sum(combined_race == "latino", na.rm = TRUE),
    num_native_american = sum(combined_race == "native american", na.rm = TRUE),
    num_urm = sum(combined_race %in% c("black", "latino", "native american"), na.rm = TRUE),
    num_white = sum(combined_race == "white", na.rm = TRUE),
    num_asian = sum(combined_race == "asian", na.rm = TRUE),
    num_female = sum(combined_gender == "woman", na.rm = TRUE),
    num_male = sum(combined_gender == "man", na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    pct_black = ifelse(total_speakers > 0, 100 * num_black / total_speakers, 0),
    pct_hispanic = ifelse(total_speakers > 0, 100 * num_hispanic / total_speakers, 0),
    pct_urm = ifelse(total_speakers > 0, 100 * num_urm / total_speakers, 0),
    pct_white = ifelse(total_speakers > 0, 100 * num_white / total_speakers, 0),
    pct_asian = ifelse(total_speakers > 0, 100 * num_asian / total_speakers, 0),
    pct_native_american = ifelse(total_speakers > 0, 100 * num_native_american / total_speakers, 0),
    pct_female = ifelse(total_speakers > 0, 100 * num_female / total_speakers, 0),
    pct_male = ifelse(total_speakers > 0, 100 * num_male / total_speakers, 0),
    has_any_black = as.integer(num_black > 0),
    has_any_hispanic = as.integer(num_hispanic > 0),
    has_any_urm = as.integer(num_urm > 0),
    has_any_female = as.integer(num_female > 0),
    has_any_native_american = as.integer(num_native_american > 0),
    has_any_non_black = as.integer((total_speakers - num_black) > 0),
    num_non_black = total_speakers - num_black,
    pct_non_black = ifelse(total_speakers > 0,
      100 * (total_speakers - num_black) / total_speakers,
      0
    ),
    num_non_urm = total_speakers - num_urm
  )

cat("  Aggregated seminars:", nrow(speaker_agg), "\n")

# ============================================================================
# STEP 4: Semester outcomes
# ============================================================================
cat("\n--- Step 4: Semester outcomes ---\n")

speakers_sem <- speakers %>%
  mutate(
    semester = case_when(
      !is.na(date_parsed) & date_parsed >= as.Date("2024-07-01") & date_parsed <= as.Date("2024-12-31") ~ "fall",
      !is.na(date_parsed) & date_parsed >= as.Date("2025-01-01") & date_parsed <= as.Date("2025-06-30") ~ "spring",
      TRUE ~ NA_character_
    )
  )

semester_agg <- speakers_sem %>%
  filter(!is.na(semester)) %>%
  group_by(seminar_id, semester) %>%
  summarise(
    sem_total_speakers = n(),
    sem_num_black = sum(combined_race == "black", na.rm = TRUE),
    sem_num_hispanic = sum(combined_race == "latino", na.rm = TRUE),
    sem_num_urm = sum(combined_race %in% c("black", "latino", "native american"), na.rm = TRUE),
    sem_num_female = sum(combined_gender == "woman", na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    sem_pct_black = ifelse(sem_total_speakers > 0, 100 * sem_num_black / sem_total_speakers, 0),
    sem_pct_hispanic = ifelse(sem_total_speakers > 0, 100 * sem_num_hispanic / sem_total_speakers, 0),
    sem_pct_urm = ifelse(sem_total_speakers > 0, 100 * sem_num_urm / sem_total_speakers, 0),
    sem_pct_female = ifelse(sem_total_speakers > 0, 100 * sem_num_female / sem_total_speakers, 0),
    sem_has_any_black = as.integer(sem_num_black > 0),
    sem_has_any_hispanic = as.integer(sem_num_hispanic > 0),
    sem_has_any_urm = as.integer(sem_num_urm > 0)
  )

fall_agg <- semester_agg %>%
  filter(semester == "fall") %>%
  transmute(
    seminar_id,
    fall_total_speakers = sem_total_speakers,
    fall_num_black = sem_num_black,
    fall_num_hispanic = sem_num_hispanic,
    fall_num_urm = sem_num_urm,
    fall_num_female = sem_num_female,
    fall_pct_black = sem_pct_black,
    fall_pct_hispanic = sem_pct_hispanic,
    fall_pct_urm = sem_pct_urm,
    fall_pct_female = sem_pct_female,
    fall_has_any_black = sem_has_any_black,
    fall_has_any_hispanic = sem_has_any_hispanic,
    fall_has_any_urm = sem_has_any_urm
  )

spring_agg <- semester_agg %>%
  filter(semester == "spring") %>%
  transmute(
    seminar_id,
    spring_total_speakers = sem_total_speakers,
    spring_num_black = sem_num_black,
    spring_num_hispanic = sem_num_hispanic,
    spring_num_urm = sem_num_urm,
    spring_num_female = sem_num_female,
    spring_pct_black = sem_pct_black,
    spring_pct_hispanic = sem_pct_hispanic,
    spring_pct_urm = sem_pct_urm,
    spring_pct_female = sem_pct_female,
    spring_has_any_black = sem_has_any_black,
    spring_has_any_hispanic = sem_has_any_hispanic,
    spring_has_any_urm = sem_has_any_urm
  )

semester_wide <- speaker_agg %>%
  select(seminar_id) %>%
  left_join(fall_agg, by = "seminar_id") %>%
  left_join(spring_agg, by = "seminar_id") %>%
  mutate(
    across(starts_with("fall_"), ~replace_na(., 0)),
    across(starts_with("spring_"), ~replace_na(., 0)),
    has_fall_speakers = as.integer(fall_total_speakers > 0),
    has_spring_speakers = as.integer(spring_total_speakers > 0),
    has_any_black_fall = fall_has_any_black,
    has_any_black_spring = spring_has_any_black,
    has_any_urm_fall = fall_has_any_urm,
    has_any_urm_spring = spring_has_any_urm,
    has_any_hispanic_fall = fall_has_any_hispanic,
    has_any_hispanic_spring = spring_has_any_hispanic
  )

# ============================================================================
# STEP 5: Assignment variables
# ============================================================================
cat("\n--- Step 5: Treatment assignment and batch variables ---\n")

treatment_assign <- read_csv(
  file.path(raw_dir, "treatment_assignment.csv"),
  col_types = cols(.default = col_character())
) %>%
  transmute(
    department = normalize_text(department),
    condition = normalize_text(condition),
    bin_category = normalize_text(bin_category),
    treatment = as.integer(condition == "treatment"),
    bin_0_1 = as.integer(bin_category == "[0,1]"),
    bin_1_3 = as.integer(bin_category == "(1,3]"),
    bin_3_5 = as.integer(bin_category == "(3,5]"),
    bin_5_7 = as.integer(bin_category == "(5,7]"),
    bin_7_11 = as.integer(bin_category == "(7,11]"),
    bin_11_17 = as.integer(bin_category == "(11,17]")
  )

batch_assign <- read_csv(
  file.path(raw_dir, "email_batch_assignment.csv"),
  col_types = cols(.default = col_character())
) %>%
  transmute(
    seminar_id = normalize_text(seminar_id),
    batch_number = as.integer(as.numeric(batch_number)),
    batch_1 = as.integer(batch_number == 1),
    batch_2 = as.integer(batch_number == 2),
    batch_3 = as.integer(batch_number == 3),
    batch_4 = as.integer(batch_number == 4),
    batch_5 = as.integer(batch_number == 5),
    batch_6 = as.integer(batch_number == 6),
    batch_7 = as.integer(batch_number == 7),
    batch_8 = as.integer(batch_number == 8),
    batch_9 = as.integer(batch_number == 9)
  )

# ============================================================================
# STEP 6: Department faculty variables
# ============================================================================
cat("\n--- Step 6: Department faculty characteristics ---\n")

dept_faculty <- read_csv(
  file.path(raw_dir, "department_faculty.csv"),
  col_types = cols(.default = col_character()),
  locale = locale(encoding = "UTF-8")
) %>%
  transmute(
    department = normalize_department_key(normalize_text(paste0(University, "-", Department))),
    total_faculty = as.numeric(`Total Faculty Count (2024-2025)`),
    urm_faculty = as.numeric(`URM (Black, Latino, NativeAmerican) Faculty Count (2024-2025)`),
    black_faculty_raw = as.numeric(`Black Faculty Count`),
    hispanic_faculty_raw = as.numeric(`Hispanic/Latino Faculty Count`),
    women_faculty = as.numeric(`Women Faculty Count (2024-2025)`)
  ) %>%
  mutate(
    total_faculty = replace_na(total_faculty, 0),
    urm_faculty = replace_na(urm_faculty, 0),
    women_faculty = replace_na(women_faculty, 0),
    black_faculty = case_when(
      !is.na(black_faculty_raw) ~ black_faculty_raw,
      urm_faculty == 0 ~ 0,
      TRUE ~ NA_real_
    ),
    hispanic_faculty = case_when(
      !is.na(hispanic_faculty_raw) ~ hispanic_faculty_raw,
      urm_faculty == 0 ~ 0,
      !is.na(black_faculty) ~ pmax(urm_faculty - black_faculty, 0),
      TRUE ~ NA_real_
    ),
    frac_black_faculty = ifelse(total_faculty > 0, black_faculty / total_faculty, 0),
    frac_hispanic_faculty = ifelse(total_faculty > 0, hispanic_faculty / total_faculty, 0),
    frac_urm_faculty = ifelse(total_faculty > 0, urm_faculty / total_faculty, 0),
    frac_women_faculty = ifelse(total_faculty > 0, women_faculty / total_faculty, 0),
    pct_black_faculty = frac_black_faculty * 100,
    pct_hispanic_faculty = frac_hispanic_faculty * 100,
    has_urm_faculty = as.integer(urm_faculty > 0),
    has_women_faculty = as.integer(women_faculty > 0),
    frac_native_faculty = pmax(frac_urm_faculty - frac_black_faculty - frac_hispanic_faculty, 0)
  ) %>%
  select(-black_faculty_raw, -hispanic_faculty_raw)

dept_quartile <- dept_faculty %>%
  distinct(department, frac_black_faculty) %>%
  arrange(frac_black_faculty, department) %>%
  mutate(
    black_faculty_quartile = if_else(
      is.na(frac_black_faculty),
      NA_integer_,
      ntile(row_number(), 4L)
    )
  ) %>%
  select(department, black_faculty_quartile)

# ============================================================================
# STEP 7: Rankings and peer department variables
# ============================================================================
cat("\n--- Step 7: Rankings and peer department variables ---\n")

dept_rankings <- read_csv(
  file.path(raw_dir, "department_rankings.csv"),
  col_types = cols(.default = col_character())
) %>%
  mutate(
    university = normalize_text(university),
    across(c(physics_rank, chemistry_rank, math_rank, cs_rank, me_rank, general_rank), ~as.numeric(.x)),
    across(c(missing_physics, missing_chemistry, missing_math, missing_cs, missing_me), ~as.integer(.x))
  )

missing_rank_sets <- list(
  Physics = dept_rankings %>% filter(missing_physics == 1L) %>% pull(university),
  Chemistry = dept_rankings %>% filter(missing_chemistry == 1L) %>% pull(university),
  Mathematics = dept_rankings %>% filter(missing_math == 1L) %>% pull(university),
  `Computer Science` = dept_rankings %>% filter(missing_cs == 1L) %>% pull(university),
  `Mechanical Engineering` = dept_rankings %>% filter(missing_me == 1L) %>% pull(university)
)

discipline_rank_map <- c(
  "Physics" = "physics_rank",
  "Chemistry" = "chemistry_rank",
  "Mathematics" = "math_rank",
  "Computer Science" = "cs_rank",
  "Mechanical Engineering" = "me_rank"
)

discipline_db_map <- c(
  "Physics" = "physics",
  "Chemistry" = "chemistry",
  "Mathematics" = "mathematics",
  "Computer Science" = "computer_science",
  "Mechanical Engineering" = "mechanical_engineering"
)

urm_dbs <- list()
for (disc_name in names(discipline_db_map)) {
  db_file <- file.path(raw_dir, "urm_faculty_databases", paste0(discipline_db_map[[disc_name]], ".csv"))
  urm_dbs[[disc_name]] <- read_csv(db_file, col_types = cols(.default = col_character())) %>%
    transmute(university = normalize_text(Schools)) %>%
    group_by(university) %>%
    summarise(n_urm = n(), .groups = "drop")
}

compute_peer_urm <- function(univ, disc, rankings_df, urm_dbs_list) {
  rank_col <- discipline_rank_map[[disc]]
  if (is.null(rank_col) || !(rank_col %in% names(rankings_df))) {
    return(tibble(total_peer_departments = NA_integer_, total_urm_peer_faculty = NA_integer_))
  }

  ranked_universities <- rankings_df %>%
    filter(!is.na(!!sym(rank_col))) %>%
    arrange(!!sym(rank_col), university) %>%
    pull(university) %>%
    unique()

  focal_idx <- match(univ, ranked_universities)
  if (is.na(focal_idx)) {
    return(tibble(total_peer_departments = NA_integer_, total_urm_peer_faculty = NA_integer_))
  }

  n_ranked <- length(ranked_universities)
  lower_idx <- max(1L, focal_idx - 20L)
  upper_idx <- min(n_ranked, focal_idx + 20L)

  get_peers <- function(lo, hi) {
    ranked_universities[seq.int(lo, hi)] %>%
      setdiff(univ)
  }

  # Ensure at least 40 peer departments by expanding near boundaries.
  peers <- get_peers(lower_idx, upper_idx)
  while (length(peers) < 40L && (lower_idx > 1L || upper_idx < n_ranked)) {
    if (lower_idx > 1L) lower_idx <- lower_idx - 1L
    if (upper_idx < n_ranked) upper_idx <- upper_idx + 1L
    peers <- get_peers(lower_idx, upper_idx)
  }

  urm_db <- urm_dbs_list[[disc]]
  if (is.null(urm_db)) {
    return(tibble(total_peer_departments = length(peers), total_urm_peer_faculty = 0L))
  }

  count_peer_urm <- function(peer_universities, urm_data) {
    if (length(peer_universities) == 0) return(0L)
    peer_tbl <- tibble(university = peer_universities) %>%
      left_join(urm_data, by = "university") %>%
      mutate(n_urm = replace_na(n_urm, 0))
    as.integer(sum(peer_tbl$n_urm, na.rm = TRUE))
  }

  total_urm <- count_peer_urm(peers, urm_db)

  # If fewer than 20 URM faculty are available, iteratively expand by one rank
  # above and one below until threshold is met or bounds are exhausted.
  while (total_urm < 20L && (lower_idx > 1L || upper_idx < n_ranked)) {
    if (lower_idx > 1L) lower_idx <- lower_idx - 1L
    if (upper_idx < n_ranked) upper_idx <- upper_idx + 1L
    peers <- get_peers(lower_idx, upper_idx)
    total_urm <- count_peer_urm(peers, urm_db)
  }

  tibble(
    total_peer_departments = length(peers),
    total_urm_peer_faculty = total_urm
  )
}

univ_disc_pairs <- seminar_meta %>%
  distinct(university, discipline)

peer_results <- univ_disc_pairs %>%
  rowwise() %>%
  mutate(peer_data = list(compute_peer_urm(university, discipline, dept_rankings, urm_dbs))) %>%
  unnest(peer_data) %>%
  ungroup()

ranking_data <- univ_disc_pairs %>%
  left_join(dept_rankings, by = "university") %>%
  mutate(
    dept_ranking_raw = case_when(
      discipline == "Physics" ~ physics_rank,
      discipline == "Chemistry" ~ chemistry_rank,
      discipline == "Mathematics" ~ math_rank,
      discipline == "Computer Science" ~ cs_rank,
      discipline == "Mechanical Engineering" ~ me_rank,
      TRUE ~ NA_real_
    ),
    # Pre-registration: replace missing discipline rank with general rank,
    # and keep an indicator for that missingness event.
    missing_dept_rank = case_when(
      discipline == "Physics" ~ as.integer(university %in% missing_rank_sets$Physics | is.na(dept_ranking_raw)),
      discipline == "Chemistry" ~ as.integer(university %in% missing_rank_sets$Chemistry | is.na(dept_ranking_raw)),
      discipline == "Mathematics" ~ as.integer(university %in% missing_rank_sets$Mathematics | is.na(dept_ranking_raw)),
      discipline == "Computer Science" ~ as.integer(university %in% missing_rank_sets$`Computer Science` | is.na(dept_ranking_raw)),
      discipline == "Mechanical Engineering" ~ as.integer(university %in% missing_rank_sets$`Mechanical Engineering` | is.na(dept_ranking_raw)),
      TRUE ~ as.integer(is.na(dept_ranking_raw))
    ),
    dept_ranking = case_when(
      missing_dept_rank == 1L ~ general_rank,
      TRUE ~ dept_ranking_raw
    ),
    dept_ranking = coalesce(dept_ranking, general_rank),
    general_ranking = general_rank,
    dept_ranking_raw = NULL
  ) %>%
  select(university, discipline, dept_ranking, general_ranking, missing_dept_rank) %>%
  left_join(peer_results, by = c("university", "discipline"))

# ============================================================================
# STEP 8: Engagement and click variables
# ============================================================================
cat("\n--- Step 8: Engagement and click variables ---\n")

click_tracking <- read_csv(
  file.path(raw_dir, "email_click_tracking.csv"),
  col_types = cols(.default = col_character())
) %>%
  transmute(
    seminar_id = normalize_text(seminar_id),
    bitly_clicked = as.integer(as.numeric(clicked) > 0),
    bitly_click_count = as.integer(replace_na(as.numeric(click_count), 0))
  )

database_full <- read_csv(
  file.path(raw_dir, "database_full_responses.csv"),
  col_types = cols(.default = col_character())
) %>%
  mutate(
    utm_campaign = normalize_text(utm_campaign),
    condition = normalize_text(condition),
    facultyShown = if_else(is.na(facultyShown), "", facultyShown),
    peerCounts = if_else(is.na(peerCounts), "", peerCounts)
  )

database_eng <- read_csv(
  file.path(raw_dir, "database_seminar_engagement.csv"),
  col_types = cols(.default = col_character()),
  comment = "#"
) %>%
  transmute(
    recipient_id = normalize_text(recipient_id),
    seminar_id = normalize_text(seminar_id),
    condition = normalize_text(condition)
  )

treatment_recipients_with_access <- database_full %>%
  filter(condition == "treatment") %>%
  filter(is_nonempty_json(facultyShown) | is_nonempty_json(peerCounts)) %>%
  pull(utm_campaign) %>%
  unique()

control_recipients_with_access <- database_full %>%
  filter(condition == "control") %>%
  filter(is_nonempty_json(peerCounts)) %>%
  pull(utm_campaign) %>%
  unique()

treatment_access <- database_eng %>%
  filter(condition == "treatment", recipient_id %in% treatment_recipients_with_access) %>%
  distinct(seminar_id) %>%
  mutate(accessed_database = 1L)

control_access <- database_eng %>%
  filter(condition == "control", recipient_id %in% control_recipients_with_access) %>%
  distinct(seminar_id) %>%
  mutate(accessed_dept_database = 1L)

engagement <- seminar_meta %>%
  select(seminar_id, condition) %>%
  left_join(treatment_access, by = "seminar_id") %>%
  left_join(control_access, by = "seminar_id") %>%
  mutate(
    accessed_database = if_else(condition == "treatment", replace_na(accessed_database, 0L), 0L),
    accessed_dept_database = if_else(condition == "control", replace_na(accessed_dept_database, 0L), 0L)
  ) %>%
  select(seminar_id, accessed_database, accessed_dept_database)

# ============================================================================
# STEP 9: Recipient demographics
# ============================================================================
cat("\n--- Step 9: Recipient demographics ---\n")

recipient_counts <- read_csv(
  file.path(raw_dir, "email_recipient_counts.csv"),
  col_types = cols(department = col_character(), num_recipients = col_integer())
) %>%
  mutate(department = normalize_text(department))

recipient_demo <- read_csv(
  recipient_demo_file,
  col_types = cols(
    .default = col_character(),
    is_female = col_double(),
    is_black = col_double(),
    is_hispanic = col_double(),
    is_urm = col_double()
  )
) %>%
  mutate(
    department = normalize_text(department),
    contact_type = normalize_text(contact_type)
  )

recipient_all <- recipient_demo %>%
  group_by(department) %>%
  summarise(
    frac_recipients_female = safe_mean(is_female),
    frac_recipients_black = safe_mean(is_black),
    frac_recipients_hispanic = safe_mean(is_hispanic),
    frac_recipients_urm = safe_mean(is_urm),
    .groups = "drop"
  )

recipient_chair <- recipient_demo %>%
  filter(contact_type == "department_chair") %>%
  group_by(department) %>%
  summarise(
    frac_dept_chair_female = safe_mean(is_female),
    frac_dept_chair_black = safe_mean(is_black),
    frac_dept_chair_hispanic = safe_mean(is_hispanic),
    frac_dept_chair_urm = safe_mean(is_urm),
    .groups = "drop"
  )

recipient_organizer <- recipient_demo %>%
  filter(contact_type %in% c("seminar_contact", "faculty")) %>%
  group_by(department) %>%
  summarise(
    frac_seminar_organizer_female = safe_mean(is_female),
    frac_seminar_organizer_black = safe_mean(is_black),
    frac_seminar_organizer_hispanic = safe_mean(is_hispanic),
    frac_seminar_organizer_urm = safe_mean(is_urm),
    .groups = "drop"
  )

recipient_vars <- recipient_counts %>%
  left_join(recipient_all, by = "department") %>%
  left_join(recipient_chair, by = "department") %>%
  left_join(recipient_organizer, by = "department") %>%
  mutate(
    pct_hispanic_recipients = 100 * frac_recipients_hispanic
  )

# ============================================================================
# STEP 10: Database-attribution and mechanism outcomes
# ============================================================================
cat("\n--- Step 10: Database-attribution and mechanism outcomes ---\n")

db_matches <- read_csv(
  file.path(raw_dir, "speaker_database_matches.csv"),
  col_types = cols(.default = col_character())
) %>%
  transmute(
    seminar_id = normalize_text(seminar_id),
    black_from_db_raw = as.integer(replace_na(as.numeric(black_from_db), 0)),
    hispanic_from_db_raw = as.integer(replace_na(as.numeric(hispanic_from_db), 0)),
    urm_from_db_raw = as.integer(replace_na(as.numeric(urm_from_db), 0)),
    # Mechanism: peer window
    n_black_inpeer_raw  = as.integer(replace_na(as.numeric(n_black_inpeer), 0)),
    n_black_outside_raw = as.integer(replace_na(as.numeric(n_black_outside), 0)),
    n_hispanic_inpeer_raw  = as.integer(replace_na(as.numeric(n_hispanic_inpeer), 0)),
    n_hispanic_outside_raw = as.integer(replace_na(as.numeric(n_hispanic_outside), 0)),
    n_urm_inpeer_raw  = as.integer(replace_na(as.numeric(n_urm_inpeer), 0)),
    n_urm_outside_raw = as.integer(replace_na(as.numeric(n_urm_outside), 0)),
    # Mechanism: rank direction
    n_black_above_raw = as.integer(replace_na(as.numeric(n_black_above), 0)),
    n_black_below_raw = as.integer(replace_na(as.numeric(n_black_below), 0)),
    # Mechanism: host institution
    n_black_host_inst_raw = as.integer(replace_na(as.numeric(n_black_host_inst), 0)),
    # Mechanism: top-N / bottom-N
    n_black_top_10_raw  = as.integer(replace_na(as.numeric(n_black_top_10), 0)),
    n_black_bot_10_raw  = as.integer(replace_na(as.numeric(n_black_bot_10), 0)),
    n_black_top_20_raw  = as.integer(replace_na(as.numeric(n_black_top_20), 0)),
    n_black_bot_20_raw  = as.integer(replace_na(as.numeric(n_black_bot_20), 0)),
    n_black_top_50_raw  = as.integer(replace_na(as.numeric(n_black_top_50), 0)),
    n_black_bot_50_raw  = as.integer(replace_na(as.numeric(n_black_bot_50), 0)),
    n_nonblack_top_10_raw = as.integer(replace_na(as.numeric(n_nonblack_top_10), 0)),
    n_nonblack_bot_10_raw = as.integer(replace_na(as.numeric(n_nonblack_bot_10), 0)),
    n_nonblack_top_20_raw = as.integer(replace_na(as.numeric(n_nonblack_top_20), 0)),
    n_nonblack_bot_20_raw = as.integer(replace_na(as.numeric(n_nonblack_bot_20), 0)),
    n_nonblack_top_50_raw = as.integer(replace_na(as.numeric(n_nonblack_top_50), 0)),
    n_nonblack_bot_50_raw = as.integer(replace_na(as.numeric(n_nonblack_bot_50), 0))
  )

# ============================================================================
# STEP 11: Merge all data
# ============================================================================
cat("\n--- Step 11: Merge all variables ---\n")

combined <- seminar_meta %>%
  left_join(treatment_assign, by = c("department", "condition")) %>%
  left_join(batch_assign, by = "seminar_id") %>%
  left_join(speaker_agg, by = "seminar_id") %>%
  left_join(semester_wide, by = "seminar_id") %>%
  left_join(dept_faculty, by = "department") %>%
  left_join(dept_quartile, by = "department") %>%
  left_join(ranking_data, by = c("university", "discipline")) %>%
  left_join(click_tracking, by = "seminar_id") %>%
  left_join(engagement, by = "seminar_id") %>%
  left_join(recipient_vars, by = "department") %>%
  left_join(db_matches, by = "seminar_id")

cat("  Rows before canonical sample filter:", nrow(combined), "\n")

combined <- combined %>%
  filter(seminar_id %in% seminars_with_speakers$seminar_id) %>%
  mutate(
    across(c(
      treatment,
      starts_with("bin_"),
      starts_with("batch_"),
      bitly_clicked,
      bitly_click_count,
      accessed_database,
      accessed_dept_database,
      black_from_db_raw,
      hispanic_from_db_raw,
      urm_from_db_raw,
      n_black_inpeer_raw, n_black_outside_raw,
      n_hispanic_inpeer_raw, n_hispanic_outside_raw,
      n_urm_inpeer_raw, n_urm_outside_raw,
      n_black_above_raw, n_black_below_raw, n_black_host_inst_raw,
      n_black_top_10_raw, n_black_bot_10_raw,
      n_black_top_20_raw, n_black_bot_20_raw,
      n_black_top_50_raw, n_black_bot_50_raw,
      n_nonblack_top_10_raw, n_nonblack_bot_10_raw,
      n_nonblack_top_20_raw, n_nonblack_bot_20_raw,
      n_nonblack_top_50_raw, n_nonblack_bot_50_raw
    ), ~replace_na(., 0)),

    # Database origin (corrected with fuzzy matching)
    num_black_from_db = pmin(black_from_db_raw, replace_na(num_black, 0)),
    num_hispanic_from_db = pmin(hispanic_from_db_raw, replace_na(num_hispanic, 0)),
    num_urm_from_db = pmin(urm_from_db_raw, replace_na(num_urm, 0)),

    has_any_black_from_db = as.integer(num_black_from_db > 0),
    has_any_hispanic_from_db = as.integer(num_hispanic_from_db > 0),
    has_any_urm_from_db = as.integer(num_urm_from_db > 0),

    pct_black_from_db = ifelse(total_speakers > 0, 100 * num_black_from_db / total_speakers, 0),
    pct_hispanic_from_db = ifelse(total_speakers > 0, 100 * num_hispanic_from_db / total_speakers, 0),
    pct_urm_from_db = ifelse(total_speakers > 0, 100 * num_urm_from_db / total_speakers, 0),

    num_black_not_from_db = num_black - num_black_from_db,
    num_hispanic_not_from_db = num_hispanic - num_hispanic_from_db,
    num_urm_not_from_db = num_urm - num_urm_from_db,

    pct_black_not_from_db = ifelse(total_speakers > 0, 100 * num_black_not_from_db / total_speakers, 0),
    pct_hispanic_not_from_db = ifelse(total_speakers > 0, 100 * num_hispanic_not_from_db / total_speakers, 0),
    pct_urm_not_from_db = ifelse(total_speakers > 0, 100 * num_urm_not_from_db / total_speakers, 0),

    black_from_db = num_black_from_db,

    # Mechanism: peer window
    num_black_inpeer  = n_black_inpeer_raw,
    num_black_outside = n_black_outside_raw,
    pct_black_inpeer  = ifelse(total_speakers > 0, 100 * n_black_inpeer_raw / total_speakers, 0),
    pct_black_outside = ifelse(total_speakers > 0, 100 * n_black_outside_raw / total_speakers, 0),
    num_hispanic_inpeer  = n_hispanic_inpeer_raw,
    num_hispanic_outside = n_hispanic_outside_raw,
    pct_hispanic_inpeer  = ifelse(total_speakers > 0, 100 * n_hispanic_inpeer_raw / total_speakers, 0),
    pct_hispanic_outside = ifelse(total_speakers > 0, 100 * n_hispanic_outside_raw / total_speakers, 0),
    num_urm_inpeer  = n_urm_inpeer_raw,
    num_urm_outside = n_urm_outside_raw,
    pct_urm_inpeer  = ifelse(total_speakers > 0, 100 * n_urm_inpeer_raw / total_speakers, 0),
    pct_urm_outside = ifelse(total_speakers > 0, 100 * n_urm_outside_raw / total_speakers, 0),

    # Mechanism: rank direction
    num_black_above = n_black_above_raw,
    num_black_below = n_black_below_raw,
    pct_black_above = ifelse(total_speakers > 0, 100 * n_black_above_raw / total_speakers, 0),
    pct_black_below = ifelse(total_speakers > 0, 100 * n_black_below_raw / total_speakers, 0),

    # Mechanism: host institution
    num_black_host_inst = n_black_host_inst_raw,
    pct_black_host_inst = ifelse(total_speakers > 0, 100 * n_black_host_inst_raw / total_speakers, 0),

    # Mechanism: top-N / bottom-N
    num_black_top_10  = n_black_top_10_raw,
    num_black_bot_10  = n_black_bot_10_raw,
    num_black_top_20  = n_black_top_20_raw,
    num_black_bot_20  = n_black_bot_20_raw,
    num_black_top_50  = n_black_top_50_raw,
    num_black_bot_50  = n_black_bot_50_raw,
    num_nonblack_top_10 = n_nonblack_top_10_raw,
    num_nonblack_bot_10 = n_nonblack_bot_10_raw,
    num_nonblack_top_20 = n_nonblack_top_20_raw,
    num_nonblack_bot_20 = n_nonblack_bot_20_raw,
    num_nonblack_top_50 = n_nonblack_top_50_raw,
    num_nonblack_bot_50 = n_nonblack_bot_50_raw,

    # Unranked: residual (speakers with no ranked affiliation, excluding host institution)
    num_black_unranked = pmax(0L, as.integer(replace_na(num_black, 0) - n_black_above_raw - n_black_below_raw - n_black_host_inst_raw)),
    pct_black_unranked = ifelse(total_speakers > 0,
        100 * pmax(0, replace_na(num_black, 0) - n_black_above_raw - n_black_below_raw - n_black_host_inst_raw) / total_speakers, 0),

    # Combined unranked and host institution speakers
    num_black_missing_rank = pmax(0L, as.integer(replace_na(num_black, 0) - n_black_above_raw - n_black_below_raw)),
    pct_black_missing_rank = ifelse(total_speakers > 0,
        100 * pmax(0, replace_na(num_black, 0) - n_black_above_raw - n_black_below_raw) / total_speakers, 0),

    department_std = paste0(university, "-", discipline),
    disc_chemistry = as.integer(discipline == "Chemistry"),
    disc_computer_science = as.integer(discipline == "Computer Science"),
    disc_mathematics = as.integer(discipline == "Mathematics"),
    disc_mechanical_engineering = as.integer(discipline == "Mechanical Engineering"),
    disc_physics = as.integer(discipline == "Physics"),

    n_seminars = 1L,
    num_distinct_seminars = 1L,
    total_pct = 100L,

    db_access_combined = ifelse(treatment == 1, accessed_database, accessed_dept_database),

    any_black_organizer = as.integer(!is.na(frac_seminar_organizer_black) & frac_seminar_organizer_black > 0),
    any_urm_organizer = as.integer(!is.na(frac_seminar_organizer_urm) & frac_seminar_organizer_urm > 0),
    any_hispanic_organizer = as.integer(!is.na(frac_seminar_organizer_hispanic) & frac_seminar_organizer_hispanic > 0)
  )

cat("  Rows after canonical sample filter:", nrow(combined), "\n")

# ============================================================================
# STEP 12: Validation
# ============================================================================
cat("\n--- Step 12: Validation ---\n")

stopifnot(nrow(combined) == 1686)
stopifnot(all(combined$seminar_id != ""))
stopifnot(all(combined$condition %in% c("control", "treatment")))
stopifnot(all((combined$condition == "control" & combined$treatment == 0) |
              (combined$condition == "treatment" & combined$treatment == 1)))

stopifnot(all(combined$num_black_above + combined$num_black_below +
              combined$num_black_host_inst + combined$num_black_unranked ==
              replace_na(combined$num_black, 0)))
cat("  Validation passed (N = 1,686)\n")

# ============================================================================
# STEP 13: Export manuscript and supplemental datasets
# ============================================================================
cat("\n--- Step 13: Export ---\n")

manuscript_cols <- c(
  "seminar_id", "university", "discipline", "department", "department_std",
  "condition", "treatment",
  "bin_0_1", "bin_1_3", "bin_3_5", "bin_5_7", "bin_7_11", "bin_11_17",
  "batch_1", "batch_2", "batch_3", "batch_4", "batch_5",
  "batch_6", "batch_7", "batch_8", "batch_9",
  "pct_urm", "num_urm", "has_any_urm",
  "pct_black", "num_black", "has_any_black",
  "pct_hispanic", "num_hispanic", "has_any_hispanic",
  "total_speakers",
  "fall_pct_black", "fall_num_black", "has_any_black_fall",
  "spring_pct_black", "spring_num_black", "has_any_black_spring",
  "fall_pct_urm", "fall_num_urm", "has_any_urm_fall",
  "spring_pct_urm", "spring_num_urm", "has_any_urm_spring",
  "fall_pct_hispanic", "fall_num_hispanic", "has_any_hispanic_fall",
  "spring_pct_hispanic", "spring_num_hispanic", "has_any_hispanic_spring",
  "accessed_database", "accessed_dept_database", "db_access_combined",
  "bitly_clicked", "bitly_click_count",
  "pct_black_from_db", "num_black_from_db", "has_any_black_from_db",
  "num_black_not_from_db", "pct_black_not_from_db",
  "num_black_inpeer", "pct_black_inpeer", "num_black_outside", "pct_black_outside",
  "num_hispanic_inpeer", "pct_hispanic_inpeer", "num_hispanic_outside", "pct_hispanic_outside",
  "num_urm_inpeer", "pct_urm_inpeer", "num_urm_outside", "pct_urm_outside",
  "num_black_above", "pct_black_above", "num_black_below", "pct_black_below",
  "num_black_host_inst", "pct_black_host_inst",
  "num_black_unranked", "pct_black_unranked",
  "num_black_missing_rank", "pct_black_missing_rank",
  "total_faculty", "frac_urm_faculty", "frac_women_faculty",
  "frac_black_faculty", "frac_hispanic_faculty", "frac_native_faculty",
  "dept_ranking", "missing_dept_rank",
  "total_urm_peer_faculty", "total_peer_departments",
  "num_recipients", "black_faculty",
  "frac_recipients_female", "frac_recipients_urm",
  "frac_recipients_black", "frac_recipients_hispanic",
  "frac_dept_chair_female", "frac_dept_chair_urm",
  "frac_dept_chair_black", "frac_dept_chair_hispanic",
  "frac_seminar_organizer_female", "frac_seminar_organizer_urm",
  "frac_seminar_organizer_black", "frac_seminar_organizer_hispanic",
  "pct_hispanic_recipients"
)

supplemental_extra_cols <- c(
  "num_non_urm", "num_non_black", "pct_non_black",
  "disc_chemistry", "disc_computer_science", "disc_mathematics",
  "disc_mechanical_engineering", "disc_physics",
  "n_seminars",
  "any_black_organizer", "any_urm_organizer", "any_hispanic_organizer",
  "num_hispanic_from_db", "pct_hispanic_from_db", "has_any_hispanic_from_db",
  "num_urm_from_db", "pct_urm_from_db", "has_any_urm_from_db",
  "num_hispanic_not_from_db", "pct_hispanic_not_from_db",
  "num_urm_not_from_db", "pct_urm_not_from_db",
  "black_faculty_quartile"
)

missing_manuscript_cols <- setdiff(manuscript_cols, names(combined))
if (length(missing_manuscript_cols) > 0) {
  stop("Missing manuscript columns: ", paste(missing_manuscript_cols, collapse = ", "))
}

supplemental_cols <- c(manuscript_cols, supplemental_extra_cols)
missing_supp_cols <- setdiff(supplemental_cols, names(combined))
if (length(missing_supp_cols) > 0) {
  stop("Missing supplemental columns: ", paste(missing_supp_cols, collapse = ", "))
}

final_out <- combined %>%
  select(all_of(manuscript_cols))

supplemental_out <- combined %>%
  select(all_of(supplemental_cols))

write_csv(final_out, out_final, na = "")
write_csv(supplemental_out, out_supplemental, na = "")

cat("  Wrote", out_final, ":", nrow(final_out), "rows x", ncol(final_out), "columns\n")
cat("  Wrote", out_supplemental, ":", nrow(supplemental_out), "rows x", ncol(supplemental_out), "columns\n")
cat("\n=== prepare_final_data.R complete ===\n")
