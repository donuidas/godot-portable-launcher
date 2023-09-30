@echo off

CD .\game
FOR %%a IN ("..\tools\Godot_*-stable_win64.exe") DO SET exeLcn=%%a

IF NOT "%exeLcn%"=="" GOTO havegodot
ECHO download first godot
PAUSE
GOTO end
:havegodot

IF EXIST .\.import\* GOTO haveimport
IF EXIST .\.godot\* GOTO haveimport
ECHO run first the editor
PAUSE
GOTO end
:haveimport

START %exeLcn%

:end