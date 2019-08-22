---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  MacYTDL
--  A GUI for the Python Script youtube-dl (http://rg3.github.io/youtube-dl/).  Many thanks to Shane Stanley, Adam Albrec, kopurando and Michael Page
--  This is the Monitor Adviser - advises user when download complete
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Include libraries - needed for Shane Staney's Dialog Toolkit
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions

-- This script provides an Adviser for each video file download requested by user in Main Dialog - it is called by monitor.sctp

on run {monitor_pid, youtubedl_pid, MacYTDL_custom_icon_file_not_posix_monitor, MacYTDL_preferences_path_monitor, YTDL_response_file_monitor, downloadsFolder_Path_monitor, diag_Title_quoted_monitor, DL_description_monitor, download_filename_new_monitor, download_filename_new_monitor_plain}
	
	-- display dialog "download_filename_new_monitor: " & download_filename_new_monitor & return & "download_filename_new_monitor_plain: " & download_filename_new_monitor_plain with title "Adviser"
	
	
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
		
		-- Change extension of description file to txt if description is requested by user and file exists
		if DL_description_monitor is "Yes" then
			set Ad_description_file to (downloadsFolder_Path_monitor & "/" & download_filename_new_monitor & ".description")
			tell application "System Events"
				if exists file Ad_description_file then
					set name of file Ad_description_file to download_filename_new_monitor & ".txt"
				end if
			end tell
		end if
		
		-- Get response file content into a variable so it can be checked for the 100% - which if not present suggests there was a download error
		set YTDL_response to read file YTDL_response_file_monitor as text
		if YTDL_response contains "100%" then
			-- Download completed probably without errors	
			set adviser_button to button returned of (display dialog "Your download of \"" & download_filename_new_monitor_plain & "\" has finished." buttons {"Logs", "Downloads", "OK"} default button "OK" with title diag_Title_quoted_monitor with icon file MacYTDL_custom_icon_file_not_posix_monitor giving up after 7)
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
		else
			-- Download completed probably has errors	
			set adviser_button to button returned of (display dialog "Your download of \"" & download_filename_new_monitor_plain & "\" might not have succeeded.  You can open the log file to find out what happened." buttons {"Open log file", "Cancel"} default button "Open log file" cancel button "Cancel" with title diag_Title_quoted_monitor with icon file MacYTDL_custom_icon_file_not_posix_monitor giving up after 15)
			if adviser_button is "Open log file" then
				tell application "TextEdit"
					activate
					open YTDL_response_file_monitor as alias
				end tell
			end if
		end if
	end try
end run
