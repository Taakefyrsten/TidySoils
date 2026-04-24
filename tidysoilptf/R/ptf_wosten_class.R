#' Wösten et al. (1999) class pedotransfer functions
#'
#' Returns Van Genuchten–Mualem parameters from a lookup table keyed by FAO
#' texture class and topsoil/subsoil designation. 10 parameter sets total
#' (5 texture classes × 2 depth positions), as published in Wösten et al.
#' (1999), Table 1.
#'
#' @details
#' ## Texture class codes
#'
#' | Code | Description |
#' |---|---|
#' | `"Cs"` | Coarse (sand, loamy sand) |
#' | `"Ms"` | Medium (silt, silt loam, loam, sandy loam) |
#' | `"Mf"` | Medium fine (sandy clay loam) |
#' | `"Fi"` | Fine (clay loam, silty clay loam, sandy clay) |
#' | `"Vc"` | Very fine (clay, silty clay) |
#'
#' These correspond to the HYPRES texture classification, which broadly maps
#' to USDA texture classes as shown above.
#'
#' @param data A data frame or tibble.
#' @param texture_class Texture class code (`"Cs"`, `"Ms"`, `"Mf"`, `"Fi"`,
#'   or `"Vc"`). Bare column name or character scalar.
#' @param topsoil Logical or 0/1. `TRUE` / `1` for topsoil, `FALSE` / `0` for
#'   subsoil. Bare column name or scalar.
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
#' @seealso [ptf_wosten()] for the continuous variant.
#'
#' @examples
#' library(tibble)
#'
#' soils <- tibble(
#'   texture_class = c("Cs", "Ms", "Fi", "Vc"),
#'   topsoil       = c(TRUE, TRUE, FALSE, FALSE)
#' )
#'
#' ptf_wosten_class(soils, texture_class = texture_class, topsoil = topsoil)
#'
#' @export
ptf_wosten_class <- function(data, texture_class, topsoil) {
  tc_quo  <- rlang::enquo(texture_class)
  top_quo <- rlang::enquo(topsoil)

  TC <- resolve_arg(tc_quo,  data, "texture_class")
  TS <- as.integer(resolve_arg(top_quo, data, "topsoil"))

  valid_classes <- c("Cs", "Ms", "Mf", "Fi", "Vc")
  bad <- !TC %in% valid_classes
  if (any(bad))
    cli::cli_abort(c(
      "Unknown texture class in {.arg texture_class}.",
      "x" = "Got: {.val {unique(TC[bad])}}.",
      "i" = "Valid classes: {.val {valid_classes}}."
    ))

  # Wösten et al. (1999) Table 1
  # Rows: Cs_top, Cs_sub, Ms_top, Ms_sub, Mf_top, Mf_sub, Fi_top, Fi_sub, Vc_top, Vc_sub
  lut <- data.frame(
    class   = c("Cs","Cs","Ms","Ms","Mf","Mf","Fi","Fi","Vc","Vc"),
    topsoil = c( 1L,  0L,  1L,  0L,  1L,  0L,  1L,  0L,  1L,  0L),
    theta_r = c(0.025,0.025,0.010,0.010,0.010,0.010,0.010,0.010,0.010,0.010),
    theta_s = c(0.403,0.366,0.439,0.387,0.430,0.412,0.520,0.450,0.614,0.520),
    alpha   = c(0.0383,0.0430,0.0314,0.0083,0.0083,0.0051,0.0367,0.0265,0.0265,0.0332),
    n       = c(1.3774,1.5206,1.1804,1.2539,1.2539,1.3549,1.1012,1.1033,1.1033,1.2039),
    K_sat   = c(60.0,  7.2,  12.7,  25.0,  25.0,  6.0,   1.04,  0.26,  0.26,  1.69),
    L       = c(-1.175,2.146,  -2.342, 0.851, 0.851, -0.756, 0.000, 0.000, 0.000, -1.298),
    stringsAsFactors = FALSE
  )

  key <- data.frame(class = TC, topsoil = TS, stringsAsFactors = FALSE)
  idx <- match(
    paste(key$class, key$topsoil),
    paste(lut$class, lut$topsoil)
  )

  out <- tibble::as_tibble(data)
  out$.theta_r <- lut$theta_r[idx]
  out$.theta_s <- lut$theta_s[idx]
  out$.alpha   <- lut$alpha[idx]
  out$.n       <- lut$n[idx]
  out$.K_sat   <- lut$K_sat[idx]
  out$.L       <- lut$L[idx]
  out
}
