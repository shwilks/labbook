
##' Subtitle goes here
###' Page title goes here
#'
#' ## Aim
#' This is an example page, any text you type after a `#'` marker will be
#' rendered to the __page__ as _markdown_.

# Setup the page
rm(list = ls())
library(labbook)

#' New text like this will break the code block and start a new one. You can set the figure size
#' by using `#' [4,8]` to specify width and height

plot(cars)

#' Any text that is output from your code is hidden by default but will be shown when you toggle
#' the "Show inline code" on the page
#'
#' For example:

cat("### A subheading")

#' If you want to print something directly to the webpage to be interpreted as is (for example a
#' programatically generated heading) you can use the `out` function.

out("### A subheading")

#' You can use other types of functions to output tables etc.

out.table(cars[1:10,])

#' Or make a some output collapsible:
out.collapsible(
    label = "Cars data",
    out.table(cars[1:10,])
)

#' You can also use `out.plot()` to have finer control over plot outputs.
for(plotdim in 3:5){

    out.plot(
        plot(cars),
        fig_width  = plotdim,
        fig_height = plotdim,
        inline = TRUE
    )

}

#' It also works with html widgets like plotly.
library(plotly)

for(plotdim in 3:5){

    out.plot(
        plot_ly(data = iris, x = ~Sepal.Length, y = ~Petal.Length),
        fig_width  = plotdim,
        fig_height = plotdim,
        inline = TRUE
    )

}

#' You can also break output into tabs
out.tabset(
    out.tab(
        label = "cars 1",
        out.plot(
            plot(cars),
            4,4
        )
    ),
    out.tab(
        label = "cars 2",
        out.plot(
            plot(cars, col = "green"),
            4,4
        )
    ),
    out.tab(
        label = "cars 3",
        out.plot(
            plot(cars, col = "red"),
            4,4
        )
    )
)

#' You can also use normal arguments that you might use in code chunks in an rmarkdown document
#' for example to take advantage of animation hooks:
#' [4,4] animation.hook='gifski'
for (i in 1:2) {
    pie(c(i %% 2, 6), col = c('red', 'yellow'), labels = NA)
}

