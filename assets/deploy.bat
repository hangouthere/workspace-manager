SET DEPLOY_VERSION="1.0.1"

SET AHK2EXE="C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
SET ZIP="C:\Program Files\7-Zip\7z.exe"

SET CONFIG=.\WorkSpaceConfig.json
SET BUILD=.\_build
SET DEPLOY=.\_deploy
SET ICON=.\assets/app.ico
SET ZIP_NAME=WorkSpaceManager_v%DEPLOY_VERSION%.zip

SET IN_MANAGER=.\index.ahk
SET OUT_MANAGER=%BUILD%/wsmgr.exe
SET IN_EDITOR=.\WorkspaceEditor.ahk
SET OUT_EDITOR=%BUILD%/wseditor.exe

mkdir %BUILD%
mkdir %DEPLOY%

%AHK2EXE% /in %IN_MANAGER% /out %OUT_MANAGER% /icon %ICON% /mpress 1
%AHK2EXE% /in %IN_EDITOR% /out %OUT_EDITOR% /icon %ICON% /mpress 1

copy %CONFIG% %BUILD%
copy .\crosshair.ico %BUILD%

%ZIP% a -tzip %DEPLOY%/%ZIP_NAME% %BUILD%\*

rmdir /q/s %BUILD%