#' Copy editable Quarto text blocks
#'
#' Copies the text blocks for the selected report scope into a working
#' directory. Edit these copies and pass the directory to [render_report()].
#' The package installation itself is never edited.
#'
#' @param path Local directory for the editable text blocks.
#' @param overwrite Whether existing blocks may be replaced. Defaults to FALSE.
#' @param scope Report scope: `"pilotierung"` for design, sample and performance,
#'   `"pilotierung_leistung"` for the performance section only, or
#'   `"haupttest_struktur"` to also include main-test selection and modules.
#' @return Invisibly, the paths of the copied Quarto files.
#' @export
#' @examples
#' texts <- tempfile("report-texts-")
#' edit_report_texts(texts)
edit_report_texts <- function(path, overwrite = FALSE,
                              scope = c("pilotierung", "pilotierung_leistung", "haupttest_struktur")) {
  scope <- match.arg(scope)
  check_report_path(path, "path")
  check_report_flag(overwrite, "overwrite")
  sources <- report_text_files(scope = scope)
  targets <- file.path(path, basename(sources))
  if (!overwrite && any(file.exists(targets))) {
    stop("Textbausteine existieren bereits; zum Ersetzen overwrite = TRUE angeben.", call. = FALSE)
  }
  if (!dir.exists(path) && !dir.create(path, recursive = TRUE)) {
    stop("Der Textordner konnte nicht angelegt werden.", call. = FALSE)
  }
  if (!all(file.copy(sources, targets, overwrite = overwrite))) {
    stop("Nicht alle Textbausteine konnten kopiert werden.", call. = FALSE)
  }
  invisible(normalizePath(targets, winslash = "/"))
}

#' Render pilot-study sections with the corporate Word layout
#'
#' The renderer covers test design, sample composition and performance for the
#' pilot-study scope, or the performance section alone. Scope `haupttest_struktur`
#' also adds main-test selection and modules. It is not yet a complete
#' technical report. Inputs follow [example_report()] and are validated before
#' rendering. Synthetic data and illustrative cuts are explicitly labelled.
#'
#' The package includes the corporate DOCX layout. Alternatively, supply a
#' corporate DOTX or DOCX file. Its styles, page geometry, headers and footers
#' are used to prepare a local DOCX reference with the report typography.
#' Template body text is not imported. Missing Pandoc styles are derived from
#' corporate styles. Quarto must be installed separately.
#'
#' All generated files, including the derived reference and a baseline snapshot
#' of inputs, results, texts and software information, are written inside
#' `output_dir`. Use a private directory excluded from version control, for
#' example `lokal/demo-de`. This snapshot is not a signed-off release archive;
#' change comparison and margin markers are not implemented yet.
#'
#' @param config Report configuration from [example_report()]. The cover uses
#'   `config$report$authors` (names in display order) and
#'   `config$report$affiliation` (shared affiliation, optionally multiple lines).
#'   Earlier inputs without these fields receive visible placeholders.
#' @param data Input tables including population, PV values and, for the
#'   pilot-study scope, design and sample information.
#' @param corporate_template Optional path to a corporate DOTX or DOCX template.
#'   NULL uses the layout included with the package.
#' @param text_dir Optional directory containing all editable Quarto blocks
#'   created by [edit_report_texts()]. For the pilot-study scope, optional local
#'   blocks `grundlagen_kompetenzstufen.qmd`, `pilotierung_durchfuehrung.qmd`
#'   and `pilotierung_auswertung.qmd` are also rendered and archived when present.
#'   NULL uses the package blocks.
#' @param output_dir Private local directory for the report and its snapshot.
#' @param overwrite Allow replacement of an earlier eatTechReport rendering in
#'   this directory. The earlier directory is retained as a sibling backup after
#'   successful rendering. Failed attempts leave the previous output intact.
#'   Nonempty unrelated directories are always rejected.
#' @param update_fields How to finalise Word fields and the table of contents.
#'   `"auto"` uses a locally installed Microsoft Word on Windows when available.
#'   `"word"` requires it. `"none"` skips this step. Unupdated documents have
#'   manifest status `fields_pending` and produce a warning. Word automation
#'   operates only on the newly generated staging document.
#' @return A list of class `eat_report` with `path`, `archive_dir`, `manifest`,
#'   `summaries`, `config` and `previous_output_dir`. Paths are absolute.
#' @export
#' @examples
#' \dontrun{
#' demo <- example_report()
#' result <- render_report(demo$config, demo$data,
#'                         output_dir = "lokal/demo-de")
#' result$path
#' }
render_report <- function(config, data,
                          corporate_template = NULL,
                          text_dir = NULL, output_dir, overwrite = FALSE,
                          update_fields = c("auto", "word", "none")) {
  update_fields <- match.arg(update_fields)
  input <- list(config = config, data = data)
  validate_report_input(input)
  if (is.null(corporate_template)) {
    corporate_template <- system.file("templates", "eatTechReport.docx", package = "eatTechReport")
    if (!nzchar(corporate_template)) {
      stop("Die Corporate-Vorlage fehlt in der Paketinstallation.", call. = FALSE)
    }
  }
  check_report_path(corporate_template, "corporate_template")
  check_report_path(output_dir, "output_dir")
  check_report_flag(overwrite, "overwrite")
  if (!file.exists(corporate_template) || dir.exists(corporate_template)) {
    stop("Die verbindliche Corporate-Vorlage fehlt: ", corporate_template,
         ".", call. = FALSE)
  }
  if (!tolower(tools::file_ext(corporate_template)) %in% c("dotx", "docx")) {
    stop("corporate_template muss auf eine DOTX- oder DOCX-Vorlage verweisen.", call. = FALSE)
  }
  sources <- report_text_files(text_dir, scope = config$scope)
  if (!requireNamespace("knitr", quietly = TRUE) || !requireNamespace("rmarkdown", quietly = TRUE)) {
    stop("Die R-Ausfuehrung in Quarto benoetigt knitr und rmarkdown.", call. = FALSE)
  }
  quarto_path <- quarto::quarto_path()
  if (is.null(quarto_path) || !nzchar(quarto_path)) {
    stop("Quarto CLI ist nicht installiert oder nicht auffindbar.", call. = FALSE)
  }
  existing <- if (dir.exists(output_dir)) list.files(output_dir, all.files = TRUE, no.. = TRUE) else character()
  if (length(existing) && (!overwrite || !file.exists(file.path(output_dir, ".eatTechReport-render")))) {
    stop("output_dir ist nicht leer. Nur eigene fruehere Renderlaeufe koennen mit overwrite = TRUE ersetzt werden.",
         call. = FALSE)
  }
  fields_requested <- resolve_field_update(update_fields)
  parent <- dirname(output_dir)
  if (!dir.exists(parent) && !dir.create(parent, recursive = TRUE)) {
    stop("Der uebergeordnete Ausgabeordner konnte nicht angelegt werden.", call. = FALSE)
  }
  parent <- normalizePath(parent, winslash = "/")
  destination <- if (dir.exists(output_dir)) normalizePath(output_dir, winslash = "/") else
    file.path(parent, basename(output_dir))
  template_path <- normalizePath(corporate_template, winslash = "/")
  sources <- normalizePath(sources, winslash = "/")
  source_paths <- tolower(c(template_path, sources))
  if (any(startsWith(source_paths, paste0(tolower(destination), "/")))) {
    stop("Vorlage und redigierte Texte muessen ausserhalb von output_dir liegen.", call. = FALSE)
  }
  output_dir <- tempfile(".eatTechReport-render-", tmpdir = parent)
  dir.create(output_dir)
  output_dir <- normalizePath(output_dir, winslash = "/")
  # Both directory moves at the end are confined to this checked parent.
  if (!identical(dirname(output_dir), parent) || !identical(dirname(destination), parent)) {
    stop("Die Ausgabeordner liegen ausserhalb des angegebenen Zielverzeichnisses.", call. = FALSE)
  }
  writeLines("eatTechReport rendering", file.path(output_dir, ".eatTechReport-render"))
  archive_dir <- file.path(output_dir, "archive")
  text_path <- file.path(archive_dir, "texts")
  asset_path <- file.path(output_dir, "figures")
  for (path in c(archive_dir, text_path, asset_path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  complete <- FALSE
  write_report_manifest(list(status = "rendering"), archive_dir)
  on.exit({
    if (!complete && dir.exists(archive_dir)) {
      write_report_manifest(list(status = "failed", scope = config$scope), archive_dir)
      message("Renderlauf fehlgeschlagen; bisherige Ausgabe bleibt erhalten. Arbeitsdateien: ", output_dir)
    }
  }, add = TRUE)
  reference <- file.path(output_dir, "corporate-reference.docx")
  prepare_corporate_reference(template_path, reference)
  copied_texts <- file.path(text_path, basename(sources))
  if (!all(file.copy(sources, copied_texts, overwrite = TRUE))) {
    stop("Die Textbausteine konnten nicht in den Renderlauf kopiert werden.", call. = FALSE)
  }
  summaries <- summarise_report_input(input)
  saveRDS(input, file.path(archive_dir, "inputs.rds"), version = 3)
  saveRDS(summaries, file.path(archive_dir, "summaries.rds"), version = 3)
  display_labels <- list(
    scales = vapply(config$scales, function(scale) report_markdown_text(scale$label), character(1)),
    levels = lapply(config$scales, function(scale) report_markdown_text(scale$level_labels))
  )
  saveRDS(display_labels, file.path(archive_dir, "display-labels.rds"), version = 3)
  for (scale_id in names(config$scales)) {
    ggplot2::ggsave(file.path(asset_path, paste0(scale_id, ".png")),
                    plot = plot_performance(input, scale_id, font_family = "Arial"),
                    width = 15.5, height = 9.4, units = "cm", dpi = 200, bg = "white")
  }
  item_figures <- main_test_figure_plan(config, summaries$main_test)
  for (kind in names(item_figures)) {
    for (figure in item_figures[[kind]]) {
      ggplot2::ggsave(file.path(asset_path, figure$file),
        plot = plot_item_levels(input, figure$scale_id,
          by = if (kind == "selection") "selection" else "module",
          module_ids = figure$module_ids, font_family = "Arial"),
        width = figure$width, height = figure$height, units = "cm", dpi = 200, bg = "white")
    }
  }
  saveRDS(item_figures, file.path(archive_dir, "item-figures.rds"), version = 3)
  main_source <- system.file("quarto", "report.qmd", package = "eatTechReport")
  if (!nzchar(main_source)) stop("Die Quarto-Hauptdatei fehlt in der Paketinstallation.", call. = FALSE)
  source <- file.path(output_dir, "report.qmd")
  if (!file.copy(main_source, source, overwrite = TRUE)) {
    stop("Die Quarto-Hauptdatei konnte nicht kopiert werden.", call. = FALSE)
  }
  subject <- if (config$report$subject == "de") "Deutsch" else "Mathematik"
  title <- paste(c(paste("Vergleichsarbeiten", config$report$main_year),
                   "3. Jahrgangsstufe", subject), collapse = "  \n")
  subtitle <- "Technischer Bericht"
  quarto::quarto_render(
    input = source, output_format = "docx", output_file = "report.docx",
    metadata = list(title = title, subtitle = subtitle),
    quiet = TRUE, as_job = FALSE
  )
  report_path <- file.path(output_dir, "report.docx")
  if (!file.exists(report_path)) stop("Quarto hat keine DOCX-Datei erzeugt.", call. = FALSE)
  finalise_report_docx(report_path, report = config$report)
  fields_updated <- FALSE
  if (fields_requested) {
    update_docx_fields(report_path, file.path(archive_dir, "word-fields.log"))
    fields_updated <- TRUE
  }
  session <- utils::sessionInfo()
  writeLines(utils::capture.output(session), file.path(archive_dir, "sessionInfo.txt"), useBytes = TRUE)
  hashes <- tools::md5sum(copied_texts)
  names(hashes) <- basename(copied_texts)
  manifest <- list(
    archive_schema = "0.1.0", status = if (fields_updated) "development_snapshot" else "fields_pending",
    created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    scope = config$scope, data_origin = config$report$data_origin,
    schema_version = config$schema_version,
    package_version = as.character(utils::packageVersion("eatTechReport")),
    quarto_version = as.character(quarto::quarto_version()),
    template_file = basename(template_path), template_md5 = unname(tools::md5sum(template_path)),
    text_md5 = hashes, report_md5 = unname(tools::md5sum(report_path)),
    main_source_file = "../report.qmd", main_source_md5 = unname(tools::md5sum(source)),
    reference_file = "../corporate-reference.docx", figures_dir = "../figures",
    inputs_file = "inputs.rds", summaries_file = "summaries.rds",
    change_markers = FALSE, fields_updated = fields_updated
  )
  write_report_manifest(manifest, archive_dir)
  previous <- NULL
  if (dir.exists(destination)) {
    previous <- tempfile(paste0(basename(destination), "-previous-"), tmpdir = parent)
    if (!identical(dirname(previous), parent) || !file.rename(destination, previous)) {
      stop("Die bisherige Ausgabe konnte nicht gesichert werden; der neue Lauf bleibt im Arbeitsordner.", call. = FALSE)
    }
  }
  if (!file.rename(output_dir, destination)) {
    if (!is.null(previous) && !file.rename(previous, destination)) {
      stop("Ausgabeverschiebung fehlgeschlagen. Die bisherige Ausgabe liegt unter: ", previous, call. = FALSE)
    }
    stop("Die neue Ausgabe konnte nicht an den Zielort verschoben werden.", call. = FALSE)
  }
  complete <- TRUE
  structure(list(path = file.path(destination, "report.docx"),
                 archive_dir = file.path(destination, "archive"), manifest = manifest,
                 summaries = summaries, config = config, previous_output_dir = previous), class = "eat_report")
}

windows_word_available <- function() {
  if (.Platform$OS.type != "windows" || !nzchar(Sys.which("powershell"))) return(FALSE)
  registry <- tryCatch(utils::readRegistry("Word.Application\\CLSID", hive = "HCR", maxdepth = 1L),
                       error = function(e) NULL)
  length(registry) > 0L
}

resolve_field_update <- function(mode, available = windows_word_available()) {
  if (mode == "none") {
    warning("Word-Felder werden nicht aktualisiert; der Archivstatus lautet fields_pending.", call. = FALSE)
    return(FALSE)
  }
  if (available) return(TRUE)
  if (mode == "word") {
    stop("update_fields = 'word' benoetigt Microsoft Word und PowerShell unter Windows.", call. = FALSE)
  }
  warning("Microsoft Word unter Windows ist nicht verfuegbar: Inhaltsverzeichnis und Felder bleiben unaktualisiert (fields_pending).",
          call. = FALSE)
  FALSE
}

update_docx_fields <- function(path, log_path) {
  script <- system.file("scripts", "update-word-fields.ps1", package = "eatTechReport")
  if (!nzchar(script)) stop("Das Skript zur Word-Feldaktualisierung fehlt.", call. = FALSE)
  result <- tryCatch(processx::run(
    command = unname(Sys.which("powershell")),
    args = c("-NoLogo", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
             "-File", script, "-DocumentPath", path),
    timeout = 120000, windows_hide_window = TRUE, error_on_status = TRUE
  ), error = function(e) {
    stop("Word-Felder konnten nicht automatisch aktualisiert werden: ", conditionMessage(e), call. = FALSE)
  })
  writeLines(c(result$stdout, result$stderr), log_path, useBytes = TRUE)
  invisible(TRUE)
}

write_report_manifest <- function(manifest, archive_dir) {
  saveRDS(manifest, file.path(archive_dir, "manifest.rds"), version = 3)
  writeLines(utils::capture.output(dput(manifest)), file.path(archive_dir, "manifest.txt"), useBytes = TRUE)
}

report_markdown_text <- function(value) {
  special <- c("\\", "`", "*", "_", "{", "}", "[", "]", "(", ")", "#", "+", "-", ".", "!", "|", "<", ">")
  vapply(strsplit(enc2utf8(value), "", fixed = TRUE), function(chars) {
    escaped <- ifelse(chars %in% special, paste0("\\", chars), chars)
    escaped[chars == "|"] <- "&#124;"
    paste0(escaped, collapse = "")
  }, character(1), USE.NAMES = FALSE)
}

check_report_path <- function(path, label) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(trimws(path))) {
    stop(label, " muss genau einen nichtleeren Dateipfad enthalten.", call. = FALSE)
  }
}

check_report_flag <- function(value, label) {
  if (!is.logical(value) || length(value) != 1L || is.na(value)) {
    stop(label, " muss TRUE oder FALSE sein.", call. = FALSE)
  }
}

report_text_files <- function(text_dir = NULL,
                              scope = c("pilotierung", "pilotierung_leistung", "haupttest_struktur")) {
  scope <- match.arg(scope)
  expected <- c("grundlagen_ueberblick.qmd", "pilotierung_leistung.qmd", "leistung_methoden.qmd")
  if (scope %in% c("pilotierung", "haupttest_struktur")) expected <- c(expected, study_text_names())
  if (scope == "haupttest_struktur") {
    expected <- c(expected, "haupttest_auswahl.qmd", "haupttest_module.qmd")
  }
  if (is.null(text_dir)) text_dir <- system.file("quarto", "texts", package = "eatTechReport")
  check_report_path(text_dir, "text_dir")
  paths <- file.path(text_dir, expected)
  if (!all(file.exists(paths)) || any(dir.exists(paths))) {
    stop("text_dir muss alle Textbausteine enthalten: ", paste(expected, collapse = ", "), call. = FALSE)
  }
  if (scope %in% c("pilotierung", "haupttest_struktur")) {
    optional <- file.path(text_dir, c("grundlagen_kompetenzstufen.qmd",
                                      "pilotierung_durchfuehrung.qmd",
                                      "pilotierung_auswertung.qmd"))
    if (any(dir.exists(optional))) {
      stop("Optionale Textbausteine muessen Dateien sein, keine Verzeichnisse.", call. = FALSE)
    }
    paths <- c(paths, optional[file.exists(optional)])
  }
  paths
}

study_text_names <- function() {
  paste0(c("pilotierung_design_pool", "pilotierung_design_hefte",
           "pilotierung_stichprobe_ruecklauf", "pilotierung_stichprobe_merkmale",
           "pilotierung_stichprobe_bearbeitungen"), ".qmd")
}

word_ns <- function() c(w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
                       r = "http://schemas.openxmlformats.org/officeDocument/2006/relationships")

extract_word_package <- function(path, directory) {
  entries <- utils::unzip(path, list = TRUE)$Name
  if (!length(entries) || any(grepl("(^/|^[A-Za-z]:|\\\\|(^|/)\\.\\.(/|$))", entries))) {
    stop("Die Word-Datei enthaelt ungueltige Archivpfade.", call. = FALSE)
  }
  required <- c("[Content_Types].xml", "word/document.xml", "word/styles.xml")
  if (!all(required %in% entries)) stop("Die Datei ist kein vollstaendiges Word-Archiv.", call. = FALSE)
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  utils::unzip(path, exdir = directory)
  invisible(entries)
}

pack_word_package <- function(directory, path) {
  path <- file.path(normalizePath(dirname(path), winslash = "/", mustWork = TRUE), basename(path))
  files <- list.files(directory, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  zip::zipr(zipfile = path, files = files, root = directory,
            include_directories = FALSE, mode = "mirror")
}

# Work on a copy: externally supplied templates may contain private material.
prepare_corporate_reference <- function(template, reference) {
  directory <- tempfile(".corporate-parts-", tmpdir = dirname(reference))
  on.exit(remove_word_parts(directory, dirname(reference)), add = TRUE)
  extract_word_package(template, directory)
  content_file <- file.path(directory, "[Content_Types].xml")
  content <- xml2::read_xml(content_file)
  main <- xml2::xml_find_first(content, "//*[local-name()='Override'][@PartName='/word/document.xml']")
  supported <- paste0("application/vnd.openxmlformats-officedocument.wordprocessingml.",
                      c("template", "document"), ".main+xml")
  if (!xml2::xml_attr(main, "ContentType") %in% supported) {
    stop("Die Corporate-Datei ist keine Word-DOTX- oder DOCX-Vorlage.", call. = FALSE)
  }
  xml2::xml_set_attr(main, "ContentType",
                     "application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml")
  xml2::write_xml(content, content_file)
  ns <- word_ns()
  document_file <- file.path(directory, "word/document.xml")
  doc <- xml2::read_xml(document_file)
  sections <- xml2::xml_find_all(doc, "//w:sectPr", ns)
  if (!length(sections)) stop("Die Corporate-Vorlage enthaelt keine Seiteneinstellungen.", call. = FALSE)
  # Resolve section inheritance before Pandoc ignores the template body.
  refs <- list()
  for (section in sections) {
    for (node in xml2::xml_find_all(section, "w:headerReference|w:footerReference", ns)) {
      key <- paste(xml2::xml_name(node), xml2::xml_attr(node, "w:type", ns = ns), sep = "_")
      refs[[key]] <- node
    }
  }
  final <- xml2::xml_find_first(doc, "(//w:sectPr)[last()]", ns)
  xml2::xml_remove(xml2::xml_find_all(final, "w:headerReference|w:footerReference", ns))
  for (node in refs) xml2::xml_add_child(final, node)
  # The first page uses the corporate cover header. Subsequent pages use the
  # effective body headers/footers; no body text is copied from the template.
  for (kind in c("headerReference", "footerReference")) {
    first <- xml2::xml_find_first(sections[[1L]], paste0("w:", kind, "[@w:type='first']"), ns)
    if (!inherits(first, "xml_missing")) {
      xml2::xml_remove(xml2::xml_find_all(final, paste0("w:", kind, "[@w:type='first']"), ns))
      xml2::xml_add_child(final, first)
    }
  }
  if (inherits(xml2::xml_find_first(final, "w:titlePg", ns), "xml_missing")) {
    xml2::xml_add_child(final, "w:titlePg")
  }
  section_order <- c("headerReference", "footerReference", "footnotePr", "endnotePr", "type",
                     "pgSz", "pgMar", "paperSrc", "pgBorders", "lnNumType", "pgNumType", "cols",
                     "formProt", "vAlign", "noEndnote", "titlePg", "textDirection", "bidi",
                     "rtlGutter", "docGrid", "printerSettings", "sectPrChange")
  section_children <- xml2::xml_children(final)
  positions <- match(xml2::xml_name(section_children), section_order)
  positions[is.na(positions)] <- length(section_order) + 1L
  for (node in section_children[order(positions)]) xml2::xml_add_child(final, node)
  xml2::xml_remove(section_children)
  xml2::write_xml(doc, document_file)
  styles_file <- file.path(directory, "word/styles.xml")
  styles <- xml2::read_xml(styles_file)
  find_style <- function(name) {
    style_nodes <- xml2::xml_find_all(styles, "w:style", ns)
    style_names <- tolower(xml2::xml_attr(xml2::xml_find_first(style_nodes, "w:name", ns), "w:val", ns = ns))
    pos <- match(tolower(name), style_names)
    if (is.na(pos)) return(NULL)
    style_nodes[[pos]]
  }
  cover_paragraphs <- xml2::xml_find_all(doc, "w:body/w:p[w:pPr/w:pStyle]", ns)
  cover_style <- function(index, fallback) {
    if (length(cover_paragraphs) >= index) {
      id <- xml2::xml_attr(xml2::xml_find_first(cover_paragraphs[[index]], "w:pPr/w:pStyle", ns), "w:val", ns)
      found <- xml2::xml_find_all(styles, "w:style", ns)
      ids <- xml2::xml_attr(found, "w:styleId", ns)
      if (id %in% ids) return(found[[match(id, ids)]])
    }
    find_style(fallback)
  }
  if (is.null(find_style("Normal")) || is.null(find_style("Body Text"))) {
    stop("Corporate-Vorlage braucht die Formatvorlagen Normal und Body Text.", call. = FALSE)
  }
  mappings <- c("First Paragraph" = "Body Text", "Compact" = "Body Text",
                "Subtitle" = "Subtitel_Zwischenseite", "TOC Heading" = "Titel_Inhaltsverzeichnis",
                "Table Caption" = "caption", "Image Caption" = "caption",
                "Figure" = "Body Text", "Captioned Figure" = "Body Text")
  for (target in names(mappings)) {
    if (!is.null(find_style(target))) next
    source <- find_style(mappings[[target]])
    if (is.null(source)) source <- find_style("Body Text")
    new_style <- xml2::xml_add_child(styles, source)
    xml2::xml_set_attr(new_style, "w:styleId", gsub("[^A-Za-z0-9]", "", target))
    xml2::xml_set_attr(xml2::xml_find_first(new_style, "w:name", ns), "w:val", target)
    xml2::xml_remove(xml2::xml_find_all(new_style, "w:link|w:aliases", ns))
  }
  # Use the styles actually applied on the template's first page. The template
  # also contains white lettering for other backgrounds, which is unsuitable
  # for this cover. Direct formatting on the template paragraphs overrides style
  # properties, but their placeholder text is never copied.
  for (i in seq_along(c("Title", "Subtitle"))) {
    target <- find_style(c("Title", "Subtitle")[[i]])
    cover <- cover_style(i, c("Title", "Subtitle")[[i]])
    if (is.null(cover) || is.null(target)) next
    if (!identical(xml2::xml_path(cover), xml2::xml_path(target))) {
      xml2::xml_remove(xml2::xml_find_all(target, "w:pPr|w:rPr", ns))
      for (node in xml2::xml_find_all(cover, "w:pPr|w:rPr", ns)) xml2::xml_add_child(target, node)
    }
    if (length(cover_paragraphs) >= i) {
      paragraph <- cover_paragraphs[[i]]
      direct <- list(
        pPr = xml2::xml_find_all(paragraph, "w:pPr/*[not(self::w:pStyle or self::w:sectPr or self::w:rPr)]", ns),
        rPr = xml2::xml_find_all(paragraph, "(.//w:r[w:t])[1]/w:rPr/*", ns)
      )
      for (group in names(direct)) {
        if (!length(direct[[group]])) next
        props <- xml2::xml_find_first(target, paste0("w:", group), ns)
        if (inherits(props, "xml_missing")) props <- xml2::xml_add_child(target, paste0("w:", group))
        for (node in direct[[group]]) {
          xml2::xml_remove(xml2::xml_find_all(props, paste0("w:", xml2::xml_name(node)), ns))
          xml2::xml_add_child(props, node)
        }
      }
    }
  }
  xml2::write_xml(styles, styles_file)
  # Pandoc can select the first section. Give it exactly one resolved section,
  # after inspecting the original cover formatting. No template prose remains.
  body <- xml2::xml_find_first(doc, "w:body", ns)
  xml2::xml_add_child(body, final)
  children <- xml2::xml_children(body)
  xml2::xml_remove(children[-length(children)])
  xml2::xml_add_child(body, "w:p", .where = 0)
  xml2::write_xml(doc, document_file)
  apply_report_layout(directory)
  pack_word_package(directory, reference)
  invisible(reference)
}

finalise_report_docx <- function(path, report = NULL) {
  directory <- tempfile(".report-parts-", tmpdir = dirname(path))
  on.exit(remove_word_parts(directory, dirname(path)), add = TRUE)
  extract_word_package(path, directory)
  ns <- word_ns()
  document_file <- file.path(directory, "word/document.xml")
  doc <- xml2::read_xml(document_file)
  styles_file <- file.path(directory, "word/styles.xml")
  styles <- if (file.exists(styles_file)) xml2::read_xml(styles_file) else NULL
  if (!is.null(report)) {
    add_report_cover_authors(doc, styles, report, ns)
    xml2::write_xml(styles, styles_file)
  }
  contents <- xml2::xml_find_first(doc, "//w:sdt[.//w:instrText[contains(., 'TOC')]]", ns)
  if (!inherits(contents, "xml_missing")) {
    page_break <- xml2::read_xml(paste0('<w:p xmlns:w="', ns[["w"]],
                                      '"><w:r><w:br w:type="page"/></w:r></w:p>'))
    xml2::xml_add_sibling(contents, page_break, .where = "before")
  }
  # Tables: strong outer rules, light horizontal separators, no verticals.
  for (table in xml2::xml_find_all(doc, "//w:tbl", ns)) {
    space_report_table(table, styles, ns)
    # Captioned figures are layout containers, not data tables. Their image
    # dimensions and caption placement are finalised after general typography.
    if (is_report_figure_table(table, styles, ns)) next
    # Quarto wraps a caption and its data table in an outer layout table. Only
    # the inner data table receives rules, repeated headings and header shading.
    if (length(xml2::xml_find_all(table, ".//w:tbl", ns))) {
      clear_report_layout_table(table, ns)
      next
    }
    rows <- xml2::xml_find_all(table, "w:tr", ns)
    if (length(rows) <= 8L) {
      for (i in seq_along(rows)) {
        row_props <- xml2::xml_find_first(rows[[i]], "w:trPr", ns)
        if (inherits(row_props, "xml_missing")) row_props <- xml2::xml_add_child(rows[[i]], "w:trPr", .where = 0)
        if (inherits(xml2::xml_find_first(row_props, "w:cantSplit", ns), "xml_missing")) {
          xml2::xml_add_child(row_props, "w:cantSplit")
        }
        for (paragraph in xml2::xml_find_all(rows[[i]], ".//w:p", ns)) {
          pprops <- xml2::xml_find_first(paragraph, "w:pPr", ns)
          if (inherits(pprops, "xml_missing")) pprops <- xml2::xml_add_child(paragraph, "w:pPr", .where = 0)
          xml2::xml_remove(xml2::xml_find_all(pprops, "w:keepNext", ns))
          keep <- xml2::xml_add_child(pprops, "w:keepNext")
          xml2::xml_set_attr(keep, "w:val", if (i < length(rows)) "1" else "0")
        }
      }
    }
    props <- xml2::xml_find_first(table, "w:tblPr", ns)
    if (inherits(props, "xml_missing")) props <- xml2::xml_add_child(table, "w:tblPr", .where = 0)
    xml2::xml_remove(xml2::xml_find_all(props, "w:tblBorders", ns))
    borders <- xml2::xml_add_child(props, "w:tblBorders")
    for (side in c("top", "left", "bottom", "right", "insideH", "insideV")) {
      border <- xml2::xml_add_child(borders, paste0("w:", side))
      xml2::xml_set_attr(border, "w:val", if (side %in% c("top", "bottom", "insideH")) "single" else "nil")
      xml2::xml_set_attr(border, "w:sz", if (side == "insideH") "4" else "12")
      xml2::xml_set_attr(border, "w:color", if (side == "insideH") "B3B3B3" else "000000")
    }
    # Cell borders take precedence over table borders in Word. Set the outer
    # rules on the actual cells too, so inherited thin rules cannot win.
    for (i in seq_along(rows)) {
      for (cell in xml2::xml_find_all(rows[[i]], "w:tc", ns)) {
        cell_props <- xml2::xml_find_first(cell, "w:tcPr", ns)
        if (inherits(cell_props, "xml_missing")) cell_props <- xml2::xml_add_child(cell, "w:tcPr", .where = 0)
        xml2::xml_set_attr(layout_child(cell_props, "vAlign", ns), "w:val", "center")
        margins <- layout_child(cell_props, "tcMar", ns)
        # Word puts most of the extra 1.5-line leading below Arial's visible
        # glyphs. Compensate above the text instead of adding equal margins:
        # 6.5 pt above / 0 pt below optically centers one- and multiline cells
        # while preserving the report's 11 pt font and 1.5-line spacing.
        for (side in c("top", "bottom")) {
          margin <- layout_child(margins, side, ns)
          xml2::xml_set_attrs(margin, c("w:w" = if (side == "top") "130" else "0",
                                       "w:type" = "dxa"))
        }
        layout_order_children(margins, c("top", "start", "left", "bottom", "end", "right"))
        # Inherited paragraph-after spacing would add a second gap below.
        # Keep the report line spacing but remove these extra gaps.
        for (paragraph in xml2::xml_find_all(cell, ".//w:p", ns)) {
          paragraph_props <- layout_child(paragraph, "pPr", ns, first = TRUE)
          spacing <- layout_child(paragraph_props, "spacing", ns)
          xml2::xml_set_attrs(spacing, c("w:before" = "0", "w:after" = "0",
                                        "w:beforeAutospacing" = "0", "w:afterAutospacing" = "0"))
          xml2::xml_set_attr(spacing, "w:beforeLines", NULL, ns)
          xml2::xml_set_attr(spacing, "w:afterLines", NULL, ns)
        }
        xml2::xml_remove(xml2::xml_find_all(cell_props, "w:tcBorders", ns))
        cell_borders <- xml2::xml_add_child(cell_props, "w:tcBorders")
        for (side in c("top", "left", "bottom", "right")) {
          outer <- (side == "top" && i == 1L) || (side == "bottom" && i == length(rows))
          horizontal <- side %in% c("top", "bottom")
          under_header <- (side == "bottom" && i == 1L) || (side == "top" && i == 2L)
          border <- xml2::xml_add_child(cell_borders, paste0("w:", side))
          xml2::xml_set_attrs(border, c("w:val" = if (horizontal) "single" else "nil",
                                      "w:sz" = if (outer) "12" else "4",
                                      "w:color" = if (outer || under_header) "000000" else "B3B3B3"))
        }
      }
    }
    first_row <- xml2::xml_find_first(table, "w:tr", ns)
    row_props <- xml2::xml_find_first(first_row, "w:trPr", ns)
    if (inherits(row_props, "xml_missing")) row_props <- xml2::xml_add_child(first_row, "w:trPr", .where = 0)
    if (inherits(xml2::xml_find_first(row_props, "w:tblHeader", ns), "xml_missing")) {
      xml2::xml_add_child(row_props, "w:tblHeader")
    }
    for (cell in xml2::xml_find_all(first_row, "w:tc", ns)) {
      cell_props <- xml2::xml_find_first(cell, "w:tcPr", ns)
      if (inherits(cell_props, "xml_missing")) cell_props <- xml2::xml_add_child(cell, "w:tcPr", .where = 0)
      xml2::xml_remove(xml2::xml_find_all(cell_props, "w:shd", ns))
      shade <- xml2::xml_add_child(cell_props, "w:shd")
      xml2::xml_set_attr(shade, "w:fill", "F2F2F2")
    }
  }
  for (props in xml2::xml_find_all(doc, "//w:tcPr", ns)) {
    layout_order_children(props, c("cnfStyle", "tcW", "gridSpan", "hMerge", "vMerge",
                                   "tcBorders", "shd", "noWrap", "tcMar", "textDirection",
                                   "tcFitText", "vAlign", "hideMark", "headers", "cellIns",
                                   "cellDel", "cellMerge", "tcPrChange"))
  }
  xml2::write_xml(doc, document_file)
  settings_file <- file.path(directory, "word/settings.xml")
  if (file.exists(settings_file)) {
    settings <- xml2::read_xml(settings_file)
    xml2::xml_remove(xml2::xml_find_all(settings, "w:updateFields", ns))
    update <- xml2::xml_add_child(settings, "w:updateFields")
    xml2::xml_set_attr(update, "w:val", "true")
    xml2::write_xml(settings, settings_file)
  }
  apply_report_layout(directory)
  doc <- xml2::read_xml(document_file)
  styles <- xml2::read_xml(styles_file)
  finalise_report_figures(doc, styles, ns)
  xml2::write_xml(doc, document_file)
  pack_word_package(directory, path)
  invisible(path)
}

clear_report_layout_table <- function(table, ns) {
  props <- xml2::xml_find_first(table, "w:tblPr", ns)
  if (inherits(props, "xml_missing")) props <- xml2::xml_add_child(table, "w:tblPr", .where = 0)
  xml2::xml_remove(xml2::xml_find_all(props, "w:tblBorders | w:shd", ns))
  borders <- xml2::xml_add_child(props, "w:tblBorders")
  for (side in c("top", "left", "bottom", "right", "insideH", "insideV")) {
    border <- xml2::xml_add_child(borders, paste0("w:", side))
    xml2::xml_set_attr(border, "w:val", "nil")
  }
  # A long inner table must still be allowed to break across pages. Repeating
  # the single wrapper row would repeat its entire caption and data table.
  xml2::xml_remove(xml2::xml_find_all(table, "w:tr/w:trPr/w:tblHeader | w:tr/w:trPr/w:cantSplit", ns))
  for (cell in xml2::xml_find_all(table, "w:tr/w:tc", ns)) {
    cell_props <- xml2::xml_find_first(cell, "w:tcPr", ns)
    if (inherits(cell_props, "xml_missing")) cell_props <- xml2::xml_add_child(cell, "w:tcPr", .where = 0)
    xml2::xml_remove(xml2::xml_find_all(cell_props, "w:tcBorders | w:shd", ns))
    shade <- xml2::xml_add_child(cell_props, "w:shd")
    xml2::xml_set_attrs(shade, c("w:val" = "clear", "w:fill" = "auto"))
    for (paragraph in xml2::xml_find_all(cell, "w:p[following-sibling::w:tbl]", ns)) {
      pprops <- xml2::xml_find_first(paragraph, "w:pPr", ns)
      if (inherits(pprops, "xml_missing")) pprops <- xml2::xml_add_child(paragraph, "w:pPr", .where = 0)
      xml2::xml_remove(xml2::xml_find_all(pprops, "w:keepNext", ns))
      keep <- xml2::xml_add_child(pprops, "w:keepNext")
      xml2::xml_set_attr(keep, "w:val", "1")
    }
  }
  invisible(table)
}

# Apply spacing to the neighbouring text paragraphs, outside the table borders.
# Keep heading spacing; captions sit close to their table.
space_report_table <- function(table, styles, ns, points = 6) {
  before <- xml2::xml_find_first(table, "preceding-sibling::*[1]", ns)
  after <- xml2::xml_find_first(table, "following-sibling::*[1]", ns)
  if (!inherits(after, "xml_missing") && xml2::xml_name(after) == "tbl") {
    separator <- xml2::read_xml(paste0('<w:p xmlns:w="', ns[["w"]], '"/>'))
    xml2::xml_add_sibling(table, separator, .where = "after")
    after <- xml2::xml_find_first(table, "following-sibling::*[1]", ns)
  }
  for (side in c("before", "after")) {
    paragraph <- if (side == "before") before else after
    if (inherits(paragraph, "xml_missing") || xml2::xml_name(paragraph) != "p") next
    props <- xml2::xml_find_first(paragraph, "w:pPr", ns)
    if (inherits(props, "xml_missing")) props <- xml2::xml_add_child(paragraph, "w:pPr", .where = 0)
    spacing <- xml2::xml_find_first(props, "w:spacing", ns)
    if (inherits(spacing, "xml_missing")) spacing <- xml2::xml_add_child(props, "w:spacing")
    # Pandoc separates successive tables with an empty paragraph. Make that a
    # single six-point gap rather than adding two margins around a blank line.
    between_tables <- length(xml2::xml_find_all(paragraph,
      "preceding-sibling::*[1][self::w:tbl] | following-sibling::*[1][self::w:tbl]", ns)) == 2L
    has_content <- nzchar(trimws(xml2::xml_text(paragraph))) ||
      length(xml2::xml_find_all(paragraph, ".//w:br | .//w:drawing | .//w:object | .//w:fldChar", ns)) > 0L
    if (side == "before" && has_content) {
      keep <- xml2::xml_find_first(props, "w:keepNext", ns)
      if (inherits(keep, "xml_missing")) keep <- xml2::xml_add_child(props, "w:keepNext")
      xml2::xml_set_attr(keep, "w:val", "1")
    }
    if (between_tables && !has_content) {
      xml2::xml_set_attrs(spacing, c("w:before" = "0", "w:after" = "0",
                                    "w:line" = as.character(points * 20), "w:lineRule" = "exact"))
    } else {
      attribute <- if (side == "before") "after" else "before"
      existing <- report_paragraph_spacing(paragraph, styles, attribute, ns)
      style_id <- xml2::xml_attr(xml2::xml_find_first(props, "w:pStyle", ns), "w:val", ns)
      is_caption <- side == "before" && !is.na(style_id) && grepl("caption", style_id, ignore.case = TRUE)
      gap <- if (is_caption) 40 else max(points * 20, existing)
      xml2::xml_set_attr(spacing, paste0("w:", attribute), as.character(gap))
      xml2::xml_set_attr(spacing, paste0("w:", attribute, "Autospacing"), "0")
    }
    contextual <- xml2::xml_find_first(props, "w:contextualSpacing", ns)
    if (inherits(contextual, "xml_missing")) contextual <- xml2::xml_add_child(props, "w:contextualSpacing")
    xml2::xml_set_attr(contextual, "w:val", "0")
  }
  invisible(table)
}

report_paragraph_spacing <- function(paragraph, styles, side, ns) {
  read_spacing <- function(node) {
    value <- xml2::xml_attr(xml2::xml_find_first(node, "w:pPr/w:spacing", ns), paste0("w:", side), ns)
    suppressWarnings(as.numeric(value))
  }
  value <- read_spacing(paragraph)
  if (!is.na(value)) return(value)
  if (is.null(styles)) return(0)
  entries <- xml2::xml_find_all(styles, "w:style[@w:type='paragraph']", ns)
  ids <- xml2::xml_attr(entries, "w:styleId", ns)
  id <- xml2::xml_attr(xml2::xml_find_first(paragraph, "w:pPr/w:pStyle", ns), "w:val", ns)
  if (is.na(id)) {
    id <- xml2::xml_attr(xml2::xml_find_first(styles, "w:style[@w:type='paragraph'][@w:default='1']", ns), "w:styleId", ns)
  }
  visited <- character()
  while (!is.na(id) && id %in% ids && !id %in% visited) {
    visited <- c(visited, id)
    style <- entries[[match(id, ids)]]
    value <- read_spacing(style)
    if (!is.na(value)) return(value)
    id <- xml2::xml_attr(xml2::xml_find_first(style, "w:basedOn", ns), "w:val", ns)
  }
  value <- xml2::xml_attr(xml2::xml_find_first(styles, "w:docDefaults/w:pPrDefault/w:pPr/w:spacing", ns),
                          paste0("w:", side), ns)
  value <- suppressWarnings(as.numeric(value))
  if (is.na(value)) 0 else value
}

remove_word_parts <- function(directory, parent) {
  if (!dir.exists(directory)) return(invisible(NULL))
  resolved <- normalizePath(directory, winslash = "/", mustWork = TRUE)
  parent <- normalizePath(parent, winslash = "/", mustWork = TRUE)
  if (!identical(dirname(resolved), parent) ||
      !grepl("^\\.(corporate|report)-parts-", basename(resolved))) {
    stop("Ungueltiger temporaerer Word-Arbeitsordner.", call. = FALSE)
  }
  unlink(resolved, recursive = TRUE)
  invisible(NULL)
}
