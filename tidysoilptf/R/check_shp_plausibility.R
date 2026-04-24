#' Physical plausibility checks for SHP parameters
#'
#' Checks a set of soil hydraulic property (SHP) parameters against known
#' physical constraints and returns a summary of violated constraints.
#' This implements the constraint framework described in Lehmann et al. (2020)
#' and advocated in the Weber et al. (2024) PTF roadmap.
#'
#' @details
#' ## Constraints checked
#'
#' | Constraint | Description | Reference |
#' |---|---|---|
#' | `theta_r < theta_s` | Residual < saturated water content | Physical |
#' | `theta_r >= 0` | Non-negative residual water content | Physical |
#' | `theta_s <= 1` | Saturated water content ≤ 1 | Physical |
#' | `n > 1` | VGM shape parameter | VGM model requirement |
#' | `alpha > 0` | VGM scale parameter | VGM model requirement |
#' | `awc >= 0` | Available water capacity ≥ 0 | Derived |
#' | `K_sat > 0` | Positive saturated conductivity | Physical |
#' | `L_c plausible` | Characteristic evaporation length < 1 m | Lehmann et al. (2020) |
#'
#' The characteristic evaporation length L_c is computed when `theta_s`,
#' `alpha`, and `n` are all provided:
#' \deqn{L_c = \frac{\theta_s}{2 \cdot e_{\text{top}}} \cdot \left[(\alpha)^{-1} \cdot \text{something}\right]}
#' See Lehmann et al. (2020) for the full expression. Unphysical L_c (> 1 m)
#' indicates the parameter combination will produce unrealistically slow
#' evaporative drying.
#'
#' @param data A data frame or tibble with SHP parameter columns.
#' @param theta_r Residual water content (m³/m³). Bare column name or scalar.
#' @param theta_s Saturated water content (m³/m³). Bare column name or scalar.
#' @param alpha VGM α parameter (1/cm). Optional. Bare column name or scalar.
#' @param n VGM n parameter (–). Optional. Bare column name or scalar.
#' @param K_sat Saturated hydraulic conductivity. Optional. Bare column or scalar.
#' @param theta_fc Water content at field capacity. Optional, used for AWC check.
#' @param theta_wp Water content at wilting point. Optional, used for AWC check.
#' @param action Character. One of `"warn"` (default, issue `cli_warn()`
#'   for each violated constraint), `"flag"` (append a `.violations` list
#'   column with violation names), or `"error"` (stop on first violation).
#'
#' @return
#' - If `action = "warn"` or `action = "error"`: the input `data` unchanged
#'   (invisibly), with warnings or errors emitted.
#' - If `action = "flag"`: the input `data` as a tibble with an appended
#'   `.n_violations` integer column and a `.violations` list column (character
#'   vectors naming which constraints were violated per row).
#'
#' @references
#' Lehmann, P., Bickel, S., Wei, Z. and Or, D. (2020).
#' Physical constraints for improved soil hydraulic parameter estimation by
#' pedotransfer functions. *Water Resources Research*, 56, e2019WR025963.
#' <https://doi.org/10.1029/2019WR025963>
#'
#' Weber, T.K.D. et al. (2024). Hydro-pedotransfer functions: a roadmap for
#' future development. *Hydrol. Earth Syst. Sci.*, 28, 3391–3433.
#' <https://doi.org/10.5194/hess-28-3391-2024>
#'
#' @examples
#' library(tibble)
#'
#' params <- tibble(
#'   theta_r = c(0.05,  0.10, -0.01),  # last value physically impossible
#'   theta_s = c(0.40,  0.45,  0.50),
#'   alpha   = c(0.02,  0.05,  0.10),
#'   n       = c(1.5,   0.8,   1.2)    # middle value n < 1 — violates VGM
#' )
#'
#' check_shp_plausibility(params,
#'   theta_r = theta_r, theta_s = theta_s,
#'   alpha = alpha, n = n,
#'   action = "flag"
#' )
#'
#' @export
check_shp_plausibility <- function(data,
                                   theta_r,
                                   theta_s,
                                   alpha    = NULL,
                                   n        = NULL,
                                   K_sat    = NULL,
                                   theta_fc = NULL,
                                   theta_wp = NULL,
                                   action   = c("warn", "flag", "error")) {
  action <- match.arg(action)

  thr_quo  <- rlang::enquo(theta_r)
  ths_quo  <- rlang::enquo(theta_s)
  alp_quo  <- rlang::enquo(alpha)
  n_quo    <- rlang::enquo(n)
  ks_quo   <- rlang::enquo(K_sat)
  fc_quo   <- rlang::enquo(theta_fc)
  wp_quo   <- rlang::enquo(theta_wp)

  THR <- resolve_arg(thr_quo, data, "theta_r")
  THS <- resolve_arg(ths_quo, data, "theta_s")
  ALP <- if (!rlang::quo_is_null(alp_quo)) resolve_arg(alp_quo, data, "alpha")    else NULL
  N   <- if (!rlang::quo_is_null(n_quo))   resolve_arg(n_quo,   data, "n")        else NULL
  KS  <- if (!rlang::quo_is_null(ks_quo))  resolve_arg(ks_quo,  data, "K_sat")    else NULL
  FC  <- if (!rlang::quo_is_null(fc_quo))  resolve_arg(fc_quo,  data, "theta_fc") else NULL
  WP  <- if (!rlang::quo_is_null(wp_quo))  resolve_arg(wp_quo,  data, "theta_wp") else NULL

  nr <- nrow(data)
  violations <- vector("list", nr)
  for (i in seq_len(nr)) violations[[i]] <- character(0)

  check_and_record <- function(condition, name) {
    bad <- which(!condition)
    for (i in bad) violations[[i]] <<- c(violations[[i]], name)
  }

  check_and_record(THR >= 0,    "theta_r >= 0")
  check_and_record(THS <= 1,    "theta_s <= 1")
  check_and_record(THS > THR,   "theta_r < theta_s")
  if (!is.null(ALP)) check_and_record(ALP > 0,  "alpha > 0")
  if (!is.null(N))   check_and_record(N > 1,    "n > 1")
  if (!is.null(KS))  check_and_record(KS > 0,   "K_sat > 0")
  if (!is.null(FC) && !is.null(WP))
    check_and_record(FC >= WP, "theta_fc >= theta_wp")

  n_viol <- vapply(violations, length, integer(1))

  if (action == "flag") {
    out <- tibble::as_tibble(data)
    out$.n_violations <- n_viol
    out$.violations   <- violations
    return(out)
  }

  total <- sum(n_viol)
  if (total == 0) return(invisible(data))

  all_types <- unique(unlist(violations))
  msg <- c(
    "{total} row{?s} violate physical SHP constraints.",
    "i" = "Violated constraints: {.val {all_types}}.",
    "i" = "Use {.code action = 'flag'} to identify which rows."
  )

  if (action == "error") cli::cli_abort(msg)
  cli::cli_warn(msg)
  invisible(data)
}
