#!/usr/bin/env bash

# SPDX-FileCopyrightText: Copyright (c) The helly25 authors (helly25.com)
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

function die() {
    echo "ERROR: ${*}" 1>&2
    exit 1
}

[[ ${#} == 1 ]] || die "Must provide a version argument."

git fetch origin main # Make sure the below is relevant

# trunk-ignore(shellcheck/SC2312)
if [[ -n "$(git status --porcelain)" ]]; then
    # Non empty output means non clean branch.
    die "Must be run from clean 'main' branch."
fi
# trunk-ignore(shellcheck/SC2312)
if [[ -n "$(git diff origin/main --numstat)" ]]; then
    die "Must be run from clean 'main' branch."
fi
# trunk-ignore(shellcheck/SC2312)
if [[ -n "$(git diff origin/main --cached --numstat)" ]]; then
    die "Must be run from clean 'main' branch."
fi

VERSION="${1}"

BAZELMOD_VERSION="$(sed -rne 's,.*version = "([0-9]+([.][0-9]+)+.*)".*,\1,p' <MODULE.bazel | head -n1)"
CHANGELOG_VERSION="$(sed -rne 's,^# ([0-9]+([.][0-9]+)+.*)$,\1,p' <CHANGELOG.md | head -n1)"
NEXT_VERSION="$(echo "${VERSION}" | awk -F. '/^(0|[1-9][0-9]*)([.](0|[1-9][0-9]*)){2,}([-+]|$)/{print $1"."$2"."(($3)+1)}')"

if [[ "${BAZELMOD_VERSION}" != "${CHANGELOG_VERSION}" ]]; then
    die "MODULE.bazel (${BAZELMOD_VERSION}) != CHANGELOG.md (${CHANGELOG_VERSION})."
fi

if [[ "${VERSION}" != "${BAZELMOD_VERSION}" ]]; then
    die "Provided version argument (${VERSION}) different from merged version (${BAZELMOD_VERSION})."
fi

if [[ -z "${NEXT_VERSION}" ]]; then
    die "Could not determine next version from input (${VERSION})."
fi

# trunk-ignore(shellcheck/SC2312)
grep -E "^${VERSION}$" < <(git tag -l) && die "Version tag is already in use."

echo "Next version: ${NEXT_VERSION}"

sed -i '' -f - CHANGELOG.md <<EOF
1i\\
# ${NEXT_VERSION}
1i\\

EOF

sed -i '' "s/version = \"${VERSION}\"/version = \"${NEXT_VERSION}\"/" MODULE.bazel

MESSAGE_BODY="$(awk '/^#/{if(NR>1)exit}/^[^#]/{print}' <CHANGELOG.md)"

git tag -s -a "${VERSION}" \
    -m "New release tag version: '${VERSION}'." \
    -m "${MESSAGE_BODY}"

git push origin --tags

NEXT_BRANCH="chore/bump_version_to_${NEXT_VERSION}"

git checkout -b "${NEXT_BRANCH}"
git add MODULE.bazel
git add CHANGELOG.md
git commit -m "Bump version to ${NEXT_VERSION}"
git push -u origin "${NEXT_BRANCH}"

# trunk-ignore(shellcheck/SC2230)
if which gh; then
    PRNUM=""
    PRURL=""
    BUMP_TEXT="Bump version from ${VERSION} to ${NEXT_VERSION}"
    MERGE_TITLE="${BUMP_TEXT}"
    MERGE_SUBJECT="${BUMP_TEXT}"
    MERGE_BODY="Auto approved version bump from ${VERSION} to ${NEXT_VERSION} by trigger script."
    if [[ -z "${GH_TOKEN:-}" ]]; then
        # Dynamically fetch the token from the macOS Keychain if available
        if security find-generic-password -s "bzl-release" >/dev/null 2>&1; then
            GH_TOKEN="$(security find-generic-password -s "bzl-release" -w)"
            export GH_TOKEN
        else
            echo "WARNING: GH_TOKEN not set and 'bzl-release' not found in Keychain. Falling back to default gh host auth."
        fi
    fi
    if gh pr create --title "${MERGE_TITLE}" -b "Created by ${0}." 2>&1 | tee pr_create_output.txt; then
        PRNUM="$(sed -E -n 's,.*pull/([0-9]+).*,\1,p' pr_create_output.txt | head -n1)"
        PRURL="https://github.com/helly25/bzl/pull/${PRNUM}"
    else
        echo "ERROR: Cannot create PR:"
        cat pr_create_output.txt
    fi
    if [[ "${PRNUM}" -gt 1 ]]; then
        gh pr ready "${NEXT_BRANCH}"
        gh pr review "${NEXT_BRANCH}" -a -b "${MERGE_BODY}" || true
        if gh pr merge "${NEXT_BRANCH}" --admin -d -s -b "${MERGE_BODY}" -t "${MERGE_SUBJECT}"; then
            git checkout main
            git branch -d "${NEXT_BRANCH}"
            echo "PR ${PRNUM} was merged via admin override. See: ${PRURL}."
        else
            gh pr merge "${NEXT_BRANCH}" --auto -d -s -b "${MERGE_BODY}" -t "${MERGE_SUBJECT}"
            git checkout main
            git branch -d "${NEXT_BRANCH}" || true
            echo "PR ${PRNUM} cannot be merged via admin override."
            echo "Please approve it at ${PRURL}."
        fi
    fi
fi
