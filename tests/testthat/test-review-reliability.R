review_reliability_fixture <- function() {
  data.frame(scale_id = c("DH", "DL"), agreement_percent = c(91.3, 89.0),
    cohen_kappa = c(.76, .88), reliability_description = c("eine gute Reliabilität", "eine hohe Reliabilität"),
    stringsAsFactors = FALSE)
}

test_that("coding reliability tables permit partial coverage but reject ambiguous scales", {
  config <- example_leistung_input()$config
  table <- review_reliability_fixture()
  expect_true(validate_editorial_reliability(NULL, config))
  expect_true(validate_editorial_reliability(table, config))
  expect_true(validate_editorial_reliability(table[1L, ], config))
  expect_true(validate_editorial_reliability(table[, rev(names(table))], config))
  expect_error(validate_editorial_reliability(rbind(table, table[1L, ]), config), "nur einmal")
  unknown <- table
  unknown$scale_id[1L] <- "unbekannt"
  expect_true(validate_editorial_reliability(unknown))
  expect_error(validate_editorial_reliability(unknown, config), "nicht konfigurierte Skala")
  for (bad in list(list(), as.matrix(table), table[FALSE, ], table[-1L],
                   cbind(table, extra = TRUE))) {
    expect_error(validate_editorial_reliability(bad), "genau den Spalten")
  }
  names(table)[2L] <- "scale_id"
  expect_error(validate_editorial_reliability(table), "genau den Spalten")
})

test_that("editorial constructor and report validation preserve supplied reliability summaries", {
  input <- example_report(n_persons = 4L, n_pv = 1L)
  before <- summarise_report_input(input)
  table <- review_reliability_fixture()
  input$config$editorial <- report_editorial(reliability_by_scale = table)
  expect_identical(input$config$editorial$reliability_by_scale, table)
  expect_true(validate_report_input(input))
  expect_identical(summarise_report_input(input), before)
  expect_error(report_editorial_value(input$config, "reliability_by_scale"), "Tabellarische Kennwerte")
  input$config$editorial$reliability_by_scale$scale_id[1L] <- "MO"
  expect_error(validate_report_input(input), "nicht konfigurierte Skala")
})

test_that("coding reliability inputs reject nonfinite values, wrong units and malformed columns", {
  original <- review_reliability_fixture()
  for (field in c("scale_id", "reliability_description")) {
    for (bad in list(c(NA, "x"), c(" ", "x"), c("x\ny", "x"), c(1, 2), factor(c("x", "y")))) {
      table <- original
      table[[field]] <- bad
      expect_error(validate_editorial_reliability(table), "Zeichenketten")
    }
  }
  for (field in c("agreement_percent", "cohen_kappa")) {
    for (bad in list(c(NA_real_, 0), c(Inf, 0), c(NaN, 0), c("0", "1"), c(1+0i, 0+0i), list(1, 0))) {
      table <- original
      table[[field]] <- bad
      expect_error(validate_editorial_reliability(table), "endliche Zahlen")
    }
    table <- original
    table[[field]] <- matrix(c(0, 1), ncol = 1L)
    expect_error(validate_editorial_reliability(table), "Matrixspalten")
  }
  for (bad in c(-.1, 100.1)) {
    table <- original
    table$agreement_percent[1L] <- bad
    expect_error(validate_editorial_reliability(table), "von 0 bis 100")
  }
  for (bad in c(-1.1, 1.1)) {
    table <- original
    table$cohen_kappa[1L] <- bad
    expect_error(validate_editorial_reliability(table), "von -1 bis 1")
  }
  original$agreement_percent <- c(0, 100)
  original$cohen_kappa <- c(-1, 1)
  expect_true(validate_editorial_reliability(original))
})

test_that("German coding reliability preserves scale order and separate results", {
  config <- example_leistung_input()$config
  config$report$data_origin <- "observed"
  config$editorial <- list(reliability_by_scale = review_reliability_fixture())
  text <- report_coding_reliability_text(config)
  paragraphs <- strsplit(text, "\n\n", fixed = TRUE)[[1L]]
  expect_length(paragraphs, 2L)
  expect_match(paragraphs[1L], "Kompetenzbereich „Lesen“", fixed = TRUE)
  expect_match(paragraphs[1L], "eine hohe Reliabilität", fixed = TRUE)
  expect_match(paragraphs[1L], "*Median* = 89,0 %", fixed = TRUE)
  expect_match(paragraphs[1L], "0,88", fixed = TRUE)
  expect_match(paragraphs[2L], "Kompetenzbereich „Zuhören“", fixed = TRUE)
  expect_match(paragraphs[2L], "*Median* = 91,3 %", fixed = TRUE)
  expect_match(paragraphs[2L], "0,76", fixed = TRUE)
  expect_false(grepl("90,15", text, fixed = TRUE))
  expect_false(grepl("EatSimulatedValue", text, fixed = TRUE))

  config$editorial$reliability_by_scale <- config$editorial$reliability_by_scale[1L, ]
  config$editorial$agreement_percent <- 99.9
  config$editorial$cohen_kappa <- .99
  config$editorial$reliability_description <- "GLOBALER TEXT"
  text <- report_coding_reliability_text(config)
  expect_match(text, "Prozentuale Übereinstimmung für Lesen", fixed = TRUE)
  expect_match(text, "Einordnung der Interrater\\-Reliabilität für Lesen", fixed = TRUE)
  expect_false(grepl("99,9|0,99|GLOBALER TEXT", text))
  expect_match(text, "91,3", fixed = TRUE)
})

test_that("open and supplied per-scale values are highlighted and safely escaped", {
  config <- example_leistung_input()$config
  config$editorial <- list(reliability_by_scale = review_reliability_fixture()[1L, ])
  config$editorial$reliability_by_scale$reliability_description <- "eine [gute] **Reliabilität**"
  text <- report_coding_reliability_text(config)
  expect_match(text, '[Prozentuale Übereinstimmung für Lesen]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  expect_match(text, '[91,3]{custom-style="EatSimulatedValue"}', fixed = TRUE)
  expect_match(text, '\\[gute\\]', fixed = TRUE)
  expect_false(grepl('**Reliabilität**', text, fixed = TRUE))
  config$editorial <- NULL
  text <- report_coding_reliability_text(config)
  expect_match(text, "Kappa für Lesen", fixed = TRUE)
  expect_match(text, "Kappa für Zuhören", fixed = TRUE)
})

test_that("mathematics retains global prose with explicit per-scale overrides", {
  config <- example_leistung_input("v3_ma_mg_ms")$config
  config$report$data_origin <- "observed"
  config$editorial <- list(reliability_description = "eine gute Reliabilität",
                           agreement_percent = 97.5, cohen_kappa = .88)
  text <- report_coding_reliability_text(config)
  expect_match(text, "Die in Haupttestmodule aufgenommenen Items wiesen eine gute Reliabilität auf.", fixed = TRUE)
  expect_match(text, "*Median* = 97,5 %", fixed = TRUE)
  expect_match(text, "0,88", fixed = TRUE)
  expect_false(grepl("Kompetenzbereich", text, fixed = TRUE))
  config$editorial$reliability_by_scale <- review_reliability_fixture()[1L, ]
  config$editorial$reliability_by_scale$scale_id <- "MO"
  text <- report_coding_reliability_text(config)
  expect_match(text, "91,3", fixed = TRUE)
  expect_false(grepl("97,5", text, fixed = TRUE))
  config$editorial <- NULL
  expect_match(report_coding_reliability_text(config), "Einordnung der Interrater", fixed = TRUE)
  config$report$subject <- "unknown"
  expect_error(report_coding_reliability_text(config), "nur Deutsch oder Mathematik")
})
