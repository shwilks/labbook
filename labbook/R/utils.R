
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
    # html_path <- gsub("(\\(|\\))", "\\\\\\1", html_path)
    tryCatch(
        expr  = { system2("open", args = c(additional.args, html_path)) },
        error = function(e){ system2("start", html_path) }
    )
}


#' Edit the current labbook page open in safari
#' @export
edit_safaripage <- function(labbook_path = NULL){

    safaripage <- system2(
        command = "osascript",
        input = c(
            'tell application "Safari"',
            'set vURL to URL of current tab of window 1',
            'end tell'
        ),
        stdout = TRUE
    )

    if(is.null(labbook_path)){
        labbook_path <- normalizePath(file.path(rstudioapi::getActiveProject(), "..", ".."))
    }

    labbook_url <- paste0("file://", labbook_path)
    if(substr(safaripage, 1, nchar(labbook_url)) != labbook_url){
        stop(sprintf("Page '%s' is not a local labbook page", safaripage))
    }

    # Strip the file://
    safaripage <- substr(safaripage, 8, nchar(safaripage))
    if(basename(dirname(safaripage)) != "pages"){
        stop(sprintf("Page '%s' is not a local labbook page", safaripage))
    }

    # Get the page name
    pagename <- basename(safaripage)
    codename <- gsub("\\.html$", ".R", pagename)
    codepath <- normalizePath(
        file.path(
            dirname(safaripage),
            "..", "code",
            codename
        )
    )

    # Open the code file
    file.edit(codepath)

}

# List all open RStudio projects
list_open_projects <- function(){

    system2(
        command = "osascript",
        input = c(
            'tell application "System Events" to get the name of every window of (every process whose background only is false and name is "RStudio")'
        ),
        stdout = TRUE
    )
}
