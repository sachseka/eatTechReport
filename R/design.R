# The design describes the current pilot wave. Item roles are current roles,
# not a claim that pilot items are newly developed or anchors are older items.
validate_design_data <- function(design, config) {
  fail <- function(message) stop(message, call. = FALSE)
  tables <- list(
    items = c("item_id", "task_id", "domain_id", "role"),
    blocks = c("block_id", "label", "module"),
    block_items = c("block_id", "item_id"),
    booklets = c("booklet_id", "design_id"),
    booklet_slots = c("booklet_id", "position", "kind", "block_id", "duration_minutes"),
    design_rules = c("design_id", "label", "assignment_unit", "assignment_description")
  )
  if (!is.list(design) || is.data.frame(design) ||
      is.null(names(design)) || anyDuplicated(names(design)) ||
      !setequal(names(design), names(tables))) {
    fail(paste0("data$design erwartet genau: ", paste(names(tables), collapse = ", "), "."))
  }
  for (name in names(tables)) {
    value <- design[[name]]
    if (!is.data.frame(value) || !nrow(value) || anyDuplicated(names(value)) ||
        !setequal(names(value), tables[[name]])) {
      fail(paste0("data$design$", name, " muss eine nichtleere Tabelle mit genau ",
                  paste(tables[[name]], collapse = ", "), " sein."))
    }
    if (any(vapply(value, function(column) {
      !is.atomic(column) || !is.null(dim(column)) || length(column) != nrow(value)
    }, logical(1)))) {
      fail(paste0("data$design$", name, " braucht eindimensionale Spalten mit einem Wert je Zeile."))
    }
  }
  strings <- function(value, label, unique = FALSE) {
    if (!is.character(value) || !is.null(dim(value)) ||
        anyNA(value) || any(!nzchar(trimws(value))) ||
        any(grepl("[[:cntrl:]]", value)) || (unique && anyDuplicated(value))) {
      fail(paste0(label, " braucht nichtleere Zeichenketten ohne Fehlwerte",
                  if (unique) " und ohne Duplikate" else "", "."))
    }
  }
  key <- function(...) paste(..., sep = "\r")
  choices <- function(value, allowed, label) {
    strings(value, label)
    if (any(!value %in% allowed)) {
      fail(paste0(label, " erlaubt nur: ", paste(allowed, collapse = ", "), "."))
    }
  }
  foreign <- function(value, allowed, label) {
    if (any(!value %in% allowed)) fail(paste0(label, " enthaelt unbekannte IDs."))
  }
  complete <- function(actual, expected, label) {
    if (!setequal(actual, expected)) fail(paste0(label, ": Jede definierte ID muss verwendet werden."))
  }
  if (!is.list(config) || !is.data.frame(config$domains) ||
      !all(c("domain_id", "label") %in% names(config$domains))) {
    fail("config$domains muss domain_id und label enthalten.")
  }
  strings(config$domains$domain_id, "config$domains$domain_id", TRUE)
  strings(config$domains$label, "config$domains$label")

  items <- design$items
  blocks <- design$blocks
  links <- design$block_items
  booklets <- design$booklets
  slots <- design$booklet_slots
  rules <- design$design_rules
  strings(items$item_id, "design$items$item_id", TRUE)
  strings(items$task_id, "design$items$task_id")
  strings(items$domain_id, "design$items$domain_id")
  foreign(items$domain_id, config$domains$domain_id, "design$items$domain_id")
  choices(items$role, c("pilot", "anchor"), "design$items$role")
  strings(blocks$block_id, "design$blocks$block_id", TRUE)
  strings(blocks$label, "design$blocks$label")
  choices(blocks$module, c("none", "base", "supplement"), "design$blocks$module")
  strings(links$block_id, "design$block_items$block_id")
  strings(links$item_id, "design$block_items$item_id")
  if (anyDuplicated(key(links$block_id, links$item_id))) {
    fail("design$block_items enthaelt doppelte Block-Item-Zuordnungen.")
  }
  foreign(links$block_id, blocks$block_id, "design$block_items$block_id")
  foreign(links$item_id, items$item_id, "design$block_items$item_id")
  complete(links$block_id, blocks$block_id, "design$block_items$block_id")
  complete(links$item_id, items$item_id, "design$block_items$item_id")
  strings(rules$design_id, "design$design_rules$design_id", TRUE)
  strings(rules$label, "design$design_rules$label")
  choices(rules$assignment_unit, c("person", "class", "school"),
          "design$design_rules$assignment_unit")
  strings(rules$assignment_description, "design$design_rules$assignment_description")
  strings(booklets$booklet_id, "design$booklets$booklet_id", TRUE)
  strings(booklets$design_id, "design$booklets$design_id")
  foreign(booklets$design_id, rules$design_id, "design$booklets$design_id")
  complete(booklets$design_id, rules$design_id, "design$booklets$design_id")
  strings(slots$booklet_id, "design$booklet_slots$booklet_id")
  foreign(slots$booklet_id, booklets$booklet_id, "design$booklet_slots$booklet_id")
  complete(slots$booklet_id, booklets$booklet_id, "design$booklet_slots$booklet_id")
  if (!is.numeric(slots$position) || any(!is.finite(slots$position)) ||
      any(slots$position < 1 | slots$position > .Machine$integer.max |
            slots$position != floor(slots$position))) {
    fail("design$booklet_slots$position braucht positive ganze Zahlen.")
  }
  if (anyDuplicated(key(slots$booklet_id, slots$position))) {
    fail("design$booklet_slots enthaelt doppelte Heft-Positionen.")
  }
  choices(slots$kind, c("block", "pause", "instruction"), "design$booklet_slots$kind")
  if (!is.numeric(slots$duration_minutes) || any(!is.finite(slots$duration_minutes)) ||
      any(slots$duration_minutes < 0)) {
    fail("design$booklet_slots$duration_minutes braucht endliche, nichtnegative Minuten.")
  }
  is_block <- slots$kind == "block"
  if (!is.character(slots$block_id) ||
      any(!is.na(slots$block_id[!is_block]))) {
    fail("design$booklet_slots$block_id muss bei Pausen und Instruktionen NA_character_ sein.")
  }
  strings(slots$block_id[is_block], "design$booklet_slots$block_id")
  foreign(slots$block_id[is_block], blocks$block_id, "design$booklet_slots$block_id")
  complete(slots$block_id[is_block], blocks$block_id, "design$booklet_slots$block_id")
  if (!setequal(slots$booklet_id[is_block], booklets$booklet_id)) {
    fail("Jedes Testheft muss mindestens einen Block enthalten.")
  }
  invisible(TRUE)
}

summarise_design_data <- function(design, config) {
  validate_design_data(design, config)
  items <- design$items
  blocks <- design$blocks
  links <- design$block_items
  booklets <- design$booklets
  slots <- design$booklet_slots
  pool <- do.call(rbind, lapply(seq_len(nrow(config$domains)), function(i) {
    do.call(rbind, lapply(c("pilot", "anchor"), function(role) {
      selected <- items[items$domain_id == config$domains$domain_id[i] &
                          items$role == role, , drop = FALSE]
      data.frame(domain_id = config$domains$domain_id[i],
                 domain_label = config$domains$label[i], role = role,
                 n_tasks = length(unique(selected$task_id)), n_items = nrow(selected),
                 stringsAsFactors = FALSE)
    }))
  }))
  block_summary <- do.call(rbind, lapply(seq_len(nrow(blocks)), function(i) {
    selected <- items[items$item_id %in% links$item_id[links$block_id == blocks$block_id[i]], ,
                      drop = FALSE]
    data.frame(block_id = blocks$block_id[i], label = blocks$label[i], module = blocks$module[i],
               n_tasks = length(unique(selected$task_id)), n_items = nrow(selected),
               n_pilot = sum(selected$role == "pilot"), n_anchor = sum(selected$role == "anchor"),
               domain_ids = paste(config$domains$domain_id[
                 config$domains$domain_id %in% selected$domain_id], collapse = ", "),
               stringsAsFactors = FALSE)
  }))
  slots <- slots[order(match(slots$booklet_id, booklets$booklet_id), slots$position), ,
                 drop = FALSE]
  slots$design_id <- booklets$design_id[match(slots$booklet_id, booklets$booklet_id)]
  index <- match(slots$block_id, block_summary$block_id)
  slots$block_label <- block_summary$label[index]
  slots$block_label[slots$kind == "pause"] <- "Pause"
  slots$block_label[slots$kind == "instruction"] <- "Instruktion"
  slots$module <- block_summary$module[index]
  slots$n_items <- ifelse(slots$kind == "block", block_summary$n_items[index], 0L)
  slots$n_anchor <- ifelse(slots$kind == "block", block_summary$n_anchor[index], 0L)
  booklet_summary <- do.call(rbind, lapply(seq_len(nrow(booklets)), function(i) {
    selected <- slots[slots$booklet_id == booklets$booklet_id[i], , drop = FALSE]
    selected_items <- items[items$item_id %in% links$item_id[
      links$block_id %in% selected$block_id[selected$kind == "block"]], , drop = FALSE]
    data.frame(booklet_id = booklets$booklet_id[i], design_id = booklets$design_id[i],
               n_blocks = sum(selected$kind == "block"),
               test_minutes = sum(selected$duration_minutes[selected$kind == "block"]),
               total_minutes = sum(selected$duration_minutes),
               n_tasks = length(unique(selected_items$task_id)), n_items = nrow(selected_items),
               stringsAsFactors = FALSE)
  }))
  rownames(pool) <- rownames(block_summary) <- rownames(slots) <- rownames(booklet_summary) <- NULL
  list(pool = pool,
       totals = data.frame(n_tasks = length(unique(items$task_id)), n_items = nrow(items),
                           n_blocks = nrow(blocks), n_booklets = nrow(booklets)),
       blocks = block_summary, booklets = booklet_summary, slots = slots,
       design_rules = design$design_rules)
}

# Deliberately illustrative designs: the domain configuration does not imply
# that real assessments use these times, block counts or assignment procedures.
example_design_data <- function(config) {
  items <- blocks <- links <- booklets <- slots <- rules <- list()
  add_items <- function(domain, supplement = FALSE) {
    pilot_ids <- paste0(domain, "_P", sprintf("%02d", seq_len(if (supplement) 4L else 2L)))
    anchor_ids <- paste0(domain, "_A", sprintf("%02d", seq_len(2L)))
    data.frame(item_id = c(pilot_ids, anchor_ids),
               task_id = c(paste0(domain, "_T", rep(seq_len(length(pilot_ids) / 2L), each = 2L)),
                           rep(paste0(domain, "_TA"), 2L)),
               domain_id = domain, role = c(rep("pilot", length(pilot_ids)), rep("anchor", 2L)),
               stringsAsFactors = FALSE)
  }
  add_block <- function(id, label, module, item_ids) {
    blocks[[length(blocks) + 1L]] <<- data.frame(block_id = id, label = label, module = module,
                                                stringsAsFactors = FALSE)
    links[[length(links) + 1L]] <<- data.frame(block_id = id, item_id = item_ids,
                                               stringsAsFactors = FALSE)
  }
  add_slots <- function(booklet, kind, ids, minutes) {
    slots[[length(slots) + 1L]] <<- data.frame(
      booklet_id = booklet, position = seq_along(kind), kind = kind,
      block_id = ids, duration_minutes = minutes, stringsAsFactors = FALSE)
  }
  if (identical(config$report$subject, "de")) {
    for (i in seq_len(nrow(config$domains))) {
      domain <- config$domains$domain_id[i]
      items[[i]] <- add_items(domain, supplement = TRUE)
      ids <- paste0(domain, c("_B1", "_B2", "_A"))
      add_block(ids[1], paste(domain, "1"), "none", paste0(domain, c("_P01", "_P02", "_A01")))
      add_block(ids[2], paste(domain, "2"), "none", paste0(domain, c("_P03", "_P04", "_A02")))
      add_block(ids[3], paste(domain, "Anker"), "none", paste0(domain, c("_A01", "_A02")))
      booklet_ids <- paste0(domain, c("_H1", "_H2"))
      booklets[[i]] <- data.frame(booklet_id = booklet_ids, design_id = domain,
                                  stringsAsFactors = FALSE)
      add_slots(booklet_ids[1], c("instruction", "block", "pause", "block"),
                c(NA_character_, ids[1], NA_character_, ids[2]), c(2, 12, 5, 15))
      add_slots(booklet_ids[2], c("block", "block"), c(ids[2], ids[3]), c(15, 6))
      rules[[i]] <- data.frame(
        design_id = domain, label = config$domains$label[i],
        assignment_unit = if (i %% 2L) "person" else "class",
        assignment_description = if (i %% 2L)
          "Im synthetischen Beispiel werden die Heftversionen innerhalb der Klassen verteilt."
        else "Im synthetischen Beispiel erhaelt jede Klasse eine gemeinsame Heftversion.",
        stringsAsFactors = FALSE)
    }
  } else if (identical(config$report$subject, "ma")) {
    for (i in seq_len(nrow(config$domains))) {
      domain <- config$domains$domain_id[i]
      focus <- domain %in% config$focus_domains
      items[[i]] <- add_items(domain, supplement = focus)
      add_block(paste0(domain, "_B"), paste(domain, "Basis"), "base",
                paste0(domain, c("_P01", "_P02", "_A01", "_A02")))
      if (focus) {
        add_block(paste0(domain, "_E"), paste(domain, "Erg\u00e4nzung"), "supplement",
                  paste0(domain, c("_P03", "_P04", "_A01")))
      }
    }
    base_ids <- paste0(config$domains$domain_id, "_B")
    for (i in seq_along(config$focus_domains)) {
      booklet <- paste0("MA_H", i)
      booklets[[i]] <- data.frame(booklet_id = booklet, design_id = "MA",
                                  stringsAsFactors = FALSE)
      kinds <- c(rep("block", length(base_ids)), "pause", "block")
      ids <- c(if (i %% 2L) base_ids else rev(base_ids), NA_character_,
               paste0(config$focus_domains[i], "_E"))
      minutes <- c(rep(5, length(base_ids)), 5, 15 + 5 * (i - 1L))
      if (i %% 2L == 0L) {
        kinds <- c("instruction", kinds)
        ids <- c(NA_character_, ids)
        minutes <- c(2, minutes)
      }
      add_slots(booklet, kinds, ids, minutes)
    }
    rules[[1L]] <- data.frame(
      design_id = "MA", label = "Mathematik", assignment_unit = "class",
      assignment_description = "Im synthetischen Beispiel erhaelt jede Klasse eine gemeinsame Heftversion.",
      stringsAsFactors = FALSE)
  } else stop("Beispieldesign unterstuetzt subject = 'de' oder 'ma'.", call. = FALSE)
  out <- lapply(list(items = items, blocks = blocks, block_items = links,
                    booklets = booklets, booklet_slots = slots, design_rules = rules),
                function(parts) {
                  value <- do.call(rbind, parts)
                  rownames(value) <- NULL
                  value
                })
  validate_design_data(out, config)
  out
}
