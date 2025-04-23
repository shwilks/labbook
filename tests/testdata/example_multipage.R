##' Subtitle one
###' An example multipage page
#'
#' ## Aim
#' This is the aim of the page and a plot:

# General setup
library(labbook)
rm(list = ls())

message("Rendering general setup")

#' ### Multiple pages

out.pageset({
  for (x in 1:3) {
    out.page(
      paste("page", x),
      {
        plot(cars, col = rainbow(3)[x])
        message(sprintf("Rendering page %s", x))
      }
    )
  }
})
