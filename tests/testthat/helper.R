# Test helper functions

#' Skip tests if offline
#'
#' Checks for network connectivity by attempting to reach Google's DNS server.
#' If no connection is available, skips the test with a message.
#'
#' @return NULL (skips test if offline)
#' @keywords internal
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", timeout(5))
    if (httr::http_error(response)) {
      skip("No network connectivity")
    }
  }, error = function(e) {
    skip("No network connectivity")
  })
}
