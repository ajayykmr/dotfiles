@echo off
REM Not managed by chezmoi: run it from a clone of the dotfiles repo on Windows, and edit it in the repo.

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "FEDORA_ID="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "$b=(bcdedit /enum firmware | Out-String) -split '(?:\r?\n){2,}'; $m=$b | Where-Object { $_ -match 'shimx64' } | Select-Object -First 1; if(-not $m){$m=$b | Where-Object { $_ -match 'Fedora' } | Select-Object -First 1}; if($m -match '(\{[0-9a-fA-F-]{36}\})'){$Matches[1]}"`) do set "FEDORA_ID=%%I"

if not defined FEDORA_ID (
    echo Could not find the Fedora firmware entry. Entries found:
    bcdedit /enum firmware
    pause
    exit /b 1
)

echo Fedora entry: %FEDORA_ID%

bcdedit /set "{fwbootmgr}" displayorder "%FEDORA_ID%" /addfirst

if errorlevel 1 (
    echo Failed to put Fedora first in the firmware boot order.
    pause
    exit /b 1
)

shutdown /r /t 0
