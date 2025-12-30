# Format IRN with leading zeros

Ensures IRN is formatted as a 6-digit string with leading zeros.

## Usage

``` r
format_irn(irn)
```

## Arguments

- irn:

  Numeric or character IRN

## Value

Character vector with properly formatted IRNs

## Examples

``` r
format_irn(43752)    # "043752"
#> [1] "043752"
format_irn("43752")  # "043752"
#> [1] "043752"
```
