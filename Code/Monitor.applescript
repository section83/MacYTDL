---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  MacYTDL
--  A GUI for the Python Script youtube-dl (http://rg3.github.io/youtube-dl/).  Many thanks to Shane Stanley, Adam Albrec, kopurando and Michael Page
--  This is the Download Monitor
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Include libraries - needed for Shane Staney's Dialog Toolkit
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use script "DialogToolkitMacYTDL" version "1.0" -- Yosemite (10.10) or later

-- This script provides a download Monitor for each video file download requested by user of Main Dialog

-- Run the Monitor when the script is called
on run {downloadsFolder_Path_monitor, MacYTDL_preferences_path_monitor, ytdl_options_monitor, URL_user_entered_monitor, YTDL_response_file_monitor, download_filename_new_monitor, MacYTDL_custom_icon_file_posix_monitor, monitor_dialog_position, YTDL_simulate_response_monitor, diag_Title_quoted_monitor}
	
	--*****************
	-- Dialog for testing that parameters were passed correctly by the calling script
	-- display dialog "downloadsFolder_Path_monitor: " & downloadsFolder_Path_monitor & return & return & "ytdl_options_monitor: " & ytdl_options_monitor & return & return & "URL_user_entered_monitor: " & URL_user_entered_monitor & return & return & "YTDL_response_file_monitor: " & YTDL_response_file_monitor & return & return & "download_filename_new_monitor: " & download_filename_new_monitor & return & return & "MacYTDL_custom_icon_file_posix_monitor: " & MacYTDL_custom_icon_file_posix_monitor & return & return & "monitor_dialog_position: " & monitor_dialog_position & return & return & "YTDL_simulate_response_monitor: " & YTDL_simulate_response_monitor
	--*****************
	
	-- Get bounds of the user's screen so that correct position of Monitor dialog can be calculated - dialogs are shown in columns and rows on the screen so they don't overlap
	tell application "Finder"
		set screen_bounds to bounds of window of desktop
		set screen_width to item 3 of screen_bounds as string
		set screen_height to item 4 of screen_bounds as string
	end tell
	
	-- Calculate the number of monitor dialogs per column which is also the maximum number of rows
	set number_of_monitors_per_column to round (screen_height / 150)
	
	-- Calculate the column number
	set column_number to (round (monitor_dialog_position / number_of_monitors_per_column) rounding up)
	
	-- Set the X_position
	set X_position_monitor to (column_number * 400)
	
	-- Work out which row is to be used - starts at row 0 which is the top of the screen
	set row_number to (monitor_dialog_position - (number_of_monitors_per_column * (column_number - 1))) - 1
	
	-- Calculate the Y_position
	set Y_position_monitor to (row_number * 150)
	
	
	--*****************
	-- Dialog for testing where monitor dialogs will be displayed
	-- display dialog "screen_width: " & screen_width & return & "screen_height: " & screen_height & return & "monitor_dialog_position: " & monitor_dialog_position & return & "number_of_monitors_per_column: " & number_of_monitors_per_column & return & "column_number: " & column_number & return & "X_position_monitor: " & X_position_monitor & return & "row_number: " & row_number & return & "Y_position_monitor: " & Y_position_monitor
	--*****************
	
	set download_finished to "No"
	
	-- Set paths for shell command - probably don't need all of these - need to test reomving some
	set shellPath to "PATH=$PATH:/bin:/sbin:/usr/bin:/usr/local/bin:/usr/sbin:~/opt/bin:~/opt/sbin:/opt/local/bin:/opt/local/sbin:" & quoted form of (POSIX path of ((path to me as text) & "::")) & "; "
	
	-- Need quoted form so that paths and strings with spaces are handled correctly by the shell
	set downloadsFolder_Path_monitor to quoted form of downloadsFolder_Path_monitor
	set YTDL_response_file_monitor_quoted to quoted form of YTDL_response_file_monitor
	set diag_Title_monitor to quoted form of diag_Title_quoted_monitor
	set diag_Title_quoted_monitor to quoted form of diag_Title_quoted_monitor
	set MacYTDL_custom_icon_file_not_posix_monitor to POSIX file MacYTDL_custom_icon_file_posix_monitor as text
	set MacYTDL_custom_icon_file_not_posix_monitor_quoted to quoted form of MacYTDL_custom_icon_file_not_posix_monitor -- Passed to Adviser for display dialog
	
	-- Remove extension from file name for presentation purposes in dialogs
	
	-- Revert download show name to spaces so it looks nice in dialog
	if download_filename_new_monitor contains "_" then
		set download_filename_new_monitor_plain to my replace_chars(download_filename_new_monitor, "_", " ")
	else
		set download_filename_new_monitor_plain to download_filename_new_monitor
	end if
	
	-- Put single quotes around each URL - mainly because the ampersand in some Youtube URLs ends up being treated as a delimiter - crude but effective
	-- 19 October 2019 - Restricted adding quotes to case where URL contains ampersands - all others go through without
	if URL_user_entered_monitor contains "&" then
		set AppleScript's text item delimiters to " "
		set number_of_URLs to number of text items in URL_user_entered_monitor
		if number_of_URLs is greater than 1 then
			set URL_user_entered_monitor_quoted to ""
			repeat with current_URL in text items of URL_user_entered_monitor
				-- set current_URL to quoted form of current_URL
				set current_URL to "'" & current_URL & "'"
				set URL_user_entered_monitor_quoted to URL_user_entered_monitor_quoted & current_URL & " "
			end repeat
		else
			set URL_user_entered_monitor_quoted to quoted form of URL_user_entered_monitor
		end if
		set AppleScript's text item delimiters to ""
	else
		set URL_user_entered_monitor_quoted to URL_user_entered_monitor
	end if
	
	-- Remove quotes from around YTDL_options as they cause problems with running youtube-dl command from shell
	set ytdl_options_monitor to items 2 thru -1 of ytdl_options_monitor as string
	
	-- Blank out URL_user_entered_monitor_quoted - is set to Null when downloading a batch
	if URL_user_entered_monitor_quoted is "Null" then
		set URL_user_entered_monitor_quoted to ""
	end if
	
	-- Issue youtube-dl command to download the requested video file - returns PID of Python process + errors; anything else flagged by youtube-dl goes into response file	
	set youtubedl_pid to do shell script shellPath & "cd " & downloadsFolder_Path_monitor & " ; " & "youtube-dl " & ytdl_options_monitor & " " & URL_user_entered_monitor_quoted & " " & "&> " & YTDL_response_file_monitor_quoted & " & echo $!"
	
	-- Set up for starting the Download Adviser - get path to adviser script, set parameters to be passed, start the Adviser
	-- Prepare to call on the Monitor Adviser - first get pid of this Monitor instance and Adviser script location
	try
		set monitor_pid to do shell script "pgrep -n osascript &"
	on error errtext
		display dialog "There was an error with the pgrep:" & errtext
	end try
	
	-- Test whether user wants a description file - transmit to Adviser so it can fix the file name after download
	set DL_description_monitor to "No"
	if ytdl_options_monitor contains "description" then
		set DL_description_monitor to "Yes"
	end if
	set path_to_monitor to (path to me) as string
	set path_to_scripts to text 1 thru -13 of path_to_monitor
	set myAdviserScriptAsString to quoted form of POSIX path of (path_to_scripts & "adviser.scpt")
	set download_filename_new_monitor to quoted form of download_filename_new_monitor
	set download_filename_new_monitor_plain_quoted to quoted form of download_filename_new_monitor_plain
	set adviser_params to monitor_pid & " " & youtubedl_pid & " " & MacYTDL_custom_icon_file_not_posix_monitor_quoted & " " & MacYTDL_preferences_path_monitor & " " & YTDL_response_file_monitor_quoted & " " & downloadsFolder_Path_monitor & " " & diag_Title_quoted_monitor & " " & DL_description_monitor & " " & download_filename_new_monitor & " " & download_filename_new_monitor_plain_quoted
	
	-- Production call to Adviser
	set adviser_pid to do shell script "osascript -s s " & myAdviserScriptAsString & " " & adviser_params & " " & " > /dev/null 2> /dev/null & echo $!"
	
	-- Test call to Adviser - often not useful
	-- set adviser_pid to do shell script "osascript -s s " & myAdviserScriptAsString & " " & adviser_params & " " & " echo $!"
	
	-- Prepare and display the download monitor dialog - a simple version at present until it can be re-done in ASOC <= Maybe never
	-- Set variables
	set monitor_diag_Title to "MacYTDL Video Downloader"
	set diag_intro_text to "Your download of \"" & download_filename_new_monitor_plain & "\" has started.  Download can be stopped while this dialog is open Ð it auto-closes after 5 minutes."
	set accViewWidth to 400
	set accViewInset to 0
	
	-- Set buttons, label and icon
	--	set {theButtons, minWidth} to create buttons {"Logs", "Downloads", "Stop", "Close"} button keys {"l", "d", "S", ""} given Çclass btnsÈ:4
	set {theButtons, minWidth} to create buttons {"Logs", "Downloads", "Stop", "Close"} button keys {"l", "d", "S", ""}
	if minWidth > accViewWidth then set accViewWidth to minWidth -- make sure buttons fit
	set {intro_label, theTop} to create label diag_intro_text left inset 75 bottom 5 max width accViewWidth - 80 control size small size
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix_monitor left inset 0 bottom theTop - 50 view width 60 view height 60 scale image scale proportionally
	
	-- Display the monitor dialog
	tell me to activate
	set {monitor_button_returned} to display enhanced window monitor_diag_Title buttons theButtons giving up after 300 acc view width accViewWidth acc view height theTop acc view controls {intro_label, MacYTDL_icon} initial position {X_position_monitor, Y_position_monitor}
	
	-- User clicked on the Stop download button - This kills the Python process and all child FFmpeg processes, then moves to Trash all ".part" files related to the download
	if monitor_button_returned is "Stop" then
		-- Try to kill the process but, error if process already gone. If so, just tell user and continue
		try
			-- Try to kill the ffmpeg child process then the python process
			set ffmpeg_child_pid to do shell script "pgrep -P " & youtubedl_pid
			if ffmpeg_child_pid is not {} then
				do shell script "kill " & ffmpeg_child_pid
				do shell script "kill " & youtubedl_pid
				do shell script "kill " & adviser_pid
			end if
		on error the_Error
			if the_Error is "The command exited with a non-zero status." then
				try
					-- Failed to kill the child ffmpeg process or the python process but try again as the other process might still be running - if error tell user
					do shell script "kill " & youtubedl_pid
					do shell script "kill " & adviser_pid
				on error
					set MacYTDL_custom_icon_file_not_posix_monitor to POSIX file MacYTDL_custom_icon_file_posix_monitor
					display dialog "Looks like the download has finished. Just close this dialog." buttons {"OK"} with title diag_Title_monitor with icon file MacYTDL_custom_icon_file_not_posix_monitor giving up after 60
					set download_finished to "Yes"
				end try
			end if
		end try
		if download_finished is not "Yes" then
			-- Partly completed download process will leave behind "part" and/or "ytdl" files which should be moved to Trash
			-- Completed downloads should be left alone
			-- Handle multiple downloads separately as the name for the file spec comes from simulate.txt instead of the download_filename_new_monitor variable
			-- Need to trim off file extension in name search because YTDL sometimes has part files with part numbers between the name and the extension - works for 3 and 4 character extensions
			if download_filename_new_monitor_plain is "the multiple videos" or download_filename_new_monitor_plain is "the-playlist" then
				repeat with each_filename in (get paragraphs of YTDL_simulate_response_monitor)
					set each_filename to text 1 thru -5 of each_filename
					if each_filename does not contain "WARNING" then
						set part_files to do shell script "find " & downloadsFolder_Path_monitor & " -maxdepth 1 -type f -iname *" & quoted form of each_filename & "*.part* -or -iname *" & quoted form of each_filename & "*.ytdl*"
						repeat with each_part_files in (get paragraphs of part_files)
							do shell script "mv " & quoted form of each_part_files & " ~/.trash/"
						end repeat
					end if
				end repeat
				-- Monitor currently cannot delete partly downloaded files left by batch download
			else if download_filename_new_monitor is not "the batch" then
				-- Look for all files in DL folder that meet file spec
				set download_filename_new_monitor_plain_trimmed to text 1 thru -5 of download_filename_new_monitor_plain
				set part_files to do shell script "find " & downloadsFolder_Path_monitor & " -maxdepth 1 -type f -iname *" & quoted form of download_filename_new_monitor_plain_trimmed & "*.part* -or -iname *" & quoted form of download_filename_new_monitor_plain_trimmed & "*.ytdl*"
				repeat with each_part_files in (get paragraphs of part_files)
					do shell script "mv " & quoted form of each_part_files & " ~/.trash/"
				end repeat
			end if
		end if
		
		-- User clicked on "Open log folder"
	else if monitor_button_returned is "Logs" then
		tell application "Finder"
			activate
			open (MacYTDL_preferences_path_monitor as POSIX file)
			set the position of the front Finder window to {100, 100} -- <= This DOES work but is ugly - it opens the window then moves it
		end tell
	else if monitor_button_returned is "Downloads" then
		set downloadsFolder_Path_monitor to text 2 thru -2 of downloadsFolder_Path_monitor
		tell application "Finder"
			activate
			open (downloadsFolder_Path_monitor as POSIX file)
			set the position of the front Finder window to {100, 100} -- <= This DOES work but is ugly - it opens the window then moves it
		end tell
	end if
end run
-- Handler to find-replace text inside a string
on replace_chars(this_text, search_string, replacement_string)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replace_chars
