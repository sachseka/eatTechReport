#' Supply editorial values for editable report chapters
#'
#' Create an optional `config$editorial` list for study-specific prose. These
#' values describe decisions and procedures supplied by the caller; they never
#' filter persons, score responses or estimate reliability.
#'
#' @param ... Named values from the fields documented below. Omit a field or
#'   supply NULL to leave it open. Unknown or duplicated names are errors.
#' @return A validated named list to assign to `input$config$editorial`.
#' @details Text fields are `study_period`, `print_provider`, `booklet_structure`,
#'   `pause_description`, `reliability_description`, `software_description`,
#'   `reference_population`, `exclusion_reasons`, `model_publication` and
#'   `ds_reference_adjustment`. They contain one nonempty plain-text value.
#'
#'   `coding_training_sessions`, `ds_linking_items` and `ds_dependent_items`
#'   are nonnegative integer counts. `double_coding_percent` and
#'   `agreement_percent` are percentages from 0 to 100; `cohen_kappa` lies
#'   between -1 and 1. Values document upstream results, not calculations
#'   performed by this package.
#'   `agreement_percent` is the upstream median of the item-specific percentage
#'   agreements, matching the report's `Median = ...` wording; it is not a
#'   pooled proportion across all responses.
#'
#'   Optional `reliability_by_scale` is a data frame with `scale_id`,
#'   `agreement_percent`, `cohen_kappa` and `reliability_description` columns.
#'   Each row describes one configured scale; duplicate or unknown scales are
#'   rejected. German coding text reports each scale separately, leaving
#'   missing rows open instead of repeating a pooled result. For mathematics,
#'   a supplied `MO` row takes precedence over the scalar reliability fields.
#'
#'   `testcenter_version`, `kodierbox_version`, `eatpreptba_version` and
#'   `tam_version` contain the software versions used. Their corresponding
#'   `_year` fields contain citation years as positive integers. Supply actual
#'   study versions; the renderer does not substitute locally installed or
#'   latest online versions.
#'
#'   `include_booklet_structure` is a logical switch for the design-structure
#'   sentence (default TRUE). Without an explicit `booklet_structure` text,
#'   block counts and module order are derived from the supplied booklet slots.
#'   Test duration is always derived from the design data.
#'
#'   `changed_conditions_included` is an optional logical statement about
#'   the upstream treatment of participants with changed test conditions.
#'   FALSE requires that none of those participants occur in the supplied
#'   analysis population. The explanation then uses participation counts;
#'   other sample characteristics continue to describe the analysis population.
#'   `exclusion_reasons` is an optional sentence in the participation-table note.
#'
#'   Editable Quarto blocks can use `editorial("study_period")` etc. Supplied
#'   and still-open values appear without square brackets. In synthetic mode
#'   they are highlighted yellow. The public text blocks use relevant design
#'   and sample fields; the remaining fields support optional local chapters.
#' @seealso [report_conventions()], [validate_report_input()], [render_report()]
#' @examples
#' input <- example_report()
#' input$config$editorial <- report_editorial(
#'   study_period = "Mai und Juni 2026",
#'   coding_training_sessions = 2L,
#'   changed_conditions_included = TRUE
#' )
#' validate_report_input(input)
#' @export
report_editorial <- function(...) {
  values <- list(...)
  validate_report_editorial(values)
  values <- values[!vapply(values, is.null, logical(1))]
  if (!length(values)) list() else values
}

report_editorial_fields <- function() {
  text <- c(study_period = "Erhebungszeitraum",
    print_provider = "Druckdienstleister",
    booklet_structure = "Aufbau der Testhefte",
    pause_description = "Zeitpunkt und Dauer vorgesehener Pausen",
    reliability_description = "Einordnung der Interrater-Reliabilit\u00e4t",
    software_description = "Software und Versionsnachweise erg\u00e4nzen",
    reference_population = "Referenzpopulation erg\u00e4nzen",
    exclusion_reasons = "Gr\u00fcnde f\u00fcr den Ausschluss erg\u00e4nzen",
    model_publication = "Ver\u00f6ffentlichungszeitpunkt des Kompetenzstufenmodells",
    ds_reference_adjustment = "Referenzpopulation und Varianzkorrektur erg\u00e4nzen",
    testcenter_version = "Version des IQB-Testcenters erg\u00e4nzen",
    kodierbox_version = "Version der IQB-Kodierbox erg\u00e4nzen",
    eatpreptba_version = "Version von eatPrepTBA erg\u00e4nzen",
    tam_version = "Version von TAM erg\u00e4nzen")
  counts <- c(coding_training_sessions = "Anzahl der Schulungstermine",
    ds_linking_items = "Anzahl der Verlinkungsitems",
    ds_dependent_items = "Anzahl auff\u00e4lliger Verlinkungsitems")
  years <- c(testcenter_year = "Zitierjahr des IQB-Testcenters erg\u00e4nzen",
    kodierbox_year = "Zitierjahr der IQB-Kodierbox erg\u00e4nzen",
    eatpreptba_year = "Zitierjahr von eatPrepTBA erg\u00e4nzen",
    tam_year = "Zitierjahr von TAM erg\u00e4nzen")
  list(text = text, counts = counts, years = years,
       percent = c(double_coding_percent = "Anteil doppelt kodierter Antworten",
                   agreement_percent = "Prozentuale \u00dcbereinstimmung"),
       kappa = c(cohen_kappa = "Kappa"),
       table = c(reliability_by_scale = "Interraterkennwerte je Skala"),
       flag = c(changed_conditions_included = "Ver\u00e4nderte Testbedingungen einbezogen",
                include_booklet_structure = "Testheftstruktur beschreiben"))
}

validate_report_editorial <- function(values) {
  if (is.null(values)) return(invisible(TRUE))
  fail <- function(message) stop("config$editorial: ", message, call. = FALSE)
  fields <- report_editorial_fields()
  allowed <- unlist(lapply(fields, names), use.names = FALSE)
  if (!is.list(values) || is.data.frame(values) ||
      (length(values) && (is.null(names(values)) || anyNA(names(values)) ||
       anyDuplicated(names(values)) || any(!names(values) %in% allowed)))) {
    fail("Benannte Liste mit dokumentierten, eindeutigen Feldern erwartet.")
  }
  for (name in names(values)) {
    value <- values[[name]]
    if (is.null(value)) next
    if (name == "reliability_by_scale") {
      validate_editorial_reliability(value)
      next
    }
    if (!is.null(dim(value))) fail(paste0(name, " muss ein einzelner Wert ohne Dimensionen sein."))
    if (name %in% names(fields$text)) {
      if (!is.character(value) || length(value) != 1L || is.na(value) ||
          !nzchar(trimws(value)) || grepl("[[:cntrl:]]", value)) {
        fail(paste0(name, " braucht genau einen nichtleeren Text ohne Steuerzeichen."))
      }
    } else if (name %in% names(fields$flag)) {
      if (!is.logical(value) || length(value) != 1L || is.na(value)) {
        fail(paste0(name, " muss TRUE oder FALSE sein."))
      }
    } else {
      if (!is.numeric(value) || is.complex(value) || length(value) != 1L ||
          is.na(value) || !is.finite(value)) fail(paste0(name, " braucht eine endliche Zahl."))
      count <- name %in% names(fields$counts)
      year <- name %in% names(fields$years)
      minimum <- if (year) 1 else if (name == "cohen_kappa") -1 else 0
      maximum <- if (name %in% names(fields$percent)) 100 else if (name == "cohen_kappa") 1 else Inf
      if (value < minimum || value > maximum || ((count || year) && value != floor(value))) {
        fail(paste0(name, " liegt au\u00dferhalb des zul\u00e4ssigen Wertebereichs."))
      }
    }
  }
  if (!is.null(values$ds_linking_items) && !is.null(values$ds_dependent_items) &&
      values$ds_dependent_items > values$ds_linking_items) {
    fail("ds_dependent_items darf ds_linking_items nicht \u00fcberschreiten.")
  }
  invisible(TRUE)
}

report_editorial_value <- function(config, name, placeholder = NULL, digits = NULL) {
  fields <- report_editorial_fields()
  labels <- unlist(fields, use.names = FALSE)
  names(labels) <- unlist(lapply(fields, names), use.names = FALSE)
  if (!is.character(name) || length(name) != 1L || is.na(name) || !name %in% names(labels)) {
    stop("Unbekanntes redaktionelles Feld.", call. = FALSE)
  }
  if (name == "reliability_by_scale") stop("Tabellarische Kennwerte mit report_coding_reliability_text ausgeben.", call. = FALSE)
  validate_report_editorial(config$editorial)
  if (!is.null(digits) && (!is.numeric(digits) || !is.null(dim(digits)) || is.complex(digits) || length(digits) != 1L ||
      is.na(digits) || !is.finite(digits) || digits != floor(digits) || digits < 0 || digits > 8)) {
    stop("digits muss eine ganze Zahl zwischen 0 und 8 sein.", call. = FALSE)
  }
  if (!is.null(placeholder) && (!is.character(placeholder) || length(placeholder) != 1L ||
      is.na(placeholder) || !nzchar(trimws(placeholder)))) {
    stop("placeholder muss genau einen nichtleeren Text enthalten.", call. = FALSE)
  }
  value <- config$editorial[[name]]
  if (is.null(value)) value <- if (is.null(placeholder)) labels[[name]] else placeholder
  if (is.numeric(value)) {
    if (is.null(digits)) digits <- if (name %in% names(fields$percent)) 1L else if (name == "cohen_kappa") 2L else 0L
    value <- study_number(value, digits)
  }
  report_text_value(value, config)
}

# Derived design prose stays consistent when a study has a different number or
# arrangement of blocks. A local editorial override is deliberately explicit.
report_design_structure_text <- function(design, config) {
  if (identical(config$editorial$include_booklet_structure, FALSE)) return("")
  if (!is.null(config$editorial$booklet_structure)) {
    return(report_editorial_value(config, "booklet_structure"))
  }
  mark <- function(x) report_text_value(x, config)
  counts <- design$booklets$n_blocks
  if (length(unique(counts)) != 1L) {
    return(paste0("Je Testheft waren zwischen ", mark(min(counts)), " und ",
                  mark(max(counts)), " Bl\u00f6cke vorgesehen."))
  }
  sentence <- paste0("Jedes Testheft beinhaltete ", mark(counts[1L]), " Bl\u00f6cke")
  slots <- design$slots[design$slots$kind == "block", , drop = FALSE]
  slots <- slots[order(slots$booklet_id, slots$position), , drop = FALSE]
  sequences <- lapply(split(slots, slots$booklet_id), function(x) x$module)
  common <- length(sequences) && all(vapply(sequences, identical, logical(1), sequences[[1L]]))
  if (identical(config$report$subject, "ma") && common) {
    sequence <- sequences[[1L]]
    n_base <- sum(sequence == "base")
    if (n_base >= 1L && length(sequence) == n_base + 1L &&
        identical(sequence, c(rep("base", n_base), "supplement"))) {
      sentence <- paste0(sentence, ", wobei ",
        if (n_base == 1L) "der erste Block" else paste0("die ersten ", mark(n_base), " Bl\u00f6cke"),
        " f\u00fcr den Einsatz im Basismodul und der letzte Block f\u00fcr den Einsatz im Erg\u00e4nzungsmodul konzipiert waren")
    }
  }
  paste0(sentence, ".")
}

report_design_timing_text <- function(design, config) {
  mark <- function(x) report_text_value(x, config)
  minutes <- mean(design$booklets$test_minutes)
  text <- paste0("Die reine Testzeit betrug im Mittel ca. ",
                 mark(study_number(minutes, if (minutes == round(minutes)) 0L else 1L)), " min.")
  if (!is.null(config$editorial$pause_description)) {
    return(paste(text, report_editorial_value(config, "pause_description")))
  }
  slots <- design$slots[order(design$slots$booklet_id, design$slots$position), , drop = FALSE]
  slots$block_number <- stats::ave(as.integer(slots$kind == "block"), slots$booklet_id, FUN = cumsum)
  pauses <- slots[slots$kind == "pause", , drop = FALSE]
  if (!nrow(pauses)) return(paste(text, "Es waren keine Pausen vorgesehen."))
  if (length(unique(pauses$block_number)) == 1L && length(unique(pauses$duration_minutes)) == 1L &&
      !anyDuplicated(pauses$booklet_id) && nrow(pauses) == nrow(design$booklets)) {
    pause_text <- paste0(if (pauses$block_number[1L] == 0L) "Vor dem ersten Block" else
      paste0("Nach Block ", mark(pauses$block_number[1L])), " war eine Pause von ",
      mark(study_number(pauses$duration_minutes[1L],
        if (pauses$duration_minutes[1L] == round(pauses$duration_minutes[1L])) 0L else 1L)), " min vorgesehen.")
  } else pause_text <- "Zeitpunkt und Dauer der vorgesehenen Pausen sind in den Anmerkungen zu den Testdesigns angegeben."
  paste(text, pause_text)
}
