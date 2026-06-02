out.plot_by_panel_size <- function(
  gp,
  panel_width,
  panel_height,
  ...
) {
  # Calculate the total dimensions
  plot_size <- ggdim::panel2plotsize(
    plot = gp,
    panel_width = panel_width,
    panel_height = panel_height
  )

  # Output the plot according to the total size
  out.plot(
    gp,
    fig_width = plot_size$total_width,
    fig_height = plot_size$total_height,
    ...
  )
}
