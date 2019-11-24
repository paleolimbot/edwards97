
test_that("edwards_fit works", {
  fit_data_alum <- edwards_jar_tests[edwards_jar_tests$coagulant == "Alum", ]
  fit_data_alum$DOC_final <- fit_data_alum$TOC_final
  fit_data_small <- fit_data_alum[1:50, ]

  fit <- fit_edwards_optim(fit_data_alum, edwards_coefs("alum"))
  fit_small <- fit_edwards_optim(fit_data_small, edwards_coefs("alum"))

  # check fit methods
  expect_named(coef(fit), c("K1", "K2", "x1", "x2", "x3", "b", "root"))
  expect_is(coef(fit), "numeric")
  expect_identical(fitted(fit), predict(fit))
  expect_named(broom::tidy(fit), c("term", "estimate"))
  expect_named(broom::glance(fit), c("fit_method", "r.squared", "RMSE", "df.residual", "deviance"))
  expect_output(expect_identical(print(fit), fit), "<edwards_fit_optim>")
  expect_identical(plot(fit), fit)

  # expect that the local fit is better than the global fit fot the small data
  fit_small_resid <- residuals(fit_small)
  fit_all_resid <- predict(fit, newdata = fit_data_small) - fit_data_small$DOC_final
  expect_true(
    sum(fit_small_resid^2, na.rm = TRUE) < sum(fit_all_resid^2, na.rm = TRUE)
  )
})
