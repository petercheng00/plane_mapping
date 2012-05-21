@echo off 
rem CopyNewer.bat   Version 0.0.1, 2011-4-25, Binglong’s Space 
rem %1 = src_dir 
rem %2 = dst_dir 
rem %3 = fn1 
rem %4 = fn2 
rem …

setlocal EnableDelayedExpansion

rem insufficient arguments, go to usage. 
IF .%3==. GOTO USAGE

set SRC_DIR=%1 
set DST_DIR=%2 
rem remove trailing slash in SRC_DIR 
IF !SRC_DIR:~-1!==\ SET "SRC_DIR=!SRC_DIR:~0,-1!"

rem @echo SRC_DIR=%SRC_DIR%  DST_DIR=%DST_DIR%

IF NOT EXIST %SRC_DIR% GOTO SRC_DIR_NONEXISTING 
IF EXIST %DST_DIR% GOTO START_COPY

:CREATE_DST_DIR 
mkdir %DST_DIR% 
IF %ERRORLEVEL% NEQ 0 GOTO DST_DIR_CANNOT_BE_CREATED

:START_COPY 
IF .%3==. GOTO QUIT 
set FILENAME=%3 
@echo COPY %FILENAME%  %SRC_DIR% =^> %DST_DIR% 
xcopy /d /y %SRC_DIR%\%FILENAME% %DST_DIR% >NUL 
rem @echo %ERRORLEVEL% 
rem process next filename argument 
SHIFT 
GOTO START_COPY

: DST_DIR_CANNOT_BE_CREATED 
@echo Cannot create destination directory %DST_DIR% 
goto QUIT

:SRC_DIR_NONEXISTING 
@echo Source directory doest not exist: %SRC_DIR% 
goto QUIT

:USAGE 
@echo. 
@echo Copy Newer(dated) Files from source directory to destination directory. 
@echo   – It silently overwrites files if they are older. 
@echo   – It creates destination directory if needed. 
@echo This tool is intended to be used in Visual Studio build events. 
@echo. 
@echo    (c)2011 Binglong’s Space 
@echo. 
@echo Usage: %0 SRC_DIR DST_DIR FN1 FN2 FN3 … 
@echo        FN1, FN2, FN3 are filenames (could be *,? etc as in COPY)

:QUIT 
@echo on