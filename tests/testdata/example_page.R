
##' Subtitle one
###' A first example page
#'
#' ## Aim
#' This is the aim of the page and a plot:

# General setup
rm(list = ls())
# graphics.off()

# Output some stuff
1:10
print(1:10)

out.tabset({

    for(x in 1:2){

        out.tab(paste("tab", x), {
            # gp <- ggplot2::qplot(cars$speed, cars$dist)
            # out.plot(plotly::ggplotly(gp), 5, 4)
            out.plot(
                plot(cars, col = rainbow(2)[x]),
                5, 4
            )
        })

    }

})

# plot(cars)

# out.plot(
#     plot(cars),
#     8, 5
# )

# # Do a plotly output
# gp <- ggplot2::ggplot(cars, ggplot2::aes(speed, dist)) + ggplot2::geom_point()
# for(x in 1:2){
#     out.plot(
#         #plotly::ggplotly(gp),
#         plot(cars),
#         8, 5
#     )
#     # plot(cars)
# }
