# generate_simulated_data.R
# Generate a small simulated dataset with the same structure as the real UKB data.
# This is intended for demonstration purposes only; values are random and not real.

set.seed(20260708)

n <- 200

# Simulate variables
sim_data <- data.frame(
  f.eid = 1:n,
  
  # Exposure groups (4 categories)
  sugar_ex_gro = factor(
    sample(c("Unexposed", "In_Utero_Only", "In_Utero_Post1yr", "In_Utero_Post2yr"),
           n, replace = TRUE, prob = c(0.30, 0.20, 0.25, 0.25)),
    levels = c("Unexposed", "In_Utero_Only", "In_Utero_Post1yr", "In_Utero_Post2yr")
  ),
  
  # Binary exposure
  sugar.g2 = factor(sample(c(0,1), n, replace = TRUE, prob = c(0.30, 0.70))),
  
  # Ordered exposure (0,1,2,3)
  sugar_ex_ordered = sample(0:3, n, replace = TRUE, prob = c(0.30, 0.20, 0.25, 0.25)),
  
  # Fine‑grained groups for event‑study plots
  birth_group_fine = factor(
    sample(c("ref_1954Jul_Dec", "expo_in_utero_only", "expo_in_utero_6mo",
             "expo_in_utero_12mo", "expo_in_utero_18mo", "expo_in_utero_24mo",
             "unexposed_1955Jan_Jun", "unexposed_1955Jul_Dec", "unexposed_1956Jan_Mar", "other"),
           n, replace = TRUE)
  ),
  
  event_study_k = sample(-3:5, n, replace = TRUE),
  
  # Covariates
  sex = factor(sample(c("Female", "Male"), n, replace = TRUE, prob = c(0.56, 0.44))),
  ethnic = factor(sample(c("White", "Non-white"), n, replace = TRUE, prob = c(0.99, 0.01))),
  birth_place = factor(sample(c("England", "Scotland", "Wales"), n, replace = TRUE, prob = c(0.86, 0.09, 0.05))),
  north_decile = factor(sample(1:10, n, replace = TRUE)),
  east_decile = factor(sample(1:10, n, replace = TRUE)),
  birth_month = factor(sample(month.name, n, replace = TRUE), levels = month.name, ordered = TRUE),
  survey_yr_centered = rnorm(n, mean = 0, sd = 1),
  
  # Family history
  only_fm_diabetes_v0 = sample(c(TRUE, FALSE), n, replace = TRUE, prob = c(0.19, 0.81)),
  only_fm_cvd_v0 = sample(c(TRUE, FALSE), n, replace = TRUE, prob = c(0.74, 0.26)),
  
  # Additional covariates (placeholders)
  age_assess = round(rnorm(n, mean = 54.6, sd = 1.6), 1),
  bmi_v0 = round(rnorm(n, mean = 27.5, sd = 5.0), 1),
  waist_v0 = round(rnorm(n, mean = 90.0, sd = 14.0), 1),
  sbp_v0 = round(rnorm(n, mean = 136, sd = 17.6), 0),
  dbp_v0 = round(rnorm(n, mean = 82, sd = 10), 0),
  blood_hba1c_v0 = round(rnorm(n, mean = 35.8, sd = 6.4), 1),
  blood_tg_v0 = round(rnorm(n, mean = 1.8, sd = 1.0), 2),
  blood_tc_v0 = round(rnorm(n, mean = 5.9, sd = 1.1), 2),
  blood_hdl_v0 = round(rnorm(n, mean = 1.5, sd = 0.4), 2),
  blood_ldl_v0 = round(rnorm(n, mean = 3.7, sd = 0.9), 2),
  blood_crp_v0 = round(rnorm(n, mean = 2.5, sd = 4.2), 2)
)

# Simulate survival outcome (Infections) with Gompertz‑like distribution
library(flexsurv)
shape <- 0.1
rate <- 0.02
coef_exp <- c(0, -0.05, -0.10, -0.15)
names(coef_exp) <- levels(sim_data$sugar_ex_gro)

lp <- coef_exp[sim_data$sugar_ex_gro] +
      ifelse(sim_data$sex == "Male", 0.1, 0) +
      ifelse(sim_data$ethnic == "Non-white", 0.05, 0)

u <- runif(n)
lambda <- rate * exp(lp)
sim_data$Infections_yr <- -log(1 - u) / lambda

# Censoring (follow‑up between 5 and 15 years)
censor_time <- runif(n, 5, 15)
sim_data$outcome_fo_birth_Diseases_of_Infections <- ifelse(sim_data$Infections_yr <= censor_time, 1, 0)
sim_data$Infections_yr <- pmin(sim_data$Infections_yr, censor_time)

# Create output directory
dir.create("data/simulated", recursive = TRUE, showWarnings = FALSE)

# Save RDS and CSV
saveRDS(sim_data, "data/simulated/simulated_data.rds")
write.csv(sim_data, "data/simulated/simulated_data.csv", row.names = FALSE)

message("Simulated dataset saved to data/simulated/simulated_data.rds (n = ", n, ")")
