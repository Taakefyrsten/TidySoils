#' TidySoils: Tidy Tools for Soil Science
#'
#' A meta-package that installs and attaches the TidySoils ecosystem:
#'
#' * **tidysoiltexture** — USDA soil texture classification and ggplot2-based
#'   texture triangle visualisation
#' * **tidysoilwater** — Van Genuchten soil water retention and Mualem-Van
#'   Genuchten unsaturated hydraulic conductivity modelling
#' * **tidysoilinfiltration** — Minidisk (Zhang 1997), ring (Philip / Horton /
#'   Kostiakov), and BeerKan (BEST; Lassabatère et al. 2006) infiltration
#'   analysis
#'
#' All packages are pipe-compatible, accept and return tibbles, and use tidy
#' evaluation for column arguments.
#'
#' @docType package
#' @name TidySoils-package
#' @aliases TidySoils
#'
#' @seealso
#' * [tidysoiltexture::classify_texture()]
#' * [tidysoiltexture::gg_texture_triangle()]
#' * [tidysoilwater::swrc_van_genuchten()]
#' * [tidysoilwater::hydraulic_conductivity()]
#' * [tidysoilwater::fit_swrc()]
#' * [tidysoilinfiltration::minidisk_conductivity()]
#' * [tidysoilinfiltration::ring_conductivity()]
#' * [tidysoilinfiltration::infiltration_cumulative()]
#' * [tidysoilinfiltration::beerkan_cumulative()]
#' * [tidysoilinfiltration::fit_infiltration()]
#' * [tidysoilinfiltration::fit_best()]
#'
#' @references
#' Van Genuchten, M. Th. (1980). A closed-form equation for predicting the
#' hydraulic conductivity of unsaturated soils. *Soil Science Society of
#' America Journal*, 44(5), 892–898.
#' <https://doi.org/10.2136/sssaj1980.03615995004400050002x>
#'
#' Mualem, Y. (1976). A new model for predicting the hydraulic conductivity of
#' unsaturated porous media. *Water Resources Research*, 12(3), 513–522.
#' <https://doi.org/10.1029/WR012i003p00513>
#'
#' Lassabatère, L. et al. (2006). Beerkan estimation of soil transfer
#' parameters through infiltration experiments—BEST. *Soil Science Society of
#' America Journal*, 70(2), 521–532.
#' <https://doi.org/10.2136/sssaj2005.0026>
#'
#' Zhang, R. (1997). Determination of soil sorptivity and hydraulic
#' conductivity from the disk infiltrometer. *Soil Science Society of America
#' Journal*, 61(4), 1024–1030.
#' <https://doi.org/10.2136/sssaj1997.03615995006100060008x>
"_PACKAGE"
