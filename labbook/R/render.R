

chunk_start <- "```{r}"
chunk_end   <- "```"

# Wrap text in a code chunk
chunk_code <- function(code, args = NULL){

    paste0(
        "```\n",
        "\n```{r, ",
        paste(
            paste(names(args), args, sep = " = "),
            collapse = ", "
        )
        ,"}\n",
        code,
        "\n", chunk_end,
        "\n```{r}"
    )

}


# Start a new code chunk
new_chunk <- function(chunk.name = NULL, args){

    paste0(
        chunk_end, "\n",
        "\n```{r ", chunk.name, ", ",
        paste(
            paste(names(args), args, sep = " = "),
            collapse = ", "
        )
        ,"}"
    )

}


# Render a currently open file
render.file <- function(){

    filename <- basename(rstudioapi::getActiveDocumentContext()$path)
    if(filename == "overall-todo.md"){
        openTodo(openmd = FALSE)
    } else {
        render.page()
    }

}



# Render the page
#' @export
render.page <- function(codepath       = NULL,
                        pagepath       = NULL,
                        pagelink       = pagepath,
                        add_index_link = TRUE,
                        eval           = TRUE,
                        openpage       = TRUE,
                        verbose        = TRUE,
                        codetoggle     = TRUE,
                        standalone     = FALSE,
                        headcontent    = NULL,
                        headercontent  = NULL){

    # Set default codepath
    if(is.null(codepath)){
        codepath <- rstudioapi::getActiveDocumentContext()$path
    }

    # Exit if no valid codepath found
    if(codepath == "") return()

    # Parse code path
    codepath   <- normalizePath(codepath)
    codename   <- basename(codepath)
    codedir    <- dirname(codepath)
    projectdir <- file.path(codedir, "..")
    index_path <- file.path(codedir, "..", "..", "..", "index.html")

    # Message that knitting is in progress
    if(verbose) message("Knitting...", appendLF = FALSE)

    # Remove any current files
    pagefiledir <- paste0(substr(pagepath, 1, nchar(pagepath) - 5), "_files")
    unlink(pagefiledir, recursive = TRUE)

    # Preprocess the markdown file
    markdown_file <- tempfile(fileext = ".Rmd")
    page <- preprocess_codefile(
        code_file         = codepath,
        markdown_output   = markdown_file,
        include_code_link = !standalone
    )

    # Set default pagepath
    if(is.null(pagepath)){
        pagename <- gsub("\\.R$", ".html", codename)
        if(!is.null(page$version)){
            pagename <- gsub("\\.html$", paste0("@", page$version, ".html"), pagename)
        }
        pagepath <- file.path(codedir, "..", "pages", pagename)
    }

    # Knit the markdown file to the page output
    knit_markdown(
        markdown_file = markdown_file,
        output_file   = pagepath,
        eval          = eval,
        project_path  = projectdir,
        index_path    = index_path,
        page_title    = page$title,
        codetoggle    = codetoggle,
        headcontent   = headcontent,
        headercontent = headercontent,
        standalone    = standalone
    )

    # Try and open the page
    if(openpage){
        open_webpage(pagepath, make.front = FALSE)
    }

    # Update the index page
    if(add_index_link){

        addIndexPageLink(
            index_path    = index_path,
            project_title = readLines(file.path(projectdir, ".title")),
            page_title    = page$title,
            page_subtitle = page$subtitle,
            page_version  = page$version,
            page_link     = file.path("projects", basename(normalizePath(projectdir)), "pages", basename(pagepath)),
            overwrite     = TRUE
        )

    }

    # Message that knitting is done
    if(verbose) message("done.")

}


# Pre process a markdown file
preprocess_codefile <- function(code_file,
                                include_code_link = TRUE,
                                markdown_output,
                                eval = TRUE){

    # Parse codepath
    codepath <- normalizePath(code_file)
    codename <- basename(codepath)

    # Read code lines
    code    <- readLines(code_file)
    rawcode <- code

    # Strip empty start lines
    while(length(code) > 0 && code[1] == "") code <- code[-1]

    # Remove any inline code if not to be evaluated
    if(!eval){
        code <- gsub("\\`r .*?\\`", "`r 'placeholder'`", code)
    }

    # Find the page title and remove it
    titleline <- substr(code, 1, 4) == "###'"
    pagetitle <- code[titleline]
    pagetitle <- trimws(substr(pagetitle, 5, nchar(pagetitle)))
    code      <- code[!titleline]

    # Check page title has been given
    if(length(pagetitle) == 0) stop("Page must have a title")

    # Find the page subtitle and remove it
    subtitleline <- substr(code, 1, 3) == "##'"
    pagesubtitle <- code[subtitleline]
    pagesubtitle <- trimws(substr(pagesubtitle, 4, nchar(pagesubtitle)))
    code         <- code[!subtitleline]
    if(length(pagesubtitle) == 0) stop("Page must have a subtitle")

    # Find any page versions and remove them
    pageversionline <- substr(code, 1, 4) == "#' @"
    pageversion <- code[pageversionline]
    if(length(pageversion) == 0) {
        pageversion <- NULL
    } else {
        pageversion <- trimws(substr(pageversion, 5, nchar(pageversion)))
        code[pageversionline] <- paste0("#' <div class='page-version'>", pageversion, "</div>")
    }

    # Replace lines starting with #'
    speciallines <- grepl("^#'", code)
    commentlines <- rep(FALSE, length(speciallines))

    for(linenum in which(speciallines)){

        # Extract the comment
        linecontent <- code[linenum]
        comment     <- gsub("^#'( )*", "", linecontent)

        if(grepl("^#' \\[", linecontent)){

            # Changing figure sizes
            fig.dim   <- as.numeric(strsplit(gsub("^.*\\[(.*)\\].*$", "\\1", comment), ",")[[1]])
            fig.scale <- stringr::str_extract(comment, "\\*[0-9\\.]*")

            if(is.na(fig.scale)) fig.scale <- 1
            else                 fig.scale <- as.numeric(substr(fig.scale, 2, nchar(fig.scale)))

            # Getting and stripping the figure name
            fig.name  <- stringr::str_extract(comment, "//.*$")
            if(!is.na(fig.name)) fig.name <- trimws(substr(fig.name, 3, nchar(fig.name)))
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
            for(i in seq_along(fig.extra)){
                extra <- strsplit(fig.extra[i], "=")[[1]]
                chunk_args[extra[1]] <- extra[2]
            }

            # Output the chunk
            code[linenum] <- new_chunk(fig.name, chunk_args)

        } else {

            # Note that this line was a regular comment
            commentlines[linenum] <- TRUE

        }

    }

    # Take comments out of the code chunks
    lastlinecomment <- FALSE
    sectionnum      <- 1

    for(linenum in seq_along(commentlines)){

        # Strip the comment marks
        if(commentlines[linenum]){

            # Remove the #'
            code[linenum] <- substr(code[linenum], 4, nchar(code[linenum]))

            # Replace blank comment lines with line breaks
            if(grepl("^( ){2,}$", code[linenum])){
                code[linenum] <- "<br/>"
            }

        }

        # If starting new lines of comments
        if(commentlines[linenum] && !lastlinecomment){
            code[linenum] <- paste0(chunk_end, "\n<div class='text-section' id='text-section-", sectionnum, "'>", code[linenum])
            sectionnum <- sectionnum + 1
        }

        # If ending a line of comments
        if(!commentlines[linenum] && lastlinecomment){
            code[linenum] <- paste0("</div>\n```{r}\n", code[linenum])
        }

        # If you've reached the last line as a comment
        if(commentlines[linenum] && linenum == length(commentlines)){
            code[linenum] <- paste0(code[linenum], "</div>\n```{r}")
        }

        # Update last line was a comment
        lastlinecomment <- commentlines[linenum]

    }

    # Set the codefile link
    if(include_code_link){
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
            "```{r}",
            code,
            chunk_end,
            "</main>",
            "<footer>",
            codelink,
            "```{r class.source='code-block page-code', eval=FALSE}",
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
        version  = pageversion
    )

}


# Knit a markdown file
knit_markdown <- function(markdown_file,
                          output_file,
                          project_path,
                          index_path,
                          page_title,
                          codetoggle    = TRUE,
                          headercontent = NULL,
                          headcontent   = NULL,
                          standalone    = FALSE,
                          eval          = TRUE){

    # Set the library and cache location
    lib_dir   <- file.path(dirname(output_file), ".lib")
    # cache_dir <- gsub("\\.html$", "_cache/", output_file)

    # Get project information
    project    <- project.info(project_path)

    # Set the code link
    # codelink <- paste0("<a id='code-download-link' href='", file.path("..", "code", codename),"'>Download code</a>")

    # "```{r class.source='code-block page-code', eval=FALSE}",
    # rawcode,
    # "```"

    # Generate header file
    header_file <- tempfile()
    if(is.null(headcontent)){
        if(standalone){
            headcontent <- c(
                sprintf('<script src="%s"></script>', normalizePath(file.path(project_path, ".lib", "scripts", "jquery.min.js"))),
                sprintf('<script src="%s"></script>', normalizePath(file.path(project_path, ".lib", "scripts", "page.js")))
            )
        } else {
            headcontent <- c(
                '<link href="../.lib/styles/general.css" rel="stylesheet"/>',
                '<link href="../.lib/styles/shared.css" rel="stylesheet"/>',
                '<link href="../.lib/styles/page.css" rel="stylesheet"/>',
                '<script src="../.lib/scripts/jquery.min.js"></script>',
                '<script src="../.lib/scripts/page.js"></script>'
            )
        }
    }
    writeLines(
        text = headcontent,
        con  = header_file
    )

    # Set code toggle
    if(codetoggle){ codetogglediv <- "<div class='headerlink' id='codetoggle'></div>" }
    else          { codetogglediv <- NULL                          }

    # Generate header file
    before_body_file <- tempfile()
    labbook_name     <- getLabbookName(index_path)

    if(standalone){

        writeLines(
            text = c(
                "<header>",
                codetogglediv,
                headercontent,
                "</header>",
                "<main>"
            ),
            con = before_body_file
        )

    } else {

        writeLines(
            text = c(
                "<header>",
                "<div id='page-header'>",
                sprintf(
                    '<div><a href="%1$s">%5$s</a> / <a href="%1$s#%2$s">%3$s</a> / %4$s</div>',
                    index_path,
                    project$directory,
                    project$title,
                    page_title,
                    labbook_name
                ),
                "</div>",
                codetogglediv,
                headercontent,
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
    if(standalone){
        css <- c(
            file.path(project_path, ".lib", "styles", "general.css"),
            file.path(project_path, ".lib", "styles", "shared.css"),
            file.path(project_path, ".lib", "styles", "page.css")
        )
        output_format <- eval(substitute(
            rmarkdown::html_document(
                highlight = "default",
                theme = NULL,
                self_contained = TRUE,
                mathjax = "default",
                section_divs = TRUE,
                css = css,
                includes = rmarkdown::includes(
                    in_header   = header_file,
                    before_body = before_body_file,
                    after_body  = after_body_file
                ),
            )
        ))
    } else {
        output_format <- eval(substitute(
            rmarkdown::html_document(
                highlight = "default",
                theme = NULL,
                self_contained = FALSE,
                lib_dir = lib_dir,
                includes = rmarkdown::includes(
                    in_header   = header_file,
                    before_body = before_body_file,
                    after_body  = after_body_file
                ),
                mathjax = "local",
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
    output_format$knitr$opts_chunk$fig.keep      = 'high'
    output_format$knitr$opts_chunk$message       = FALSE
    output_format$knitr$opts_chunk$warning       = FALSE
    output_format$knitr$opts_chunk$eval          = eval
    output_format$knitr$opts_chunk$subchunk      = TRUE
    output_format$knitr$opts_chunk$comment       = NA
    output_format$knitr$opts_chunk$results       = "asis"
    # output_format$knitr$opts_chunk$cache      = TRUE
    # output_format$knitr$opts_chunk$cache.path = cache_dir

    # Set hook for numbering subchunks
    output_format$knitr$knit_hooks$subchunk <- function(before, options, envir){

        if(before){
            envir$`.subChunkNum`   <- 0
            envir$`.chunk-label`   <- options$label
            return(NULL)
        }

    }

    # Custom hook for inline output
    output_format$knitr$knit_hooks$inline <- function(x){
        if(grepl("\n", x)){
            return(paste0("<div class='inline-output'>", x, "</div>"))
        } else {
            return(paste0("<span class='inline-output'>", x, "</span>"))
        }
    }

    # Render the html page
    rmarkdown::render(
        input = markdown_file,
        output_format = output_format,
        output_file = output_file,
        quiet = TRUE,
        knit_root_dir = getwd(),
        envir = new.env()
    )

}


#' @export
rerendertext <- function(codepath = NULL,
                         pagepath = NULL,
                         openpage = TRUE){

    # Set default codepath
    if(is.null(codepath)){
        codepath <- rstudioapi::getActiveDocumentContext()$path
    }

    # Exit if no valid codepath found
    if(codepath == "") return()

    codename <- basename(codepath)
    codedir  <- dirname(codepath)

    # Set default pagepath
    if(is.null(pagepath)){
        pagename <- gsub("\\.R$", ".html", codename)
        pagepath <- file.path(codedir, "..", "pages", pagename)
    }

    tmppage <- tempfile()
    renderpage(
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

    if(length(pagesections) != length(tmpsections)){
        stop("Cannot perform automatic section matching, please rerender the page.")
    }

    # Replace each text section with the new text
    for(sectionnum in seq_along(pagesections)){

        pagesection <- pagesections[[sectionnum]]
        tmpsection  <- tmpsections[[sectionnum]]

        # Count any inline code outputs
        xpath <- "//*[@class='inline-output']"
        pagesection_inlinenodes <- xml2::xml_find_all(pagesection, xpath)
        tmpsection_inlinenodes  <- xml2::xml_find_all(tmpsection,  xpath)

        # Replace the inline nodes with those from the original page
        if(length(pagesection_inlinenodes) != length(tmpsection_inlinenodes)){
            stop("Cannot perform automatic section matching, please rerender the page.")
        }

        for(nodenum in seq_along(pagesection_inlinenodes)){

            if(xml2::xml_name(pagesection_inlinenodes[[nodenum]]) == "span"){

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
    for(sectionnum in seq_along(pagesections)){

        # Now replace the original text node
        xml2::xml_replace(pagesections[[sectionnum]], tmpsections[[sectionnum]])

    }

    # Rewrite to the html file
    xml2::write_html(pagehtml, pagepath)

    # Try and open the page
    if(openpage){
        labBook:::open_webpage(pagepath, make.front = FALSE)
    }

}

# renderpage(
#   codepath = "~/Dropbox/LabBook/flu_b_landscapes/code/mean_titers_treated.R",
#   pagepath = "~/Dropbox/LabBook/flu_b_landscapes/pages/mean_titers_treated.html"
# )








