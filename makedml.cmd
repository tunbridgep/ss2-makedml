::DO NOT USE ! OR % IN YOUR FOLDER NAMES!!!!
::IT WILL BREAK THE SCRIPT!

::Files starting with # will not be copied to your output dir
::Use this to write development notes or have files that you don't want included in a release

@echo off

if "%1" == "-f" (
	call :make_features %2 %3 %4 %5 %6 %7 %8 %9
) else if "%1" == "-v" (
	call :make_versions %2 %3 %4 %5 %6 %7 %8 %9
) else if "%1" == "-z" (
	call :zip %2 %3 %4 %5
) else (
	echo MakeDML version 0.1
	echo:
	echo Usage:
	echo for feature mode
	echo 	%~nx0 -f $source_dir $destination_dir [$headers1] [$headers2] [$headers3] [$headers4]...
	echo or for version mode
	echo 	%~nx0 -v $source_dir $destination_dir [$headers1] [$headers2] [$headers3] [$headers4]...
	echo or for zip mode
	echo 	%~nx0 -z ^(-v or -f^) $destination_dir $modname [$main_file_name]
	echo:
	echo.
	echo Feature Mode ^(-f^):
	echo.
	echo The structure of each subfolder of $source_dir will be copied into $destination_dir in sequence.
	echo Files that exist in multiple folders will be concatenated together with a new line.
	echo.
	echo After this, add an optional list of dml headers to add, based on folder name.
	echo Adding headers will also add the DML1 header automatically
	echo.
	echo See the "headers" folder for examples
	echo.
	echo.
	echo Version Mode ^(-v^):
	echo.
	echo Each subfolder of $source_dir will be made independently into a separate version of the project,
	echo as if feature mode was run for that subfolder.
	echo.
	echo Additionally, the contents of the $common and $core version folders will be added to each version of the mod before building.
	echo The main difference is that $common will not be made as a standalone version, but $core will.
	echo Any version directories starting with "$" will be built standalone and will not have the contents of $common or $core added
	echo.
	echo.
	echo Zip Mode ^(-z, then -f or -v^):
	echo.
	echo If zip mode is run with -f, the contents of the specified $destination_dir will be zipped
	echo using the specified $modname as "$modname.7z"
	echo in the current directory
	echo.
	echo If zip mode is run with -v, each subfolder of the specified $destination_dir will be zipped
	echo into "$modname - ^<version name^>.7z" and placed in a zips folder in the current directory
	echo in the current directory.
	echo.
	echo When building Version mode, any directory named $core or $main will use only
	echo the mod name, not the version name for their zip ^("$modname.7z"^)
	echo or, if the $main_file_name variable is set, will use ^("$modname - $main_file_name.7z"^)
	echo.
	echo In all cases, any starting "$" characters will be removed from version suffixes.
	echo.
	echo.
	echo Additional Notes:
	echo.
	echo Any file or folder beginning with the # character will not be copied into the built version
	echo Use this for creating todos or other files which are relevant to the mod but shouldn't be shipped
	echo.
	echo Usage example: Build DML files in feature mode with DML1 headers, as well as SCP and Vanilla fingerprints:
	echo 	%~nx0 -f "<project>\src" "<project>\out" "vanilla" "scp"
)

EXIT /B

::FUNCTIONS

:zip

if "%~3" == "" (
	echo zip: Invalid mod name specified: "%~3"
	EXIT /B 0
)

if "%1" == "-f" (
	@del "%~3.7z"
	7z a "%~3.7z" "%~dpn2\*"
) else if "%1" == "-v" (
	rmdir /s /q ".\zips" 2>NUL
	mkdir ".\zips"
	
	setlocal enableDelayedExpansion
		for /D %%i in ("%~dpn2\*") do (
		
			rem Set the version name, but we need to remove the trailing "$" if it exists
			set "version_name=%%~ni"
			if "!version_name:~0,1!" == "$" (
				set "version_name=!version_name:~1!"
			)

			if "%%~ni" == "$core" (
				if not "%~n4" == "" (
					7z a ".\zips\%~3 - %~n4.7z" "%%~i\*"
				) else (
					7z a ".\zips\%~3.7z" "%%~i\*"
				)
			) else if "%%~ni" == "$main" (
				if not "%~n4" == "" (
					7z a ".\zips\%~3 - %~n4.7z" "%%~i\*"
				) else (
					7z a ".\zips\%~3.7z" "%%~i\*"
				)
			) else (
				7z a ".\zips\%~3 - !version_name!.7z" "%%~i\*"
			)
		)
	endlocal
)

EXIT /B 0

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
	echo 	-- Writing DML Header to new file %~nx1
	
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
			set "outfile=!file!"
			set "basename=%%~nA"		
			set first_character=!basename:~0,1!
			
			rem Delete existing file in output if we are set to "replace"
			if "!first_character!" == "$" (
				set "delfile=!file:~1!"
				set "outfile=!file:~1!"
				echo 	-- File %%~nxA is set to overwrite^^!
				@del "%~dpnx2\!delfile!" 2>NUL
			)
			
			if NOT "!first_character!" == "#" (
				if !ext! == .dml (
					call :populate_headers "%~dpnx2\!outfile!" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
				)
				md "%~dpnx2\!outfile!\.." 2>NUL
				
				if exist "%~dpnx2\!outfile!" (
					echo 	-- Appending to file !outfile! !dml!
					echo.>> "%~dpnx2\!outfile!"
					echo.>> "%~dpnx2\!outfile!"
				) else (
					echo 	-- Writing new file !outfile! !dml!
				)
				
				type "%%i\!file!" >> "%~dpnx2\!outfile!"
			) else (
				echo 	-- Skipping file !outfile!
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
	) else (
		echo Making version !folder_name!...
		mkdir "%~nx2\%%~nxi"
		
		if "!folder_name:~0,1!" == "$" (
			echo 	-- Version is standalone, not adding $common or $core folders...
		) else (
		
			if exist "%~dpnx1\$common" (
				call :make_feature_folder "%~nx1\$common" "%~nx2\%%~nxi" %3 %4 %5 %6 %7 %8 %9
			)
			
			if exist "%~dpnx1\$core" (
				call :make_feature_folder "%~nx1\$core" "%~nx2\%%~nxi" %3 %4 %5 %6 %7 %8 %9
			)
		)
		
		call :make_feature_folder "%~nx1\%%~nxi" "%~nx2\%%~nxi" %3 %4 %5 %6 %7 %8 %9
	)
	
)
endlocal

cd %back%
EXIT /B 0