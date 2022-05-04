
# Open a file
#' @export
file.open <- function(path){
    system2("open", shQuote(normalizePath(path)))
}

#' @export
openwd <- function(){
    file.open(getwd())
}

#' @export
restart <- function(command = ""){
    rstudioapi::restartSession(command)
}

# Make a safe file name from text
make.safename <- function(x){
    tolower(gsub(".", "_", make.names(x), fixed = TRUE))
}

# Get current project information
project.info <- function(path = NULL){
    if(is.null(path)) path <- rstudioapi::getActiveProject()
    list(
        directory = basename(normalizePath(path)),
        title     = readLines(file.path(path, ".title"))
    )
}

# Get the labbook title from the index page
getLabbookName <- function(index_path){
    index <- xml2::read_html(index_path)
    titlenode <- xml2::xml_find_first(index, "//head/title")
    xml2::xml_text(titlenode)
}

# Get intermediate directories
intermediate.dirs <- function(dir, parent){

    dirs <- c()
    while(dirname(dir) != normalizePath(parent)){
        dirs <- c(dirs, basename(dirname(dir)))
        dir  <- dirname(dir)
        if(dirname(dir) == "/") {
            stop(sprintf("%s is not a subdirectory of %s", dir, parent))
        }
    }
    rev(dirs)

}

# Function for viewing webpage associated with current code document
open_webpage <- function(html_path, make.front = TRUE){

    if(missing(html_path)) {
        doc_info  <- rstudioapi::getActiveDocumentContext()
        code_path <- doc_info$path
        html_path <- gsub("\\.R$", ".html", code_path)
        html_path <- gsub("/code/", "/pages/", html_path)
    }

    # Set args
    if(make.front) additional.args = NULL
    else           additional.args = "-g"

    # Escape special characters
    tryCatch(
        expr  = {

            # Mac
            system2(
                command = "open",
                args = c(
                    shQuote(additional.args),
                    shQuote(path.expand(html_path))
                ),
                wait = FALSE
            )
        },
        error = function(e){

            tryCatch(
                expr  = {

                    # Linux
                    system2(
                        command = "xdg-open",
                        args = shQuote(path.expand(html_path)),
                        wait = FALSE
                    )
                },
                error = function(e){

                    # Windows
                    system2("start", shQuote(path.expand(html_path)))

                }
            )

        }
    )

}

#' @export
cat.link <- function(link, text = NULL){
    if(is.null(text)) text <- basename(link)
    htmltools::a(
        href = file.path("..", link),
        text
    )
}

# Make a unique page id
make_page_id <- function(){
    hexdec <- c(letters, 0:9)
    paste(sample(hexdec, 12, replace = T), collapse = "")
}

get.codefile.depth = function(path){
    path_split = stringr::str_split(path, stringr::fixed('/'))[[1]]
    which(rev(path_split) == 'code') - 2
}
