
#' Low-level langmuir coagulation calculations
#'
#' The Edwards (1997) model is a Langmuir-based semiempirical model designed to predict
#' OC removal during alum coagulation. The model is on a non-linear function
#' derived from physical relationships, primarily the process of
#' Langmuir sorptive removal (Tipping 1981, Jekyl 1986).
#'
#' @param coefs The output of [edwards_coefs()] or a similar named vector
#'   containing elements `K1`, `K2`, `x1`, `x2`, `x3`, `b` and `root`.
#' @param data A data frame containing columns `DOC`, `dose`, `pH`, and `UV254`.
#' @param DOC The initial DOC concentration (mg/L).
#' @param dose The coagulant metal concentration (Al3+ or Fe3+) in mmol/L.
#' @param pH The pH of coagulation.
#' @param UV254 The absorbance of UV254 (1/cm). With `DOC`,
#'   used to calculate SUVA.
#' @param K1,K2 Empirical fitting coefficients relating to SUVA.
#' @param x1,x2,x3 Empirical fitting coefficients relating to pH.
#' @param b The Langmuir term.
#' @param root The solution to the equation presented in Edwards (1997) is
#'   a quadratic with two roots. `root` can be 1 or -1 to account for these roots,
#'   however we see no evidence that anything except -1 here results in realistic
#'   predictions.
#'
#' @return A vector of predicted organic carbon concentrations (in mg/L) following
#'   coagulation.
#'
#' @references
#' Edwards, M. 1997. Predicting DOC removal during enhanced coagulation.
#' Journal - American Water Works Association, 89: 78–89.
#' https://doi.org/10.1002/j.1551-8833.1997.tb08229.x
#'
#' Jekel, M.R. 1986. Interactions of humic acids and aluminum salts
#' in the flocculation process. Water Research, 20: 1535-1542.
#' https://doi.org/10.1016/0043-1354(86)90118-1
#'
#' Tipping, E. 1981. The adsorption of aquatic humic substances by iron oxides.
#' Geochimica et Cosmochimica Acta, 45: 191-199.
#' https://doi.org/10.1016/0016-7037(81)90162-9
#'
#' @export
#'
#' @examples
#' alum_jar_tests <- edwards_data("Al")
#' alum_jar_tests$DOC_final_model <- coagulate(alum_jar_tests, edwards_coefs("Al"))
#' plot(DOC_final_model ~ DOC_final, data = alum_jar_tests)
#'
coagulate <- function(data, coefs) {
  rlang::exec(
    coagulate_base,
    !!!data[c("DOC", "dose", "pH", "UV254")],
    !!!as.list(coefs[c("K1", "K2", "x1", "x2", "x3", "b", "root")])
  )
}

#' @rdname coagulate
#' @export
coagulate_base <- function(DOC, dose, pH, UV254, K1, K2, x1, x2, x3, b, root = -1) {

  # allows root to be theoretically continuous for the purposes of optim()
  root <- sign(root)

  # dose values of 0 violate the original equation whose solution is below
  dose[dose == 0] <- NA_real_

  SUVA <- 100 * UV254 / DOC
  non_sorbable_DOC <- DOC * (K1 * SUVA + K2)
  S <- 1 - SUVA * K1 - K2
  a <- pH^3 * x3 + pH^2 * x2 + pH * x1

  first_term <- -(DOC * S * b - 1 - dose * a * b)
  sqrt_term <- sqrt((DOC * S * b - 1 - dose * a * b)^2 - 4 * (-b * DOC * S))
  denominator <- 2 * (-b)

  DOC_final <- (first_term + root * sqrt_term) / denominator
  DOC_final + non_sorbable_DOC
}

coag_non_sorbable_DOC <- function(DOC, UV254, K1, K2) {
  SUVA <- 100 * UV254 / DOC
  fraction_non_sorbable <- K1 * SUVA + K2
  fraction_non_sorbable * DOC
}

coag_sorbable_DOC <- function(DOC, UV254, K1, K2) {
  DOC - coag_non_sorbable_DOC(DOC, UV254, K1, K2)
}

coag_langmuir_a <- function(pH, x3, x2, x1) {
  pH^3 * x3 + pH^2 * x2 + pH * x1
}

coag_SUVA <- function(DOC, UV254) {
  100 * UV254 / DOC
}
