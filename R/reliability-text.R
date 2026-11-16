# Coding agreement is an upstream result, not an aggregate to infer from the
# number of domains. A partial table deliberately leaves the other scales open.
validate_editorial_reliability <- function(table, config = NULL) {
  if (is.null(table)) return(invisible(TRUE))
  fail <- function(message) {
    stop("config$editorial$reliability_by_scale: ", message, call. = FALSE)
  }
  fields <- c("scale_id", "agreement_percent", "cohen_kappa", "reliability_description")
  if (!is.data.frame(table) || nrow(table) == 0L || anyDuplicated(names(table)) ||
      !setequal(names(table), fields)) {
    fail(paste0("Nichtleere Tabelle mit genau den Spalten ", paste(fields, collapse = ", "), " erwartet."))
  }
  if (any(vapply(table, function(column) !is.null(dim(column)) || length(column) != nrow(table),
                 logical(1)))) {
    fail("Jede Spalte braucht einen einfachen Wert pro Zeile; Matrixspalten sind unzulaessig.")
  }
  for (field in c("scale_id", "reliability_description")) {
    value <- table[[field]]
    if (!is.character(value) || anyNA(value) || any(!nzchar(trimws(value))) ||
        any(grepl("[[:cntrl:]]", value))) {
      fail(paste0(field, " braucht nichtleere Zeichenketten ohne Fehlwerte oder Steuerzeichen."))
    }
  }
  if (anyDuplicated(table$scale_id)) fail("Jede scale_id darf nur einmal vorkommen.")
  if (!is.null(config) && any(!table$scale_id %in% names(config$scales))) {
    fail("scale_id enthaelt eine nicht konfigurierte Skala.")
  }
  for (field in c("agreement_percent", "cohen_kappa")) {
    value <- table[[field]]
    minimum <- if (field == "agreement_percent") 0 else -1
    maximum <- if (field == "agreement_percent") 100 else 1
    if (!is.numeric(value) || is.complex(value) || any(!is.finite(value)) ||
        any(value < minimum | value > maximum)) {
      fail(paste0(field, " braucht endliche Zahlen von ", minimum, " bis ", maximum,
                  " ohne Fehlwerte."))
    }
  }
  invisible(TRUE)
}

report_coding_reliability_text <- function(config) {
  table <- config$editorial$reliability_by_scale
  validate_editorial_reliability(table, config)
  value <- function(x) report_text_value(x, config)
  fields <- c("reliability_description", "agreement_percent", "cohen_kappa")
  description <- function(scale_id, global_fallback = FALSE) {
    row <- if (is.null(table)) NA_integer_ else match(scale_id, table$scale_id)
    if (!is.na(row)) {
      return(c(value(table$reliability_description[row]),
               value(study_number(table$agreement_percent[row], 1L)),
               value(study_number(table$cohen_kappa[row], 2L))))
    }
    if (global_fallback) {
      return(vapply(fields, function(field) report_editorial_value(config, field), character(1)))
    }
    label <- config$scales[[scale_id]]$label
    value(paste(c("Einordnung der Interrater-Reliabilit\u00e4t f\u00fcr",
                  "Prozentuale \u00dcbereinstimmung f\u00fcr", "Kappa f\u00fcr"), label))
  }
  paragraph <- function(values, prefix) {
    paste0(prefix, values[1L],
           " auf. Die prozentuale \u00dcbereinstimmung zwischen den Kodierenden betrug *Median* = ",
           values[2L], " % bei einem Kappa nach Cohen (1960) von ", values[3L], ".")
  }
  if (identical(config$report$subject, "ma")) {
    return(paragraph(description("MO", global_fallback = TRUE),
                     "Die in Haupttestmodule aufgenommenen Items wiesen "))
  }
  if (!identical(config$report$subject, "de")) {
    stop("Kodierreliabilitaetstext unterstuetzt nur Deutsch oder Mathematik.", call. = FALSE)
  }
  paragraphs <- vapply(names(config$scales), function(scale_id) {
    prefix <- paste0("F\u00fcr den Kompetenzbereich \u201e", value(config$scales[[scale_id]]$label),
                      "\u201c wiesen die in Haupttestmodule aufgenommenen Items ")
    paragraph(description(scale_id), prefix)
  }, character(1))
  paste(paragraphs, collapse = "\n\n")
}
