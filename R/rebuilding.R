symlink_project_libs <- function(labbook_path = "../../") {
  projects <- list.dirs(
    file.path(labbook_path, "projects"),
    recursive = FALSE
  )

  for (project in projects) {
    unlink(
      file.path(project, ".lib"),
      recursive = TRUE
    )

    file.symlink(
      from = "../../library",
      to = file.path(project, ".lib")
    )
  }
}

# Rebuild the index file based on the current projects
rebuild_index <- function(labbook_path = "../../") {
  # Read the index file
  index_path <- file.path(labbook_path, "index.html")
  index_old <- read_index(index_path)
  index_new <- read_index(index_path)

  # Read the current project order from the index file
  project_order <- getProjectNodes(index_old) |> sapply(getProjectNodeTitle)

  # List all the projects and determine ordering
  project_dirs <- list.dirs(
    file.path(labbook_path, "projects"),
    recursive = FALSE
  )

  project_titles <- sapply(project_dirs, function(project_dir) {
    readLines(file.path(project_dir, ".title"))
  })

  project_order <- c(
    project_order[project_order %in% project_titles],
    project_titles[!project_titles %in% project_order]
  )

  names(project_order) <- names(project_titles)[match(
    project_order,
    project_titles
  )]

  # Get the project section
  project_section_old <- get_index_project_section(index_old)
  project_section_new <- get_index_project_section(index_new)

  # Copy the index html and remove all the projects from the copy
  xml2::xml_remove(xml2::xml_children(project_section_new))

  # Add back in the project index div
  xml2::xml_add_child(project_section_new, "div", id = "project-index")

  # Add back in the projects in the correct order
  for (project_title in project_order) {
    project_dir <- names(project_order)[project_order == project_title]
    add_index_project(index_new, project_title, project_dir)

    # Read all the code files in the project (must be .r or .R or .py)
    code_files <- list.files(
      file.path(project_dir, "code"),
      pattern = "\\.r$|\\.R$|\\.py$"
    )
    page_files <- list.files(
      file.path(project_dir, "pages"),
      pattern = "\\.html$"
    )

    # Order the page and code files based on the last modified time
    page_files <- page_files[order(file.mtime(file.path(
      project_dir,
      "pages",
      page_files
    )))]

    code_files <- code_files[order(file.mtime(file.path(
      project_dir,
      "code",
      code_files
    )))]

    # Read all the subtitles in the index file for that project
    project_node_old <- get_index_project(index_old, project_title)
    project_node_new <- get_index_project(index_new, project_title)
    project_subtitles <- getSubtitleNodes(project_node_old) |>
      sapply(xml2::xml_text)

    original_page_links <- getPageLinkNodes(project_node_old) |>
      sapply(xml2::xml_attr, "href")
    new_page_links <- c()

    # Add back in the subtitles in the correct order
    for (subtitle in project_subtitles) {
      addSubtitleNode(project_node_new, subtitle)
    }

    for (code_file in code_files) {
      tryCatch(
        {
          # Extract the page title and subtitle from the code file
          page <- preprocess_codefile(
            code_file = file.path(project_dir, "code", code_file)
          )

          # Determine the page link
          page_link <- file.path(
            "projects",
            basename(project_dir),
            "pages",
            paste0(tools::file_path_sans_ext(code_file), ".html")
          )

          # Check the page exists
          if (file.exists(file.path(labbook_path, page_link))) {
            # Record new page link
            new_page_links <- c(new_page_links, page_link)

            # Add the page link to the index
            add_project_pagelink(
              projectnode = project_node_new,
              subtitle = page$subtitle,
              page_title = page$title,
              page_link = page_link
            )
          }

          # Add a link to the code file
          add_project_codelink(
            projectnode = project_node_new,
            subtitle = page$subtitle,
            page_title = sprintf("%s - %s", page$title, code_file),
            page_link = file.path(
              "projects",
              basename(project_dir),
              "code",
              code_file
            )
          )
        },
        error = function(e) {
          if (e$message == "Page must have a title") {
            add_project_codelink(
              projectnode = project_node_new,
              subtitle = NULL,
              page_title = code_file,
              page_link = file.path(
                "projects",
                basename(project_dir),
                "code",
                code_file
              )
            )
          } else {
            message(
              sprintf(
                "Error processing code file %s: %s",
                code_file,
                e$message
              )
            )
          }
        }
      )
    }

    missing_links <- original_page_links[
      !original_page_links %in% new_page_links
    ]
    if (length(missing_links) > 0) {
      message(
        sprintf(
          "The following page links were found in the index but not in the project code files. They have been removed from the index.\n%s",
          paste(missing_links, collapse = "\n")
        )
      )
    }
  }

  # Write the new index file
  write_index(index_new, index_path)
}
