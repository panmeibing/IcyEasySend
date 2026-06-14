#!/usr/bin/env bash
# Shared helpers to locate Flutter Linux release bundles and map them to Debian arch names.
set -euo pipefail

APP_NAME="${APP_NAME:-IcyEasySend}"

host_to_flutter_arch() {
  case "$(uname -m)" in
    x86_64) echo "x64" ;;
    aarch64|arm64) echo "arm64" ;;
    riscv64) echo "riscv64" ;;
    *) echo "" ;;
  esac
}

to_deb_arch() {
  local hint="${1:-}"
  case "${hint}" in
    *x86-64*|*x86_64*|amd64) echo "amd64" ;;
    *aarch64*|*ARM*64*|arm64) echo "arm64" ;;
    *RISC-V*|*riscv64*) echo "riscv64" ;;
    i386|i686) echo "i386" ;;
    armhf|*ARM*,*EABI*) echo "armhf" ;;
    *) echo "" ;;
  esac
}

detect_deb_arch_from_binary() {
  local binary="$1"
  if [[ ! -f "${binary}" ]] || ! command -v file >/dev/null 2>&1; then
    return 1
  fi
  to_deb_arch "$(file -b "${binary}")"
}

find_release_bundle() {
  local root="$1"
  local host_arch preferred bundle

  host_arch="$(host_to_flutter_arch)"
  preferred="${root}/build/linux/${host_arch}/release/bundle"
  if [[ -x "${preferred}/${APP_NAME}" ]]; then
    echo "${preferred}"
    return 0
  fi

  local -a candidates=()
  shopt -s nullglob
  for bundle in "${root}"/build/linux/*/release/bundle; do
    if [[ -x "${bundle}/${APP_NAME}" ]]; then
      candidates+=("${bundle}")
    fi
  done
  shopt -u nullglob

  if [[ ${#candidates[@]} -eq 0 ]]; then
    return 1
  fi
  if [[ ${#candidates[@]} -eq 1 ]]; then
    echo "${candidates[0]}"
    return 0
  fi

  for bundle in "${candidates[@]}"; do
    if [[ "${host_arch}" != "" && "${bundle}" == *"/linux/${host_arch}/"* ]]; then
      echo "${bundle}"
      return 0
    fi
  done

  echo "${candidates[0]}"
}

resolve_bundle_and_arch() {
  local root="$1"
  local bundle arch

  bundle="$(find_release_bundle "${root}")" || return 1
  arch="$(detect_deb_arch_from_binary "${bundle}/${APP_NAME}" || true)"
  if [[ -z "${arch}" ]]; then
    case "$(uname -m)" in
      x86_64) arch="amd64" ;;
      aarch64|arm64) arch="arm64" ;;
      riscv64) arch="riscv64" ;;
      *) return 1 ;;
    esac
  fi

  printf '%s\n%s\n' "${bundle}" "${arch}"
}
