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

def _versions_ge_test(ctx):
    """Unit tests for versions.ge."""
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
    """Unit tests for versions.ge."""
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
    """Unit tests for versions.ge."""
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
    """Unit tests for versions.ge."""
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

versions_ge_test = unittest.make(_versions_ge_test)
versions_gt_test = unittest.make(_versions_gt_test)
versions_le_test = unittest.make(_versions_le_test)
versions_lt_test = unittest.make(_versions_lt_test)

def versions_test_suite():
    """Creates the test targets and test suite for paths.bzl tests."""
    unittest.suite(
        "versions_tests",
        versions_ge_test,
        versions_gt_test,
        versions_le_test,
        versions_lt_test,
    )
