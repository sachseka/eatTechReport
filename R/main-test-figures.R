# One plan supplies filenames, dimensions and module groups to both the renderer
# and the editable Quarto blocks. Filenames use validated scale codes, never IDs
# or labels supplied for modules.
main_test_figure_plan <- function(config, main_test) {
  result <- list(selection = list(), modules = list())
  if (is.null(main_test$item_levels)) return(result)
  levels <- main_test$item_levels
  for (scale_id in names(config$scales)) {
    if (!scale_id %in% levels$selection$scale_id) next
    label <- config$scales[[scale_id]]$label
    result$selection[[length(result$selection) + 1L]] <- list(
      scale_id = scale_id, label = label, module_ids = NULL,
      file = paste0("item-levels-selection-", scale_id, ".png"),
      id = paste0("fig-item-levels-selection-", tolower(scale_id)),
      width = 15.5, height = 8.2)
    ids <- main_test$modules$module_id[
      main_test$modules$module_id %in% levels$modules$module_id[
        levels$modules$scale_id == scale_id]]
    groups <- split(ids, ceiling(seq_along(ids) / 3L))
    for (i in seq_along(groups)) {
      result$modules[[length(result$modules) + 1L]] <- list(
        scale_id = scale_id, label = label, module_ids = unname(groups[[i]]),
        file = paste0("item-levels-modules-", scale_id, "-", i, ".png"),
        id = paste0("fig-item-levels-modules-", tolower(scale_id), "-", i),
        width = 15.5, height = 4.2 + 4 * length(groups[[i]]))
    }
  }
  result
}
