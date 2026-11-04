# Larger, wholly synthetic inputs exercise the report at study-like scale.
# These are layout/test fixtures, not a fitted assessment or copied study data.
example_realistic_input <- function(input, scope, seed) {
  if (identical(scope, "pilotierung_leistung")) return(input)
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit({
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      rm(list = ".Random.seed", envir = .GlobalEnv)
    }
  }, add = TRUE)
  set.seed(as.integer(seed))
  input$config$scope <- scope
  input$config$schema_version <- "0.3.0-draft"
  input$data$design <- example_realistic_design(input$config)
  input$data$sample <- example_realistic_sample(input)
  if (scope %in% c("haupttest_struktur", "bericht")) {
    input$config$schema_version <- "0.4.0-draft"
    input$data$main_test <- example_realistic_main_test(input$config, input$data$design)
    statistics <- example_realistic_item_results(input)
    input$data$main_test$item_levels <- statistics$levels
  }
  if (identical(scope, "bericht")) {
    input$config$schema_version <- "0.5.0-draft"
    input$data$main_test_results <- statistics$results
  }
  validate_report_input(input)
  input
}

example_realistic_design <- function(config) {
  items <- blocks <- links <- booklets <- slots <- rules <- list()
  add_block <- function(domain, suffix, module, task_sizes, norming = FALSE) {
    id <- paste0(domain, "_", suffix)
    task_ids <- paste0(id, "_T", sprintf("%02d", seq_along(task_sizes)))
    task <- rep(task_ids, times = task_sizes)
    item_ids <- paste0(task, "_I", sprintf("%02d", sequence(task_sizes)))
    items[[length(items) + 1L]] <<- data.frame(item_id = item_ids, task_id = task,
      domain_id = domain, role = if (norming) "anchor" else "pilot")
    blocks[[length(blocks) + 1L]] <<- data.frame(block_id = id,
      label = paste0(domain, "-", suffix), module = module, is_norming = norming)
    links[[length(links) + 1L]] <<- data.frame(block_id = id, item_id = item_ids)
    id
  }
  add_booklet <- function(id, design_id, block_ids, minutes, pause = FALSE) {
    booklets[[length(booklets) + 1L]] <<- data.frame(booklet_id = id, design_id = design_id)
    kinds <- rep("block", length(block_ids))
    if (pause) {
      block_ids <- append(block_ids, NA_character_, after = length(block_ids) - 1L)
      kinds <- append(kinds, "pause", after = length(kinds) - 1L)
      minutes <- append(minutes, 5, after = length(minutes) - 1L)
    }
    slots[[length(slots) + 1L]] <<- data.frame(booklet_id = id,
      position = seq_along(kinds), kind = kinds, block_id = block_ids,
      duration_minutes = minutes)
  }
  if (identical(config$report$subject, "de")) {
    for (d in seq_len(nrow(config$domains))) {
      domain <- config$domains$domain_id[d]
      ids <- vapply(seq_len(12L), function(i) {
        sizes <- if (i <= 9L) c(4L + i %% 3L, 8L - i %% 3L) else 6L
        add_block(domain, sprintf("B%02d", i), "none", sizes, norming = i > 9L)
      }, character(1))
      for (i in seq_len(14L)) {
        pair <- c((i - 1L) %% length(ids) + 1L, (i + 4L) %% length(ids) + 1L)
        add_booklet(paste0(domain, "_H", sprintf("%02d", i)), domain,
                    ids[pair], c(20, 20))
      }
      rules[[d]] <- data.frame(design_id = domain, label = config$domains$label[d],
        assignment_unit = "person",
        assignment_description = "Die Heftversionen wurden innerhalb der Klassen verteilt.")
    }
  } else {
    for (domain in config$domains$domain_id) {
      for (i in seq_len(4L)) {
        add_block(domain, sprintf("B%02d", i), "base", c(1L, 1L, 1L, 1L, 2L),
                    norming = i == 4L)
      }
      if (domain %in% config$focus_domains) {
        for (i in seq_len(6L)) {
          add_block(domain, sprintf("E%02d", i), "supplement",
                    c(rep(1L, 3L), 2L, rep(1L, 3L), 2L, rep(1L, 4L)), norming = i == 6L)
        }
      }
    }
    supplements <- unlist(lapply(config$focus_domains,
      function(id) paste0(id, "_E", sprintf("%02d", seq_len(6L)))), use.names = FALSE)
    for (i in seq_len(24L)) {
      base <- paste0(config$domains$domain_id, "_B",
                       sprintf("%02d", (i + seq_len(nrow(config$domains)) - 2L) %% 4L + 1L))
      add_booklet(paste0("MA_H", sprintf("%02d", i)), "MA",
                    c(base, supplements[(i - 1L) %% length(supplements) + 1L]),
                    c(rep(8, length(base)), 20), pause = TRUE)
    }
    rules[[1L]] <- data.frame(design_id = "MA", label = "Mathematik",
      assignment_unit = "person",
      assignment_description = "Die Heftversionen wurden innerhalb der Klassen verteilt.")
  }
  result <- lapply(list(items = items, blocks = blocks, block_items = links,
    booklets = booklets, booklet_slots = slots, design_rules = rules), function(parts) {
      result <- do.call(rbind, parts)
      rownames(result) <- NULL
      result
    })
  validate_design_data(result, config)
  result
}

# A balanced synthetic booklet assignment defines which items were presented.
# Counts therefore reflect matrix sampling rather than the whole population.
example_realistic_exposures <- function(input) {
  design <- input$data$design
  counts <- stats::setNames(integer(nrow(design$items)), design$items$item_id)
  for (id in design$design_rules$design_id) {
    booklets <- design$booklets$booklet_id[design$booklets$design_id == id]
    block_ids <- design$booklet_slots$block_id[design$booklet_slots$booklet_id %in% booklets]
    item_ids <- design$block_items$item_id[design$block_items$block_id %in% block_ids]
    domains <- unique(design$items$domain_id[design$items$item_id %in% item_ids])
    scales <- input$config$domains$scale_id[input$config$domains$domain_id %in% domains]
    ids <- unique(input$data$population$person_id[input$data$population$scale_id %in% scales])
    # Cyclic allocation is deliberate: it is reproducible and well balanced
    # even when a small n_persons is explicitly requested for a larger design.
    assigned <- rep(booklets, length.out = length(ids))
    for (booklet in booklets) {
      blocks <- design$booklet_slots$block_id[design$booklet_slots$booklet_id == booklet]
      presented <- unique(design$block_items$item_id[design$block_items$block_id %in% blocks])
      counts[presented] <- counts[presented] + sum(assigned == booklet)
    }
  }
  unname(counts)
}

example_realistic_sample <- function(input) {
  analysis_ids <- unique(input$data$population$person_id)
  extra_ids <- sprintf("demo_participation_only_%03d", seq_len(max(1L, ceiling(length(analysis_ids) * .01))))
  ids <- c(analysis_ids, extra_ids)
  n_classes <- ceiling(length(ids) / 22L)
  n_requested <- n_classes + max(1L, ceiling(n_classes * .06))
  n_states <- min(7L, n_classes)
  states <- data.frame(state_id = sprintf("demo_state_%02d", seq_len(n_states)),
    label = paste("Beispielland", LETTERS[seq_len(n_states)]))
  classes <- data.frame(class_id = sprintf("demo_class_%03d", seq_len(n_requested)),
    state_id = rep(states$state_id, length.out = n_requested),
    requested = TRUE, participated = seq_len(n_requested) <= n_classes)
  persons <- data.frame(person_id = ids,
    class_id = rep(classes$class_id[classes$participated], each = 22L, length.out = length(ids)))
  exposed <- example_realistic_exposures(input)
  response_counts <- data.frame(item_id = input$data$design$items$item_id,
    n_valid = stats::rbinom(length(exposed), size = exposed,
                            prob = stats::runif(length(exposed), .92, .995)))
  values <- function(x) data.frame(person_id = ids, value = x)
  category <- function(label, categories, probabilities) list(label = label,
    categories = categories, values = values(sample(c(categories, NA_character_),
      length(ids), replace = TRUE, prob = probabilities)))
  ages <- pmax(7.5, stats::rnorm(length(ids), 9.2, .55))
  ages[stats::runif(length(ids)) < .025] <- NA_real_
  list(states = states, classes = classes, persons = persons, response_counts = response_counts,
    response_definition = paste("Nvalid umfasst die bewertbaren Antworten der Auswertungspopulation.",
      "Die synthetische Heftzuweisung begrenzt die vorgelegten Items; nicht vorgelegte",
      "Items und nicht bewertbare Antworten werden nicht gez\u00e4hlt."),
    characteristics = list(age = list(label = "Alter (Jahre)", values = values(ages)),
      gender = category("Geschlecht", c("m\u00e4nnlich", "weiblich", "divers"), c(.489, .489, .004, .018)),
      family_language = category("Familiensprache", c("immer Deutsch",
        "Deutsch und eine andere Sprache", "meistens eine andere Sprache"), c(.64, .24, .10, .02)),
      changed_conditions = category("Ver\u00e4nderte Testbedingungen", c("ja", "nein"), c(.065, .915, .02))))
}

example_realistic_main_test <- function(config, design) {
  modules <- links <- list()
  add_module <- function(id, label, type, minutes, task_ids) {
    selected <- design$items[design$items$task_id %in% task_ids, , drop = FALSE]
    selected <- selected[order(match(selected$task_id, task_ids), selected$item_id), , drop = FALSE]
    modules[[length(modules) + 1L]] <<- data.frame(module_id = id, label = label,
      module_type = type, position = length(modules) + 1L, duration_minutes = minutes)
    links[[length(links) + 1L]] <<- data.frame(module_id = id, item_id = selected$item_id,
      task_position = match(selected$task_id, task_ids),
      item_position = as.integer(stats::ave(seq_len(nrow(selected)), selected$task_id, FUN = seq_along)))
  }
  if (identical(config$report$subject, "de")) {
    for (i in seq_len(nrow(config$domains))) {
      domain <- config$domains$domain_id[i]
      label <- config$domains$label[i]
      tasks <- unique(design$items$task_id[design$items$domain_id == domain & design$items$role == "pilot"])
      add_module(paste0(domain, "_BM"), paste(label, "Basismodul"), "base", 40, tasks[1:3])
      add_module(paste0(domain, "_EM"), paste(label, "Erg\u00e4nzungsmodul A"), "supplement", 20, tasks[c(3, 4)])
      add_module(paste0(domain, "_EM_B"), paste(label, "Erg\u00e4nzungsmodul B"), "supplement", 20, tasks[5:6])
    }
  } else {
    tasks <- unlist(lapply(config$domains$domain_id, function(domain)
      unique(design$items$task_id[startsWith(design$items$task_id, paste0(domain, "_B01"))])),
      use.names = FALSE)
    add_module("MA_BM", "Mathematik Basismodul", "base", 40, tasks)
    for (domain in config$focus_domains) {
      label <- config$domains$label[match(domain, config$domains$domain_id)]
      tasks <- lapply(1:3, function(i) unique(design$items$task_id[
        startsWith(design$items$task_id, paste0(domain, "_E", sprintf("%02d", i)))]))
      add_module(paste0(domain, "_EM"), paste(label, "Erg\u00e4nzungsmodul A"), "supplement", 20,
                   c(tasks[[1]], tasks[[2]][1:4]))
      add_module(paste0(domain, "_EM_B"), paste(label, "Erg\u00e4nzungsmodul B"), "supplement", 20,
                   c(tasks[[3]], tasks[[2]][1:4]))
    }
  }
  links <- do.call(rbind, links)
  selected <- design$items[design$items$item_id %in% links$item_id,
                            c("item_id", "task_id", "domain_id"), drop = FALSE]
  selected$task_label <- paste("Aufgabe", selected$domain_id,
    sprintf("%02d", vapply(selected$task_id, function(id) {
      domain <- selected$domain_id[match(id, selected$task_id)]
      match(id, unique(selected$task_id[selected$domain_id == domain]))
    }, integer(1))))
  # Replace one task per domain by an independently identified earlier task.
  # Most selected items still belong to the current pilot inventory.
  old_tasks <- vapply(config$domains$domain_id, function(id)
    utils::tail(unique(selected$task_id[selected$domain_id == id]), 1L), character(1))
  older <- selected$task_id %in% old_tasks
  old_ids <- selected$item_id[older]
  selected$item_id[older] <- paste0(selected$item_id[older], "_previous")
  selected$task_id[older] <- paste0(selected$task_id[older], "_previous")
  replacement <- match(links$item_id, old_ids)
  links$item_id[!is.na(replacement)] <- selected$item_id[older][replacement[!is.na(replacement)]]
  waves <- data.frame(wave_id = c("demo_previous", "demo_current"),
    pilot_year = c(max(1L, config$report$pilot_year - 2L), config$report$pilot_year),
    label = c("Fr\u00fchere Pilotierungswelle", "Aktuelle Pilotierungswelle"))
  item_waves <- data.frame(item_id = selected$item_id,
    wave_id = ifelse(older, "demo_previous", "demo_current"))
  item_waves <- rbind(item_waves, data.frame(item_id = selected$item_id[which(!older)[1L]],
    wave_id = "demo_previous"))
  result <- list(items = selected[, c("item_id", "task_id", "task_label", "domain_id")],
    modules = do.call(rbind, modules), module_items = links, waves = waves, item_waves = item_waves)
  result <- lapply(result, function(x) { rownames(x) <- NULL; x })
  validate_main_test_data(result, config)
  result
}

example_realistic_item_results <- function(input) {
  config <- input$config
  main <- input$data$main_test
  items <- main$items
  tasks <- unique(items$task_id)
  task_means <- stats::rnorm(length(tasks), -.45, .7)
  names(task_means) <- tasks
  for (task in tasks) {
    ids <- items$item_id[items$task_id == task]
    modules <- main$module_items$module_id[main$module_items$item_id %in% ids]
    if (all(endsWith(modules, "_EM_B"))) task_means[task] <- stats::rnorm(1L, .65, .4)
    else if (all(endsWith(modules, "_EM"))) task_means[task] <- stats::rnorm(1L, -1.2, .4)
  }
  logits <- task_means[items$task_id] + stats::rnorm(nrow(items), sd = .45)
  scale_ids <- config$domains$scale_id[match(items$domain_id, config$domains$domain_id)]
  p_correct <- numeric(nrow(items))
  levels <- character(nrow(items))
  score <- 500 + 100 * (logits + stats::qlogis(.625))
  for (id in unique(scale_ids)) {
    index <- which(scale_ids == id)
    # Simulate a marginal success proportion from the example abilities. This
    # does not fit a response model or estimate parameters from actual data.
    pv <- input$data$pvs[input$data$pvs$scale_id == id &
                          input$data$pvs$pv_id == config$scales[[id]]$pv_ids[1L], ]
    abilities <- (pv$value - 500) / 100
    p_correct[index] <- vapply(logits[index], function(b) mean(stats::plogis(abilities - b)), numeric(1))
    levels[index] <- config$scales[[id]]$level_labels[
      findInterval(score[index], config$scales[[id]]$cuts) + 1L]
  }
  result <- example_main_test_results(config, main)
  result$item_statistics <- data.frame(item_id = items$item_id,
    p_correct = unname(p_correct), logit = unname(logits))
  result$definitions$p_correct <- paste("Synthetischer marginaler Anteil korrekter Antworten,",
    "berechnet aus simulierten F\u00e4higkeiten und Itemschwierigkeiten; keine empirische Modellsch\u00e4tzung.")
  list(results = result, levels = data.frame(item_id = items$item_id, level_label = levels))
}
