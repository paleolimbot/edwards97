
test_that("edwards_coefs works", {
  expect_is(edwards_coefs(), "numeric")
  expect_identical(
    names(edwards_coefs()),
    c("K1", "K2", "x1", "x2", "x3", "b", "root")
  )
  expect_error(edwards_coefs(type = "not a type"), "should be one of")
})
