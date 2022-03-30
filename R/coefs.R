
#' Coagulation coefficients
#'
#' These are coefficients intended for general use. Use
#' [fit_edwards_optim()] to optimise these coefficients
#' for a specific source water.
#'
#' @param type One of "Low DOC", "Fe", "Al", "General-Fe", "General-Al", or "empty".
#'
#' @return A named vector of empirical coefficients to be used in
#'   [coagulate()].
#' @export
#'
#' @references
#' Edwards, M. 1997. Predicting DOC removal during enhanced coagulation.
#' Journal - American Water Works Association, 89: 78–89.
#' https://doi.org/10.1002/j.1551-8833.1997.tb08229.x
#'
#' @examples
#' edwards_coefs("Low DOC")
#'
edwards_coefs <- function(type) {
  type <- match.arg(type, choices = edwards_coef_types())

  switch(
    type,
    "Fe" = c(
      x3 = 4.96, x2 = -73.9, x1 = 280,
      K1 = -0.028, K2 = 0.23,
      b = 0.068, root = -1
    ),
    "Al" = c(
      x3 = 4.91, x2 = -74.2, x1 = 284,
      K1 = -0.075, K2 = 0.56,
      b = 0.147, root = -1
    ),
    "General-Fe" = c(
      x3 = 6.42, x2 = -98.6, x1 = 383,
      K1 = -0.054, K2 = 0.54,
      b = 0.092, root = -1
    ),
    "General-Al" = c(
      x3 = 6.42, x2 = -98.6, x1 = 383,
      K1 = -0.054, K2 = 0.54,
      b = 0.145, root = -1
    ),
    "Low DOC" = c(
      x3 = 6.44, x2 = -99.2, x1 = 387,
      K1 = -0.053, K2 = 0.54,
      b = 0.107, root = -1
    ),
    # default: all NAs
    c(
      x3 = NA_real_, x2 = NA_real_, x1 = NA_real_,
      K1 = NA_real_, K2 = NA_real_,
      b = NA_real_, root = NA_real_
    )
  )
}

#' @rdname edwards_coefs
#' @export
edwards_data <- function(type) {
  type <- match.arg(type, choices = edwards_coef_types())

  # common data base: TOC approximates DOC and removing observations where
  # - outside 5-8 for alum
  # - below 4 for ferric
  # - DOC_final > (0.2 mg/L + DOC)
  # - dose == 0 (@paleolimbot added this one)
  data_base <- edwards97::edwards_jar_tests
  data_base$TOC <- data_base$DOC
  data_base$DOC_final  <- data_base$TOC_final
  data_base <- data_base[c("coagulant", "DOC", "dose", "pH", "UV254", "DOC_final")]

  alum_outside_pH <- (data_base$pH < 5) & (data_base$pH > 8) & (data_base$coagulant == "Alum")
  ferric_outside_pH <- (data_base$pH <= 4) & grepl("^Ferric", data_base$coagulant)
  low_removal <- data_base$DOC_final > (0.2 + data_base$DOC)
  zero_dose <- data_base$dose == 0

  data_base <- data_base[!alum_outside_pH & !ferric_outside_pH & !low_removal & !zero_dose, ]

  result <- switch(
    type,
    "General-Fe" = ,
    "Fe" = data_base[grepl("^Ferric", data_base$coagulant), ],
    "General-Al" = ,
    "Al" = data_base[data_base$coagulant == "Alum", ],
    "Low DOC" = data_base[data_base$DOC <= 10, ],
    # default: empty data
    data_base[numeric(0), ]
  )

  result[!is.na(result$coagulant), ]
}

#' @rdname edwards_coefs
#' @export
fit_edwards <- function(type) {
  fit <- rlang::eval_tidy(
    rlang::quo(
      fit_edwards_coefs(data = edwards_data(!!type), coefs = edwards_coefs(!!type))
    )
  )

  fit$type <- type
  class(fit) <- c("edwards_fit", class(fit))
  fit
}

edwards_coef_types <- function() {
  c("Low DOC", "Fe", "Al", "General-Fe", "General-Al", "empty")
}
