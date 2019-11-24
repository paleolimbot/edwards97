
#' Fit Empirical Coefficients
#'
#' The coefficients calculated by Edwards (1997) and returned by
#' [edwards_coefs()] were designed to produce reasonable results
#' for several general cases, however each source water will have
#' a set of empirical coefficients that produce more accurate
#' predictions than the general case. This function calculates
#' the optimal coefficients given a test set of known initial
#' values (DOC)
#'
#' @param data A data frame with columns
#'   `DOC` (mg/L), `dose` (mmol/L), `pH` (pH units), `UV254` (1/cm), and
#'   `DOC_final` (mg/L). See [coagulate()] for more information.
#' @param initial_coefs A set of initial coefficients from which to
#'   start the optimisation. Most usefully one of the coefficient
#'   sets returned by [edwards_coefs()].
#' @param optim_params Additional arguments to be passed to [stats::optim()].
#' @param object,x A fit objected created with [fit_edwards_optim()].
#' @param newdata A data frame with columns
#'   `DOC` (mg/L), `dose` (mmol/L), `pH` (pH units), and `UV254` (1/cm). If
#'   omitted, the data used to fit the model is used.
#' @param ... Not used.
#'
#' @return An S3 of type "edwards_fit_optim" with components:
#' \describe{
#'   \item{data, initial_coefs, optim_params}{References to inputs.}
#'   \item{fit_optim}{The fit object returned by [stats::optim()].}
#' }
#'
#' @export
#'
fit_edwards_optim <- function(data, initial_coefs = edwards_coefs(), optim_params = list()) {

  # need to improve error messages for bad inputs, but this is one way to
  # make it work
  data <- data[c("DOC", "dose", "pH", "UV254", "DOC_final")]

  edwards_MSE_fitted <- function(par) {
    fitted <- coagulate(data, par)
    mean((fitted - data$DOC_final)^2, na.rm = TRUE)
  }

  fit_optim <- suppressWarnings(
    rlang::exec(
      stats::optim,
      # initial parameter values
      initial_coefs,
      # the function to optimise
      edwards_MSE_fitted,
      # additional parameters
      !!!optim_params
    )
  )

  structure(
    list(
      data = data,
      initial_coefs = initial_coefs,
      optim_params = optim_params,
      fit_optim = fit_optim
    ),
    class = c("edwards_fit_optim", "edwards_fit")
  )
}

#' @importFrom stats coef
#' @rdname fit_edwards_optim
#' @export
coef.edwards_fit_optim <- function(object, ...) {
  coefs <- object$fit_optim$par
  coefs["root"] <- sign(coefs["root"])
  coefs
}

#' @importFrom stats predict
#' @rdname fit_edwards_optim
#' @export
predict.edwards_fit <- function(object, newdata = NULL, ...) {
  if (is.null(newdata)) {
    newdata <- object$data
  }

  coagulate(newdata, coef(object))
}

#' @importFrom stats fitted
#' @rdname fit_edwards_optim
#' @export
fitted.edwards_fit <- function(object, ...) {
  predict(object, ...)
}

#' @importFrom stats residuals
#' @rdname fit_edwards_optim
#' @export
residuals.edwards_fit <- function(object, ...) {
  predict(object, ...) - object$data$DOC_final
}

#' @importFrom broom tidy
#' @rdname fit_edwards_optim
#' @export
tidy.edwards_fit <- function(x, ...) {
  tibble::enframe(coef(x), name = "term", value = "estimate")
}

#' @importFrom broom glance
#' @rdname fit_edwards_optim
#' @export
glance.edwards_fit <- function(x, ...) {
  known <- x$data$DOC_final
  predicted <- predict(x, ...)
  residuals <- predicted - known
  n_obs <- sum(is.finite(residuals))

  tibble::tibble(
    fit_method = class(x)[1],
    r.squared = stats::cor(predicted, known, method = "pearson", use = "pairwise.complete.obs"),
    # number of coefs = 7
    df.residual = n_obs - 7,
    # deviance is the sum of the squared residuals
    deviance = sum(residuals^2, na.rm = TRUE)
  )
}