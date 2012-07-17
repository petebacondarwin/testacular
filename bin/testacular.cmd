@IF EXIST "%~dp0\node.exe" (
  "%~dp0\node.exe"  "%~dp0\testacular" %*
) ELSE (
  node  "%~dp0\testacular" %*
)