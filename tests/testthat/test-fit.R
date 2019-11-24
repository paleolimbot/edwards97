
test_that("edwards_fit works", {
  fit_data_alum <- edwards_jar_tests[edwards_jar_tests$coagulant == "Alum", ]
  fit_data_alum$DOC_final <- fit_data_alum$TOC_final
  fit_data_small <- fit_data_alum[1:50, ]

  fit <- fit_edwards_optim(fit_data_alum, edwards_coefs("alum"))
  fit_small <- fit_edwards_optim(fit_data_small, edwards_coefs("alum"))

  tidy_fit <- broom::tidy(fit)
  expect_named(tidy_fit, c("term", "estimate"))

  glance_fit <- broom::glance(fit)
  expect_named(glance_fit, c("fit_method", "r.squared", "df.residual", "deviance"))

  # expect that the local fit is better than the global fit fot the small data
  fit_small_resid <- residuals(fit_small)
  fit_all_resid <- predict(fit, newdata = fit_data_small) - fit_data_small$DOC_final
  expect_true(
    sum(fit_small_resid^2, na.rm = TRUE) < sum(fit_all_resid^2, na.rm = TRUE)
  )
})
