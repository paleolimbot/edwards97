
#' Calculate the dose of diminishing return
#'
#' @inheritParams coagulate
#' @param DOC_final The final DOC concentration, probably modeled using [fit_edwards_optim()]
#'   or [fit_edwards()] and [coagulate_grid()].
#' @param molar_mass The moalr mass of the coagulant, in grams per mol Al or Fe.
#' @param threshold The point of diminishing return threshold, in mg/L DOC per mg/L dose.
#'   Often this is taken to be 0.3 mg/L DOC per 10 mg/L dose (Brantby 2016).
#' @param criterion A desired final DOC concentration in mg/L
#'
#' @return The dose (in mmol/L) of diminishing returns.
#' @export
#'
#' @references
#' Bratby, J. 2016. Coagulation and Flocculation in Water and Wastewater Treatment.
#' IWA Publishing. https://books.google.ca/books?id=PabQDAAAQBAJ
#'
#' @examples
#' dose_curve <- coagulate_grid(fit_edwards("Low DOC"), DOC = 4, UV254 = 0.2, pH = 5.5)
#' dose_of_diminishing_returns(dose_curve$dose, dose_curve$DOC_final)
#' dose_for_criterion(dose_curve$dose, dose_curve$DOC_final, criterion = 3)
#'
dose_of_diminishing_returns <- function(dose, DOC_final, molar_mass = 297, threshold = 0.3 / 10) {
  tbl <- prepare_dose_tbl(dose, DOC_final)
  if (nrow(tbl) < 3) {
    return(NA_real_)
  }

  # convert mmol/L to mg/L
  tbl$dose_mg_L <- tbl$dose / 1000 * molar_mass * 1000

  lagged <- c(1, seq_len(nrow(tbl) - 1))
  lead <- c(seq_len(nrow(tbl))[-1], nrow(tbl))

  tbl$slope <- -(tbl$DOC_final[lead] - tbl$DOC_final[lagged]) /
    (tbl$dose_mg_L[lead] - tbl$dose_mg_L[lagged])

  stats::approx(
    x = tbl$slope,
    y = tbl$dose,
    xout = threshold
  )$y
}

#' @rdname dose_of_diminishing_returns
#' @export
dose_for_criterion <- function(dose, DOC_final, criterion) {
  tbl <- prepare_dose_tbl(dose, DOC_final)
  if (nrow(tbl) < 2) {
    return(NA_real_)
  }

  stats::approx(
    x = tbl$DOC_final,
    y = tbl$dose,
    xout = criterion
  )$y
}

prepare_dose_tbl <- function(dose, DOC_final) {
  tbl <- tibble::tibble(dose, DOC_final)
  tbl <- tbl[is.finite(tbl$dose) & is.finite(tbl$DOC_final), ]
  tbl[order(tbl$dose), ]
}
