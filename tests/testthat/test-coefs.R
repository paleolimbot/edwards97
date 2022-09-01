
test_that("edwards_coefs works for all types", {
  for (type in edwards_coef_types()) {
    expect_vector(edwards_coefs(!!type), double())
    expect_identical(
      names(edwards_coefs(!!type)),
      c("x3", "x2", "x1", "K1", "K2", "b", "root")
    )
    expect_s3_class(edwards_data(!!type), "data.frame")
    expect_true(all(!is.na(edwards_data(!!type)$coagulant)))
    expect_s3_class(fit_edwards(!!type), "edwards_fit")
    expect_identical(nrow(edwards_data(!!type)), length(residuals(fit_edwards(!!type))))
  }

  expect_error(edwards_coefs(type = "not a type"), "should be one of")
})

test_that("edwards fits produce reasonable predictions", {
  # produces visual output
  for (type in edwards_coef_types()) {
    expect_s3_class(plot(fit_edwards(type)), "edwards_fit")
  }

  # also makes sure coefficients/prediction is stable
  expect_equal(broom::glance(fit_edwards("Low DOC"))$RMSE, 0.426914409821377)
  expect_equal(broom::glance(fit_edwards("General-Al"))$RMSE, 1.33868850822505)
})
