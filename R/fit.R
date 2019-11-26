
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
#' @inheritParams coagulate
#' @param data A data frame with columns
#'   `DOC` (mg/L), `dose` (mmol/L), `pH` (pH units), `UV254` (1/cm), and
#'   `DOC_final` (mg/L). See [coagulate()] for more information.
#' @param coefs,initial_coefs A set of initial coefficients from which to
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
fit_edwards_optim <- function(data, initial_coefs = edwards_coefs("Al"), optim_params = list()) {

  data_label <- rlang::quo_label(rlang::enquo(data))

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
      title = glue::glue("Fit optimised for {data_label}"),
      data = data,
      initial_coefs = initial_coefs,
      optim_params = optim_params,
      fit_optim = fit_optim
    ),
    class = c("edwards_fit_optim", "edwards_fit_base")
  )
}

#' @rdname fit_edwards_optim
#' @export
fit_edwards_coefs <- function(coefs, data = edwards_data("empty")) {
  data_label <- rlang::quo_label(rlang::enquo(data))
  coefs_label <- rlang::quo_label(rlang::enquo(coefs))

  structure(
    list(
      title = c(
        glue::glue("Fit with coefs {coefs_label}"),
        glue::glue("validated using {data_label}")
      ),
      data = data,
      coefs = coefs
    ),
    class = c("edwards_fit_coefs", "edwards_fit_base")
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

#' @importFrom stats coef
#' @rdname fit_edwards_optim
#' @export
coef.edwards_fit_coefs <- function(object, ...) {
  object$coefs
}

#' @importFrom stats predict
#' @rdname fit_edwards_optim
#' @export
predict.edwards_fit_base <- function(object, newdata = NULL, ...) {
  if (is.null(newdata)) {
    newdata <- object$data
  }

  coagulate(newdata, coef(object))
}

#' @rdname fit_edwards_optim
#' @export
coagulate_grid <- function(object, DOC, UV254, dose = seq(0.01, 2, length.out = 50),
                           pH = seq(5, 8, length.out = 50)) {
  data <- expand.grid(
    DOC = DOC,
    UV254 = UV254,
    dose = dose,
    pH = pH,
    stringsAsFactors = FALSE
  )

  data$DOC_final <- predict(object, newdata = data)
  tibble::as_tibble(data)
}

#' @importFrom stats fitted
#' @rdname fit_edwards_optim
#' @export
fitted.edwards_fit_base <- function(object, ...) {
  predict(object, ...)
}

#' @importFrom stats residuals
#' @rdname fit_edwards_optim
#' @export
residuals.edwards_fit_base <- function(object, ...) {
  predict(object, ...) - object$data$DOC_final
}

#' @importFrom broom tidy
#' @rdname fit_edwards_optim
#' @export
tidy.edwards_fit_base <- function(x, ...) {
  tibble::enframe(coef(x), name = "term", value = "estimate")
}

#' @importFrom broom glance
#' @rdname fit_edwards_optim
#' @export
glance.edwards_fit_base <- function(x, ...) {
  tibble::tibble(
    fit_method = class(x)[1],
    !!!evaluate_edwards_fit(x$data$DOC_final, predict(x, ...))
  )
}

#' @rdname fit_edwards_optim
#' @export
print.edwards_fit_base <- function(x, ...) {
  coefs <- stats::coef(x)
  coefs_format <- unlist(lapply(coefs, format, digits = 3, trim = TRUE))
  coef_text <- paste0(
    cli::col_blue(names(coefs_format)),
    ' = ',
    cli::col_red(coefs_format) ,
    collapse = ', '
  )

  glanced <- broom::glance(x)[c("r.squared", "RMSE", "n.obs")]
  names(glanced) <- c("r\u00B2", "RMSE", "number of finite observations")
  glanced_format <- unlist(lapply(glanced, format, digits = 3, trim = TRUE))
  glanced_units <- c("", " mg/L", "")
  glanced_text <- paste0(
    cli::col_blue(names(glanced_format)),
    ' = ',
    cli::col_red(glanced_format),
    cli::col_grey(glanced_units),
    collapse = ', '
  )

  summary_data <- x$data[c("DOC", "dose", "pH", "UV254", "DOC_final")]
  summary_data$`Predictions` <- predict(x)
  summary_data$`Langmuir a` <- coag_langmuir_a(
    pH = summary_data$pH,
    x3 = coefs["x3"],
    x2 = coefs["x2"],
    x1 = coefs["x1"]
  )
  summary_data$`Sorbable DOC (%)` <- coag_sorbable_DOC(
    DOC = summary_data$DOC,
    UV254 = summary_data$UV254,
    K1 = coefs["K1"],
    K2 = coefs["K2"]
  ) / summary_data$DOC * 100

  cli::cat_line(
    glue::glue(
      "
<{class(x)[1]}>
  {paste(x$title, collapse = ' ')}
  Coefficients:
    {coef_text}
  Performance:
    {glanced_text}
  Input data:
      "
    )
  )

  print(summary(summary_data))
  invisible(x)
}

#' @importFrom graphics plot
#' @rdname fit_edwards_optim
#' @export
plot.edwards_fit_base <- function(x, ...) {
  input_data <- x$data[c("DOC", "dose", "pH", "UV254", "DOC_final")]
  input_data$DOC_final_predicted <- stats::predict(x)
  input_data$residual <- stats::residuals(x)
  coefs <- stats::coef(x)

  # empty data is possible from edward_fit_coefs()
  if (nrow(input_data) > 0) {
    limits <- range(c(input_data$DOC_final, input_data$DOC_final_predicted), na.rm = TRUE)
    max_residual <- max(abs(input_data$residual), na.rm = TRUE)
    residual_limits <- c(-max_residual, max_residual)
  } else {
    limits <- c(0, 10)
    residual_limits <- c(-1, 1)
  }

  withr::with_par(list(mfrow = c(2, 2)), {
    graphics::plot(
      input_data$DOC_final,
      input_data$DOC_final_predicted,
      xlim = limits, ylim = limits,
      xlab = "Final DOC (measured)",
      ylab = "Final DOC (predicted)",
      main = NULL
    )
    graphics::abline(0, 1, lty = 2, col = grDevices::rgb(0, 0, 0, alpha = 0.7))

    graphics::title(x$title, outer = TRUE, line = -2)

    graphics::hist(
      if (nrow(input_data) > 0) input_data$residual else  0,
      xlim = residual_limits,
      main = NULL,
      xlab = "Residual (mg/L)"
    )

    langmuir_func <- function(pH) coag_langmuir_a(pH, x3 = coefs["x3"], x2 = coefs["x2"], x1 = coefs["x1"])
    graphics::plot(
      langmuir_func,
      xlim = c(4, 8),
      ylim = if (is.na(coefs["x3"] || is.na(coefs["x2"] || is.na(coefs["x1"])))) c(0, 1) else NULL,
      main = "Langmuir a",
      xlab = "pH", ylab = "a (mg DOC/mmol dose)"
    )
    graphics::points(
      x = input_data$pH,
      y = langmuir_func(input_data$pH)
    )

    graphics::plot(
      coag_SUVA(input_data$DOC, input_data$UV254),
      coag_sorbable_DOC(input_data$DOC, input_data$UV254, K1 = coefs["K1"], K2 = coefs["K2"]) /
        input_data$DOC * 100,
      main = "Sorbable DOC",
      ylab = "Sorbable DOC (%)",
      xlab = "SUVA",
      xlim = if(nrow(input_data) == 0) c(0, 1),
      ylim = if(nrow(input_data) == 0) c(0, 1),
    )
  })

  invisible(x)
}

evaluate_edwards_fit <- function(known, predicted) {
  residuals <- predicted - known
  n_obs <- sum(is.finite(residuals))
  r2 <- if (n_obs >= 2) {
    stats::cor(predicted, known, method = "pearson", use = "pairwise.complete.obs")
  } else {
    NA_real_
  }

  tibble::tibble(
    r.squared = r2,
    RMSE = sqrt(mean(residuals^2, na.rm = TRUE)),
    n.obs = n_obs,
    # number of coefs = 7
    df.residual = n_obs - 7,
    # deviance is the sum of the squared residuals
    deviance = sum(residuals^2, na.rm = TRUE)
  )
}
