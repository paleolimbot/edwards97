
#' Low-level langmuir coagulation calculations
#'
#' The Edwards (1997) model is a Langmuir‐based semiempirical model designed to predict
#' OC removal during alum coagulation. The model is on a non-linear function
#' derived from physical relationships, primarily the process of
#' Langmuir sorptive removal (Tipping 1981, Jekyl 1986).
#'
#' @param coefs The output of [edwards_coefs()] or a similar data frame
#'   containing columns `K1`, `K2`, `x1`, `x2`, `x3`, `b` and `root`. Must contain
#'   one row or the same number of rows as `data`.
#' @param data A data frame containing columns `DOC`, `dose`, `pH`, and `UV254`.
#' @param DOC The initial DOC concentration (mg/L).
#' @param dose The coagulant dose (mmol/L).
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
#' alum_jar_tests <- edwards_jar_tests[edwards_jar_tests$coagulant == "Alum", ]
#' alum_jar_tests$TOC_final_model <- coagulate(alum_jar_tests, edwards_coefs("alum"))
#' plot(TOC_final_model ~ TOC_final, data = alum_jar_tests)
#'
coagulate <- function(data, coefs = edwards_coefs()) {
  # using tibble() here enforces the 1-row or same-row numbers
  input <- tibble::tibble(
    !!!data[c("DOC", "dose", "pH", "UV254")],
    !!!coefs[c("K1", "K2", "x1", "x2", "x3", "b", "root")]
  )

  rlang::exec(coagulate_base, !!!input)
}

#' @rdname coagulate
#' @export
coagulate_base <- function(DOC, dose, pH, UV254, K1, K2, x1, x2, x3, b, root = -1) {

  # allows root to be theoretically continuous for the purposes of optim()
  root <- sign(root)

  SUVA <- 100 * UV254 / DOC
  S <- 1 - SUVA * K1 - K2
  a <- pH^3 * x3 + pH^2 * x2 + pH * x1

  first_term <- -(DOC * S * b - 1 - dose * a * b)
  sqrt_term <- sqrt((DOC * S * b - 1 - dose * a * b)^2 - 4 * (-b * DOC * S))
  denominator <- 2 * (-b)

  (first_term + root * sqrt_term) / denominator
}
