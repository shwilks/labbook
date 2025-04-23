
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
