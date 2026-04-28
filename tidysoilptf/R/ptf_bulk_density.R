#' Bulk density pedotransfer functions
#'
#' Estimates bulk density from texture and organic carbon when measured BD
#' is unavailable. Implements Rawls (1983) and Manrique & Jones (1991).
#' BD is required as an input by most parametric PTFs.
#'
#' @details
#' ## Methods
#'
#' **Rawls (1983):**
#' \deqn{\rho_b = \frac{1}{0.332 - 0.0007251 \cdot SA + 0.1276 \cdot \log_{10}(OC)}}
#'
#' **Manrique & Jones (1991):** Two equations depending on whether
#' the soil is mineral or organic-rich:
#' \deqn{\rho_b = 1.660 - 0.318 \cdot OC^{0.5} \quad \text{(OC < 3\%)}}
#' \deqn{\rho_b = 0.224 + 0.598 \cdot e^{-0.209 \cdot OC} \quad \text{(OC >= 3\%)}}
#'
#' ## Measurement method caveat
#'
#' BD measurement methods are not standardised. Core sampling and clod methods
#' produce systematically different values, particularly for structured soils
#' (Weber et al., 2024, Fig. 8). The PTF that will consume the estimated BD
#' should be calibrated on the same measurement method as the training data
#' used here.
#'
#' @param data A data frame or tibble.
#' @param sand Sand content (%). Required for `method = "rawls"`. Bare column
#'   name or scalar.
#' @param oc Organic carbon content (%). Bare column name or scalar.
#' @param method Character. `"rawls"` (Rawls, 1983) or `"manrique_jones"`
#'   (Manrique & Jones, 1991). Default: `"rawls"`.
#'
#' @return The input `data` as a tibble with an appended `.bulk_density` column
#'   (g/cm³).
#'
#' @references
#' Rawls, W.J. (1983). Estimating soil bulk density from particle size
#' analysis and organic matter content. *Soil Science*, 135(2), 123–125.
#'
#' Manrique, L.A. and Jones, C.A. (1991). Bulk density of soils in relation
#' to soil physical and chemical properties. *Soil Science Society of America
#' Journal*, 55(2), 476–481.
#' <https://doi.org/10.2136/sssaj1991.03615995005500020030x>
#'
#' @seealso [ptf_wosten()], [ptf_weynants()], [ptf_vereecken()].
#'
#' @examples
#' library(tibble)
#'
#' soils <- tibble(
#'   sand = c(60, 30, 10),
#'   oc   = c(1.5, 2.5, 4.0)
#' )
#'
#' ptf_bulk_density(soils, sand = sand, oc = oc, method = "rawls")
#'
#' ptf_bulk_density(soils, oc = oc, method = "manrique_jones")
#'
#' @export
ptf_bulk_density <- function(data, sand = NULL, oc,
                              method = c("rawls", "manrique_jones")) {
  method  <- match.arg(method)
  oc_quo  <- rlang::enquo(oc)
  OC      <- resolve_arg(oc_quo, data, "oc")

  out <- tibble::as_tibble(data)

  if (method == "rawls") {
    sand_quo <- rlang::enquo(sand)
    if (rlang::quo_is_null(sand_quo))
      cli::cli_abort("{.arg sand} is required for method = {.val 'rawls'}.")
    SA <- resolve_arg(sand_quo, data, "sand")
    check_range_01(SA, "sand")
    OC_safe <- pmax(OC, 0.01)
    out$.bulk_density <- 1 / (0.332 - 0.0007251 * SA + 0.1276 * log10(OC_safe))

  } else {
    out$.bulk_density <- ifelse(
      OC < 3,
      1.660 - 0.318 * sqrt(OC),
      0.224 + 0.598 * exp(-0.209 * OC)
    )
  }

  warn_outside_domain(
    list(sand = if (method == "rawls") get0("SA") else NULL, oc = OC),
    .ptf_domain_registry$ptf_bulk_density$inputs,
    paste0("ptf_bulk_density (", method, ")")
  )

  cli::cli_inform(c(
    "i" = "Estimated BD is an approximation. Use measured BD where possible.",
    "i" = "See {.fn ptf_info('ptf_bulk_density')} for measurement method caveats."
  ))

  out
}
