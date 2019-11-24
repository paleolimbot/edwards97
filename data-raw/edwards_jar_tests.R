
library(tidyverse)
library(readxl)

# ---- Read 9x9, wrangle names ----

jartest_raw <- read_excel(
  "data-raw/9X9.XLS",
  sheet = "Using TOC",
  range = "A11:Z1429",
  col_types = "text"
)

cols <- names(jartest_raw)

# equivalent weights
cols[2:7] <- paste0(
  "eqw_",
  names(jartest_raw[2:7]) %>% str_to_lower() %>% str_replace_all("\\s+", "_")
)

# raw water quality
cols[8:14] <- paste0(
  "raw_",
  c("TOC", "DOC", "UV254", "alkalinity", "turbidity", "pH", "temp")
)

# treatment conditions
cols[15:21] <- c(
  "coag_dose_mg_L", "coag_dose_mmol_L",
  "base_other_dose_mg_L", "acid_dose_mg_L", "coag_pH",
  "settling_time_min", "filtration"
)

# treated water qualities
cols[22:26] <- c("treat_turbidity", "treat_TOC", "treat_UV254", "filter_TOC", "filter_UV254")


names(jartest_raw) <- cols

# ---- wrangle column data ----

jartests_clean <- jartest_raw %>%
  # these are blank columns
  select(-eqw_soda_ash, -eqw_lime) %>%
  # NAs are represented in a few ways
  mutate_all(~replace(., . %in% c("--", "", "NA"), NA)) %>%
  # the acid dose column has some codes that are difficult to pin down
  extract(acid_dose_mg_L, "acid_dose_flag", "^([A-Za-z]+)", remove = FALSE) %>%
  mutate(acid_dose_mg_L = replace(acid_dose_mg_L, !is.na(acid_dose_flag), NA)) %>%
  # most columns are numbers
  mutate_at(vars(-filtration, -acid_dose_flag), parse_number) %>%
  mutate(
    filtration = filtration == "Yes",
    coagulant = case_when(
      eqw_coagulant %in% c(162.2, 270.2) ~ "Ferric chloride",
      eqw_coagulant == 280.8 ~ "Ferric sulfate",
      eqw_coagulant == 245 ~ "Unknown non-alum",
      TRUE ~ "Alum"
    )
  )

# ---- subset and export ----

edwards_data_raw <- jartests_clean %>%
  select(coagulant, coag_dose_mmol_L, coag_pH, starts_with("treat"), starts_with("raw")) %>%
  filter(coagulant %in% c("Alum", "Ferric chloride", "Ferric sulfate"))

edwards_jar_tests <- tibble::tibble(
  coagulant = edwards_data_raw$coagulant,
  dose_mmol_L = edwards_data_raw$coag_dose_mmol_L,
  DOC_initial_mg_L = edwards_data_raw$raw_DOC,
  TOC_initial_mg_L = edwards_data_raw$raw_TOC,
  pH  = edwards_data_raw$coag_pH,
  UV254_per_cm = edwards_data_raw$raw_UV254,
  TOC_final_mg_L = edwards_data_raw$treat_TOC
)

usethis::use_data(edwards_jar_tests, overwrite = TRUE)
