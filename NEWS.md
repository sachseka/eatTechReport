# eatTechReport 0.0.0.9000

* Add cross-platform R CMD check and Codecov workflows, with additional tests
  for report generation, archived results, and safe recovery after failures.
* Include author ORCIDs and workflow/coverage badges in the documentation.
* Keep internal planning documents locally; user documentation remains in the
  package reference and website articles.
* Introduce an installable development package for the VERA-3 performance
  section. Other technical-report chapters remain under development.
* Provide reproducible synthetic German and mathematics inputs with 15
  plausible values by default, independent report years, and the agreed
  domain/scale codes.
* Validate complete, unweighted population/PV combinations and calculate
  means, standard deviations, and proficiency-level percentages on the
  reporting scale.
* Plot PV distributions with common smoothing and the same proficiency-level
  percentages used in the summary tables.
* Render an editable Quarto performance section to Word using the mandatory
  locally supplied corporate template, and save a reproducibility snapshot.
  Successful reruns retain the previous output as a backup. With Microsoft Word
  on Windows, update the contents and page-number fields automatically.
* Add function documentation, synthetic website examples, package tests, and
  light/dark logo variants. Private templates, data, and rendered corporate
  documents are excluded from package builds and website examples.
