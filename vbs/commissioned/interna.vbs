set Wshshell = WScript.CreateObject("WScript.Shell")

' set LOCALES

WshShell.Regwrite "HKCU\control Panel\International\iCountry", "44" 
WshShell.Regwrite "HKCU\control Panel\International\iCurrDigits", "2" 
WshShell.Regwrite "HKCU\control Panel\International\iCurrency", "0" 
WshShell.Regwrite "HKCU\control Panel\International\iDate", "1" 
WshShell.Regwrite "HKCU\control Panel\International\iDigits", "2" 
WshShell.Regwrite "HKCU\control Panel\International\iCurrDigits", "2" 
WshShell.Regwrite "HKCU\control Panel\International\iLzero", "1" 
WshShell.Regwrite "HKCU\control Panel\International\iMeasure", "0"
WshShell.Regwrite "HKCU\control Panel\International\iNegCurr", "1" 
WshShell.Regwrite "HKCU\control Panel\International\iTime", "1" 
WshShell.Regwrite "HKCU\control Panel\International\iTLzero", "1" 
WshShell.Regwrite "HKCU\control Panel\International\Locale", "00000809"
WshShell.Regwrite "HKCU\control Panel\International\s1159", "AM" 
WshShell.Regwrite "HKCU\control Panel\International\s2359", "PM"
WshShell.Regwrite "HKCU\control Panel\International\sCountry", "United Kingdom"
WshShell.Regwrite "HKCU\control Panel\International\sCurrency", "�"
WshShell.Regwrite "HKCU\control Panel\International\sDate", "/"
WshShell.Regwrite "HKCU\control Panel\International\sDecimal", "."
WshShell.Regwrite "HKCU\control Panel\International\sLanguage", "ENG"
WshShell.Regwrite "HKCU\control Panel\International\sList", ","
WshShell.Regwrite "HKCU\control Panel\International\sLongDate", "dd MMMM yyyy"
WshShell.Regwrite "HKCU\control Panel\International\sShortDate", "dd/MM/yyyy"
WshShell.Regwrite "HKCU\control Panel\International\sThousand", ","
WshShell.Regwrite "HKCU\control Panel\International\sTime", ":"
WshShell.Regwrite "HKCU\control Panel\International\sTimeFormat", "HH:mm:ss"
WshShell.Regwrite "HKCU\control Panel\International\iTimePrefix", "0"
WshShell.Regwrite "HKCU\control Panel\International\sMonDecimalSep", "0"
WshShell.Regwrite "HKCU\control Panel\International\sMonThousandSep", ","
WshShell.Regwrite "HKCU\control Panel\International\iNegNumber", "1"
WshShell.Regwrite "HKCU\control Panel\International\sNativeDigits", "0123456789"
WshShell.Regwrite "HKCU\control Panel\International\NumShape", "1"
WshShell.Regwrite "HKCU\control Panel\International\icalendartype", "1"
WshShell.Regwrite "HKCU\control Panel\International\iFirstDayOfWeek", "0"
WshShell.Regwrite "HKCU\control Panel\International\IfirstDayOfYear", "0"
WshShell.Regwrite "HKCU\control Panel\International\sGrouping", "3;0"
WshShell.Regwrite "HKCU\control Panel\International\sMonGrouping", "3;0"
WshShell.Regwrite "HKCU\control Panel\International\sPositiveSign", ""
WshShell.Regwrite "HKCU\control Panel\International\sNegativeSign", "-"
WshShell.Regwrite "HKCU\control Panel\International\Geo\Nation", "242"

' TimeZone 

Wshshell.Regwrite "HKLM\SYSTEM\Controlset001\TimeZoneInformation\Bias", "00000000", "REG_DWORD"
Wshshell.Regwrite "HKLM\SYSTEM\Controlset001\TimeZoneInformation\StandardName", "GMT Standard Time"
Wshshell.Regwrite "HKLM\SYSTEM\Controlset001\TimeZoneInformation\StandardBias", "00000000", "REG_DWORD"
Wshshell.Regwrite "HKLM\SYSTEM\Controlset001\TimeZoneInformation\StandardStart", "00 00 0a 00 05 00 02 00 00 00 00 00 00 00 00 00"
Wshshell.Regwrite "HKLM\SYSTEM\controlset001\TimeZoneInformation\DaylightName", "GMT Daylight Time"
Wshshell.Regwrite "HKLM\SYSTEM\controlset001\TimeZoneInformation\DaylightBias", "ffffffc4"
Wshshell.Regwrite "HKLM\SYSTEM\controlset001\TimeZoneInformation\DaylightStart", "00 00 03 00 05 00 01 00 00 00 00 00 00 00 00 00"
Wshshell.RegWrite "HKLM\SYSTEM\controlset001\TimeZoneInformation\ActiveTimeBias", "ffffffc4"

' kEYBOARD lAYOUT SETS UK CHANGES WILL NOT TAKE EFFECT UNTIL USER NEXTS LOGON 

Wshshell.Regwrite "HKCU\Keyboard Layout\Preload\1", "00000809"




