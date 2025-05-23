get_code_page_path <- function(codepath) {
  pagepath <- gsub("/code/", "/pages/", codepath, fixed = T)
  pagepath <- gsub("\\.[^/]+$", ".html", pagepath)
  pagepath[!file.exists(pagepath)] <- NA
  pagepath
}

get_page_metadate <- function(pagepath) {
  pagemeta <- file.path(gsub("\\.html$", "_files", pagepath), "meta.txt")
  pagemeta[is.na(pagepath)] <- NA
  pagemeta[!is.na(pagemeta)][!file.exists(pagemeta[!is.na(pagemeta)])] <- NA

  pagedates <- pagemeta
  pagedates[!is.na(pagemeta)] <- sapply(
    pagemeta[!is.na(pagemeta)],
    readLines
  ) |>
    unname()
  as.Date(pagedates)
}

get_code_title <- function(codepath) {
  vapply(
    codepath,
    \(filepath) {
      content <- readLines(filepath)
      codetitle <- content[substr(content, 1, 4) == "###'"][1]
      trimws(substr(codetitle, 5, nchar(codetitle)))
    },
    character(1)
  ) |>
    unname()
}

get_page_stats <- function() {
  project_dirs <- list.dirs("../", recursive = F)

  # Scrape code files
  project_files <- lapply(project_dirs, \(project_dir) {
    title <- readLines(file.path(project_dir, ".title"))
    files <- list.files(file.path(project_dir, "code"), full.names = T)
    files <- files[grepl(".", basename(files), fixed = T)]
    files <- files[!grepl("\\.log$", files)]

    tibble::tibble(
      project = title,
      codefile = files
    ) |>
      dplyr::distinct()
  }) |>
    dplyr::bind_rows()

  # Get any page and date information
  project_files$codefile_mtime <- file.info(project_files$codefile)$mtime |>
    as.Date()
  project_files$pagefile <- get_code_page_path(project_files$codefile)
  project_files$pagedate <- get_page_metadate(project_files$pagefile)
  project_files$codetitle <- get_code_title(project_files$codefile)
  project_files
}

update_page_stats <- function() {
  page_stats <- get_page_stats()
  jsonlite::write_json(
    page_stats,
    "../../library/pagestats.js",
    auto_unbox = TRUE
  )
}
