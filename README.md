
<!-- README.md is generated from README.Rmd. Please edit that file -->

# edwards97

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![Travis build
status](https://travis-ci.org/paleolimbot/edwards97.svg?branch=master)](https://travis-ci.org/paleolimbot/edwards97)
[![Codecov test
coverage](https://codecov.io/gh/paleolimbot/edwards97/branch/master/graph/badge.svg)](https://codecov.io/gh/paleolimbot/edwards97?branch=master)
<!-- badges: end -->

The goal of edwards97 is to implement the Edwards (1997) Langmuir-based
semiempirical coagulation model, which predicts the concentration of
organic carbon remaining in water after treatment with an Al- or
Fe-based coagulant. Methods and example data are provided to optimise
empirical coefficients.

This package is experimental, under constant development, and is in no
way guaranteed to give accurate predictions (yet).

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("paleolimbot/edwards97")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(edwards97)

# `edwards_jar_tests` is included
fit_data_alum <- edwards_jar_tests[edwards_jar_tests$coagulant == "Alum", ]

# Use TOC measurements as estimates of final DOC
fit_data_alum$DOC_final <- fit_data_alum$TOC_final

# optimise coefficients for this dataset
fit <- fit_edwards_optim(fit_data_alum, initial_coefs = edwards_coefs("alum"))

# add predictions to the original data frame
fit_data_alum$DOC_final_predict <- predict(fit)

# plot predictions
ggplot(fit_data_alum) +
  geom_abline(slope = 1, intercept = 0, lty = 2, alpha = 0.7) + 
  geom_point(aes(DOC_final, DOC_final_predict))
```

<img src="man/figures/README-example-1.png" width="100%" />

## References

Edwards, M. 1997. Predicting DOC removal during enhanced coagulation.
Journal - American Water Works Association, 89: 78–89.
<https://doi.org/10.1002/j.1551-8833.1997.tb08229.x>