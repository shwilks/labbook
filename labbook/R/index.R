
# Read the index file
read_index <- function(index_path){
    xml2::read_html(index_path)
}

# Write the index file
write_index <- function(index, index_path, format = TRUE){
    xml2::write_html(index, index_path, options=c("format_whitespace", "format"))
}

# Format the index
format_index <- function(index_path){
    prettyindex <- system2(
        command = "prettier",
        args    = c("--print-width 400", index_path),
        stdout  = TRUE
    )
    writeLines(prettyindex, index_path)
}

# Get a project
get_index_project <- function(index, project_title){
    xml2::xml_parent(
        xml2::xml_find_first(
            index,
            sprintf("//section[@id='projects']/div[@class='project']/h3[text()='%s']", project_title)
        )
    )
}

# Get the project section
get_index_project_section <- function(index){
    xml2::xml_find_first(index, "//section[@id='projects']")
}

# Add a project section
add_index_project <- function(index, project_title, project_dir){
    project_section <- get_index_project_section(index)
    project_node <- xml2::xml_add_child(
        project_section,
        "div",
        class = "project",
        id = basename(project_dir)
    )
    xml2::xml_add_child(
        project_node,
        "h3",
        project_title
    )
}



# Add a page link to the project section
add_project_pagelink <- function(projectnode,
                                 subtitle,
                                 page_title,
                                 page_link,
                                 page_version = NULL,
                                 subtitlepos  = "bottom"){

    # Get the subtitle node
    titlenode <- getSubtitleNode(projectnode, subtitle)

    # Add the subtitle node if not found
    if(length(titlenode) == 0) titlenode <- addSubtitleNode(projectnode, subtitle, subtitlepos)

    # Get links under the subtitle
    linknodes <- getSubtitleLinks(projectnode, subtitle)

    # Work out sibling node
    if(length(linknodes) == 0) siblingnode <- titlenode
    else                       siblingnode <- linknodes[length(linknodes)]

    # Set attributes
    node_attributes <- list(
        siblingnode, "a", page_title,
        href   = page_link,
        .where = "after"
    )

    # Deal with page versions
    if(!is.null(page_version)){

        # Add a version attribute
        node_attributes$version <- page_version

    }

    # Add the node
    newnode <- do.call(xml2::xml_add_sibling, node_attributes)
    if(class(newnode) == "list") newnode <- newnode[[1]]

    # Check for other versions of the page
    for(linknode in linknodes){
        if(xml2::xml_text(linknode) == page_title){

            # If no version is found make it 0
            if(is.na(xml2::xml_attr(linknode, "version"))){
                xml2::xml_attr(linknode, "version") <- "0"
            }

            # Label other links as other versions
            xml2::xml_attr(linknode, "class") <- "alt-page-version"

            # Move the link below the newly added one
            xml2::xml_add_sibling(
                newnode,
                linknode,
                .copy = FALSE
            )

        }
    }

}


# Remove a project page link
remove_project_pagelink <- function(projectnode, page_link){

    xml2::xml_remove(
        xml2::xml_find_all(projectnode, sprintf("a[@href='%s']", page_link))
    )

}


# Get a subtitle node
getSubtitleNode <- function(projectnode,
                            subtitle){

    if(is.null(subtitle)){
        subtitlenode <- xml2::xml_find_first(projectnode, "h3")
    } else {
        subtitlenode <- xml2::xml_find_first(projectnode, paste0("h4[text() = '", subtitle,"']"))
    }
    subtitlenode

}


# Get all subtitle nodes
getSubtitleNodes <- function(projectnode){

    xml2::xml_find_all(projectnode, paste0("h4"))

}


# Get subtitle nodes
getSubtitleLinks <- function(projectnode,
                             subtitle = NULL){

    if(is.null(subtitle)){
        xml2::xml_find_all(projectnode, paste0("a[count(preceding-sibling::h4) = 0]"))
    } else {
        xml2::xml_find_all(projectnode, paste0("a[preceding-sibling::h4[1][text() = '", subtitle,"']]"))
    }

}


# Make a subtitle node
addSubtitleNode <- function(projectnode,
                            subtitle,
                            subtitlepos = "bottom"){

    if(subtitlepos == "bottom"){
        xml2::xml_add_child(projectnode, "h4", subtitle)
    } else if(subtitlepos == "top"){
        projecttitlenode <- xml2::xml_find_first(projectnode, "h3")
        xml2::xml_add_sibling(
            projecttitlenode,
            "h4",
            subtitle
        )
    } else {
        stop("subtitlepos must be one of 'bottom' or 'top'")
    }

}


# Add a link to the index page
addIndexPageLink <- function(
    index_path,
    project_title,
    page_title,
    page_subtitle,
    page_link,
    page_version = NULL,
    overwrite = TRUE,
    subtitlepos = "bottom"
){

    index   <- read_index(index_path)
    project <- get_index_project(index, project_title)

    if(overwrite){
        remove_project_pagelink(
            projectnode = project,
            page_link   = page_link
        )
    }

    add_project_pagelink(
        projectnode  = project,
        subtitle     = page_subtitle,
        page_title   = page_title,
        page_link    = page_link,
        page_version = page_version,
        subtitlepos  = subtitlepos
    )

    write_index(index, index_path)

}

# Update a project node todo div
update_project_todo <- function(
    projectnode,
    todo,
    todolink
){

    # Remove the current todo
    xml2::xml_remove(
        xml2::xml_find_first(projectnode, "div[@class='todo']")
    )

    # Add new todo
    if(length(todo) > 0){

        todonode <- xml2::xml_add_child(
            projectnode,
            "a",
            length(todo),
            href = todolink,
            class = "todo",
            .where = 0
        )

    }

}

# Update the index todo for a project
updateIndexToDo <- function(
    index_path,
    project_title,
    todo,
    todolink
){

    index   <- read_index(index_path)
    project <- get_index_project(index, project_title)
    update_project_todo(
        projectnode = project,
        todo        = todo,
        todolink    = todolink
    )
    write_index(index, index_path)

}


