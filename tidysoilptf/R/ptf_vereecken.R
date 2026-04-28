#' Vereecken et al. (1989) pedotransfer functions
#'
#' Estimates Van Genuchten parameters from sand, clay, organic carbon, and
#' bulk density using the regression PTFs of Vereecken et al. (1989).
#'
#' @details
#' ## Parameterisation warning: m = 1, not m = 1 − 1/n
#'
#' Vereecken et al. (1989) used the VG water retention model with **m = 1**:
#' \deqn{S_e(h) = \frac{1}{[1 + (\alpha |h|)^n]^1}}
#'
#' This is **different** from the standard VGM model (Mualem, 1976) which
#' uses m = 1 − 1/n. The `.m` column is always returned as 1.0 to make this
#' explicit. Using these parameters directly in the Mualem hydraulic
#' conductivity model (as in [tidysoilwater::hydraulic_conductivity()]) is
#' **not physically correct** without re-parameterisation.
#'
#' Despite this constraint, Vereecken et al. (1989) is consistently among the
#' top performers in PTF benchmark studies.
#'
#' ## Equations
#'
#' \deqn{\theta_r = 0.015 + 0.005 \cdot CL + 0.014 \cdot OC}
#' \deqn{\theta_s = 0.81 - 0.283 \cdot \rho_b + 0.001 \cdot CL}
#' \deqn{\ln \alpha = -2.486 + 0.025 \cdot SA - 0.351 \cdot OC - 2.617 \cdot \rho_b - 0.023 \cdot CL}
#' \deqn{\ln n = 0.053 - 0.009 \cdot SA - 0.013 \cdot CL + 0.00015 \cdot SA^2}
#'
#' where SA = sand (%), CL = clay (%), OC = organic carbon (%),
#' ρ_b = bulk density (g/cm³).
#'
#' @param data A data frame or tibble.
#' @param sand Sand content (%). Bare column name or scalar.
#' @param clay Clay content (%). Bare column name or scalar.
#' @param oc Organic carbon content (%). Bare column name or scalar.
#' @param bulk_density Bulk density (g/cm³). Bare column name or scalar.
#'
#' @return The input `data` as a tibble with appended columns:
#' \describe{
#'   \item{`.theta_r`}{Residual water content (m³/m³).}
#'   \item{`.theta_s`}{Saturated water content (m³/m³).}
#'   \item{`.alpha`}{VG α (1/cm). Note: calibrated for m = 1 model.}
#'   \item{`.n`}{VG n (–). Note: calibrated for m = 1 model.}
#'   \item{`.m`}{Always 1.0. Returned explicitly to flag the non-standard parameterisation.}
#' }
#'
#' @references
#' Vereecken, H., Maes, J., Feyen, J. and Darius, P. (1989).
#' Estimating the soil moisture retention characteristic from texture, bulk
#' density and carbon content. *Soil Science*, 148(6), 389–403.
#'
#' @seealso [check_shp_plausibility()], [ptf_info()].
#'
#' @examples
#' library(tibble)
#'
#' soils <- tibble(
#'   sand         = c(65, 30, 10),
#'   clay         = c(15, 30, 60),
#'   oc           = c(1.5, 2.0, 1.0),
#'   bulk_density = c(1.3, 1.4, 1.5)
#' )
#'
#' ptf_vereecken(soils, sand = sand, clay = clay,
#'               oc = oc, bulk_density = bulk_density)
#'
#' @export
ptf_vereecken <- function(data, sand, clay, oc, bulk_density) {
  sand_quo <- rlang::enquo(sand)
  clay_quo <- rlang::enquo(clay)
  oc_quo   <- rlang::enquo(oc)
  bd_quo   <- rlang::enquo(bulk_density)

  SA <- resolve_arg(sand_quo, data, "sand")
  CL <- resolve_arg(clay_quo, data, "clay")
  OC <- resolve_arg(oc_quo,   data, "oc")
  BD <- resolve_arg(bd_quo,   data, "bulk_density")

  check_range_01(SA, "sand")
  check_range_01(CL, "clay")
  check_positive(BD, "bulk_density")

  warn_outside_domain(
    list(sand = SA, clay = CL, oc = OC, bulk_density = BD),
    .ptf_domain_registry$ptf_vereecken$inputs,
    "ptf_vereecken"
  )

  theta_r <- 0.015 + 0.005 * CL + 0.014 * OC
  theta_s <- 0.81 - 0.283 * BD  + 0.001 * CL
  alpha   <- exp(-2.486 + 0.025 * SA - 0.351 * OC - 2.617 * BD - 0.023 * CL)
  n       <- exp( 0.053 - 0.009 * SA - 0.013 * CL + 0.00015 * SA^2)

  out <- tibble::as_tibble(data)
  out$.theta_r <- theta_r
  out$.theta_s <- theta_s
  out$.alpha   <- alpha
  out$.n       <- n
  out$.m       <- 1.0   # explicit: m = 1, not m = 1-1/n
  out
}
