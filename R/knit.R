

# Check if code is being called as part of knitting
knitting <- function(){
    isTRUE(getOption('knitr.in.progress'))
}

#' @export
div <- function(...){

    if (knitting()) {
        cat("<div class='parent'>")
        list(...)
        cat("</div>")
    } else {
        list(...)
    }

}

#' @export
out.plot <- function(code, fig_width=5, fig_height=7, out_height=NULL, out_width=NULL, inline=FALSE) {

    if(!is.null(out_width) && is.null(out_height)) out_height <- out_width*(fig_height/fig_width)
    if(is.null(out_width) && !is.null(out_height)) out_width  <- out_height*(fig_width/fig_height)

    if (knitting()) {
        g_deparsed <- paste0("function(){ ", deparse(substitute(code, env = parent.frame())), "}")

        if(is.null(out_height)) out_height <- "NULL"
        if(is.null(out_width))  out_width  <- "NULL"

        sub_chunk <- paste0("```{r ", parent.frame()$`.chunk-label`, "_subchunk", sample(1:1000000000, 1),
                            ", fig.height=", fig_height,
                            ", fig.width=",  fig_width,
                            ", out.height=", out_height,
                            ", out.width=",  out_width,
                            ", echo=FALSE, warning=FALSE, message=FALSE, error=FALSE, render=labpage_render}",
                            "\n(",
                            g_deparsed
                            , ")()",
                            "\n```
        ")

        if(inline){
            div <- "<div style='display:inline-block; vertical-align: top;'>"
        } else {
            div <- "<div>"
        }

        out(paste0(
          div,
          gsub("\n", "", knitr::knit(text = knitr::knit_expand(text = sub_chunk)), fixed = T),
          "</div>"
        ))

    } else {
        print(code)
    }
}

#' @export
out <- function(...){

    if (knitting()) {
        escape_output(...)
    } else {
        grey <- crayon::make_style("grey40")
        cat(grey(paste(..., sep = "")))
        cat("\n")
    }

}

#' @export
out.table <- function(x, scale = 1, escape = TRUE, ...){

    if (knitting()) {
        if (escape) {
          x[] <- apply(x, 1:2, gsub, pattern = "*", replacement = "\\*", fixed = TRUE)
        }
        out(sprintf("<div style='font-size:%s'>", paste0(scale*100, "%")))
        out(knitr::kable(x, format = "html", escape = escape, ...))
        out("</div>")
    } else {
        print(x)
    }
    invisible(NULL)

}

#' @export
out.collapsible <- function(label, x){

    if (knitting()) {
        out("<div class='collapsible-div' label='", label,"'>", sep = "")
        force(x)
        out("</div>")
    } else {
        force(x)
    }
    invisible(NULL)

}

#' @export
out.tabset <- function(...){

    if (knitting()) {
        out("<div class='tabset-div'>")
        list(...)
        out("</div>")
    } else {
        list(...)
    }
    invisible(NULL)

}

#' @export
out.tab <- function(label, x){

    if (knitting()) {
        out("<div class='tab-div' label='", label,"'>", sep = "")
        force(x)
        out("</div>")
    } else {
        force(x)
    }
    invisible(NULL)

}

#' @export
out.div <- function(...){

    if (knitting()) {
        out("<div>")
        list(...)
        out("</div>")
    } else {
        list(...)
    }
    invisible(NULL)

}

#' @export
out.flexdiv <- function(...){

  if (knitting()) {
    out("<div style='display:flex;'>")
    list(...)
    out("</div>")
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
  margin.left = 0
){

  if (knitting()) {
    out(
      sprintf(
        "<div style='display:inline-block; margin:%spx %spx %spx %spx;'>",
        margin.top,
        margin.right,
        margin.bottom,
        margin.left
      )
    )
    list(...)
    out("</div>")
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
out.pre <- function(textlines){

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
out.p <- function(...){

  if (knitting()) {
    out("<p>")
    out(...)
    out("</p>")
  } else {
    list(...)
  }
  invisible(NULL)

}

#' @export
out.h1 <- function(txt){
  out("<h1>")
  out(txt)
  out("</h1>")
  # out(paste("\n#", txt))
}

#' @export
out.h2 <- function(txt){
  out("<h2>")
  out(txt)
  out("</h2>")
  # out(paste("\n##", txt))
}

#' @export
out.h3 <- function(txt){
  out("<h3>")
  out(txt)
  out("</h3>")
  # out(paste("\n###", txt))
}

#' @export
out.h4 <- function(txt){
  out("<h4>")
  out(txt)
  out("</h4>")
  # out(paste("\n####", txt))
}

#' @export
out.link <- function(path){
  if(!file.exists(path)) stop(sprintf("File '%s' not found.", path))
  file.path("..", path)
}


escape_start <- "[[[["
escape_end   <- "]]]]"

escape_output <- function(...){
  cat(paste(c(escape_start, ..., escape_end), collapse = ""))
}

#' @export
out.pageset <- function(...){

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
out.page <- function(label, x){

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
      out("<div class='page-div' label='", label,"'>", sep = "")
      force(x)
      out("</div>")
    }

  } else {

    # Otherwise simply run it
    force(x)

  }

  invisible(NULL)

}

