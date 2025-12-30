# Validate IRN format

Checks if an IRN is valid (6-digit Ohio identifier).

## Usage

``` r
is_valid_irn(irn)
```

## Arguments

- irn:

  Character vector of IRNs to validate

## Value

Logical vector indicating valid IRNs

## Examples

``` r
is_valid_irn("043752")  # TRUE
#> [1] TRUE
is_valid_irn("12345")   # FALSE (only 5 digits)
#> [1] FALSE
is_valid_irn("1234567") # FALSE (7 digits)
#> [1] FALSE
```
