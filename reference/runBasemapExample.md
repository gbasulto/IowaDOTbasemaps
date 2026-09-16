# Run the Shiny Basemap Regression Example

Launches an app exercising basemap replacement, incident proxy updates,
popups, multiple maps and a hidden tab. CARTO requires your basemap key;
Iowa DOT does not currently require a key.

## Usage

``` r
runBasemapExample(...)
```

## Arguments

- ...:

  Arguments to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html), such
  as `launch.browser = TRUE`.

## Value

The result of
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).
