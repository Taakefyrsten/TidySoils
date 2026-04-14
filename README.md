# TidySoils <img src="tidysoil_hex.svg" align="right" height="139" alt="" />

<!-- badges: start -->
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![R CMD check](https://github.com/Taakefyrsten/TidySoils/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Taakefyrsten/TidySoils/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**Tidy tools for soil science in R.** 
The TidySoils ecosystem brings soil
texture classification, water retention modelling, hydraulic conductivity
analysis, and field infiltration analysis into modern times —
tidyverse/pipe-compatible, tibble-in/tibble-out, and blazingly fast.

---

## Why TidySoils?

Existing soil science R packages were written before the tidyverse era. They
require manual looping over samples, return named vectors or S4 objects, and
don't interoperate with `dplyr` pipelines. TidySoils was designed from the
ground up around three principles:

1. **Pipe-compatible** — every function takes a data frame as its first
   argument and returns a tibble with result columns appended.
2. **Tidy evaluation** — column arguments accept bare column names (like
   `dplyr::mutate()`), scalars, or any mix. No `df$column` indexing.
3. **Vectorised backends** — no R-level loops over rows. All core
   computations operate on vectors, making the functions fast enough for
   raster workflows at millions of cells.

---

## Speed comparison

| Task | Typical existing approach | TidySoils | Speedup |
|------|--------------------------|-----------|---------|
| Classify 10 000 soil samples | soiltexR / aqp row loop ~2.7 s | `classify_texture()` 0.011 s | **~250×** |
| Classify 1 M raster cells | R loop over terra values ~60+ s | `classify_texture()` < 5 s | **>12×** |
| SWRC for 1 M rows | `soilwater::swc()` vectorized ~21 ms | `swrc_van_genuchten()` ~29 ms | ~1.4× overhead (tidy-eval cost) |
| K(h) for 1 M rows | soilwater equivalent ~120 ms | `hydraulic_conductivity()` < 40 ms | **~3×** |
| Fit 500 pedons (4 cores) | `lapply()` sequential | `fit_swrc(workers=4)` parallel | **~4×** |

---

## Code comparison

### Texture classification

```r
# Old approach — loop over rows
library(soiltexR)
results <- character(nrow(df))
for (i in seq_len(nrow(df))) {
  results[i] <- getTexture(df$sand[i], df$silt[i], df$clay[i])
}
df$texture <- results

# TidySoils
library(tidysoiltexture)
df |> classify_texture(sand, silt, clay)
```

### SWRC evaluation in a tidy pipeline

```r
# Old approach — separate loop, manual column binding
library(soilwater)
df$theta <- mapply(function(h, alpha, n) {
  SWC(alpha, 0.05, 0.42, n, h)
}, df$h, df$alpha, df$n)

# TidySoils
library(tidysoilwater)
df |>
  swrc_van_genuchten(theta_r = 0.05, theta_s = 0.42,
                     alpha = alpha, n = n, h = h)
```

### Minidisk infiltration (Zhang 1997)

```r
# Old approach — infiltrodiscR, manual per-sample workflow
library(infiltrodiscR)
vg  <- vg_parameters(texture = "Sandy Loam", suction = "2")
A   <- parameter_A(vg, h = 2)
fit <- infiltration(data = df_sample, time = "time", volume = "volume")
K   <- hydraulic_conductivity(fit, A)

# TidySoils — four steps, any number of samples, one group_by
library(tidysoilinfiltration)
df |>
  group_by(sample_id) |>
  infiltration_cumulative(time = time, volume = volume) |>
  fit_infiltration(.infiltration, .sqrt_time) |>
  left_join(meta, by = "sample_id") |>
  minidisk_conductivity(texture = texture, suction = suction)
```

### Ponded ring infiltration (Horton Kfs)

```r
# Old approach — manual rate calculation, then nls() by hand
rates <- diff(cumulative) / diff(times)
fit   <- nls(rate ~ fc + (f0 - fc) * exp(-k * t), ...)
Kfs   <- coef(fit)[["fc"]]

# TidySoils — raw readings to Kfs in one step
df |>
  group_by(site) |>
  ring_conductivity(time = time, volume = volume, radius = 10)
```

### Spatial classification (terra raster)

```r
# Old approach — extract values, loop, reassemble
vals <- as.data.frame(terra::values(r))
vals$texture <- NA_character_
for (i in seq_len(nrow(vals))) {
  vals$texture[i] <- getTexture(vals$sand[i], vals$silt[i], vals$clay[i])
}

# TidySoils — one line
classify_texture(r / 10, sand = "sand", silt = "silt", clay = "clay")
```

---

## Packages

<table>
<tr>
<td width="50%">

### [tidysoiltexture](https://taakefyrsten.github.io/tidysoiltexture)

USDA soil texture classification and ggplot2 texture triangle plots.

* `classify_texture()` — 12 USDA classes, data frame / sf / SpatRaster
* `gg_texture_triangle()` — publication-ready ternary plots
* `texture_surface()` + `geom_texture_contour()` — continuous fill layers

```r
pak::pak("Taakefyrsten/tidysoiltexture")
```

</td>
<td width="50%">

### [tidysoilwater](https://taakefyrsten.github.io/tidysoilwater)

Van Genuchten soil water retention and Mualem-Van Genuchten K(h).

* `swrc_van_genuchten()` — θ(h) for any parameter × head combination
* `hydraulic_conductivity()` — K(h) at any saturation state (exposed `tau` parameter)
* `soil_water_capacity()` / `soil_water_diffusivity()` / `saturation_index()` — derived quantities
* `fit_swrc()` — NLS fitting, grouped, with constraints and parallel workers
* `fit_swrc_hcc()` — joint simultaneous SWRC + K(h) fitting *(new in v1.2.0)*
* `confint.fit_swrc()` — profile-likelihood confidence intervals *(new in v1.2.0)*

```r
pak::pak("Taakefyrsten/tidysoilwater")
```

</td>
</tr>
<tr>
<td width="50%">

### [tidysoilinfiltration](https://taakefyrsten.github.io/tidysoilinfiltration)

Field infiltration analysis covering three measurement protocols.

* `minidisk_conductivity()` — raw readings → K(h) in four steps (Zhang 1997)
* `ring_conductivity()` — raw readings → Kfs via Horton model in one step
* `fit_infiltration()` / `fit_infiltration_kostiakov()` — Philip & Kostiakov fits
* `beerkan_cumulative()` + `fit_best()` — BeerKan / BEST algorithm

```r
pak::pak("Taakefyrsten/tidysoilinfiltration")
```

</td>
<td width="50%">

</td>
</tr>
</table>

---

## Installation

```r
# Install the full ecosystem via the meta-package:
pak::pak("Taakefyrsten/TidySoils")

# Or install individually:
pak::pak("Taakefyrsten/tidysoiltexture")
pak::pak("Taakefyrsten/tidysoilwater")
pak::pak("Taakefyrsten/tidysoilinfiltration")
```

---

## Design decisions

* **S3 dispatch for spatial types** — `classify_texture()` detects sf and
  terra objects automatically; no separate function to remember.
* **No external spatial dependencies for core operations** — sf and terra are
  in Suggests, not Imports. The packages work without them.
* **Base R parallelism** — `fit_swrc(workers = N)` and `fit_best(workers = N)`
  use `parallel::mclapply()`, a base R function. No future/foreach overhead.
* **IDW not a spatial package** — `texture_surface()` implements inverse
  distance weighting in pure vectorised R.

---

## Standing on the Shoulders of Giants

TidySoils stands on the shoulders of the packages that pioneered soil science in R.
We are sincerly grateful to their authors — their foundational work made all of this 
and close to 2 decades of soil science it possible. In several cases their function 
signatures directly informed our own API design.

| Legacy package | Authors | What it contributed | TidySoils home |
|---|---|---|---|
| [`soilwater`](https://CRAN.R-project.org/package=soilwater) | Cordano, Zottele & Andreis | Van Genuchten SWRC, Mualem K(h), water capacity and diffusivity | `tidysoilwater` |
| [`soilhypfit`](https://CRAN.R-project.org/package=soilhypfit) | Papritz & Lehmann | Simultaneous SWRC + K(h) fitting; the τ (tortuosity) parameter | `tidysoilwater` |
| [`soiltexture`](https://CRAN.R-project.org/package=soiltexture) | Moeys | The Soil Texture Wizard — ternary plots and 15+ classification systems | `tidysoiltexture` |
| [`soiltexR`](https://CRAN.R-project.org/package=soiltexR) | Grunwald | Lightweight USDA classification with `getTexture()` | `tidysoiltexture` |
| [`aqp`](https://CRAN.R-project.org/package=aqp) | Beaudette et al. | Algorithms for quantitative pedology, incl. `textureTriangle()` | `tidysoiltexture` |
| [`infiltrodiscR`](https://CRAN.R-project.org/package=infiltrodiscR) | Salazar Zarzosa et al. | Minidisk infiltrometer workflow (Philip fit, VG lookup, K(h)) | `tidysoilinfiltration` |

### Functionality coverage

The tables below map key functions from legacy packages to their TidySoils
equivalents, so you can verify that no functionality has been lost in the transition.

**Soil water (soilwater + soilhypfit → tidysoilwater)**

| Legacy call | TidySoils equivalent | Since |
|---|---|---|
| `soilwater::swc(alpha, theta_r, theta_s, n, h)` | `swrc_van_genuchten(df, alpha=, n=, h=, ...)` | v1.0.0 |
| `soilwater::swc(...)` K(h) mode | `hydraulic_conductivity(df, ...)` | v1.0.0 |
| `soilwater::cap(...)` | `soil_water_capacity(df, ...)` | v1.1.0 |
| `soilwater::diffusivity(...)` | `soil_water_diffusivity(df, ...)` | v1.1.0 |
| `soilwater::swc(..., saturation_index = TRUE)` | `saturation_index(df, ...)` | v1.1.0 |
| `soilhypfit::hc_model(tau = ...)` | `hydraulic_conductivity(df, tau = ...)` | v1.1.0 |
| *(no equivalent)* | `fit_swrc()` — grouped NLS with constraints and parallel workers | v1.0.0 |
| *(no equivalent)* | `fit_swrc_hcc()` — joint SWRC + K(h) fit | v1.2.0 |
| *(no equivalent)* | `confint.fit_swrc()` — profile-likelihood confidence intervals | v1.2.0 |

> **Note:** `soilwater::watervolume()` — which integrates the SWRC vertically over a
> soil profile to compute total stored water — is outside tidysoilwater's current scope
> (hillslope/water balance domain rather than pedon-level analysis).

**Soil texture (soiltexture + soiltexR + aqp → tidysoiltexture)**

| Legacy call | TidySoils equivalent | Since |
|---|---|---|
| `soiltexR::getTexture(sand, silt, clay)` | `classify_texture(df, sand, silt, clay)` | v1.0.0 |
| `soiltexture::TT.plot(...)` | `gg_texture_triangle(df, ...)` | v1.0.0 |
| `aqp::textureTriangle(...)` | `gg_texture_triangle(df, ...)` | v1.0.0 |
| USDA 12-class system | `classify_texture()` — vectorised, < 0.015 s / 10 000 samples | v1.0.0 |
| sf / SpatRaster S3 dispatch | `classify_texture(sf_or_raster, ...)` | v1.0.0 |
| FAO classification | *(planned — see [roadmap issues](https://github.com/Taakefyrsten/TidySoils/issues))* | — |
| British / USDA-UK system | *(planned — see [roadmap issues](https://github.com/Taakefyrsten/TidySoils/issues))* | — |

> **Note:** `soiltexture` supports 15+ international classification systems.
> tidysoiltexture currently covers the USDA system only. Expanding to FAO and
> British standards is the most important remaining gap and is actively tracked
> in the issue tracker.

**Infiltration (infiltrodiscR → tidysoilinfiltration)**

| Legacy call | TidySoils equivalent | Since |
|---|---|---|
| `infiltrodiscR::infiltration(df, time, volume)` | `infiltration_cumulative(df, time, volume)` | v1.0.0 |
| `infiltrodiscR::vg_par()` | `infiltration_vg_params(df, texture, suction)` | v1.0.0 |
| `infiltrodiscR::parameter_A(vg, h)` | `parameter_A_zhang(df, ...)` | v1.0.0 |
| `infiltrodiscR::hydraulic_conductivity(fit, A)` | `hydraulic_conductivity_minidisk(df, C1, A)` | v1.0.0 |
| Full Minidisk pipeline (manual `nest()` + `map()`) | `minidisk_conductivity(df, texture, suction)` | v1.1.0 |
| *(no equivalent)* | `fit_infiltration_horton()` — Horton exponential decay | v1.0.0 |
| *(no equivalent)* | `fit_infiltration_kostiakov()` — Kostiakov power model | v1.0.0 |
| *(no equivalent)* | `beerkan_cumulative()` + `fit_best()` — BeerKan / BEST algorithm | v1.0.0 |
| *(no equivalent)* | `ring_conductivity()` — ponded ring → Kfs in one step | v1.1.0 |

---

## Roadmap

Feature roadmap items are tracked as
[enhancement issues](https://github.com/Taakefyrsten/TidySoils/issues?q=label%3Aenhancement)
on GitHub. See the issue tracker for status and discussion.

---

## Citation

```r
citation("tidysoiltexture")
citation("tidysoilwater")
citation("tidysoilinfiltration")
```

## License

MIT © Einar Taakefyrsten
