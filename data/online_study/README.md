# Supplemental online experiment: aggregate replication data

The final experiment was fielded September 21, 2026. The recruitment report was 600 U.S.-based Prolific participants. The survey recorded 599 unique randomized respondents. The main analyses use the 554 respondents with valid belief responses, applying the preregistered missing-belief exclusion. The 45 remaining respondents lack a valid belief response. The preregistered target was 600 valid belief responses, so the realized valid-belief sample fell 46 short. Both salience outcomes were observed for all 599 recorded randomized respondents, which supports the separately labeled sensitivity analyses.

## Conditions and outcomes

The URM Directory Treatment condition supplied a directory of 20 Black STEM professors. The Directory Control condition supplied faculty-directory links for the same 20 departments. Both directory conditions included the same encouragement to diversify. Pure Control supplied neither encouragement nor a search resource. Participants nominated six professors before reporting beliefs and salience. Nominations are not an outcome in these tables.

- Belief: post-treatment estimate of the percentage of U.S. STEM professors who are Black, on a 0–100 scale. The study did not elicit a baseline belief, so these are between-condition differences in posterior beliefs rather than measured within-person changes.
- Three-item attention measure: mean of three responses adapted from the cognitive-engagement items in Rich et al. (2010), each on a 1–7 scale. All three items must be observed for the mean.
- Consideration item: separate 1–7 response adapted from Chang et al. (2020). It is not combined with the three attention items.

## Files and variables

`condition_moments.csv` contains 15 aggregate rows, one for each of three conditions in five model/sample combinations. It contains no participant-level records.

| Variable | Meaning |
|---|---|
| `model` | `belief_main`, `salience_main`, `consideration_main`, `salience_sensitivity`, or `consideration_sensitivity` |
| `condition` | Pure Control, URM Directory Treatment, or Directory Control |
| `n` | Number of observations contributing to that condition/outcome/sample |
| `mean` | Arithmetic condition mean |
| `sd` | Sample standard deviation, with denominator `n - 1` |

The three `main` models use 554 valid-belief respondents: 187 Pure Control, 191 URM Directory Treatment, and 176 Directory Control. The two sensitivity models use all 599 recorded randomized respondents: 199, 209, and 191, respectively.

## Reproduction

Run `Rscript code/04_online_study_analysis.R` from the repository root. Only base R is required. The script produces Tables S13 and S14 as CSVs and full-precision coefficient, contrast, model-summary, and condition-descriptive CSVs in `code/tables/online_study/`.

Each OLS model includes an intercept and indicators for URM Directory Treatment and Directory Control, with Pure Control omitted. It uses ordinary model-based standard errors, two-sided t tests, t-based 95% confidence intervals, and a one-restriction Wald F test for the treatment-minus-directory-control contrast. There are no covariates, weights, robust covariance corrections, imputations, or multiplicity adjustments.

Condition sample sizes, means, and standard deviations are sufficient to reconstruct these condition-only OLS results. The residual sum of squares is the sum of `(n - 1) * sd^2` across conditions. Coefficients are the reference-condition mean and differences from that mean. This allows reproduction without simulating or reconstructing individual observations.

The package reproduces the reported five OLS models and condition descriptives, but does not independently audit participant exclusions, the item-level attention composite, scale reliability, demographics, randomization records, or resource use. It cannot support alternative participant-level models, robust standard errors, mediation analyses, or linking responses across outcomes. The released summaries are limited to the information needed for the reported tables.

## Provenance and preregistration

The aggregate input was computed from the final September 22, 2026 export at 14:54:54 UTC. Its SHA-256 is `5a64b12bceaf8a84ccbb25c3e35b35670e001be4a13fd35568a4b5f79aee3921`. That export is byte-identical to the previously verified export at 01:11:54 UTC that day. No pilot responses are included. The source export itself is not released here.

The experiment was preregistered on September 19, 2026, as [AsPredicted #312433, “STEM Faculty Belief Updating and Salience”](https://aspredicted.org/hc3jy8.pdf). The linked PDF withholds the three authors' identities for review. The repository's root `Preregistration.pdf` documents the earlier field experiment and is not the preregistration for this online study.

## References

Rich BL, LePine JA, Crawford ER (2010) Job engagement: Antecedents and effects on job performance. Acad. Management J. 53(3):617–635. https://doi.org/10.5465/amj.2010.51468988

Chang EH, Kirgios EL, Rai A, Milkman KL (2020) The isolated choice effect and its implications for gender diversity in organizations. Management Sci. 66(6):2752–2761. https://doi.org/10.1287/mnsc.2019.3533
