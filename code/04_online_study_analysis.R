# Reproduce Supplemental Tables S13 and S14 from aggregate condition moments.
# Base R only. No individual participant data are required or reconstructed.
args <- commandArgs(trailingOnly = FALSE)
script_arg <- grep("^--file=", args, value = TRUE)
root <- if (length(script_arg)) {
  dirname(dirname(normalizePath(sub("^--file=", "", script_arg[1]))))
} else if (file.exists("../data/online_study/condition_moments.csv")) {
  normalizePath("..")
} else {
  normalizePath(".")
}
input <- file.path(root, "data", "online_study", "condition_moments.csv")
out <- file.path(root, "code", "tables", "online_study")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
write_csv <- function(value, path) {
  connection <- file(path, open = "wb")
  on.exit(close(connection))
  write.csv(value, connection, row.names = FALSE, eol = "\n")
}
d <- read.csv(input, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(all(c("model", "condition", "n", "mean", "sd") %in% names(d)))
stopifnot(all(d$n > 1), all(d$sd >= 0), all(is.finite(d$mean)))

models <- c("belief_main", "salience_main", "consideration_main",
            "salience_sensitivity", "consideration_sensitivity")
conditions <- c("Pure Control", "URM Directory Treatment", "Directory Control")
terms <- c("Constant", "URM Directory Treatment", "Directory Control")
coefs <- contrasts <- fits <- list()

for (model in models) {
  g <- d[d$model == model, ]
  stopifnot(nrow(g) == 3L, setequal(g$condition, conditions))
  g <- g[match(conditions, g$condition), ]
  n <- sum(g$n)
  df <- n - 3
  # The saturated three-condition model fits each condition mean. Within-group
  # sums of squares therefore suffice for its ordinary residual variance.
  sse <- sum((g$n - 1) * g$sd^2)
  grand_mean <- sum(g$n * g$mean) / n
  sst <- sse + sum(g$n * (g$mean - grand_mean)^2)
  sigma2 <- sse / df
  x <- rbind(c(1, 0, 0), c(1, 1, 0), c(1, 0, 1))
  vcov <- sigma2 * solve(t(x) %*% diag(g$n) %*% x)
  b <- c(g$mean[1], g$mean[2] - g$mean[1], g$mean[3] - g$mean[1])
  se <- sqrt(diag(vcov))
  tval <- b / se
  critical <- qt(.975, df)
  coefs[[model]] <- data.frame(model, term = terms, estimate = b, se,
    t = tval, df, p = 2 * pt(-abs(tval), df),
    ci_lower = b - critical * se, ci_upper = b + critical * se)
  restrictions <- rbind(c(0, 1, 0), c(0, 0, 1), c(0, 1, -1))
  contrast_labels <- c("URM Directory Treatment - Pure Control",
    "Directory Control - Pure Control", "URM Directory Treatment - Directory Control")
  estimates <- as.vector(restrictions %*% b)
  contrast_se <- sqrt(diag(restrictions %*% vcov %*% t(restrictions)))
  contrast_t <- estimates / contrast_se
  contrasts[[model]] <- data.frame(model, contrast = contrast_labels,
    estimate = estimates, se = contrast_se, t = contrast_t, df,
    p = 2 * pt(-abs(contrast_t), df),
    ci_lower = estimates - critical * contrast_se,
    ci_upper = estimates + critical * contrast_se,
    wald_F = contrast_t^2, wald_df1 = 1, wald_df2 = df,
    wald_p = pf(contrast_t^2, 1, df, lower.tail = FALSE))
  r2 <- 1 - sse / sst
  f <- ((sst - sse) / 2) / sigma2
  fits[[model]] <- data.frame(model, n, residual_df = df, r_squared = r2,
    adjusted_r_squared = 1 - (1 - r2) * (n - 1) / df,
    residual_standard_error = sqrt(sigma2), sse, sst,
    omnibus_F = f, omnibus_df1 = 2, omnibus_df2 = df,
    omnibus_p = pf(f, 2, df, lower.tail = FALSE))
}
coefs <- do.call(rbind, coefs)
contrasts <- do.call(rbind, contrasts)
fits <- do.call(rbind, fits)
write_csv(coefs, file.path(out, "coefficients.csv"))
write_csv(contrasts, file.path(out, "contrasts.csv"))
write_csv(fits, file.path(out, "model_summary.csv"))
write_csv(d, file.path(out, "condition_descriptives.csv"))

stars <- function(p) ifelse(p < .001, "***", ifelse(p < .01, "**", ifelse(p < .05, "*", "")))
ptext <- function(p) ifelse(p < .001, "< .001", sub("^0", "", sprintf("%.3f", p)))
display <- function(model) {
  c <- coefs[coefs$model == model, ]
  c <- c[match(c("URM Directory Treatment", "Directory Control", "Constant"), c$term), ]
  f <- fits[fits$model == model, ]
  k <- contrasts[contrasts$model == model &
    contrasts$contrast == "URM Directory Treatment - Directory Control", ]
  c(sprintf("%.2f%s (%.2f)", c$estimate, stars(c$p), c$se),
    as.character(f$n), sprintf("%.3f", f$r_squared), sprintf("%.3f", f$adjusted_r_squared),
    sprintf("%.2f", k$estimate), sprintf("%.2f", k$se),
    sprintf("[%.2f, %.2f]", k$ci_lower, k$ci_upper),
    sprintf("%.2f", k$wald_F), ptext(k$wald_p))
}
rows <- c("URM Directory Treatment", "Directory Control", "Constant", "Observations",
  "R-squared", "Adjusted R-squared", "Treatment - Directory Control",
  "Contrast standard error", "95% confidence interval", "Wald F", "Wald p")
matrix <- data.frame(row = rows, stringsAsFactors = FALSE, check.names = FALSE)
for (model in models) matrix[[model]] <- display(model)
write_csv(matrix[c("row", "belief_main")], file.path(out, "Table_S13_belief.csv"))
write_csv(matrix[c("row", models[-1])], file.path(out, "Table_S14_salience.csv"))
cat("Reproduced Tables S13/S14 and numerical audit files for five models.\n")
