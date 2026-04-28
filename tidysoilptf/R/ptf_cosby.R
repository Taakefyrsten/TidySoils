#' Cosby et al. (1984) pedotransfer functions
#'
#' Estimates Campbell/Clapp-Hornberger soil hydraulic parameters from sand,
#' silt, and clay percentages using the linear regression PTFs of Cosby et al.
#' (1984). These are the default PTFs in many land-surface models (CLM, JULES,
#' Noah-MP).
#'
#' @details
#' ## Equations
#'
#' Parameters are estimated as linear functions of sand (SA) and clay (CL)
#' fractions (expressed as percentages, not fractions):
#'
#' \deqn{\log_{10}(K_s) = -0.600 - 0.0064 \cdot CL + 0.0126 \cdot SA}
#' \deqn{\log_{10}(-\psi_s) = 1.54 - 0.0095 \cdot SA + 0.0063 \cdot SI}
#' \deqn{b = 3.10 + 0.157 \cdot CL - 0.003 \cdot SA}
#' \deqn{\theta_s = 0.505 - 0.037 \cdot CL - 0.142 \cdot SA / 100}
#'
#' where K_s is in inches/hour, ψ_s is the saturated matric potential (cm),
#' b is the pore-size distribution index (Campbell exponent), and θ_s is
#' volumetric water content at saturation.
#'
#' ## Output model
#'
#' Output is **Campbell / Clapp-Hornberger**, not VGM. To use these parameters
#' with VGM-based models, apply [convert_params()] with
#' `from = "Campbell", to = "VGM"`.
#'
#' ## Domain warnings
#'
#' Cosby et al. (1984) calibrated on 1448 soil samples from 23 US states.
#' The Weber et al. (2024) roadmap explicitly states: *"it is highly debatable
#' whether it is appropriate to use this PTF in a global model simulation
#' including grid cells with dominant soil types other than those covered by
#' the US data."* Input values outside the training ranges issue a
#' [cli::cli_warn()].
#'
#' @param data A data frame or tibble.
#' @param sand Sand content (%). Bare column name or scalar.
#' @param silt Silt content (%). Bare column name or scalar.
#' @param clay Clay content (%). Bare column name or scalar.
#'
#' @return The input `data` as a tibble with appended columns:
#' \describe{
#'   \item{`.theta_s`}{Saturated water content (m³/m³).}
#'   \item{`.psi_s`}{Saturated matric potential (cm, negative).}
#'   \item{`.b`}{Campbell pore-size distribution index (–).}
#'   \item{`.K_sat`}{Saturated hydraulic conductivity (cm/h).}
#' }
#'
#' @references
#' Cosby, B.J., Hornberger, G.M., Clapp, R.B. and Ginn, T.R. (1984).
#' A statistical exploration of the relationships of soil moisture characteristics
#' to the physical properties of soils.
#' *Water Resources Research*, 20(6), 682–690.
#' <https://doi.org/10.1029/WR020i006p00682>
#'
#' Weber, T.K.D. et al. (2024). Hydro-pedotransfer functions: a roadmap for
#' future development. *Hydrol. Earth Syst. Sci.*, 28, 3391–3433.
#' <https://doi.org/10.5194/hess-28-3391-2024>
#'
#' @seealso [convert_params()] to convert Campbell output to VGM.
#'
#' @examples
#' library(tibble)
#'
#' soils <- tibble(
#'   sand = c(65, 30, 10),
#'   silt = c(20, 40, 30),
#'   clay = c(15, 30, 60)
#' )
#'
#' ptf_cosby(soils, sand = sand, silt = silt, clay = clay)
#'
#' # Convert to approximate VGM parameters
#' ptf_cosby(soils, sand = sand, silt = silt, clay = clay) |>
#'   convert_params(from = "Campbell", to = "VGM",
#'                  b = .b, psi_s = .psi_s, theta_s = .theta_s)
#'
#' @export
ptf_cosby <- function(data, sand, silt, clay) {
  sand_quo <- rlang::enquo(sand)
  silt_quo <- rlang::enquo(silt)
  clay_quo <- rlang::enquo(clay)

  SA <- resolve_arg(sand_quo, data, "sand")
  SI <- resolve_arg(silt_quo, data, "silt")
  CL <- resolve_arg(clay_quo, data, "clay")

  check_range_01(SA, "sand")
  check_range_01(SI, "silt")
  check_range_01(CL, "clay")

  warn_outside_domain(
    list(sand = SA, silt = SI, clay = CL),
    .ptf_domain_registry$ptf_cosby$inputs,
    "ptf_cosby"
  )

  # Cosby et al. (1984), Table 4
  log10_Ksat <- -0.600 - 0.0064 * CL + 0.0126 * SA   # inches/hour
  K_sat      <- 10^log10_Ksat * 2.54                   # convert to cm/h

  log10_psi_s <- 1.54 - 0.0095 * SA + 0.0063 * SI    # |psi_s| in cm
  psi_s       <- -10^log10_psi_s                       # negative convention

  b       <- 3.10 + 0.157 * CL - 0.003 * SA
  theta_s <- 0.505 - 0.037 * CL / 100 - 0.142 * SA / 100

  out <- tibble::as_tibble(data)
  out$.theta_s <- theta_s
  out$.psi_s   <- psi_s
  out$.b       <- b
  out$.K_sat   <- K_sat
  out
}
