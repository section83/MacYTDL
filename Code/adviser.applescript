---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  MacYTDL
--  A GUI for the Python Script youtube-dl (http://rg3.github.io/youtube-dl/).  Many thanks to Shane Stanley, Adam Albrec, kopurando and Michael Page
--  This is the Monitor Adviser - advises user when download complete
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Include libraries
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

-- This script provides an Adviser for each video file download requested by user in Main Dialog - it is called by monitor.sctp

on run {monitor_pid, youtubedl_pid, MacYTDL_custom_icon_file_not_posix_monitor_quoted, MacYTDL_preferences_path_monitor, YTDL_response_file_monitor, downloadsFolder_Path_monitor, diag_Title_quoted_monitor, DL_description_monitor, download_filename_new_monitor, download_filename_new_monitor_plain}
	
	--*********************************************
	-- dialog for checking values passed from Monitor script
	-- display dialog "monitor_pid: " & monitor_pid & return & "youtubedl_pid: " & youtubedl_pid & return & "MacYTDL_custom_icon_file_not_posix_monitor_quoted: " & MacYTDL_custom_icon_file_not_posix_monitor_quoted & return & "MacYTDL_preferences_path_monitor: " & MacYTDL_preferences_path_monitor & return & "YTDL_response_file_monitor: " & YTDL_response_file_monitor & return & "downloadsFolder_Path_monitor: " & downloadsFolder_Path_monitor & return & "diag_Title_quoted_monitor: " & diag_Title_quoted_monitor & return & "DL_description_monitor: " & DL_description_monitor & return & "download_filename_new_monitor: " & download_filename_new_monitor & return & "download_filename_new_monitor_plain: " & download_filename_new_monitor_plain with title "Adviser"
	--*********************************************	
	
	-- Set up to enable Adviser to open the log file
	set YTDL_response_file_monitor to POSIX file YTDL_response_file_monitor
	
	-- Check download process every 2 seconds until it disappears from process list
	try
		repeat
			-- does the PID exist?
			do shell script "ps -p" & youtubedl_pid
			delay 2
		end repeat
	on error
		-- youtubedl_pid has disappeared - kill off the Monitor process, test for download error, advise user accordingly, open logs or downloads or open log file, or do nothing as desired
		try
			do shell script "kill " & monitor_pid
		end try
		
		-- Change extension of description file(s) to txt if description is requested by user and file exists - using shell has risks but is quick
		if DL_description_monitor is "Yes" then
			try
				do shell script "for file in " & quoted form of downloadsFolder_Path_monitor & "/*.description; do mv \"$file\" \"${file/.description/.txt}\" > /dev/null 2> /dev/null ; done"
			end try
		end if
		
		-- Get response file content into a variable so it can be checked for the 100% - which if not present suggests there was a download error
		try
			set YTDL_response to read file YTDL_response_file_monitor as text
		on error errMsg
			display dialog "Error in reading response file: " & errMsg
		end try
		if YTDL_response contains "100%" and YTDL_response does not contain "ERROR:" then
			-- Download completed without errors	
			set adviser_button to button returned of (display dialog "Your download of \"" & download_filename_new_monitor_plain & "\" has finished." buttons {"Logs", "Downloads", "OK"} default button "OK" with title diag_Title_quoted_monitor with icon file MacYTDL_custom_icon_file_not_posix_monitor_quoted giving up after 7)
			if adviser_button is "Logs" then
				tell application "Finder"
					activate
					open (MacYTDL_preferences_path_monitor as POSIX file)
					set the position of the front Finder window to {100, 100} -- <= This DOES work but is ugly - it opens the window then moves it
				end tell
			else if adviser_button is "Downloads" then
				tell application "Finder"
					activate
					open (downloadsFolder_Path_monitor as POSIX file)
					set the position of the front Finder window to {100, 100} -- <= This DOES work but is ugly - it opens the window then moves it
				end tell
			end if
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
		else if YTDL_response contains "ERROR:" then
			-- Download had errors	
			set adviser_button to button returned of (display dialog "Your download of \"" & download_filename_new_monitor_plain & "\" encountered an error.  You can open the log file to find out what happened." buttons {"Open log file", "Cancel"} default button "Open log file" cancel button "Cancel" with title diag_Title_quoted_monitor with icon file MacYTDL_custom_icon_file_not_posix_monitor_quoted giving up after 15)
			if adviser_button is "Open log file" then
				tell application "TextEdit"
					activate
					open YTDL_response_file_monitor as alias
				end tell
			end if
		else if YTDL_response does not contain "ERROR:" and YTDL_response does not contain "100%" then
			-- Download not completed but no errors reported
			set adviser_button to button returned of (display dialog "Your download of \"" & download_filename_new_monitor_plain & "\" might not have completed.  You can open the log file to find out what happened." buttons {"Open log file", "Cancel"} default button "Open log file" cancel button "Cancel" with title diag_Title_quoted_monitor with icon file MacYTDL_custom_icon_file_not_posix_monitor_quoted giving up after 15)
			if adviser_button is "Open log file" then
				tell application "TextEdit"
					activate
					open YTDL_response_file_monitor as alias
				end tell
			end if
		end if
	end try
end run