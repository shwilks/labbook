
#' @export
render.pagetemplate <- function(
    template,
    codepath,
    vars,
    as.job = TRUE
) {

    # Read the template
    templatelines <- readLines(template)

    # Replace placeholders with vars
    for (x in seq_along(vars)) {
        templatelines <- gsub(
            sprintf("{{%s}}", names(vars)[x]),
            as.character(vars[[x]]),
            templatelines,
            fixed = TRUE
        )
    }

    # Write the code file
    writeLines(templatelines, codepath)

    # Render the page
    if (as.job) {
        render.page.job(normalizePath(codepath))
    } else {
        render.page(normalizePath(codepath))
    }

}
