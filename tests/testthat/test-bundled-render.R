test_that("the distributed layout contains no source prose or external template links", {
  template <- system.file("templates", "eatTechReport.docx", package = "eatTechReport")
  expect_true(file.exists(template))
  parts <- tempfile("bundled-template-inspection-")
  extract_word_package(template, parts)
  entries <- list.files(parts, recursive = TRUE, all.files = TRUE)
  expect_false(any(grepl("customXml|comments|glossary|embeddings|vbaProject", entries)))
  doc <- xml2::read_xml(file.path(parts, "word/document.xml"))
  expect_length(xml2::xml_find_all(doc, "//w:t", word_ns()), 0L)
  expect_length(xml2::xml_find_all(doc, "//w:sectPr", word_ns()), 1L)
  relationships <- list.files(parts, pattern = "[.]rels$", recursive = TRUE,
                               all.files = TRUE, full.names = TRUE)
  for (path in relationships) {
    rels <- xml2::read_xml(path)
    expect_length(xml2::xml_find_all(rels, "//*[@TargetMode='External']"), 0L)
  }
  settings <- xml2::read_xml(file.path(parts, "word/settings.xml"))
  expect_length(xml2::xml_find_all(settings, "//w:attachedTemplate", word_ns()), 0L)
  for (entry in entries[grepl("[.]xml$", entries)]) {
    xml <- xml2::read_xml(file.path(parts, entry))
    expect_length(xml2::xml_find_all(xml,
      "//*[local-name()='rsid' or local-name()='rsids' or local-name()='ins' or local-name()='del']"), 0L)
  }
})

test_that("Quarto renders a report with the installed layout and no private inputs", {
  skip_on_cran()
  cli <- quarto::quarto_path()
  skip_if(is.null(cli) || !nzchar(cli), "Quarto CLI is not installed")
  input <- example_report("v3_ma_mg_mm", n_persons = 30L, n_pv = 1L,
                           scope = "haupttest_struktur",
                           authors = c("Ada Beispiel", "B\u00e9la & Beispiel [2]"),
                           affiliation = c("Institut f\u00fcr Beispielstudien", "Universit\u00e4t Musterstadt"))
  output <- tempfile("bundled-render-")
  expect_warning(result <- render_report(input$config, input$data,
                                          output_dir = output, update_fields = "none"),
                   "fields_pending")
  parts <- tempfile("bundled-render-inspection-")
  extract_word_package(result$path, parts)
  doc <- xml2::read_xml(file.path(parts, "word/document.xml"))
  ns <- word_ns()
  styles <- xml2::read_xml(file.path(parts, "word/styles.xml"))
  title_id <- xml2::xml_attr(xml2::xml_find_first(styles, "w:style[w:name/@w:val='Title']", ns),
                              "w:styleId", ns)
  title <- xml2::xml_find_first(doc, paste0("//w:p[w:pPr/w:pStyle/@w:val='", title_id, "']"), ns)
  expect_match(xml2::xml_text(title), paste("Vergleichsarbeiten", input$config$report$main_year))
  expect_match(xml2::xml_text(title), "3. JahrgangsstufeMathematik", fixed = TRUE)
  expect_length(xml2::xml_find_all(title, ".//w:br", ns), 2L)
  expect_match(xml2::xml_text(doc), "Technischer Bericht", fixed = TRUE)
  author <- xml2::xml_find_first(doc, "//w:p[w:pPr/w:pStyle/@w:val='ReportAuthors']", ns)
  affiliation <- xml2::xml_find_first(doc, "//w:p[w:pPr/w:pStyle/@w:val='ReportAffiliation']", ns)
  expect_identical(xml2::xml_text(author), "Ada Beispiel & B\u00e9la & Beispiel [2]")
  expect_identical(xml2::xml_text(affiliation), paste(input$config$report$affiliation, collapse = ""))
  expect_length(xml2::xml_find_all(affiliation, ".//w:br", ns), 1L)
  expect_identical(xml2::xml_attr(xml2::xml_find_first(author, "preceding-sibling::*[1]/w:pPr/w:pStyle", ns),
                                 "w:val", ns),
                   xml2::xml_attr(xml2::xml_find_first(styles, "w:style[w:name/@w:val='Subtitle']", ns),
                                   "w:styleId", ns))
  expect_match(xml2::xml_text(doc), "synthetisch", ignore.case = TRUE)
  expect_gt(length(xml2::xml_find_all(doc, "//w:tbl", ns)), 0L)
  expect_gt(length(xml2::xml_find_all(doc, "//w:drawing", ns)), 0L)
  expect_match(xml2::xml_text(doc), "Auswahl", fixed = TRUE)
  expect_true(all(c("haupttest_auswahl.qmd", "haupttest_module.qmd") %in%
                    list.files(file.path(result$archive_dir, "texts"))))
  expect_identical(readRDS(file.path(result$archive_dir, "inputs.rds"))$data$main_test,
                    input$data$main_test)
  expect_identical(readRDS(file.path(result$archive_dir, "summaries.rds"))$main_test,
                    summarise_report_input(input)$main_test)
  expect_identical(result$manifest$template_file, "eatTechReport.docx")
  expect_identical(result$manifest$report_md5, unname(tools::md5sum(result$path)))
})
