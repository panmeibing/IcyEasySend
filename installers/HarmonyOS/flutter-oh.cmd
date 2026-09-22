@echo off
REM HarmonyOS wrapper — always uses Flutter-OH 3.41.9, regardless of PATH.
REM Override: set FLUTTER_OH_ROOT / HOS_SDK_HOME / DEVECO_ROOT before calling.

if not defined FLUTTER_OH_ROOT set "FLUTTER_OH_ROOT=F:\flutter_flutter_ohos_341"
if not defined DEVECO_ROOT set "DEVECO_ROOT=C:\Program Files\Huawei\DevEco Studio"
set "JAVA_HOME=%DEVECO_ROOT%\jbr"

set "PATH=%JAVA_HOME%\bin;%DEVECO_ROOT%\tools\node;%DEVECO_ROOT%\tools\ohpm\bin;%DEVECO_ROOT%\tools\hvigor\bin;%FLUTTER_OH_ROOT%\bin;%PATH%"
set "FLUTTER_GIT_URL=https://gitcode.com/CPF-Flutter/flutter_flutter.git"

if defined HOS_SDK_HOME goto :sdk_ok
if exist "F:\harmony-sdk\default\sdk-pkg.json" (
  set "HOS_SDK_HOME=F:\harmony-sdk\default"
) else (
  set "HOS_SDK_HOME=%DEVECO_ROOT%\sdk\default"
)
:sdk_ok
set "DEVECO_SDK_HOME=%HOS_SDK_HOME%"

"%FLUTTER_OH_ROOT%\bin\flutter.bat" %*
