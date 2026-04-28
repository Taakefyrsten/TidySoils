# Internal utilities shared across PTF functions

# Resolve a tidy-eval argument: bare column name or scalar numeric
resolve_arg <- function(quo, data, arg_name) {
  if (rlang::quo_is_symbol(quo) || rlang::quo_is_call(quo)) {
    rlang::eval_tidy(quo, data)
  } else {
    val <- rlang::eval_tidy(quo)
    if (!is.numeric(val))
      cli::cli_abort("{.arg {arg_name}} must be a numeric column name or scalar.")
    rep(val, nrow(data))
  }
}

check_range_01 <- function(x, arg_name) {
  if (any(!is.finite(x)) || any(x < 0) || any(x > 100))
    cli::cli_abort(c(
      "{.arg {arg_name}} must be in [0, 100] (percent).",
      "x" = "Found values outside this range."
    ))
}

check_positive <- function(x, arg_name) {
  if (any(!is.finite(x)) || any(x <= 0))
    cli::cli_abort(c(
      "{.arg {arg_name}} must be strictly positive.",
      "x" = "Found non-positive or non-finite values."
    ))
}

# Warn when input values fall outside the PTF's training domain.
# domain: a named list with elements like list(bulk_density = c(1.0, 1.8))
# values: a named list of numeric vectors matching domain names
# ptf_name: character string for the warning message
warn_outside_domain <- function(values, domain, ptf_name) {
  for (var in names(domain)) {
    if (!var %in% names(values)) next
    x   <- values[[var]]
    rng <- domain[[var]]
    out <- x < rng[1] | x > rng[2]
    n_out <- sum(out, na.rm = TRUE)
    if (n_out > 0) {
      cli::cli_warn(c(
        "{ptf_name}: {n_out} value{?s} of {.field {var}} outside training range \\
        [{rng[1]}, {rng[2]}].",
        "i" = "PTF predictions may be unreliable outside the calibration domain.",
        "i" = "Use {.fn ptf_info} to inspect the full domain metadata."
      ))
    }
  }
}
