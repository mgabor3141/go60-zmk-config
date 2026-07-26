@echo off

setlocal enabledelayedexpansion

set IMAGE=go60-zmk-config-docker

:: Set revision from first parameter, default to the reviewed pin if not provided
if "%~1"=="" (
	set REVISION=5b071c50500ecbf45545516789160e21c83ce190
) else (
	set REVISION=%~1
)

:: Build Docker image
docker build -t "%IMAGE%" .

:: Run Docker container
docker run --rm -v "%cd%:/config" -v go60-zmk-src:/zmk -v go60-build-cache:/build -e UID=0 -e GID=0 -e REVISION="%REVISION%" "%IMAGE%"

endlocal
