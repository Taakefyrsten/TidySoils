# tidysoilptf 0.1.0

* Initial release.
* Parametric PTFs: `ptf_wosten()`, `ptf_wosten_class()`, `ptf_saxton_rawls()`,
  `ptf_vereecken()`, `ptf_weynants()`, `ptf_cosby()`, `ptf_rawls_brakensiek()`,
  `ptf_rawls_1982()`.
* Machine-learning PTF wrapper: `ptf_euptf2()` (requires `euptf2` package).
* Bulk density estimation: `ptf_bulk_density()`.
* Physical plausibility checks: `check_shp_plausibility()`.
* Parameter model converters: `convert_params()` (Campbell → VGM, Brooks-Corey → VGM).
* Training-domain metadata registry and `ptf_info()` generic.
* All PTFs issue `cli_warn()` when inputs fall outside the PTF's training range.
