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
on run {downloadsFolder_Path_monitor, MacYTDL_preferences_path_monitor, YTDL_TimeStamps_monitor, ytdl_options_monitor, URL_user_entered_monitor, YTDL_response_file_monitor, download_filename_monitor, download_filename_new_monitor, MacYTDL_custom_icon_file_posix_monitor, monitor_dialog_position, YTDL_simulate_response_monitor, diag_Title_quoted_monitor, is_Livestream_Flag_monitor, screen_width, screen_height, DL_Use_YTDLP}
	
	--*****************
	-- Dialog for testing that parameters were passed correctly by the calling script
	-- display dialog "downloadsFolder_Path_monitor: " & downloadsFolder_Path_monitor & return & return & "timestamps: " & YTDL_TimeStamps_monitor & return & return & "ytdl_options_monitor: " & ytdl_options_monitor & return & return & "URL_user_entered_monitor: " & URL_user_entered_monitor & return & return & "YTDL_response_file_monitor: " & YTDL_response_file_monitor & return & return & "download_filename_monitor: " & "\"" & download_filename_monitor & "\"" & return & return & "download_filename_new_monitor: " & download_filename_new_monitor & return & return & "MacYTDL_custom_icon_file_posix_monitor: " & MacYTDL_custom_icon_file_posix_monitor & return & return & "monitor_dialog_position: " & monitor_dialog_position & return & return & "YTDL_simulate_response_monitor: " & YTDL_simulate_response_monitor & return & return & "is_Livestream_Flag_monitor: " & is_Livestream_Flag_monitor
	--*****************
	
	-- try
	
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
	set Y_position_monitor to (row_number * 175)
	
	set download_finished to "No"
	
	-- Set more variables to enable passing to shell 
	set YTDL_response_file_monitor_posix to POSIX file YTDL_response_file_monitor
	set MacYTDL_custom_icon_file_not_posix_monitor to POSIX file MacYTDL_custom_icon_file_posix_monitor as text
	
	-- Set paths for shell command - probably don't need all of these - need to test reomving some
	set shellPath to "PATH=$PATH:/bin:/sbin:/usr/bin:/usr/local/bin:/usr/sbin:~/opt/bin:~/opt/sbin:/opt/local/bin:/opt/local/sbin:" & quoted form of (POSIX path of ((path to me as text) & "::")) & "; "
	
	-- Need quoted form so that paths and strings with spaces are handled correctly by the shell
	set downloadsFolder_Path_monitor_quoted to quoted form of downloadsFolder_Path_monitor
	set YTDL_response_file_monitor_quoted to quoted form of YTDL_response_file_monitor
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
	
	-- Remove quotes from around YTDL_options as they cause problems with running youtube-dl/yt-dlp command from shell
	set ytdl_options_monitor to items 2 thru -1 of ytdl_options_monitor as string
	
	-- Blank out URL_user_entered_monitor_quoted - is set to Null when downloading a batch
	if URL_user_entered_monitor_quoted is "Null" then
		set URL_user_entered_monitor_quoted to ""
	end if
	
	-- Sometimes, there is a linefeed at the end of the file name - remove it
	if character -1 of download_filename_monitor is linefeed then
		set download_filename_monitor to text 1 thru -2 of download_filename_monitor
	end if
	
	-- Change extension in download file name and displayed file name if user requested a remux - simulate often has the old format extension - need to match the final after remux so that Adviser can play it - But not for playlists
	if ytdl_options_monitor contains "--recode-video" then
		-- Get new extension - always follows the word recode
		set all_words to words in ytdl_options_monitor
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
			set download_filename_monitor to replace_chars(download_filename_monitor, old_extension, new_extension)
			if (count of paragraphs in download_filename_monitor) is 1 then
				set download_filename_new_monitor_plain to download_filename_monitor
			end if
		end if
	end if
	
	-- Change extension in download file name if user requested a particular audio format - simulate often has the old format extension - need to match the final after post processing so that Adviser can play it
	if ytdl_options_monitor contains "--audio-format" then
		-- Get new extension - always follows the word audio-format
		set AppleScript's text item delimiters to {"audio-format ", " --audio-quality"}
		set new_extension to second text item of ytdl_options_monitor
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
	--display dialog "shellPath: " & shellPath & return & return & "downloadsFolder_Path_monitor_quoted: " & downloadsFolder_Path_monitor_quoted & return & return & "YTDL_TimeStamps_monitor_quoted: " & YTDL_TimeStamps_monitor_quoted & return & return & "DL_Use_YTDLP: " & DL_Use_YTDLP & return & return & "ytdl_options_monitor: " & ytdl_options_monitor & return & return & "URL_user_entered_monitor_quoted: " & URL_user_entered_monitor_quoted & return & return & "YTDL_response_file_monitor_quoted: " & YTDL_response_file_monitor_quoted
	-- *****************************************
	
	-- Issue youtube-dl/yt-dlp command to download the requested video file in background - returns PID of Python process + errors; anything else flagged by youtube-dl/yt-dlp goes into response file
	set youtubedl_pid to do shell script shellPath & "cd " & downloadsFolder_Path_monitor_quoted & " ; " & YTDL_TimeStamps_monitor_quoted & " " & DL_Use_YTDLP & " " & ytdl_options_monitor & " " & URL_user_entered_monitor_quoted & " &> " & YTDL_response_file_monitor_quoted & " & echo $!"
	
	-- Set up for starting the Adviser - get path to adviser script, set parameters to be passed, start the Adviser
	-- Prepare to call on the Adviser
	-- Get pid of this Monitor instance
	-- Might get the wrong pid if there are two osascript processes underway + complicated by the "ets" process - but as of 25/1/22 it seems to work and can't think of another way
	
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
	
	-- *****************************************
	set path_to_monitor to (path to me) as string -- <= Duplicates line of code at beginning of this script except "string" instead of "text"
	-- *****************************************
	
	-- Make quoted forms of variables so they are passed corectly into the shell script
	set path_to_scripts to text 1 thru -13 of path_to_monitor
	set myAdviserScriptAsString to quoted form of POSIX path of (path_to_scripts & "adviser.scpt")
	set download_filename_monitor_quoted to quoted form of download_filename_monitor
	set download_filename_new_monitor to quoted form of download_filename_new_monitor
	set download_filename_new_monitor_plain_quoted to quoted form of download_filename_new_monitor_plain
	set YTDL_simulate_response_monitor_quoted to quoted form of YTDL_simulate_response_monitor
	set MacYTDL_preferences_path_monitor_quoted to quoted form of MacYTDL_preferences_path_monitor
	set adviser_params to monitor_pid & " " & youtubedl_pid & " " & MacYTDL_custom_icon_file_not_posix_monitor_quoted & " " & MacYTDL_preferences_path_monitor_quoted & " " & YTDL_response_file_monitor_quoted & " " & downloadsFolder_Path_monitor_quoted & " " & diag_Title_quoted_monitor & " " & DL_description_monitor & " " & is_Livestream_Flag_monitor & " " & download_filename_monitor_quoted & " " & download_filename_new_monitor & " " & download_filename_new_monitor_plain_quoted & " " & YTDL_simulate_response_monitor_quoted
	
	-- Production call to Adviser
	set adviser_pid to do shell script "osascript -s s " & myAdviserScriptAsString & " " & adviser_params & " " & " > /dev/null 2> /dev/null & echo $!"
	
	-- Test call to Adviser - often not useful
	-- set adviser_pid to do shell script "osascript -s s " & myAdviserScriptAsString & " " & adviser_params & " " & " echo $!"
	
	-- Set text for localization
	set theProgressLabel to localized string "Progress:" in bundle file pathToBundleShort from table "MacYTDL"
	set theProgressingLabel to localized string "Progressing" in bundle file pathToBundleShort from table "MacYTDL"
	set theDownloadInLabel to localized string "downloaded in" in bundle file pathToBundleShort from table "MacYTDL"
	set theDownloadOfLabel to localized string "downloaded of" in bundle file pathToBundleShort from table "MacYTDL"
	set theMinutesLabel to localized string "minutes." in bundle file pathToBundleShort from table "MacYTDL"
	set theInLabel to localized string "in" in bundle file pathToBundleShort from table "MacYTDL"
	set theOKLabel to localized string "OK" in bundle file pathToBundleShort from table "MacYTDL"
	set theMonitorIntroTextLabel1 to localized string "Your download of" in bundle file pathToBundleShort from table "MacYTDL"
	set theMonitorIntroTextLabel2 to localized string "has started." in bundle file pathToBundleShort from table "MacYTDL"
	set theButtonsLogsLabel to localized string "Logs" in bundle file pathToBundleShort from table "MacYTDL"
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
	set diag_intro_text_1 to theMonitorIntroTextLabel1 & " \"" & download_filename_new_monitor_plain & "\" " & theMonitorIntroTextLabel2
	set accViewWidth to 100
	set accViewInset to 0
	set the_date_start to current date
	set the_time_start to time of the_date_start
	
	-- Set buttons
	if is_Livestream_Flag_monitor is "True" then
		set {theButtons, minWidth} to create buttons {theButtonsLogsLabel, theButtonsStopLabel} button keys {"l", "S"}
		set minWidth to 250
	else
		set {theButtons, minWidth} to create buttons {theButtonsLogsLabel, theButtonsStopLabel, theButtonsCloseLabel} button keys {"l", "S", ""} cancel button 3
	end if
	if minWidth > accViewWidth then set accViewWidth to minWidth -- make sure buttons fit
	
	-- It can take time for response file to get content - delay Monitor a bit
	delay 2
	
	-- Repeat loop to display monitor every 5 seconds, update with progress, redisplay - can close dialog, stop download or open logs folder - automatically closed by Adviser.scpt when download finished
	repeat
		-- Get YTDL response up to this point - if file is empty, Monitor will show "Progressing"
		set size_of_response to get eof YTDL_response_file_monitor_posix
		if size_of_response is less than 5 then
			set YTDL_response to "No response"
		else
			try
				set YTDL_response to read file YTDL_response_file_monitor_posix as text
			on error errMsg
				display dialog "Error in reading response file: " & YTDL_response_file_monitor_posix & return & "Error message: " & errMsg
			end try
		end if
		
		-- Get time running since start, convert into minutes
		set the_time to time of (current date)
		set seconds_running to the_time - the_time_start
		set time_running to seconds_running / minutes
		set round_factor to 0.1
		set time_running to (round time_running / round_factor) * round_factor
		
		--A default display when there are no progress details available in response file
		set progress_percentage to ""
		set diag_intro_text_2 to theProgressingLabel
		
		-- Use content of response to fashion text to appear in Monitor dialog
		if YTDL_response is not "No response" then
			set YTDL_response_lastParapraph to paragraph -2 of YTDL_response
			-- If progress meter available, get current percentage and file size - trim leading spaces from percentage - convert [MiB to MB]/[GiB to GB] in file size to match Finder
			if YTDL_response_lastParapraph contains "[download]" and YTDL_response_lastParapraph contains "%" and YTDL_response_lastParapraph contains "at" then
				set progress_percentage to last word in (text 1 thru (offset of "%" in YTDL_response_lastParapraph) of YTDL_response_lastParapraph)
				set o to (offset of "." in progress_percentage)
				if ((o > 0) and (0.0 as text is "0,0")) then set progress_percentage to (text 1 thru (o - 1) of progress_percentage & "," & text (o + 1) thru -1 of progress_percentage)
				-- YTDL Progress meter reports estimated size of download in GiB or MiB
				set GiBPositionAfterSize to offset of "GiB" in YTDL_response_lastParapraph -- Crude but does work
				if GiBPositionAfterSize is not 0 then
					set downloadFileSizeGiB to last word in (text 22 thru (GiBPositionAfterSize - 1) of YTDL_response_lastParapraph)
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
					set MiBPositionAfterSize to offset of "MiB" in YTDL_response_lastParapraph
					set downloadFileSizeMiB to last word in (text 22 thru (MiBPositionAfterSize - 1) of YTDL_response_lastParapraph)
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
			else if YTDL_response_lastParapraph contains "[Merger] Merging formats into" then
				set diag_intro_text_2 to "FFmpeg merging formats ...."
			else if YTDL_response_lastParapraph contains "[VideoConvertor] Converting video from" then
				set diag_intro_text_2 to "Converting download ...."
			else if YTDL_response_lastParapraph contains "[ThumbnailsConvertor] Converting thumbnail" then
				set diag_intro_text_2 to "Converting thumbnail ...."
			else if YTDL_response_lastParapraph contains "[EmbedThumbnail] mutagen:" then
				set diag_intro_text_2 to "Embedding thumbnail ...."
			else if YTDL_response_lastParapraph contains "[ExtractAudio] Destination:" then
				set diag_intro_text_2 to "Extracting audio ...."
			else if YTDL_response_lastParapraph contains "[ffmpeg] Fixing malformed" then
				set diag_intro_text_2 to "FFmpeg fixing bitstream ...."
			else if YTDL_response_lastParapraph contains "[ffmpeg] Merging formats into" then
				set diag_intro_text_2 to "FFmpeg merging formats ...."
			else if YTDL_response_lastParapraph contains "[FixupM3u8] Fixing" then
				set diag_intro_text_2 to "Fixing container ...."
			else if YTDL_response_lastParapraph contains "[info] Downloading video thumbnail" or YTDL_response_lastParapraph contains "[info] Writing video thumbnail" then
				set diag_intro_text_2 to "Writing thumbnail ...."
			else if YTDL_response_lastParapraph contains "[debug] Invoking downloader on" then
				set diag_intro_text_2 to "Starting download ...."
			else if YTDL_response_lastParapraph contains "[debug] ffmpeg command line" then
				set diag_intro_text_2 to (theRunningLabel & " FFmpeg ....")
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
				set diag_intro_text_2 to theProgressLabel & " " & sizeOfdownloadProgressDelimited & "KB" & " " & theDownloadInLabel & " " & time_running & " " & theMinutesLabel
			end if
		end if
		
		-- Set variables for Monitor dialog which need to be updated with each repeat		
		set {intro_label2, theTop} to create label diag_intro_text_2 left inset 0 bottom 5 max width minWidth aligns center aligned control size small size
		set {intro_label1, theTop} to create label diag_intro_text_1 left inset 50 bottom theTop + 10 max width minWidth - 51 control size small size
		set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix_monitor left inset 0 bottom theTop - 40 view width 45 view height 45 scale image scale proportionally
		
		-- Display the monitor dialog 
		set {monitor_button_returned} to display enhanced window monitor_diag_Title buttons theButtons giving up after 5 acc view width accViewWidth acc view height theTop acc view controls {intro_label2, intro_label1, MacYTDL_icon} initial position {X_position_monitor, Y_position_monitor}
		
		-- User clicked on the Stop download button - This kills the Python process and all child FFmpeg processes, then moves to Trash all ".part" files related to the download - Suppress the Adviser
		if monitor_button_returned is theButtonsStopLabel then
			-- Try to kill the processes but, ignore if process already gone - YTDL and yt-dlp have different process child-parent structures
			-- Kill the adviser as it's not needed except for live streams - force kill because during auto-dowloads it cannot be terminated normally
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
				if DL_Use_YTDLP is "yt-dlp" then
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
			-- WORK IN PROGRESS - PROBABLY SHOULD ONLY DELETE PARTIAL FILES IF USER WANTS IT DONE
			if download_finished is not "Yes" then
				-- Partly completed download process will leave behind "part" and/or "ytdl" files which should be moved to Trash
				-- Completed downloads should be left alone
				-- Handle multiple downloads separately as the name for the file spec comes from simulate.txt instead of the download_filename_new_monitor variable
				-- Need to trim off file extension in name search because YTDL sometimes has part files with part numbers between the name and the extension - works for 3 and 4 character extensions
				if download_filename_new_monitor_plain is "the multiple videos" or download_filename_new_monitor_plain is "the-playlist" then
					repeat with each_filename in (get paragraphs of YTDL_simulate_response_monitor)
						set each_filename to text 1 thru -5 of each_filename
						if each_filename does not contain "WARNING" then
							set part_files to do shell script "find " & downloadsFolder_Path_monitor_quoted & " -maxdepth 1 -type f -iname *" & quoted form of each_filename & "*.part* -or -iname *" & quoted form of each_filename & "*.ytdl*"
							repeat with each_part_files in (get paragraphs of part_files)
								do shell script "mv " & quoted form of each_part_files & " ~/.trash/"
							end repeat
						end if
					end repeat
					-- Handle ABC & SBS show pages separately as file names are not in simulate nor in download_filename_new_monitor but in download_filename_monitor
				else if YTDL_simulate_response_monitor contains "ERROR: Unsupported URL: https://iview" or YTDL_simulate_response_monitor contains "ERROR: Unsupported URL: https://www.sbs" then
					repeat with each_filename in (get paragraphs of download_filename_monitor)
						set each_filename to text 1 thru -1 of each_filename
						if each_filename does not contain "WARNING:" then
							set part_files to do shell script "find " & downloadsFolder_Path_monitor_quoted & " -maxdepth 1 -type f -iname *" & quoted form of each_filename & "*.part* -or -iname *" & quoted form of each_filename & "*.ytdl*"
							repeat with each_part_files in (get paragraphs of part_files)
								do shell script "mv " & quoted form of each_part_files & " ~/.trash/"
							end repeat
						end if
					end repeat
					-- All other kinds of download - Monitor currently cannot delete partly downloaded files left by batch download
				else if download_filename_new_monitor is not "the batch" and is_Livestream_Flag_monitor is "False" then
					-- Look for all files in DL folder that meet file spec
					set download_filename_monitor_trimmed to text 1 thru -5 of download_filename_monitor
					set part_files to do shell script "find " & downloadsFolder_Path_monitor_quoted & " -maxdepth 1 -type f -iname *" & quoted form of download_filename_monitor_trimmed & "*.part* -or -iname *" & quoted form of download_filename_monitor_trimmed & "*.ytdl*"
					repeat with each_part_files in (get paragraphs of part_files)
						do shell script "mv " & quoted form of each_part_files & " ~/.trash/"
					end repeat
				end if
			end if
			exit repeat
			-- Open log folder and continue to display Monitor
		else if monitor_button_returned is theButtonsLogsLabel then
			tell application "Finder"
				activate
				open (MacYTDL_preferences_path_monitor as POSIX file)
				set the position of the front Finder window to {100, 100}
			end tell
		end if
		-- Check whether the download has finished - if it has, the download process has gone and a "ps" command will bang an error
		try
			-- does the PID exist?
			do shell script "ps -p" & youtubedl_pid
		on error
			exit repeat
		end try
		
	end repeat
	
	
	
	
	--on error errMsg
	--	display dialog errMsg
	--end try
	
	
	
	
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