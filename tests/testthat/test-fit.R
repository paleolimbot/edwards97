
test_that("edwards_fit_optim works", {
  fit_data_alum <- edwards_jar_tests[edwards_jar_tests$coagulant == "Alum", ]
  fit_data_alum$DOC_final <- fit_data_alum$TOC_final
  fit_data_small <- fit_data_alum[1:50, ]

  fit <- fit_edwards_optim(fit_data_alum, edwards_coefs("Al"))
  fit_small <- fit_edwards_optim(fit_data_small, edwards_coefs("Al"))

  # check fit methods
  expect_named(coef(fit), c("x3", "x2", "x1", "K1", "K2", "b", "root"))
  expect_vector(coef(fit), double())
  expect_identical(fitted(fit), predict(fit))
  expect_named(broom::tidy(fit), c("term", "estimate"))
  expect_named(broom::glance(fit), c("fit_method", "r.squared", "RMSE", "n.obs", "df.residual", "deviance"))
  expect_output(expect_identical(print(fit), fit), "<edwards_fit_optim>")
  expect_identical(plot(fit), fit)

  # expect that the local fit is better than the global fit fot the small data
  fit_small_resid <- residuals(fit_small)
  fit_all_resid <- predict(fit, newdata = fit_data_small) - fit_data_small$DOC_final
  expect_true(
    sum(fit_small_resid^2, na.rm = TRUE) < sum(fit_all_resid^2, na.rm = TRUE)
  )
})

test_that("edwards_fit_coefs() works with data", {
  fit_data_alum <- edwards_jar_tests[edwards_jar_tests$coagulant == "Alum", ]
  fit_data_alum$DOC_final <- fit_data_alum$TOC_final
  fit <- fit_edwards_coefs(coefs = edwards_coefs("Al"), data = fit_data_alum)

  # check fit methods
  expect_named(coef(fit), c("x3", "x2", "x1", "K1", "K2", "b", "root"))
  expect_vector(coef(fit), double())
  expect_identical(fitted(fit), predict(fit))
  expect_named(broom::tidy(fit), c("term", "estimate"))
  expect_named(broom::glance(fit), c("fit_method", "r.squared", "RMSE", "n.obs", "df.residual", "deviance"))
  expect_output(expect_identical(print(fit), fit), "<edwards_fit_coefs>")
  expect_identical(plot(fit), fit)
})

test_that("edwards_fit_coefs() works without data", {
  fit <- fit_edwards_coefs(coefs = edwards_coefs("Al"))

  # check fit methods
  expect_named(coef(fit), c("x3", "x2", "x1", "K1", "K2", "b", "root"))
  expect_vector(coef(fit), double())
  expect_identical(fitted(fit), predict(fit))
  expect_named(broom::tidy(fit), c("term", "estimate"))
  expect_named(broom::glance(fit), c("fit_method", "r.squared", "RMSE", "n.obs", "df.residual", "deviance"))
  expect_output(expect_identical(print(fit), fit), "<edwards_fit_coefs>")
  expect_identical(plot(fit), fit)
})

test_that("coagulate_grid() works as expected", {
  grid <- coagulate_grid(fit_edwards("Low DOC"), DOC = 10, UV254 = 1)
  expect_true(all(!is.na(grid$DOC_final)))
})
