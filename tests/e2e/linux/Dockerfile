# Copyright 2026 Han Li and contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# No Dart here on purpose: dart may only come from what vfox installs from the
# official archive. zip packs the plugin under test; curl fetches vfox.
RUN set -o errexit -o nounset -o xtrace; \
    apt-get update; \
    apt-get install --assume-yes --no-install-recommends ca-certificates curl zip; \
    rm --recursive --force /var/lib/apt/lists/*

COPY metadata.lua /e2e/metadata.lua
COPY hooks /e2e/hooks
COPY lib /e2e/lib

# Long-lived container: the Go test drives every phase through exec calls.
CMD ["sleep", "infinity"]
