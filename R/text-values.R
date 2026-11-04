# Mark values where they enter report text, never by searching for matching
# numbers/words afterwards. Fixed prose can contain the same text legitimately.
report_text_value <- function(value, config = NULL, markdown = FALSE) {
  text <- as.character(value)
  if (!markdown) text <- report_markdown_text(text)
  if (!identical(config$report$data_origin, "synthetic")) return(text)
  present <- !is.na(text) & nzchar(text)
  marked <- grepl('custom-style="EatSimulatedValue"', text, fixed = TRUE)
  index <- which(present & !marked)
  text[index] <- paste0("[", text[index], ']{custom-style="EatSimulatedValue"}')
  text
}

report_inline_value_hook <- function(config, previous) {
  force(config)
  force(previous)
  function(x) report_text_value(previous(x), config, markdown = TRUE)
}

highlight_report_run <- function(run, ns = word_ns()) {
  props <- layout_child(run, "rPr", ns, first = TRUE)
  xml2::xml_set_attr(layout_child(props, "highlight", ns), "w:val", "yellow")
  # Task-matrix headers have white lettering. Preserve the corporate cell
  # colour but use dark letters on the yellow text highlight for readability.
  colour <- xml2::xml_find_first(props, "w:color", ns)
  if (!inherits(colour, "xml_missing") &&
      identical(toupper(xml2::xml_attr(colour, "w:val", ns)), "FFFFFF")) {
    xml2::xml_set_attr(colour, "w:val", "000000")
    for (attribute in c("themeColor", "themeTint", "themeShade")) {
      xml2::xml_set_attr(colour, paste0("w:", attribute), NULL, ns)
    }
  }
  # Retain note font sizes (10 pt) and every other existing run property.
  layout_order_children(props, c("rStyle", "rFonts", "b", "bCs", "i", "iCs", "caps",
    "smallCaps", "strike", "dstrike", "outline", "shadow", "emboss", "imprint",
    "noProof", "snapToGrid", "vanish", "webHidden", "color", "spacing", "w", "kern",
    "position", "sz", "szCs", "highlight", "u", "effect", "bdr", "shd", "fitText",
    "vertAlign", "rtl", "cs", "em", "lang", "eastAsianLayout", "specVanish", "oMath",
    "rPrChange"))
  invisible(run)
}

apply_report_value_highlights <- function(doc, styles, report, ns = word_ns()) {
  if (!identical(report$data_origin, "synthetic")) return(invisible(doc))
  if (identical(xml2::xml_name(doc), "hdr")) mark_report_header_values(doc, report, ns)
  marker <- "EatSimulatedValue"
  style <- xml2::xml_find_first(styles, paste0("w:style[@w:styleId='", marker, "']"), ns)
  if (inherits(style, "xml_missing")) {
    style <- xml2::xml_add_child(styles, "w:style")
    xml2::xml_set_attrs(style, c("w:type" = "character", "w:customStyle" = "1", "w:styleId" = marker))
    xml2::xml_set_attr(xml2::xml_add_child(style, "w:name"), "w:val", marker)
  }
  # Word does not reliably display character-style highlights and may remove
  # identical direct formatting on save. Keep the style as provenance only;
  # the visible yellow must remain a direct property of each supplied run.
  xml2::xml_remove(xml2::xml_find_all(style, "w:rPr/w:highlight", ns))
  for (run in xml2::xml_find_all(doc, ".//w:r[w:rPr/w:rStyle/@w:val='EatSimulatedValue']", ns)) {
    highlight_report_run(run, ns)
  }
  # Names and affiliation are inserted as XML after Pandoc and are entirely
  # supplied values. Their paragraph style identifies them without text matching.
  for (run in xml2::xml_find_all(doc,
    ".//w:p[w:pPr/w:pStyle/@w:val='ReportAuthors' or w:pPr/w:pStyle/@w:val='ReportAffiliation']//w:r[w:t]", ns)) {
    highlight_report_run(run, ns)
  }
  # These owned matrices need their structural character styles for shading
  # and pauses. Applying a second character style in Markdown would erase that
  # metadata. Highlight their supplied cells directly, leaving static stubs alone.
  for (table in xml2::xml_find_all(doc, "//w:tbl[not(.//w:tbl)]", ns)) {
    header_styles <- xml2::xml_attr(xml2::xml_find_all(table, "w:tr[1]//w:rStyle", ns), "w:val", ns)
    design <- "EatDesignHeader" %in% header_styles
    tasks <- "EatTaskMatrix" %in% header_styles
    if (!design && !tasks) next
    rows <- xml2::xml_find_all(table, "w:tr", ns)
    for (i in seq_along(rows)) {
      cells <- xml2::xml_find_all(rows[[i]], "w:tc", ns)
      for (j in seq_along(cells)) {
        if (i == 1L && j == 1L) next
        for (run in xml2::xml_find_all(cells[[j]], ".//w:r[w:t[normalize-space(.) != '']]", ns)) {
          highlight_report_run(run, ns)
        }
      }
    }
  }
  invisible(doc)
}

# Word populates the corporate header from its title document-property control.
# Once materialised, mark the two supplied title fragments and keep that owned
# control as rich text so reopening Word cannot replace the individual runs.
mark_report_header_values <- function(doc, report, ns = word_ns()) {
  if (is.null(report$main_year) || is.null(report$subject)) return(invisible(doc))
  subject <- if (identical(report$subject, "de")) "Deutsch" else "Mathematik"
  fragments <- c("Vergleichsarbeiten ", as.character(report$main_year),
                 " 3. Jahrgangsstufe ", subject)
  expected <- paste0(fragments, collapse = "")
  controls <- xml2::xml_find_all(doc,
    "//w:sdt[w:sdtPr/w:dataBinding[contains(@w:xpath, ':title')] or w:sdtPr/w:tag/@w:val='EatReportTitleValues']", ns)
  for (control in controls) {
    paragraph <- xml2::xml_find_first(control, "w:sdtContent/w:p", ns)
    texts <- xml2::xml_find_all(paragraph, ".//w:t", ns)
    if (!identical(paste0(xml2::xml_text(texts), collapse = ""), expected)) next
    runs <- xml2::xml_find_all(paragraph, "w:r", ns)
    if (!length(runs)) next
    # Rebuilding only direct runs would duplicate text held by a hyperlink or
    # another nested control. Preserve such customised titles and their binding.
    if (length(xml2::xml_find_all(paragraph, "w:r/w:t", ns)) != length(texts)) next
    props <- xml2::xml_find_first(runs[[1L]], "w:rPr", ns)
    control_props <- xml2::xml_find_first(control, "w:sdtPr", ns)
    xml2::xml_remove(xml2::xml_find_all(control_props, "w:dataBinding|w:text", ns))
    xml2::xml_set_attr(layout_child(control_props, "tag", ns), "w:val", "EatReportTitleValues")
    for (i in seq_along(fragments)) {
      run <- xml2::xml_add_child(paragraph, "w:r")
      if (!inherits(props, "xml_missing")) xml2::xml_add_child(run, props)
      text <- xml2::xml_add_child(run, "w:t")
      xml2::xml_set_attr(text, "xml:space", "preserve")
      xml2::xml_text(text) <- fragments[i]
      if (i %in% c(2L, 4L)) {
        rprops <- layout_child(run, "rPr", ns, first = TRUE)
        xml2::xml_set_attr(layout_child(rprops, "rStyle", ns, first = TRUE), "w:val", "EatSimulatedValue")
      }
    }
    xml2::xml_remove(runs)
  }
  invisible(doc)
}

# Footnote text is stored outside document.xml. Process its explicit markers as
# well; no string matching is used and body/title formatting is left untouched.
finalise_report_value_parts <- function(directory, report, ns = word_ns()) {
  if (!identical(report$data_origin, "synthetic")) return(invisible(directory))
  styles_path <- file.path(directory, "word/styles.xml")
  styles <- xml2::read_xml(styles_path)
  parts <- list.files(file.path(directory, "word"), full.names = TRUE,
    pattern = "^(header[0-9]*|footer[0-9]*|footnotes|endnotes)\\.xml$")
  for (path in parts) {
    part <- xml2::read_xml(path)
    apply_report_value_highlights(part, styles, report, ns)
    xml2::write_xml(part, path)
  }
  xml2::write_xml(styles, styles_path)
  invisible(directory)
}
