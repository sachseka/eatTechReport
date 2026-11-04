# Cover names are document inputs, independent of the package authors.
report_cover_data <- function(report) {
  list(authors = if (is.null(report$authors)) "[Autorinnen und Autoren]" else report$authors,
       affiliation = if (is.null(report$affiliation)) "[Affiliation]" else report$affiliation)
}

add_report_cover_authors <- function(doc, styles, report, ns = word_ns()) {
  values <- report_cover_data(report)
  style_nodes <- xml2::xml_find_all(styles, "w:style", ns)
  style_names <- tolower(xml2::xml_attr(xml2::xml_find_first(style_nodes, "w:name", ns), "w:val", ns))
  style_ids <- xml2::xml_attr(style_nodes, "w:styleId", ns)
  subtitle_id <- style_ids[match("subtitle", style_names)]
  paragraphs <- xml2::xml_find_all(doc, "w:body/w:p", ns)
  ids <- xml2::xml_attr(xml2::xml_find_first(paragraphs, "w:pPr/w:pStyle", ns), "w:val", ns)
  position <- match(subtitle_id, ids)
  if (is.na(subtitle_id) || is.na(position)) {
    stop("Der Untertitel auf dem Deckblatt fehlt; Autoren konnten nicht eingefuegt werden.", call. = FALSE)
  }
  cursor <- paragraphs[[position]]
  # Reapplying this step replaces its own paragraphs, without touching prose.
  xml2::xml_remove(paragraphs[!is.na(ids) & ids %in% c("ReportAuthors", "ReportAffiliation")])
  author_text <- if (length(values$authors) == 1L) values$authors else {
    paste(paste(utils::head(values$authors, -1L), collapse = ", "),
          utils::tail(values$authors, 1L), sep = " & ")
  }
  lines <- list(ReportAuthors = author_text, ReportAffiliation = values$affiliation)
  normal <- style_ids[match("normal", style_names)]
  for (id in names(lines)) {
    style <- xml2::xml_find_first(styles, paste0("w:style[@w:styleId='", id, "']"), ns)
    if (inherits(style, "xml_missing")) {
      style <- xml2::xml_add_child(styles, "w:style")
      xml2::xml_set_attrs(style, c("w:type" = "paragraph", "w:customStyle" = "1", "w:styleId" = id))
      xml2::xml_set_attr(xml2::xml_add_child(style, "w:name"), "w:val", id)
      if (!is.na(normal)) xml2::xml_set_attr(xml2::xml_add_child(style, "w:basedOn"), "w:val", normal)
      run_props <- xml2::xml_add_child(style, "w:rPr")
      for (property in c("b", "i")) xml2::xml_set_attr(xml2::xml_add_child(run_props, paste0("w:", property)), "w:val", "0")
      xml2::xml_set_attr(xml2::xml_add_child(run_props, "w:color"), "w:val", "000000")
    }
    paragraph <- xml2::read_xml(paste0('<w:p xmlns:w="', ns[["w"]], '"/>'))
    props <- xml2::xml_add_child(paragraph, "w:pPr")
    xml2::xml_set_attr(xml2::xml_add_child(props, "w:pStyle"), "w:val", id)
    for (i in seq_along(lines[[id]])) {
      run <- xml2::xml_add_child(paragraph, "w:r")
      if (i > 1L) xml2::xml_add_child(run, "w:br")
      # xml_text escapes ampersands/angle brackets; names never become markup.
      text_node <- xml2::xml_add_child(run, "w:t")
      xml2::xml_text(text_node) <- lines[[id]][[i]]
    }
    xml2::xml_add_sibling(cursor, paragraph, .where = "after")
    cursor <- xml2::xml_find_first(cursor, "following-sibling::*[1]", ns)
  }
  invisible(doc)
}
