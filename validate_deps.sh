#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

declare -A DEPS

DEPS=( [ruby]='3.0.0'
       [terraform]='v1.5.4'
       [aws]='2.13.4'
       [bundler]='2.2.3'
       [rvm]='1.29.12'
)

for dep in "${!DEPS[@]}"; do
  printf "checking for %s version %s..." "$dep" "${DEPS[$dep]}"
  (command -v "$dep">/dev/null) || printf "\n\tUnable to find %s...\n" "$dep"
  _version="$($dep --version)"
  [[ "$_version" =~ "${DEPS[$dep]}" ]] || printf "\n\t%s installed but version is %s...\n" "$dep" "$_version"
  printf "Done.\n"
done
