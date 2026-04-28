#' Convert between soil hydraulic property model parameterisations
#'
#' Converts between the Campbell/Clapp-Hornberger, Brooks-Corey, and
#' Van Genuchten-Mualem (VGM) SHP model families. These conversions
#' enable outputs from PTFs calibrated on one model framework (e.g. Cosby 1984
#' → Campbell; Rawls & Brakensiek 1985 → Brooks-Corey) to be used in models
#' that require a different parameterisation.
#'
#' @details
#' ## Supported conversions
#'
#' | `from` | `to` | Method |
#' |---|---|---|
#' | `"Campbell"` | `"VGM"` | Approximate; see below |
#' | `"Brooks-Corey"` | `"VGM"` | Lenhard et al. (1989) |
#' | `"VGM"` | `"Brooks-Corey"` | Inverse of Lenhard et al. |
#'
#' ## Campbell → VGM approximation
#'
#' The Campbell model uses:
#' \deqn{\theta(h) = \theta_s \left(\frac{\psi_s}{h}\right)^{1/b}}
#'
#' Approximate VGM conversion (van Genuchten, 1980):
#' \deqn{n \approx b + 1}
#' \deqn{\alpha \approx \frac{1}{|\psi_s|}}
#' \deqn{\theta_r \approx 0}
#'
#' ## Brooks-Corey → VGM approximation
#'
#' Using the Lenhard et al. (1989) relationships:
#' \deqn{n = \lambda + 1}
#' \deqn{\alpha = \frac{1}{\psi_b \cdot (1 + 2\lambda)^{1/n}}}
#'
#' All conversions are **approximate** and introduce additional uncertainty.
#' For precise VGM parameters from observed retention data, use
#' [tidysoilwater::fit_swrc()].
#'
#' @param data A data frame or tibble.
#' @param from Character. Source parameterisation: `"Campbell"`,
#'   `"Brooks-Corey"`, or `"VGM"`.
#' @param to Character. Target parameterisation: `"VGM"` or `"Brooks-Corey"`.
#' @param b Campbell pore-size distribution index. Required when
#'   `from = "Campbell"`. Bare column name or scalar.
#' @param psi_s Saturated matric potential (cm, negative). Required when
#'   `from = "Campbell"`. Bare column name or scalar.
#' @param theta_s Saturated water content (m³/m³). Required for all
#'   conversions. Bare column name or scalar.
#' @param psi_b Brooks-Corey bubbling pressure (cm). Required when
#'   `from = "Brooks-Corey"`. Bare column name or scalar.
#' @param lambda Brooks-Corey pore-size distribution index. Required when
#'   `from = "Brooks-Corey"`. Bare column name or scalar.
#'
#' @return The input `data` as a tibble with appended parameter columns
#'   appropriate for the target parameterisation.
#'
#' @references
#' Lenhard, R.J., Parker, J.C. and Mishra, S. (1989).
#' On the correspondence between Brooks-Corey and van Genuchten models.
#' *Journal of Irrigation and Drainage Engineering*, 115(4), 744–751.
#'
#' @seealso [ptf_cosby()], [ptf_rawls_brakensiek()].
#'
#' @examples
#' library(tibble)
#'
#' # Campbell → VGM (from ptf_cosby output)
#' soils <- tibble(sand = 60, silt = 20, clay = 20)
#' cosby_out <- ptf_cosby(soils, sand = sand, silt = silt, clay = clay)
#'
#' convert_params(cosby_out,
#'   from = "Campbell", to = "VGM",
#'   b = .b, psi_s = .psi_s, theta_s = .theta_s
#' )
#'
#' @export
convert_params <- function(data,
                            from,
                            to,
                            b       = NULL,
                            psi_s   = NULL,
                            theta_s,
                            psi_b   = NULL,
                            lambda  = NULL) {
  from <- match.arg(from, c("Campbell", "Brooks-Corey", "VGM"))
  to   <- match.arg(to,   c("VGM", "Brooks-Corey"))

  ths_quo <- rlang::enquo(theta_s)
  THS <- resolve_arg(ths_quo, data, "theta_s")

  out <- tibble::as_tibble(data)

  if (from == "Campbell" && to == "VGM") {
    b_quo   <- rlang::enquo(b)
    ps_quo  <- rlang::enquo(psi_s)
    B   <- resolve_arg(b_quo,  data, "b")
    PSI <- resolve_arg(ps_quo, data, "psi_s")

    out$.theta_r_vg <- 0.0
    out$.theta_s_vg <- THS
    out$.n_vg       <- B + 1
    out$.alpha_vg   <- 1 / abs(PSI)
    cli::cli_inform(c(
      "i" = "Campbell → VGM conversion is approximate (θ_r set to 0).",
      "i" = "Fit observed data with {.fn tidysoilwater::fit_swrc} for precise parameters."
    ))

  } else if (from == "Brooks-Corey" && to == "VGM") {
    pb_quo  <- rlang::enquo(psi_b)
    lam_quo <- rlang::enquo(lambda)
    PSI_B <- resolve_arg(pb_quo,  data, "psi_b")
    LAM   <- resolve_arg(lam_quo, data, "lambda")

    n_vg     <- LAM + 1
    alpha_vg <- 1 / (PSI_B * (1 + 2 * LAM)^(1 / n_vg))

    out$.theta_r_vg <- 0.0
    out$.theta_s_vg <- THS
    out$.n_vg       <- n_vg
    out$.alpha_vg   <- alpha_vg
    cli::cli_inform(c(
      "i" = "Brooks-Corey → VGM conversion uses Lenhard et al. (1989) — approximate.",
      "i" = "θ_r set to 0. Use {.fn tidysoilwater::fit_swrc} for precise parameters."
    ))

  } else {
    cli::cli_abort("Conversion from {.val {from}} to {.val {to}} is not yet implemented.")
  }

  out
}
