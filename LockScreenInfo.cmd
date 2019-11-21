:: ============================================================================
:: Script  : LockScreenInfo.cmd
:: Purpose : Update Logon or Lock Screen Background Image with technical informations
:: May be scheduled on Boot and on SessionLock
:: ============================================================================
setlocal
set LOGFILE="%TEMP%\%~n0.log"
pushd "%~dp0"
set LSICONF=%~dp0
set TARGETIMAGE="%SystemRoot%\System32\oobe\info\backgrounds\backgroundDefault.jpg"
set PS1FILE=%LSICONF%LockScreenInfo.ps1
if exist "%~dp0LockScreenInfo.ps1" set PS1FILE=%~dp0LockScreenInfo.ps1
if NOT exist "%SystemRoot%\System32\oobe\info\backgrounds" md "%SystemRoot%\System32\oobe\info\backgrounds"
if exist %TARGETIMAGE% del %TARGETIMAGE%
if exist "%PS1FILE%" powershell.exe -ExecutionPolicy "UnRestricted" -File "%PS1FILE%" -TargetImage %TARGETIMAGE%
:End
popd
endlocal
exit /b 0