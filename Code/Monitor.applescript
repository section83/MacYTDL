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
	set number_of_monitors_per_column to round (screen_height / 200)
	
	-- Calculate the column number
	set column_number to (round (monitor_dialog_position / number_of_monitors_per_column) rounding up)
	
	-- Set the X_position
	-- set X_position_monitor to (column_number * 300)
	set X_position_monitor to screen_width - (290 * column_number)
	
	-- Work out which row is to be used - starts at row 0 which is the top of the screen
	set row_number to (monitor_dialog_position - (number_of_monitors_per_column * (column_number - 1))) - 1
	
	-- Calculate the Y_position
	set Y_position_monitor to (row_number * 175)
	
	
	--*****************
	-- Dialog for testing where monitor dialogs will be displayed
	-- display dialog "screen_width: " & screen_width & return & "screen_height: " & screen_height & return & "monitor_dialog_position: " & monitor_dialog_position & return & "number_of_monitors_per_column: " & number_of_monitors_per_column & return & "column_number: " & column_number & return & "X_position_monitor: " & X_position_monitor & return & "row_number: " & row_number & return & "Y_position_monitor: " & Y_position_monitor
	--*****************
	
	set YTDL_response_file_monitor_posix to POSIX file YTDL_response_file_monitor
	
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
	
	-- Prepare and display the download monitor dialog - set starting variables for Monitor dialog
	set seconds_running to 0
	set time_running to 0
	set progress_percentage to ""
	set downloadFileSize to ""
	set monitor_diag_Title to "MacYTDL Video Downloader"
	set diag_intro_text_1 to "Your download of \"" & download_filename_new_monitor_plain & "\" has started.  Download can be stopped while this dialog is open."
	set accViewWidth to 100
	-- set accViewWidth to 400
	set accViewInset to 0
	set the_date_start to current date
	set the_time_start to time of the_date_start
	
	-- Set buttons
	set {theButtons, minWidth} to create buttons {"Logs", "Stop", "Close"} button keys {"l", "S", ""} cancel button "Close"
	if minWidth > accViewWidth then set accViewWidth to minWidth -- make sure buttons fit
	
	-- It can take time for response file to get content - delay Monitor a bit
	delay 5
	
	-- Repeat loop to display monitor, close after set time, update on progress, redisplay and stop download or open logs folder
	repeat
		-- Get YTDL response up to this point
		try
			set YTDL_response to read file YTDL_response_file_monitor_posix as text
		on error errMsg
			if errMsg contains "End of file" then
				set YTDL_response to "No response"
			else
				display dialog "Error in reading response file: " & errMsg
			end if
		end try
		
		-- Get time running since start, convert into minutes
		set the_time to time of (current date)
		set seconds_running to the_time - the_time_start
		set time_running to seconds_running / minutes
		set round_factor to 0.1
		set time_running to (round time_running / round_factor) * round_factor
		
		-- Use content of response to fashion text to appear in Monitor dialog
		if YTDL_response is not "No response" then
			set YTDL_response_lastParapraph to paragraph -2 of YTDL_response
			-- If progress meter available, get current percentage and file size - trim leading spaces from percentage - convert MiB to MB in file size to match Finder
			if YTDL_response_lastParapraph contains "[download]" and YTDL_response_lastParapraph contains "%" then
				set progress_percentage to text 12 thru 17 of YTDL_response_lastParapraph
				set firstWordInPercentage to first word in progress_percentage
				set firstWordInPercentageStart to offset of firstWordInPercentage in progress_percentage
				set progress_percentage to text firstWordInPercentageStart thru end of progress_percentage
				set MiBPositionAfterSize to offset of "MiB" in YTDL_response_lastParapraph
				set downloadFileSizeMiB to text 22 thru (MiBPositionAfterSize - 1) of YTDL_response_lastParapraph
				set approxIndicator to text 1 of downloadFileSizeMiB
				if approxIndicator is "~" then
					set downloadFileSizeMiB to text 2 thru end of downloadFileSizeMiB
					set downloadFileSizeMiB to downloadFileSizeMiB as number
					set downloadFileSizeMB to downloadFileSizeMiB * 1.04858 as number
					set round_factor to 0.01
					set downloadFileSizeMB to (round downloadFileSizeMB / round_factor) * round_factor
				else
					set approxIndicator to ""
					set downloadFileSizeMiB to downloadFileSizeMiB as number
					set downloadFileSizeMB to downloadFileSizeMiB * 1.04858 as number
					set round_factor to 0.01
					set downloadFileSizeMB to (round downloadFileSizeMB / round_factor) * round_factor
				end if
				set diag_intro_text_2 to "Progress: " & progress_percentage & " downloaded of " & approxIndicator & downloadFileSizeMB & "MB" & " in " & time_running & " minutes."
			else if YTDL_response contains "size= " then
				-- FFMpeg regularly reports amount downloaded - find latest report - convert kibibytes to kilobytes to match size reported by Finder
				set numParasInResponse to count of paragraphs in YTDL_response
				repeat with i from 1 to numParasInResponse
					set lastParaInResponse to paragraph (-i) of YTDL_response
					if lastParaInResponse contains "size=" then
						set offsetOfSize to offset of "size" in lastParaInResponse
						set sizeOfDownloadProgress to text (offsetOfSize + 5) thru (offsetOfSize + 12) of lastParaInResponse
						set sizeOfDownloadProgress to (sizeOfDownloadProgress * 1.024) as integer
						exit repeat
					else
						set i to i + 1
					end if
				end repeat
				set sizeOfdownloadProgressDelimited to convertNumberToCommaDelimitedString(sizeOfDownloadProgress)
				set diag_intro_text_2 to "Progress: " & sizeOfdownloadProgressDelimited & "KB downloaded in " & time_running & " minutes."
			else
				--A default display when there are no progress details available in response file
				set progress_percentage to ""
				set diag_intro_text_2 to "Progressing"
			end if
		end if
		
		-- Set variables for Monitor display which need to be updated with each repeat		
		set {intro_label2, theTop} to create label diag_intro_text_2 left inset 0 bottom 5 max width minWidth aligns center aligned control size small size
		set {intro_label1, theTop} to create label diag_intro_text_1 left inset 50 bottom theTop + 10 max width minWidth - 50 control size small size
		-- set {intro_label, theTop} to create label diag_intro_text left inset 75 bottom 5 max width accViewWidth - 80 control size small size
		set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix_monitor left inset 0 bottom theTop - 40 view width 45 view height 45 scale image scale proportionally
		
		-- Display the monitor dialog
		set {monitor_button_returned} to display enhanced window monitor_diag_Title buttons theButtons giving up after 5 acc view width accViewWidth acc view height theTop acc view controls {intro_label2, intro_label1, MacYTDL_icon} initial position {X_position_monitor, Y_position_monitor}
		
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
			exit repeat
			-- User clicked on "Open log folder"
		else if monitor_button_returned is "Logs" then
			tell application "Finder"
				activate
				open (MacYTDL_preferences_path_monitor as POSIX file)
				set the position of the front Finder window to {100, 100} -- <= This DOES work but is ugly - it opens the window then moves it
			end tell
			exit repeat
		end if
		
	end repeat
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
-- Handler to add comma delimiters to a number
on convertNumberToCommaDelimitedString(theNumber)
	set theNumber to theNumber as string
	set theNumberLength to length of theNumber
	set theNumber to (reverse of every character of theNumber) as string
	set commaDelimitedNumber to ""
	repeat with a from 1 to theNumberLength
		if a is theNumberLength or (a mod 3) is not 0 then
			set commaDelimitedNumber to (character a of theNumber & commaDelimitedNumber) as string
		else
			set commaDelimitedNumber to ("," & character a of theNumber & commaDelimitedNumber) as string
		end if
	end repeat
	return commaDelimitedNumber
end convertNumberToCommaDelimitedString
