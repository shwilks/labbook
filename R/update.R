update_labbook_scripts <- function(
  labbook_path,
  overwrite_backups = FALSE
) {
  library_dir <- get_library_dir()

  scripts <- list.files(
    file.path(library_dir, "scripts"),
    full.names = TRUE
  )

  for (script in scripts) {
    # Create a backup of the existing script
    existing_script <- file.path(
      labbook_path,
      "library",
      "scripts",
      basename(script)
    )
    if (file.exists(existing_script)) {
      file.copy(
        existing_script,
        paste0(existing_script, ".bak"),
        overwrite = overwrite_backups
      )
    }

    # Copy over the new script
    message("Updating script: ", basename(script))
    file.copy(
      script,
      existing_script,
      overwrite = TRUE
    )
  }
}

update_labbook_styles <- function(
  labbook_path,
  overwrite_backups = FALSE
) {
  library_dir <- get_library_dir()

  styles <- list.files(
    file.path(library_dir, "styles"),
    full.names = TRUE
  )

  for (style in styles) {
    # Create a backup of the existing style
    existing_style <- file.path(
      labbook_path,
      "library",
      "styles",
      basename(style)
    )
    if (file.exists(existing_style)) {
      file.copy(
        existing_style,
        paste0(existing_style, ".bak"),
        overwrite = overwrite_backups
      )
    }

    # Copy over the new style
    message("Updating style: ", basename(style))
    file.copy(
      style,
      existing_style,
      overwrite = TRUE
    )
  }
}

get_library_dir <- function() {
  if (dir.exists("inst/labbook/library/")) {
    "inst/labbook/library/"
  } else {
    system.file(
      "labbook",
      "library",
      package = "labbook",
      mustWork = TRUE
    )
  }
}
