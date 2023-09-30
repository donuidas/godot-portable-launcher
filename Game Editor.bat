@echo off

CD .\game
FOR %%a IN ("..\tools\Godot_*-stable_win64.exe") DO SET exeLcn=%%a

IF NOT "%exeLcn%"=="" GOTO havegodot
ECHO download first godot
PAUSE
GOTO end
:havegodot

START %exeLcn% -e

:end