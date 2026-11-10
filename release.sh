#!/usr/bin/env bash
# Discover mandelbulber2 GitHub releases and push missing Docker tags.
#
# Env:
#   CI_PROJECT_NAME   image name (e.g. mandelbulber2-ubuntu)
#   DOCKERHUB_USER    Docker Hub namespace (e.g. aamillan)
#   LOOKBACK          optional max number of *missing* version tags to build
#                     this run (default: unlimited). Does not select a fixed
#                     window into the GitHub release list.
#   DRY_RUN           if set to 1/true/yes, only print skip/build decisions
#
# Skips non-release tags (continuous, *alpha*, *-dev*). Sets `latest` to the
# newest eligible stable (non-prerelease) GitHub release after ensuring that
# version tag exists on Docker Hub / GitLab.
set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"
case "${DRY_RUN}" in
  1|true|TRUE|yes|YES) DRY_RUN=1 ;;
  *) DRY_RUN=0 ;;
esac

: "${CI_PROJECT_NAME:?CI_PROJECT_NAME is required}"
: "${DOCKERHUB_USER:?DOCKERHUB_USER is required}"

GITHUB_REPO="buddhi1980/mandelbulber2"
DOCKERHUB_REPO="${DOCKERHUB_USER}/${CI_PROJECT_NAME}"
GITLAB_REPO="registry.gitlab.com/mandelbulber/${CI_PROJECT_NAME}"
GH_API="https://api.github.com/repos/${GITHUB_REPO}/releases?per_page=100"
DH_API="https://hub.docker.com/v2/repositories/${DOCKERHUB_REPO}/tags"

BUILT_TAGS=()

is_buildable_tag() {
  local tag="$1"
  # Keep version tags like 2.34 or 2.31-1; drop continuous/alpha/dev junk.
  [[ "$tag" =~ ^[0-9]+\.[0-9]+(-[0-9]+)?$ ]]
}

fetch_github_releases() {
  local tmp http_code
  tmp="$(mktemp)"
  http_code="$(curl -sS -o "$tmp" -w '%{http_code}' "$GH_API" || true)"
  if [[ "$http_code" != "200" ]]; then
    echo "ERROR: GitHub releases API failed (HTTP ${http_code}) for ${GITHUB_REPO}" >&2
    echo "Response body:" >&2
    cat "$tmp" >&2 || true
    rm -f "$tmp"
    exit 1
  fi
  if ! jq -e 'type == "array"' "$tmp" >/dev/null 2>&1; then
    echo "ERROR: GitHub releases API returned unexpected JSON for ${GITHUB_REPO}" >&2
    cat "$tmp" >&2 || true
    rm -f "$tmp"
    exit 1
  fi
  if [[ "$(jq 'length' "$tmp")" -eq 0 ]]; then
    echo "ERROR: GitHub releases API returned an empty list for ${GITHUB_REPO}" >&2
    rm -f "$tmp"
    exit 1
  fi
  cat "$tmp"
  rm -f "$tmp"
}

fetch_dockerhub_tags() {
  local url="$DH_API?page_size=100" page_json next
  local -a tags=()
  while [[ -n "$url" && "$url" != "null" ]]; do
    page_json="$(curl -sS "$url" || true)"
    if ! echo "$page_json" | jq -e '.results' >/dev/null 2>&1; then
      echo "ERROR: Docker Hub tags API failed for ${DOCKERHUB_REPO}" >&2
      echo "$page_json" >&2
      exit 1
    fi
    while IFS= read -r tag; do
      [[ -n "$tag" ]] && tags+=("$tag")
    done < <(echo "$page_json" | jq -r '.results[].name')
    next="$(echo "$page_json" | jq -r '.next // empty')"
    url="$next"
  done
  printf '%s\n' "${tags[@]}"
}

tag_exists_on_hub() {
  local needle="$1"
  local existing
  for existing in "${DOCKERHUB_TAGS[@]}"; do
    if [[ "$existing" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

was_built_this_run() {
  local needle="$1"
  local existing
  for existing in "${BUILT_TAGS[@]}"; do
    if [[ "$existing" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

version_available() {
  local tag="$1"
  tag_exists_on_hub "$tag" || was_built_this_run "$tag"
}

run_or_echo() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "DRY_RUN: $*"
  else
    "$@"
  fi
}

build_and_push_version() {
  local tag="$1"
  echo "BUILD: ${tag}"
  run_or_echo docker build \
    --cache-from "${GITLAB_REPO}:${tag}" \
    --build-arg "VERSION=${tag}" \
    -t "${CI_PROJECT_NAME}:${tag}" \
    .
  run_or_echo docker tag "${CI_PROJECT_NAME}:${tag}" "${GITLAB_REPO}:${tag}"
  run_or_echo docker push "${GITLAB_REPO}:${tag}"
  run_or_echo docker tag "${CI_PROJECT_NAME}:${tag}" "${DOCKERHUB_REPO}:${tag}"
  run_or_echo docker push "${DOCKERHUB_REPO}:${tag}"
  BUILT_TAGS+=("$tag")
}

ensure_latest() {
  local tag="$1"
  echo "LATEST: point latest -> ${tag}"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    if version_available "$tag"; then
      echo "DRY_RUN: would retag ${tag} as latest on GitLab and Docker Hub"
    else
      echo "ERROR: cannot set latest; ${tag} is not on Docker Hub and was not built this run" >&2
      exit 1
    fi
    return 0
  fi

  if docker image inspect "${CI_PROJECT_NAME}:${tag}" >/dev/null 2>&1; then
    docker tag "${CI_PROJECT_NAME}:${tag}" "${CI_PROJECT_NAME}:latest"
  elif tag_exists_on_hub "$tag"; then
    # Version already published; retag without rebuilding.
    docker pull "${DOCKERHUB_REPO}:${tag}"
    docker tag "${DOCKERHUB_REPO}:${tag}" "${CI_PROJECT_NAME}:latest"
  else
    echo "ERROR: cannot set latest; local and Docker Hub images for ${tag} are missing" >&2
    exit 1
  fi
  docker tag "${CI_PROJECT_NAME}:latest" "${GITLAB_REPO}:latest"
  docker push "${GITLAB_REPO}:latest"
  docker tag "${CI_PROJECT_NAME}:latest" "${DOCKERHUB_REPO}:latest"
  docker push "${DOCKERHUB_REPO}:latest"
}

echo "Fetching GitHub releases for ${GITHUB_REPO}..."
RELEASES_JSON="$(fetch_github_releases)"

mapfile -t ELIGIBLE_TAGS < <(
  echo "$RELEASES_JSON" | jq -r '
    .[]
    | select(.draft == false)
    | select(.prerelease == false)
    | .tag_name
  ' | while IFS= read -r tag; do
    if is_buildable_tag "$tag"; then
      echo "$tag"
    else
      echo "SKIP ineligible GitHub tag: ${tag}" >&2
    fi
  done
)

if [[ "${#ELIGIBLE_TAGS[@]}" -eq 0 ]]; then
  echo "ERROR: no eligible release tags found after filtering" >&2
  exit 1
fi

NEWEST_ELIGIBLE="${ELIGIBLE_TAGS[0]}"
echo "Newest eligible release: ${NEWEST_ELIGIBLE}"
echo "Eligible releases (${#ELIGIBLE_TAGS[@]}): ${ELIGIBLE_TAGS[*]}"

echo "Fetching Docker Hub tags for ${DOCKERHUB_REPO}..."
mapfile -t DOCKERHUB_TAGS < <(fetch_dockerhub_tags)
echo "Docker Hub tags (${#DOCKERHUB_TAGS[@]}): ${DOCKERHUB_TAGS[*]}"

MISSING=()
for tag in "${ELIGIBLE_TAGS[@]}"; do
  if tag_exists_on_hub "$tag"; then
    echo "SKIP exists on Docker Hub: ${tag}"
  else
    echo "MISSING on Docker Hub: ${tag}"
    MISSING+=("$tag")
  fi
done

if [[ -n "${LOOKBACK:-}" ]]; then
  if ! [[ "$LOOKBACK" =~ ^[0-9]+$ ]]; then
    echo "ERROR: LOOKBACK must be a non-negative integer (got: ${LOOKBACK})" >&2
    exit 1
  fi
  if [[ "$LOOKBACK" -gt 0 && "${#MISSING[@]}" -gt "$LOOKBACK" ]]; then
    echo "LOOKBACK=${LOOKBACK}: limiting to ${LOOKBACK} of ${#MISSING[@]} missing tags (newest first)"
    MISSING=("${MISSING[@]:0:$LOOKBACK}")
  elif [[ "$LOOKBACK" -eq 0 ]]; then
    echo "LOOKBACK=0: skipping version builds unless needed for latest"
    MISSING=()
  fi
fi

if [[ "${#MISSING[@]}" -eq 0 ]]; then
  echo "No missing version tags to build in this run."
else
  echo "Will build/push missing tags: ${MISSING[*]}"
fi

for tag in "${MISSING[@]}"; do
  build_and_push_version "$tag"
done

# Always ensure the newest eligible version exists so latest can point at it.
if ! version_available "$NEWEST_ELIGIBLE"; then
  echo "Newest eligible ${NEWEST_ELIGIBLE} still missing; building it for latest"
  build_and_push_version "$NEWEST_ELIGIBLE"
fi

ensure_latest "$NEWEST_ELIGIBLE"
echo "Done. latest -> ${NEWEST_ELIGIBLE}"
