::DO NOT USE ! OR % IN YOUR FOLDER NAMES!!!!
::IT WILL BREAK THE SCRIPT!

::Files starting with # will not be copied to your output dir
::Use this to write development notes or have files that you don't want included in a release

@echo off

::Set third parameter to 1 to enable DML1 header generation
::This is useful if you're not using a $common folder, so DML files can be written in any order.
call :make_features %1 %2 %3
::call :make_versions %1 %2

EXIT /B

::FUNCTIONS

:make_features
::MAKE FEATURES
::Designed for when you have a complicated mod with many features
::Simply place each feature into it's own folder, it becomes it's own foldeer structure
::Each feature folder will be combined in the output folder into a single folder structure,
::with overlapping files being combined.
:: 1. Iterate through each feature folder
:: 2. Write all the files from each to the destination, appending each time (not overwriting)
:: 3. Fix DML headers (ensure one is at the top of each dml file) if DML header generation is enabled
set back=%cd%

::recreate output directory
::echo %~dpnx2
rmdir /s /q "%~dpnx2"
mkdir "%~dpnx2"

::for each feature folder, copy each file to the dest folder, appending if required
for /D %%i in ("%~dpnx1\*") do (

	::This is some hacked together magic
	setlocal disableDelayedExpansion
	for /f "delims=" %%A in ('forfiles /P "%%i" /s /m *.* /c "cmd /c echo @relpath"') do (
		set "file=%%~A"
		set "ext=%%~xA"
		setlocal enableDelayedExpansion
		set "file=!file:~2!"
		
		set first_character=!file:~0,1!
		if NOT "!first_character!" == "#" (
				
			echo Writing file "%~dpnx2\!file!"		
			if "%3" == "1" (
				if !ext! == .dml (
					if not exist "%~dpnx2\!file!" (
						echo new DML file - writing DML1 header
						echo DML1> "%~dpnx2\!file!"
					)
				)
			)
			md "%~dpnx2\!file!\.." 2>NUL
			
			if exist "%~dpnx2\!file!" (
				echo: >> "%~dpnx2\!file!"
				echo: >> "%~dpnx2\!file!"
			)
			
			type "%%i\!file!" >> "%~dpnx2\!file!"
		)
		endlocal
	)
)

cd %back%
EXIT /B 0


:make_versions
::MAKE VERSIONS
::Designed for when you have a mod with a common codebase
::but should generate multiple versions which should all be slightly different
::Versioning allows you to create a $common folder, the contents of which will appear in all versions
::then you can put only the differences in each folder, and it will generate
::a complete package for each version
:: 1. Create a copy of each src folder in the destination
:: 2. Write the files from the _common folder to each folder
:: 3. Write all the files from each src to it's destination folder, appending each time (not overwriting)
set back=%cd%

::recreate output directory
::echo %~dpnx2
rmdir /s /q "%~dpnx2"
mkdir "%~dpnx2"

::for each version folder, copy over the $common folder first, and then copy across that versions files
for /D %%i in ("%~dpnx1\*") do (
	echo %%i
	echo %%~ni
	
	if NOT %%~ni == $common (
	
		::create version dir
		md "%~dpnx2\%%~ni" 2>NUL
		
		::copy over $common stuff
		if exist "%~dpnx1\$common" (
			xcopy /Q /E /I "%~dpnx1\$common" "%~dpnx2\%%~ni"
		)
		
		::This is some hacked together magic
		setlocal disableDelayedExpansion
		for /f "delims=" %%A in ('forfiles /P "%%i" /s /m *.* /c "cmd /c echo @relpath"') do (
			set "file=%%~A"
			set "ext=%%~xA"
			setlocal enableDelayedExpansion
			set "file=!file:~2!"
					
			echo Writing file "%~dpnx2\%%~ni\!file!"
				
			md "%~dpnx2\%%~ni\!file!\.." 2>NUL
			
			if exist "%~dpnx2\%%~ni\!file!" (
				echo: >> "%~dpnx2\%%~ni\!file!"
				echo: >> "%~dpnx2\%%~ni\!file!"
			)
			
			type "%%i\!file!" >> "%~dpnx2\%%~ni\!file!"
			endlocal
		)
	)
)

cd %back%
EXIT /B 0