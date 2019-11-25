
test_that("quadratic solution used in coagulate() satisfies equations in Edwards (1997)", {

  # equation 1
  fraction_non_sorbable_DOC <- function(SUVA, K1, K2) {
    K1 * SUVA + K2
  }

  # equation 2
  sorbable_DOC <- function(DOC, SUVA, K1, K2) {
    (1 - fraction_non_sorbable_DOC(SUVA, K1, K2)) * DOC
  }

  # implied
  non_sorbable_DOC <- function(DOC, SUVA, K1, K2) {
    fraction_non_sorbable_DOC(SUVA, K1, K2) * DOC
  }

  # equation 3
  langmuir_eqn_left <- function(removed_DOC, dose) {
    removed_DOC / dose
  }
  langmuir_eqn_right <- function(a, b, DOC_final_sorbable) {
    (a * b * DOC_final_sorbable) / (1 + b * DOC_final_sorbable)
  }

  # implied in text
  removed_DOC <- function(DOC, SUVA, K1, K2, DOC_final_sorbable)  {
    sorbable_DOC(DOC, SUVA, K1, K2) - DOC_final_sorbable
  }

  # equation 5
  langmuir_a <- function(pH, x1, x2, x3) {
    pH^3 * x3 + pH^2 * x2 + pH * x1
  }

  # equation 6 in Edwards (1997)
  edwards_eqn_left <- function(SUVA, K1, K2, DOC, DOC_final_sorbable, dose) {
    ((1 - SUVA * K1 - K2) * DOC - DOC_final_sorbable) / (dose)
  }
  edwards_eqn_right <- function(x1, x2, x3, pH, b, DOC_final_sorbable) {
    ((x3 * pH^3 + x2 * pH^2 + x1 * pH) * b * DOC_final_sorbable) / (1 + b * DOC_final_sorbable)
  }

  coefs <- edwards_coefs("Al")

  alum_jar_tests <- edwards_jar_tests[edwards_jar_tests$coagulant == "Alum", ]
  alum_jar_tests <- edwards_jar_tests[edwards_jar_tests$dose > 0, ]
  alum_jar_tests$TOC_final_model <- coagulate(alum_jar_tests, coefs)
  alum_jar_tests$TOC_sorbable <- with(
    alum_jar_tests,
    TOC_final_model - non_sorbable_DOC(DOC = DOC, SUVA = 100 * UV254 / DOC, K1 = coefs["K1"], K2 = coefs["K2"])
  )

  eqn3_left <- with(
    alum_jar_tests,
    langmuir_eqn_left(
      removed_DOC = removed_DOC(
        DOC = DOC,
        SUVA = 100 * UV254 / DOC,
        K1 = coefs["K1"],
        K2 = coefs["K2"],
        DOC_final_sorbable = TOC_sorbable
      ),
      dose = dose
    )
  )

  eqn3_right <- with(
    alum_jar_tests,
    langmuir_eqn_right(
      a = langmuir_a(pH, x1 = coefs["x1"], x2 = coefs["x2"], x3 = coefs["x3"]),
      b = coefs["b"],
      DOC_final_sorbable = TOC_sorbable
    )
  )

  expect_equal(eqn3_left, eqn3_right)

  eqn6_left <- with(
    alum_jar_tests,
    edwards_eqn_left(
      SUVA = 100 * UV254 / DOC,
      K1 = coefs["K1"],
      K2 = coefs["K2"],
      DOC = DOC,
      DOC_final_sorbable = TOC_sorbable,
      dose = dose
    )
  )

  eqn6_right <- with(
    alum_jar_tests,
    edwards_eqn_right(
      x1 = coefs["x1"],
      x2 = coefs["x2"],
      x3 = coefs["x3"],
      pH = pH,
      b = coefs["b"],
      DOC_final_sorbable = TOC_sorbable
    )
  )

  expect_equal(eqn6_left, eqn6_right)
})
