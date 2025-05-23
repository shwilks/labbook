##' Subtitle one
###' A first example page
#'
#' ## Aim
#' This is the aim of the page and a plot:

# General setup
rm(list = ls())
library(labbook)

# Do several plotly plots
gp1 <- ggplot2::ggplot(cars, ggplot2::aes(speed, dist)) +
  ggplot2::geom_point()
gp2 <- ggplot2::ggplot(cars, ggplot2::aes(dist, dist)) +
  ggplot2::geom_point()

out.tabset({
  out.tab(
    "tab1",
    out.plot(
      plotly::ggplotly(gp1),
      # gp,
      8,
      5
    )
  )
  out.tab(
    "tab2",
    out.plot(
      plotly::ggplotly(gp2),
      # gp,
      8,
      5
    )
  )
})
