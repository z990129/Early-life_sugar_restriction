# UK Biobank Analysis Code

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21262897.svg)](https://doi.org/10.5281/zenodo.21262897)

This branch contains the complete analytical code for the UK Biobank component of the manuscript:

> **Early‑Life Sugar Restriction, Multi‑omics Architecture, and Multisystem Resilience: A Natural Experiment**  
> Yiwei Zhang, Dan Chen, Xiaolong Liang, et al.  
> Preprint: https://doi.org/10.64898/2026.04.30.26352133  
> *Under review at **Nature Human Behaviour***

---

## Repository Structure

```
.
├── analysis.R              # Main analysis pipeline
├── functions/
│   ├── helpers.R           # Custom helper functions (recode_*, get_fields, etc.)
│   ├── survival_utils.R    # calculate_results, model fitting wrappers
│   └── mediation_utils.R   # Mediation analysis functions
├── data/
│   └── simulated/
│       └── demo_data.csv   # Small anonymised demonstration dataset (see Demo section)
├── output/                 # Generated results (CSV files)
└── README.md               # This file
```

---

## System Requirements

- **R version**: 4.1.1 or higher (tested on 4.1.1 and 4.3.0)
- **Operating systems**: Windows 10/11, macOS 12+, Ubuntu 20.04/22.04 (all tested)
- **Non‑standard hardware**: None required

### Required R Packages

```r
install.packages(c(
  "tidyverse",
  "survival",
  "flexsurv",
  "glmnet",
  "mediation",
  "tableone",
  "ggplot2",
  "gridExtra",
  "kableExtra",
  "lubridate",
  "data.table"
))
```

---

## Installation Guide

1. **Clone the repository and switch to this branch**:

```bash
git clone https://github.com/z990129/Early-life_sugar_restriction.git
cd Early-life_sugar_restriction
git checkout UKB
```

2. **Set up R environment**:

```r
# Option A: Using renv (if renv.lock is provided)
renv::restore()

# Option B: Manual installation (see list above)
install.packages(c("tidyverse", "survival", "flexsurv", "glmnet", "mediation", "tableone", "ggplot2", "gridExtra", "kableExtra", "lubridate", "data.table"))
```

3. **Configure file paths**:

In `analysis.R`, change the `setwd()` line to point to your project root:

```r
setwd('/path/to/your/Early-life_sugar_restriction/UKB')
```

---

## Demo: Running on the Provided Anonymised Dataset

We include a small, fully anonymised demonstration dataset (`demo_data.csv`) in `data/simulated/`. This dataset contains the same variable structure as the real UK Biobank data, but with all values perturbed and participant IDs replaced. It is intended solely for testing the code without requiring actual UK Biobank access.

**To run the demo using this dataset:**

```r
# Load the demo data
demo <- read.csv("data/simulated/demo_data.csv")

# Ensure factor variables are correctly set
demo$sex <- factor(demo$sex)
demo$ethnic <- factor(demo$ethnic)
demo$birth_place <- factor(demo$birth_place)
demo$north_decile <- factor(demo$north_decile)
demo$east_decile <- factor(demo$east_decile)
demo$birth_month <- factor(demo$birth_month, levels = month.name, ordered = TRUE)

# Example: Fit a Gompertz survival model for Infections
library(flexsurv)
fit <- flexsurvreg(
  Surv(Infections_yr, outcome_fo_birth_Diseases_of_Infections) ~
    sugar_ex_gro + sex + ethnic,
  data = demo,
  dist = "gompertz"
)
summary(fit)
```

**Expected workflow:**

- Data loading (200 rows)
- Exposure assignment (`sugar_ex_gro`, `sugar.g2`, `event_study_k`) – variables already present
- Covariate processing
- Survival models for infection outcomes (Gompertz)
- Output results to console

**Expected output (illustrative):**

| Outcome | HR (95% CI) | P value |
|:---|:---|:---|
| Diseases of Infections | 0.92 (0.88–0.96) | <0.001 |

> **Note**: Results from the demo data will differ from manuscript values because the data have been artificially generated and perturbed.

**Expected run time (demo):** ~1 minute on a standard desktop.

---

## Reproduction: Full Manuscript Results

### Data access

To reproduce the manuscript results, you must apply for UK Biobank data access:

- **Application number**: 73201
- **Website**: https://www.ukbiobank.ac.uk/
- **Required data**: All variables listed in Supplementary Table S2 (available in the paper's supplementary materials)

Once obtained, place the RDS files in the `data/` directory as follows:

```
data/
├── withdraw.RDS          # withdrawn participant IDs
├── recode.RDS            # recoded baseline data
├── birth_year.RDS        # year of birth (Field 34)
├── birth_month.RDS       # month of birth (Field 52)
├── outcome_all.rds       # all outcome definitions
├── PA.RDS                # physical activity data
├── PRS/                  # polygenic risk scores
└── protein/              # proteomics data (Olink)
```

### Running the full analysis

```r
# 1. Set use_simulated = FALSE in analysis.R
use_simulated <- FALSE

# 2. Run the pipeline
source("analysis.R")
```

**Generated outputs:**

- Table 1: baseline characteristics
- Table 2: association results for all disease categories
- Figure 2: event‑study temporal dynamics
- Supplementary Tables S6–S21 (various sensitivity and subgroup analyses)

**Expected run time (full data):** ~2–3 hours on a standard desktop.

---

## Key Methods Summary

| Component | Method | Implementation |
|:---|:---|:---|
| Exposure definition | Birth‑date relative to sugar rationing end (Sept 1953) | `birth_group_fine`, `sugar_ex_gro` |
| Primary outcome model | Gompertz parametric survival | `flexsurvreg(dist = "gompertz")` |
| Multiple testing | Benjamini‑Hochberg FDR | `p.adjust(method = "BH")` |
| Feature selection | LASSO regression | `cv.glmnet(alpha = 1)` |
| Mediation analysis | Product‑of‑coefficients (1000 bootstrap resamples) | `mediation::mediate()` |
| Internal validation | Propensity score matching (sex + race) | Custom matching function |
| Sensitivity | Additional adjustment for perinatal/adult factors | Model 2 + covariates |

---

## Custom Function Dependencies

The following custom functions are defined in `functions/` and `sourced` in `analysis.R`:

| Function | Location | Purpose |
|:---|:---|:---|
| `get_fields()` | `helpers.R` | Retrieve UKB fields from RDS files |
| `recode_unknow()` | `helpers.R` | Recode "Do not know" / "Prefer not to answer" to NA |
| `recodeVar()` | `helpers.R` | General value recoding |
| `calculate_results()` | `survival_utils.R` | Extract HR, CI, P from `flexsurvreg` output |
| `cox.analysis.f()` | `survival_utils.R` | Wrapper for Cox regression with formatted output |
| `t1.f()` | `helpers.R` | Table 1 formatting with kable |
| `fmd_all()` | `helpers.R` | Family history disease parsing |

---

## License

This code is released under the MIT License. See the `LICENSE` file in the root of this repository for details.

---

## Contact

- **Issues**: https://github.com/z990129/Early-life_sugar_restriction/issues
- **Corresponding author**: Xianhui Qin (pharmaqin@126.com)

---

## Citation

If you use this code, please cite:

> Zhang Y, Chen D, Liang X, et al. Early‑Life Sugar Restriction, Multi‑omics Architecture, and Multisystem Resilience: A Natural Experiment. *Preprint*. 2026. doi:10.64898/2026.04.30.26352133

And the code archive:

> z990129. (2026). z990129/Early-life_sugar_restriction: v1.0.0. Zenodo. https://doi.org/10.5281/zenodo.21262897

---

*Last updated: July 2026*
```
