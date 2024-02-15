---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  MacYTDL
--  A GUI for the Python Scripts youtube-dl and yt-dlp.  Many thanks to Shane Stanley
--  This is the Adviser - advises user when download complete - give options if download failed
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Include libraries
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

-- This script provides an Adviser for each video file download requested by user in Main Dialog - it is called by monitor.scpt

on run {monitor_pid, youtubedl_pid, MacYTDL_custom_icon_file_not_posix_monitor, MacYTDL_preferences_path_monitor, YTDL_log_file_monitor, downloadsFolder_Path_monitor, diag_Title_quoted_monitor, DL_description_monitor, is_Livestream_Flag_monitor, download_filename_monitor, download_filename_new_monitor, download_filename_new_monitor_plain, YTDL_simulate_log_monitor}
	
	--	try
	
	--*********************************************
	-- dialog for checking values passed from Monitor script
	-- display dialog "monitor_pid: " & monitor_pid & return & return & "MacYTDL_custom_icon_file_not_posix_monitor: " & MacYTDL_custom_icon_file_not_posix_monitor & return & return & "MacYTDL_preferences_path_monitor: " & MacYTDL_preferences_path_monitor & return & return & "YTDL_log_file_monitor: " & YTDL_log_file_monitor & return & return & "downloadsFolder_Path_monitor: " & downloadsFolder_Path_monitor & return & return & "diag_Title_quoted_monitor: " & diag_Title_quoted_monitor & return & return & "DL_description_monitor: " & DL_description_monitor & return & return & "is_Livestream_Flag_monitor: " & is_Livestream_Flag_monitor & return & return & "download_filename_monitor: \"" & download_filename_monitor & "\"" & return & return & "download_filename_new_monitor: " & download_filename_new_monitor & return & return & "download_filename_new_monitor_plain: " & download_filename_new_monitor_plain & return & return & "YTDL_simulate_log_monitor: \"" & YTDL_simulate_log_monitor & "\"" with title "Adviser"
	--*********************************************	
	
	-- display dialog "Sorting out filename variables" & return & "download_filename_monitor: " & download_filename_monitor & return & "download_filename_new_monitor: " & download_filename_new_monitor & return & "download_filename_new_monitor_plain: " & return & download_filename_new_monitor_plain
	
	-- Set variable to contain path to MacYTDL bundle - to enable localized text and Alerter tool to be found
	set pathToBundle to (path to me) as text
	set pathToBundleShort to text 1 thru -40 of pathToBundle
	set alerterPath to quoted form of (POSIX path of (pathToBundleShort & "Contents:Resources:"))
	
	-- Set up to enable Adviser to open the log file
	set YTDL_log_file_monitor to POSIX file YTDL_log_file_monitor
	
	-- Some downloads come thru with multiple file names - isolate the first so it can be played when download finished
	set num_paragraphs_file_name to count of paragraphs in download_filename_monitor
	if num_paragraphs_file_name is greater than 1 then
		repeat with find_paragraph in paragraphs of download_filename_monitor
			if find_paragraph does not contain "ERROR:" and find_paragraph does not contain "WARNING:" then
				set download_filename_play to find_paragraph
				exit repeat
			end if
		end repeat
	else
		set download_filename_play to download_filename_new_monitor_plain
	end if
	
	-- For a batch need to get download file name from different variable - need to remove quotes - THIS SECTION LOOKS AT WRONG VARIABLE !?
	if download_filename_new_monitor is "the saved batch" then
		set download_filename_play to download_filename_monitor
	end if
	
	-- Check Monitor process every 2 seconds until it disappears from process list - surrogate for completed download + prevents alert showing at same time as Monitor
	-- But, DL can continue after Monitor process ceases so, check on youtubedl_pid also, before posting Adviser
	try
		repeat
			-- does the monitor_pid exist?
			do shell script "ps -p" & monitor_pid
			delay 2
		end repeat
	on error
		try
			repeat
				-- does the PID exist?
				do shell script "ps -p" & youtubedl_pid
				delay 2
			end repeat
		on error
			
			-- monitor_pid has disappeared - test for download error, advise user accordingly, show Adviser alert, open logs or downloads, or do nothing as desired		
			-- Change extension of description file(s) to txt if description is requested by user and file exists - using shell has risks but is quick
			if DL_description_monitor is "Yes" then
				try
					do shell script "for file in " & quoted form of downloadsFolder_Path_monitor & "/*.description; do mv \"$file\" \"${file/.description/.txt}\" > /dev/null 2> /dev/null ; done"
				end try
			end if
			
			set theAdviserButtonsCloseLabel1 to localized string "Close" in bundle file pathToBundleShort from table "MacYTDL"
			set subtitleText to quoted form of ("“" & download_filename_new_monitor_plain & "”")
			-- Get log file content into a variable so it can be checked for the 100% - which if not present suggests there was a download error
			-- 4/3/23 - Add delay as it seems, sometimes, the log file is not free or is locked
			delay 1
			set error39 to false
			try
				set YTDL_log to read file YTDL_log_file_monitor as «class utf8»
			on error errmsg
				if errmsg contains "End of file" then
					set error39 to true
				else
					display dialog "Error in Adviser reading log file: " & YTDL_log_file_monitor & return & "The error reported was " & errmsg
				end if
			end try
			if (YTDL_log contains "100%" or is_Livestream_Flag_monitor is "True") and YTDL_log does not contain "ERROR:" then
				-- Download completed without errors - if YTDL merged into mkv, update extension in download_filename_play - but not if user has chosen to recode
				if (YTDL_log contains "Requested formats are incompatible for merge and will be merged into mkv" or YTDL_log contains "doesn't support embedding a thumbnail, mkv will be used") and YTDL_log does not contain "Converting video from mkv to " then
					set start_extension to offset of "." in download_filename_play
					set download_filename_play to (text 1 thru start_extension of download_filename_play) & "mkv"
				end if
				if YTDL_log contains "There are no subtitles for the requested languages" then
					set theAdviserTextLabel1 to quoted form of (localized string "Finished - but no subtitles:" in bundle file pathToBundleShort from table "MacYTDL")
				else
					set theAdviserTextLabel1 to quoted form of (localized string "MacYTDL download finished:" in bundle file pathToBundleShort from table "MacYTDL")
				end if
				set theAdviserTextLabel2 to quoted form of (localized string "Click to open downloads folder" in bundle file pathToBundleShort from table "MacYTDL")
				set theAdviserButtonsCloseLabel2 to localized string "Play" in bundle file pathToBundleShort from table "MacYTDL"
				set adviser_button to do shell script alerterPath & "/alerter -message " & theAdviserTextLabel2 & " -title " & theAdviserTextLabel1 & " -subtitle " & subtitleText & " -closeLabel " & theAdviserButtonsCloseLabel1 & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & theAdviserButtonsCloseLabel2
				
				-- User chose to play the finished download - or the first item of a batch, playlist or multiple download
				if adviser_button is theAdviserButtonsCloseLabel2 then
					-- If download is a recorded live stream, get file name from log file as it can be different to name found in simulation - beware of date-time stamps
					-- Look for cases in which downloads are merged
					set number_of_log_paras to count of paragraphs in YTDL_log
					repeat with x from number_of_log_paras to 1 by -1
						set find_paragraph to paragraph x of YTDL_log
						if is_Livestream_Flag_monitor is "True" then
							if find_paragraph contains "[download] Destination:" then
								set offset_download to offset of "[download] Destination:" in find_paragraph
								set download_filename_play to text (offset_download + 24) thru end of find_paragraph
								exit repeat
							end if
						else if find_paragraph contains "; Destination: " then
							set offset_download to offset of "; Destination: " in find_paragraph
							set download_filename_play to text (offset_download + 15) thru end of find_paragraph
							exit repeat
						else if find_paragraph contains "[Merger] Merging formats into" then
							set offset_download to offset of "[Merger] Merging formats into" in find_paragraph
							set length_of_found_paragraph to (count of characters in find_paragraph) - 1 -- Trim off the last double quote
							set download_filename_play to text (offset_download + 31) thru length_of_found_paragraph of find_paragraph
							exit repeat
						end if
						if find_paragraph contains " [download] 100% of " then
							exit repeat
						end if
					end repeat
					
					-- Did user specify download location in custom template - if so, downloadsFolder_Path_monitor can be omitted
					if download_filename_play contains "Users" then
						set pathToVideoFile to POSIX file (download_filename_play)
					else
						set pathToVideoFile to POSIX file (downloadsFolder_Path_monitor & "/" & download_filename_play)
					end if
					tell application "Finder"
						-- tell application "System Events" to open file pathToVideoFile  -- Decided to switch to Finder
						open pathToVideoFile as alias
					end tell
					-- end if
				else if adviser_button is "@CONTENTCLICKED" then
					tell application "Finder"
						activate
						open (downloadsFolder_Path_monitor as POSIX file)
						set the position of the front Finder window to {100, 100}
					end tell
				end if
				-- If batch download completed without error, delete URLs from batch file
				if download_filename_new_monitor is "the saved batch" then
					set batch_filename to "BatchFile.txt" as string
					set batch_file to POSIX file (MacYTDL_preferences_path_monitor & batch_filename)
					try
						set batch_file_ref to missing value
						set batch_file_ref to open for access file batch_file with write permission
						set eof batch_file_ref to 0
						close access batch_file_ref
					on error batch_errMsg
						display dialog "There was an error: " & batch_errMsg & "batch_file: " & batch_file buttons {"OK"} default button {"OK"}
						try
							close access batch_file_ref
						end try
					end try
				end if
			else if YTDL_log contains "ERROR:" or error39 is true then
				-- Download had errors	
				set theAdviserTextLabel1 to quoted form of (localized string "MacYTDL download error with:" in bundle file pathToBundleShort from table "MacYTDL")
				set theAdviserTextLabel2 to quoted form of (localized string "Click to open downloads or Options" in bundle file pathToBundleShort from table "MacYTDL")
				set theAdviserButtonsCloseLabel2 to localized string "Options" in bundle file pathToBundleShort from table "MacYTDL"
				set theAdviserButtonsCloseLabel3 to quoted form of (localized string "Open Log" in bundle file pathToBundleShort from table "MacYTDL")
				set theAdviserButtonsCloseLabel4 to quoted form of (localized string "Show Logs" in bundle file pathToBundleShort from table "MacYTDL")
				set adviser_button to do shell script alerterPath & "/alerter -message " & theAdviserTextLabel2 & " -title " & theAdviserTextLabel1 & " -subtitle " & subtitleText & " -closeLabel " & theAdviserButtonsCloseLabel1 & " -timeout 20 -sender com.apple.script.id.MacYTDL -actions " & theAdviserButtonsCloseLabel3 & "," & theAdviserButtonsCloseLabel4 & " -dropdownLabel " & theAdviserButtonsCloseLabel2
				if adviser_button is text 2 thru -2 of theAdviserButtonsCloseLabel3 then
					-- Substituted ASOC code in a separate handler until Apple fix the bug !
					set theFile to POSIX path of YTDL_log_file_monitor
					openFile(theFile)
				else if adviser_button is text 2 thru -2 of theAdviserButtonsCloseLabel4 then
					tell application "Finder"
						activate
						open (MacYTDL_preferences_path_monitor as POSIX file)
						set the position of the front Finder window to {100, 100}
					end tell
				else if adviser_button is "@CONTENTCLICKED" then
					tell application "Finder"
						activate
						open (downloadsFolder_Path_monitor as POSIX file)
						set the position of the front Finder window to {100, 100}
					end tell
				end if
			else if YTDL_log does not contain "ERROR:" and YTDL_log does not contain "100%" and YTDL_log does not contain "has already been downloaded" and is_Livestream_Flag_monitor is "False" then
				-- Download not completed but no errors reported
				set theAdviserTextLabel1 to quoted form of (localized string "MacYTDL download incomplete:" in bundle file pathToBundleShort from table "MacYTDL")
				set theAdviserTextLabel2 to quoted form of (localized string "Click “Options” to troubleshoot." in bundle file pathToBundleShort from table "MacYTDL")
				set theAdviserButtonsCloseLabel2 to localized string "Options" in bundle file pathToBundleShort from table "MacYTDL"
				set theAdviserButtonsCloseLabel3 to quoted form of (localized string "Open Log" in bundle file pathToBundleShort from table "MacYTDL")
				set theAdviserButtonsCloseLabel4 to quoted form of (localized string "Show Logs" in bundle file pathToBundleShort from table "MacYTDL")
				set adviser_button to do shell script alerterPath & "/alerter -message " & theAdviserTextLabel2 & " -title " & theAdviserTextLabel1 & " -subtitle " & subtitleText & " -closeLabel " & theAdviserButtonsCloseLabel1 & " -timeout 20 -sender com.apple.script.id.MacYTDL -actions " & theAdviserButtonsCloseLabel3 & "," & theAdviserButtonsCloseLabel4 & " -dropdownLabel " & theAdviserButtonsCloseLabel2
				if adviser_button is text 2 thru -2 of theAdviserButtonsCloseLabel3 then
					-- Substituted ASOC code in a separate handler until Apple fix the bug !
					set theFile to POSIX path of YTDL_log_file_monitor
					openFile(theFile)
				else if adviser_button is text 2 thru -2 of theAdviserButtonsCloseLabel4 then
					tell application "Finder"
						activate
						open (MacYTDL_preferences_path_monitor as POSIX file)
						set the position of the front Finder window to {100, 100}
					end tell
				else if adviser_button is "@CONTENTCLICKED" then
					tell application "Finder"
						activate
						open (downloadsFolder_Path_monitor as POSIX file)
						set the position of the front Finder window to {100, 100}
					end tell
				end if
			end if
		end try
	end try
	
	
	
	--	on error errmsg
	--		display dialog errmsg
	--	end try
	
	
end run

on openFile(theFile) -- theFile is POSIX path
	script theScript
		use framework "AppKit"
		use framework "Foundation"
		on openTheFile(theFile)
			set theWorkSpace to current application's NSWorkspace's sharedWorkspace()
			set theFile to current application's |NSURL|'s fileURLWithPath:theFile
			theWorkSpace's openURL:theFile
		end openTheFile
	end script
	theScript's openTheFile(theFile)
end openFile
