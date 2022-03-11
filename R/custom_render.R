
# A custom render function, whose purpose is to extract htmlwidget meta data into
# additional files that can then be loaded asynchronously
labpage_render <- function(x, options, ...) {

    # Special behaviour for html widgets
    if (!options$standalone && inherits(x, "htmlwidget")) {

        # Convert to html output with the options
        x <- htmlwidgets:::toHTML(x, knitrOptions = options)

        # Extract the json data component to be exported to a separate file
        src <- x[[2]]

        # Append a custom html-widget-unloaded class
        x[[1]][[2]]$attribs$class <- paste(x[[1]][[2]]$attribs$class, "html-widget-unloaded")

        # Escape characters
        widget_data <- src$children[[1]]
        widget_data <- gsub("\\", "\\\\", widget_data, fixed = T)
        widget_data <- gsub("`", "\\`", widget_data, fixed = T)

        # Wrap it in an object definition
        widget_id          <- gsub("-", "_", src$attribs$`data-for`, fixed = T)
        widget_data_script <- sprintf("var %s = `%s`;", widget_id, widget_data)

        # Write it out to the widget directory
        if(!dir.exists(options$widgets.dir)) dir.create(options$widgets.dir, recursive = T)
        writeLines(
            widget_data_script,
            file.path(options$widgets.dir, paste0(widget_id, ".js"))
        )

        # Include only the placeholder div in the actual output and attach the widget
        # loader script as a dependency
        dependencies <- htmltools::htmlDependencies(x)
        widget_loader <- htmltools::htmlDependency(
            name = "widget_loader",
            version = 1,
            src = system.file("scripts", package = "labbook"),
            script = "load_widgets.js"
        )

        # x <- htmltools::tagList(x[[1]], x[[2]], x[[3]])
        x <- htmltools::tagList(x[[1]], x[[3]])
        x <- htmltools::attachDependencies(x, dependencies)
        x <- htmltools::attachDependencies(x, widget_loader, append = TRUE)

    }

    # Call knit_print on the result
    knitr::knit_print(x, options = options, ...)

}

