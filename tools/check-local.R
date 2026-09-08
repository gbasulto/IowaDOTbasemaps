# Run from the package root in a fresh R session.
local({
needed <- c("leaflet", "htmltools", "jsonlite", "curl", "shiny", "testthat")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing)
r_executable <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "R.exe" else "R")
package_dir <- normalizePath(".", winslash = "/")
stopifnot(file.exists(file.path(package_dir, "DESCRIPTION")))
version <- read.dcf(file.path(package_dir, "DESCRIPTION"))[1, "Version"]
previous_dir <- setwd(dirname(package_dir))
on.exit(setwd(previous_dir), add = TRUE)
result <- system2(r_executable, c("CMD", "build", shQuote(package_dir)))
if (result != 0) stop("Package build failed.")
archive <- paste0("ctremaps_", version, ".tar.gz")
result <- system2(r_executable, c("CMD", "check", "--no-manual", shQuote(archive)))
if (result != 0) stop("R CMD check reported errors; inspect the .Rcheck directory.")
})
