# Presentation of supplied main-test results. Estimation and transformations
# belong to the upstream analysis; these helpers never infer coefficients.
report_completion_module_table <- function(results) {
  rows <- results$module_statistics
  data.frame(
    "Modul" = rows$label,
    "Skala" = rows$scale_id,
    "Items (N)" = rows$n_items,
    "M L\u00f6sung (%)" = study_number(100 * rows$mean_p_correct),
    "M Logit" = study_number(rows$mean_logit, 2L),
    check.names = FALSE
  )
}

report_transformation_number <- function(value) {
  if (!is.numeric(value) || is.complex(value) || length(value) != 1L ||
      !is.finite(value)) {
    stop("Transformationskoeffizienten m\u00fcssen einzelne endliche Zahlen sein.", call. = FALSE)
  }
  # Only validated numbers enter TeX. Keep small coefficients visible instead
  # of rounding them to the one/two decimals used in descriptive tables.
  number <- format(value, digits = 15L, scientific = FALSE, trim = TRUE,
                   decimal.mark = ".")
  sub(".", "{,}", number, fixed = TRUE)
}

report_transformation_markdown <- function(results, config) {
  rows <- results$transformations
  blocks <- vapply(seq_len(nrow(rows)), function(i) {
    row <- rows[i, , drop = FALSE]
    person <- identical(row$target, "person")
    label <- config$scales[[row$scale_id]]$label
    heading <- report_markdown_text(paste0(label, " (", row$scale_id, ")"))
    equation <- paste0("y_{\\mathrm{", if (person) "Person" else "Item", "}} = ",
      report_transformation_number(row$intercept), " + ",
      report_transformation_number(row$slope), " \\cdot ",
      if (person) "\\theta" else "\\beta")
    paste0("**", heading, ": ", if (person) "Personenf\u00e4higkeit" else "Itemschwierigkeit",
           "**\n\n$$\n", equation, "\n$$\n\n",
           "*Grundlage:* ", report_markdown_text(row$source_label), ".\n\n")
  }, character(1))
  paste(blocks, collapse = "")
}

# These are bibliographic facts, not excerpts from the private report prose.
# The local editorial bibliography requests the sources cited in chapters 1/2;
# the bundled original text only cites the recommendation on school feedback.
report_completion_bibliography <- function(config, include_background = FALSE) {
  entries <- c(kmk2012 = paste0(
    "KMK (2012). *Vereinbarung zur Weiterentwicklung von VERA.* ",
    "Beschluss der Kultusministerkonferenz vom 08.03.2012."))
  if (include_background) {
    entries <- c(entries,
      cohen1960 = paste0("Cohen, J. (1960). A coefficient of agreement for nominal scales. ",
                         "*Educational and Psychological Measurement, 20*(1), 37\u201346."),
      loyd1980 = paste0("Loyd, B. H. & Hoover, H. D. (1980). Vertical equating using the Rasch model. ",
                        "*Journal of Educational Measurement, 17*, 179\u2013193."))
    if (identical(config$report$subject, "de")) {
      entries <- c(entries, kmk2005 = paste0("KMK (2005). *Bildungsstandards im Fach Deutsch ",
        "f\u00fcr den Primarbereich.* Beschluss der Kultusministerkonferenz vom 15.10.2004. Luchterhand."))
      if ("DL" %in% config$domains$domain_id) entries <- c(entries, iqb2013a = paste0(
        "IQB (2013a). *Kompetenzstufenmodell zu den Bildungsstandards f\u00fcr das Fach Deutsch ",
        "im Kompetenzbereich \u201eLesen \u2013 mit Texten und Medien umgehen\u201c. Primarbereich.* ",
        "Auf Grundlage des L\u00e4ndervergleichs 2011 \u00fcberarbeiteter Entwurf, Version vom 13. Februar 2013."))
      if ("DH" %in% config$domains$domain_id) entries <- c(entries, iqb2013b = paste0(
        "IQB (2013b). *Kompetenzstufenmodell zu den Bildungsstandards f\u00fcr das Fach Deutsch ",
        "im Kompetenzbereich \u201eSprechen und Zuh\u00f6ren\u201c. Primarbereich.* ",
        "Beschluss der Kultusministerkonferenz vom 04.03.2010; auf Grundlage des L\u00e4ndervergleichs ",
        "2011 \u00fcberarbeiteter Entwurf, Version vom 13. Februar 2013."))
    } else {
      entries <- c(entries,
        reiss2008 = paste0("Reiss, K. & Winkelmann, H. (2008). Step by step. Ein Kompetenzstufenmodell ",
          "f\u00fcr das Fach Mathematik. *Grundschule, 40*(10), 18\u201321."),
        reiss2009 = paste0("Reiss, K. & Winkelmann, H. (2009). Kompetenzstufenmodelle f\u00fcr das Fach ",
          "Mathematik im Primarbereich. In *Bildungsstandards Deutsch und Mathematik. ",
          "Leistungsmessung in der Grundschule.* Beltz."),
        # Primary sources: University of Minnesota publisher archive (1984),
        # https://conservancy.umn.edu/bitstreams/632e9a81-983f-4a8f-89c3-80105dbe74b9/download
        # and Wiley https://doi.org/10.1111/j.1745-3984.1993.tb00423.x (1993).
        yen1984 = paste0("Yen, W. M. (1984). Effects of local item dependence on the fit and equating ",
          "performance of the three-parameter logistic model. *Applied Psychological Measurement, 8*(2), ",
          "125\u2013145. [Originalartikel](https://conservancy.umn.edu/bitstreams/632e9a81-983f-4a8f-89c3-80105dbe74b9/download)."),
        yen1993 = paste0("Yen, W. M. (1993). Scaling performance assessments: Strategies for managing local ",
          "item dependence. *Journal of Educational Measurement, 30*(3), 187\u2013213. ",
          "[Originalartikel](https://doi.org/10.1111/j.1745-3984.1993.tb00423.x)."))
    }
  }
  unname(entries[order(entries, method = "radix")])
}
