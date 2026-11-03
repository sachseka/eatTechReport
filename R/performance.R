#' Generate synthetic inputs for the performance chapter
#'
#' Create a complete, unweighted VERA-3 performance example on the reporting
#' metric. All values are simulated; no item-response model is fitted.
#'
#' @param profile Example profile: `"v3_de_lesen_zuhoeren"` for German reading
#'   and listening, or `"v3_ma_mg_mm"` for globally scaled mathematics.
#' @param seed Nonnegative integer random seed. This is not a reporting year.
#' @param n_persons Number of persons per scale, at least two.
#' @param n_pv Number of plausible values per person and scale, at least one.
#' @param main_year Main assessment year recorded in the configuration.
#' @param pilot_year Pilot year, supplied independently of `main_year`.
#' @param authors Character vector of report authors in display order.
#'   NULL uses visible placeholders. Stored in `config$report$authors`.
#' @param affiliation Shared affiliation for the authors. A character vector
#'   supplies separate lines. NULL uses a visible placeholder. Stored in
#'   `config$report$affiliation`.
#'
#' @return A list with `config` and `data`. `data$population` specifies the
#'   expected person-scale pairs independently of the long `data$pvs` table.
#'   Its schema is `0.2.0-draft` and its scope is `pilotierung_leistung`.
#' @details The default pilot year and numerical cuts are illustrative, not
#'   approved assessment specifications. The default 15 PVs reflect the current
#'   expectation, not a fixed requirement. The caller's random state is restored.
#' @seealso [validate_leistung_input()], [summarise_leistung_input()],
#'   [plot_performance()], [example_report()]
#' @examples
#' de <- example_leistung_input(seed = 42, n_pv = 15)
#' summarise_leistung_input(de)$descriptives
#' ma <- example_leistung_input("v3_ma_mg_mm")
#' @export
example_leistung_input <- function(profile = "v3_de_lesen_zuhoeren",
                                  seed = 42L,
                                  n_persons = 24L,
                                  n_pv = 15L,
                                  main_year = 2027L,
                                  pilot_year = 2026L,
                                  authors = NULL, affiliation = NULL) {
  profiles <- c("v3_de_lesen_zuhoeren", "v3_ma_mg_mm")
  if (!is.character(profile) || length(profile) != 1L ||
      is.na(profile) || !profile %in% profiles) {
    stop("profile muss eines der beiden dokumentierten Beispielprofile sein.",
         call. = FALSE)
  }
  whole_number <- function(x, minimum) {
    is.numeric(x) && length(x) == 1L && is.finite(x) &&
      x >= minimum && x <= .Machine$integer.max && x == floor(x)
  }
  if (!whole_number(seed, 0)) stop("seed muss eine nichtnegative ganze Zahl sein.", call. = FALSE)
  if (!whole_number(n_persons, 2)) stop("n_persons muss mindestens 2 sein.", call. = FALSE)
  if (!whole_number(n_pv, 1)) stop("n_pv muss mindestens 1 sein.", call. = FALSE)
  if (!whole_number(main_year, 1)) stop("main_year muss eine Jahreszahl sein.", call. = FALSE)
  if (!whole_number(pilot_year, 1)) stop("pilot_year muss eine Jahreszahl sein.", call. = FALSE)

  # seed steuert nur die Zufallsdaten; die Berichtjahre werden separat uebergeben.
  # Die Beispielerzeugung veraendert den Zufallszustand des Aufrufers nicht.
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit({
    if (had_seed) {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(list = ".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  set.seed(as.integer(seed))

  subject <- if (profile == profiles[1L]) "de" else "ma"
  if (subject == "de") {
    domains <- data.frame(
      domain_id = c("DL", "DH"),
      label = c("Lesen", "Zuh\u00f6ren"),
      scale_id = c("DL", "DH"), stringsAsFactors = FALSE
    )
    scale_labels <- c(DL = "Lesen", DH = "Zuh\u00f6ren")
    focus_domains <- character()
  } else {
    domains <- data.frame(
      domain_id = c("MZ", "MR", "MM", "MG", "MD"),
      label = c("Zahlen und Operationen", "Raum und Form", "Muster und Strukturen / Funktionaler Zusammenhang",
                "Gr\u00f6\u00dfen und Messen", "Daten, H\u00e4ufigkeit und Wahrscheinlichkeit"),
      scale_id = rep("MO", 5L), stringsAsFactors = FALSE
    )
    scale_labels <- c(MO = "Mathematik (Globalmodell)")
    focus_domains <- c("MG", "MM")
  }

  pv_ids <- sprintf("pv%02d", seq_len(n_pv))
  scales <- lapply(scale_labels, function(label) list(
    label = unname(label),
    metric = "bista_500",
    pv_ids = pv_ids,
    cuts = c(400, 475, 550, 625),
    level_labels = c("Ia", "Ib", "II", "III", "IV"),
    cut_source = "illustrative_demo_only"
  ))
  config <- list(
    schema_version = "0.2.0-draft",
    scope = "pilotierung_leistung",
    report = list(study = "vera3", subject = subject, main_year = as.integer(main_year),
                  pilot_year = as.integer(pilot_year), data_origin = "synthetic",
                  authors = if (is.null(authors)) c("[Autorin/Autor 1]", "[Autorin/Autor 2]") else authors,
                  affiliation = if (is.null(affiliation)) "[Affiliation]" else affiliation),
    domains = domains,
    focus_domains = focus_domains,
    performance = list(population = "all", weighted = FALSE, subgroups = FALSE),
    scales = scales
  )

  person_ids <- sprintf("demo_%03d", seq_len(n_persons))
  population <- do.call(rbind, lapply(names(scales), function(scale_id) {
    data.frame(person_id = person_ids, scale_id = scale_id, stringsAsFactors = FALSE)
  }))
  # Ein technisches Beispiel mit korrelierten Wiederholungswerten je Person.
  # Dies sind keine aus einem IRT-Modell geschaetzten Plausible Values.
  shared_person_value <- stats::rnorm(n_persons, mean = 0, sd = 80)
  pvs <- do.call(rbind, lapply(seq_along(scales), function(i) {
    scale_id <- names(scales)[i]
    center <- if (subject == "ma") 510 else c(480, 520)[i]
    person_value <- center + shared_person_value + stats::rnorm(n_persons, sd = 35)
    rows <- expand.grid(person_id = person_ids, pv_id = pv_ids,
                        KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
    data.frame(
      person_id = rows$person_id, scale_id = scale_id, pv_id = rows$pv_id,
      value = rep(person_value, times = n_pv) + stats::rnorm(n_persons * n_pv, sd = 25),
      stringsAsFactors = FALSE
    )
  }))
  rownames(population) <- rownames(pvs) <- NULL
  input <- list(config = config, data = list(population = population, pvs = pvs))
  validate_leistung_input(input)
  input
}

#' Validate complete performance inputs
#'
#' Check the configuration and all expected person-scale-PV combinations before
#' calculating results. Missing or non-finite values are errors; no observations
#' are dropped or imputed.
#'
#' @param input A list with `config` and `data`, as returned by
#'   [example_leistung_input()].
#' @return Invisibly `TRUE` for valid inputs; otherwise an error.
#' @details German domain and scale codes are `DL`, `DH`, `DO`, and `DS`.
#'   Mathematics domains `MZ`, `MG`, `MM`, `MR`, and `MD` all map to `MO`.
#'   Each person-scale pair must have exactly the configured PV identifiers.
#'   The population must be supplied independently of the PV table to detect
#'   entirely missing persons or scales. All cases are unweighted, without
#'   subgroups. Observed inputs cannot use cuts marked `illustrative_demo_only`.
#' @examples
#' validate_leistung_input(example_leistung_input())
#' @export
validate_leistung_input <- function(input) {
  input <- performance_component(input)
  fail <- function(message) stop(message, call. = FALSE)
  exact_names <- function(x, expected, label, is_table = FALSE) {
    if ((is_table && !is.data.frame(x)) || (!is_table && (!is.list(x) || is.data.frame(x))) ||
        is.null(names(x)) || anyDuplicated(names(x)) || !setequal(names(x), expected)) {
      fail(paste0(label, " erwartet genau: ", paste(expected, collapse = ", "), "."))
    }
  }
  strings <- function(x, label, unique = FALSE) {
    if (!is.character(x) || length(x) == 0L || anyNA(x) ||
        any(!nzchar(trimws(x))) || any(grepl("[[:cntrl:]]", x)) ||
        (unique && anyDuplicated(x))) {
      fail(paste0(label, " muss nichtleere Zeichenketten ohne Fehlwerte",
                  if (unique) " und ohne Duplikate" else "", " enthalten."))
    }
  }
  scalar_string <- function(x, label) {
    strings(x, label)
    if (length(x) != 1L) fail(paste0(label, " muss genau einen Wert enthalten."))
  }
  key <- function(...) paste(..., sep = "\r")

  exact_names(input, c("config", "data"), "input")
  config <- input$config
  data <- input$data
  exact_names(config, c("schema_version", "scope", "report", "domains", "focus_domains",
                         "performance", "scales"), "config")
  if (!identical(config$schema_version, "0.2.0-draft") ||
      !identical(config$scope, "pilotierung_leistung")) {
    fail("Erwartet werden schema_version = '0.2.0-draft' und scope = 'pilotierung_leistung'.")
  }
  cover_fields <- intersect(c("authors", "affiliation"), names(config$report))
  exact_names(config$report, c("study", "subject", "main_year", "pilot_year", "data_origin", cover_fields),
              "config$report")
  for (field in cover_fields) strings(config$report[[field]], paste0("config$report$", field))
  if (!identical(config$report$study, "vera3") ||
      !is.character(config$report$subject) || length(config$report$subject) != 1L ||
      is.na(config$report$subject) || !config$report$subject %in% c("de", "ma")) {
    fail("Unterstuetzt wird VERA-3 mit subject = 'de' oder 'ma'.")
  }
  for (field in c("main_year", "pilot_year")) {
    value <- config$report[[field]]
    if (!is.numeric(value) || length(value) != 1L || !is.finite(value) ||
        value < 1 || value != floor(value)) fail(paste0("config$report$", field, " muss eine Jahreszahl sein."))
  }
  scalar_string(config$report$data_origin, "config$report$data_origin")
  if (!config$report$data_origin %in% c("synthetic", "observed")) {
    fail("data_origin muss 'synthetic' oder 'observed' sein.")
  }
  exact_names(config$performance, c("population", "weighted", "subgroups"), "config$performance")
  if (!identical(config$performance$population, "all") ||
      !identical(config$performance$weighted, FALSE) ||
      !identical(config$performance$subgroups, FALSE)) {
    fail("VERA-3-Leistung umfasst alle Faelle, ohne Gewichte und ohne Untergruppen.")
  }
  if (!is.list(config$scales) || is.data.frame(config$scales) || length(config$scales) == 0L) {
    fail("config$scales muss eine benannte, nichtleere Liste sein.")
  }
  strings(names(config$scales), "Skalenkennungen", unique = TRUE)
  scale_ids <- names(config$scales)
  for (scale_id in scale_ids) {
    scale <- config$scales[[scale_id]]
    label <- paste0("config$scales$", scale_id)
    exact_names(scale, c("label", "metric", "pv_ids", "cuts", "level_labels", "cut_source"), label)
    scalar_string(scale$label, paste0(label, "$label"))
    scalar_string(scale$cut_source, paste0(label, "$cut_source"))
    if (config$report$data_origin == "observed" &&
        scale$cut_source == "illustrative_demo_only") {
      fail(paste0(label, ": illustrative Demo-Cuts duerfen nicht fuer beobachtete Daten verwendet werden."))
    }
    if (!identical(scale$metric, "bista_500")) fail(paste0(label, " muss metric = 'bista_500' verwenden."))
    strings(scale$pv_ids, paste0(label, "$pv_ids"), unique = TRUE)
    strings(scale$level_labels, paste0(label, "$level_labels"), unique = TRUE)
    if (!is.numeric(scale$cuts) || length(scale$cuts) == 0L || any(!is.finite(scale$cuts)) ||
        any(diff(scale$cuts) <= 0) || length(scale$level_labels) != length(scale$cuts) + 1L) {
      fail(paste0(label, ": Cuts muessen endlich und streng aufsteigend sein; Stufenanzahl = Cut-Anzahl + 1."))
    }
  }

  exact_names(config$domains, c("domain_id", "label", "scale_id"), "config$domains", TRUE)
  strings(config$domains$domain_id, "domain_id", unique = TRUE)
  strings(config$domains$label, "Domaenenbezeichnungen")
  strings(config$domains$scale_id, "Domaenen-Skalen-Zuordnung")
  if (!setequal(config$domains$scale_id, scale_ids)) fail("Domaenen und konfigurierte Skalen passen nicht zusammen.")
  if (config$report$subject == "ma") {
    if (!identical(scale_ids, "MO") ||
        !setequal(config$domains$domain_id, c("MZ", "MR", "MM", "MG", "MD"))) {
      fail("Mathematik braucht die fuenf Leitideen und ausschliesslich die Skala 'MO'.")
    }
    strings(config$focus_domains, "focus_domains", unique = TRUE)
    if (length(config$focus_domains) != 2L ||
        any(!config$focus_domains %in% config$domains$domain_id)) {
      fail("Mathematik braucht genau zwei gueltige Schwerpunkt-Leitideen.")
    }
  } else {
    if (any(!config$domains$domain_id %in% c("DL", "DH", "DO", "DS")) ||
        any(config$domains$scale_id != config$domains$domain_id)) {
      fail("Deutsch braucht je Kompetenzbereich die gleichnamige Skala: DL, DH, DO oder DS.")
    }
    if (!is.character(config$focus_domains) || length(config$focus_domains) != 0L) {
      fail("focus_domains ist fuer Deutsch character(0); die Bereiche stehen in domains.")
    }
  }

  exact_names(data, c("population", "pvs"), "data")
  exact_names(data$population, c("person_id", "scale_id"), "data$population", TRUE)
  exact_names(data$pvs, c("person_id", "scale_id", "pv_id", "value"), "data$pvs", TRUE)
  for (field in c("person_id", "scale_id")) strings(data$population[[field]], paste0("population$", field))
  for (field in c("person_id", "scale_id", "pv_id")) strings(data$pvs[[field]], paste0("pvs$", field))
  if (!setequal(data$population$scale_id, scale_ids)) fail("population muss alle und nur die konfigurierten Skalen enthalten.")
  if (anyDuplicated(key(data$population$person_id, data$population$scale_id))) {
    fail("population enthaelt doppelte Person-Skala-Zuordnungen.")
  }
  if (!is.numeric(data$pvs$value) || any(!is.finite(data$pvs$value))) {
    fail("pvs$value muss vollstaendig numerisch und endlich sein: keine NA-, NaN- oder Inf-Werte.")
  }
  actual_keys <- key(data$pvs$person_id, data$pvs$scale_id, data$pvs$pv_id)
  if (anyDuplicated(actual_keys)) fail("pvs enthaelt doppelte Person-Skala-PV-Zuordnungen.")
  expected_keys <- unlist(lapply(scale_ids, function(scale_id) {
    persons <- data$population$person_id[data$population$scale_id == scale_id]
    if (length(persons) < 2L) fail(paste0("Skala '", scale_id, "' braucht mindestens zwei Personen."))
    pv_ids <- config$scales[[scale_id]]$pv_ids
    key(rep(persons, times = length(pv_ids)), scale_id,
        rep(pv_ids, each = length(persons)))
  }), use.names = FALSE)
  missing <- setdiff(expected_keys, actual_keys)
  extra <- setdiff(actual_keys, expected_keys)
  if (length(missing) || length(extra)) {
    example <- if (length(missing)) missing[1L] else extra[1L]
    fail(paste0("PV-Belegung stimmt nicht mit population und pv_ids ueberein: ",
                length(missing), " fehlende, ", length(extra), " unerwartete Zellen. Beispiel: ",
                gsub("\r", " / ", example, fixed = TRUE), "."))
  }
  invisible(TRUE)
}

#' Summarise plausible values by reporting scale
#'
#' Calculate unweighted summaries for each PV and aggregate those results across
#' PVs. Values are not averaged within persons before calculating summaries.
#'
#' @inheritParams validate_leistung_input
#' @return A list of three data frames: `descriptives` (person count, PV count,
#'   mean and SD per scale), `percentages` (competence-level intervals and shares),
#'   and `per_pv` (count, mean and sample variance per scale and PV). Results are
#'   unrounded. No standard errors or confidence intervals are estimated.
#' @details The reported mean is the average of PV-specific means. The reported
#'   SD is the square root of the average PV-specific sample variance (denominator
#'   N - 1), not the average of PV-specific SDs. Level shares are calculated
#'   within each PV then averaged. Values exactly equal to a cut belong to the
#'   higher level. The first and last intervals extend to infinity.
#' @examples
#' results <- summarise_leistung_input(example_leistung_input())
#' results$descriptives
#' results$percentages
#' @export
summarise_leistung_input <- function(input) {
  validate_leistung_input(input)
  config <- input$config
  data <- input$data
  per_scale <- lapply(names(config$scales), function(scale_id) {
    scale <- config$scales[[scale_id]]
    pvs <- data$pvs[data$pvs$scale_id == scale_id, , drop = FALSE]
    n <- sum(data$population$scale_id == scale_id)
    per_pv <- do.call(rbind, lapply(scale$pv_ids, function(pv_id) {
      values <- pvs$value[pvs$pv_id == pv_id]
      data.frame(scale_id = scale_id, pv_id = pv_id, n_persons = length(values),
                 mean = mean(values), variance = stats::var(values), stringsAsFactors = FALSE)
    }))
    shares <- vapply(scale$pv_ids, function(pv_id) {
      values <- pvs$value[pvs$pv_id == pv_id]
      # findInterval ordnet Werte auf einem Cut dem hoeheren Intervall zu.
      tabulate(findInterval(values, scale$cuts) + 1L,
               nbins = length(scale$level_labels)) / length(values)
    }, numeric(length(scale$level_labels)))
    proportions <- rowMeans(shares)
    list(
      descriptives = data.frame(scale_id = scale_id, n_persons = n,
                               n_pv = length(scale$pv_ids), mean = mean(per_pv$mean),
                               sd = sqrt(mean(per_pv$variance)), stringsAsFactors = FALSE),
      percentages = data.frame(scale_id = scale_id, level = seq_along(scale$level_labels),
                               level_label = scale$level_labels,
                               lower = c(-Inf, scale$cuts), upper = c(scale$cuts, Inf),
                               proportion = proportions, percent = 100 * proportions,
                               stringsAsFactors = FALSE),
      per_pv = per_pv
    )
  })
  result <- lapply(c("descriptives", "percentages", "per_pv"), function(component) {
    rows <- do.call(rbind, lapply(per_scale, `[[`, component))
    rownames(rows) <- NULL
    rows
  })
  names(result) <- c("descriptives", "percentages", "per_pv")
  result
}

#' Generate example inputs for the implemented report scope
#'
#' A convenient entry point for synthetic report inputs. By default this includes
#' test design, sample composition and performance. All example populations,
#' item counts, booklet arrangements and cuts are illustrative, not real study
#' results. The performance-only scope remains available explicitly.
#'
#' @inheritParams example_leistung_input
#' @param scope `"pilotierung"` includes the implemented pilot-study sections;
#'   `"pilotierung_leistung"` returns the earlier performance-only example;
#'   `"haupttest_struktur"` also includes main-test selection and module structure.
#' @return A `config` and `data` list. The pilot-study scope uses schema
#'   `0.3.0-draft` and adds `design` and `sample` to the performance input tables.
#'   The extended scope uses schema `0.4.0-draft` and also adds `main_test`.
#' @seealso [render_report()]
#' @examples
#' demo <- example_report(profile = "v3_ma_mg_mm", seed = 42)
#' summarise_leistung_input(demo)$descriptives
#' @export
example_report <- function(profile = "v3_de_lesen_zuhoeren", seed = 42L,
                           n_persons = 24L, n_pv = 15L,
                           main_year = 2027L, pilot_year = 2026L,
                           scope = c("pilotierung", "pilotierung_leistung", "haupttest_struktur"),
                           authors = NULL, affiliation = NULL) {
  scope <- match.arg(scope)
  input <- example_leistung_input(profile = profile, seed = seed,
                                  n_persons = n_persons, n_pv = n_pv,
                                  main_year = main_year, pilot_year = pilot_year,
                                  authors = authors, affiliation = affiliation)
  if (scope %in% c("pilotierung", "haupttest_struktur")) {
    input$config$scope <- scope
    input$config$schema_version <- "0.3.0-draft"
    input$data$design <- example_design_data(input$config)
    input$data$sample <- example_sample_data(input)
    if (scope == "haupttest_struktur") {
      input$config$schema_version <- "0.4.0-draft"
      input$data$main_test <- example_main_test_data(input$config)
    }
    validate_report_input(input)
  }
  input
}
