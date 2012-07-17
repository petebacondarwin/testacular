@IF EXIST "%~dp0\node.exe" (
  "%~dp0\node.exe"  "%~dp0\testacular-run" %*
) ELSE (
  node  "%~dp0\testacular-run" %*
)