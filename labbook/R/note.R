
#' Render a new note
#' @export
render.note <- function(
    notepath = NULL,
    pagepath = NULL,
    pagelink = NULL,
    project.path = NULL,
    add_index_link = TRUE,
    notetitle = NULL,
    openpage = FALSE,
    headcontent = NULL,
    headercontent = NULL
){

    # Set default codepath
    if(is.null(notepath)){
        notepath <- rstudioapi::getActiveDocumentContext()$path
    }

    # Exit if no valid codepath found
    if(notepath == "") return()

    # Get default project dir
    if(is.null(project.path)) project.path <- rstudioapi::getActiveProject()

    # Parse code path
    notepath   <- normalizePath(notepath)
    notename   <- basename(notepath)
    notedir    <- dirname(notepath)
    index_path <- file.path(project.path, "..", "..", "index.html")

    # Set default pagepath
    if(is.null(pagepath)){
        pagename <- gsub("\\.md$", ".html", notename)
        pagepath <- file.path(project.path, "pages", pagename)
    }

    # Preprocess note
    notemd <- tempfile(fileext = "Rmd")
    note <- preprocess_notefile(
        notefile   = notepath,
        outputfile = notemd,
        notetitle  = notetitle
    )

    # Set header content
    if(is.null(headercontent)){
        interdirs <- intermediate.dirs(
            dir    = notepath,
            parent = file.path(project.path, "notes")
        )
        headercontent <- sprintf("<a class='headerlink' href='%s'>Open note</a>", file.path("..", file.path("notes", interdirs)))
    }

    # Knit the page
    knit_markdown(
        markdown_file = notemd,
        output_file   = pagepath,
        project_path  = project.path,
        index_path    = index_path,
        page_title    = note$title,
        eval          = FALSE,
        codetoggle    = FALSE,
        headcontent   = headcontent,
        headercontent = headercontent
    )

    # Try and open the page
    if(openpage){
        open_webpage(pagepath, make.front = FALSE)
    }

    # Update the index page
    if(add_index_link){

        # Get any intermediate directories
        interdirs <- intermediate.dirs(
            dir    = notepath,
            parent = file.path(project.path, "notes")
        )
        interdirs <- paste(
            interdirs,
            collapse = " / "
        )

        addIndexPageLink(
            index_path    = index_path,
            project_title = readLines(file.path(project.path, ".title")),
            page_title    = paste(c(interdirs, note$title), collapse = " / "),
            page_subtitle = "Notes",
            page_link     = file.path("projects", basename(normalizePath(project.path)), "pages", basename(pagepath)),
            overwrite     = TRUE,
            subtitlepos   = "top"
        )

    }

}


# Preprocessing a note file for rendering
preprocess_notefile <- function(
    notefile,
    outputfile,
    notetitle = NULL
){

    # Read the note file
    notetext   <- readLines(notefile)

    # Get the note title
    if(is.null(notetitle)){
        for(notelinenum in seq_along(notetext)){
            noteline <- notetext[notelinenum]
            if(substr(trimws(noteline), 1, 2) == "# "){
                notetitle <- substr(trimws(noteline), 3, nchar(trimws(noteline)))
                notetext <- notetext[-notelinenum]
                break
            }
        }
    }
    if(is.null(notetitle)) stop("Please give the note a title")

    # Write the note output
    writeLines(
        text = c(
            "---",
            paste0('title: "', notetitle, '"'),
            "---",
            notetext
        ),
        con = outputfile
    )

    # Return the note title
    list(
        title = notetitle
    )

}
