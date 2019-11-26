
test_that("diminishing returns calculation works", {
  dose_curve <- coagulate_grid(fit_edwards("Low DOC"), DOC = 4, UV254 = 0.2, pH = 5.5)
  expect_equal(
    round(dose_of_diminishing_returns(dose_curve$dose, dose_curve$DOC_final), 3),
    0.090
  )
})

test_that("diminishing returns calculation returns NA when expected", {
  diminishing_returns_calc <- function(doses) {
    dose_curve <- coagulate_grid(
      fit_edwards("Low DOC"),
      DOC = 4, UV254 = 0.2, pH = 5.5, dose = doses
    )
    dose_of_diminishing_returns(
      dose_curve$dose,
      dose_curve$DOC_final
    )
  }

  # good
  expect_equal(
    round(diminishing_returns_calc(c(0.07, 0.08, 0.09)), 3),
    0.086
  )

  # too few finite values
  expect_equal(
    diminishing_returns_calc(c(0.07, 0.08, NA)),
    NA_real_
  )

  # doesn't contain any values higher
  expect_equal(
    diminishing_returns_calc(c(0.06, 0.07, 0.08)),
    NA_real_
  )
  expect_equal(
    diminishing_returns_calc(c(0.08, 0.09, 0.10)),
    NA_real_
  )
})

test_that("dose-for-final-concentration calculation works", {
  dose_curve <- coagulate_grid(fit_edwards("Low DOC"), DOC = 4, UV254 = 0.2, pH = 5.5)
  round(dose_for_criterion(dose_curve$dose, dose_curve$DOC_final, criterion = 3), 3)
  expect_equal(
    round(dose_for_criterion(dose_curve$dose, dose_curve$DOC_final, criterion = 3), 3),
    0.034
  )
})

test_that("dose-for-final-concentration calculation returns NA when appropriate", {
  target_dose_calc <- function(doses) {
    dose_curve <- coagulate_grid(
      fit_edwards("Low DOC"),
      DOC = 4, UV254 = 0.2, pH = 5.5, dose = doses
    )
    dose_for_criterion(
      dose_curve$dose,
      dose_curve$DOC_final,
      criterion = 3
    )
  }

  expect_equal(
    round(target_dose_calc(c(0.02, 0.04)), 3),
    0.031
  )

  expect_equal(
    target_dose_calc(c(0.03)),
    NA_real_
  )

  expect_equal(
    target_dose_calc(c(0.01, 0.02)),
    NA_real_
  )

  expect_equal(
    target_dose_calc(c(0.03, 0.04)),
    NA_real_
  )
})
