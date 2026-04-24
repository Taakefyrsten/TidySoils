#' euptf v2 pedotransfer functions (Szabó et al., 2021)
#'
#' Tidy wrapper around the European Hydropedological PTF v2 random forest
#' models (euptf2 package). Returns VGM parameters with built-in prediction
#' uncertainty. This is the current state-of-the-art European PTF.
#'
#' @details
#' ## Dependency
#'
#' This function requires the `euptf2` package
#' (GitHub: `tkdweber/euptf2`). Install with:
#' ```r
#' remotes::install_github("tkdweber/euptf2")
#' ```
#'
#' ## Flexible predictor hierarchy
#'
#' euptf2 supports flexible predictor combinations. The minimum required
#' input is particle size distribution + depth class. Additional predictors
#' (OC, BD, CaCO3, pH, CEC) improve predictions when available.
#'
#' ## Uncertainty
#'
#' The random forest models provide quantile-based prediction uncertainty.
#' When `uncertainty = TRUE`, columns pairs (`*_q05`, `*_q95`) are returned
#' alongside the median predictions (`*_q50`).
#'
#' @param data A data frame or tibble.
#' @param sand Sand content (%). Bare column name or scalar.
#' @param silt Silt content (%). Bare column name or scalar.
#' @param clay Clay content (%). Bare column name or scalar.
#' @param depth_class Topsoil/subsoil flag. Bare column name or scalar.
#'   Typically `"topsoil"` or `"subsoil"` — see `euptf2` documentation.
#' @param om Organic matter content (%). Optional. Bare column name or scalar.
#' @param bulk_density Bulk density (g/cm³). Optional. Bare column name or scalar.
#' @param uncertainty Logical. If `TRUE`, return 5th and 95th percentile
#'   prediction intervals alongside median. Default `FALSE`.
#'
#' @return The input `data` as a tibble. When `uncertainty = FALSE`, appended
#'   columns are `.theta_s`, `.theta_fc`, `.theta_wp`, `.awc`, `.K_sat`, and
#'   VGM parameters. When `uncertainty = TRUE`, each column is accompanied
#'   by `_q05` and `_q95` variants.
#'
#' @references
#' Szabó, B., Weynants, M. and Weber, T.K.D. (2021).
#' Updated European pedotransfer functions with communicated uncertainties in
#' the predicted variables (euptfv2).
#' *Geoscientific Model Development*, 14, 151–175.
#' <https://doi.org/10.5194/gmd-14-151-2021>
#'
#' @seealso [ptf_wosten()] for the parametric European alternative,
#'   [ptf_info()].
#'
#' @examples
#' \dontrun{
#' library(tibble)
#'
#' soils <- tibble(
#'   sand        = c(65,  20, 10),
#'   silt        = c(20,  50, 30),
#'   clay        = c(15,  30, 60),
#'   depth_class = c("topsoil", "topsoil", "subsoil")
#' )
#'
#' ptf_euptf2(soils,
#'   sand = sand, silt = silt, clay = clay,
#'   depth_class = depth_class
#' )
#'
#' # With uncertainty intervals
#' ptf_euptf2(soils,
#'   sand = sand, silt = silt, clay = clay,
#'   depth_class = depth_class,
#'   uncertainty = TRUE
#' )
#' }
#'
#' @export
ptf_euptf2 <- function(data, sand, silt, clay, depth_class,
                        om = NULL, bulk_density = NULL,
                        uncertainty = FALSE) {
  if (!requireNamespace("euptf2", quietly = TRUE))
    cli::cli_abort(c(
      "{.pkg euptf2} is required for {.fn ptf_euptf2}.",
      "i" = 'Install with: {.code remotes::install_github("tkdweber/euptf2")}'
    ))

  sand_quo <- rlang::enquo(sand)
  silt_quo <- rlang::enquo(silt)
  clay_quo <- rlang::enquo(clay)
  dep_quo  <- rlang::enquo(depth_class)
  om_quo   <- rlang::enquo(om)
  bd_quo   <- rlang::enquo(bulk_density)

  SA  <- resolve_arg(sand_quo, data, "sand")
  SI  <- resolve_arg(silt_quo, data, "silt")
  CL  <- resolve_arg(clay_quo, data, "clay")
  DEP <- resolve_arg(dep_quo,  data, "depth_class")
  OM  <- if (!rlang::quo_is_null(om_quo))  resolve_arg(om_quo, data, "om")           else NULL
  BD  <- if (!rlang::quo_is_null(bd_quo))  resolve_arg(bd_quo, data, "bulk_density") else NULL

  warn_outside_domain(
    list(sand = SA, silt = SI, clay = CL),
    .ptf_domain_registry$ptf_euptf2$inputs,
    "ptf_euptf2"
  )

  # Build predictor data.frame for euptf2 — column names must match its spec
  euptf_input <- data.frame(
    SAND = SA, SILT = SI, CLAY = CL,
    DEPTH = DEP,
    stringsAsFactors = FALSE
  )
  if (!is.null(OM)) euptf_input$OC <- OM / 1.724  # OM → OC conversion
  if (!is.null(BD)) euptf_input$BD <- BD

  # euptf2::euptf2() returns a data.frame; wrap results as tibble columns
  result <- euptf2::euptf2(euptf_input, quantiles = if (uncertainty) c(0.05, 0.5, 0.95) else 0.5)

  out <- tibble::as_tibble(data)
  # Bind result columns with tidy .prefix naming
  for (nm in names(result)) {
    out[[paste0(".", nm)]] <- result[[nm]]
  }
  out
}
