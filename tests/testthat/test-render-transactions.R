# Exercise the complete orchestration with synthetic Word XML. Only executable
# boundaries are replaced; validation, plots, archives and directory moves run.
render_fixture <- function() {
  root <- tempfile("render-fixture-")
  dir.create(root)
  template <- file.path(root, "corporate fixture.dotx")
  synthetic_word_template(template)
  list(root = root, template = template, output = file.path(root, "result"),
       input = example_report("v3_ma_mg_mm", n_persons = 2L, n_pv = 1L))
}

fake_quarto_render <- function(input, output_file, ...) {
  directory <- dirname(input)
  file.copy(file.path(directory, "corporate-reference.docx"),
            file.path(directory, output_file))
  invisible(NULL)
}

local_render_boundaries <- function(quarto_render = fake_quarto_render,
                                    word_available = FALSE, .env = parent.frame()) {
  local_mocked_bindings(quarto_path = function() "quarto-test",
                         quarto_version = function() package_version("1.8.26"),
                         quarto_render = quarto_render,
                         .package = "quarto", .env = .env)
  local_mocked_bindings(windows_word_available = function() word_available,
                         .package = "eatTechReport", .env = .env)
}

render_fixture_report <- function(fixture, ...) {
  render_report(fixture$input$config, fixture$input$data,
                 corporate_template = fixture$template,
                 output_dir = fixture$output, ...)
}

test_that("a successful rendering archives exact inputs and records pending fields", {
  fixture <- render_fixture()
  original_template <- tools::md5sum(fixture$template)
  fixture$input$config$scales$MO$label <- "Mathematik [A] *B*"
  local_render_boundaries()

  expect_warning(result <- render_fixture_report(fixture), "fields_pending")
  expect_s3_class(result, "eat_report")
  expect_true(file.exists(result$path))
  expect_null(result$previous_output_dir)
  expect_identical(result$manifest$status, "fields_pending")
  expect_false(result$manifest$fields_updated)
  expect_identical(tools::md5sum(fixture$template), original_template)
  expect_identical(readRDS(file.path(result$archive_dir, "inputs.rds")), fixture$input)
  expect_identical(readRDS(file.path(result$archive_dir, "summaries.rds")),
                    summarise_report_input(fixture$input))
  expect_identical(result$manifest$report_md5, unname(tools::md5sum(result$path)))
  expect_identical(result$manifest$main_source_md5,
                    unname(tools::md5sum(file.path(fixture$output, "report.qmd"))))
  expect_true(file.exists(file.path(fixture$output, "figures/MO.png")))
  labels <- readRDS(file.path(result$archive_dir, "display-labels.rds"))
  expect_identical(unname(labels$scales), "Mathematik \\[A\\] \\*B\\*")
  expect_false(any(grepl("parts-", list.files(fixture$output, all.files = TRUE))))
})

test_that("successful overwrites retain the entire previous output as a backup", {
  fixture <- render_fixture()
  local_render_boundaries()
  first <- suppressWarnings(render_fixture_report(fixture))
  old_hash <- tools::md5sum(first$path)
  note <- file.path(fixture$output, "review-notes.txt")
  writeLines("Preserve these review notes.", note)
  old_manifest <- readRDS(file.path(first$archive_dir, "manifest.rds"))
  fixture$input$data$pvs$value <- fixture$input$data$pvs$value + 25

  expect_error(render_fixture_report(fixture), "nicht leer")
  result <- suppressWarnings(render_fixture_report(fixture, overwrite = TRUE))
  expect_identical(unname(tools::md5sum(file.path(result$previous_output_dir, "report.docx"))),
                    unname(old_hash))
  expect_identical(readLines(file.path(result$previous_output_dir, "review-notes.txt")),
                    "Preserve these review notes.")
  expect_identical(readRDS(file.path(result$previous_output_dir, "archive/manifest.rds")), old_manifest)
  expect_identical(readRDS(file.path(result$archive_dir, "inputs.rds")), fixture$input)
  expect_false(file.exists(file.path(fixture$output, "review-notes.txt")))
})

test_that("Quarto failures leave the previous report and manifest consistent", {
  fixture <- render_fixture()
  local_render_boundaries()
  previous <- suppressWarnings(render_fixture_report(fixture))
  hashes <- tools::md5sum(c(previous$path, file.path(previous$archive_dir, "manifest.rds"),
                            file.path(previous$archive_dir, "inputs.rds")))
  local_mocked_bindings(quarto_render = function(...) stop("Quarto render failed"), .package = "quarto")
  expect_error(suppressMessages(suppressWarnings(render_fixture_report(fixture, overwrite = TRUE))),
                 "Quarto render failed")
  expect_identical(tools::md5sum(names(hashes)), hashes)
  failures <- list.files(fixture$root, pattern = "^\\.eatTechReport-render-", full.names = TRUE,
                         all.files = TRUE)
  expect_length(failures, 1L)
  expect_identical(readRDS(file.path(failures, "archive/manifest.rds"))$status, "failed")
})

test_that("a missing Quarto output cannot be accepted as a successful report", {
  fixture <- render_fixture()
  local_render_boundaries(quarto_render = function(...) invisible(NULL))
  expect_error(suppressMessages(suppressWarnings(render_fixture_report(fixture))),
                 "keine DOCX-Datei")
  expect_false(dir.exists(fixture$output))
})

test_that("failed installation of the new directory restores the previous output", {
  fixture <- render_fixture()
  local_render_boundaries()
  previous <- suppressWarnings(render_fixture_report(fixture))
  old_hashes <- tools::md5sum(c(previous$path, file.path(previous$archive_dir, "manifest.rds")))
  real_rename <- base::file.rename
  moves <- 0L
  local_mocked_bindings(file.rename = function(from, to) {
    moves <<- moves + 1L
    # The old output is backed up first; fail the subsequent installation.
    if (moves == 2L) return(FALSE)
    real_rename(from, to)
  }, .package = "base")
  expect_error(suppressMessages(suppressWarnings(render_fixture_report(fixture, overwrite = TRUE))),
                 "neue Ausgabe konnte nicht")
  expect_identical(tools::md5sum(names(old_hashes)), old_hashes)
})

test_that("Word finalisation runs before the archived report hash is calculated", {
  fixture <- render_fixture()
  local_render_boundaries(word_available = TRUE)
  before_word <- NULL
  local_mocked_bindings(run = function(command, args, ...) {
    path <- args[match("-DocumentPath", args) + 1L]
    before_word <<- unname(tools::md5sum(path))
    expect_true(file.exists(args[match("-File", args) + 1L]))
    expect_true(file.exists(file.path(dirname(path), ".eatTechReport-render")))
    parts <- tempfile("word-updated-")
    extract_word_package(path, parts)
    document_path <- file.path(parts, "word/document.xml")
    doc <- xml2::read_xml(document_path)
    body <- xml2::xml_find_first(doc, "w:body", word_ns())
    paragraph <- xml2::read_xml(paste0('<w:p xmlns:w="', word_ns()[["w"]],
                                      '"><w:r><w:t>Updated field result</w:t></w:r></w:p>'))
    xml2::xml_add_child(body, paragraph, .where = 0)
    xml2::write_xml(doc, document_path)
    pack_word_package(parts, path)
    list(stdout = '{"fields_updated":true}', stderr = "", status = 0L)
  }, .package = "processx")

  result <- render_fixture_report(fixture, update_fields = "word")
  expect_true(result$manifest$fields_updated)
  expect_identical(result$manifest$status, "development_snapshot")
  expect_false(identical(before_word, result$manifest$report_md5))
  expect_identical(result$manifest$report_md5, unname(tools::md5sum(result$path)))
  expect_match(readLines(file.path(result$archive_dir, "word-fields.log"))[[1L]], "fields_updated")
})

test_that("Word failures preserve the previous successful rendering", {
  fixture <- render_fixture()
  local_render_boundaries()
  previous <- suppressWarnings(render_fixture_report(fixture))
  old_hashes <- tools::md5sum(c(previous$path, file.path(previous$archive_dir, "manifest.rds")))
  local_mocked_bindings(windows_word_available = function() TRUE, .package = "eatTechReport")
  local_mocked_bindings(run = function(...) stop("Word automation failed"), .package = "processx")
  expect_error(suppressMessages(render_fixture_report(fixture, overwrite = TRUE, update_fields = "word")),
                 "Word-Felder konnten nicht automatisch aktualisiert werden")
  expect_identical(tools::md5sum(names(old_hashes)), old_hashes)
})

test_that("input sources inside an output directory cannot be moved into backups", {
  fixture <- render_fixture()
  local_render_boundaries()
  dir.create(fixture$output)
  writeLines("eatTechReport", file.path(fixture$output, ".eatTechReport-render"))
  inside <- file.path(fixture$output, "template.dotx")
  file.copy(fixture$template, inside)
  fixture$template <- inside
  original <- tools::md5sum(inside)
  expect_error(suppressWarnings(render_fixture_report(fixture, overwrite = TRUE)), "ausserhalb")
  expect_identical(tools::md5sum(inside), original)
})

test_that("missing Quarto and invalid file arguments fail before output creation", {
  fixture <- render_fixture()
  local_render_boundaries()
  local_mocked_bindings(quarto_path = function() NULL, .package = "quarto")
  expect_error(render_fixture_report(fixture), "Quarto CLI")
  expect_false(dir.exists(fixture$output))
  expect_error(render_fixture_report(fixture, overwrite = NA), "TRUE oder FALSE")
  expect_error(edit_report_texts(NA_character_), "Dateipfad")
  renamed <- sub("dotx$", "docx", fixture$template)
  file.copy(fixture$template, renamed)
  fixture$template <- renamed
  expect_error(render_fixture_report(fixture), "DOTX-Vorlage")
})
