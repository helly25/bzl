# Helly25 mbo_bzl, a Bazel support library

This library provide Bazel Skylark functionality meant to help in maintaining other libraries.

## Versions

The `@mbo_bzl//mbo_bzl:versions.bzl` sub-libray provides:

* `versions` a single import structure:

  * `parse`: Parses a version.
  * `ge`: Implements L >= R.
  * `gt`: Implements L > R.
  * `le`: Implements L <= R.
  * `lt`: Implements L < R.
  * `eq`: Implements L == R.
  * `ne`: Implements L != R.
  * `check_one_requirement`: Checks a version adheres to a single requirement.
  * `check_all_requirements`: Checks a version adheres to a requirements list.
  * `parse_requirements`: Parses a requirements specification.
