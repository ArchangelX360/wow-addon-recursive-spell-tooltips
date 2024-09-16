@echo off
setlocal enabledelayedexpansion
set addon_name=RecursiveSpellTooltip
set addon_dir=C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\%addon_name%
echo %date% %time% 🚀 Installing '%addon_name%' add-on...
if exist "%addon_dir%" (
    rmdir /s /q "%addon_dir%"
)
mkdir "%addon_dir%"
xcopy /e /i /y src "%addon_dir%"
echo %date% %time% ✅ Add-on '%addon_name%' installed in '%addon_dir%'.
dir /a "%addon_dir%"
echo %date% %time% Don't forget to '/reload' in the game!
endlocal
pause
