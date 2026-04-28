#' @keywords internal
"_PACKAGE"

#' @section Overview:
#' `tidysoilptf` provides a tidy collection of pedotransfer functions (PTFs)
#' for estimating soil hydraulic properties from basic soil data.
#'
#' ## Parametric PTFs (closed-form equations)
#'
#' | Function | Reference | Output model |
#' |---|---|---|
#' | [ptf_wosten()] | Wösten et al. (1999) | VGM |
#' | [ptf_wosten_class()] | Wösten et al. (1999) | VGM |
#' | [ptf_saxton_rawls()] | Saxton & Rawls (2006) | Tension–moisture |
#' | [ptf_vereecken()] | Vereecken et al. (1989) | VG (m = 1) |
#' | [ptf_weynants()] | Weynants et al. (2009) — corrected | VGM |
#' | [ptf_cosby()] | Cosby et al. (1984) | Campbell/CH |
#' | [ptf_rawls_brakensiek()] | Rawls & Brakensiek (1985) | Brooks–Corey |
#' | [ptf_rawls_1982()] | Rawls et al. (1982) | Point θ(h) |
#' | [ptf_bulk_density()] | Rawls (1983); Manrique & Jones (1991) | BD |
#'
#' ## Machine-learning PTFs
#'
#' | Function | Reference | Output model |
#' |---|---|---|
#' | [ptf_euptf2()] | Szabó et al. (2021) | VGM + uncertainty |
#'
#' ## Utilities
#'
#' | Function | Purpose |
#' |---|---|
#' | [check_shp_plausibility()] | Physical constraint checks on SHP parameters |
#' | [convert_params()] | Convert between Campbell, Brooks–Corey, and VGM |
#' | [ptf_info()] | Print PTF training-domain metadata |
#'
#' @references
#' Weber, T.K.D., Weihermüller, L., Nemes, A., et al. (2024).
#' Hydro-pedotransfer functions: a roadmap for future development.
#' *Hydrology and Earth System Sciences*, 28, 3391–3433.
#' <https://doi.org/10.5194/hess-28-3391-2024>
#'
#' @name tidysoilptf-package
#' @aliases tidysoilptf
NULL
