@echo off
setlocal enabledelayedexpansion
set "file=%1"
set "tempfile=%file%.tmp"

(
  for /f "tokens=*" %%a in ('type "%file%"') do (
    set "line=%%a"
    if "!line:~0,5!"=="pick " (
      set "hash=!line:~5,7!"
      if "!hash!"=="3985736" (
        echo squash !line:~5!
      ) else if "!hash!"=="913d8bc" (
        echo squash !line:~5!
      ) else if "!hash!"=="cf47054" (
        echo reword !line:~5!
      ) else (
        echo !line!
      )
    ) else (
      echo !line!
    )
  )
) > "%tempfile%"

move /y "%tempfile%" "%file%" >nul
