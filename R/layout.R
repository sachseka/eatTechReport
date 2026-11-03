# Apply the report typography to an extracted Word package. Both the reference
# document and the rendered document use this step: Pandoc and Word can add
# direct formatting which otherwise overrides the reference styles.
apply_report_layout <- function(directory) {
  ns <- word_ns()
  styles_file <- file.path(directory, "word/styles.xml")
  styles <- xml2::read_xml(styles_file)
  defaults <- layout_child(styles, "docDefaults", ns, first = TRUE)
  run_default <- layout_child(layout_child(defaults, "rPrDefault", ns), "rPr", ns)
  layout_run_properties(run_default, ns, size = 22)
  paragraph_default <- layout_child(layout_child(defaults, "pPrDefault", ns), "pPr", ns)
  layout_paragraph_properties(paragraph_default, ns)

  style_nodes <- xml2::xml_find_all(styles, "w:style", ns)
  ids <- xml2::xml_attr(style_nodes, "w:styleId", ns)
  names <- xml2::xml_attr(xml2::xml_find_first(style_nodes, "w:name", ns), "w:val", ns)
  roles <- stats::setNames(vapply(seq_along(ids), function(i) layout_style_role(c(ids[i], names[i])),
                          character(1)), ids)
  # Linked character styles and derived paragraph styles must agree with the
  # paragraph style; otherwise the old cover/heading size can reappear.
  parents <- lapply(style_nodes, function(style) {
    xml2::xml_attr(xml2::xml_find_all(style, "w:basedOn|w:link", ns), "w:val", ns)
  })
  for (pass in seq_along(ids)) {
    previous <- roles
    for (i in which(roles == "")) {
      inherited <- roles[parents[[i]]]
      inherited <- inherited[!is.na(inherited) & nzchar(inherited)]
      if (length(inherited)) roles[i] <- inherited[1L]
    }
    if (identical(previous, roles)) break
  }
  for (i in seq_along(style_nodes)) {
    style <- style_nodes[[i]]
    role <- roles[i]
    run_props <- layout_child(style, "rPr", ns)
    layout_run_properties(run_props, ns, size = layout_role_size(role))
    if (grepl("^heading[4-9]$", role)) {
      xml2::xml_set_attr(layout_child(run_props, "b", ns), "w:val", "1")
      layout_run_properties(run_props, ns)
    }
    if (identical(xml2::xml_attr(style, "w:type", ns), "paragraph")) {
      props <- layout_child(style, "pPr", ns)
      layout_paragraph_properties(props, ns, role)
    }
    layout_order_children(style, c("name", "aliases", "basedOn", "next", "link",
                                  "autoRedefine", "hidden", "uiPriority", "semiHidden",
                                  "unhideWhenUsed", "qFormat", "locked", "personal",
                                  "personalCompose", "personalReply", "rsid", "pPr",
                                  "rPr", "tblPr", "trPr", "tcPr", "tblStylePr"))
  }
  # Conditional table styles can carry their own font and small point sizes.
  for (props in xml2::xml_find_all(styles, "//w:rPr", ns)) layout_run_properties(props, ns)
  xml2::write_xml(styles, styles_file)

  parts <- list.files(file.path(directory, "word"), full.names = TRUE,
                      pattern = "^(document|header[0-9]*|footer[0-9]*|footnotes|endnotes|comments|numbering)\\.xml$")
  for (path in parts) {
    part <- xml2::read_xml(path)
    for (props in xml2::xml_find_all(part, "//w:rPr", ns)) {
      # Symbol/Wingdings bullet glyphs are not ordinary text; changing their
      # font would turn the corporate bullet into a missing-character box.
      bullet <- length(xml2::xml_find_all(props, "../w:numFmt[@w:val='bullet']", ns)) > 0L
      layout_run_properties(props, ns, set_font = !bullet)
    }
    # Empty separator paragraphs and image-only paragraphs retain their exact
    # spacing. They are layout elements, rather than lines of report text.
    for (paragraph in xml2::xml_find_all(part, "//w:p[.//w:t or .//w:instrText or .//w:fldSimple]", ns)) {
      id <- xml2::xml_attr(xml2::xml_find_first(paragraph, "w:pPr/w:pStyle", ns), "w:val", ns)
      role <- if (!is.na(id) && id %in% ids) roles[[id]] else layout_style_role(id)
      props <- layout_child(paragraph, "pPr", ns, first = TRUE)
      # Quarto's standalone bold labels (e.g. a domain before its booklet
      # explanation) behave as headings even when they use the body style.
      if (!nzchar(role) && basename(path) == "document.xml" &&
          !length(xml2::xml_find_all(paragraph, "ancestor::w:tbl", ns))) {
        text_runs <- xml2::xml_find_all(paragraph, ".//w:r[w:t[normalize-space(.) != '']]", ns)
        bold <- vapply(text_runs, function(run) {
          node <- xml2::xml_find_first(run, "w:rPr/w:b", ns)
          !inherits(node, "xml_missing") &&
            !xml2::xml_attr(node, "w:val", ns) %in% c("0", "false", "off")
        }, logical(1))
        if (length(bold) && all(bold)) {
          xml2::xml_set_attr(layout_child(props, "keepNext", ns), "w:val", "1")
        }
      }
      layout_paragraph_properties(props, ns, role)
      if (nzchar(role)) {
        for (run in xml2::xml_find_all(paragraph, ".//w:r[w:t or w:instrText]", ns)) {
          run_props <- layout_child(run, "rPr", ns, first = TRUE)
          if (grepl("^heading[4-9]$", role)) {
            xml2::xml_set_attr(layout_child(run_props, "b", ns), "w:val", "1")
          }
          layout_run_properties(run_props, ns, size = layout_role_size(role))
        }
      }
    }
    xml2::write_xml(part, path)
  }
  invisible(directory)
}

layout_child <- function(parent, name, ns, first = FALSE) {
  node <- xml2::xml_find_first(parent, paste0("w:", name), ns)
  if (inherits(node, "xml_missing")) {
    node <- xml2::xml_add_child(parent, paste0("w:", name), .where = if (first) 0 else Inf)
  }
  node
}

layout_style_role <- function(names) {
  keys <- tolower(gsub("[ _-]", "", names[!is.na(names)]))
  if (any(keys %in% c("title", "titel", "titeldeckblatt"))) return("title")
  if (any(keys %in% c("subtitle", "untertitel", "untertitel1", "subtiteldeckblatt"))) return("subtitle")
  if (any(keys == "reportauthors")) return("coverauthors")
  if (any(keys == "reportaffiliation")) return("coveraffiliation")
  if (any(keys %in% c("caption", "tablecaption", "imagecaption", "beschriftung"))) return("caption")
  if (any(keys %in% c("tocheading", "titelinhaltsverzeichnis",
                     "inhaltsverzeichnisberschrift1", "inhaltsverzeichnis\u00fcberschrift1"))) return("heading1")
  heading <- grep("^(heading|[u\u00fc]?berschrift)[1-9]$", keys, value = TRUE)
  if (length(heading)) return(paste0("heading", sub(".*([1-9])$", "\\1", heading[1L])))
  ""
}

layout_role_size <- function(role) {
  if (role == "title") return(44)
  if (role == "subtitle") return(36)
  if (role == "caption") return(22)
  if (role %in% c("coverauthors", "coveraffiliation")) return(22)
  if (grepl("^heading[1-9]$", role)) {
    level <- as.integer(sub("heading", "", role))
    return(c(32, 26, 24, rep(22, 6))[level])
  }
  NULL
}

layout_run_properties <- function(props, ns, size = NULL, set_font = TRUE) {
  if (set_font) {
    fonts <- layout_child(props, "rFonts", ns)
    # Theme font attributes take precedence over explicitly named fonts.
    for (attribute in c("asciiTheme", "hAnsiTheme", "eastAsiaTheme", "cstheme", "csTheme")) {
      xml2::xml_set_attr(fonts, paste0("w:", attribute), NULL, ns)
    }
    for (attribute in c("ascii", "hAnsi", "eastAsia", "cs")) {
      xml2::xml_set_attr(fonts, paste0("w:", attribute), "Arial")
    }
  }
  for (kind in c("sz", "szCs")) {
    node <- xml2::xml_find_first(props, paste0("w:", kind), ns)
    if (is.null(size) && inherits(node, "xml_missing")) next
    if (inherits(node, "xml_missing")) node <- layout_child(props, kind, ns)
    existing <- suppressWarnings(as.numeric(xml2::xml_attr(node, "w:val", ns)))
    value <- if (!is.null(size)) size else if (is.finite(existing)) max(22, existing) else 22
    xml2::xml_set_attr(node, "w:val", as.character(value))
  }
  layout_order_children(props, c("rStyle", "rFonts", "b", "bCs", "i", "iCs", "caps",
                                "smallCaps", "strike", "dstrike", "outline", "shadow",
                                "emboss", "imprint", "noProof", "snapToGrid", "vanish",
                                "webHidden", "color", "spacing", "w", "kern", "position",
                                "sz", "szCs", "highlight", "u", "effect", "bdr", "shd",
                                "fitText", "vertAlign", "rtl", "cs", "em", "lang",
                                "eastAsianLayout", "specVanish", "oMath", "rPrChange"))
  invisible(props)
}

layout_paragraph_properties <- function(props, ns, role = "") {
  spacing <- layout_child(props, "spacing", ns)
  layout_set_attributes(spacing, c("w:line" = "360", "w:lineRule" = "auto"), ns)
  xml2::xml_set_attr(layout_child(props, "snapToGrid", ns), "w:val", "0")
  xml2::xml_set_attr(layout_child(props, "widowControl", ns), "w:val", "1")
  if (grepl("^heading[1-9]$", role)) {
    level <- as.integer(sub("heading", "", role))
    before <- if (level == 1L) 480 else if (level == 2L) 360 else 240
    layout_set_attributes(spacing, c("w:before" = as.character(before), "w:after" = "120",
                                    "w:beforeAutospacing" = "0", "w:afterAutospacing" = "0"), ns)
    xml2::xml_set_attr(spacing, "w:beforeLines", NULL, ns)
    xml2::xml_set_attr(spacing, "w:afterLines", NULL, ns)
    xml2::xml_set_attr(layout_child(props, "keepNext", ns), "w:val", "1")
    xml2::xml_set_attr(layout_child(props, "keepLines", ns), "w:val", "1")
    xml2::xml_set_attr(layout_child(props, "contextualSpacing", ns), "w:val", "0")
    xml2::xml_set_attr(layout_child(props, "jc", ns), "w:val", "left")
  } else if (role == "caption") {
    layout_set_attributes(spacing, c("w:before" = "120", "w:after" = "40",
                                    "w:beforeAutospacing" = "0", "w:afterAutospacing" = "0"), ns)
    xml2::xml_set_attr(spacing, "w:beforeLines", NULL, ns)
    xml2::xml_set_attr(spacing, "w:afterLines", NULL, ns)
    xml2::xml_set_attr(layout_child(props, "keepNext", ns), "w:val", "1")
    xml2::xml_set_attr(layout_child(props, "contextualSpacing", ns), "w:val", "0")
  } else if (role %in% c("title", "subtitle")) {
    xml2::xml_set_attr(layout_child(props, "jc", ns), "w:val", "left")
  } else if (role %in% c("coverauthors", "coveraffiliation")) {
    layout_set_attributes(spacing, c("w:before" = if (role == "coverauthors") "480" else "0",
                                    "w:after" = if (role == "coverauthors") "120" else "0",
                                    "w:beforeAutospacing" = "0", "w:afterAutospacing" = "0"), ns)
    xml2::xml_set_attr(layout_child(props, "jc", ns), "w:val", "left")
    xml2::xml_set_attr(layout_child(props, "keepLines", ns), "w:val", "1")
    xml2::xml_set_attr(layout_child(props, "keepNext", ns), "w:val",
                      if (role == "coverauthors") "1" else "0")
  }
  layout_order_children(props, c("pStyle", "keepNext", "keepLines", "pageBreakBefore",
                                "framePr", "widowControl", "numPr", "suppressLineNumbers",
                                "pBdr", "shd", "tabs", "suppressAutoHyphens", "kinsoku",
                                "wordWrap", "overflowPunct", "topLinePunct", "autoSpaceDE",
                                "autoSpaceDN", "bidi", "adjustRightInd", "snapToGrid",
                                "spacing", "ind", "contextualSpacing", "mirrorIndents",
                                "suppressOverlap", "jc", "textDirection", "textAlignment",
                                "textboxTightWrap", "outlineLvl", "divId", "cnfStyle",
                                "rPr", "sectPr", "pPrChange"))
  invisible(props)
}

layout_set_attributes <- function(node, values, ns) {
  for (attribute in names(values)) xml2::xml_set_attr(node, attribute, values[[attribute]], ns)
  invisible(node)
}

layout_order_children <- function(parent, order) {
  children <- xml2::xml_children(parent)
  if (length(children) < 2L) return(invisible(parent))
  positions <- match(xml2::xml_name(children), order)
  positions[is.na(positions)] <- length(order) + 1L
  sorted <- base::order(positions)
  if (!identical(sorted, seq_along(children))) {
    for (node in children[sorted]) xml2::xml_add_child(parent, node)
    xml2::xml_remove(children)
  }
  invisible(parent)
}
