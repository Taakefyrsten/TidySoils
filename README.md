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
| SWRC for 1 M rows | manual vectorisation (baseline) | `swrc_van_genuchten()` < 20 ms | reference |
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
vg <- vg_parameters(texture = "Sandy Loam", suction = "2")
A  <- parameter_A(vg, h = 2)
fit <- infiltration(data = df_sample, time = "time", volume = "volume")
K  <- hydraulic_conductivity(fit, A)

# TidySoils — one pipeline, any number of samples
library(tidysoilinfiltration)
df |>
  group_by(sample_id) |>
  infiltration_cumulative(time = time, volume = volume) |>
  group_by(sample_id) |>
  fit_infiltration(infiltration_col = .infiltration, sqrt_time_col = .sqrt_time) |>
  left_join(meta, by = "sample_id") |>
  infiltration_vg_params(texture = texture, suction = suction) |>
  hydraulic_conductivity_minidisk(C1 = .C1, A = .A)
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
* `hydraulic_conductivity()` — K(h) at any saturation state
* `fit_swrc()` — NLS fitting, grouped, with optional parallel workers

```r
pak::pak("Taakefyrsten/tidysoilwater")
```

</td>
</tr>
<tr>
<td width="50%">

### [tidysoilinfiltration](https://taakefyrsten.github.io/tidysoilinfiltration)

Field infiltration analysis covering three measurement protocols.

* `infiltration_cumulative()` / `infiltration_rate()` — Minidisk & ring
* `hydraulic_conductivity_minidisk()` — K(h) via Zhang (1997)
* `fit_infiltration_horton()` / `fit_infiltration_kostiakov()` — ring models
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

## Roadmap

* Bayesian parameter fitting for clay soils (brms / Stan)
* FAO and British soil texture classification systems
* Additional pedotransfer function families (Rawls & Brakensiek, Rosetta 3)
* Shiny explorer app for interactive texture and retention analysis

---

## Citation

```r
citation("tidysoiltexture")
citation("tidysoilwater")
citation("tidysoilinfiltration")
```

## License

MIT © Einar Taakefyrsten
