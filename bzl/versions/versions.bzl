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

SEE [README.md](https://github.com/helly25/bzl/blob/main/README.md).
"""

def _maybe_int(value):
    if type(value) == "string" and value.isdigit():
        return int(value)
    return value

def _parse_pre_release(version):
    parts = [_maybe_int(v) for v in version.split(".")]
    results = []
    for part in parts:
        if type(part) == "int":
            results.append(part)
            continue
        part = str(part)
        if not part[0].isdigit() and part[-1].isdigit():
            p = 0  # The interpreter does not see this is always initialized.
            for p in range(len(part), 0, -1):
                if not part[p - 1].isdigit():
                    break
            if p > 1 and part[p - 1] == "-":
                # A single trailing "-" gets removed iff remainder is not empty.
                results.append(part[:p - 1])
            else:
                results.append(part[:p])
            results.append(part[p:])
        else:
            results.append(part)
    return results

def _parse_build(version):
    parts = [_maybe_int(v) for v in version.split(".")]
    return parts

def _split_version_relese_build(version):
    r = None
    b = None
    for p in range(len(version)):
        if not b:
            if version[p] == "+":
                b = p
                break
            if not r and version[p] == "-":
                r = p

    if r and b:
        rel = _parse_pre_release(version[r + 1:b])
        bld = _parse_build(version[b + 1:])
        return [version[:r], "-"] + rel + ["+"] + bld
    elif r:
        rel = _parse_pre_release(version[r + 1:])
        return [version[:r], "-"] + rel
    elif b:
        bld = _parse_build(version[b + 1:])
        return [version[:b], "+"] + bld
    else:
        return [version]

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
                # For safety we just split on all dots which is likely the
                # intended behavior.
                version = version[:-1] + version[-1].split(".")
            elif version[-1]:
                # Unlike Semver which requires <major>.<minor>.<patch> we allow
                # any length of number/"." sequence followed by "-" or "+" for
                # <pre_release> and <build> components respectively.
                # Note: Semver allows both <pre_release> and <build> to be "."
                # separated parts. Still separated by "-" and "+" respectively.
                release_build = _split_version_relese_build(version[-1])
                version = version[:-1] + release_build

    elif type(version) == "tuple":
        version = [v for v in version]
    if type(version) == "list":
        return [_maybe_int(version[p]) for p in range(len(version))]
    extra_error = "Input was: '{version}'.".format(version = version)
    if error:
        fail([error, extra_error].join(" "))
    else:
        fail(error)

def _cmp(lhs, rhs):
    if lhs == rhs:
        return 0
    lhs = _maybe_int(lhs)
    rhs = _maybe_int(rhs)
    if type(lhs) == "int" or type(rhs) == "string":
        # Purely numeric identifiers have lower precedence than strings.
        if type(lhs) == "int" and type(rhs) == "string":
            return -1
        if type(lhs) == "string" and type(rhs) == "int":
            return 1
        if type(lhs) == "int" and type(rhs) == "int":
            return int(lhs > rhs) - int(lhs < rhs)
    lhs = str(lhs)
    rhs = str(rhs)
    return int(lhs > rhs) - int(lhs < rhs)

def _extra_cmp(lhs, rhs):
    """Comparisons respecting `None`, "-" and "+"."""
    if _maybe_int(lhs) == _maybe_int(rhs):
        return 0
    if not lhs:
        if rhs == "-":
            return 1
        else:
            return -1
    if not rhs:
        if lhs == "-":
            return -1
        else:
            return 1

    # Case `lhs == rhs` was already handled.
    if lhs == "-":
        return -1
    elif rhs == "-":
        return 1

    return _cmp(lhs, rhs)

def _at_or(array, pos, default = None):
    if pos < len(array):
        return array[pos]
    return default

def _version_cmp(version_lhs, version_rhs):
    """Implements `version_lhs` <=> `version_rhs`."""
    lhs = _parse_version(
        version_lhs,
        "Left hand argument is neither string, int nor list but {typ}.".format(
            typ = type(version_lhs),
        ),
    )
    rhs = _parse_version(
        version_rhs,
        "Right hand argument is neither string, int nor list {typ}.".format(
            typ = type(version_rhs),
        ),
    )
    part = 0
    for part in range(min(len(lhs), len(rhs))):
        if lhs in ["-", "+"] or rhs in ["-", "+"]:
            part -= 1  # Since we later increase
            break
        res = _cmp(lhs[part], rhs[part])
        if res != 0:
            return res

    part += 1  # Skip the already compared part even if that moves beyond end.
    res = _extra_cmp(_at_or(lhs, part), _at_or(rhs, part))
    if res != 0:
        return res

    # All parts available on both sides are the same.
    return _cmp(len(lhs), len(rhs))

def _version_ge(version_lhs, version_rhs):
    """Implements `version_lhs` >= `version_rhs`."""
    return _version_cmp(version_lhs, version_rhs) >= 0

def _version_le(version_lhs, version_rhs):
    """Implements `version_lhs` <= `version_rhs`."""
    return _version_cmp(version_lhs, version_rhs) <= 0

def _version_eq(version_lhs, version_rhs):
    """Implements `version_lhs` == `version_rhs`."""
    return _version_cmp(version_lhs, version_rhs) == 0

def _version_lt(version_lhs, version_rhs):
    """Implements `version_lhs` < `version_rhs`."""
    return _version_cmp(version_lhs, version_rhs) < 0

def _version_gt(version_lhs, version_rhs):
    """Implements `version_lhs` > `version_rhs`."""
    return _version_cmp(version_lhs, version_rhs) > 0

def _version_ne(version_lhs, version_rhs):
    """Implements `version_lhs` != `version_rhs`."""
    return _version_cmp(version_lhs, version_rhs) != 0

def _version_compare(lhs, op, rhs, error = None):
    """Implements `lhs OP rhs`."""
    if op == ">=":
        return _version_ge(lhs, rhs)
    elif op == "<=":
        return _version_le(lhs, rhs)
    elif op == "<":
        return _version_lt(lhs, rhs)
    elif op == ">":
        return _version_gt(lhs, rhs)
    elif op == "==":
        return _version_eq(lhs, rhs)
    elif op == "!=":
        return _version_ne(lhs, rhs)
    elif error:
        fail(error)
    else:
        fail("Bad comparator: '{op}'.".format(op = op))

def _check_one_requirement_struct(version, requirement):
    return _version_compare(
        version,
        requirement.op,
        requirement.version,
        "Bad requirement: '{requirement}'.".format(requirement = requirement),
    )

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

def _check_all_requirements(version, requirements):
    """Verifiy if `version` adheres to the `requirements` (list or string)."""
    if type(requirements) == "list":
        return all([
            _check_one_requirement(version, r)
            for r in requirements
        ])
    if type(requirements) == "string":
        return all([
            _check_one_requirement(version, r.strip())
            for r in requirements.split(",")
        ])
    fail("Requirements must be 'list' or 'string'.")

def _parse_split_requirement(req):
    if req.startswith(">="):
        return struct(op = ">=", version = _parse_version(req[2:].strip()))
    elif req.startswith(">"):
        return struct(op = ">", version = _parse_version(req[1:].strip()))
    elif req.startswith("<="):
        return struct(op = "<=", version = _parse_version(req[2:].strip()))
    elif req.startswith("<"):
        return struct(op = "<", version = _parse_version(req[1:].strip()))
    elif req.startswith("=="):
        return struct(op = "==", version = _parse_version(req[2:].strip()))
    elif req.startswith("!="):
        return struct(op = "!=", version = _parse_version(req[2:].strip()))
    else:
        return struct(op = "==", version = _parse_version(req))

def _parse_requirements(requirements):
    """Splits the `requirements` string for use in `check_all_requirements`."""
    return [
        _parse_split_requirement(req.strip())
        for req in requirements.split(",")
    ]

versions = struct(
    parse = _parse_version,
    ge = _version_ge,
    gt = _version_gt,
    le = _version_le,
    lt = _version_lt,
    eq = _version_eq,
    ne = _version_ne,
    cmp = _version_cmp,
    compare = _version_compare,
    check_one_requirement = _check_one_requirement,
    check_all_requirements = _check_all_requirements,
    parse_requirements = _parse_requirements,
)
