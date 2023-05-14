::========== LuaSTG Sub ==========

@cd %~dp0
@cd ..
@echo %cd%

@setlocal
    :: Env

    @set LUASTG_BUILD_DIR=%cd%\engine\build
    @set LUASTG_DOC_DIR=%cd%\engine\luastg\doc
    @set DOC_DIR=%cd%\doc
    @set GAME_DIR=%cd%\game
    @set BUILD_DIR=%cd%\build
    @set TOOLS_DIR=%cd%\tools

    :: Doc

    @rmdir    %DOC_DIR%           /s /q
    @robocopy %LUASTG_DOC_DIR%    %DOC_DIR%    /e

    :: Develop

    @set LUASTG_BUILD_DEVELOP_DIR=%LUASTG_BUILD_DIR%\develop\x86\LuaSTG\Release

    @del  %GAME_DIR%\LuaSTGSub.exe
    @del  %GAME_DIR%\xaudio2_9redist.dll
    @del  %GAME_DIR%\d3dcompiler_47.dll

    @copy %LUASTG_BUILD_DEVELOP_DIR%\LuaSTG.exe             %GAME_DIR%\LuaSTGSub.exe
    @copy %LUASTG_BUILD_DEVELOP_DIR%\xaudio2_9redist.dll    %GAME_DIR%\xaudio2_9redist.dll
    @copy %LUASTG_BUILD_DEVELOP_DIR%\d3dcompiler_47.dll     %GAME_DIR%\d3dcompiler_47.dll
@endlocal

@cd engine
