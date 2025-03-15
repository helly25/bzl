# Helly25 bzl, a Bazel support library

This library provides [Bazel](http://bazel.build) [Starlark](https://bazel.build/rules/language) functionality meant to help in maintaining other libraries.

[![Test](https://github.com/helly25/bzl/actions/workflows/main.yml/badge.svg)](https://github.com/helly25/bzl/actions/workflows/main.yml)

## Versions

* `load("@helly25_bzl//bzl/versions:versions_bzl", _versions = "versions")`
  * `versions` is a single import structure:
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
  * Example:
    ```bazel
    my_version = "25.33.42"
    min_version = (10, 11, 12)
    if _versions.lt(my_version, min_version):
      fail("My version {my_version} is earlier than {min_version}.".format(
        my_version = my_version,
        min_version = min_version,
      ))
    ```
