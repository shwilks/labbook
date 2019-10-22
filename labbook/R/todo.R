
#' Render a new todo
#' @export
render.todo <- function(
    todopath = NULL,
    pagepath = NULL,
    pagelink = NULL,
    project.path = NULL,
    add_index_link = TRUE,
    update_index_todo = TRUE,
    openpage = FALSE,
    headcontent = NULL
){

    render.note(
        notepath = todopath,
        pagepath = pagepath,
        pagelink = pagelink,
        project.path = project.path,
        add_index_link = FALSE,
        notetitle = "To do",
        openpage = openpage,
        headcontent = headcontent,
        headercontent = sprintf("<a class='headerlink' href='%s'>Open todo</a>", file.path("..", "todo"))
    )

    todos <- trimws(readLines(todopath))
    todos <- substr(todos, 3, nchar(todos))

    if(update_index_todo){
        updateIndexToDo(
            index_path    = file.path(project.path, "..", "..", "index.html"),
            project_title = readLines(file.path(project.path, ".title")),
            todo          = todos,
            todolink      = file.path("projects", basename(project.path), "pages", "todo.html")
        )
    }

}

# Parse the overall todo file
parseOverallTodo <- function(todopath){

    todocontent  <- list()
    todolines    <- readLines(todopath)
    todosubtitle <- NULL

    for(linenum in seq_along(todolines)){

        todoline <- trimws(todolines[linenum])
        if(substr(trimws(todoline), 1, 2) == "# "){
            todosubtitle <- substr(todoline, 3, nchar(todoline))
        } else {
            if(todoline != ""){
                todocontent[[todosubtitle]] <- c(todocontent[[todosubtitle]], gsub("^[-*] ", "", todoline))
            }
        }

    }

    todocontent

}


# Render the overall todo
render.overalltodo <- function(
    todopath = NULL,
    index.path = NULL,
    openpage = FALSE
){

    # Set index path
    if(is.null(index.path)) index.path <- file.path(dirname(todopath), "..", "..", "index.html")

    index <- read_index(index.path)
    project_section_node <- get_index_project_section(index)

    # Remove any current node
    overall_todo_node <- xml2::xml_find_first(project_section_node, "div[@id='overall-todo']")
    xml2::xml_remove(overall_todo_node)

    # Add in the new node
    overall_todo_node <- xml2::xml_add_child(
        project_section_node,
        "div",
        id = "overall-todo",
        .where = 0
    )

    # Parse the overall todo
    overall_todo_content <- parseOverallTodo(todopath)
    for(x in seq_along(overall_todo_content)){
        xml2::xml_add_child(
            overall_todo_node,
            "div",
            length(overall_todo_content[[x]]),
            class = "overall-todo-badge",
            title = names(overall_todo_content[x])
        )
    }

    # Write the index
    write_index(index, index.path)

    # Set the pagehead content
    headcontent <- c(
        '<link href="../library/styles/general.css" rel="stylesheet"/>',
        '<link href="../library/styles/shared.css" rel="stylesheet"/>',
        '<link href="../library/styles/page.css" rel="stylesheet"/>',
        '<link href="../library/styles/todo.css" rel="stylesheet"/>',
        '<script src="../library/scripts/jquery.min.js"></script>',
        '<script src="../library/scripts/page.js"></script>'
    )

    # Write the todo page
    render.todo(
        todopath = todopath,
        pagepath = file.path(normalizePath(dirname(todopath)), "overall-todo.html"),
        add_index_link = FALSE,
        update_index_todo = FALSE,
        openpage = openpage,
        headcontent = headcontent
    )

}


#' Open the todo page
#'
#' Render and open the overall todo page
#'
#' @param todopath The path to the todo file
#'
#' @export
#'
openTodo <- function(openmd = TRUE, todopath = NULL){

    if(is.null(todopath)){
        todopath <- file.path(
            rstudioapi::getActiveProject(),
            "..", "..", "todo", "overall-todo.md"
        )
    }

    render.overalltodo(
        todopath   = todopath,
        openpage   = TRUE,
        index.path = file.path(dirname(todopath), "..", "index.html")
    )

    if(openmd){
        file.edit(todopath)
    }

}


