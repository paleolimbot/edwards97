
test_that("quadratic solution used it coagulate() matches equations in Edwards (1997)", {

  # equation 6 in Edwards (1997)
  edwards_eqn_left <- function(SUVA, K1, K2, DOC, DOC_final, dose) {
    ((1 - SUVA * K1 - K2) * DOC - DOC_final) / (dose)
  }
  edwards_eqn_right <- function(x1, x2, x3, pH, b, DOC_final) {
    ((x3 * pH^3 + x2 * pH^2 + x1 * pH) * b * DOC_final) / (1 + b * DOC_final)
  }

  coefs <- edwards_coefs("alum")

  alum_jar_tests <- edwards_jar_tests[edwards_jar_tests$coagulant == "Alum", ]
  alum_jar_tests <- edwards_jar_tests[edwards_jar_tests$dose > 0, ]
  alum_jar_tests$TOC_final_model <- coagulate(alum_jar_tests, coefs)

  eqn_left <- with(
    alum_jar_tests,
    edwards_eqn_left(
      SUVA = 100 * UV254 / DOC,
      K1 = coefs["K1"],
      K2 = coefs["K2"],
      DOC = DOC,
      DOC_final = TOC_final_model,
      dose = dose
    )
  )

  eqn_right <- with(
    alum_jar_tests,
    edwards_eqn_right(
      x1 = coefs["x1"],
      x2 = coefs["x2"],
      x3 = coefs["x3"],
      pH = pH,
      b = coefs["b"],
      DOC_final = TOC_final_model
    )
  )

  expect_equal(eqn_left, eqn_right)
})
