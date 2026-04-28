#' Rawls et al. (1982) point pedotransfer functions
#'
#' Estimates volumetric water content at 12 matric potentials (−4 to −1500 kPa)
#' from sand, clay, and organic matter using the linear regression PTFs of
#' Rawls et al. (1982). A historical benchmark PTF with simple coefficients.
#'
#' @details
#' ## Equations
#'
#' Water content θ(h) at each of 12 pressure heads is estimated as:
#' \deqn{\theta_h = a_0 + a_1 \cdot SA + a_2 \cdot CL + a_3 \cdot OM}
#'
#' where SA = sand (%), CL = clay (%), OM = organic matter (%), and a_0–a_3
#' are tabulated regression coefficients (Rawls et al., 1982, Table 1).
#'
#' Nemes et al. (2009) evaluated these PTFs at the US national scale and
#' found systematic biases. Include as a historical benchmark.
#'
#' @param data A data frame or tibble.
#' @param sand Sand content (%). Bare column name or scalar.
#' @param clay Clay content (%). Bare column name or scalar.
#' @param om Organic matter content (%). Bare column name or scalar.
#'
#' @return The input `data` as a tibble with 12 appended columns named
#'   `.theta_4kPa`, `.theta_7kPa`, `.theta_10kPa`, `.theta_20kPa`,
#'   `.theta_33kPa`, `.theta_60kPa`, `.theta_100kPa`, `.theta_200kPa`,
#'   `.theta_400kPa`, `.theta_700kPa`, `.theta_1000kPa`, `.theta_1500kPa`.
#'
#' @references
#' Rawls, W.J., Brakensiek, D.L. and Saxton, K.E. (1982).
#' Estimation of soil water properties.
#' *Transactions of the ASAE*, 25(5), 1316–1320.
#' <https://doi.org/10.13031/2013.33720>
#'
#' Nemes, A., Rawls, W.J., Pachepsky, Y.A. and van Genuchten, M.T. (2009).
#' Sensitivity analysis of the nonparametric nearest neighbor technique to
#' estimate soil water retention. *Vadose Zone Journal*, 5, 1222–1235.
#'
#' @seealso [ptf_saxton_rawls()] for the more complete Saxton & Rawls (2006)
#'   system.
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
#' ptf_rawls_1982(soils, sand = sand, clay = clay, om = om)
#'
#' @export
ptf_rawls_1982 <- function(data, sand, clay, om) {
  sand_quo <- rlang::enquo(sand)
  clay_quo <- rlang::enquo(clay)
  om_quo   <- rlang::enquo(om)

  SA <- resolve_arg(sand_quo, data, "sand")
  CL <- resolve_arg(clay_quo, data, "clay")
  OM <- resolve_arg(om_quo,   data, "om")

  check_range_01(SA, "sand")
  check_range_01(CL, "clay")

  warn_outside_domain(
    list(sand = SA, clay = CL, om = OM),
    .ptf_domain_registry$ptf_rawls_1982$inputs,
    "ptf_rawls_1982"
  )

  # Rawls et al. (1982) Table 1 — coefficients [a0, a_SA, a_CL, a_OM]
  coefs <- rbind(
    `4kPa`    = c( 0.4188, -0.0030, 0.00283,  0.000317),
    `7kPa`    = c( 0.3814, -0.0028, 0.00339,  0.000371),
    `10kPa`   = c( 0.3588, -0.0021, 0.00374,  0.000416),
    `20kPa`   = c( 0.3111, -0.0013, 0.00453,  0.000539),
    `33kPa`   = c( 0.2576, -0.0020, 0.00363,  0.000299),
    `60kPa`   = c( 0.2065, -0.0016, 0.00400,  0.000336),
    `100kPa`  = c( 0.1633, -0.0012, 0.00421,  0.000371),
    `200kPa`  = c( 0.1211, -0.0008, 0.00422,  0.000407),
    `400kPa`  = c( 0.0878, -0.0004, 0.00407,  0.000416),
    `700kPa`  = c( 0.0656, -0.0002, 0.00385,  0.000409),
    `1000kPa` = c( 0.0521, -0.0001, 0.00369,  0.000399),
    `1500kPa` = c( 0.0260,  0.0005, 0.00158, -0.000217)
  )

  out <- tibble::as_tibble(data)
  for (nm in rownames(coefs)) {
    a <- coefs[nm, ]
    out[[paste0(".theta_", nm)]] <- a[1] + a[2] * SA + a[3] * CL + a[4] * OM
  }
  out
}
