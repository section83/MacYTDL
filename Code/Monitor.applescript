---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  MacYTDL
--  A GUI for the Python Scripts youtube-dl and yt-dlp.  Many thanks to Shane Stanley, Adam Albrec, kopurando and Michael Page
--  This is the Download Monitor
--  This script provides a download Monitor for each video file download requested by user - it is called by main.scpt
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Include libraries - needed for Shane Staney's Dialog Toolkit
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use script "DialogToolkitMacYTDL" -- Yosemite (10.10) or later

-- Run the Monitor when the script is called
on run {downloadsFolder_Path_monitor, MacYTDL_preferences_path_monitor, YTDL_TimeStamps_monitor, ytdl_settings_monitor, URL_user_entered_monitor, YTDL_log_file_monitor, download_filename_monitor, download_filename_new_monitor, MacYTDL_custom_icon_file_posix_monitor, monitor_dialog_position, YTDL_simulate_log_monitor, diag_Title_quoted_monitor, is_Livestream_Flag_monitor, screen_width, screen_height, DL_Use_YTDLP, path_to_MacYTDL, YTDL_Delete_Partial, ADL_Clear_Batch}
	
	
	--	try
	
	
	--*****************
	-- Dialog for testing that parameters were passed correctly by the calling script
	--	display dialog "downloadsFolder_Path_monitor: " & downloadsFolder_Path_monitor & return & return & "MacYTDL_preferences_path_monitor: " & MacYTDL_preferences_path_monitor & return & return & "timestamps: " & YTDL_TimeStamps_monitor & return & return & "ytdl_settings_monitor: " & ytdl_settings_monitor & return & return & "URL_user_entered_monitor: " & URL_user_entered_monitor & return & return & "YTDL_log_file_monitor: " & YTDL_log_file_monitor & return & return & "download_filename_monitor: " & "\"" & download_filename_monitor & "\"" & return & return & "download_filename_new_monitor: " & download_filename_new_monitor & return & return & "MacYTDL_custom_icon_file_posix_monitor: " & MacYTDL_custom_icon_file_posix_monitor & return & return & "monitor_dialog_position: " & monitor_dialog_position & return & return & "YTDL_simulate_log_monitor: " & YTDL_simulate_log_monitor & return & return & "diag_Title_quoted_monitor: " & diag_Title_quoted_monitor & return & return & "is_Livestream_Flag_monitor: " & is_Livestream_Flag_monitor & return & return & "screen_width: " & screen_width & return & return & "screen_height: " & screen_height & return & return & "DL_Use_YTDLP: " & DL_Use_YTDLP & return & return & "path_to_MacYTDL: " & path_to_MacYTDL & return & return & "Delete partial: " & YTDL_Delete_Partial & return & return & "Clear batch: " & ADL_Clear_Batch with title "Monitor"
	--*****************
	
	-- Set variable to contain path to MacYTDL bundle and the ets executable
	set pathToBundle to (path to me) as text
	set pathToBundleShort to text 1 thru -40 of pathToBundle
	
	-- Calculate the number of monitor dialogs per column which is also the maximum number of rows
	set number_of_monitors_per_column to round (screen_height / 200)
	-- Calculate the column number
	set column_number to (round (monitor_dialog_position / number_of_monitors_per_column) rounding up)
	-- Set the X_position
	set X_position_monitor to screen_width - (250 * column_number)
	-- Work out which row is to be used - starts at row 0 which is the top of the screen
	set row_number to (monitor_dialog_position - (number_of_monitors_per_column * (column_number - 1))) - 1
	-- Calculate the Y_position
	set Y_position_monitor to (row_number * 150)
	
	-- This variable is never set to Yes so, why keep it ?
	set download_finished to "No"
	
	-- Set more variables to enable passing to shell 
	set YTDL_log_file_monitor_posix to POSIX file YTDL_log_file_monitor
	set MacYTDL_custom_icon_file_not_posix_monitor to POSIX file MacYTDL_custom_icon_file_posix_monitor as text
	
	-- Set paths for shell command - probably don't need all of these - need to test reomving some
	set shellPath to "PATH=$PATH:/bin:/sbin:/usr/bin:/usr/local/bin:/usr/sbin:~/opt/bin:~/opt/sbin:/opt/local/bin:/opt/local/sbin:/opt/homebrew/bin:" & quoted form of (POSIX path of ((path to me as text) & "::")) & "; "
	
	-- Need quoted form so that paths and strings with spaces are handled correctly by the shell
	set downloadsFolder_Path_monitor_quoted to quoted form of downloadsFolder_Path_monitor
	set YTDL_log_file_monitor_quoted to quoted form of YTDL_log_file_monitor
	set diag_Title_monitor to quoted form of diag_Title_quoted_monitor
	set diag_Title_quoted_monitor to quoted form of diag_Title_quoted_monitor
	if YTDL_TimeStamps_monitor is not "" then
		set YTDL_TimeStamps_monitor_quoted to quoted form of YTDL_TimeStamps_monitor
	else
		set YTDL_TimeStamps_monitor_quoted to ""
	end if
	set MacYTDL_custom_icon_file_not_posix_monitor_quoted to quoted form of MacYTDL_custom_icon_file_not_posix_monitor -- Passed to Adviser for display dialog
	
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
	
	-- Initialise flag to indicate kind of Monitor is being displayed
	set monitor_state_flag to "Downloading"
	
	
	-- Remove quotes from around ytdl_settings_monitor as they cause problems with running youtube-dl/yt-dlp command from shell
	set ytdl_settings_monitor to items 2 thru -1 of ytdl_settings_monitor as string
	
	-- Blank out URL_user_entered_monitor_quoted - is set to Null when downloading a batch
	if URL_user_entered_monitor_quoted is "Null" then
		set URL_user_entered_monitor_quoted to ""
	end if
	
	-- Sometimes, there is a linefeed at the end of the file name - remove it
	if character -1 of download_filename_monitor is linefeed then
		set download_filename_monitor to text 1 thru -2 of download_filename_monitor
	end if
	
	-- Change extension in download file name and displayed file name if user requested a remux - simulate often has the old extension - need to match the final after remux so that Adviser can play it - Need to handle batches which have different remux setting to original add to batch - But not for playlists
	-- 1.24 - This If block caused problems with SBS/ABC Chooser downloads in which the download_filename_monitor has no extension - decided to add code looking for the "." character positioned 3 or 4 characters from end of the name
	if ytdl_settings_monitor contains "--recode-video" then
		set look_for_extension_1 to character -4 of download_filename_monitor
		set look_for_extension_2 to character -5 of download_filename_monitor
		if look_for_extension_1 is "." or look_for_extension_2 is "." then
			-- Get new extension - always follows the word recode
			set all_words to words in ytdl_settings_monitor
			repeat with i from 1 to the length of all_words
				if item i of all_words is "recode" then exit repeat
			end repeat
			set new_extension to item (i + 2) in all_words
			-- Get old extension - with multiple downloads and playlists, only need to find the first as the Adviser only plays the first file
			set the_first_file_name to first paragraph of download_filename_monitor
			set AppleScript's text item delimiters to {"."}
			set old_extension to last text item of the_first_file_name
			set AppleScript's text item delimiters to {""}
			if old_extension is not equal to new_extension then
				-- Following code changed in v1.23.1 - For a batch need to get download file name from different variable
				if download_filename_new_monitor_plain is "the saved batch" then
					set download_filename_monitor to replace_chars(download_filename_monitor, old_extension, new_extension)
				end if
				set download_filename_new_monitor_plain to replace_chars(download_filename_new_monitor_plain, old_extension, new_extension)
			end if
		end if
	end if
	
	-- Change extension in download file name if user requested a particular audio format - simulate often has the old format extension - need to match the final after post processing so that Adviser can play it
	if ytdl_settings_monitor contains "--audio-format" then
		-- Get new extension - always follows the word audio-format
		set AppleScript's text item delimiters to {"audio-format ", " --audio-quality"}
		set new_extension to second text item of ytdl_settings_monitor
		-- Get old extension - with multiple downloads and playlists, only need to find the first as the Adviser only plays the first file
		set the_first_file_name to first paragraph of download_filename_monitor
		set AppleScript's text item delimiters to {"."}
		set old_extension to last text item of the_first_file_name
		set AppleScript's text item delimiters to {""}
		if old_extension is not equal to new_extension then
			set download_filename_monitor to replace_chars(download_filename_monitor, old_extension, new_extension)
		end if
	end if
	
	-- *****************************************
	-- Dialog for testing content of parameters about to be sent to shell to do download
	--display dialog "shellPath: " & shellPath & return & return & "downloadsFolder_Path_monitor_quoted: " & downloadsFolder_Path_monitor_quoted & return & return & "YTDL_TimeStamps_monitor_quoted: " & YTDL_TimeStamps_monitor_quoted & return & return & "DL_Use_YTDLP: " & DL_Use_YTDLP & return & return & "ytdl_settings_monitor: " & ytdl_settings_monitor & return & return & "URL_user_entered_monitor_quoted: " & URL_user_entered_monitor_quoted & return & return & "YTDL_log_file_monitor_quoted: " & YTDL_log_file_monitor_quoted
	-- *****************************************
	
	-- Convert name of  YT-DLP-Legacy to make life easier from here on
	if DL_Use_YTDLP is "yt-dlp-legacy" then
		set monitor_DL_Use_YTDLP to "yt-dlp"
	else
		set monitor_DL_Use_YTDLP to DL_Use_YTDLP
	end if
	
	-- Get pid of this Monitor instance to send to Adviser
	-- Might get the wrong pid if there are two osascript processes underway + complicated by the "ets" process - but as of 25/1/22 it seems to work and can't think of another way
	try
		set monitor_pid to do shell script "pgrep -n osascript &"
	on error errtext
		display dialog "There was an error with the pgrep:" & errtext
	end try
	
	
	-- *******************************************************************************************************************************************************		
	-- Parallel downloads - parse download_filename_new_monitor to get multiple URLs, files names and log file names - use a repeat loop
	set batch_parallel_flag to false
	-- Set up for parallel download of playlists
	if download_filename_new_monitor contains "#$" then -- This is a playlist to be downloaded in parallel
		set number_paragraphs to ((count of paragraphs of download_filename_new_monitor) - 1) -- Always has a return at the end
		-- Need a list of process ids, file names, playlist name and log file names to check after they have all started and show in Monitor dialog - only works if list items are initialised
		set ytdl_parallel_pid to {}
		set download_logfile_Parallel_List to {}
		set download_filename_Parallel_List to {}
		repeat (number_paragraphs) times
			set end of ytdl_parallel_pid to ""
			set end of download_logfile_Parallel_List to ""
			set end of download_filename_Parallel_List to ""
		end repeat
		
		set AppleScript's text item delimiters to {"##", "#$"} -- This is the delimiter added by Main to download_filename_new_monitor when user wants parallel downloads
		repeat with x from 1 to number_paragraphs
			set download_filename_new_monitor_item to paragraph x of download_filename_new_monitor
			
			set playlist_parallel_name to text item 1 of download_filename_new_monitor_item
			set download_filename_parallel to text item 2 of download_filename_new_monitor_item
			set item x of download_filename_Parallel_List to (playlist_parallel_name & "#$" & download_filename_parallel) -- show_parallel_Monitor() needs to find these cases
			
			set download_URL_parallel_quoted to quoted form of (text item 3 of download_filename_new_monitor_item)
			
			set download_logfile_Parallel_not_quoted to (text item 4 of download_filename_new_monitor_item)
			set download_logfile_Parallel_quoted to quoted form of download_logfile_Parallel_not_quoted
			set item x of download_logfile_Parallel_List to download_logfile_Parallel_not_quoted -- Test of not adding quotes - WORKS
			
			-- Issue yt-dlp command to download the requested video file in background - returns PID of Python process + errors; anything else returned by yt-dlp goes into log file
			set item x of ytdl_parallel_pid to do shell script shellPath & "cd " & downloadsFolder_Path_monitor_quoted & " ; " & YTDL_TimeStamps_monitor_quoted & " " & monitor_DL_Use_YTDLP & " " & ytdl_settings_monitor & " " & download_URL_parallel_quoted & " &> " & download_logfile_Parallel_quoted & " & echo $!"
		end repeat
		set AppleScript's text item delimiters to {""}
		
		show_parallel_Monitor(download_logfile_Parallel_List, download_filename_Parallel_List, pathToBundleShort, MacYTDL_custom_icon_file_posix_monitor, X_position_monitor, Y_position_monitor, ytdl_parallel_pid, MacYTDL_preferences_path_monitor, batch_parallel_flag, downloadsFolder_Path_monitor, YTDL_Delete_Partial, ADL_Clear_Batch)
		
		-- Set up for parallel downloads of batches and multiple downloads		
	else if download_filename_new_monitor contains "##" then -- Parallel download of multiple URLs or batch
		set number_paragraphs to ((count of paragraphs of download_filename_new_monitor) - 1) -- Always has a return at the end
		-- Need a list of process ids, file names and log file names to check after they have all started and show in Monitor dialog - only works if list items are initialised
		set ytdl_parallel_pid to {}
		set download_logfile_Parallel_List to {}
		set download_filename_Parallel_List to {}
		repeat (number_paragraphs) times
			set end of ytdl_parallel_pid to ""
			set end of download_logfile_Parallel_List to ""
			set end of download_filename_Parallel_List to ""
		end repeat
		
		-- Remove any single quotes surrounding download_filename_new_monitor
		if character 1 of download_filename_new_monitor is "'" then
			set download_filename_new_monitor to text 2 thru -2 of download_filename_new_monitor
		end if
		
		set AppleScript's text item delimiters to {"##"} -- This is the delimiter added by Main to download_filename_new_monitor when user wants parallel downloads
		repeat with x from 1 to number_paragraphs
			set download_filename_parallel to text item 1 of paragraph x of download_filename_new_monitor
			set item x of download_filename_Parallel_List to download_filename_parallel
			set download_URL_parallel_quoted to quoted form of (text item 2 of paragraph x of download_filename_new_monitor)
			set download_logfile_Parallel_not_quoted to (text item 3 of paragraph x of download_filename_new_monitor)
			set download_logfile_Parallel_quoted to quoted form of download_logfile_Parallel_not_quoted
			set item x of download_logfile_Parallel_List to download_logfile_Parallel_not_quoted -- Test of not adding quotes - WORKS
			
			-- Issue yt-dlp command to download the requested video file in background - returns PID of Python process + errors; anything else returned by yt-dlp goes into log file
			set item x of ytdl_parallel_pid to do shell script shellPath & "cd " & downloadsFolder_Path_monitor_quoted & " ; " & YTDL_TimeStamps_monitor_quoted & " " & monitor_DL_Use_YTDLP & " " & ytdl_settings_monitor & " " & download_URL_parallel_quoted & " &> " & download_logfile_Parallel_quoted & " & echo $!"
		end repeat
		set AppleScript's text item delimiters to {""}
		
		if URL_user_entered_monitor is null then set batch_parallel_flag to true
		
		show_parallel_Monitor(download_logfile_Parallel_List, download_filename_Parallel_List, pathToBundleShort, MacYTDL_custom_icon_file_posix_monitor, X_position_monitor, Y_position_monitor, ytdl_parallel_pid, MacYTDL_preferences_path_monitor, batch_parallel_flag, downloadsFolder_Path_monitor, YTDL_Delete_Partial, ADL_Clear_Batch)
		
		-- Set up for parallel download of iView and SBS episodes - download_filename_new_monitor is not used any further and so can be used to store the parallel flag which would otherwise cause grief with parsing
	else if download_filename_new_monitor contains "$$" then
		set number_paragraphs to count of paragraphs of download_filename_monitor
		
		-- Need a list of process ids, file names and log file names to check after they have all started and show in Monitor dialog - only works if list items are initialised
		set ytdl_parallel_pid to {}
		set download_logfile_Parallel_List to {}
		set download_filename_Parallel_List to {}
		repeat (number_paragraphs) times
			set end of ytdl_parallel_pid to ""
			set end of download_logfile_Parallel_List to ""
			set end of download_filename_Parallel_List to ""
		end repeat
		
		-- Remove any single quotes surrounding download_filename_monitor
		if character 1 of download_filename_monitor is "'" then
			set download_filename_monitor to text 2 thru -2 of download_filename_monitor
		end if
		-- Setting delimiters done for each iteration as otherwise it pollutes the offset command
		repeat with x from 1 to number_paragraphs
			set download_filename_parallel to paragraph x of download_filename_monitor
			set item x of download_filename_Parallel_List to download_filename_parallel
			set AppleScript's text item delimiters to {" "}
			-- v1.27 - Very crude - should look for reason URL_user_entered_monitor sometimes starts with a space character
			if text 1 of URL_user_entered_monitor is not "h" then
				set download_URL_parallel_quoted to quoted form of (text item (x + 1) of URL_user_entered_monitor)
			else
				set download_URL_parallel_quoted to quoted form of (text item x of URL_user_entered_monitor)
			end if
			set AppleScript's text item delimiters to {""}
			
			-- Need to trim off ".[extension]" from file name before making name of log file
			set download_filename_parallel_trimmed to text 1 thru ((download_filename_parallel's length) - (offset of "." in (the reverse of every character of download_filename_parallel) as text)) of download_filename_parallel
			set download_filename_parallel_trimmed_not_quoted to replace_chars(download_filename_parallel_trimmed, " ", "_")
			set download_date_time to get_Date_Time()
			set download_logfile_Parallel to MacYTDL_preferences_path_monitor & "ytdl_log-" & download_filename_parallel_trimmed_not_quoted & "-" & download_date_time & ".txt"
			set download_logfile_Parallel_quoted to quoted form of download_logfile_Parallel
			set item x of download_logfile_Parallel_List to download_logfile_Parallel
			
			-- Issue yt-dlp command to download the requested video file in background - returns PID of Python process + errors; anything else returned by yt-dlp goes into log file
			set item x of ytdl_parallel_pid to do shell script shellPath & "cd " & downloadsFolder_Path_monitor_quoted & " ; " & YTDL_TimeStamps_monitor_quoted & " " & monitor_DL_Use_YTDLP & " " & ytdl_settings_monitor & " " & download_URL_parallel_quoted & " &> " & download_logfile_Parallel_quoted & " & echo $!"
		end repeat
		
		if URL_user_entered_monitor is null then set batch_parallel_flag to true
		
		show_parallel_Monitor(download_logfile_Parallel_List, download_filename_Parallel_List, pathToBundleShort, MacYTDL_custom_icon_file_posix_monitor, X_position_monitor, Y_position_monitor, ytdl_parallel_pid, MacYTDL_preferences_path_monitor, batch_parallel_flag, downloadsFolder_Path_monitor, YTDL_Delete_Partial, ADL_Clear_Batch)
		
		
		
		-- *******************************************************************************************************************************************************		
		
		
		
		
	else
		
		-- Issue youtube-dl/yt-dlp command to download the requested video file in background - returns PID of Python process + errors; anything else returned by youtube-dl/yt-dlp goes into log file
		set youtubedl_pid to do shell script shellPath & "cd " & downloadsFolder_Path_monitor_quoted & " ; " & YTDL_TimeStamps_monitor_quoted & " " & monitor_DL_Use_YTDLP & " " & ytdl_settings_monitor & " " & URL_user_entered_monitor_quoted & " &> " & YTDL_log_file_monitor_quoted & " & echo $!"
		
		-- Set up for starting the Adviser - get path to adviser script, set parameters to be passed, start the Adviser
		-- Prepare to call on the Adviser
		
		-- Test whether user wants a description file - transmit to Adviser so it can fix the file name after download
		set DL_description_monitor to "No"
		if ytdl_settings_monitor contains "description" then
			set DL_description_monitor to "Yes"
		end if
		
		-- *****************************************
		set path_to_monitor to (path to me) as string -- <= Duplicates line of code at beginning of this script except "string" instead of "text"
		-- *****************************************
		
		-- Make quoted forms of variables so they are passed corectly into the Adviser shell script
		set path_to_scripts to text 1 thru -13 of path_to_monitor
		set myAdviserScriptAsString to quoted form of POSIX path of (path_to_scripts & "adviser.scpt")
		set download_filename_monitor_quoted to quoted form of download_filename_monitor
		set download_filename_new_monitor to quoted form of download_filename_new_monitor
		set download_filename_new_monitor_plain_quoted to quoted form of download_filename_new_monitor_plain
		set YTDL_simulate_log_monitor_quoted to quoted form of YTDL_simulate_log_monitor
		set MacYTDL_preferences_path_monitor_quoted to quoted form of MacYTDL_preferences_path_monitor
		set adviser_params to monitor_pid & " " & youtubedl_pid & " " & MacYTDL_custom_icon_file_not_posix_monitor_quoted & " " & MacYTDL_preferences_path_monitor_quoted & " " & YTDL_log_file_monitor_quoted & " " & downloadsFolder_Path_monitor_quoted & " " & diag_Title_quoted_monitor & " " & DL_description_monitor & " " & is_Livestream_Flag_monitor & " " & download_filename_monitor_quoted & " " & download_filename_new_monitor & " " & download_filename_new_monitor_plain_quoted & " " & YTDL_simulate_log_monitor_quoted & " " & ADL_Clear_Batch
		
		-- Production call to Adviser
		set adviser_pid to do shell script "osascript -s s " & myAdviserScriptAsString & " " & adviser_params & " " & " > /dev/null 2> /dev/null & echo $!"
		
		-- Test call to Adviser - often not useful
		--set adviser_pid to do shell script "osascript -s s " & myAdviserScriptAsString & " " & adviser_params & " " & " echo $!"
		
		
		-- Set text for localization
		set theProgressLabel to localized string "Progress:" in bundle file pathToBundleShort from table "MacYTDL"
		set theProgressingLabel to localized string "Progressing" in bundle file pathToBundleShort from table "MacYTDL"
		set theDownloadInLabel to localized string "downloaded in" in bundle file pathToBundleShort from table "MacYTDL"
		set theDownloadOfLabel to localized string "downloaded of" in bundle file pathToBundleShort from table "MacYTDL"
		set theMinutesLabel to localized string "minutes." in bundle file pathToBundleShort from table "MacYTDL"
		set theInLabel to localized string "in" in bundle file pathToBundleShort from table "MacYTDL"
		set theOKLabel to localized string "OK" in bundle file pathToBundleShort from table "MacYTDL"
		set theMonitorIntroTextLabel1 to localized string "Download" in bundle file pathToBundleShort from table "MacYTDL"
		--			set theMonitorIntroTextLabel1 to localized string "Your download of" in bundle file pathToBundleShort from table "MacYTDL"
		set theMonitorIntroTextLabel2 to localized string "has started." in bundle file pathToBundleShort from table "MacYTDL"
		set theButtonsPauseLabel to localized string "Pause" in bundle file pathToBundleShort from table "MacYTDL"
		set theButtonsResumeLabel to localized string "Resume" in bundle file pathToBundleShort from table "MacYTDL"
		set theButtonsLogLabel to localized string "Log" in bundle file pathToBundleShort from table "MacYTDL"
		set theButtonsStopLabel to localized string "Stop" in bundle file pathToBundleShort from table "MacYTDL"
		set theButtonsCloseLabel to localized string "Close" in bundle file pathToBundleShort from table "MacYTDL"
		set theRunningLabel to localized string "Running" in bundle file pathToBundleShort from table "MacYTDL"
		set thePercentSymbolLabel to localized string "%" in bundle file pathToBundleShort from table "MacYTDL"
		set theMBSymbolLabel to localized string "MB" in bundle file pathToBundleShort from table "MacYTDL"
		set theGBSymbolLabel to localized string "GB" in bundle file pathToBundleShort from table "MacYTDL"
		
		-- Prepare and display the download monitor dialog - set starting variables
		set seconds_running to 0
		set time_running to 0
		set progress_percentage to ""
		set downloadFileSize to ""
		set monitor_diag_Title to "MacYTDL"
		set diag_intro_text_1 to theMonitorIntroTextLabel1 & " \"" & download_filename_new_monitor_plain & "\" "
		--			set diag_intro_text_1 to theMonitorIntroTextLabel1 & " \"" & download_filename_new_monitor_plain & "\" " & theMonitorIntroTextLabel2
		set accViewWidth to 100
		set accViewInset to 0
		set the_date_start to current date
		set the_time_start to time of the_date_start
		
		-- Set buttons
		if is_Livestream_Flag_monitor is "True" then
			set {theButtons, minWidth} to create buttons {theButtonsLogLabel, theButtonsStopLabel} button keys {"l", "S"}
			set minWidth to 250
		else
			set {theButtons, minWidth} to create buttons {theButtonsLogLabel, theButtonsStopLabel, theButtonsPauseLabel, theButtonsCloseLabel} button keys {"l", "S", "P", ""} default button 4
		end if
		if minWidth > accViewWidth then set accViewWidth to minWidth -- make sure buttons fit
		
		-- It can take time for log file to get content - delay Monitor a bit
		delay 2
		
		-- Repeat loop to display monitor every 5 seconds (set in create enhanced window call), update with progress, redisplay - can close dialog, stop download, pause download or open logs folder - automatically closed by Adviser.scpt when download finished
		repeat
			-- Get YTDL log up to this point - if file is empty, Monitor will show "Progressing"
			set size_of_log to get eof YTDL_log_file_monitor_posix
			if size_of_log is less than 5 then
				set YTDL_log to "No log"
			else
				try
					set YTDL_log to read file YTDL_log_file_monitor_posix as text
				on error errMsg
					display dialog "Error in Monitor reading log file: " & YTDL_log_file_monitor_posix & return & "Error message: " & errMsg
				end try
			end if
			
			-- Get time running since start, convert into minutes
			set the_time to time of (current date)
			set seconds_running to the_time - the_time_start
			set time_running to seconds_running / minutes
			set round_factor to 0.1
			set time_running to (round time_running / round_factor) * round_factor
			
			--A default display when there are no progress details available in log file
			set progress_percentage to ""
			set diag_intro_text_2 to theProgressingLabel
			
			-- Use content of log to fashion text to appear in Monitor dialog
			if YTDL_log is not "No log" then
				set YTDL_log_lastParapraph to paragraph -2 of YTDL_log
				-- If progress meter available, get current percentage and file size - trim leading spaces from percentage - convert [MiB to MB]/[GiB to GB] in file size to match Finder
				if YTDL_log_lastParapraph contains "[download]" and YTDL_log_lastParapraph contains "%" and YTDL_log_lastParapraph contains "at" then
					set progress_percentage to last word in (text 1 thru (offset of "%" in YTDL_log_lastParapraph) of YTDL_log_lastParapraph)
					set o to (offset of "." in progress_percentage)
					if ((o > 0) and (0.0 as text is "0,0")) then set progress_percentage to (text 1 thru (o - 1) of progress_percentage & "," & text (o + 1) thru -1 of progress_percentage)
					-- YTDL Progress meter reports estimated size of download in GiB or MiB
					set GiBPositionAfterSize to offset of "GiB" in YTDL_log_lastParapraph -- Crude but does work
					if GiBPositionAfterSize is not 0 then
						set downloadFileSizeGiB to last word in (text 22 thru (GiBPositionAfterSize - 1) of YTDL_log_lastParapraph)
						set approxIndicator to character 1 of downloadFileSizeGiB
						if approxIndicator is "~" then
							set downloadFileSizeGiB to text 2 thru end of downloadFileSizeGiB
							set o to (offset of "." in downloadFileSizeGiB)
							if ((o > 0) and (0.0 as text is "0,0")) then set downloadFileSizeGiB to (text 1 thru (o - 1) of downloadFileSizeGiB & "," & text (o + 1) thru -1 of downloadFileSizeGiB)
							set downloadFileSizeGiB to downloadFileSizeGiB as number
							set downloadFileSizeGB to downloadFileSizeGiB * 1.04858 as number
							set round_factor to 0.01
							set downloadFileSizeGB to (round downloadFileSizeGB / round_factor) * round_factor
						else
							set approxIndicator to ""
							set o to (offset of "." in downloadFileSizeGiB)
							if ((o > 0) and (0.0 as text is "0,0")) then set downloadFileSizeGiB to (text 1 thru (o - 1) of downloadFileSizeGiB & "," & text (o + 1) thru -1 of downloadFileSizeGiB)
							set downloadFileSizeGiB to downloadFileSizeGiB as number
							set downloadFileSizeGB to downloadFileSizeGiB * 1.04858 as number
							set round_factor to 0.01
							set downloadFileSizeGB to (round downloadFileSizeGB / round_factor) * round_factor
						end if
						set diag_intro_text_2 to theProgressLabel & " " & progress_percentage & thePercentSymbolLabel & " " & theDownloadOfLabel & " " & approxIndicator & downloadFileSizeGB & theGBSymbolLabel & " " & theInLabel & " " & time_running & " " & theMinutesLabel
					else
						set MiBPositionAfterSize to offset of "MiB" in YTDL_log_lastParapraph
						set downloadFileSizeMiB to last word in (text 22 thru (MiBPositionAfterSize - 1) of YTDL_log_lastParapraph)
						set approxIndicator to character 1 of downloadFileSizeMiB
						if approxIndicator is "~" then
							set downloadFileSizeMiB to text 2 thru end of downloadFileSizeMiB
							set o to (offset of "." in downloadFileSizeMiB)
							if ((o > 0) and (0.0 as text is "0,0")) then set downloadFileSizeMiB to (text 1 thru (o - 1) of downloadFileSizeMiB & "," & text (o + 1) thru -1 of downloadFileSizeMiB)
							set downloadFileSizeMiB to downloadFileSizeMiB as number
							set downloadFileSizeMB to downloadFileSizeMiB * 1.04858 as number
							set round_factor to 0.01
							set downloadFileSizeMB to (round downloadFileSizeMB / round_factor) * round_factor
						else
							set approxIndicator to ""
							set o to (offset of "." in downloadFileSizeMiB)
							if ((o > 0) and (0.0 as text is "0,0")) then set downloadFileSizeMiB to (text 1 thru (o - 1) of downloadFileSizeMiB & "," & text (o + 1) thru -1 of downloadFileSizeMiB)
							set downloadFileSizeMiB to downloadFileSizeMiB as number
							set downloadFileSizeMB to downloadFileSizeMiB * 1.04858 as number
							set round_factor to 0.01
							set downloadFileSizeMB to (round downloadFileSizeMB / round_factor) * round_factor
						end if
						set diag_intro_text_2 to theProgressLabel & " " & progress_percentage & thePercentSymbolLabel & " " & theDownloadOfLabel & " " & approxIndicator & downloadFileSizeMB & theMBSymbolLabel & " " & theInLabel & " " & time_running & " " & theMinutesLabel
					end if
				else if YTDL_log_lastParapraph contains "[Merger] Merging formats into" then
					set diag_intro_text_2 to "FFmpeg merging formats ...."
				else if YTDL_log_lastParapraph contains "[VideoConvertor] Converting video from" then
					set diag_intro_text_2 to "Converting download ...."
				else if YTDL_log_lastParapraph contains "[ThumbnailsConvertor] Converting thumbnail" then
					set diag_intro_text_2 to "Converting thumbnail ...."
				else if YTDL_log_lastParapraph contains "[EmbedThumbnail] mutagen:" then
					set diag_intro_text_2 to "Embedding thumbnail ...."
				else if YTDL_log_lastParapraph contains "[ExtractAudio] Destination:" then
					set diag_intro_text_2 to "Extracting audio ...."
				else if YTDL_log_lastParapraph contains "[ffmpeg] Fixing malformed" then
					set diag_intro_text_2 to "FFmpeg fixing bitstream ...."
				else if YTDL_log_lastParapraph contains "[ffmpeg] Merging formats into" then
					set diag_intro_text_2 to "FFmpeg merging formats ...."
				else if YTDL_log_lastParapraph contains "[FixupM3u8] Fixing" then
					set diag_intro_text_2 to "Fixing container ...."
				else if YTDL_log_lastParapraph contains "[info] Downloading video thumbnail" or YTDL_log_lastParapraph contains "[info] Writing video thumbnail" then
					set diag_intro_text_2 to "Writing thumbnail ...."
				else if YTDL_log_lastParapraph contains "[debug] Invoking downloader on" then
					set diag_intro_text_2 to "Starting download ...."
				else if YTDL_log_lastParapraph contains "[debug] ffmpeg command line" then
					set diag_intro_text_2 to (theRunningLabel & " FFmpeg ....")
				else if YTDL_log contains "size= " then
					-- FFMpeg regularly reports amount downloaded - find latest report - convert kibibytes to kilobytes to match size reported by Finder
					set numParasInlog to count of paragraphs in YTDL_log
					repeat with i from 1 to numParasInlog
						set lastParaInlog to paragraph (-i) of YTDL_log
						if lastParaInlog contains "size=" then
							set offsetOfSize to offset of "size" in lastParaInlog
							set sizeOfDownloadProgress to text (offsetOfSize + 5) thru (offsetOfSize + 12) of lastParaInlog
							set sizeOfDownloadProgress to (sizeOfDownloadProgress * 1.024) as integer
							exit repeat
						else
							set i to i + 1
						end if
					end repeat
					set sizeOfdownloadProgressDelimited to convertNumberToCommaDelimitedString(sizeOfDownloadProgress)
					set diag_intro_text_2 to theProgressLabel & " " & sizeOfdownloadProgressDelimited & "KB" & " " & theDownloadInLabel & " " & time_running & " " & theMinutesLabel
				end if
			end if
			
			-- Set variables for Monitor dialog which need to be updated with each repeat
			-- v1.25 – Move intro_label2 down the Monitor ie increase theTop variable if intro_label1 is one line - prevents overlap with image
			--set {intro_label2, theTop} to create label diag_intro_text_2 left inset 0 bottom 5 max width minWidth - 20 aligns center aligned control size mini size with multiline
			set {intro_label2, theTop} to create label diag_intro_text_2 left inset 0 bottom 5 max width minWidth - 20 aligns center aligned control size small size with multiline
			set intro_label2_thTop to theTop
			--set {intro_label1, theTop} to create label diag_intro_text_1 left inset 50 bottom theTop + 10 max width minWidth - 51 control size mini size
			set {intro_label1, theTop} to create label diag_intro_text_1 left inset 50 bottom theTop + 10 max width minWidth - 51 control size small size
			set intro_label1_thTop to theTop
			if (intro_label1_thTop - intro_label2_thTop) < 25 then set theTop to (theTop + 12) -- Calculate height added by intro_label1
			set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix_monitor left inset 0 bottom theTop - 40 view width 40 view height 40 scale image scale proportionally
			
			-- Display the monitor dialog - set give up @ 5 seconds so that code can continue the repeat loop - but not if paused
			if monitor_state_flag is "Downloading" then
				set {monitor_button_returned, buttonNumber, controlResults, finalPosition} to display enhanced window monitor_diag_Title buttons theButtons giving up after 5 acc view width accViewWidth acc view height theTop acc view controls {intro_label2, intro_label1, MacYTDL_icon} initial position {X_position_monitor, Y_position_monitor}
			else if monitor_state_flag is "Paused" then
				set {theButtons} to create buttons {theButtonsLogLabel, theButtonsResumeLabel, theButtonsCloseLabel} button keys {"l", "R", ""} default button 3
				set {monitor_button_returned, buttonNumber, controlResults, finalPosition} to display enhanced window monitor_diag_Title buttons theButtons acc view width accViewWidth acc view height theTop acc view controls {intro_label2, intro_label1, MacYTDL_icon} initial position {X_position_monitor, Y_position_monitor}
			end if
			
			-- User clicked on the Pause download button - This kills the Python process and all child FFmpeg processes - Suppress the Adviser - Leave alone partially downloaded file
			if monitor_button_returned is theButtonsPauseLabel then
				-- Try to kill the download processes but, ignore if process already gone - YTDL and yt-dlp have different process child-parent structures
				-- Kill the adviser as it's not needed except for live streams - force kill because during auto-dowloads it cannot be terminated normally
				-- Re-display the Monitor but with Resume instead of Stop
				set monitor_state_flag to "Paused"
				try
					if is_Livestream_Flag_monitor is not "True" then
						do shell script "kill -9 " & adviser_pid
					end if
				end try
				
				-- Both YTDL and yt-dlp spawn a child process
				try
					set ffmpeg_child_pid to do shell script "pgrep -P " & youtubedl_pid
				end try
				--yt-dlp often has an FFmpeg process which is a child of a child of youtubedl_pid - ignore any errors e.g. there is no child or grandchild process
				try
					if monitor_DL_Use_YTDLP is "yt-dlp" then
						set ffmpeg_grandchild_pid to do shell script "pgrep -P " & ffmpeg_child_pid
					end if
				end try
				-- Try to killl everything and ignore errors e.g. process doesn't exist
				try
					do shell script "kill " & ffmpeg_grandchild_pid
				end try
				try
					do shell script "kill " & ffmpeg_child_pid
				end try
				try
					do shell script "kill " & youtubedl_pid
				end try
				-- Now it returns to start of this repeat loop and redisplays Monitor but with different buttons
			else if monitor_button_returned is theButtonsResumeLabel then
				
				-- Spawn another Monitor to resume download - this instance should die - YT-DLP will by default resume partially downloaded file
				-- Need to form up content of myMonitorScriptAsString and my_params
				-- Other variables might need some tweaking to get right
				
				-- Need to form up some variables to send to the next Monitor
				set monitor_state_flag to "Resumed"
				set ytdl_settings_monitor to (" " & ytdl_settings_monitor)
				-- Trim extension off download filename and remove extraneous quotes - for log file name
				set download_filename_new_monitor_noquotes_trimmed to text 2 thru ((download_filename_new_monitor's length) - (offset of "." in (the reverse of every character of download_filename_new_monitor) as text)) of download_filename_new_monitor
				-- Remove extraneous quotes from download_filename_new_monitor and diag_Title_quoted_monitor which gets quoted in next call to Monitor.scpt - safer that way
				if last character of diag_Title_quoted_monitor is "'" then
					set diag_Title_quoted_monitor to text 2 through ((length of diag_Title_quoted_monitor) - 1) of diag_Title_quoted_monitor
				end if
				if last character of download_filename_new_monitor is "'" then
					set download_filename_new_monitor to text 2 through ((length of download_filename_new_monitor) - 1) of download_filename_new_monitor
				end if
				set download_date_time to get_Date_Time()
				set myMonitorScriptAsString to quoted form of ((POSIX path of path_to_MacYTDL) & "Contents/Resources/Scripts/Monitor.scpt")
				set YTDL_log_file_resume to MacYTDL_preferences_path_monitor & "youtube-dl_log-" & download_filename_new_monitor_noquotes_trimmed & "-" & download_date_time & ".txt"
				
				set my_params to quoted form of downloadsFolder_Path_monitor & " " & quoted form of MacYTDL_preferences_path_monitor & " " & quoted form of YTDL_TimeStamps_monitor & " " & quoted form of ytdl_settings_monitor & " " & quoted form of URL_user_entered_monitor & " " & quoted form of YTDL_log_file_resume & " " & quoted form of download_filename_monitor & " " & quoted form of download_filename_new_monitor & " " & quoted form of MacYTDL_custom_icon_file_posix_monitor & " " & monitor_dialog_position & " " & quoted form of YTDL_simulate_log_monitor & " " & quoted form of diag_Title_quoted_monitor & " " & is_Livestream_Flag_monitor & " " & screen_width & " " & screen_height & " " & monitor_DL_Use_YTDLP & " " & quoted form of path_to_MacYTDL
				
				do shell script "osascript -s s " & myMonitorScriptAsString & " " & my_params & " " & " > /dev/null 2> /dev/null &"
				-- Now return to beginning of repeat loop to re-display the Monitor dialog
				
				-- User clicked on the Stop download button - This kills the Python process and all child FFmpeg processes, then moves to Trash all ".part" files related to the download - Suppress the Adviser
			else if monitor_button_returned is theButtonsStopLabel then
				
				-- Try to kill the processes but, ignore if process already gone - YTDL and yt-dlp have different process child-parent structures
				-- Kill the adviser as it's not needed except for live streams - force kill because during auto-downloads it cannot be terminated normally				
				set monitor_state_flag to "Stopped"
				try
					if is_Livestream_Flag_monitor is not "True" then
						do shell script "kill -9 " & adviser_pid
					end if
				end try
				
				-- Both YTDL and yt-dlp spawn a child process
				try
					set ffmpeg_child_pid to do shell script "pgrep -P " & youtubedl_pid
				end try
				--yt-dlp often has an FFmpeg process which is a child of a child of youtubedl_pid - ignore any errors e.g. there is no child or grandchild process
				try
					if monitor_DL_Use_YTDLP is "yt-dlp" then
						set ffmpeg_grandchild_pid to do shell script "pgrep -P " & ffmpeg_child_pid
					end if
				end try
				-- v1.27 - Issue interupts to live streams - to enable FFmpeg to exit gracefully
				-- Try to killl everything and ignore errors e.g. process doesn't exist
				if is_Livestream_Flag_monitor is "True" then
					try
						do shell script "kill -2 " & ffmpeg_grandchild_pid
					end try
					try
						do shell script "kill -2 " & ffmpeg_child_pid
					end try
					try
						do shell script "kill -2 " & youtubedl_pid
					end try
				else
					try
						do shell script "kill " & ffmpeg_grandchild_pid
					end try
					try
						do shell script "kill " & ffmpeg_child_pid
					end try
					try
						do shell script "kill " & youtubedl_pid
					end try
				end if
				-- WORK IN PROGRESS - SOMETIMES FAILS TO DELETE PARTIAL FILES - BUT NOT SURE THAT'S A BAD THING
				if download_finished is "No" then
					-- Partly completed download process will leave behind "part" and/or "ytdl" files which are be moved to Trash if user wishes
					-- Completed downloads should be left alone
					-- Handle multiple downloads separately as the name for the file spec comes from simulate.txt instead of the download_filename_new_monitor variable
					-- Need to trim off file extension in name search because YTDL sometimes has part files with part numbers between the name and the extension - works for 3 and 4 character extensions
					if (download_filename_new_monitor_plain is "the multiple videos" or download_filename_new_monitor_plain is "the-playlist") and YTDL_Delete_Partial is "true" then
						repeat with each_filename in (get paragraphs of YTDL_simulate_log_monitor)
							set each_filename to text 1 thru -5 of each_filename
							if each_filename does not contain "WARNING" then
								set part_files to do shell script "find " & downloadsFolder_Path_monitor_quoted & " -maxdepth 1 -type f -iname *" & quoted form of each_filename & "*.part* -or -iname " & quoted form of each_filename & "*.ytdl*"
								repeat with each_part_files in (get paragraphs of part_files)
									do shell script "mv " & quoted form of each_part_files & " ~/.trash/"
								end repeat
							end if
						end repeat
						-- Handle ABC & SBS show pages separately as file names are not in simulate nor in download_filename_new_monitor but in download_filename_monitor
					else if (YTDL_simulate_log_monitor contains "ERROR: Unsupported URL: https://iview" or YTDL_simulate_log_monitor contains "ERROR: Unsupported URL: https://www.sbs") and YTDL_Delete_Partial is "true" then
						repeat with each_filename in (get paragraphs of download_filename_monitor)
							set each_filename to text 1 thru -1 of each_filename
							if each_filename does not contain "WARNING:" then
								set part_files to do shell script "find " & downloadsFolder_Path_monitor_quoted & " -maxdepth 1 -type f -iname *" & (quoted form of each_filename) & "*part* -or -iname *" & (quoted form of each_filename) & "*.ytdl* -or -iname *" & (quoted form of each_filename) & "*-Frag* -or -iname *" & (quoted form of each_filename) & "*f???*"
								repeat with each_part_files in (get paragraphs of part_files)
									do shell script "mv " & quoted form of each_part_files & " ~/.trash/"
								end repeat
							end if
						end repeat
						-- All other kinds of download - Monitor currently cannot delete partly downloaded files left by batch download
					else if download_filename_new_monitor is not "the saved batch" and is_Livestream_Flag_monitor is "False" and YTDL_Delete_Partial is "true" then
						-- Look for all files in DL folder that meet file spec
						set download_filename_monitor_trimmed to text 1 thru -5 of download_filename_monitor
						set part_files to do shell script "find " & downloadsFolder_Path_monitor_quoted & " -maxdepth 1 -type f -iname *" & (quoted form of download_filename_monitor_trimmed) & "*part* -or -iname *" & (quoted form of download_filename_monitor_trimmed) & "*.ytdl* -or -iname *" & (quoted form of download_filename_monitor_trimmed) & "*-Frag* -or -iname *" & (quoted form of download_filename_monitor_trimmed) & "*f???*"
						repeat with each_part_files in (get paragraphs of part_files)
							do shell script "mv " & quoted form of each_part_files & " ~/.trash/"
						end repeat
					end if
				end if
				exit repeat
				
				-- Open log folder and continue to display Monitor - Would be nice to open log file for currently downloading file – the Adviser has code for that
			else if monitor_button_returned is theButtonsLogLabel then
				tell application "Finder"
					activate
					open (MacYTDL_preferences_path_monitor as POSIX file)
					set the position of the front Finder window to {100, 100}
				end tell
				--				end if
				
			else if monitor_button_returned is theButtonsCloseLabel then
				exit repeat
			end if
			
			
			-- Check whether the download has finished - if it has, the download process has gone and a "ps" command will bang an error - keep monitor open if user paused DL
			-- This try/on error block checks for presence of the "ets" process - that's the pid returned by the do shell script which starts the downloads
			if monitor_state_flag is not "Paused" then
				try
					-- does the PID exist?
					do shell script "ps -p " & youtubedl_pid
				on error
					exit repeat
				end try
			end if
		end repeat
	end if
	
	
	
	
	
	--	on error errMsg
	--		display dialog errMsg
	--	end try
	
	
	
	
end run

-- Handler to show Monitor dialog for parallel downloads
on show_parallel_Monitor(download_logfile_Parallel_List, download_filename_Parallel_List, pathToBundleShort, MacYTDL_custom_icon_file_posix_monitor, X_position_monitor, Y_position_monitor, ytdl_parallel_pid, MacYTDL_preferences_path_monitor, batch_parallel_flag, downloadsFolder_Path_monitor, YTDL_Delete_Partial, ADL_Clear_Batch)
	
	-- Set text for localization
	set theProgressLabel to localized string "Progress:" in bundle file pathToBundleShort from table "MacYTDL"
	set theProgressingLabel to localized string "Progressing" in bundle file pathToBundleShort from table "MacYTDL"
	set theDownloadInLabel to localized string "downloaded in" in bundle file pathToBundleShort from table "MacYTDL"
	set theDownloadOfLabel to localized string "downloaded of" in bundle file pathToBundleShort from table "MacYTDL"
	set theMinutesLabel to localized string "minutes." in bundle file pathToBundleShort from table "MacYTDL"
	set theInLabel to localized string "in" in bundle file pathToBundleShort from table "MacYTDL"
	set theOKLabel to localized string "OK" in bundle file pathToBundleShort from table "MacYTDL"
	set theButtonsPauseLabel to localized string "Pause" in bundle file pathToBundleShort from table "MacYTDL"
	set theButtonsResumeLabel to localized string "Resume" in bundle file pathToBundleShort from table "MacYTDL"
	set theButtonsLogLabel to localized string "Log" in bundle file pathToBundleShort from table "MacYTDL"
	set theButtonsStopLabel to localized string "Stop" in bundle file pathToBundleShort from table "MacYTDL"
	set theButtonsCloseLabel to localized string "Close" in bundle file pathToBundleShort from table "MacYTDL"
	set theRunningLabel to localized string "Running" in bundle file pathToBundleShort from table "MacYTDL"
	set thePercentSymbolLabel to localized string "%" in bundle file pathToBundleShort from table "MacYTDL"
	set theMBSymbolLabel to localized string "MB" in bundle file pathToBundleShort from table "MacYTDL"
	set theGBSymbolLabel to localized string "GB" in bundle file pathToBundleShort from table "MacYTDL"
	
	-- Prepare and display the download monitor dialog - set starting variables
	set seconds_running to 0
	set time_running to 0
	set progress_percentage to ""
	set downloadFileSize to ""
	set monitor_diag_Title to "MacYTDL"
	--	set diag_intro_text_1 to theMonitorIntroTextLabel1 & " \"" & download_filename_new_monitor_plain & "\" " & theMonitorIntroTextLabel2
	set accViewWidth to 150
	set accViewInset to 0
	set the_date_start to current date
	set the_time_start to time of the_date_start
	set number_of_downloads to number of items in download_logfile_Parallel_List
	
	-- Initialise counter to track completed downloads
	set download_completed_flag to {}
	repeat (number_of_downloads) times
		set end of download_completed_flag to ""
	end repeat
	
	-- Set buttons
	set {theButtons, minWidth} to create buttons {theButtonsLogLabel, theButtonsStopLabel, theButtonsCloseLabel} button keys {"l", "S", ""} cancel button 3
	if minWidth > accViewWidth then set accViewWidth to minWidth -- make sure buttons fit
	
	-- It can take time for log file to get content - delay Monitor a bit
	delay 2
	
	-- Repeat loop to display monitor every 3 seconds (delay is set in "create enhanced window"), update with progress, redisplay - can close dialog, stop download or open logs folder
	repeat
		
		-- Need to reset diag_progress_text after showing the dialog for each iteration
		set diag_progress_text to ""
		
		-- Nest another repeat loop which iterates through the multiple log files to get progress on each download them format that into the one Monitor dialog
		-- Find last line of each log file, add to diag_progress_text [a string] which will be shown in Monitor dialog
		repeat with x from 1 to number_of_downloads
			
			set download_filename_truncated to (item x of download_filename_Parallel_List)
			set playlist_name to ""
			-- Trim playlist details from download filename
			if download_filename_truncated contains "#$" then
				set AppleScript's text item delimiters to {"#$"}
				set playlist_name to text item 1 of download_filename_truncated
				set download_filename_truncated to text item 2 of download_filename_truncated
				set AppleScript's text item delimiters to {""}
			end if
			if length of download_filename_truncated is greater than 35 then
				set download_filename_truncated to text 1 thru 35 of download_filename_truncated & "..."
			end if
			set download_filename_truncated to replace_chars(download_filename_truncated, "_", " ") -- So that file name in Monitor dialog looks better and takes less space
			
			set YTDL_log_file_monitor to item x of download_logfile_Parallel_List
			set YTDL_log_file_monitor_posix to POSIX file YTDL_log_file_monitor
			
			-- Get YTDL log up to this point - if file is empty, Monitor will show "Progressing"
			set size_of_log to get eof YTDL_log_file_monitor_posix
			if size_of_log is less than 5 then
				set YTDL_log to "No log"
			else
				try
					set YTDL_log to read file YTDL_log_file_monitor_posix as text
				on error errMsg
					display dialog "Error in Monitor reading log file: " & YTDL_log_file_monitor_posix & return & "Error message: " & errMsg
				end try
			end if
			
			-- Get time running since start, convert into minutes
			set the_time to time of (current date)
			set seconds_running to the_time - the_time_start
			set time_running to seconds_running / minutes
			set round_factor to 0.1
			set time_running to (round time_running / round_factor) * round_factor
			
			--A default display when there are no progress details available in log file
			set progress_percentage to ""
			set diag_intro_text_2 to download_filename_truncated & return & theProgressingLabel
			
			if item x of download_completed_flag is true then
				set diag_intro_text_2 to download_filename_truncated & return & "Completed"
			end if
			
			-- Use content of log to fashion text to appear in Monitor dialog - log file always has a blank paragraph at end - so, need to find the second last paragraph for latest progress report
			if YTDL_log is not "No log" then
				set YTDL_log_lastParapraph to paragraph -2 of YTDL_log
				-- If progress meter available, get current percentage and file size - trim leading spaces from percentage - convert [MiB to MB]/[GiB to GB] in file size to match Finder
				if YTDL_log_lastParapraph contains "[download]" and YTDL_log_lastParapraph contains "%" and YTDL_log_lastParapraph contains "at" then
					set progress_percentage to last word in (text 1 thru (offset of "%" in YTDL_log_lastParapraph) of YTDL_log_lastParapraph)
					set o to (offset of "." in progress_percentage)
					if ((o > 0) and (0.0 as text is "0,0")) then set progress_percentage to (text 1 thru (o - 1) of progress_percentage & "," & text (o + 1) thru -1 of progress_percentage)
					-- YTDL Progress meter reports estimated size of download in GiB or MiB
					set GiBPositionAfterSize to offset of "GiB" in YTDL_log_lastParapraph -- Crude but does work
					if GiBPositionAfterSize is not 0 then
						set downloadFileSizeGiB to last word in (text 22 thru (GiBPositionAfterSize - 1) of YTDL_log_lastParapraph)
						set approxIndicator to character 1 of downloadFileSizeGiB
						if approxIndicator is "~" then
							set downloadFileSizeGiB to text 2 thru end of downloadFileSizeGiB
							set o to (offset of "." in downloadFileSizeGiB)
							if ((o > 0) and (0.0 as text is "0,0")) then set downloadFileSizeGiB to (text 1 thru (o - 1) of downloadFileSizeGiB & "," & text (o + 1) thru -1 of downloadFileSizeGiB)
							set downloadFileSizeGiB to downloadFileSizeGiB as number
							set downloadFileSizeGB to downloadFileSizeGiB * 1.04858 as number
							set round_factor to 0.01
							set downloadFileSizeGB to (round downloadFileSizeGB / round_factor) * round_factor
						else
							set approxIndicator to ""
							set o to (offset of "." in downloadFileSizeGiB)
							if ((o > 0) and (0.0 as text is "0,0")) then set downloadFileSizeGiB to (text 1 thru (o - 1) of downloadFileSizeGiB & "," & text (o + 1) thru -1 of downloadFileSizeGiB)
							set downloadFileSizeGiB to downloadFileSizeGiB as number
							set downloadFileSizeGB to downloadFileSizeGiB * 1.04858 as number
							set round_factor to 0.01
							set downloadFileSizeGB to (round downloadFileSizeGB / round_factor) * round_factor
						end if
						set diag_intro_text_2 to download_filename_truncated & return & progress_percentage & thePercentSymbolLabel & " " & theDownloadOfLabel & " " & approxIndicator & downloadFileSizeGB & theGBSymbolLabel
					else
						set MiBPositionAfterSize to offset of "MiB" in YTDL_log_lastParapraph
						set downloadFileSizeMiB to last word in (text 22 thru (MiBPositionAfterSize - 1) of YTDL_log_lastParapraph)
						set approxIndicator to character 1 of downloadFileSizeMiB
						if approxIndicator is "~" then
							set downloadFileSizeMiB to text 2 thru end of downloadFileSizeMiB
							set o to (offset of "." in downloadFileSizeMiB)
							if ((o > 0) and (0.0 as text is "0,0")) then set downloadFileSizeMiB to (text 1 thru (o - 1) of downloadFileSizeMiB & "," & text (o + 1) thru -1 of downloadFileSizeMiB)
							set downloadFileSizeMiB to downloadFileSizeMiB as number
							set downloadFileSizeMB to downloadFileSizeMiB * 1.04858 as number
							set round_factor to 0.01
							set downloadFileSizeMB to (round downloadFileSizeMB / round_factor) * round_factor
						else
							set approxIndicator to ""
							set o to (offset of "." in downloadFileSizeMiB)
							if ((o > 0) and (0.0 as text is "0,0")) then set downloadFileSizeMiB to (text 1 thru (o - 1) of downloadFileSizeMiB & "," & text (o + 1) thru -1 of downloadFileSizeMiB)
							set downloadFileSizeMiB to downloadFileSizeMiB as number
							set downloadFileSizeMB to downloadFileSizeMiB * 1.04858 as number
							set round_factor to 0.01
							set downloadFileSizeMB to (round downloadFileSizeMB / round_factor) * round_factor
						end if
						set diag_intro_text_2 to download_filename_truncated & return & progress_percentage & thePercentSymbolLabel & " " & theDownloadOfLabel & " " & approxIndicator & downloadFileSizeMB & theMBSymbolLabel
					end if
				else if YTDL_log_lastParapraph contains "[Merger] Merging formats into" then
					set diag_intro_text_2 to download_filename_truncated & return & "FFmpeg merging formats ...."
				else if YTDL_log_lastParapraph contains "[VideoConvertor] Converting video from" then
					set diag_intro_text_2 to download_filename_truncated & return & "Converting download ...."
				else if YTDL_log_lastParapraph contains "[ThumbnailsConvertor] Converting thumbnail" then
					set diag_intro_text_2 to download_filename_truncated & return & "Converting thumbnail ...."
				else if YTDL_log_lastParapraph contains "[EmbedThumbnail] mutagen:" then
					set diag_intro_text_2 to download_filename_truncated & return & "Embedding thumbnail ...."
				else if YTDL_log_lastParapraph contains "[ExtractAudio] Destination:" then
					set diag_intro_text_2 to download_filename_truncated & return & "Extracting audio ...."
				else if YTDL_log_lastParapraph contains "[ffmpeg] Fixing malformed" then
					set diag_intro_text_2 to download_filename_truncated & return & "FFmpeg fixing bitstream ...."
				else if YTDL_log_lastParapraph contains "[ffmpeg] Merging formats into" then
					set diag_intro_text_2 to download_filename_truncated & return & "FFmpeg merging formats ...."
				else if YTDL_log_lastParapraph contains "[FixupM3u8] Fixing" then
					set diag_intro_text_2 to download_filename_truncated & return & "Fixing container ...."
				else if YTDL_log_lastParapraph contains "[info] Downloading video thumbnail" or YTDL_log_lastParapraph contains "[info] Writing video thumbnail" then
					set diag_intro_text_2 to download_filename_truncated & return & "Writing thumbnail ...."
				else if YTDL_log_lastParapraph contains "[debug] Invoking downloader on" then
					set diag_intro_text_2 to download_filename_truncated & return & "Starting download ...."
				else if YTDL_log_lastParapraph contains "[debug] ffmpeg command line" then
					set diag_intro_text_2 to download_filename_truncated & return & (theRunningLabel & " FFmpeg ....")
				else if YTDL_log contains "size= " then
					-- FFMpeg regularly reports amount downloaded - find latest report - convert kibibytes to kilobytes to match size reported by Finder
					set numParasInlog to count of paragraphs in YTDL_log
					repeat with i from 1 to numParasInlog
						set lastParaInlog to paragraph (-i) of YTDL_log
						if lastParaInlog contains "size=" then
							set offsetOfSize to offset of "size" in lastParaInlog
							set sizeOfDownloadProgress to text (offsetOfSize + 5) thru (offsetOfSize + 12) of lastParaInlog
							set sizeOfDownloadProgress to (sizeOfDownloadProgress * 1.024) as integer
							exit repeat
						else
							set i to i + 1
						end if
					end repeat
					set sizeOfdownloadProgressDelimited to convertNumberToCommaDelimitedString(sizeOfDownloadProgress)
					set diag_intro_text_2 to download_filename_truncated & return & " " & sizeOfdownloadProgressDelimited & "KB"
				end if
			end if
			-- Form up diag_progress_text which will be shown in Monitor dialog - hold progress details from all the log files
			set diag_progress_text to diag_progress_text & diag_intro_text_2 & return
		end repeat
		
		-- Set variables for Monitor dialog which need to be updated with each repeat
		--		set {intro_label2, theTop} to create label diag_progress_text left inset 0 bottom 5 max width minWidth - 20 aligns center aligned control size mini size with multiline
		set {intro_label2, theTop} to create label diag_progress_text left inset 0 bottom 1 max width accViewWidth aligns center aligned control size mini size without multiline
		set intro_label2_thTop to theTop
		
		if playlist_name is "" then
			set diag_intro_text_1 to localized string "Parallel download:" in bundle file pathToBundleShort from table "MacYTDL"
		else
			set diag_intro_text_1 to localized string "Parallel download of playlist:" in bundle file pathToBundleShort from table "MacYTDL"
		end if
		if batch_parallel_flag is true then set diag_intro_text_1 to localized string "Parallel download of batch:" in bundle file pathToBundleShort from table "MacYTDL"
		set {intro_label1, theTop} to create label diag_intro_text_1 left inset 35 bottom theTop + 10 max width minWidth - 51 control size small size
		set intro_label1_thTop to theTop
		if (intro_label1_thTop - intro_label2_thTop) < 25 then set theTop to (theTop + 12) -- Calculate height added by intro_label1
		
		set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix_monitor left inset 0 bottom theTop - 30 view width 30 view height 30 scale image scale proportionally
		
		-- Display the monitor dialog - set giving up @ 3 seconds so that code can continue the repeat loop
		set {monitor_button_returned, buttonNumber, controlResults, finalPosition} to display enhanced window monitor_diag_Title buttons theButtons giving up after 3 acc view width accViewWidth acc view height theTop acc view controls {intro_label2, intro_label1, MacYTDL_icon} initial position {X_position_monitor, Y_position_monitor}
		
		if monitor_button_returned is theButtonsStopLabel then
			-- Try to kill the processes but, ignore if process already gone - YTDL and yt-dlp have different process child-parent structures
			-- Repeat through all the parent processes - kill them and all the child processes
			repeat with x from 1 to number_of_downloads
				set youtubedl_pid to (item x of ytdl_parallel_pid)
				try
					set ffmpeg_child_pid to do shell script "pgrep -P " & youtubedl_pid
				end try
				--yt-dlp often has an FFmpeg process which is a child of a child of youtubedl_pid - ignore any errors e.g. there is no child or grandchild process
				try
					if monitor_DL_Use_YTDLP is "yt-dlp" then
						set ffmpeg_grandchild_pid to do shell script "pgrep -P " & ffmpeg_child_pid
					end if
				end try
				-- Try to killl everything and ignore errors e.g. process doesn't exist
				try
					do shell script "kill " & ffmpeg_grandchild_pid
				end try
				try
					do shell script "kill " & ffmpeg_child_pid
				end try
				try
					do shell script "kill " & youtubedl_pid
				end try
				-- Get filename, clean it and try to move all related partial files to trash
				if YTDL_Delete_Partial is "true" then
					set download_filename to (item x of download_filename_Parallel_List)
					-- Trim playlist details from download filename
					if download_filename contains "#$" then
						set AppleScript's text item delimiters to {"#$"}
						set download_filename to text item 2 of download_filename
						set AppleScript's text item delimiters to {""}
					end if
					set download_filename to replace_chars(download_filename, "_", " ") -- So that file name in Monitor dialog looks better and takes less space
					-- Look for all files in DL folder that meet file spec - remove file extensions
					set download_filename_trimmed to text 1 thru -5 of download_filename
					set part_files to do shell script "find " & downloadsFolder_Path_monitor & " -maxdepth 1 -type f -iname *" & (quoted form of download_filename_trimmed) & "*part* -or -iname *" & (quoted form of download_filename_trimmed) & "*ytdl* -or -iname *" & (quoted form of download_filename_trimmed) & "*-Frag* -or -iname *" & (quoted form of download_filename_trimmed) & "*f???*"
					repeat with each_part_files in (get paragraphs of part_files)
						do shell script "mv " & quoted form of each_part_files & " ~/.trash/"
					end repeat
				end if
			end repeat
			
			-- Open log folder and continue to display Monitor
		else if monitor_button_returned is theButtonsLogLabel then
			tell application "Finder"
				activate
				open (MacYTDL_preferences_path_monitor as POSIX file)
				set the position of the front Finder window to {100, 100}
			end tell
			
			-- User clicked on Close - close Monitor but continue downloads		
		else if monitor_button_returned is theButtonsCloseLabel then
			exit repeat
		end if
		
		-- Report back when all processes have finished - crude but works
		set process_finished_count to 0
		repeat with x from 1 to number_of_downloads
			try
				-- does the PID exist?
				do shell script "ps -p" & (item x of ytdl_parallel_pid)
			on error
				set process_finished_count to process_finished_count + 1
				set item x of download_completed_flag to true
			end try
		end repeat
		-- If all processes have finished, close Monitor dialog - show Adviser but not if user stopped the download - Kill Monitor which otherwise will stay on screen for 3 seconds thus perhaps overlapping the Adviser alert
		if process_finished_count is number_of_downloads then
			if monitor_button_returned is not theButtonsStopLabel then
				-- Need a way to close the Monitor dialog so it no longer underlies the Adviser
				show_Adviser(pathToBundleShort, theButtonsCloseLabel, downloadsFolder_Path_monitor, download_logfile_Parallel_List, MacYTDL_preferences_path_monitor, ADL_Clear_Batch)
			end if
			exit repeat
		end if
		
		-- This ends the repeat loop which shows the Monitor - Monitor has closed because user clicked on "Close" or because downloads have finished - now return to on run()
	end repeat
	
end show_parallel_Monitor

-- Handler to show an advice that parallel downloads have finished
on show_Adviser(pathToBundleShort, theButtonsCloseLabel, downloadsFolder_Path_monitor, download_logfile_Parallel_List, MacYTDL_preferences_path_monitor, ADL_Clear_Batch)
	set alerterPath to quoted form of (POSIX path of (pathToBundleShort & "Contents:Resources:"))
	-- Try to reduce Advsier overlapping with Monitor – don't know why/how they can be displayed at same time !
	delay 1
	-- Check log files for errors
	set error_count to 0
	set number_of_downloads to number of items in download_logfile_Parallel_List
	set batch_failed_downloads to ""
	set batch_filename to "BatchFile.txt" as string
	set batch_file to POSIX file (MacYTDL_preferences_path_monitor & batch_filename)
	set batch_file_download_items to read file batch_file as «class utf8»
	repeat with y from 1 to number_of_downloads
		set final_logfile to item y of download_logfile_Parallel_List
		set final_logfile_posix to POSIX file final_logfile
		try
			set YTDL_log to read file final_logfile_posix as text
		on error errMsg
			display dialog "Error in Monitor reading log file: " & final_logfile & return & "Error message: " & errMsg
		end try
		if YTDL_log contains "ERROR: " then
			set error_count to (error_count + 1)
			set batch_failed_URL_item to paragraph y of batch_file_download_items
			set batch_failed_downloads to (batch_failed_downloads & batch_failed_URL_item & return)
		end if
		-- if YTDL_log does not contain "ERROR: " then set error_count to (error_count + 1) -- <<== For testing the alert
	end repeat
	
	--	set subtitleText to quoted form of ("“" & download_filename_new_monitor_plain & "”")    -- Might be able to provide playlist name or similar
	if error_count is greater than 0 then
		if ADL_Clear_Batch is "true" then
			set batch_file_ref to missing value
			set batch_file_ref to open for access batch_file with write permission
			set eof batch_file_ref to 0
			write batch_failed_downloads to batch_file_ref starting at eof as «class utf8»
			close access batch_file_ref
		end if
		set theAdviserTextLabel1 to quoted form of (localized string "There was an error in the download." in bundle file pathToBundleShort from table "MacYTDL")
		set theAdviserTextLabel2 to quoted form of (localized string "Click to open downloads folder" in bundle file pathToBundleShort from table "MacYTDL")
		set subtitleText to quoted form of ((localized string "There were errors with" in bundle file pathToBundleShort from table "MacYTDL") & " " & error_count & " " & (localized string "files" in bundle file pathToBundleShort from table "MacYTDL") & ".")
	else
		if ADL_Clear_Batch is "true" then
			set batch_file_ref to missing value
			set batch_file_ref to open for access batch_file with write permission
			set eof batch_file_ref to 0
			close access batch_file_ref
		end if
		set subtitleText to quoted form of ((number_of_downloads as string) & " " & (localized string "downloads." in bundle file pathToBundleShort from table "MacYTDL"))
		set theAdviserTextLabel1 to quoted form of (localized string "MacYTDL parallel download finished:" in bundle file pathToBundleShort from table "MacYTDL")
		set theAdviserTextLabel2 to quoted form of (localized string "Click to open downloads folder" in bundle file pathToBundleShort from table "MacYTDL")
	end if
	-- Might add actions when able to play one of the downloads
	--set theAdviserButtonsCloseLabel2 to localized string "Play" in bundle file pathToBundleShort from table "MacYTDL"
	--	set adviser_button to do shell script alerterPath & "/alerter -message " & theAdviserTextLabel2 & " -title " & theAdviserTextLabel1 & " -subtitle " & subtitleText & " -closeLabel " & theButtonsCloseLabel & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & theAdviserButtonsCloseLabel2
	set adviser_button to do shell script alerterPath & "/alerter -message " & theAdviserTextLabel2 & " -title " & theAdviserTextLabel1 & " -subtitle " & subtitleText & " -actions " & theButtonsCloseLabel & " -timeout 10 -sender com.apple.script.id.MacYTDL"
	if adviser_button is "@CONTENTCLICKED" then
		tell application "Finder"
			activate
			open (downloadsFolder_Path_monitor as POSIX file)
			set the position of the front Finder window to {100, 100}
		end tell
	end if
end show_Adviser

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
-- Handler to get and format current date-time - needs all special characters replaced with underscores
on get_Date_Time()
	set download_date_time to (current date) as string
	set AppleScript's text item delimiters to {", ", " ", ":", ","}
	set the item_list to every text item of download_date_time
	set AppleScript's text item delimiters to "_"
	set download_date_time to the item_list as string
	set AppleScript's text item delimiters to ""
	return download_date_time
end get_Date_Time
