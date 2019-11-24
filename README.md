
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
fit_data_alum <- edwards_jar_tests %>% 
  filter(coagulant == "Alum")

# Use TOC measurements as estimates of final DOC
fit_data_alum$DOC_final <- fit_data_alum$TOC_final

# optimise coefficients for this dataset
fit <- fit_edwards_optim(fit_data_alum, initial_coefs = edwards_coefs("alum"))

# view fit results
print(fit)
#> <edwards_fit_optim>
#>   Coefficients:
#>     K1 = -0.00524, K2 = -0.188, x1 = 382, x2 = -96.4, x3 = 6.23, b = 0.0343, root = -1
#>   Performance:
#>     r² = 0.961, RMSE = 1.11 mg/L, degrees of freedom = 527
#>   Input data:
#>       DOC              dose               pH            UV254       
#>  Min.   : 1.800   Min.   :0.00000   Min.   :4.500   Min.   :0.0260  
#>  1st Qu.: 2.900   1st Qu.:0.06734   1st Qu.:6.072   1st Qu.:0.0810  
#>  Median : 4.000   Median :0.16835   Median :6.590   Median :0.1200  
#>  Mean   : 6.595   Mean   :0.21998   Mean   :6.540   Mean   :0.1975  
#>  3rd Qu.: 8.600   3rd Qu.:0.32338   3rd Qu.:7.018   3rd Qu.:0.2060  
#>  Max.   :26.500   Max.   :1.51515   Max.   :8.830   Max.   :1.3550  
#>  NA's   :383                                                        
#>    DOC_final     
#>  Min.   : 0.760  
#>  1st Qu.: 2.070  
#>  Median : 2.690  
#>  Mean   : 3.835  
#>  3rd Qu.: 4.001  
#>  Max.   :30.500  
#> 
plot(fit)
```

<img src="man/figures/README-example-1.png" width="100%" />

## References

Edwards, M. 1997. Predicting DOC removal during enhanced coagulation.
Journal - American Water Works Association, 89: 78–89.
<https://doi.org/10.1002/j.1551-8833.1997.tb08229.x>
