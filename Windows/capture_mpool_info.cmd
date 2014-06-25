@echo off
rem ************************************************
rem * This script captures Memory Pool information *
rem * using the support tools utility, poolmon.exe *
rem * the utility must be installed.               *
rem ************************************************

set LogDir=F:\memory_pool\

rem date and time variables
for /f "tokens=1,2" %%u in ('date /t') do set d=%%v
for /f "delims=|" %%u in ('time /t') do set t=%%u
rem if "%t:~1,1%"==":" set t=0%t%
rem set timestr=%d:~6,4%%d:~3,2%%d:~0,2%%t:~0,2%%t:~3,2%
set datestr=%d:~6,4%%d:~0,2%%d:~3,2%
set timestr=%t:~0,2%%t:~3,2%%t:~6,2% 

echo %t%
echo %datestr%
echo %timestr%

poolmon -b -n "%LogDir%poolmon_%datestr%.%timestr%.log.txt"

exit
