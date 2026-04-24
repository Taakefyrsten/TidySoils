#' Weynants et al. (2009) pedotransfer functions — corrected coefficients
#'
#' Estimates VGM soil hydraulic parameters (WRC + HCC jointly) from sand,
#' clay, organic carbon, and bulk density using the closed-form PTFs of
#' Weynants et al. (2009), with the coefficient corrections published by
#' Weihermüller et al. (2017).
#'
#' @details
#' ## Corrected coefficients
#'
#' The coefficients in the original Weynants et al. (2009) paper contain
#' typographic errors. **Only the corrected coefficients** (Weihermüller et al.,
#' 2017, as implemented in `spsh::ptf.cW`) are used here. Do not use the
#' original 2009 paper coefficients directly.
#'
#' ## Parameterisation
#'
#' θ_r is constrained to 0 by design (Weynants et al., 2009). The PTF predicts
#' θ_s, α, n, K_s, and L. Outputs represent the matching-point conductivity
#' K_0 at the lowest retention measurement, **not** field-saturated K_sat.
#'
#' The PTF is **not suitable for |h| < 6 cm** (macropore domain excluded from
#' calibration data).
#'
#' @param data A data frame or tibble.
#' @param sand Sand content (%). Bare column name or scalar.
#' @param clay Clay content (%). Bare column name or scalar.
#' @param oc Organic carbon content (%). Bare column name or scalar.
#' @param bulk_density Bulk density (g/cm³). Bare column name or scalar.
#'
#' @return The input `data` as a tibble with appended columns:
#' \describe{
#'   \item{`.theta_r`}{Residual water content — always 0.0.}
#'   \item{`.theta_s`}{Saturated water content (m³/m³).}
#'   \item{`.alpha`}{VGM α parameter (1/cm).}
#'   \item{`.n`}{VGM n shape parameter (–).}
#'   \item{`.K_0`}{Matching-point conductivity (cm/d). Note: this is K at the
#'     lowest calibration pressure head, not K_sat.}
#'   \item{`.L`}{Mualem tortuosity/connectivity parameter (–).}
#' }
#'
#' @references
#' Weynants, M., Vereecken, H. and Javaux, M. (2009).
#' Revisiting Vereecken pedotransfer functions: introducing a closed-form
#' hydraulic model. *Vadose Zone Journal*, 8(1), 86–95.
#' <https://doi.org/10.2136/vzj2008.0062>
#'
#' Weihermüller, L., Lehmann, P., Herbst, M., Rahmati, M., Verhoef, A.,
#' Or, D., Jacques, D. and Vereecken, H. (2017).
#' Choice of pedotransfer functions matters when simulating soil water balance
#' fluxes. *Journal of Advances in Modeling Earth Systems*, 13, e2020MS002404.
#' <https://doi.org/10.1029/2020MS002404>
#'
#' @seealso [ptf_vereecken()] for the related Vereecken (1989) PTF,
#'   [check_shp_plausibility()].
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
#' ptf_weynants(soils, sand = sand, clay = clay,
#'              oc = oc, bulk_density = bulk_density)
#'
#' @export
ptf_weynants <- function(data, sand, clay, oc, bulk_density) {
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
    .ptf_domain_registry$ptf_weynants$inputs,
    "ptf_weynants"
  )

  # Corrected coefficients from Weihermüller et al. (2017) / spsh::ptf.cW
  theta_s <- 0.6355 + 0.0013 * CL - 0.1631 * BD
  ln_alpha <- -1.9772 + 0.0200 * SA - 0.0064 * CL - 0.0055 * OC * SA
  alpha    <- exp(ln_alpha)
  ln_n     <-  0.5764 - 0.0060 * SA - 0.0072 * CL + 0.0072 * CL * log(OC)
  n        <- exp(ln_n) + 1
  ln_K0    <- -0.9916 + 0.0280 * SA - 0.0291 * CL - 0.7150 * BD
  K_0      <- exp(ln_K0)
  L        <-  0.1469 + 0.0408 * OC

  out <- tibble::as_tibble(data)
  out$.theta_r <- 0.0
  out$.theta_s <- theta_s
  out$.alpha   <- alpha
  out$.n       <- n
  out$.K_0     <- K_0
  out$.L       <- L
  out
}
