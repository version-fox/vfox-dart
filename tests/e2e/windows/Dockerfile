# escape=`
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

FROM mcr.microsoft.com/windows/servercore:ltsc2022

SHELL ["powershell", "-NoProfile", "-Command"]

# PowerShell 7 is what vfox's `activate pwsh` targets. A zip, not the MSI:
# extraction is quicker and leaves the machine PATH to us. No Dart here on
# purpose: dart may only come from what vfox installs from the archive.
# Single quotes only: the classic builder wraps RUN in powershell -Command
# through cmd.exe, where double quotes and backticks break parsing.
RUN $ErrorActionPreference='Stop'; $p='C:\Program Files\PowerShell\7'; New-Item -ItemType Directory -Force -Path $p | Out-Null; curl.exe -fsSL --retry 3 --retry-all-errors -o C:\pwsh.zip https://github.com/PowerShell/PowerShell/releases/download/v7.6.6/PowerShell-7.6.6-win-x64.zip; tar.exe -xf C:\pwsh.zip -C $p; Remove-Item C:\pwsh.zip; if (-not (Test-Path -Path ($p + '\pwsh.exe'))) { throw 'pwsh.exe is missing' }; [Environment]::SetEnvironmentVariable('PATH', [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';C:\Program Files\PowerShell\7', 'Machine')

WORKDIR C:\e2e

COPY metadata.lua C:\e2e\metadata.lua
COPY hooks C:\e2e\hooks
COPY lib C:\e2e\lib

# Long-lived container: the Go test drives every phase through pwsh execs.
ENTRYPOINT ["C:/Program Files/PowerShell/7/pwsh.exe", "-NoProfile", "-Command"]
CMD ["while ($true) { Start-Sleep 3600 }"]
