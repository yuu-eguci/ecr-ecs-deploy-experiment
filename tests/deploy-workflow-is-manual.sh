#!/usr/bin/env sh
# Guard: aws.yml must only run on manual dispatch (workflow_dispatch),
# so that no push or pull request can start an AWS deployment by accident.
set -eu

workflow="${1:-.github/workflows/aws.yml}"

triggers="$(yq -r '.on | keys | join(",")' "$workflow")"

if [ "$triggers" != "workflow_dispatch" ]; then
  echo "NG: $workflow must only be triggered by workflow_dispatch (found: $triggers)" >&2
  exit 1
fi

echo "OK: $workflow runs on manual dispatch only"
