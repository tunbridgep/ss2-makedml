::DO NOT USE ! OR % IN YOUR FOLDER NAMES!!!!
::IT WILL BREAK THE SCRIPT!

::Files starting with # will not be copied to your output dir
::Use this to write development notes or have files that you don't want included in a release

@echo off

::Set third parameter to 1 to enable DML1 header generation
::This is useful if you're not using a $common folder, so DML files can be written in any order.
if "%1" == "-f" (
	call :make_features %2 %3 %4
) else if "%1" == "-v" (
	call :make_versions %2 %3
) else (
	echo MakeDML version 0.1
	echo:
	echo usage:
	echo for feature mode
	echo 	makedml.cmd -f $source_dir $destination_dir $make_DML_headers
	echo or for version mode
	echo 	makedml.cmd -v $source_dir $destination_dir
	echo:
	echo In feature mode, the structure of each subfolder of $source_dir will be copied into $destination_dir in sequence.
	echo Files that exist in multiple folders will be concatenated together with a new line.
	echo Setting the $make_DML_headers variable to 1 will add "DML1" to the first line of every .dml file found.
	echo This is because the DML header must appear at the top of all DML files, but feature folders can be in any order.
	echo If you wish to specify your own DML headers, they should be in
	echo a folder that appears at the TOP of your src folder, it's recommended to use $core or something similar.
	echo In that instance, the $make_DML_headers variable should be 0 or not specified.
	echo:
	echo In version mode, for each subfolder of $source_dir, the contents of $common will be copied into a new subfolder in $destination_dir.
	echo Then, the contents of the subfolder in $source_dir will be added to the equivalent subfolder in $destination_dir.
	echo Files that exist in both folders will be concatenated together with a new line.
)

EXIT /B

::FUNCTIONS
:make_out_dir
::recreate output directory
::echo %~dpnx1
rmdir /s /q "%~dpnx1" 2>NUL
mkdir "%~dpnx1"
echo Outputting to %~dpnx1
EXIT /B 0

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

::remake output dir
call :make_out_dir %2

::for each feature folder, copy each file to the dest folder, appending if required
setlocal enableDelayedExpansion
for /D %%i in ("%~dpnx1\*") do (
	set "folder_name=%%~nxi"
	if "!folder_name:~0,1!" == "#" (
		echo Skipping ignored feature !folder_name!
	) else (
		echo Including feature !folder_name!
		::This is some hacked together magic
		for /f "delims=" %%A in ('forfiles /P "%%i" /s /m *.* /c "cmd /c echo @relpath"') do (
			set "file=%%~A"
			set "ext=%%~xA"
			set "file=!file:~2!"
			
			set first_character=!file:~0,1!
			if NOT "!first_character!" == "#" (
					
				if "%3" == "1" (
					if !ext! == .dml (
						if not exist "%~dpnx2\!file!" (
							::echo new DML file - writing DML1 header
							echo DML1> "%~dpnx2\!file!"
							echo 	-- Writing DML Header to new file !file!
						)
					)
				)
				md "%~dpnx2\!file!\.." 2>NUL
				
				if exist "%~dpnx2\!file!" (
					echo: >> "%~dpnx2\!file!"
					echo: >> "%~dpnx2\!file!"
					echo 	-- Appending to file !file! !dml!
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

::remake output dir
call :make_out_dir %2

::for each version folder, copy over the $common folder first, and then copy across that versions files
setlocal enableDelayedExpansion
for /D %%i in ("%~dpnx1\*") do (
	
	set "folder_name=%%~nxi"
	if "!folder_name:~0,1!" == "#" (
		echo Skipping version !folder_name!
	) else (		
		if NOT %%~ni == $common (
		
			echo Creating Version %%~ni
		
			::create version dir
			md "%~dpnx2\%%~ni" 2>NUL
			
			::copy over $common stuff
			if exist "%~dpnx1\$common" (
				echo 	-- Copying files from $common into new version folder
				::xcopy /V /E /I "%~dpnx1\$common" "%~dpnx2\%%~ni" >NUL
				robocopy "%~dpnx1\$common" "%~dpnx2\%%~ni" /E /XF "#*" /XF "#*" /XD "#*" >NUL
			)
			
			::This is some hacked together magic
			for /f "delims=" %%A in ('forfiles /P "%%i" /s /m *.* /c "cmd /c echo @relpath"') do (
				set "file=%%~A"
				set "ext=%%~xA"
				set "file=!file:~2!"
				
				set first_character=!file:~0,1!
				if NOT "!first_character!" == "#" (
										
					md "%~dpnx2\%%~ni\!file!\.." 2>NUL
					
					if exist "%~dpnx2\%%~ni\!file!" (
						echo: >> "%~dpnx2\%%~ni\!file!"
						echo: >> "%~dpnx2\%%~ni\!file!"
						echo 	-- Appending to file !file! !dml!
					) else (
						echo 	-- Writing new file !file! !dml!
					)
					
					type "%%i\!file!" >> "%~dpnx2\%%~ni\!file!"
				
				) else (
					echo 	-- Skipping file !file!
				)
			)
		)
	)
)
endlocal

cd %back%
EXIT /B 0