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
# See the License for the specific language governing permissions and
# limitations under the License.

"""A starlark implementation of versioning functions that mostly follow semver.

Semantic Versioning (Semver) is defined at https://semver.org/

At the moment the comparisons `eq (`==`) and `ne` (`!=`) respect all details.

All other comparators only correctly respect major, minor and patch components.

The full functionality is exposed as a singele struct containing all functions.

The version parameters support:
- a string that can be parsed according to:
     <major>['.' <minor> [ '.' <patch> [.*]]]
- a `list` or `tuple` where each component is a version part.
- a single `int` which will be the major version.
- anything else is an error and the functions will `fail`.

Example:

```starlark
load("versions.bzl", _versions = "versions")

print(_versions.eq("42.25.0", (42, 25, 0)) == True)
print(_versions.le("42.0.0", 42) == True)
```
"""

def _maybe_int(value):
    if type(value) == "string" and value.isdigit():
        return int(value)
    return value

def _parse_version(version, error = "Cannot parse version."):
    """Parses the input into a `list` or `tuple` of version components.

    The function requires the input to be a single int, string, list or tuple.
    If the input is a string, then it is separated into its components:
        <major>['.' <minor> [ '.' <patch> [.*]]]
    A single integer is turned into a list.
    Lists or tuples are returned as is.
    Everything else is an error.

    While this attempts to retain Semver principles this mostly works for
    simple versions that have components consisting of (major, minor, patch).

    The function is also relaxed about Semver as it is safer to try to parse
    with likely intent rather then exact standard enforcement. If the latter is
    necessary than a separate function, setting or parameter is needed.
    """
    if type(version) == "int":
        return [version]
    elif type(version) == "string":
        if not version:
            return []
        version = version.split(".", 2)
        if version:
            if version[-1].count("-") + version[-1].count("+") == 0:
                # No semver compatible <pre_release> or <build> present.
                # For safety we just split on all dots which is likely the intended behavior.
                version = version[:-1] + version[-1].split(".")
            elif version[-1]:
                # Unlike Semver which requires <major>.<minor>.<patch> we allow
                # any length of number/"." sequence followed by "-" or "+" for
                # <pre_release> and <build> components respectively.
                pre_release = version[-1].split("-", 1)
                if len(pre_release) > 1 and pre_release[0].count("+") == 0:
                    version[-1] = pre_release[0]
                    version.append("-" + pre_release[1])
                build = version[-1].split("+", 1)
                if len(build) > 1:
                    version[-1] = build[0]
                    version.append("+" + build[1])
    elif type(version) == "tuple":
        version = [v for v in version]
    if type(version) == "list":
        return [_maybe_int(version[p]) for p in range(len(version))]
    extra_error = "Input was: '{version}'.".format(version = version)
    if error:
        fail([error, extra_error].join(" "))
    else:
        fail(error)

def _version_ge(version_lhs, version_rhs):
    """Implements `version_lhs` >= `version_rhs`.

    The inputs are parsed with `_parse_version`.
    At most 3 parts (major, minor, patch) plus the lengths are considered.
    """
    lhs = _parse_version(version_lhs, "Left hand argument is neither string, int nor list but {typ}.".format(typ = type(version_lhs)))
    rhs = _parse_version(version_rhs, "Right hand argument is neither string, int nor list {typ}.".format(typ = type(version_rhs)))
    for part in range(min(3, len(lhs), len(rhs))):
        lhs_part = int(lhs[part])
        rhs_part = int(rhs[part])
        if lhs_part < rhs_part:
            return False
        if lhs_part > rhs_part:
            return True

    # All parts available on both sides are the same.
    return min(3, len(lhs)) >= min(3, len(rhs))

def _version_le(version_lhs, version_rhs):
    """Implements `version_lhs` <= `version_rhs`.

    The inputs are parsed with `_parse_version`.
    At most 3 parts (major, minor, patch) plus the lengths are considered.
    """
    lhs = _parse_version(version_lhs, "Left hand argument is neither string, int nor list.")
    rhs = _parse_version(version_rhs, "Right hand argument is neither string, int nor list.")
    for part in range(min(3, len(lhs), len(rhs))):
        lhs_part = int(lhs[part])
        rhs_part = int(rhs[part])
        if lhs_part < rhs_part:
            return True
        if lhs_part > rhs_part:
            return False

    # All parts available on both sides are the same.
    return min(3, len(lhs)) <= min(3, len(rhs))

def _version_eq(version_lhs, version_rhs):
    """Compares two versions and returns whether their semantic implementation is equal.

    The inputs are parsed with `_parse_version`.
    """
    lhs = _parse_version(version_lhs, "Left hand argument is neither string, int nor list.")
    rhs = _parse_version(version_rhs, "Right hand argument is neither string, int nor list.")
    if len(lhs) != len(rhs):
        return False
    for part in range(min(len(lhs), len(rhs))):
        if part < 3:
            lhs_part = int(lhs[part])
            rhs_part = int(rhs[part])
            if lhs_part != rhs_part:
                return False
        elif lhs[part] != rhs[part]:
            return False

    # All parts available on both sides are the same.
    return len(lhs) == len(rhs)

def _version_lt(version_lhs, version_rhs):
    """Implements `version_lhs` < `version_rhs`.

    The inputs are parsed with `_parse_version`.
    At most 3 parts (major, minor, patch) plus the lengths are considered.
    """
    return not _version_ge(version_lhs, version_rhs)

def _version_gt(version_lhs, version_rhs):
    """Implements `version_lhs` > `version_rhs`.

    The inputs are parsed with `_parse_version`.
    At most 3 parts (major, minor, patch) plus the lengths are considered.
    """
    return not _version_le(version_lhs, version_rhs)

def _version_ne(version_lhs, version_rhs):
    """Implements `version_lhs` != `version_rhs`.

    The inputs are parsed with `_parse_version`.
    """
    return not _version_eq(version_lhs, version_rhs)

def _check_one_requirement_struct(version, requirement):
    if requirement.op == ">=":
        return _version_ge(version, requirement.version)
    elif requirement.op == "<":
        return not _version_ge(version, requirement.version)
    elif requirement.op == "<=":
        return _version_le(version, requirement.version)
    elif requirement.op == ">":
        return not _version_le(version, requirement.version)
    elif requirement.op == "==":
        return _version_eq(version, requirement.version)
    elif requirement.op == "!=":
        return not _version_eq(version, requirement.version)
    else:
        fail("Bad requirement: '{requirement}'.".format(requirement = requirement))

def _check_one_requirement(version, requirement):
    """Version comparison of the given `version` against a `requirement` string.

    The requirement has the form:
        ("<", "<=", ">", ">=", "!=", "==") <digit>+ ("." <digit>+)+

    With the exception of comparators '==' and '!=':
        At most 3 parts (major, minor, patch) plus the lengths are considered.
    """
    if type(requirement) == "string":
        if requirement.startswith(">="):
            return _version_ge(version, requirement[2:].strip())
        elif requirement.startswith("<="):
            return _version_le(version, requirement[2:].strip())
        elif requirement.startswith(">"):
            return not _version_le(version, requirement[1:].strip())
        elif requirement.startswith("<"):
            return not _version_ge(version, requirement[1:].strip())
        elif requirement.startswith("=="):
            return _version_eq(version, requirement[2:].strip())
        elif requirement.startswith("!="):
            return not _version_eq(version, requirement[2:].strip())
        else:
            return _version_eq(version, requirement)
    return _check_one_requirement_struct(version, requirement)

def _check_all_requirements(version, requirement_list):
    """Verifies whether `version` adheres to the `requirement_list`.
    """
    if type(requirement_list) == "list":
        return all([_check_one_requirement(version, req) for req in requirement_list])
    return _check_all_requirements(version, [v.split() for v in requirement_list.split(",")])

def _parse_split_req(requirement):
    if requirement.startswith(">="):
        return struct(op = ">=", version = _parse_version(requirement[2:].strip()))
    elif requirement.startswith(">"):
        return struct(op = ">", version = _parse_version(requirement[1:].strip()))
    elif requirement.startswith("<="):
        return struct(op = "<=", version = _parse_version(requirement[2:].strip()))
    elif requirement.startswith("<"):
        return struct(op = "<", version = _parse_version(requirement[1:].strip()))
    elif requirement.startswith("=="):
        return struct(op = "==", version = _parse_version(requirement[2:].strip()))
    elif requirement.startswith("!="):
        return struct(op = "!=", version = _parse_version(requirement[2:].strip()))
    else:
        return struct(op = "==", version = _parse_version(requirement))

def _parse_version_requirements(requirements):
    """Splits the `requirements` string for use with `check_all_requirements`."""
    return [_parse_split_req(req.strip()) for req in requirements.split(",")]

versions = struct(
    parse = _parse_version,
    ge = _version_ge,
    gt = _version_gt,
    le = _version_le,
    lt = _version_lt,
    eq = _version_eq,
    ne = _version_ne,
    check_one_requirement = _check_one_requirement,
    check_all_requirements = _check_all_requirements,
    parse_requirements = _parse_version_requirements,
)
