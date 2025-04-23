# Load testthat
library(testthat)
devtools::load_all()

# Render a stand-alone page
# example.path  <- testthat::test_path(file.path("..", "testdata", "example_tabbed_plotly.R"))
example.path <- testthat::test_path(file.path("..", "testdata", "example_python_page.py"))

# standalone.path <- tempfile(fileext = ".html")
standalone.path <- "~/Desktop/test.html"
render.page(
  codepath = example.path,
  pagepath = standalone.path,
  standalone = TRUE,
  openpage = FALSE,
  new_session = FALSE
)
