
index_pages <- function(){

    index <- xml2::read_html("../../index.html")
    pathprojects <- list.files("../../projects/", full.names = T)
    page_index <- lapply(pathprojects, function(pathproject){

        project <- basename(pathproject)
        message("\n")
        message(project)
        pathpages <- list.files(file.path(pathproject, "pages"), full.names = T)
        pathpages <- pathpages[grepl("\\.html$", pathpages)]

        pagescontent <- lapply(pathpages, function(pathpage){

            page <- basename(pathpage)
            message(page)
            pageinfo <- file.info(pathpage)
            href <- paste0("projects/", project, "/pages/", page)
            page_title <- xml2::xml_text(
                xml2::xml_find_first(index, paste0("//section[@id='projects']/div/a[@href='", href,"']"))
            )

            if(is.na(page_title)){
                page_title <- ""
            }

            if(pageinfo$size > 1e7){
                warning(sprintf("Skipped page '%s'", page), call. = FALSE, immediate. = TRUE)
                content <- list()
                code <- list()
            } else {
                tryCatch({

                    # Read content
                    html       <- xml2::read_html(pathpage)
                    pnodes     <- xml2::xml_find_all(html, "//p")
                    pnodeslist <- xml2::as_list(pnodes)
                    pnodestext <- lapply(pnodeslist, function(x){
                        paste0(unlist(x), collapse = "")
                    })
                    excluded <- pnodestext == "Download code" | pnodestext == ""
                    content <- pnodestext[!excluded]

                    # Read code
                    codenode <- xml2::xml_find_all(html, "//pre[contains(concat(' ', @class, ' '), ' page-code ')]")
                    code <- strsplit(xml2::xml_text(codenode), "\\n")[[1]]

                }, error = function(e){
                    warning(sprintf("When indexing pages, unable to parse page '%s'", page), call. = FALSE)
                    content <- list()
                    code <- list()
                })

            }

            list(
                page_path  = basename(pathpage),
                page_title = page_title,
                mtime      = as.character(as.Date(pageinfo$mtime)),
                content    = content,
                code       = code
            )

        })

        # contentlength <- sapply(pagescontent, function(x){ length(x$content) })
        # pagescontent  <- pagescontent[contentlength > 0]

        list(
            project_path  = basename(pathproject),
            project_title = readLines(file.path(pathproject, ".title")),
            pages         = pagescontent
        )

    })

    # Output file
    jsonoutput <- jsonlite::toJSON(page_index, auto_unbox = T)
    jsonoutput <- gsub("\\", "\\\\", jsonoutput, fixed = T)
    jsonoutput <- gsub("`", "\\`", jsonoutput, fixed = T)

    cat(
        sprintf("var pageindex = `%s`", jsonoutput),
        file = "../../library/docs/pageindex.js"
    )

}
