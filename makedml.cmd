::DO NOT USE ! OR % IN YOUR FOLDER NAMES!!!!
::IT WILL BREAK THE SCRIPT!

::Files starting with # will not be copied to your output dir
::Use this to write development notes or have files that you don't want included in a release

::@echo off

::Set third parameter to 1 to enable DML1 header generation
::This is useful if you're not using a $common folder, so DML files can be written in any order.
if "%1" == "-f" (
	call :make_features %2 %3 %4 %5 %6 %7 %8 %9
) else if "%1" == "-v" (
	call :make_versions %2 %3 %4 %5 %6 %7 %8 %9
) else (
	echo MakeDML version 0.1
	echo:
	echo usage:
	echo for feature mode
	echo 	%~nx0 -f $source_dir $destination_dir [$headers1] [$headers2] [$headers3] [$headers4]...
	echo or for version mode
	echo 	%~nx0 -v $source_dir $destination_dir [$headers1] [$headers2] [$headers3] [$headers4]...
	echo:
	echo Feature Mode:
	echo The structure of each subfolder of $source_dir will be copied into $destination_dir in sequence.
	echo Files that exist in multiple folders will be concatenated together with a new line.
	echo After this, add an optional list of dml headers to add, based on folder name.
	echo Adding headers will also add the DML1 header automatically
	echo See the "headers" folder for examples
	echo.
	echo Version Mode:
	echo Each subfolder of $source_dir will be made independently into a separate version of the project,
	echo as if feature mode was run for that subfolder.
	echo Additionally, the contents of the $common version folder will be added to each version of the mod before building.
	echo You may also use $core instead of $common, which will also be added to each version of the mod but will additionally
	echo be built as a standalone version as well. This is useful for versions of the mod with "addons" integrated, so to speak.
	echo Lastly, by using $main, you can build a version which will inherit the base folder name only, rather than using the
	echo standard "Folder Name - Version" syntax, which is useful for making "main" mods and then adding "addons" to them
	echo.
	echo Usage example: Build DML files in feature mode with DML1 headers, as well as SCP and Vanilla fingerprints:
	echo 	%~nx0 -f "<project>\src" "<project>\out" "vanilla" "scp"
	pause
)

EXIT /B

::FUNCTIONS

:populate_header

::Do not include headers for gamesys.dml, since
::usually it's automaticlaly applied to a gamesys
if "%~nx1" == "gamesys.dml" (
	EXIT /B 0
)

if exist "%~dp0headers\%~2\$common.dml" (
	echo.>> "%~1"
	echo.>> "%~1"
	type "%~dp0headers\%~2\$common.dml" >> "%~1"
)
if exist "%~dp0headers\%~2\%~nx1" (
	echo.>> "%~1"
	echo.>> "%~1"
	type "%~dp0headers\%~2\%~nx1" >> "%~1"
)

EXIT /B 0

::Create DML1 headers
:populate_headers
if not exist "%~1" (
	::echo new DML file - writing DML1 header
	echo 	-- Writing DML Header to new file %~1
	
	::No headers specified in command line, do nothing as no auto generation should happen
	if NOT "%~2%~3%~4%~5%~6%~7%~8" == "" (
		echo|set /p="DML1"> "%~1"
	)
	call :populate_header %1 %2
	call :populate_header %1 %3
	call :populate_header %1 %4
	call :populate_header %1 %5
	call :populate_header %1 %6
	call :populate_header %1 %7
	call :populate_header %1 %8
)
EXIT /B 0

::recreate output directory
:make_out_dir
::echo %~dpnx1
rmdir /s /q "%~dpnx1" 2>NUL
mkdir "%~dpnx1"
echo Outputting to %~dpnx1
EXIT /B 0


::for each feature folder, copy each file to the dest folder, appending if required
:make_feature_folder
setlocal enableDelayedExpansion
for /D %%i in ("%~dpnx1\*") do (
	set "folder_name=%%~ni"
	if "!folder_name:~0,1!" == "#" (
		echo Skipping ignored feature !folder_name!
	) else (
		echo Including feature !folder_name!
		::This is some hacked together magic
		for /f "delims=" %%A in ('forfiles /P "%%i" /s /m *.* /c "cmd /c echo @relpath"') do (
			set "file=%%~A"
			set "ext=%%~xA"
			set "file=!file:~2!"
			set "basename=%%~nA"		
			set first_character=!basename:~0,1!
			
			if NOT "!first_character!" == "#" (
				if !ext! == .dml (
					call :populate_headers "%~dpnx2\!file!" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
				)
				md "%~dpnx2\!file!\.." 2>NUL
				
				if exist "%~dpnx2\!file!" (
					echo 	-- Appending to file !file! !dml!
					echo.>> "%~dpnx2\!file!"
					echo.>> "%~dpnx2\!file!"
				) else (
					echo 	-- Writing new file !file! !dml!
				)
				
				type "%%i\!file!" >> "%~dpnx2\!file!"
			) else (
				echo 	-- Skipping file !file!
			)
		)
	)
)
endlocal
EXIT /B 0

::MAKE FEATURES
::Designed for when you have a complicated mod with many features
::Simply place each feature into it's own folder, it becomes it's own foldeer structure
::Each feature folder will be combined in the output folder into a single folder structure,
::with overlapping files being combined.
:: 1. Iterate through each feature folder
:: 2. Write all the files from each to the destination, appending each time (not overwriting)
:: 3. Fix DML headers (ensure one is at the top of each dml file) if DML header generation is enabled
:make_features

set back=%cd%

::remake output dir
call :make_out_dir %2

call :make_feature_folder %1 %2 %3 %4 %5 %6 %7 %8 %9

cd %back%
EXIT /B 0

:make_versions
::MAKE VERSIONS
::Designed for when you have a mod with a common codebase
::but should generate multiple versions which should all be slightly different
::Version folders appear above feature folders
::All version folder will be treated as if feature mode was run for that version,
::But will also contain all the folders from the $common folder
::Running in version mode will create
::a complete package for each version
:: 1. Create a copy of each src folder in the destination
:: 2. Write the files from the $common folder to each folder
:: 3. Write all the files from each src to it's destination folder, appending each time (not overwriting)
set back=%cd%

::remake output dir
call :make_out_dir %2

setlocal enableDelayedExpansion
for /D %%i in ("%~dpnx1\*") do (
	
	set "folder_name=%%~ni"
	
	if "!folder_name:~0,1!" == "#" (
		echo Skipping ignored version !folder_name!
	)
	if "!folder_name!" == "$common" (
		echo Skipping common version folder !folder_name!
	) else if "!folder_name!" == "$core" (
		echo "Making core version..."
		mkdir "%~nx2\%%~nxi"
		call :make_feature_folder "%~nx1\%%~nxi" "%~nx2\%%~nxi" %3 %4 %5 %6 %7 %8 %9
	) else (
		echo "Making version !folder_name!..."
		mkdir "%~nx2\%%~nxi"
		
		if exist "%~dpnx1\$common" (
			call :make_feature_folder "%~nx1\$common" "%~nx2\%%~nxi" %3 %4 %5 %6 %7 %8 %9
		)
		
		if exist "%~dpnx1\$core" (
			call :make_feature_folder "%~nx1\$core" "%~nx2\%%~nxi" %3 %4 %5 %6 %7 %8 %9
		)
		
		call :make_feature_folder "%~nx1\%%~nxi" "%~nx2\%%~nxi" %3 %4 %5 %6 %7 %8 %9
	)
	
)
endlocal

cd %back%
EXIT /B 0