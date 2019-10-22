# labbook
labbook is an R package meant to make maintaining a digital lab book easier, generally in combination with RStudio. It is designed to produce navigable webpages that work offline, without the need to run a local server.

## Installation
The easiest way to install the package is to install the [devtools](https://devtools.r-lib.org) package and run `install_github`:

```r
devtools::install_github(
    repo   = "shwilks/labbook",
    subdir = "labbook"
)
```

## Usage
### Initiate a labbook
To initiate a new labbook, use `labbook.init()`, specifying a parent directory, a lab book title and name for the first project that will be created. By default the lab book is created in a directory called "labbook", but this folder can be safely renamed.

```r
# Intiate a new labbook on the desktop with a first project
labbook.init(
    labbook.dir   = "~/Desktop",
    labbook.title = "Sam's labbook",
    project.title = "B cell analysis"
)
```

### Create a new page
Once inside a labbook project you can create a new page using `labbook.newPage()` which will simply create a new file inside the project's `code/` directory with a basic skeleton. You could also simply create a new R code file yourself in the `code/` directory and write your own scaffold each time.

```r
labbook.newPage("bcell_data_processing.R")
```

Page rendering is built on top of [knitr](https://yihui.name/knitr/) and [rmarkdown](https://rmarkdown.rstudio.com) but includes a pre-processing step to allow the page structure to be encoded in syntactically valid R code files that can be run and debugged as you would with any normal R code.

The package also adds a number of functions to help output plots and data to rendered pages programatically (for example plots of different dimensions from within the same for loop).

For more detailed information on the syntax you should follow and the functions you can utilise for generating pages see the [example page](examples/example_page.R).

### Render a new page
The function used to render a new page is `render.page()`. When run with no arguments it will by default render the current code file that has focus in RStudio and try and open the resulting page in the web browser. An RStudio addin `Render page` is also included and the intention is that you would set a keyboard shortcut for this, for example I use Command + Shift + R. You can however call `render.page()` directly with the appropriate arguments.

### Initiate a new project
To initiate a new project simply call `labbook.newProject()` from within any other open labbook project i.e.

```r
labbook.newProject("Antibody dynamics")
```

### Customising your lab book
Lab book pages are styled and processed according to files kept in the `library/styles` and `library/scripts` directory. The files are as follows:

| File | Usage |
| :--- | :---- |
| general.css | Contains general element styles and is applied to all pages |
| shared.css  | Contains styles for lab book-specific elements and is applied to all pages |
| index.css   | Styles applied to the index page |
| page.css    | Styles applied to lab book pages |

If you would like to edit the main `index.html` file you can freely do so, just be sure not to touch the `<section id="projects">...</section>` part since this is automatically maintained when new pages are rendered and assumes a certain format.

### Page versioning
I found myself re-running the same code several times but with small alterations or for example with additional data input. In these cases you don't necessarily want to lose the previous versions of the page that you made since often I found myself wanting to go back and check how the analyses I'd made the last week looked. However, you also don't want to clog-up your index page with many different versions of the same analyses. To address this, the lab book includes a rudimentary form of page versioning so that a new page version is rendered without over-writing the last one, and the index page is styled to hide previously made versions by default.

To indicate that a page is a new version simply include the `#' @X` tag, where `X` is the version number, i.e. `#' @2` or `#' @3.2`. The page header will then look something like this:

```r
##' B cell dynamics
###' A simple B cell ODE model
#' @2
#'
```

Now when the file is rendered the index page will be updated appropriately and previous page versions will not be over-written.

### Rendering a standalone page
The `render.page()` function can be called on a regular code file to use knitr's neat capabilities to produce a standalone webpage, containing all necessary styles, images and code libraries.

```r
# Output a standalone labbook page to the desktop
render.page(
    codepath   = "code/b_cell_dynamic_model.R",
    pagepath   = "~/Desktop/b_cell_dynamic_model.html",
    standalone = TRUE
)
```

