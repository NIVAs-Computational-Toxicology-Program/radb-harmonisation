#' Extract "Recommendations" callouts from a .qmd file
#'
#' Expects callouts of the form:
#'
#' ::: {.callout-important title="Recommendations"}
#' - recommendation one
#' - recommendation two
#'
#' **Assessment**
#'
#' - Priority: 2/5
#' - Difficulty: 3/5
#' :::
#'
#' Each callout is attributed to the nearest preceding markdown heading
#' (ignoring `#` comment lines inside fenced code chunks).
#'
#' @param path Path to a .qmd file.
#' @return A tibble: doc, doc_title, heading, anchor, priority, difficulty,
#'   recommendations (list-column of character vectors).
extract_recommendations <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")

  doc_title <- stringr::str_match(lines, '^title:\\s*"?(.*?)"?\\s*$')[, 2]
  doc_title <- doc_title[!is.na(doc_title)][1]

  # Mark lines inside fenced code chunks so `# comment` isn't read as a heading
  fence <- stringr::str_detect(lines, "^```")
  in_code <- cumsum(fence) %% 2 == 1 | fence

  is_heading <- !in_code & stringr::str_detect(lines, "^#{1,6}\\s+\\S")
  heading_text <- ifelse(
    is_heading,
    stringr::str_trim(stringr::str_remove(lines, "^#{1,6}\\s+")),
    NA_character_
  )
  # nearest preceding heading for every line
  current_heading <- vctrs::vec_fill_missing(heading_text, direction = "down")

  starts <- which(
    !in_code &
      stringr::str_detect(
        lines,
        "^:::\\s*\\{\\.callout-important[^}]*Recommendations"
      )
  )

  rows <- purrr::map(starts, function(s) {
    # closing fence is the next bare ":::" line
    e <- s + which(stringr::str_detect(lines[-seq_len(s)], "^:::\\s*$"))[1]
    body <- lines[(s + 1):(e - 1)]

    assess <- which(stringr::str_detect(body, "^\\*\\*Assessment\\*\\*"))[1]
    recs_raw <- if (is.na(assess)) body else body[seq_len(assess - 1)]
    assess_raw <- if (is.na(assess)) character() else body[-seq_len(assess)]

    # Bullets, with indented/continuation lines folded into the previous bullet
    recs <- character()
    for (l in recs_raw) {
      if (stringr::str_detect(l, "^-\\s+")) {
        recs <- c(recs, stringr::str_remove(l, "^-\\s+"))
      } else if (nzchar(stringr::str_trim(l)) && length(recs) > 0) {
        recs[length(recs)] <- paste(recs[length(recs)], stringr::str_trim(l))
      }
    }

    grab <- function(label) {
      m <- stringr::str_match(
        assess_raw,
        paste0("^-\\s+", label, ":\\s*(\\d+)\\s*/\\s*(\\d+)")
      )
      v <- m[!is.na(m[, 2]), 2]
      if (length(v) == 0) NA_integer_ else as.integer(v[1])
    }

    tibble::tibble(
      doc = basename(path),
      doc_title = doc_title,
      heading = current_heading[s],
      priority = grab("Priority"),
      difficulty = grab("Difficulty"),
      recommendations = list(recs)
    )
  })

  out <- purrr::list_rbind(rows)

  bad <- is.na(out$priority) | is.na(out$difficulty)
  if (any(bad)) {
    warning(
      basename(path),
      ": missing Priority/Difficulty under: ",
      paste(out$heading[bad], collapse = "; "),
      call. = FALSE
    )
  }
  out
}

#' Approximate pandoc's auto-generated heading id (for in-page links)
heading_anchor <- function(x) {
  x |>
    stringr::str_remove_all("`") |>
    stringr::str_to_lower() |>
    stringr::str_replace_all("\\s+", "-") |>
    stringr::str_remove_all("[^a-z0-9_.-]") |>
    stringr::str_remove("^[^a-z]+")
}
