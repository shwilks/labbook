push_labbook <- function(labbook_root = "../../") {
  # Normalize the path
  labbook_root <- normalizePath(labbook_root)

  # Stage and commit any changes from the labbook root directory
  system(paste0("git -C ", labbook_root, " add ."))
  system(paste0("git -C ", labbook_root, " commit -m 'labbook update'"))

  # Push the changes to origin
  system(paste0("git -C ", labbook_root, " push origin main"))
}

list_changes <- function(labbook_root = "../../") {
  # List unstaged git changes
  system(paste0("git -C ", labbook_root, " status --porcelain"), intern = TRUE)
}
