
#' Coagulation coefficients
#'
#' @param type Currently only "alum" is implemented.
#'
#' @return A data frame of coefficients that
#' @export
#'
#' @examples
#' edwards_coefs("alum")
#'
edwards_coefs <- function(type = c("alum", "NA")) {
  type <- match.arg(type)

  switch(
    type,
    "alum" = tibble::tibble(
      K1 = -0.054, K2 = 0.54,
      x1 = 383, x2 = -98.6, x3 = 6.42,
      b = 0.107, root = -1
    ),
    "NA" = tibble::tibble(
      K1 = NA_real_, K2 = NA_real_,
      x1 = NA_real_, x2 = NA_real_, x3 = NA_real_,
      b = NA_real_, root = NA_real_
    )
  )
}
