test_that("only named optional chapter blocks are selected and archived as sources", {
  directory <- tempfile("local-chapters-")
  edit_report_texts(directory)
  optional <- c("grundlagen_kompetenzstufen.qmd", "pilotierung_durchfuehrung.qmd",
                "pilotierung_auswertung.qmd")
  for (name in optional) writeLines("A local editorial draft.", file.path(directory, name))
  writeLines("Unrelated private content.", file.path(directory, "private-notes.qmd"))
  writeLines("Unrelated private data.", file.path(directory, "participants.csv"))

  selected <- basename(report_text_files(directory, "pilotierung"))
  expect_true(all(optional %in% selected))
  expect_false(any(c("private-notes.qmd", "participants.csv") %in% selected))
  expect_false(any(optional %in% basename(report_text_files(directory, "pilotierung_leistung"))))
})

test_that("an optional chapter directory fails before rendering", {
  directory <- tempfile("local-chapters-")
  edit_report_texts(directory)
  dir.create(file.path(directory, "pilotierung_auswertung.qmd"))
  expect_error(report_text_files(directory), "keine Verzeichnisse")
})
