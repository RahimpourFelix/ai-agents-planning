#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is not installed or not on PATH." >&2
  exit 1
fi

if [[ "${AWS_ACCESS_KEY_ID:-}" == "" ]]; then
  printf "Hetzner Object Storage access key: "
  read -r AWS_ACCESS_KEY_ID
  export AWS_ACCESS_KEY_ID
fi

if [[ "${AWS_SECRET_ACCESS_KEY:-}" == "" ]]; then
  printf "Hetzner Object Storage secret key: "
  read -rs AWS_SECRET_ACCESS_KEY
  printf "\n"
  export AWS_SECRET_ACCESS_KEY
fi

args=("$@")

if [[ ${#args[@]} -gt 0 && "${args[0]}" == "init" ]]; then
  has_backend_config=false
  for arg in "${args[@]}"; do
    if [[ "$arg" == "-backend-config=backend.hcl" ]] || [[ "$arg" == "backend.hcl" ]]; then
      has_backend_config=true
      break
    fi
  done

  if [[ "$has_backend_config" == false && -f "$script_dir/backend.hcl" ]]; then
    args+=("-backend-config=backend.hcl")
  fi
fi

terraform "${args[@]}"
