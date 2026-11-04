# eatTechReport 0.0.0.9000

* Follow the original report figures: compare German modules within each scale;
  show the global mathematics base module separately and compare supplementary
  modules within each focus domain. Use narrow bars, short legends on the right
  and the same corporate colours for each group. Omit extra selection figures
  and in-plot titles, count labels and notes from report output.
* Use Kompetenz in report prose and headings while retaining the existing API
  names. Present competence summaries and percentages with the density plots
  without duplicating them in additional PV tables. Add chapter-based figure
  and table captions, narrative cross-references and separate explanatory notes.
* Display booklet designs as block matrices with narrow blank pause columns
  and explicitly marked norming blocks via optional `blocks$is_norming`.
  Keep timing information in notes rather than inside block cells; retain the
  existing timing data and calculation rules.
* Shade task-matrix columns in corporate colours, use short module headers,
  and show all five mathematics modules together. Task titles are supplied
  through `data$main_test$items$task_label`, consistently for each `task_id`.
* Add a pkgdown workflow that builds and checks pull requests and deploys the
  website from `main` through GitHub Pages, using synthetic examples only.
* Add the opt-in `bericht` scope (schema `0.5.0-draft`) for a complete example
  report through item statistics, transformations, analysis and feedback
  guidance, and references. Its 15 editable public Quarto blocks include five
  new final-chapter blocks. Existing scopes and the default remain unchanged.
* Validate `data$main_test_results` with complete per-item solution proportions
  and logits, separate upstream person/item transformation coefficients per
  scale, and explicit metric and population definitions. Summarise module item
  statistics without transforming person PVs again. Demo coefficients are
  clearly synthetic and must be replaced with approved upstream results.
* Add a task matrix placing module task sequences side by side by task position.
* Add competence-level item-count graphics using supplied assignments and
  shared module axes. `plot_item_levels()` retains the optional overall
  selection view for use outside Word reports.
* Accept optional, complete upstream item-level assignments in
  `data$main_test$item_levels`. Count reused items once overall and once per
  module, and display empty levels explicitly. Synthetic examples include
  illustrative assignments; no item stages are inferred from person PVs/cuts.
* Add the opt-in `haupttest_struktur` scope (schema `0.4.0-draft`) with main-test
  selection, pilot-wave provenance and ordered module contents. Support reused
  items, partial tasks and multiple waves without inflating overall counts.
  Existing scopes and the default remain unchanged.
* Add two editable Quarto blocks for main-test selection and modules, synthetic
  German/mathematics examples, and documentation of the new R input tables.
* Balance visible space above and below table text while preserving Arial 11
  and 1.5 line spacing.
* Add configurable cover authors and a shared affiliation, with visible
  placeholders when unspecified and support for multiple affiliation lines.
* Centre table text vertically, add cell padding and thin horizontal rules
  beneath headers and between data rows, retaining strong outer rules.
* Display minutes as `min`, use umlauts in report text, and report missing
  age information as a percentage of the analysis population.
* Bundle the approved corporate Word template. `render_report()` uses it by
  default with `corporate_template = NULL`; an explicit DOTX or DOCX path remains
  optional. Private source reports, data and editorial text remain local.
* Use Arial at 11 pt or larger, 1.5 line spacing and more space before headings.
  Set heading levels 1–4 to 16/13/12/11 pt, the three-line cover title to 22 pt
  and its subtitle to 18 pt. Reduce the gap between table captions and tables.
* Add strong black outer table rules and spacing between tables and surrounding
  text. Display statistical symbols M, N and SD in italics in tables and plots.
* Revise pilot-study prose and valid-response summaries to follow the established
  technical-report style; use Pilotierungsitems consistently.
* Support optional local Quarto chapters for competence descriptions, study
  administration and analysis, including them in the rendering archive without
  distributing private source texts.
* Extend `example_report()` and Word output with test design and sample sections.
  The default `pilotierung` scope uses schema `0.3.0-draft`; the earlier
  `pilotierung_leistung` scope remains available explicitly.
* Add `validate_report_input()` and `summarise_report_input()` for consistent
  item/task counts, variable booklet designs, participation and analysis
  populations, sample characteristics, and valid item-response counts.
* Include missing categorical answers in percentage denominators and report
  them separately. Keep pilot-item and anchor-item response summaries distinct;
  anchor statistics appear in a separate Word footnote.
* Add five editable Quarto blocks and an article covering the new inputs.
  `edit_report_texts()` now selects the blocks for the requested report scope.
* Allocate table widths explicitly for item pools, booklet positions and sample
  counts so long labels leave enough space for identifiers and numeric headings.
* Add cross-platform R CMD check and Codecov workflows, with additional tests
  for report generation, archived results, and safe recovery after failures.
* Include author ORCIDs and workflow/coverage badges in the documentation.
* Keep internal planning documents locally; user documentation remains in the
  package reference and website articles.
* Provide an installable development package for VERA-3 technical-report drafts.
* Provide reproducible synthetic German and mathematics inputs with 15
  plausible values by default, independent report years, and the agreed
  domain/scale codes.
* Validate complete, unweighted population/PV combinations and calculate
  means, standard deviations, and proficiency-level percentages on the
  reporting scale.
* Plot PV distributions with common smoothing and the same proficiency-level
  percentages returned in the R summaries.
* Render editable Quarto pilot-study sections to Word using the approved
  corporate template, and save a reproducibility snapshot.
  Successful reruns retain the previous output as a backup. With Microsoft Word
  on Windows, update the contents and page-number fields automatically.
* Add function documentation, synthetic website examples, package tests, and
  light/dark logo variants. Private source files, data, and rendered corporate
  documents are excluded from package builds and website examples.
