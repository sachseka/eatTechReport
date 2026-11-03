# eatTechReport 0.0.0.9000

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
* Provide an installable development package for VERA-3 pilot-study sections.
  Other technical-report chapters remain under development.
* Provide reproducible synthetic German and mathematics inputs with 15
  plausible values by default, independent report years, and the agreed
  domain/scale codes.
* Validate complete, unweighted population/PV combinations and calculate
  means, standard deviations, and proficiency-level percentages on the
  reporting scale.
* Plot PV distributions with common smoothing and the same proficiency-level
  percentages used in the summary tables.
* Render editable Quarto pilot-study sections to Word using the approved
  corporate template, and save a reproducibility snapshot.
  Successful reruns retain the previous output as a backup. With Microsoft Word
  on Windows, update the contents and page-number fields automatically.
* Add function documentation, synthetic website examples, package tests, and
  light/dark logo variants. Private source files, data, and rendered corporate
  documents are excluded from package builds and website examples.
