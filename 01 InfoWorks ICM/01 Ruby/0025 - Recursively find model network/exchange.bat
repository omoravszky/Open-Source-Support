@echo off
set version=11.0
set bit=64
set script=EX_script.rb
if %bit%==32 (set "path=C:\Program Files (x86)")
if %bit%==64 (set "path=C:\Program Files")
"%path%\Innovyze Workgroup Client %version%\IExchange" ./%script% ICM
PAUSE