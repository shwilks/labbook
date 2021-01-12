
##' Subtitle one
###' A first example page
#'
#' ## Aim
#' This is the aim of the page and a plot:

# General setup
rm(list = ls())
graphics.off()

# Do a plot
gp <- ggplot2::ggplot(cars, ggplot2::aes(speed, dist)) + ggplot2::geom_point()
out.plot(
  plotly::ggplotly(gp),
  8, 5
)

# Do a second plot
gp <- ggplot2::ggplot(cars, ggplot2::aes(speed)) + ggplot2::geom_histogram(bins = 20)
out.plot(
    plotly::ggplotly(gp),
    5, 5
)

# Do a third plot
gp <- ggplot2::ggplot(DNase, ggplot2::aes(conc, density, color = Run)) + ggplot2::geom_point()
out.plot(
    plotly::ggplotly(gp),
    10, 10
)

# Do many final plots
for(x in 1:50){
    gp <- ggplot2::ggplot(cars, ggplot2::aes(speed, dist)) + ggplot2::geom_point(color = rainbow(50)[x])
    out.plot(
        plotly::ggplotly(gp),
        8, 5
    )
}

#' ## Results
#' This is some extra text

