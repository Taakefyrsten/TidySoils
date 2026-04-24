#' Saxton & Rawls (2006) pedotransfer functions
#'
#' Estimates soil water characteristics from sand, clay, and organic matter
#' using the 24 sequential polynomial equations of Saxton & Rawls (2006).
#' Returns water content at field capacity and wilting point, saturated water
#' content, and saturated hydraulic conductivity.
#'
#' @details
#' ## Equations
#'
#' Saxton & Rawls (2006) provide a sequential system of 24 polynomial
#' equations. The core predictions are:
#'
#' - θ at −33 kPa (field capacity, FC) and −1500 kPa (permanent wilting point, WP)
#' - θ_s (saturated water content / porosity)
#' - K_s (saturated hydraulic conductivity)
#' - Available water capacity (AWC = FC − WP)
#'
#' When `bulk_density` is supplied, the equations are adjusted for
#' compaction effects on θ and K_s.
#'
#' ## Domain warning
#'
#' This PTF is based on ~1722 USDA A-horizon samples with bulk density
#' 1.0–1.8 g/cm³. It **excludes organic soils** and is not appropriate for
#' tropical soils with contrasting clay mineralogy. The Weber et al. (2024)
#' roadmap explicitly identifies this as a commonly misapplied PTF.
#'
#' @param data A data frame or tibble.
#' @param sand Sand content (%). Bare column name or scalar.
#' @param clay Clay content (%). Bare column name or scalar.
#' @param om Organic matter content (%). Bare column name or scalar.
#' @param bulk_density Optional. Bulk density (g/cm³). When supplied, BD-
#'   adjusted θ and K_s predictions are returned. Bare column name or scalar.
#'
#' @return The input `data` as a tibble with appended columns:
#' \describe{
#'   \item{`.theta_fc`}{Water content at field capacity (−33 kPa), m³/m³.}
#'   \item{`.theta_wp`}{Water content at wilting point (−1500 kPa), m³/m³.}
#'   \item{`.theta_s`}{Saturated water content (m³/m³).}
#'   \item{`.awc`}{Available water capacity (θ_FC − θ_WP), m³/m³.}
#'   \item{`.K_sat`}{Saturated hydraulic conductivity (mm/h).}
#' }
#'
#' @references
#' Saxton, K.E. and Rawls, W.J. (2006).
#' Soil water characteristic estimates by texture and organic matter for
#' hydrologic solutions. *Soil Science Society of America Journal*,
#' 70(5), 1569–1578.
#' <https://doi.org/10.2136/sssaj2005.0117>
#'
#' @seealso [check_shp_plausibility()], [ptf_info()].
#'
#' @examples
#' library(tibble)
#'
#' soils <- tibble(
#'   sand = c(65, 30, 10),
#'   clay = c(15, 30, 60),
#'   om   = c(2.5, 1.5, 1.0)
#' )
#'
#' ptf_saxton_rawls(soils, sand = sand, clay = clay, om = om)
#'
#' # With optional bulk density correction
#' soils_bd <- dplyr::mutate(soils, bd = c(1.3, 1.5, 1.6))
#' ptf_saxton_rawls(soils_bd, sand = sand, clay = clay, om = om,
#'                  bulk_density = bd)
#'
#' @export
ptf_saxton_rawls <- function(data, sand, clay, om, bulk_density = NULL) {
  sand_quo <- rlang::enquo(sand)
  clay_quo <- rlang::enquo(clay)
  om_quo   <- rlang::enquo(om)
  bd_quo   <- rlang::enquo(bulk_density)

  SA  <- resolve_arg(sand_quo, data, "sand")
  CL  <- resolve_arg(clay_quo, data, "clay")
  OM  <- resolve_arg(om_quo,   data, "om")
  BD  <- if (!rlang::quo_is_null(bd_quo)) resolve_arg(bd_quo, data, "bulk_density") else NULL

  check_range_01(SA, "sand")
  check_range_01(CL, "clay")

  dom_vals <- list(sand = SA, clay = CL, om = OM)
  if (!is.null(BD)) {
    check_positive(BD, "bulk_density")
    dom_vals$bulk_density <- BD
  }
  warn_outside_domain(dom_vals, .ptf_domain_registry$ptf_saxton_rawls$inputs, "ptf_saxton_rawls")

  # Saxton & Rawls (2006) — equations in decimal fractions (sand/clay/100)
  S <- SA / 100
  C <- CL / 100

  # θ at -33 kPa (eq. 1-2)
  theta_33t <- 0.299 - 0.251 * S + 0.195 * C + 0.011 * OM +
    0.006 * S * OM - 0.027 * C * OM + 0.452 * S * C + 0.299
  theta_33  <- theta_33t + (1.283 * theta_33t^2 - 0.374 * theta_33t - 0.015)

  # θ at -1500 kPa (eq. 3-4)
  theta_1500t <- 0.031 - 0.024 * S + 0.487 * C + 0.006 * OM +
    0.005 * S * OM - 0.013 * C * OM + 0.068 * S * C + 0.031
  theta_1500  <- theta_1500t + (0.14 * theta_1500t - 0.02)

  # θ_s (eq. 5-6)
  theta_s_adj <- theta_33 + 0.278 * S + 0.034 * C + 0.022 * OM -
    0.018 * S * OM - 0.027 * C * OM - 0.584 * S * C + 0.078
  theta_s <- theta_s_adj + (0.636 * theta_s_adj - 0.107)

  # K_sat in mm/h (eq. 7)
  K_sat <- 1930 * (theta_s - theta_33)^(3 - 1.44 * C)

  # BD correction if supplied (eq. 9-11)
  if (!is.null(BD)) {
    rho_df <- BD / (1 - theta_s)   # density factor
    theta_s    <- theta_s    - 0.733 * (rho_df - 1)
    theta_33   <- theta_33   - 0.121 * (rho_df - 1)
    theta_1500 <- theta_1500 - 0.033 * (rho_df - 1)
    K_sat <- K_sat * exp(-0.694 * (rho_df - 1))
  }

  awc <- pmax(theta_33 - theta_1500, 0)

  out <- tibble::as_tibble(data)
  out$.theta_fc <- theta_33
  out$.theta_wp <- theta_1500
  out$.theta_s  <- theta_s
  out$.awc      <- awc
  out$.K_sat    <- K_sat
  out
}
