@echo off

CD .\tools

SET /p ver=<.\godot.txt
SET "download=bitsadmin /transfer Godot /download /priority normal"
%download% "https://downloads.tuxfamily.org/godotengine/%ver%/Godot_v%ver%-stable_win64.exe.zip" %cd%\tmp.zip

.\7za\7za.exe x -aoa tmp.zip 

RM .\tmp.zip

PAUSE
::TIMEOUT /T 10