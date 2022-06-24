@ECHO off 
setlocal enabledelayedexpansion
SET "OUT=test.txt"
SET "DIR=%~dp0"
SET "XSLT=%DIR%\xsl\elicom_alix.xsl"
echo %1
echo ^<alix:corpus xmlns:alix="http://alix.casa" xmlns="http://www.w3.org/1999/xhtml"^> > %OUT%
FOR %%f IN (%1) DO (
    ECHO %%~nf
    java  -jar %DIR%\lib\saxon9.jar -xsl:%XSLT% -s:%%f filename=%%~nf >> %OUT%
)
echo ^</alix:corpus^> >> %OUT%
