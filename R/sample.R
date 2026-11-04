# Internal input helpers for the pilot-study sample. Population membership is
# supplied by the upstream analysis; these helpers never remove persons or PVs.

example_sample_data <- function(input) {
  analysis_ids <- unique(input$data$population$person_id)
  extra_ids <- c("demo_participation_only_01", "demo_participation_only_02")
  if (any(extra_ids %in% analysis_ids)) {
    stop("Die synthetischen Zusatz-IDs sind bereits in der Population vorhanden.", call. = FALSE)
  }
  person_ids <- c(analysis_ids, extra_ids)
  class_ids <- rep(c("demo_class_01", "demo_class_02", "demo_class_03"),
                   length.out = length(person_ids))
  states <- data.frame(state_id = c("demo_a", "demo_b", "demo_c"),
                       label = c("Beispielland A", "Beispielland B", "Beispielland C"),
                       stringsAsFactors = FALSE)
  classes <- data.frame(
    class_id = c("demo_class_01", "demo_class_02", "demo_class_03", "demo_class_04"),
    state_id = c("demo_a", "demo_a", "demo_b", "demo_c"),
    requested = c(TRUE, TRUE, FALSE, TRUE),
    participated = c(TRUE, TRUE, TRUE, FALSE), stringsAsFactors = FALSE
  )
  persons <- data.frame(person_id = person_ids, class_id = class_ids,
                        stringsAsFactors = FALSE)
  items <- input$data$design$items
  scale_ids <- input$config$domains$scale_id[
    match(items$domain_id, input$config$domains$domain_id)]
  eligible <- vapply(scale_ids, function(scale_id) {
    length(unique(input$data$population$person_id[input$data$population$scale_id == scale_id]))
  }, integer(1))
  response_counts <- data.frame(
    item_id = items$item_id,
    n_valid = pmax(0, eligible - ((seq_len(nrow(items)) - 1L) %% 4L)),
    stringsAsFactors = FALSE
  )
  values <- function(value) data.frame(person_id = person_ids, value = value,
                                      stringsAsFactors = FALSE)
  ages <- 8 + (seq_along(person_ids) %% 7L) / 10
  ages[seq_along(ages) %% 7L == 0L] <- NA_real_
  categorical <- function(label, categories) {
    list(label = label, categories = categories,
         values = values(rep(c(categories, NA_character_), length.out = length(person_ids))))
  }
  list(
    states = states, classes = classes, persons = persons,
    response_counts = response_counts,
    response_definition = paste(
      "Im synthetischen Beispiel bezeichnet Nvalid die Anzahl eindeutig",
      "zugeordneter, bewertbarer Antworten aus der Auswertungspopulation",
      "der jeweiligen Skala. Nicht vorgelegte Items und ausgelassene oder",
      "sonstige nicht bewertbare Antworten werden in diesem Beispiel nicht mitgez\u00e4hlt."
    ),
    characteristics = list(
      age = list(label = "Alter (Jahre)", values = values(ages)),
      gender = categorical("Geschlecht", c("m\u00e4nnlich", "weiblich", "divers")),
      family_language = categorical("Familiensprache", c("immer Deutsch",
        "Deutsch und eine andere Sprache", "meistens eine andere Sprache")),
      changed_conditions = categorical("Ver\u00e4nderte Testbedingungen", c("ja", "nein"))
    )
  )
}

validate_sample_data <- function(sample, input) {
  fail <- function(message) stop(message, call. = FALSE)
  fields <- c("states", "classes", "persons", "response_counts",
              "response_definition", "characteristics")
  if (!is.list(sample) || is.data.frame(sample) || is.null(names(sample)) ||
      anyDuplicated(names(sample)) || !setequal(names(sample), fields)) {
    fail(paste0("data$sample erwartet genau: ", paste(fields, collapse = ", "), "."))
  }
  table <- function(x, expected, label, allow_empty = FALSE) {
    if (!is.data.frame(x) || anyDuplicated(names(x)) || !setequal(names(x), expected) ||
        (!allow_empty && nrow(x) == 0L)) {
      fail(paste0(label, " erwartet eine Tabelle mit: ", paste(expected, collapse = ", "), "."))
    }
    if (any(vapply(x, function(column) !is.null(dim(column)) || length(column) != nrow(x),
                   logical(1)))) {
      fail(paste0(label, " braucht je Spalte genau einen einfachen Wert pro Zeile; Matrixspalten sind unzulaessig."))
    }
  }
  strings <- function(x, label, unique = FALSE) {
    if (!is.character(x) || anyNA(x) || any(!nzchar(trimws(x))) ||
        any(grepl("[[:cntrl:]]", x)) || (unique && anyDuplicated(x))) {
      fail(paste0(label, " braucht nichtleere Zeichenketten ohne Fehlwerte",
                  if (unique) " oder Duplikate" else "", "."))
    }
  }
  table(sample$states, c("state_id", "label"), "sample$states")
  strings(sample$states$state_id, "states$state_id", TRUE)
  strings(sample$states$label, "states$label")
  table(sample$classes, c("class_id", "state_id", "requested", "participated"),
        "sample$classes")
  strings(sample$classes$class_id, "classes$class_id", TRUE)
  strings(sample$classes$state_id, "classes$state_id")
  if (any(!sample$classes$state_id %in% sample$states$state_id)) {
    fail("classes$state_id enthaelt nicht in states deklarierte Laender.")
  }
  for (field in c("requested", "participated")) {
    x <- sample$classes[[field]]
    if (!is.logical(x) || !is.null(dim(x)) || anyNA(x)) {
      fail(paste0("classes$", field, " muss vollstaendig TRUE oder FALSE sein."))
    }
  }
  table(sample$persons, c("person_id", "class_id"), "sample$persons")
  strings(sample$persons$person_id, "persons$person_id", TRUE)
  strings(sample$persons$class_id, "persons$class_id")
  if (any(!sample$persons$class_id %in% sample$classes$class_id)) {
    fail("persons$class_id enthaelt nicht in classes deklarierte Klassen.")
  }
  person_classes <- match(sample$persons$class_id, sample$classes$class_id)
  if (any(!sample$classes$participated[person_classes])) {
    fail("Teilnehmende Personen duerfen nur teilnehmenden Klassen zugeordnet sein.")
  }
  if (any(!input$data$population$person_id %in% sample$persons$person_id)) {
    fail("Die Auswertungspopulation enthaelt Personen ohne dokumentierte Teilnahme.")
  }
  table(sample$response_counts, c("item_id", "n_valid"), "sample$response_counts")
  strings(sample$response_counts$item_id, "response_counts$item_id", TRUE)
  if (!setequal(sample$response_counts$item_id, input$data$design$items$item_id)) {
    fail("response_counts muss jedes Inventaritem genau einmal enthalten.")
  }
  counts <- sample$response_counts$n_valid
  if (!is.numeric(counts) || !is.null(dim(counts)) || any(!is.finite(counts)) ||
      any(counts < 0 | counts != floor(counts))) {
    fail("response_counts$n_valid braucht vollstaendige nichtnegative ganze Zahlen.")
  }
  items <- input$data$design$items[match(sample$response_counts$item_id,
                                      input$data$design$items$item_id), , drop = FALSE]
  scale_ids <- input$config$domains$scale_id[
    match(items$domain_id, input$config$domains$domain_id)]
  eligible <- vapply(scale_ids, function(scale_id) {
    length(unique(input$data$population$person_id[input$data$population$scale_id == scale_id]))
  }, integer(1))
  if (any(counts > eligible)) {
    fail("Nvalid darf die Anzahl der Auswertungspersonen der zugehoerigen Skala nicht uebersteigen.")
  }
  strings(sample$response_definition, "sample$response_definition")
  if (length(sample$response_definition) != 1L) {
    fail("sample$response_definition muss genau einen Text zur Bezugsmenge und Fehlwertregel enthalten.")
  }
  characteristics <- sample$characteristics
  characteristic_ids <- c("age", "gender", "family_language", "changed_conditions")
  if (!is.list(characteristics) || is.data.frame(characteristics) ||
      anyDuplicated(names(characteristics)) ||
      !setequal(names(characteristics), characteristic_ids)) {
    fail("sample$characteristics braucht age, gender, family_language und changed_conditions; NULL bedeutet nicht erhoben.")
  }
  analysis_ids <- unique(input$data$population$person_id)
  for (id in characteristic_ids) {
    variable <- characteristics[[id]]
    if (is.null(variable)) next
    label <- paste0("characteristics$", id)
    expected <- if (id == "age") c("label", "values") else c("label", "categories", "values")
    if (!is.list(variable) || is.data.frame(variable) || anyDuplicated(names(variable)) ||
        !setequal(names(variable), expected)) {
      fail(paste0(label, " erwartet genau: ", paste(expected, collapse = ", "), "."))
    }
    strings(variable$label, paste0(label, "$label"))
    if (length(variable$label) != 1L) fail(paste0(label, "$label muss genau eine Bezeichnung sein."))
    table(variable$values, c("person_id", "value"), paste0(label, "$values"))
    strings(variable$values$person_id, paste0(label, "$values$person_id"), TRUE)
    if (any(!analysis_ids %in% variable$values$person_id) ||
        any(!variable$values$person_id %in% sample$persons$person_id)) {
      fail(paste0(label, "$values muss alle Auswertungspersonen und nur dokumentierte Teilnehmende enthalten; Fehlwerte als NA liefern."))
    }
    value <- variable$values$value
    if (!is.null(dim(value))) fail(paste0(label, "$value braucht genau einen Wert je Person."))
    if (id == "age") {
      if (!is.numeric(value) || any(is.nan(value)) ||
          any(!is.na(value) & (!is.finite(value) | value <= 0))) {
        fail("characteristics$age$value braucht positive Altersangaben in Jahren oder NA.")
      }
    } else {
      strings(variable$categories, paste0(label, "$categories"), TRUE)
      if (length(variable$categories) == 0L || "keine Angabe" %in% variable$categories) {
        fail(paste0(label, "$categories braucht mindestens eine Kategorie; 'keine Angabe' wird aus NA erzeugt."))
      }
      if (id == "gender" && !identical(variable$categories, c("m\u00e4nnlich", "weiblich", "divers"))) {
        fail("Geschlechtskategorien muessen in dieser Reihenfolge m\u00e4nnlich, weiblich und divers heissen; NA ergibt keine Angabe.")
      }
      if (!is.character(value) || any(!is.na(value) & !value %in% variable$categories)) {
        fail(paste0(label, "$value braucht ausschliesslich deklarierte Kategorien oder NA; Codes werden nicht automatisch umgedeutet."))
      }
    }
  }
  invisible(TRUE)
}

summarise_sample_data <- function(sample, input) {
  validate_sample_data(sample, input)
  classes <- sample$classes
  persons <- sample$persons
  persons$state_id <- classes$state_id[match(persons$class_id, classes$class_id)]
  analysis_ids <- unique(input$data$population$person_id)
  persons$analysed <- persons$person_id %in% analysis_ids
  counts <- function(state_id = NULL) {
    cs <- if (is.null(state_id)) classes else classes[classes$state_id == state_id, , drop = FALSE]
    ps <- if (is.null(state_id)) persons else persons[persons$state_id == state_id, , drop = FALSE]
    data.frame(n_requested_classes = sum(cs$requested),
               n_participating_classes = sum(cs$participated),
               n_participants = nrow(ps), n_analysis_persons = sum(ps$analysed),
               n_not_analysed = sum(!ps$analysed))
  }
  totals <- counts()
  by_state <- cbind(sample$states,
                    do.call(rbind, lapply(sample$states$state_id, counts)))
  by_state$participant_percent <- 100 * by_state$n_participants / totals$n_participants
  by_state$analysis_percent <- 100 * by_state$n_analysis_persons / totals$n_analysis_persons
  rownames(by_state) <- NULL
  by_scale <- data.frame(
    scale_id = names(input$config$scales),
    n_analysis_persons = vapply(names(input$config$scales), function(scale_id) {
      length(unique(input$data$population$person_id[input$data$population$scale_id == scale_id]))
    }, integer(1)), stringsAsFactors = FALSE, row.names = NULL
  )
  items <- input$data$design$items
  responses <- items[, c("item_id", "domain_id", "role"), drop = FALSE]
  responses$n_valid <- sample$response_counts$n_valid[
    match(responses$item_id, sample$response_counts$item_id)]
  scale_ids <- input$config$domains$scale_id[
    match(responses$domain_id, input$config$domains$domain_id)]
  responses$n_eligible <- by_scale$n_analysis_persons[match(scale_ids, by_scale$scale_id)]
  response_row <- function(x) {
    data.frame(n_items = nrow(x), min = min(x$n_valid),
               median = stats::median(x$n_valid), max = max(x$n_valid))
  }
  groups <- unique(responses[, c("domain_id", "role"), drop = FALSE])
  responses_by_domain <- do.call(rbind, lapply(seq_len(nrow(groups)), function(i) {
    group <- groups[i, , drop = FALSE]
    rows <- responses$domain_id == group$domain_id & responses$role == group$role
    cbind(group, response_row(responses[rows, , drop = FALSE]))
  }))
  roles <- unique(responses$role)
  responses_overall <- do.call(rbind, lapply(roles, function(role) {
    cbind(data.frame(role = role, stringsAsFactors = FALSE),
          response_row(responses[responses$role == role, , drop = FALSE]))
  }))
  rownames(responses_by_domain) <- rownames(responses_overall) <- NULL
  list(totals = totals, by_state = by_state, by_scale = by_scale,
       response_counts = responses, responses_by_domain = responses_by_domain,
       responses_overall = responses_overall,
       response_definition = sample$response_definition,
       characteristics = summarise_sample_characteristics(sample$characteristics,
                                                           persons[persons$analysed, , drop = FALSE],
                                                           sample$states))
}

summarise_sample_characteristics <- function(characteristics, analysis_persons, states) {
  ids <- analysis_persons$person_id
  result <- stats::setNames(vector("list", length(characteristics)), names(characteristics))
  age <- characteristics$age
  if (!is.null(age)) {
    values <- age$values$value[match(ids, age$values$person_id)]
    valid <- values[!is.na(values)]
    result$age <- data.frame(label = age$label, n = length(values),
                             n_valid = length(valid), n_missing = sum(is.na(values)),
                             mean = if (length(valid)) mean(valid) else NA_real_,
                             sd = if (length(valid) >= 2L) stats::sd(valid) else NA_real_,
                             stringsAsFactors = FALSE)
  }
  category_rows <- function(variable, person_ids) {
    value <- variable$values$value[match(person_ids, variable$values$person_id)]
    categories <- c(variable$categories, "keine Angabe")
    count <- c(vapply(variable$categories, function(category) sum(value == category, na.rm = TRUE),
                      integer(1)), sum(is.na(value)))
    data.frame(label = variable$label, category = categories, n = unname(count),
               denominator = length(person_ids),
               percent = if (length(person_ids)) 100 * unname(count) / length(person_ids) else NA_real_,
               stringsAsFactors = FALSE)
  }
  for (id in c("gender", "family_language", "changed_conditions")) {
    if (!is.null(characteristics[[id]])) {
      result[[id]] <- category_rows(characteristics[[id]], ids)
    }
  }
  result["family_language_by_state"] <- list(NULL)
  if (!is.null(characteristics$family_language)) {
    result$family_language_by_state <- do.call(rbind, lapply(seq_len(nrow(states)), function(i) {
      state <- states[i, , drop = FALSE]
      rows <- analysis_persons$state_id == state$state_id
      data.frame(state_id = state$state_id, state_label = state$label,
                  category_rows(characteristics$family_language, analysis_persons$person_id[rows]),
                  stringsAsFactors = FALSE)
    }))
    rownames(result$family_language_by_state) <- NULL
  }
  result
}
