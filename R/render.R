
# Define the chunk end
chunk_end   <- "```"

# # Wrap text in a code chunk
# chunk_code <- function(code, args = NULL, language = "r") {
#
#     paste0(
#         "```\n",
#         "\n```{", language,", ",
#         paste(
#             paste(names(args), args, sep = " = "),
#             collapse = ", "
#         )
#         ,"}\n",
#         code,
#         "\n", chunk_end,
#         "\n```{", language,"}"
#     )
#
# }


# Start a new code chunk
new_chunk <- function(chunk.name = NULL, args, language = "r") {

    paste0(
        chunk_end, "\n",
        "\n```{", language," ", chunk.name, ", ",
        paste(
            paste(names(args), args, sep = " = "),
            collapse = ", "
        )
        ,"}"
    )

}

# Render in a new r session
render_new_session <- function(...) {
  callr::r(
    func = function(...) rmarkdown::render(..., envir = globalenv()),
    args = list(...),
    show = TRUE
  )
}

# Render a currently open file
render.file <- function() {

    filepath <- rstudioapi::getSourceEditorContext()$path
    if (filepath == "") return(invisible(NULL))
    filename <- basename(filepath)

    if (filename == "overall-todo.md") {
        openTodo(openmd = FALSE)
    } else {
        rstudioapi::sendToConsole(
            sprintf('labbook::render.page.job("%s")', filepath),
            focus = FALSE
        )
    }

}

# Render text for a currently open file
render.filetext <- function() {

    filepath <- rstudioapi::getSourceEditorContext()$path
    if (filepath == "") return(invisible(NULL))
    filename <- basename(filepath)

    if (filename == "overall-todo.md") {
        openTodo(openmd = FALSE)
    } else {
        rstudioapi::sendToConsole(
            sprintf('labbook::rerender.pagetext("%s")', filepath),
            focus = FALSE
        )
    }

}


# Render the page as a job
#' @export
render.page.job <- function(codepath) {

  tmp <- tempfile(fileext = ".R")
  writeLines(
    sprintf('labbook::render.page("%s")', codepath),
    tmp
  )
  rstudioapi::jobRunScript(tmp, workingDir = getwd())

}


# Render the page
#' @export
render.page <- function(
    codepath       = NULL,
    pagepath       = NULL,
    pagelink       = pagepath,
    pagetitle      = NULL,
    pagesubtitle   = NULL,
    add_index_link = TRUE,
    eval           = TRUE,
    openpage       = TRUE,
    verbose        = FALSE,
    codetoggle     = TRUE,
    standalone     = FALSE,
    embed_js       = standalone,
    headcontent    = NULL,
    headercontent  = NULL,
    cache          = FALSE,
    async_widgets  = !standalone
    ) {

    # Set default codepath
    if (is.null(codepath)) {
        codepath <- rstudioapi::getActiveDocumentContext()$path
    }

    # Exit if no valid codepath found
    if (codepath == "") return()

    # Parse code path
    codepath      <- normalizePath(codepath)
    codename      <- basename(codepath)
    codedir       <- dirname(codepath)
    projectdir    <- file.path(codedir, "..")
    index_path    <- file.path(codedir, "..", "..", "..", "index.html")
    library_path  <- file.path(codedir, "..", "..", "..", "library")
    template_path <- file.path(library_path, "templates")
    tags_path     <- file.path(library_path, "tags.js")

    # Message that knitting is in progress
    if (verbose) message("Start rendering")

    # Remove any current files
    pagefiledir <- paste0(substr(pagepath, 1, nchar(pagepath) - 5), "_files")
    unlink(pagefiledir, recursive = TRUE)

    # Preprocess the markdown file
    markdown_file <- tempfile(fileext = ".Rmd")
    if (verbose) message("Preprocessing code file...", appendLF = FALSE)
    page <- preprocess_codefile(
        code_file         = codepath,
        markdown_output   = markdown_file,
        include_code_link = !standalone,
        pagetitle         = pagetitle,
        pagesubtitle      = pagesubtitle
    )
    # system(sprintf("open -a 'RStudio' %s", shQuote(markdown_file)))
    if (verbose) message("done.")

    # Set default pagepath
    if (is.null(pagepath)) {
        pagename <- gsub("\\..+$", ".html", codename)
        pagepath <- file.path(codedir, "..", "pages", pagename)
    }

    # Knit the markdown file to the page output
    if (verbose) message("Knitting output...", appendLF = FALSE)
    page_details <- knit_markdown(
        markdown_file  = markdown_file,
        output_file    = pagepath,
        eval           = eval,
        project_path   = projectdir,
        index_path     = index_path,
        page_title     = page$title,
        page_tags      = page$tags,
        codetoggle     = codetoggle,
        headcontent    = headcontent,
        headercontent  = headercontent,
        standalone     = standalone,
        embed_js       = embed_js,
        async_widgets  = async_widgets,
        add_index_link = add_index_link,
        cache          = cache
    )
    if (verbose) message("done.")

    # Try and open the page
    if (openpage) {
        if (verbose) message("Opening webpage...", appendLF = FALSE)
        open_webpage(pagepath, make.front = FALSE)
        if (verbose) message("done.")
    }

    # Construct the page link
    if (add_index_link && !standalone) {
      page_link <- file.path("projects", basename(normalizePath(projectdir)), "pages", basename(pagepath))
    }

    # Update the index page
    if (add_index_link && !standalone) {

        if (verbose) message("Updating index page...", appendLF = FALSE)
        addIndexPageLink(
            index_path    = index_path,
            project_title = readLines(file.path(projectdir, ".title")),
            page_title    = page$title,
            page_subtitle = page$subtitle,
            page_link     = page_link,
            overwrite     = TRUE
        )
        if (verbose) message("done.")

    }

    # Update the tags record
    if (add_index_link && !standalone && length(page$tags) > 0) {

        if (!file.exists(tags_path)) writeLines("var tags = {};", tags_path)
        tags_js <- readLines(tags_path)
        tags_record_js <- gsub("var tags = ", "", tags_js[1], fixed = T)
        tags_record_js <- gsub(";", "", tags_record_js, fixed = T)
        tags_record <- jsonlite::fromJSON(tags_record_js, simplifyVector = FALSE)

        for (tag in page$tags) {
            if (!page_link %in% sapply(tags_record[[tag]], function(x) x$link)) {
                tags_record[[tag]] <- c(
                    tags_record[[tag]],
                    list(
                        list(
                            title = page$title,
                            link = page_link
                        )
                    )
                )
            }
        }

        tags_js[1] <- paste0(
            "var tags = ",
            jsonlite::toJSON(tags_record, auto_unbox = TRUE),
            ";"
        )
        writeLines(tags_js, tags_path)

    }

    # Write page id png
    if (!standalone) {
        if (!file.exists(page_details$files_dir)) {
            dir.create(page_details$files_dir)
        }
        file.copy(
            from = file.path(template_path, "pageid.png"),
            to   = file.path(page_details$files_dir, paste0(page_details$page_id, ".png"))
        )
    }

    # Message that knitting is done
    if (verbose) message("Rendering complete.")

}

# Pre process a markdown file
preprocess_codefile <- function(
    code_file,
    include_code_link = TRUE,
    markdown_output,
    pagetitle = NULL,
    pagesubtitle = NULL,
    skipfromstop = TRUE,
    eval = TRUE
    ) {

    # Set the language
    fileext <- tolower(gsub("^.*\\.", "", code_file))
    language <- switch(
        fileext,
        "r" = "r",
        "py" = "python",
        stop(sprintf("File extension '%s' not supported", fileext))
    )

    # Parse codepath
    codepath <- normalizePath(code_file)
    codename <- basename(codepath)

    # Read code lines
    code    <- readLines(code_file)
    rawcode <- code

    # Skip any lines from a stop() declaration
    if (skipfromstop) {
        if (sum(code == "stop()") > 0) {
            first_stop <- min(which(code == "stop()"))
            code <- code[seq_len(first_stop-1)]
            warning(sprintf("Stopped at line %s", first_stop), call. = FALSE)
        }
    }

    # Strip empty start lines
    while(length(code) > 0 && code[1] == "") code <- code[-1]

    # Add line breaks
    for(x in seq_along(code)) {
        if (trimws(code[x]) == "#'") {
            if (x != 1 && trimws(code[x-1]) != "#'" && substr(code[x-1], 1, 3) == "#' ") {
                code[x-1] <- paste0(code[x-1], "  ")
            }
            code[x] <- paste0(code[x], "  ")
        }
    }

    # Remove any inline code if not to be evaluated
    if (!eval) {
        code <- gsub("\\`r .*?\\`", "`r 'placeholder'`", code)
    }

    # Find the page title and remove it
    titleline <- substr(code, 1, 4) == "###'"
    if (is.null(pagetitle)) {

        pagetitle <- code[titleline]
        pagetitle <- trimws(substr(pagetitle, 5, nchar(pagetitle)))

    }

    code <- code[!titleline]
    if (length(pagetitle) == 0) stop("Page must have a title")

    # Check for any tags
    taglines <- grepl("#' @", code, fixed = TRUE)
    tags <- trimws(gsub("#' @", "", code[taglines], fixed = TRUE))
    code <- code[!taglines]

    # Find the page subtitle and remove it
    subtitleline <- substr(code, 1, 3) == "##'"
    if (is.null(pagesubtitle)) {

        pagesubtitle <- code[subtitleline]
        pagesubtitle <- trimws(substr(pagesubtitle, 4, nchar(pagesubtitle)))

    }
    code         <- code[!subtitleline]
    if (length(pagesubtitle) == 0) stop("Page must have a subtitle")

    # Replace lines starting with #'
    speciallines <- grepl("^#'", code)
    commentlines <- rep(FALSE, length(speciallines))

    for(linenum in which(speciallines)) {

        # Extract the comment
        linecontent <- code[linenum]
        comment     <- gsub("^#'( )*", "", linecontent)

        if (grepl("^#' \\[", linecontent)) {

            # Changing figure sizes
            fig.dim   <- as.numeric(strsplit(gsub("^.*\\[(.*)\\].*$", "\\1", comment), ",")[[1]])
            fig.scale <- stringr::str_extract(comment, "\\*[0-9\\.]*")

            if (is.na(fig.scale)) fig.scale <- 1
            else                 fig.scale <- as.numeric(substr(fig.scale, 2, nchar(fig.scale)))

            # Getting and stripping the figure name
            fig.name  <- stringr::str_extract(comment, "//.*$")
            if (!is.na(fig.name)) fig.name <- trimws(substr(fig.name, 3, nchar(fig.name)))
            else                 fig.name <- NULL
            comment <- gsub("//.*$", "", comment)

            # Set chunk args
            chunk_args <- list(
                fig.width  = fig.dim[1],
                fig.height = fig.dim[2],
                out.width  = paste0("'", 120*fig.dim[1]*fig.scale, "px'"),
                out.height = paste0("'", 120*fig.dim[2]*fig.scale, "px'")
            )

            # Check for extras
            fig.extra <- gsub("^.*?]", "", comment)
            fig.extra <- strsplit(fig.extra, " ")[[1]][-1]


            # Add additional chunk args
            for(i in seq_along(fig.extra)) {
                extra <- strsplit(fig.extra[i], "=")[[1]]
                chunk_args[extra[1]] <- extra[2]
            }

            # Output the chunk
            code[linenum] <- new_chunk(fig.name, chunk_args, language)

        } else {

            # Note that this line was a regular comment
            commentlines[linenum] <- TRUE

        }

    }

    # Take comments out of the code chunks
    lastlinecomment <- FALSE
    sectionnum      <- 1

    for(linenum in seq_along(commentlines)) {

        # Strip the comment marks
        if (commentlines[linenum]) {

            # Remove the #'
            code[linenum] <- substr(code[linenum], 4, nchar(code[linenum]))

        }

        # If starting new lines of comments
        if (commentlines[linenum] && !lastlinecomment) {
            code[linenum] <- paste0(chunk_end, "\n<div class='text-section' id='text-section-", sectionnum, "'>", code[linenum])
            sectionnum <- sectionnum + 1
        }

        # If ending a line of comments
        if (!commentlines[linenum] && lastlinecomment) {
            code[linenum] <- paste0("</div>\n```{", language,"}\n", code[linenum])
        }

        # If you've reached the last line as a comment
        if (commentlines[linenum] && linenum == length(commentlines)) {
            code[linenum] <- paste0(code[linenum], "</div>\n```{", language,"}")
        }

        # Update last line was a comment
        lastlinecomment <- commentlines[linenum]

    }

    # Set the codefile link
    if (include_code_link) {
        codelink <- sprintf(
            "<a id='code-download-link' href='%s'>Download code</a>",
            file.path("..", "code", codename)
        )
    } else {
        codelink <- NULL
    }

    # Write to the markdown file
    writeLines(
        text = c(
            "---",
            paste0('title: "', pagetitle, '"'),
            "---",
            paste0("```{", language,"}"),
            code,
            chunk_end,
            "</main>",
            "<footer>",
            codelink,
            paste0("```{", language," class.source='code-block page-code', eval=FALSE}"),
            readLines(code_file),
            "```",
            "</footer>"
        ),
        con = markdown_output
    )

    # Return meta data
    list(
        title    = pagetitle,
        subtitle = pagesubtitle,
        tags     = tags
    )

}


# Knit a markdown file
knit_markdown <- function(
    markdown_file,
    output_file,
    project_path,
    index_path,
    page_title,
    page_tags,
    add_index_link = TRUE,
    codetoggle     = TRUE,
    headercontent  = NULL,
    headcontent    = NULL,
    standalone     = FALSE,
    async_widgets  = !standalone,
    embed_js       = standalone,
    eval           = TRUE,
    cache          = FALSE
) {

    # Set the library and cache location
    lib_dir     <- file.path(dirname(output_file), ".lib")
    cache_dir   <- gsub("\\.html$", "_cache/", output_file)
    files_dir   <- gsub("\\.html$", "_files/", output_file)
    widgets_dir <- file.path(files_dir, "widgets")

    # Set the code link
    # codelink <- paste0("<a id='code-download-link' href='", file.path("..", "code", codename),"'>Download code</a>")

    # "```{", language," class.source='code-block page-code', eval=FALSE}",
    # rawcode,
    # "```"

    # Generate a page id
    page_id <- make_page_id()
    page_id_div <- paste0("<div id='page-id' style='display:none;'>", page_id, "</div>")

    # Generate a page tags div
    tags_div <- paste0(
        "<div id='page-tags'>",
        paste(vapply(
            page_tags, function(tag) {
                sprintf("<div class='page-tag'>%s</div>", tag)
            },
            character(1)
        ), collapse = ""),
        "</div>"
    )

    # Generate header file
    header_file <- tempfile()
    if (is.null(headcontent)) {
        if (embed_js) {
            headcontent <- ''
        } else {
            headcontent <- c(
                '<link href="../.lib/styles/general.css" rel="stylesheet"/>',
                '<link href="../.lib/styles/shared.css" rel="stylesheet"/>',
                '<link href="../.lib/styles/page.css" rel="stylesheet"/>',
                '<link href="../.lib/styles/labpage.css" rel="stylesheet"/>',
                '<script src="../.lib/tags.js"></script>',
                '<script src="../.lib/scripts/page.js"></script>'
            )
        }
    }

    writeLines(
        text = headcontent,
        con  = header_file
    )

    # Set code toggle
    if (codetoggle) codetogglediv <- "<div class='headerlink' id='codetoggle'></div>"
    else            codetogglediv <- NULL

    # Generate header file
    before_body_file <- tempfile()

    if (standalone || !add_index_link) {

        writeLines(
            text = c(
                paste0("<header files-dir='", basename(files_dir),"'>"),
                page_id_div,
                codetogglediv,
                headercontent,
                tags_div,
                "</header>",
                "<main>"
            ),
            con = before_body_file
        )

    } else {

        # Get project information
        project <- project.info(project_path)
        labbook_name <- getLabbookName(index_path)

        writeLines(
            text = c(
                paste0("<header files-dir='", basename(files_dir),"'>"),
                "<div id='page-header'>",
                sprintf(
                    '<div><a href="%1$s">%5$s</a> / <a href="%1$s#%2$s">%3$s</a> / <a id="page-link">%4$s</a></div>',
                    "../../../index.html",
                    project$directory,
                    project$title,
                    page_title,
                    labbook_name
                ),
                "</div>",
                page_id_div,
                codetogglediv,
                headercontent,
                tags_div,
                "</header>",
                "<main>"
            ),
            con = before_body_file
        )

    }

    # After the body
    # knitr::knit(text = knitr::knit_expand(text = c(
    #     "```r",
    #     readLines(code_file),
    #     "```"
    # )))

    after_body_file <- tempfile()
    writeLines(
        text = c(""),
        con  = after_body_file
    )

    # Generate the output format
    if (embed_js) {
        output_format <- eval(substitute(
            rmarkdown::html_document(
                highlight = "default",
                theme = NULL,
                self_contained = standalone,
                # mathjax = "default",
                mathjax = NULL,
                pandoc_args = "--mathml",
                section_divs = TRUE,
                extra_dependencies = list(
                  htmldeps::html_dependency_jquery(),
                  htmltools::htmlDependency(
                    name = "Racmacs",
                    version = "1.0.11",
                    src = system.file("labbook/library", package = "labbook"),
                    script = c(
                      "scripts/page.js"
                    ),
                    stylesheet = c(
                      "styles/general.css",
                      "styles/shared.css",
                      "styles/page.css"
                    )
                  )
                ),
                includes = rmarkdown::includes(
                    in_header   = header_file,
                    before_body = before_body_file,
                    after_body  = after_body_file
                )
            )
        ))
    } else {

        # Clear directories
        unlink(files_dir, recursive = T)

        output_format <- eval(substitute(
            rmarkdown::html_document(
                highlight = "default",
                theme = NULL,
                self_contained = standalone,
                lib_dir = lib_dir,
                includes = rmarkdown::includes(
                    in_header   = header_file,
                    before_body = before_body_file,
                    after_body  = after_body_file
                ),
                extra_dependencies = list(
                  htmldeps::html_dependency_jquery()
                ),
                # mathjax = "local",
                mathjax = NULL,
                pandoc_args = "--mathml",
                section_divs = TRUE
            )
        ))
    }

    # Set package options
    output_format$knitr$opts_knit$global.par <- TRUE

    # Set additional chunk opts
    output_format$knitr$opts_chunk$class.source  = 'code-block code-output source-code'
    output_format$knitr$opts_chunk$class.warning = 'code-block code-output warning-code'
    output_format$knitr$opts_chunk$class.output  = 'code-block code-output output-code'
    output_format$knitr$opts_chunk$class.message = 'code-block code-output message-code'
    # output_format$knitr$opts_chunk$fig.keep      = 'high'
    output_format$knitr$opts_chunk$message       = FALSE
    output_format$knitr$opts_chunk$warning       = FALSE
    output_format$knitr$opts_chunk$eval          = eval
    output_format$knitr$opts_chunk$subchunk      = TRUE
    output_format$knitr$opts_chunk$comment       = NA
    output_format$knitr$opts_chunk$render        = labpage_render
    output_format$knitr$opts_chunk$widgets.dir   = widgets_dir

    # output_format$knitr$
    # browser()
    # output_format$knitr$opts_chunk$engine.path   = list(
    #     python = file.path(project_path, ".venv", "bin", "python")
    # )
    # # output_format$knitr$opts_chunk$results       = "asis"

    if (cache) {
        output_format$knitr$opts_chunk$cache      = TRUE
        output_format$knitr$opts_chunk$cache.path = cache_dir
    }

    # Set hook for numbering subchunks
    output_format$knitr$knit_hooks$subchunk <- function(before, options, envir) {

        if (before) {
            envir$`.subChunkNum`   <- 0
            envir$`.chunk-label`   <- options$label
            return(NULL)
        }

    }

    # Custom hook for inline output
    output_format$knitr$knit_hooks$inline <- function(x) {
        if (grepl("\n", x)) {
            return(paste0("<div class='inline-output'>", x, "</div>"))
        } else {
            return(paste0("<span class='inline-output'>", x, "</span>"))
        }
    }

    # Custom hook for regular output
    output_format$knitr$knit_hooks$output <- function(x, options) {

        # Sequences for div start and end
        div_start <- "<pre class='code-block code-output output-code'><code>"
        div_end   <- "</code></pre>"

        # Remove newline at end
        x <- gsub("\\n$", "", x)

        # Remove case where escape start immediately follows escape end
        x <- gsub(paste0(escape_end, escape_start), "", x, fixed = T)

        # Find output not surrounded by special preserver marks
        x <- stringr::str_replace_all(
            string      = x,
            pattern     = paste0("(^|",Hmisc::escapeRegex(escape_end),").*?($|",Hmisc::escapeRegex(escape_start),")"),
            replacement = function(s) {
                # Remove any preserver marks
                s <- gsub(escape_start, "", s, fixed = T)
                s <- gsub(escape_end, "", s, fixed = T)
                # Escape html and wrap it in a div
                paste0(div_start, htmltools::htmlEscape(s), div_end)
            }
        )

        # Remove cases where there is no output between a div start and div end
        x <- gsub(paste0(div_start, div_end), "", x, fixed = T)

        # Return the result
        x

    }

    # Clear current graphics devices
    graphics.off()

    # Render the html page
    render_new_session(
        input = markdown_file,
        output_format = output_format,
        output_file = output_file,
        quiet = TRUE,
        knit_root_dir = getwd()
    )

    # Return the page details
    list(
        page_id   = page_id,
        files_dir = files_dir
    )

}


#' @export
rerender.pagetext <- function(
    codepath = NULL,
    pagepath = NULL,
    openpage = TRUE
    ) {

    # Set default codepath
    if (is.null(codepath)) {
        codepath <- rstudioapi::getActiveDocumentContext()$path
    }

    # Exit if no valid codepath found
    if (codepath == "") return()

    codename <- basename(codepath)
    codedir  <- dirname(codepath)

    # Set default pagepath
    if (is.null(pagepath)) {
        pagename <- gsub("\\.R$", ".html", codename)
        pagepath <- file.path(codedir, "..", "pages", pagename)
    }

    tmppage <- tempfile(fileext = ".html")
    render.page(
        codepath = codepath,
        pagepath = tmppage,
        pagelink = pagepath,
        eval     = FALSE,
        openpage = FALSE,
        verbose  = FALSE
    )

    # Read html files
    pagehtml <- xml2::read_html(pagepath)
    tmphtml  <- xml2::read_html(tmppage)

    # Get text sections
    xpath <- "//div[@class='text-section']"
    pagesections <- xml2::xml_find_all(pagehtml, xpath)
    tmpsections  <- xml2::xml_find_all(tmphtml,  xpath)

    if (length(pagesections) != length(tmpsections)) {
        stop("Cannot perform automatic section matching, please rerender the page.")
    }

    # Replace each text section with the new text
    for(sectionnum in seq_along(pagesections)) {

        pagesection <- pagesections[[sectionnum]]
        tmpsection  <- tmpsections[[sectionnum]]

        # Count any inline code outputs
        xpath <- "//*[@class='inline-output']"
        pagesection_inlinenodes <- xml2::xml_find_all(pagesection, xpath)
        tmpsection_inlinenodes  <- xml2::xml_find_all(tmpsection,  xpath)

        # Replace the inline nodes with those from the original page
        if (length(pagesection_inlinenodes) != length(tmpsection_inlinenodes)) {
            stop("Cannot perform automatic section matching, please rerender the page.")
        }

        for(nodenum in seq_along(pagesection_inlinenodes)) {

            if (xml2::xml_name(pagesection_inlinenodes[[nodenum]]) == "span") {

                # If the inline node is a span we can simply replace it
                xml2::xml_replace(tmpsection_inlinenodes[[nodenum]], pagesection_inlinenodes[[nodenum]])

            } else {

                # If it's a div we have to remove the autogenerated <p> tags and replace it with a <span>
                parentNode <- xml2::xml_parent(tmpsection_inlinenodes[[nodenum]])
                xml2::xml_replace(tmpsection_inlinenodes[[nodenum]], pagesection_inlinenodes[[nodenum]])
                xml2::xml_name(parentNode) <- "span"

            }

        }

    }

    # Replace the nodes
    for(sectionnum in seq_along(pagesections)) {

        # Now replace the original text node
        xml2::xml_replace(pagesections[[sectionnum]], tmpsections[[sectionnum]])

    }

    # Rewrite to the html file
    xml2::write_html(pagehtml, pagepath)

    # Try and open the page
    if (openpage) {
        open_webpage(pagepath, make.front = FALSE)
    }

}
