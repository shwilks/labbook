
#' Initiate a new labbook
#'
#' @param labbook.dir The directory in which to create the labbook (defaults to the current working directory)
#' @param labbook.title The name for the labbook (e.g. "Sam's labbook")
#' @param project.title The name for the first project
#'
#' @export
#'
labbook.init <- function(
    labbook.dir,
    labbook.title,
    project.title
){

    # Check args
    if(missing(labbook.title)) stop("Please enter a name for the labbook")
    if(missing(project.title)) stop("Please enter a name for the first project")

    # Create the directory
    labbook.path <- file.path(labbook.dir, "labbook")
    if(file.exists(labbook.path)) stop("A labbook directory already exists at this location")
    dir.create(labbook.path)

    # Copy the library folder
    file.copy(
        from = system.file("labbook/library", package = "labbook"),
        to   = labbook.path,
        recursive = TRUE
    )

    # Create the project folder
    dir.create(file.path(labbook.path, "projects"))

    # Create the overall todo folder
    dir.create(file.path(labbook.path, "todo"))
    writeLines("", file.path(labbook.path, "todo", "overall-todo.md"))

    # Create the index page
    index <- xml2::read_html(system.file("labbook/index.html", package = "labbook"))

    ## Rename main title
    maintitle <- xml2::xml_find_first(index, "//div[@class='main-title']")
    xml2::xml_text(maintitle) <- labbook.title

    ## Rename page title
    pagetitle <- xml2::xml_find_first(index, "//title")
    xml2::xml_text(pagetitle) <- labbook.title

    ## Rename breadcrumbs
    breadcrumbs <- xml2::xml_find_first(index, "//div[@id='page-header']")
    xml2::xml_text(breadcrumbs) <- labbook.title

    ## Write the index page
    xml2::write_html(index, file.path(labbook.path, "index.html"))

    ## Create the first project
    labbook.newProject(
        project.title = project.title,
        labbook.path  = labbook.path
    )

}


#' Create a new labbook project
#'
#' @param project.title The project title
#' @param project.dir The name of the project directory
#' @param labbook.path The path to the labbook
#'
#' @export
#'
labbook.newProject <- function(
    project.title,
    project.dir = NULL,
    labbook.path
){

    # Check args
    if(is.null(project.dir)) project.dir <- make.safename(project.title)

    # Create the project dir
    project_path <- file.path(labbook.path, "projects", project.dir)
    dir.create(project_path)

    # Create a record of the title
    writeLines(project.title, file.path(project_path, ".title"))

    # Create code and page and data dirs
    dir.create(file.path(project_path, "code"))
    dir.create(file.path(project_path, "pages"))
    dir.create(file.path(project_path, "data"))
    dir.create(file.path(project_path, "notes"))
    dir.create(file.path(project_path, "todo"))

    # Create a .lib directory that is a symbolic link to the main library
    # (this allows you to grant access to only a single project directory if you wish)
    file.symlink(
        from = file.path("..", "..", "library"),
        to   = file.path(project_path, ".lib")
    )

    # Similarly create a symbolic link to the shared .Renviron file
    file.symlink(
        from = file.path("..", "..", "library", ".Renviron"),
        to   = file.path(project_path, ".Renviron")
    )

    # Create the project
    rstudioapi::initializeProject(project_path)

    # Add a project section
    index_path <- file.path(project_path, "..", "..", "index.html")
    index <- read_index(index_path)
    add_index_project(index, project.title, project.dir)
    write_index(index, index_path)

}



#' Create a new labbook page
#'
#' @param project.dir
#'
#' @export
labbook.newPage <- function(
    filename,
    project.dir = NULL,
    openfile = TRUE,
    overwrite = FALSE
){

    # Check for filename
    if(missing(filename)) {
        stop("Please provide a filename")
    }

    # Work out the project directory
    if(is.null(project.dir)) {
        project.dir <- rstudioapi::getActiveProject()
    }

    # Check if file already exists
    filepath <- file.path(project.dir, "code", filename)
    if(file.exists(filepath) & !overwrite){
        stop(sprintf("File '%s' already exists", filename))
    }

    # Copy from template if provided or if not create basic file
    if(file.exists(file.path(project.dir, "code", "_template.R"))){
        file.copy(
            from = file.path(project.dir, "code", "_template.R"),
            to   = file.path(project.dir, "code", filename),
            overwrite = overwrite
        )
    } else {
        writeLines(
            c("",
              "##' Subtitle",
              "###' Page title",
              "",
              "# Setup workspace",
              "rm(list = ls())"),
            filepath
        )
    }

    # Open the new file
    if(openfile) file.edit(filepath)

    # Return the file path silently
    invisible(filepath)

}

#' @export
labbook_newpage <- function(openfile = TRUE) {

    index <- read_index("../../index.html")
    project <- get_index_project(index, readLines(".title"))
    subtitles <- vapply(getSubtitleNodes(project), xml2::xml_text, character(1))

    # Get page title
    cat("\n")
    page_title <- trimws(readline("Page title: "))
    if (page_title == "") return()
    page_title_safe <- make.safename(page_title)

    # Get page subtitle
    print(unname(data.frame(subtitles)))
    cat("\n")
    page_subtitle <- trimws(readline("Subtitle: "))
    if (page_subtitle == "") return()
    subtitle_index <- suppressWarnings(as.numeric(page_subtitle))
    if (!is.na(subtitle_index)) page_subtitle <- subtitles[subtitle_index]

    # Write the page template
    output <- c(
        "",
        paste("##'", page_subtitle),
        paste("###'", page_title),
        "",
        "# Setup workspace",
        "rm(list = ls())",
        "library(labbook)",
        ""
    )

    # Create the file
    filepath <- file.path("code", paste0(page_title_safe, ".R"))
    writeLines(output, filepath)

    # Open the new file
    if(openfile) file.edit(filepath)
    # rstudioapi::navigateToFile(filepath)

    # Return the file path silently
    invisible(filepath)

}

#' @export
labbook_clone_page <- function(ext = "_v2") {
    path <- rstudioapi::getSourceEditorContext()$path
    lines <- readLines(path)
    lines[grep("###'", lines)] <- paste0(lines[grep("###'", lines)], ext)_v2
    newpath <- gsub("\\.([Rr])$", paste0(ext, ".\\1"), path)
    writeLines(lines, newpath)
    file.edit(newpath)
}

#' @export
labbook_merge_subtitles <- function(
    subtitle_from,
    subtitle_into
    ) {

    # Set variables
    project_title <- readLines(".title")
    index_path <- "../../index.html"

    # Get the index
    index <- read_index(index_path)

    # Get the project node
    projectnode <- get_index_project(index, project_title)

    # Get the subtitle 1 node to move from
    titlenode1 <- getSubtitleNode(projectnode, subtitle_from)
    if(length(titlenode1) == 0) stop("Subtitle not found")
    linknodes1 <- getSubtitleLinks(projectnode, subtitle_from)

    # Get the subtitle 2 node to move to
    titlenode2 <- getSubtitleNode(projectnode, subtitle_into)
    if(length(titlenode2) == 0) stop("Subtitle not found")
    linknodes2 <- getSubtitleLinks(projectnode, subtitle_into)

    # Work out sibling node from the second subtitle
    if(length(linknodes2) == 0) {
        siblingnode2 <- titlenode2
    } else {
        siblingnode2 <- linknodes2[length(linknodes2)]
    }

    # Move all the sibling nodes from 1 to 2
    lapply(rev(linknodes1), \(node) xml2::xml_add_sibling(siblingnode2, node, .copy = FALSE))

    # Remove the subtitle title node
    xml2::xml_remove(titlenode1)

    # Rewrite the index
    write_index(index, index_path)

}


#' @export
labbook_list_subtitles <- function() {

    index <- read_index("../../index.html")
    project <- get_index_project(index, readLines(".title"))
    subtitles <- vapply(getSubtitleNodes(project), xml2::xml_text, character(1))
    print(unname(data.frame(subtitles)))

}


