#' Wösten et al. (1999) continuous pedotransfer functions
#'
#' Estimates Van Genuchten–Mualem (VGM) soil hydraulic parameters from sand,
#' silt, clay, organic matter, bulk density, and topsoil/subsoil designation
#' using the continuous regression PTFs of Wösten et al. (1999), calibrated
#' on the European HYPRES database.
#'
#' @details
#' ## Equations
#'
#' The PTF predicts all six VGM parameters (θ_r, θ_s, α, n, K_s, L) as
#' functions of the predictors. The regression equations are given in
#' Wösten et al. (1999), Table 2. Predictors are expressed as:
#'
#' - Cl = clay (%), Si = silt (%), OM = organic matter (%), D = bulk density
#'   (g/cm³), topsoil = 1 for topsoil, 0 for subsoil.
#'
#' ## Domain warnings
#'
#' This PTF was calibrated on the HYPRES database of ~5500 western European
#' soils. Inputs outside the training range, or soils from outside Europe,
#' trigger a [cli::cli_warn()] message. Approximately 30% of global grid cells
#' produce unphysical evaporation characteristic lengths from Wösten-derived
#' parameters (Lehmann et al., 2020).
#'
#' @param data A data frame or tibble.
#' @param sand Sand content (%). Bare column name or scalar.
#' @param silt Silt content (%). Bare column name or scalar.
#' @param clay Clay content (%). Bare column name or scalar.
#' @param om Organic matter content (%). Bare column name or scalar.
#' @param bulk_density Bulk density (g/cm³). Bare column name or scalar.
#' @param topsoil Logical or 0/1 integer. `TRUE` / `1` for topsoil,
#'   `FALSE` / `0` for subsoil. Bare column name or scalar.
#'
#' @return The input `data` as a tibble with appended columns:
#' \describe{
#'   \item{`.theta_r`}{Residual water content (m³/m³).}
#'   \item{`.theta_s`}{Saturated water content (m³/m³).}
#'   \item{`.alpha`}{VGM α parameter (1/cm).}
#'   \item{`.n`}{VGM n shape parameter (–).}
#'   \item{`.K_sat`}{Saturated hydraulic conductivity (cm/d).}
#'   \item{`.L`}{Mualem tortuosity/connectivity parameter (–).}
#' }
#'
#' @references
#' Wösten, J.H.M., Lilly, A., Nemes, A. and Le Bas, C. (1999).
#' Development and use of a database of hydraulic properties of European soils.
#' *Geoderma*, 90, 169–185.
#' <https://doi.org/10.1016/S0016-7061(98)00132-3>
#'
#' Lehmann, P., Bickel, S., Wei, Z. and Or, D. (2020).
#' Physical constraints for improved soil hydraulic parameter estimation by
#' pedotransfer functions. *Water Resources Research*, 56, e2019WR025963.
#' <https://doi.org/10.1029/2019WR025963>
#'
#' @seealso [ptf_wosten_class()] for the class-based (lookup-table) variant,
#'   [check_shp_plausibility()] for post-prediction physical checks,
#'   [ptf_info()] for full domain metadata.
#'
#' @examples
#' library(tibble)
#'
#' soils <- tibble(
#'   sand         = c(65,  20,  10),
#'   silt         = c(20,  40,  30),
#'   clay         = c(15,  40,  60),
#'   om           = c(2.5, 1.5, 1.0),
#'   bulk_density = c(1.3, 1.4, 1.5),
#'   topsoil      = c(TRUE, TRUE, FALSE)
#' )
#'
#' ptf_wosten(soils,
#'   sand = sand, silt = silt, clay = clay,
#'   om = om, bulk_density = bulk_density, topsoil = topsoil
#' )
#'
#' @export
ptf_wosten <- function(data, sand, silt, clay, om, bulk_density, topsoil) {
  sand_quo <- rlang::enquo(sand)
  silt_quo <- rlang::enquo(silt)
  clay_quo <- rlang::enquo(clay)
  om_quo   <- rlang::enquo(om)
  bd_quo   <- rlang::enquo(bulk_density)
  top_quo  <- rlang::enquo(topsoil)

  SA <- resolve_arg(sand_quo, data, "sand")
  SI <- resolve_arg(silt_quo, data, "silt")
  CL <- resolve_arg(clay_quo, data, "clay")
  OM <- resolve_arg(om_quo,   data, "om")
  D  <- resolve_arg(bd_quo,   data, "bulk_density")
  TS <- as.integer(resolve_arg(top_quo, data, "topsoil"))

  check_range_01(SA, "sand")
  check_range_01(SI, "silt")
  check_range_01(CL, "clay")
  check_positive(D, "bulk_density")

  warn_outside_domain(
    list(sand = SA, silt = SI, clay = CL, om = OM, bulk_density = D),
    .ptf_domain_registry$ptf_wosten$inputs,
    "ptf_wosten"
  )

  # Wösten et al. (1999), Table 2 — continuous PTFs
  # θ_r
  theta_r <- 0.01 + 0.1555 * OM - 0.001535 * CL * OM

  # θ_s — depends on topsoil flag
  theta_s <- 0.7919 + 0.001691 * CL - 0.29619 * D -
    0.000001491 * SI^2 + 0.0000821 * OM^2 +
    0.02427 / CL + 0.01113 / SI + 0.01472 * log(SI) -
    0.0000733 * OM * CL - 0.000619 * D * CL -
    0.001183 * D * OM - 0.0001664 * TS * SI

  # ln(α) → α in 1/cm
  ln_alpha <- -14.96 + 0.03135 * CL + 0.0351 * SI +
    0.646 * OM + 15.29 * D - 0.192 * TS -
    4.671 * D^2 - 0.000781 * CL^2 - 0.00687 * OM^2 +
    0.0449 / OM + 0.0663 * log(SI) + 0.1482 * log(OM) -
    0.04546 * D * SI - 0.4852 * D * OM +
    0.00673 * TS * CL
  alpha <- exp(ln_alpha)

  # ln(n) → n
  ln_n <- -25.23 - 0.02195 * CL + 0.0074 * SI -
    0.1986 * OM + 22.9 * D - 0.248 * TS -
    2.811 * D^2 - 0.00037 * CL^2 - 0.000699 * OM^2 +
    0.0035 / OM + 0.00159 * log(SI) + 0.4398 * log(OM)
  n <- exp(ln_n) + 1  # n > 1 by construction

  # ln(K_sat) → K_sat in cm/d
  ln_Ksat <- 7.755 + 0.0352 * SI + 0.93 * TS -
    0.967 * D^2 - 0.000484 * CL^2 - 0.000322 * SI^2 +
    0.001 / SI - 0.0748 / OM - 0.643 * log(SI) -
    0.01398 * D * CL - 0.1673 * D * OM +
    0.02986 * TS * CL - 0.03305 * TS * SI
  K_sat <- exp(ln_Ksat)

  # L
  L <- 0.0202 + 0.0006193 * CL^2 - 0.001136 * OM^2 -
    0.2316 * log(OM) - 0.03544 * D * CL +
    0.00283 * D * SI + 0.0488 * D * OM

  out <- tibble::as_tibble(data)
  out$.theta_r <- theta_r
  out$.theta_s <- theta_s
  out$.alpha   <- alpha
  out$.n       <- n
  out$.K_sat   <- K_sat
  out$.L       <- L
  out
}
