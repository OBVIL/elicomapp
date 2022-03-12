@ECHO off 
setlocal enabledelayedexpansion
SET "DIR=%~dp0"
SET "XSLT=%DIR%\xsl\elicom_alix.xsl"

echo ^<alix:corpus xmlns:alix="http://alix.casa" xmlns="http://www.w3.org/1999/xhtml"^> > voltalix.xml
FOR %%f IN (%1\*.xml) DO (
    ECHO %%~nf
    java  -jar %DIR%\lib\saxon9.jar -xsl:%XSLT% -s:%%f filename=%%~nf >> voltalix.xml
)
echo ^</alix:corpus^> >> voltalix.xml
