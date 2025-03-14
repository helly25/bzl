# Copyright 2025 The Helly25 Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific languag

"""Unit tests for versions.bzl."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//mbo_bzl:versions.bzl", "versions")

def _versions_parse_test(ctx):
    """Unit tests for `versions.parse`."""
    env = unittest.begin(ctx)

    asserts.equals(env, versions.parse("25"), [25])
    asserts.equals(env, versions.parse("25.33.42.bla"), [25, 33, 42, "bla"])
    asserts.equals(env, versions.parse(""), [])
    # Parsing '25.33.bla' does not work because 'bla' is not a number.
    # asserts.equals(env, versions.parse("25.33.bla"), [25, 33, 42, "bla"])

    asserts.equals(env, versions.parse(25), [25])
    asserts.equals(env, versions.parse("26"), [26])
    asserts.equals(env, versions.parse([27]), [27])
    asserts.equals(env, versions.parse((28)), [28])

    asserts.equals(env, versions.parse(("25", "33")), [25, 33])
    asserts.equals(env, versions.parse(("25", "33", "42", "bla")), [25, 33, 42, "bla"])

    return unittest.end(env)

def _versions_ge_test(ctx):
    """Unit tests for `versions.ge`."""
    env = unittest.begin(ctx)

    asserts.equals(env, versions.ge(25, 25), True)
    asserts.equals(env, versions.ge(25, 42), False)
    asserts.equals(env, versions.ge(42, 25), True)

    asserts.equals(env, versions.ge("25.1", "25.1"), True)
    asserts.equals(env, versions.ge("25.2", "25.1"), True)
    asserts.equals(env, versions.ge("25.3", "25.4"), False)

    asserts.equals(env, versions.ge("25", "25"), True)
    asserts.equals(env, versions.ge("25", "25.0"), False)
    asserts.equals(env, versions.ge("25.0", "25.0"), True)
    asserts.equals(env, versions.ge("25.1", "25"), True)

    return unittest.end(env)

def _versions_gt_test(ctx):
    """Unit tests for `versions.gt`."""
    env = unittest.begin(ctx)

    asserts.equals(env, versions.gt(25, 25), False)
    asserts.equals(env, versions.gt(25, 42), False)
    asserts.equals(env, versions.gt(42, 25), True)

    asserts.equals(env, versions.gt("25.1", "25.1"), False)
    asserts.equals(env, versions.gt("25.2", "25.1"), True)
    asserts.equals(env, versions.gt("25.3", "25.4"), False)

    asserts.equals(env, versions.gt("25", "25"), False)
    asserts.equals(env, versions.gt("25", "25.0"), False)
    asserts.equals(env, versions.gt("25.0", "25.0"), False)
    asserts.equals(env, versions.gt("25.1", "25"), True)

    return unittest.end(env)

def _versions_le_test(ctx):
    """Unit tests for `versions.le`."""
    env = unittest.begin(ctx)

    asserts.equals(env, versions.le(25, 25), True)
    asserts.equals(env, versions.le(25, 42), True)
    asserts.equals(env, versions.le(42, 25), False)

    asserts.equals(env, versions.le("25.1", "25.1"), True)
    asserts.equals(env, versions.le("25.2", "25.1"), False)
    asserts.equals(env, versions.le("25.3", "25.4"), True)

    asserts.equals(env, versions.le("25", "25"), True)
    asserts.equals(env, versions.le("25", "25.0"), True)
    asserts.equals(env, versions.le("25.0", "25.0"), True)
    asserts.equals(env, versions.le("25.1", "25"), False)

    return unittest.end(env)

def _versions_lt_test(ctx):
    """Unit tests for `versions.lt`."""
    env = unittest.begin(ctx)

    asserts.equals(env, versions.lt(25, 25), False)
    asserts.equals(env, versions.lt(25, 42), True)
    asserts.equals(env, versions.lt(42, 25), False)

    asserts.equals(env, versions.lt("25.1", "25.1"), False)
    asserts.equals(env, versions.lt("25.2", "25.1"), False)
    asserts.equals(env, versions.lt("25.3", "25.4"), True)

    asserts.equals(env, versions.lt("25", "25"), False)
    asserts.equals(env, versions.lt("25", "25.0"), True)
    asserts.equals(env, versions.lt("25.0", "25.0"), False)
    asserts.equals(env, versions.lt("25.1", "25"), False)

    return unittest.end(env)

def _versions_eq_test(ctx):
    """Unit tests for `versions.eq`."""
    env = unittest.begin(ctx)

    asserts.equals(env, versions.eq(25, 25), True)
    asserts.equals(env, versions.eq(25, 42), False)
    asserts.equals(env, versions.eq(42, 25), False)

    asserts.equals(env, versions.eq("25.1", "25.1"), True)
    asserts.equals(env, versions.eq("25.2", "25.1"), False)
    asserts.equals(env, versions.eq("25.3", "25.4"), False)

    asserts.equals(env, versions.eq("25", "25"), True)
    asserts.equals(env, versions.eq("25", "25.0"), False)
    asserts.equals(env, versions.eq("25.0", "25.0"), True)
    asserts.equals(env, versions.eq("25.1", "25"), False)

    return unittest.end(env)

def _versions_ne_test(ctx):
    """Unit tests for `versions.ne`."""
    env = unittest.begin(ctx)

    asserts.equals(env, versions.ne(25, 25), False)
    asserts.equals(env, versions.ne(25, 42), True)
    asserts.equals(env, versions.ne(42, 25), True)

    asserts.equals(env, versions.ne("25.1", "25.1"), False)
    asserts.equals(env, versions.ne("25.2", "25.1"), True)
    asserts.equals(env, versions.ne("25.3", "25.4"), True)

    asserts.equals(env, versions.ne("25", "25"), False)
    asserts.equals(env, versions.ne("25", "25.0"), True)
    asserts.equals(env, versions.ne("25.0", "25.0"), False)
    asserts.equals(env, versions.ne("25.1", "25"), True)

    return unittest.end(env)

def _versions_parse_requirements_test(ctx):
    """Unit tests for `versions.parse_requirements`."""
    env = unittest.begin(ctx)

    asserts.equals(env, versions.parse_requirements("25"), [struct(op = "==", version = [25])])
    asserts.equals(env, versions.parse_requirements("<=26"), [struct(op = "<=", version = [26])])
    asserts.equals(env, versions.parse_requirements(">=27.1,<=28.1.2"), [
        struct(op = ">=", version = [27, 1]),
        struct(op = "<=", version = [28, 1, 2]),
    ])
    asserts.equals(env, versions.parse_requirements(" >= 29.1 , <= 29.1.2.bla "), [
        struct(op = ">=", version = [29, 1]),
        struct(op = "<=", version = [29, 1, 2, "bla"]),
    ])

    return unittest.end(env)

def _versions_check_one_requirement_test(ctx):
    """Unit tests for `versions.check_one_requirement`."""
    env = unittest.begin(ctx)

    asserts.equals(env, versions.check_one_requirement("25", "25"), True)
    asserts.equals(env, versions.check_one_requirement([26], "42"), False)
    asserts.equals(env, versions.check_one_requirement(27, ">=26"), True)
    asserts.equals(env, versions.check_one_requirement(28, "<=26"), False)

    return unittest.end(env)

def _versions_check_all_requirements_test(ctx):
    """Unit tests for `versions.check_all_requirements`."""
    env = unittest.begin(ctx)

    asserts.equals(env, versions.check_all_requirements("25", ["25"]), True)
    asserts.equals(env, versions.check_all_requirements("33", ["25", "33", "42"]), False)
    asserts.equals(env, versions.check_all_requirements("42", ["42", "42", "42"]), True)

    asserts.equals(env, versions.check_all_requirements("34", [">=25", "!=34", "<42"]), False)
    asserts.equals(env, versions.check_all_requirements("35", [">=25", "!=34", "<42"]), True)

    asserts.equals(env, versions.check_all_requirements("36", [
        struct(op = ">=", version = 25),
        struct(op = "!=", version = 34),
        struct(op = "<", version = 42),
    ]), True)

    asserts.equals(env, versions.check_all_requirements("37", [
        struct(op = ">=", version = 25),
        struct(op = "!=", version = 37),
        struct(op = "<", version = 42),
    ]), False)

    return unittest.end(env)

versions_parse_test = unittest.make(_versions_parse_test)
versions_ge_test = unittest.make(_versions_ge_test)
versions_gt_test = unittest.make(_versions_gt_test)
versions_le_test = unittest.make(_versions_le_test)
versions_lt_test = unittest.make(_versions_lt_test)
versions_eq_test = unittest.make(_versions_eq_test)
versions_ne_test = unittest.make(_versions_ne_test)
versions_parse_requirements_test = unittest.make(_versions_parse_requirements_test)
versions_check_one_requirement_test = unittest.make(_versions_check_one_requirement_test)
versions_check_all_requirements_test = unittest.make(_versions_check_all_requirements_test)

def versions_test_suite():
    """Creates the test targets and test suite for paths.bzl tests."""
    unittest.suite(
        "versions_tests",
        versions_parse_test,
        versions_ge_test,
        versions_gt_test,
        versions_le_test,
        versions_lt_test,
        versions_eq_test,
        versions_ne_test,
        versions_parse_requirements_test,
        versions_check_one_requirement_test,
        versions_check_all_requirements_test,
    )
