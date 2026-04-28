#' PTF training-domain metadata
#'
#' Returns a structured list describing the geographic origin, training dataset,
#' input ranges, and soil-type coverage of a PTF. Use this to assess whether a
#' PTF is appropriate for your soils before applying it.
#'
#' @param ptf Character. Name of the PTF function (e.g. `"ptf_wosten"`,
#'   `"ptf_cosby"`).
#'
#' @return A named list with elements:
#' \describe{
#'   \item{`reference`}{Full citation string.}
#'   \item{`n_samples`}{Number of training samples (if known).}
#'   \item{`geography`}{Geographic coverage of the training dataset.}
#'   \item{`soil_types`}{Soil types / orders represented.}
#'   \item{`shp_model`}{SHP model family of the output (`"VGM"`, `"Campbell"`, `"Brooks-Corey"`, etc.).}
#'   \item{`inputs`}{Named list of input variable training ranges.}
#'   \item{`caveats`}{Character vector of known limitations.}
#' }
#'
#' @examples
#' ptf_info("ptf_wosten")
#' ptf_info("ptf_cosby")
#' ptf_info("ptf_saxton_rawls")
#'
#' @export
ptf_info <- function(ptf) {
  info <- .ptf_domain_registry[[ptf]]
  if (is.null(info))
    cli::cli_abort(c(
      "No domain metadata registered for {.val {ptf}}.",
      "i" = "Available PTFs: {.val {names(.ptf_domain_registry)}}."
    ))
  structure(info, class = "ptf_info")
}

#' @export
print.ptf_info <- function(x, ...) {
  cli::cli_h1(x$ptf)
  cli::cli_text("{.strong Reference:} {x$reference}")
  cli::cli_text("{.strong Training samples:} {x$n_samples %||% 'unknown'}")
  cli::cli_text("{.strong Geography:} {x$geography}")
  cli::cli_text("{.strong Soil types:} {x$soil_types}")
  cli::cli_text("{.strong SHP model output:} {x$shp_model}")
  cli::cli_h2("Input training ranges")
  for (nm in names(x$inputs)) {
    rng <- x$inputs[[nm]]
    cli::cli_text("  {.field {nm}}: [{rng[1]}, {rng[2]}]")
  }
  if (length(x$caveats) > 0) {
    cli::cli_h2("Caveats")
    cli::cli_bullets(stats::setNames(x$caveats, rep("!", length(x$caveats))))
  }
  invisible(x)
}

# Central registry — each ptf_*.R file adds its entry here via .onLoad or
# directly at package load time. Populated in R/ptf_domains.R.
.ptf_domain_registry <- list()
