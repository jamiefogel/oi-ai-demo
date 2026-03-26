#!/usr/bin/env bash
set -euo pipefail

# Run from repo root.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${REPO_ROOT}/data"
ZIP_PATH="${DATA_DIR}/tract_outcomes.zip"
UNZIP_DIR="${DATA_DIR}/tract_outcomes"
CSV_PATH="${UNZIP_DIR}/tract_outcomes_early.csv"

SOURCE_URL="https://www2.census.gov/ces/opportunity/tract_outcomes.zip"
LOCAL_CACHE="/Users/jfogel/workforce_notes/opportunity_atlas_mobility/data/tract_outcomes.zip"

mkdir -p "${DATA_DIR}" "${UNZIP_DIR}"

if [[ -f "${ZIP_PATH}" ]]; then
  echo "Using existing ${ZIP_PATH}"
elif [[ -f "${LOCAL_CACHE}" ]]; then
  echo "Copying cached zip from ${LOCAL_CACHE}"
  cp "${LOCAL_CACHE}" "${ZIP_PATH}"
else
  echo "Downloading ${SOURCE_URL}"
  curl -L -o "${ZIP_PATH}" "${SOURCE_URL}"
fi

echo "Unzipping data..."
unzip -o -q "${ZIP_PATH}" -d "${UNZIP_DIR}"

if [[ ! -f "${CSV_PATH}" ]]; then
  echo "Expected file not found: ${CSV_PATH}" >&2
  exit 1
fi

echo "Done: ${CSV_PATH}"
