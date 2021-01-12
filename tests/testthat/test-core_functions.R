
# Load testthat
library(testthat)
library(labbook)
context("Core functions")

# Set dirs
labbook.dir  <- testthat::test_path(file.path("..", "testoutput"))
labbook.path <- file.path(labbook.dir, "labbook")

# Initiating a labbook
test_that("Initiate labbook", {

    unlink(labbook.path, recursive = TRUE)

    labbook.init(
      labbook.dir   = labbook.dir,
      labbook.title = "Test labbook",
      project.title = "First project"
    )

    expect_true(file.exists(labbook.path))
    # unlink(labbook.path, recursive = TRUE)

})


# Adding a project
test_that("Add a new project", {

    labbook.newProject(
        project.title = "A second project",
        labbook.path  = labbook.path
    )

    expect_true(
        file.exists(
            file.path(
                labbook.path, "projects", labbook:::make.safename("A second project")
            )
        )
    )

})


# Adding another project
test_that("Add another project", {

    labbook.newProject(
        project.title = "A third project",
        labbook.path = labbook.path
    )

    expect_true(
        file.exists(
            file.path(
                labbook.path, "projects", labbook:::make.safename("A third project")
            )
        )
    )

})


# Render a new page
test_that("Render a new page", {

    example.path  <- testthat::test_path(file.path("..", "testdata", "example.R"))
    codefile.path <- file.path(labbook.path, "projects", "first_project", "code", "example.R")

    file.copy(
        from = example.path,
        to   = codefile.path
    )

    render.page(codefile.path, openpage = FALSE)
    render.page(codefile.path, openpage = FALSE)
    expect_true(file.exists(example.path))
    expect_true(file.exists(codefile.path))

})


# Render a new page
test_that("Render a second page", {

  example.path  <- testthat::test_path(file.path("..", "testdata", "example2.R"))
  codefile.path <- file.path(labbook.path, "projects", "a_second_project", "code", "example2.R")

  file.copy(
    from = example.path,
    to   = codefile.path
  )

  render.page(codefile.path, openpage = FALSE)
  expect_true(file.exists(example.path))
  expect_true(file.exists(codefile.path))

})


# Render a new page
test_that("Render a third page", {

  example.path  <- testthat::test_path(file.path("..", "testdata", "example3.R"))
  codefile.path <- file.path(labbook.path, "projects", "first_project", "code", "example3.R")
  pagefile.path <- file.path(labbook.path, "projects", "first_project", "pages", "example3.html")

  file.copy(
    from = example.path,
    to   = codefile.path
  )

  expect_error(
      render.page(codefile.path, openpage = FALSE)
  )
  expect_true(file.exists(example.path))
  expect_true(file.exists(codefile.path))
  expect_false(file.exists(pagefile.path))

})


# Render a new page
test_that("Render a fourth page", {

  example.path  <- testthat::test_path(file.path("..", "testdata", "example4.R"))
  codefile.path <- file.path(labbook.path, "projects", "first_project", "code", "example4.R")

  file.copy(
    from = example.path,
    to   = codefile.path
  )

  render.page(codefile.path, openpage = FALSE)
  expect_true(file.exists(example.path))
  expect_true(file.exists(codefile.path))

})



# Render a stand-alone page
test_that("Render a standalone page", {

  example.path  <- testthat::test_path(file.path("..", "testdata", "example.R"))
  codefile.path <- file.path(labbook.path, "projects", "first_project", "code", "example.R")

  file.copy(
    from = example.path,
    to   = codefile.path
  )

  # standalone.path <- tempfile(fileext = ".html")
  standalone.path <- "~/Desktop/test.html"
  render.page(
    codepath   = codefile.path,
    pagepath   = standalone.path,
    standalone = TRUE,
    openpage   = FALSE
  )

  expect_true(file.exists(standalone.path))

})


# Test versioning
test_that("Page versioning", {

  # Version 2
  example.path  <- testthat::test_path(file.path("..", "testdata", "example4_v2.R"))
  codefile.path <- file.path(labbook.path, "projects", "first_project", "code", "example4_v2.R")

  file.copy(
    from = example.path,
    to   = codefile.path
  )

  render.page(codefile.path, openpage = FALSE)

  # Version 3
  example.path  <- testthat::test_path(file.path("..", "testdata", "example4_v3.R"))
  codefile.path <- file.path(labbook.path, "projects", "first_project", "code", "example4_v3.R")

  file.copy(
    from = example.path,
    to   = codefile.path
  )

  render.page(codefile.path, openpage = FALSE)

  expect_true(file.exists(example.path))
  expect_true(file.exists(codefile.path))

})





