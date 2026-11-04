# Figure notes use an explicit style rather than matching words such as
# "Anmerkung": table notes and ordinary prose retain the body typography.
report_note_style_ids <- function(styles, ns) {
  nodes <- xml2::xml_find_all(styles, "w:style", ns)
  ids <- xml2::xml_attr(nodes, "w:styleId", ns)
  names <- xml2::xml_attr(xml2::xml_find_first(nodes, "w:name", ns), "w:val", ns)
  normalise <- function(x) tolower(gsub("[ _-]", "", x))
  selected <- normalise(ids) %in% "reportfigurenote" |
    normalise(names) %in% "reportfigurenote"
  # Derived and linked styles must not restore the larger body text size.
  parents <- lapply(nodes, function(node) {
    xml2::xml_attr(xml2::xml_find_all(node, "w:basedOn|w:link", ns), "w:val", ns)
  })
  for (pass in seq_along(ids)) {
    previous <- selected
    selected <- selected | vapply(parents, function(parent) any(parent %in% ids[selected]), logical(1))
    if (identical(previous, selected)) break
  }
  ids[selected]
}

report_link_style_ids <- function(styles, ns) {
  nodes <- xml2::xml_find_all(styles, "w:style", ns)
  ids <- xml2::xml_attr(nodes, "w:styleId", ns)
  names <- xml2::xml_attr(xml2::xml_find_first(nodes, "w:name", ns), "w:val", ns)
  normalise <- function(x) tolower(gsub("[ _-]", "", x))
  labels <- c("hyperlink", "followedhyperlink", "visitedhyperlink",
              "besuchterhyperlink", "verfolgterhyperlink")
  ids[normalise(ids) %in% labels | normalise(names) %in% labels]
}

report_link_colour <- function(props, ns) {
  colour <- layout_child(props, "color", ns)
  xml2::xml_set_attr(colour, "w:val", "B40036")
  for (attribute in c("themeColor", "themeTint", "themeShade")) {
    xml2::xml_set_attr(colour, paste0("w:", attribute), NULL, ns)
  }
  # A separately coloured underline must not retain the old hyperlink blue.
  underline <- xml2::xml_find_first(props, "w:u", ns)
  if (!inherits(underline, "xml_missing")) {
    xml2::xml_set_attr(underline, "w:color", "B40036")
    for (attribute in c("themeColor", "themeTint", "themeShade")) {
      xml2::xml_set_attr(underline, paste0("w:", attribute), NULL, ns)
    }
  }
  layout_order_children(props, c("rStyle", "rFonts", "b", "bCs", "i", "iCs", "caps",
    "smallCaps", "strike", "dstrike", "outline", "shadow", "emboss", "imprint",
    "noProof", "snapToGrid", "vanish", "webHidden", "color", "spacing", "w", "kern",
    "position", "sz", "szCs", "highlight", "u", "effect", "bdr", "shd", "fitText",
    "vertAlign", "rtl", "cs", "em", "lang", "eastAsianLayout", "specVanish", "oMath",
    "rPrChange"))
  invisible(props)
}

report_figure_note_properties <- function(props, ns) {
  layout_paragraph_properties(props, ns)
  spacing <- layout_child(props, "spacing", ns)
  layout_set_attributes(spacing, c("w:line" = "240", "w:lineRule" = "auto",
    "w:before" = "0", "w:after" = "0", "w:beforeAutospacing" = "0",
    "w:afterAutospacing" = "0"), ns)
  xml2::xml_set_attr(spacing, "w:beforeLines", NULL, ns)
  xml2::xml_set_attr(spacing, "w:afterLines", NULL, ns)
  xml2::xml_set_attr(layout_child(props, "keepLines", ns), "w:val", "1")
  xml2::xml_set_attr(layout_child(props, "contextualSpacing", ns), "w:val", "0")
  # Reorder after adding note-specific paragraph properties.
  layout_order_children(props, c("pStyle", "keepNext", "keepLines", "pageBreakBefore",
    "framePr", "widowControl", "numPr", "suppressLineNumbers", "pBdr", "shd", "tabs",
    "suppressAutoHyphens", "kinsoku", "wordWrap", "overflowPunct", "topLinePunct",
    "autoSpaceDE", "autoSpaceDN", "bidi", "adjustRightInd", "snapToGrid", "spacing",
    "ind", "contextualSpacing", "mirrorIndents", "suppressOverlap", "jc",
    "textDirection", "textAlignment", "textboxTightWrap", "outlineLvl", "divId",
    "cnfStyle", "rPr", "sectPr", "pPrChange"))
  invisible(props)
}

format_report_note_link_styles <- function(styles, ns) {
  note_ids <- report_note_style_ids(styles, ns)
  for (node in xml2::xml_find_all(styles, "w:style", ns)) {
    if (!xml2::xml_attr(node, "w:styleId", ns) %in% note_ids) next
    layout_run_properties(layout_child(node, "rPr", ns), ns, size = 20)
    if (identical(xml2::xml_attr(node, "w:type", ns), "paragraph")) {
      report_figure_note_properties(layout_child(node, "pPr", ns), ns)
      layout_order_children(node, c("name", "aliases", "basedOn", "next", "link",
        "autoRedefine", "hidden", "uiPriority", "semiHidden", "unhideWhenUsed",
        "qFormat", "locked", "personal", "personalCompose", "personalReply", "rsid",
        "pPr", "rPr", "tblPr", "trPr", "tcPr", "tblStylePr"))
    }
  }
  # Define both standard character styles even when the input has no links yet.
  # Word can create FollowedHyperlink runs during field updates or navigation.
  ids <- xml2::xml_attr(xml2::xml_find_all(styles, "w:style", ns), "w:styleId", ns)
  for (id in setdiff(c("Hyperlink", "FollowedHyperlink"), ids)) {
    node <- xml2::xml_add_child(styles, "w:style")
    xml2::xml_set_attrs(node, c("w:type" = "character", "w:styleId" = id))
    xml2::xml_set_attr(xml2::xml_add_child(node, "w:name"), "w:val", id)
  }
  link_ids <- report_link_style_ids(styles, ns)
  for (node in xml2::xml_find_all(styles, "w:style", ns)) {
    if (xml2::xml_attr(node, "w:styleId", ns) %in% link_ids) {
      props <- layout_child(node, "rPr", ns)
      layout_run_properties(props, ns)
      report_link_colour(props, ns)
    }
  }
  invisible(styles)
}

format_report_notes_and_links <- function(part, styles, ns) {
  note_ids <- report_note_style_ids(styles, ns)
  for (paragraph in xml2::xml_find_all(part, "//w:p[w:pPr/w:pStyle]", ns)) {
    id <- xml2::xml_attr(xml2::xml_find_first(paragraph, "w:pPr/w:pStyle", ns), "w:val", ns)
    if (!id %in% note_ids) next
    props <- layout_child(paragraph, "pPr", ns, first = TRUE)
    report_figure_note_properties(props, ns)
    for (run in xml2::xml_find_all(paragraph, ".//w:r", ns)) {
      layout_run_properties(layout_child(run, "rPr", ns, first = TRUE), ns, size = 20)
    }
    marker <- xml2::xml_find_first(props, "w:rPr", ns)
    if (!inherits(marker, "xml_missing")) layout_run_properties(marker, ns, size = 20)
  }
  link_ids <- report_link_style_ids(styles, ns)
  runs <- xml2::xml_find_all(part, "//w:hyperlink//w:r | //w:r[w:rPr/w:rStyle]", ns)
  for (run in runs) {
    id <- xml2::xml_attr(xml2::xml_find_first(run, "w:rPr/w:rStyle", ns), "w:val", ns)
    in_link <- length(xml2::xml_find_all(run, "ancestor::w:hyperlink", ns)) > 0L
    if (in_link || id %in% link_ids) {
      report_link_colour(layout_child(run, "rPr", ns, first = TRUE), ns)
    }
  }
  invisible(part)
}

# Word may materialise new hyperlink runs when it updates the contents and
# cross-reference fields. Reapply only the owned note/link presentation after
# that step; do not repeat table/page-break processing or change field values.
finalise_report_note_links <- function(path, report = NULL) {
  directory <- tempfile(".report-parts-", tmpdir = dirname(path))
  on.exit(remove_word_parts(directory, dirname(path)), add = TRUE)
  extract_word_package(path, directory)
  ns <- word_ns()
  styles_path <- file.path(directory, "word/styles.xml")
  styles <- xml2::read_xml(styles_path)
  format_report_note_link_styles(styles, ns)
  xml2::write_xml(styles, styles_path)
  parts <- list.files(file.path(directory, "word"), full.names = TRUE,
    pattern = "^(document|header[0-9]*|footer[0-9]*|footnotes|endnotes|comments)\\.xml$")
  for (part_path in parts) {
    part <- xml2::read_xml(part_path)
    format_report_notes_and_links(part, styles, ns)
    apply_report_value_highlights(part, styles, report, ns)
    xml2::write_xml(part, part_path)
  }
  xml2::write_xml(styles, styles_path)
  pack_word_package(directory, path)
  invisible(path)
}
