# Training-domain metadata registry.
# Each entry is a named list consumed by ptf_info() and warn_outside_domain().
# Ranges follow the training datasets as documented in the source papers and
# the Weber et al. (2024) roadmap review.

.ptf_domain_registry <- list(

  ptf_wosten = list(
    ptf        = "ptf_wosten",
    reference  = "Wösten et al. (1999). Geoderma 90:169-185.",
    n_samples  = 5521L,
    geography  = "Western Europe (HYPRES database, 12 countries). Biased toward NW Europe.",
    soil_types = "Mineral soils; no organic/peat soils.",
    shp_model  = "VGM",
    inputs     = list(
      sand         = c(0,   100),
      silt         = c(0,   100),
      clay         = c(0,   100),
      om           = c(0,   15),
      bulk_density = c(0.8, 1.8)
    ),
    caveats = c(
      "Training data biased toward western Europe — not reliable for tropical, arid, or eastern European soils.",
      "Lehmann et al. (2020) found ~30% of global grid cells produce unphysical evaporation lengths using these parameters.",
      "Does not represent organic soils or soils with BD < 0.8 g/cm3."
    )
  ),

  ptf_wosten_class = list(
    ptf        = "ptf_wosten_class",
    reference  = "Wösten et al. (1999). Geoderma 90:169-185. Table 1.",
    n_samples  = NA_integer_,
    geography  = "Western Europe (HYPRES).",
    soil_types = "5 FAO texture classes x topsoil/subsoil (10 parameter sets total).",
    shp_model  = "VGM",
    inputs     = list(),
    caveats = c(
      "Only 10 parameter sets — extremely coarse.",
      "Same geographic limitations as ptf_wosten (continuous)."
    )
  ),

  ptf_saxton_rawls = list(
    ptf        = "ptf_saxton_rawls",
    reference  = "Saxton & Rawls (2006). SSSA J. 70:1569-1578.",
    n_samples  = 1722L,
    geography  = "USA (USDA soil database, predominantly A-horizon samples).",
    soil_types = "Mineral soils only. Excludes organic soils.",
    shp_model  = "Tension-moisture curve (not VGM)",
    inputs     = list(
      sand         = c(5,   70),
      clay         = c(5,   60),
      om           = c(0.5, 8),
      bulk_density = c(1.0, 1.8)
    ),
    caveats = c(
      "Explicitly excludes organic soils and BD outside 1.0-1.8 g/cm3; widely misapplied globally (Weber et al. 2024).",
      "Based on A-horizon samples — use with caution for subsoil parameterisation.",
      "Not appropriate for tropical soils with different clay mineralogy."
    )
  ),

  ptf_vereecken = list(
    ptf        = "ptf_vereecken",
    reference  = "Vereecken et al. (1989). Soil Science 148:389-403.",
    n_samples  = 182L,
    geography  = "Belgium.",
    soil_types = "Mineral soils from Belgian soil survey.",
    shp_model  = "VG with m=1 (NOT standard VGM — not directly compatible with Mualem HCC)",
    inputs     = list(
      sand         = c(0,  85),
      clay         = c(0,  65),
      oc           = c(0,  5),
      bulk_density = c(1.0, 1.9)
    ),
    caveats = c(
      "Uses VG with m=1, not m=1-1/n. Outputs are NOT directly usable in Mualem conductivity without re-parameterisation.",
      "Small training set (182 samples) from Belgium only.",
      "Top benchmark performer in multiple comparative studies despite small dataset."
    )
  ),

  ptf_weynants = list(
    ptf        = "ptf_weynants",
    reference  = paste0(
      "Weynants et al. (2009). VZJ 8:86-95. ",
      "Corrected coefficients: Weihermüller et al. (2017)."
    ),
    n_samples  = 166L,
    geography  = "Belgium.",
    soil_types = "Mineral soils from Belgian soil survey.",
    shp_model  = "VGM (theta_r = 0 constrained)",
    inputs     = list(
      sand         = c(0,  85),
      clay         = c(0,  65),
      oc           = c(0,  5),
      bulk_density = c(1.0, 1.9)
    ),
    caveats = c(
      "Coefficients in original 2009 paper contain errors — only corrected version (Weihermüller et al. 2017) is implemented here.",
      "Not suitable for matric potentials > -6 cm (macropore domain excluded by design).",
      "Small Belgian dataset; Belgian climate and mineralogy."
    )
  ),

  ptf_cosby = list(
    ptf        = "ptf_cosby",
    reference  = "Cosby et al. (1984). Water Resources Research 20:682-690.",
    n_samples  = 1448L,
    geography  = "USA (23 states).",
    soil_types = "Temperate mineral soils. No organic/peat, tropical, or permafrost soils.",
    shp_model  = "Campbell / Clapp-Hornberger",
    inputs     = list(
      sand = c(5,  90),
      silt = c(5,  80),
      clay = c(5,  60)
    ),
    caveats = c(
      "Highly questionable for global LSM use — does not represent organic, tropical, or permafrost soils (Weber et al. 2024).",
      "Output is Campbell/Clapp-Hornberger, not VGM. Use convert_params() to convert.",
      "No bulk density or organic matter input — cannot reflect management or land-use effects.",
      "Default in CLM, JULES, Noah-MP despite these limitations."
    )
  ),

  ptf_rawls_brakensiek = list(
    ptf        = "ptf_rawls_brakensiek",
    reference  = "Rawls & Brakensiek (1985). Proc. ASCE Watershed Mgmt. Symp.",
    n_samples  = 5320L,
    geography  = "USA.",
    soil_types = "Mineral soils from USDA Cooperative Soil Survey.",
    shp_model  = "Brooks-Corey",
    inputs     = list(
      sand         = c(5,  90),
      clay         = c(5,  60),
      bulk_density = c(1.0, 1.8)
    ),
    caveats = c(
      "Output is Brooks-Corey (psi_b, lambda), not VGM. Use convert_params() for VGM.",
      "Porosity is derived from BD assuming particle density of 2.65 g/cm3."
    )
  ),

  ptf_rawls_1982 = list(
    ptf        = "ptf_rawls_1982",
    reference  = "Rawls et al. (1982). Trans. ASAE 25:1316-1320.",
    n_samples  = NA_integer_,
    geography  = "USA (Cooperative Soil Survey).",
    soil_types = "Mineral soils.",
    shp_model  = "Point theta(h) at 12 matric potentials",
    inputs     = list(
      sand = c(0, 100),
      clay = c(0, 100),
      om   = c(0, 8)
    ),
    caveats = c(
      "Nemes et al. (2009) found systematic biases when evaluated at US national scale.",
      "Historical benchmark only — use as a reference, not primary PTF."
    )
  ),

  ptf_bulk_density = list(
    ptf        = "ptf_bulk_density",
    reference  = paste0(
      "Rawls (1983). Soil Science 135:123-125. ",
      "Manrique & Jones (1991). SSSA J. 55:476-481."
    ),
    n_samples  = NA_integer_,
    geography  = "USA (Rawls); USA + tropics (Manrique & Jones).",
    soil_types = "Mineral soils; Manrique & Jones extends to some tropical soils.",
    shp_model  = "BD estimation (not SHP)",
    inputs     = list(
      sand = c(0, 100),
      clay = c(0, 100),
      oc   = c(0, 10)
    ),
    caveats = c(
      "BD measurement methods are not standardised — core vs. clod methods diverge systematically (Weber et al. 2024, Fig. 8).",
      "Estimated BD is an approximation; use measured BD when available."
    )
  ),

  ptf_euptf2 = list(
    ptf        = "ptf_euptf2",
    reference  = "Szabó et al. (2021). Geosci. Model Dev. 14:151-175.",
    n_samples  = NA_integer_,
    geography  = "Europe (EU-HYDI database, European-wide coverage).",
    soil_types = "European mineral and some organic soils.",
    shp_model  = "VGM + prediction uncertainty (random forests)",
    inputs     = list(
      sand = c(0, 100),
      silt = c(0, 100),
      clay = c(0, 100)
    ),
    caveats = c(
      "Random forest model objects required (euptf2 package). Not pure-R.",
      "European training data — extrapolation to other continents is not validated.",
      "Web interface available at https://ptfinterface.rissac.hu"
    )
  )
)
