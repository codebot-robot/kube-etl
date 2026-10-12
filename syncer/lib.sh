# Copyright 2026 Google LLC
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

# lib.sh holds the names and helpers shared by deploy.sh and cleanup.sh.
# It is sourced, not executed.

CONTROLLER_NAMESPACE="krmsyncer-system"
CONTROLLER_DEPLOYMENT="krmsyncer-controller-manager"
KRMSYNCER_CRD="krmsyncers.syncer.gkelabs.io"

# Kubernetes ServiceAccount of the controller (config/rbac/service_account.yaml).
CONTROLLER_KSA="krmsyncer-controller-manager"

sha256_hex() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{ print $1 }'
  else
    shasum -a 256 | awk '{ print $1 }'
  fi
}

# gsa_name prints the name of the controller's Google Service Account for
# destination cluster $2 in location $1: krmsyncer-<cluster prefix>-<hash>, at
# most 29 characters (GSA IDs are limited to 30). The hash covers the location
# and name, so clusters with the same name in different locations, or names
# sharing a truncated prefix, get different GSAs.
gsa_name() {
  local location="$1" cluster="$2" hash prefix
  hash="$(printf '%s' "${location}/${cluster}" | sha256_hex)"
  hash="${hash:0:6}"
  prefix="${cluster,,}"
  prefix="${prefix//[^a-z0-9-]/-}"
  prefix="${prefix:0:12}"
  while [[ "${prefix}" == *- ]]; do prefix="${prefix%-}"; done
  if [[ -n "${prefix}" ]]; then
    printf 'krmsyncer-%s-%s\n' "${prefix}" "${hash}"
  else
    printf 'krmsyncer-%s\n' "${hash}"
  fi
}

# gsa_description prints the description deploy.sh sets on the GSA it creates
# for destination cluster $1 (<project>/<location>/<cluster>). Both scripts
# use it to check that a GSA belongs to that cluster.
gsa_description() {
  printf 'KRMSyncer controller for destination cluster %s\n' "$1"
}
