# Check if code is being called as part of knitting
knitting <- function() {
  isTRUE(getOption("knitr.in.progress"))
}

#' @export
div <- function(...) {
  if (knitting()) {
    cat("<div class='parent'>")
    list(...)
    cat("</div>")
  } else {
    list(...)
  }
}

#' @export
out.plot <- function(
    code,
    fig_width = NULL,
    fig_height = NULL,
    out_height = NULL,
    out_width = NULL,
    inline = FALSE
    ) {

    # Check input
    checkmate::assert_number(fig_width, null.ok = T)
    checkmate::assert_number(fig_height, null.ok = T)
    checkmate::assert_number(out_height, null.ok = T)
    checkmate::assert_number(out_width, null.ok = T)
    checkmate::assert_flag(inline)

    # Set default argument values
    if (is.null(fig_width) && is.null(out_width)) {
        fig_width <- 5
    }

    if (is.null(fig_height) && is.null(out_height)) {
        fig_height <- 7
    }

    # Set default plot width and height in pixels
    if (!is.null(out_width) && is.null(out_height)) {
        out_height <- out_width * (fig_height / fig_width)
    }

    if (is.null(out_width) && !is.null(out_height)) {
        out_width <- out_height * (fig_width / fig_height)
    }

    # Set default plot width and height in inches
    if (is.null(fig_width) && !is.null(out_width)) {
        fig_width <- out_width / 72
    }

    if (is.null(fig_height) && !is.null(out_height)) {
        fig_height <- out_height / 72
    }

    if (knitting()) {

        g_deparsed <- paste0("function(){ ", deparse(substitute(code, env = parent.frame())), "}")

        if (is.null(out_height)) out_height <- "NULL"
        if (is.null(out_width)) out_width <- "NULL"

        sub_chunk <- paste0(
            "```{r ", parent.frame()$`.chunk-label`, "_subchunk", sample(1:1000000000, 1),
            ", fig.height=", fig_height,
            ", fig.width=", fig_width,
            ", out.height=", out_height,
            ", out.width=", out_width,
            ", echo=FALSE, warning=FALSE, message=FALSE, error=FALSE, render=labpage_render}",
            "\n(",
            g_deparsed,
            ")()",
            "\n```
            "
        )

        out.html("<div class='plot-div'>")
        out(knitr::knit(text = knitr::knit_expand(text = sub_chunk)))
        out.html("</div>")

    } else {

        print(code)

    }

}

#' @export
out <- function(...) {
  if (knitting()) {
    escape_output(...)
  } else {
    grey <- crayon::make_style("grey40")
    cat(grey(paste(..., sep = "")))
    cat("\n")
  }
}

out.html <- function(...) {
  out(htmltools::htmlPreserve(paste(..., collapse = "")))
}

out.tagset <- function(tag, ...) {
    out.html(sprintf("<%s>", tag))
    list(...)
    out.html(sprintf("</%s>", tag))
}

#' @export
out.table <- function(x, scale = 1, escape = TRUE, ...) {
  if (is.null(dim(x))) x <- cbind(x) # Convert vectors to a column
  if (knitting()) {
    if (escape) {
      x[] <- apply(x, 1:2, gsub, pattern = "*", replacement = "\\*", fixed = TRUE)
    }
    out.html(sprintf("<div style='font-size:%s'>", paste0(scale * 100, "%")))
    out.html(knitr::kable(x, format = "html", escape = escape, ...))
    out.html("</div>")
  } else {
    print(x)
  }
  invisible(NULL)
}

#' @export
out.collapsible <- function(label, x) {
  if (knitting()) {
    out("<div class='collapsible-div' label='", label, "'>", sep = "")
    force(x)
    out("</div>")
  } else {
    force(x)
  }
  invisible(NULL)
}

#' @export
out.tabset <- function(..., cyclable = NULL, id = NULL) {

  if (is.null(cyclable)) cyclable <- is.null(id)

  cyclable_class <- ifelse(
    cyclable,
    "tabset-cyclable",
    ""
  )

  id_txt <- ifelse(
      is.null(id),
      "",
      sprintf(
          "id='%s'",
          htmltools::htmlEscape(id, attribute = T)
      )
  )

  if (knitting()) {
    out.html("<div class='tabset-div ", cyclable_class, "' ", id_txt, ">")
    list(...)
    out.html("</div>")
  } else {
    list(...)
  }
  invisible(NULL)
}

#' @export
out.tab <- function(label, x) {
  if (knitting()) {
    out.html("<div class='tab-div' label='", htmltools::htmlEscape(label, attribute = T), "'>", sep = "")
    force(x)
    out.html("</div>")
  } else {
    force(x)
  }
  invisible(NULL)
}

#' @export
out.div <- function(...) {
  if (knitting()) {
    out.html("<div>")
    list(...)
    out.html("</div>")
  } else {
    list(...)
  }
  invisible(NULL)
}

out.plotdiv <- function(...) {
    if (knitting()) {
        out.html("<div class='plot-div'>")
        list(...)
        out.html("</div>")
    } else {
        list(...)
    }
    invisible(NULL)
}

#' @export
out.flexdiv <- function(...) {
  if (knitting()) {
    out.html("<div style='display:flex;'>")
    list(...)
    out.html("</div>")
  } else {
    list(...)
  }
  invisible(NULL)
}

#' @export
out.inlinediv <- function(
    ...,
    margin.top = 0,
    margin.right = 0,
    margin.bottom = 0,
    margin.left = 0) {
  if (knitting()) {
    out.html(
      sprintf(
        "<div style='display:inline-block; margin:%spx %spx %spx %spx;'>",
        margin.top,
        margin.right,
        margin.bottom,
        margin.left
      )
    )
    list(...)
    out.html("</div>")
  } else {
    list(...)
  }
  invisible(NULL)
}

#' @export
out.tag <- function(x) {
  out(knitr::knit_print(x))
}

#' @export
out.pre <- function(textlines) {
  if (knitting()) {
    out("<pre>")
    for (textline in textlines) {
      out(textline)
      out("<br/>")
    }
    out("</pre>")
  } else {
    for (textline in textlines) {
      out(textline)
    }
  }
  invisible(NULL)
}

#' @export
out.p <- function(...) {
  if (knitting()) {
    out.html("<p>")
    out(...)
    out.html("</p>")
  } else {
    list(...)
  }
  invisible(NULL)
}

#' @export
out.h1 <- function(txt) {
  out.html("<h1>")
  out(txt)
  out.html("</h1>")
  # out(paste("\n#", txt))
}

#' @export
out.h2 <- function(txt) {
  out.html("<h2>")
  out(txt)
  out.html("</h2>")
  # out(paste("\n##", txt))
}

#' @export
out.h3 <- function(txt) {
  out.html("<h3>")
  out(txt)
  out.html("</h3>")
  # out(paste("\n###", txt))
}

#' @export
out.h4 <- function(txt) {
  out.html("<h4>")
  out(txt)
  out.html("</h4>")
  # out(paste("\n####", txt))
}

#' @export
out.link <- function(path) {
  if (!file.exists(path)) stop(sprintf("File '%s' not found.", path))
  file.path("..", path)
}

escape_start <- "[[[["
escape_end <- "]]]]"

escape_output <- function(...) {
  cat(paste(c(escape_start, ..., escape_end), collapse = ""))
}

#' @export
out.pageset <- function(...) {
  if (knitting()) {
    out("<!--[[PAGESET_HEADER]]-->")
    out("<div class='pageset-div'>")
    list(...)
    out("</div>")
  } else {
    list(...)
  }
  invisible(NULL)
}

#' @export
out.page <- function(label, x) {
  if (knitting()) {
    # Get the knitting environment
    knit_env <- knitr::knit_global()

    # Get the page being currently rendered
    pagenum_rendering <- get0(".pagenum_rendering", knit_env, ifnotfound = 0)
    pagelabels <- get0(".pagelabels", knit_env, ifnotfound = NULL)

    # Get the page num and increment it
    pagenum <- get0(".pagenum", knit_env, ifnotfound = 0)
    pagenum <- pagenum + 1
    assign(".pagenum", pagenum, envir = knit_env)

    # Add the page label record
    pagelabels <- c(pagelabels, label)
    assign(".pagelabels", pagelabels, envir = knit_env)

    # If the page number equals the page currently being rendered, render it!
    if (pagenum == pagenum_rendering) {
      out("<div class='page-div' label='", label, "'>", sep = "")
      force(x)
      out("</div>")
    }
  } else {
    # Otherwise simply run it
    force(x)
  }

  invisible(NULL)
}
