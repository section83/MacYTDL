---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  MacYTDL
--  A GUI for the Python Script yt-dlp.  Many thanks to Shane Stanley.
--  This is contains utilities for installing components etc.
--  Handlers in this script are called by main.scpt
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Include libraries
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use script "DialogToolkitMacYTDL"
use run_Utilities_handlers : script "Utilities"
use script "Utilities2"
property parent : AppleScript

global folder_chosen
-- global remux_format_choice -- 1.30, 25/11/25 - Remux runtime option removed from Main dialog
global subtitles_choice
global YTDL_credentials
global YTDL_subtitles
global YTDL_STEmbed
global YTDL_format
global YTDL_recode_remux
global YTDL_Remux_original
global YTDL_description
global YTDL_audio_only
global YTDL_audio_codec
global YTDL_over_writes
global YTDL_Thumbnail_Write
global YTDL_Thumbnail_Embed
global YTDL_metadata
global YTDL_limit_rate_value
global YTDL_verbose
global YTDL_TimeStamps
global YTDL_Use_Proxy
global YTDL_Use_Cookies
global YTDL_Custom_Settings
global YTDL_Custom_Template
global YTDL_no_part
global YTDL_QT_Compat
global YTDL_Resolution_Limit
global YTDL_Use_Parts
global YTDL_No_Warnings
global ADL_Clear_Batch
global DL_format
global DL_Remux_original
global DL_audio_codec
global DL_over_writes
global DL_Remux_format
global DL_subtitles_format
global DL_subtitles
global DL_STLanguage
global DL_STEmbed
global DL_YTAutoST
global DL_Thumbnail_Embed
global DL_Thumbnail_Write
global DL_verbose
global DL_Limit_Rate
global DL_Limit_Rate_Value
global DL_Show_Settings
global DL_Add_Metadata
global DL_Cookies_Location
global DL_Use_Cookies
global DL_Proxy_URL
global DL_Use_Proxy
global DL_Use_YTDLP
global DL_TimeStamps
global DL_Use_Custom_Template
global DL_Custom_Template
global DL_Use_Custom_Settings
global DL_Custom_Settings
global DL_Saved_Settings_Location
global DL_Settings_In_Use
global DL_QT_Compat
global DL_formats_list
global DL_discard_URL
global DL_Resolution_Limit
global DL_Dont_Use_Parts
global DL_Parallel
global DL_No_Warnings
global DL_Delete_Partial
global DL_Clear_Batch
global YTDL_version
global DL_auto
--global run_Utilities_handlers

---------------------------------------------------
--
-- 	Write current URL(s) to batch file
--
---------------------------------------------------
-- Handler to write the user's pasted URL to the batch file for later download - called from download_video() - returns to main_dialog()
-- Creates file if need, adds URL, file name and remux format and a return each time
on add_To_Batch(URL_user_entered, download_filename, download_filename_new, YTDL_remux_format, MacYTDL_preferences_path, diag_Title, theButtonOKLabel, MacYTDL_custom_icon_file)
	-- Remove any quotes from around URL_user_entered - so it can be written out to the batch file
	if character 1 of URL_user_entered is "'" then
		set URL_user_entered_lines to text 2 thru -2 of URL_user_entered
	else
		set URL_user_entered_lines to URL_user_entered
	end if
	-- Change spaces to returns when URL_user_entered has more than one URL - then add file name and remux format setting as comment - used by Adviser to play 1st file
	set URL_user_entered_lines to text 1 thru end of (my replace_chars(URL_user_entered_lines, " ", return))
	set count_of_URLs to count of paragraphs in URL_user_entered_lines
	-- Need to change file name extension if remux is required
	if YTDL_remux_format contains "--recode-video" then
		-- Get new extension - always follows the word recode -- v1.26 - Why do a loop when a simple "does it contain" would do ?
		set all_words to words in YTDL_remux_format
		repeat with i from 1 to the length of all_words
			if item i of all_words is "recode" then exit repeat
		end repeat
		set new_extension to item (i + 2) in all_words
		-- Get old extension - with multiple downloads and playlists, only need to find the first as the Adviser only plays the first file -- BUT ONLY HAS "THE MULTIPLE VIDEOS" IF MORE THAN ONE URL !
		if count_of_URLs is greater than 1 then
			set the_first_file_name to first paragraph of download_filename
		else
			set the_first_file_name to first paragraph of download_filename_new
		end if
		set AppleScript's text item delimiters to {"."}
		set old_extension to last text item of the_first_file_name
		set AppleScript's text item delimiters to {""}
		if old_extension is not equal to new_extension then
			if count_of_URLs is greater than 1 then
				-- v1.26 - add replace_chars for multiple URLs case - download_filename has multiple file names if more than one URL
				set download_filename to my replace_chars(download_filename, old_extension, new_extension)
			else
				set download_filename_new to my replace_chars(download_filename_new, old_extension, new_extension)
			end if
		end if
	end if
	set download_filename_new to my replace_chars(download_filename_new, "_", " ")
	if count_of_URLs is greater than 1 then
		set URL_user_entered_forming to ""
		repeat with i from 1 to count_of_URLs
			set URL_user_entered_forming to URL_user_entered_forming & paragraph i of URL_user_entered_lines & "#" & paragraph i of download_filename & "$" & YTDL_remux_format & return
		end repeat
	else
		set download_filename_new to text 1 thru -1 of download_filename_new
		set URL_user_entered_forming to URL_user_entered_lines & "#" & download_filename_new & "$" & YTDL_remux_format & return
	end if
	set batch_filename to "BatchFile.txt" as string
	set batch_file to POSIX file (MacYTDL_preferences_path & batch_filename) as «class furl»
	try
		set batch_refNum to missing value
		set batch_refNum to open for access batch_file with write permission
		write URL_user_entered_forming to batch_refNum starting at eof as «class utf8»
		close access batch_refNum
	on error batch_errMsg
		set theBatchErrorLabel to localized string "There was an error: " from table "MacYTDL"
		display dialog theBatchErrorLabel & batch_errMsg
		close access batch_refNum
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return "Main"
		--	main_dialog()
		-- ************************************************************************************************************************************************************
		
	end try
	--	set theAddedToBatchLabel to localized string "The URL has been added to batch file." from table "MacYTDL"
	set theAddedToBatchLabel to localized string "been added to batch file." from table "MacYTDL"
	if count_of_URLs is greater than 1 then
		set count_text to " URLs have "
	else
		set count_text to " URL has "
	end if
	set URL_count_report to ((count_of_URLs as string) & count_text)
	display dialog (URL_count_report & theAddedToBatchLabel) with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
	-- After adding to batch, reset ABC & SBS show name and number_ABC_SBS_episodes so that correct file name is used for next download
	-- v1.26 - Decided to change behaviour - retain/discard URL after adding to batch - it's the user's choice
	if DL_discard_URL is true then
		set URL_user_entered to ""
		set URL_user_entered_clean to ""
	end if
	set ABC_show_name to ""
	set SBS_show_name to ""
	set SBS_show_URLs to ""
	set ABC_show_URLs to ""
	set number_ABC_SBS_episodes to 0
	-- set the clipboard to ""
	
	-- ************************************************************************************************************************************************************
	-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
	return "Main"
	--	main_dialog()
	-- ************************************************************************************************************************************************************
	
end add_To_Batch


---------------------------------------------------------
--
-- 	Open batch processing dialog - called by Main
--
---------------------------------------------------------
-- Handler to open batch file processing dialog - called by Main dialog
on open_batch_processing(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, theButtonOKLabel, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file_posix, diag_Title, window_Position, MacYTDL_custom_icon_file, screen_width, screen_height, YTDL_Use_netrc, deno_version, YTDL_version)
	
	
	
	
	
	--	display dialog "Started open_batch_processing()"
	
	
	
	
	
	
	-- Load utilities.scpt so that various handlers can be called -- v1.30, 16/11/25 - Now using script libraries
	set MacYTDL_preferences_folder to "Library/Preferences/MacYTDL/"
	set MacYTDL_preferences_path to (POSIX path of (path to home folder) & MacYTDL_preferences_folder)
	set MacYTDL_prefs_file to MacYTDL_preferences_path & "MacYTDL.plist"
	set path_to_MacYTDL to path to me as text
	-- set path_to_Utilities to (path_to_MacYTDL & "Contents:Resources:Scripts:Utilities.scpt") as alias
	--	set run_Utilities_handlers to load script path_to_Utilities
	
	run_Utilities_handlers's read_settings(MacYTDL_prefs_file)
	set DL_format to localized string DL_format from table "MacYTDL"
	set DL_subtitles_format to localized string DL_subtitles_format from table "MacYTDL"
	set DL_Remux_format to localized string DL_Remux_format from table "MacYTDL"
	set DL_audio_codec to localized string DL_audio_codec from table "MacYTDL"
	
	-- ************************************************************************************************************************************************************
	-- 1.92.2 - tally_batch() moved to utilities.scpt - v1.30, 16/11/25 - Moved back into batch.scptd
	-- Start by calculating tally of URLs currently saved in the batch file		
	set batch_tally_number to my tally_batch(batch_file, theButtonOKLabel)
	
	
	
	
	--	display dialog "Returned from tally_batch()"
	
	
	
	
	
	
	if batch_tally_number is "Main" then return "Main"
	-- ************************************************************************************************************************************************************
	
	-- Set variables for the Batch functions dialog
	set theBatchFunctionsInstructionLabel to localized string "Choose to download list of URLs in batch file, clear the batch list, edit the batch list, remove last addition to the batch or return to Main dialog." from table "MacYTDL"
	set theBatchFunctionsDiagPromptLabel to localized string "Batch Functions" from table "MacYTDL"
	set instructions_text to theBatchFunctionsInstructionLabel
	set batch_diag_prompt to theBatchFunctionsDiagPromptLabel
	set accViewWidth to 200
	set accViewInset to 0
	
	-- Set buttons and controls
	set theButtonsEditLabel to localized string "Edit" from table "MacYTDL"
	set theButtonsClearLabel to localized string "Clear" from table "MacYTDL"
	set theButtonsRemoveLabel to localized string "Remove last item" from table "MacYTDL"
	set {theButtons, minWidth} to create buttons {theButtonReturnLabel, theButtonsEditLabel, theButtonsClearLabel, theButtonsRemoveLabel, theButtonDownloadLabel} button keys {"r", "e", "c", "U", "d"} default button 5
	if minWidth > accViewWidth then set accViewWidth to (minWidth + 25)
	set {theBatchRule, theTop} to create rule 10 rule width accViewWidth
	set theNumberVideosLabel to localized string "Number of videos in batch: " from table "MacYTDL"
	set {batch_tally, theTop} to create label theNumberVideosLabel & batch_tally_number left inset 25 bottom (theTop + 15) max width 225 aligns left aligned
	set {batch_instruct, theTop} to create label instructions_text left inset 75 bottom (theTop + 30) max width accViewWidth - 75 aligns left aligned with multiline
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 60 view width 64 view height 64 scale image scale proportionally
	set {batch_prompt, theTop} to create label batch_diag_prompt left inset 0 bottom (theTop) max width accViewWidth aligns center aligned with bold type
	set batch_allControls to {theBatchRule, batch_tally, MacYTDL_icon, batch_instruct, batch_prompt}
	
	-- Make sure MacYTDL is in front and show dialog
	tell me to activate
	set {batch_button_returned, batchButtonNumberReturned, batch_controls_results} to display enhanced window diag_Title buttons theButtons acc view width accViewWidth acc view height theTop acc view controls batch_allControls initial position window_Position
	
	if batchButtonNumberReturned is 5 then
		-- v1.30, 19/12/25 - Moved from beginning of download_batch() - Check that there is a batch file containing some URLs - Will design a better way of avoiding nesting in v1.31
		set batch_file_empty to false
		set no_batch_file to false
		set batch_file_test to batch_file as string
		tell application "System Events"
			if not (exists file batch_file_test) then set no_batch_file to true
		end tell
		if no_batch_file is true then
			set theNoBatchFileLabel to localized string "Sorry, there is no batch file." from table "MacYTDL"
			display dialog theNoBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			-- v1.30, 19/12/25 - There are no functions which can be performed as there is no batch file so, return directly to Main dialog			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
			return "Main"
			--	my main_dialog()
			-- ************************************************************************************************************************************************************
			
			-- my open_batch_processing(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, theButtonOKLabel, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file_posix, "Returning from warning dialog", window_Position, MacYTDL_custom_icon_file, screen_width, screen_height, YTDL_Use_netrc, Deno_Version, YTDL_version)
			--my open_batch_processing(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, theButtonOKLabel, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file_posix, diag_Title, window_Position, MacYTDL_custom_icon_file, screen_width, screen_height, YTDL_Use_netrc, Deno_Version, YTDL_version)
		end if
		if (get eof file batch_file) is 0 then
			set batch_file_empty to true
			
			
			
			--			display dialog "Found batch file is empty"
			
			
			
			
			
			
			set theEmptyBatchFileLabel to localized string "Sorry, the batch file is empty." from table "MacYTDL"
			display dialog theEmptyBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			my open_batch_processing(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, theButtonOKLabel, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file_posix, "Returning from warning dialog", window_Position, MacYTDL_custom_icon_file, screen_width, screen_height, YTDL_Use_netrc, deno_version, YTDL_version)
			-- my open_batch_processing(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, theButtonOKLabel, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file_posix, diag_Title, window_Position, MacYTDL_custom_icon_file, screen_width, screen_height, YTDL_Use_netrc, Deno_Version, YTDL_version)
		end if
		
		if batch_file_empty is false then my download_batch(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, diag_Title, MacYTDL_preferences_path, theButtonOKLabel, MacYTDL_custom_icon_file, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file_posix, window_Position, screen_width, screen_height, path_to_MacYTDL, YTDL_Use_netrc, deno_version, YTDL_version)
	else if batchButtonNumberReturned is 2 then
		-- Check that there is a batch file
		tell application "System Events"
			set batch_file_test to batch_file as string
			if not (exists file batch_file_test) then
				set theNoBatchFileLabel to localized string "Sorry, there is no batch file." from table "MacYTDL"
				display dialog theNoBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
				
				-- ************************************************************************************************************************************************************
				-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
				return "Main"
				--	my main_dialog()
				-- ************************************************************************************************************************************************************
				
			end if
		end tell
		set batch_file_posix to POSIX path of batch_file
		tell application "System Events" to open file batch_file_posix
		open_batch_processing(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, theButtonOKLabel, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file_posix, diag_Title, window_Position, MacYTDL_custom_icon_file, screen_width, screen_height, YTDL_Use_netrc, deno_version, YTDL_version)
	else if (batchButtonNumberReturned is 3) or ((batchButtonNumberReturned is 4) and (batch_tally_number is 1)) then
		set branch_execution to clear_batch(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, diag_Title, theButtonOKLabel, MacYTDL_custom_icon_file, screen_width, screen_height, YTDL_Use_netrc, deno_version, YTDL_version)
		if branch_execution is "Open" then open_batch_processing(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, theButtonOKLabel, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file_posix, diag_Title, window_Position, MacYTDL_custom_icon_file, screen_width, screen_height, YTDL_Use_netrc, deno_version, YTDL_version)
	else if batchButtonNumberReturned is 4 then
		remove_last_from_batch(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, theButtonOKLabel, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file_posix, diag_Title, window_Position, MacYTDL_custom_icon_file, screen_width, screen_height, YTDL_Use_netrc, deno_version, YTDL_version)
	end if
	
	-- ************************************************************************************************************************************************************
	-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
	-- User clicked on the "Return" button
	
	
	
	
	--	display dialog "Clicked Return button"
	
	
	
	
	
	
	return "Main"
	--	main_dialog()
	-- ************************************************************************************************************************************************************	
	
end open_batch_processing


-------------------------------------------------------------
--
-- 	Clear batch file - called by open_batch_processing
--
-------------------------------------------------------------
-- Handler to clear all URLs from batch file - empties the file but does not delete it
on clear_batch(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, diag_Title, theButtonOKLabel, MacYTDL_custom_icon_file, screen_width, screen_height, YTDL_Use_netrc, deno_version, YTDL_version)
	-- Check that there is a batch file
	tell application "System Events"
		set batch_file_test to batch_file as string
		if not (exists file batch_file_test) then
			set theNoBatchFileLabel to localized string "Sorry, there is no batch file." from table "MacYTDL"
			display dialog theNoBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			return "Main"
		end if
	end tell
	if (get eof file batch_file) is 0 then
		set theEmptyBatchFileLabel to localized string "Sorry, the batch file is empty." from table "MacYTDL"
		display dialog theEmptyBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		return "Open"
	end if
	try
		set batch_file_ref to missing value
		set batch_file_ref to open for access file batch_file with write permission
		set eof batch_file_ref to 0
		close access batch_file_ref
	on error batch_errMsg
		set theBatchErrorLabel to localized string "There was an error: " from table "MacYTDL"
		display dialog theBatchErrorLabel & batch_errMsg & "batch_file: " & batch_file buttons {theButtonOKLabel} default button 1
		try
			close access batch_file_ref
		on error
			return "Open"
		end try
		return
	end try
	return "Open"
end clear_batch


---------------------------------------------------
--
-- 	Calculate tally of URLs saved in batch file
--
---------------------------------------------------
-- Handler to calculate tally of URLs saved in Batch file - called by Batch dialog and maybe Main too
on tally_batch(batch_file, theButtonOKLabel)
	
	
	
	
	--	display dialog "Started tally_batch()"
	
	
	
	
	
	
	tell application "System Events"
		set batch_file_test to batch_file as string
		if not (exists file batch_file_test) then
			set number_of_URLs to 0
			return number_of_URLs
		end if
	end tell
	if (get eof file batch_file) is 0 then
		set number_of_URLs to 0
		
		
		
		
		--		display dialog "Found end of file, returning to open_batch_processing()"
		
		
		
		
		
		
		return number_of_URLs
	end if
	try
		set batch_file_ref to missing value
		set batch_file_ref to open for access file batch_file
		set batch_URLs to read batch_file_ref from 1 as «class utf8»
		set number_of_URLs to (count of paragraphs in batch_URLs) - 1
		close access batch_file_ref
	on error batch_errMsg
		set theBatchErrorLabel to localized string "There was an error: " from table "MacYTDL"
		display dialog theBatchErrorLabel & batch_errMsg & "batch_file: " & batch_file with title "Tally_batch handler" buttons {theButtonOKLabel} default button 1
		close access batch_file_ref
		
		-- ***************************************************************************************************************************************
		-- v1.29.2 - 12/5/25 - First version of repeat loop to control flow
		return "Main"
		-- main_dialog()
		-- ***************************************************************************************************************************************
		
	end try
	return number_of_URLs
end tally_batch


--------------------------------------------------------------------------
--
-- 	Remove last batch addition - called by open_batch_processing
--
--------------------------------------------------------------------------
-- Handler to remove the most recent addition to batch file
on remove_last_from_batch(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, theButtonOKLabel, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file_posix, diag_Title, window_Position, MacYTDL_custom_icon_file, screen_width, screen_height, YTDL_Use_netrc, deno_version, YTDL_version)
	-- Check that there is a batch file
	tell application "System Events"
		set batch_file_test to batch_file as string
		if not (exists file batch_file_test) then
			set theNoBatchFileLabel to localized string "Sorry, there is no batch file." from table "MacYTDL"
			display dialog theNoBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			return
		end if
	end tell
	if (get eof file batch_file) is 0 then
		set theEmptyBatchFileLabel to localized string "Sorry, the batch file is empty." from table "MacYTDL"
		display dialog theEmptyBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		return
		--		open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
	end if
	try
		set batch_file_ref to missing value
		set batch_file_ref to open for access file batch_file with write permission
		set batch_URLs to read batch_file_ref from 1 as «class utf8»
		set batch_URLs to text 1 thru -4 of batch_URLs --<= remove last few characters to remove last return
		set last_URL_offset to last item of run_Utilities_handlers's allOffset(batch_URLs, return) --<= Get last in list of offsets of returns
		set new_batch_contents to text 1 thru (last_URL_offset - 1) of batch_URLs --<= Trim off last URL
		set eof batch_file_ref to 0 --<= Empty the batch file
		write new_batch_contents & return to batch_file_ref as «class utf8» --<= Write out all URLs except the last
		close access batch_file_ref
	on error batch_errMsg number errorNumber
		set theBatchErrorLabel to localized string "There was an error: number " from table "MacYTDL"
		display dialog theBatchErrorLabel & errorNumber & " - " & batch_errMsg & "  batch_file: " & batch_file buttons {theButtonOKLabel} default button 1
		close access batch_file_ref
		return
	end try
	return
	--	open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
end remove_last_from_batch


-----------------------------------------------------------------------------
--
-- 	Download videos in Batch file - called by open_batch_processing
--
-----------------------------------------------------------------------------
-- Handler to download selection of URLs in Batch file - forms and calls youtube-dl/yt-dlp separately from the download_video handler
on download_batch(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, diag_Title, MacYTDL_preferences_path, theButtonOKLabel, MacYTDL_custom_icon_file, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file_posix, window_Position, screen_width, screen_height, path_to_MacYTDL, YTDL_Use_netrc, deno_version, YTDL_version)
	
	-- Eventually, will have code here which will read the batch file and present user with list to choose from
	
	-- v1.30, 19/12/25 - These two checks moved to open_batch_processing()
	-- Check that there is a batch file containing some URLs
	--	set no_batch_file to false
	--	set batch_file_test to batch_file as string
	--	tell application "System Events"
	--		if not (exists file batch_file_test) then set no_batch_file to true
	--	end tell
	--	if no_batch_file is true then
	--		set theNoBatchFileLabel to localized string "Sorry, there is no batch file." from table "MacYTDL"
	--		display dialog theNoBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
	--		my open_batch_processing(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, theButtonOKLabel, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file_posix, diag_Title, window_Position, MacYTDL_custom_icon_file, screen_width, screen_height, YTDL_Use_netrc, Deno_Version, YTDL_version)
	--	end if
	--	if (get eof file batch_file) is 0 then
	--		set theEmptyBatchFileLabel to localized string "Sorry, the batch file is empty." from table "MacYTDL"
	--		display dialog theEmptyBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
	--		my open_batch_processing(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, theButtonOKLabel, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file_posix, diag_Title, window_Position, MacYTDL_custom_icon_file, screen_width, screen_height, YTDL_Use_netrc, Deno_Version, YTDL_version)
	--	end if
	
	-- Get date and time so it can be added to log file name
	set download_date_time to run_Utilities_handlers's get_Date_Time()
	
	
	
	
	
	--	display dialog "Just got download_date_time"
	
	
	
	
	
	
	-- Always set is_Livestream_Flag to false for batch downloads
	set is_Livestream_Flag to "False"
	
	-- Set name to be used for log file and monitor dialog - name is in comment section of each URL line
	set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-Batch_download_on-" & download_date_time & ".txt"
	set batch_file_ref to missing value
	set batch_file_ref to open for access file batch_file
	set batch_file_contents to read batch_file_ref as «class utf8»
	
	-- Look for manual edits of the batch file that made a muck of it
	set bad_Batch_file_edits to "No"
	set AppleScript's text item delimiters to {"#", "$", return}
	repeat with aPara in (paragraphs of batch_file_contents)
		if length of aPara is greater than 2 then
			if aPara does not contain "#" then
				set bad_Batch_file_edits to "Yes"
			else
				set num_sections to number of text items in aPara
				if num_sections is not equal to 3 then
					set bad_Batch_file_edits to "Yes"
				end if
			end if
		end if
		if bad_Batch_file_edits is "Yes" then
			set theBadBatchFileEditsLabel to localized string "Sorry, it seems the batch file has been edited with the wrong format. Check the Help manual for advice on how to edit the batch file." from table "MacYTDL"
			display dialog theBadBatchFileEditsLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			close access batch_file_ref
			return "Main"
		end if
	end repeat
	
	-- Get first file name to pass to Adviser - trim off the trailing return character - also get remux setting if included - 1st occurrence is used for download entire batch
	-- v1.27 - found that this file name is incorrect - comes from Add_to_Batch()
	set download_filename to text item 2 of batch_file_contents
	set YTDL_remux_format to text item 3 of batch_file_contents
	set download_filename to text 1 thru -1 of download_filename -- Probably not needed but, is a safety measure
	if length of YTDL_remux_format is greater than 5 then
		--		set YTDL_remux_format to text 1 thru -2 of YTDL_remux_format			-- v1.27 - 17/6/24 - a bug - been there for yonks
		set YTDL_remux_format to text 1 thru -1 of YTDL_remux_format
	else
		set YTDL_remux_format to ""
	end if
	set AppleScript's text item delimiters to ""
	close access batch_file_ref
	
	-- v1.30, 19/11/25 - If URL points to YouTube, check that Deno is installed - if not, and user on yt-dlp 2025.10.22+ offer to install
	if (batch_file_contents contains "youtube" or batch_file_contents contains "youtu.be") and deno_version is "Not installed" then
		considering numeric strings
			if YTDL_version is greater than "2025.10.22" then
				set theButtonInstall to localized string "Install Deno"
				set install_deno_query to button returned of (display dialog (localized string "You need Deno installed to be sure of downloading from YouTube. Do you wish Deno to be installed, return to Main dialog or try without Deno ?") buttons {theButtonReturnLabel, theButtonContinueLabel, theButtonInstall} with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
				if install_deno_query is theButtonInstall then
					set deno_version to script "Utilities2"'s install_update_Deno(deno_version, user_system_arch, resourcesPath, path_to_MacYTDL, theButtonOKLabel, MacYTDL_custom_icon_file, diag_Title)
				else if install_deno_query is theButtonReturnLabel then
					return "Main"
				else
					-- Continue and try downloading anyway
				end if
			end if
		end considering
	end if
	
	
	-- v1.25.1 - added rough logic to get subtitles - previously never passed subtitles settings to the download
	-- If user wants for subtitles, pass current settings to download without checking - it is checked during add_To_batch() <= true but add_to_batch() doesn't add --convert subs
	-- v1.28 -- this was too crude as it ignored need to convert subtitles
	--	if subtitles_choice is true and DL_YTAutoST is false then
	--		set YTDL_subtitles to "--write-sub --sub-format " & DL_subtitles_format & " --sub-lang " & DL_STLanguage & " "
	--	end if
	--	if DL_YTAutoST is true and subtitles_choice is false then
	--		set YTDL_subtitles to "--write-auto-sub --sub-format " & DL_subtitles_format & " --sub-lang " & DL_STLanguage & " "
	--	end if
	--	if DL_YTAutoST is true and subtitles_choice is true then
	--		set YTDL_subtitles to "--write-auto-sub --write-sub --sub-format " & DL_subtitles_format & " --sub-lang " & DL_STLanguage & " "
	--	end if
	
	-- v1.28 - Following 2 lines moved above call to 	check_subtitles_download_available() so as to define YTDL_batch_file
	set YTDL_batch_file to quoted form of POSIX path of batch_file
	set YTDL_no_playlist to ""
	
	-- If user asked for subtitles, get ytdl/yt-dlp to check whether they are available - if not, warn user - if available, check against format requested - convert if different
	-- v1.21.2, added URL_user_entered to variables specifically passed - fixes SBS OnDemand subtitles error - don't know why
	-- v1.28 -- copied this if block from download_video()
	if subtitles_choice is true or DL_YTAutoST is true then
		set URL_user_entered to ("--batch-file " & YTDL_batch_file)
		set YTDL_subtitles to run_Utilities_handlers's check_subtitles_download_available(shellPath, diag_Title, subtitles_choice, URL_user_entered, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, MacYTDL_custom_icon_file, DL_Use_YTDLP, theBestLabel)
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
		if YTDL_subtitles is "Main" then return "Main"
		-- ************************************************************************************************************************************************************		
		
	end if
	-- Set up download_filename_new to hold data required for parallel download - need to get URL, file name and log file pathname - it's delimited, not a list - repeat through content of batchfile.txt
	-- v1.27 - don't bother with parallel downloads if just one entry in BatchFile.txt
	set number_paragraphs to ((count of paragraphs of batch_file_contents) - 1) -- Always has a blank last paragraph
	--	if DL_Parallel is true and number_paragraphs is greater than 2 then -- v1.28 - <= This ignored case when batch had just 2 videos
	if DL_Parallel is true and number_paragraphs is greater than 1 then
		set download_filename_new to ""
		repeat with x from 1 to number_paragraphs
			set AppleScript's text item delimiters to {"#", "$"}
			set download_batch_details to (paragraph x of batch_file_contents)
			set URL_user_entered_for_parallel to text item 1 of download_batch_details
			set download_filename_full to text item 2 of download_batch_details
			-- Trying to remove colons and spaces from file names as it might cause macOS trouble - the strange small colon DOES cause issues
			set download_filename_full to my replace_chars(download_filename_full, " ", "_")
			--	set download_filename_full to run_Utilities_handlers's replace_chars(download_filename_full, ":", "_-") -- Not sure whether this would make a mess of URLs
			set download_filename_full to my replace_chars(download_filename_full, "：", "_-")
			-- Need to trim off ".[extension]" from file name before adding to name of log file
			set download_filename_trimmed to text 1 thru ((download_filename_full's length) - (offset of "." in (the reverse of every character of download_filename_full) as text)) of download_filename_full
			set YTDL_batch_item_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_trimmed & "-" & download_date_time & ".txt"
			set download_filename_new to download_filename_new & download_filename_full & "##" & URL_user_entered_for_parallel & "##" & YTDL_batch_item_log_file & return
			set AppleScript's text item delimiters to ""
		end repeat
		set download_batch_parallel_serial to ""
	else
		set download_filename_new to "the saved batch"
		set download_batch_parallel_serial to ("--batch-file " & YTDL_batch_file)
	end if
	
	-- Change underscores to spaces in download_filname + put diag title, file and path names into quotes as they are not passed correctly when they contain apostrophes or spaces
	set diag_Title_quoted to quoted form of diag_Title
	set download_filename to my replace_chars(download_filename, "_", " ")
	set download_filename to quoted form of download_filename
	set download_filename_new to quoted form of download_filename_new
	set YTDL_log_file to quoted form of YTDL_log_file
	set YTDL_TimeStamps_quoted to quoted form of YTDL_TimeStamps
	
	-- Set remaining variables needed by Monitor.scpt
	set YTDL_simulate_log to "Null"
	set URL_user_entered to "Null" -- URL is read from the file by yt-dlp
	if YTDL_Custom_Template is not "" then
		set YTDL_output_template to " -o '" & YTDL_Custom_Template & "'"
	else
		if URL_user_entered contains "ABC" then
			set YTDL_output_template to " -o '%(series)s-%(title)s.%(ext)s'"
		else
			set YTDL_output_template to " -o '%(title)s.%(ext)s'"
		end if
	end if
	
	-- Increment the monitor dialog position number - used by monitor.scpt for positioning monitor dialogs	
	try -- In a try block to catch error of nil pids returned
		set monitor_dialogs_list to do shell script "pgrep -f osascript"
		set monitor_dialog_position to ((count of paragraphs in monitor_dialogs_list) / 2) + 1
	on error
		set monitor_dialog_position to 1
	end try
	
	-- Form up parameters to send to monitor.scpt - collect YTDL settings then merge with MacYTDL variables
	-- v1.26 - Copy ytdl_settings from download_video()
	--	set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_remux_format & " " & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_Thumbnail_Write & YTDL_Thumbnail_Embed & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & download_batch_parallel_serial)
	
	set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_Thumbnail_Write & YTDL_Thumbnail_Embed & YTDL_metadata & YTDL_limit_rate_value & " " & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & " " & download_batch_parallel_serial & " " & YTDL_Use_netrc & " ")
	
	set my_params to quoted form of folder_chosen & " " & quoted form of MacYTDL_preferences_path & " " & YTDL_TimeStamps_quoted & " " & ytdl_settings & " " & URL_user_entered & " " & YTDL_log_file & " " & download_filename & " " & download_filename_new & " " & quoted form of MacYTDL_custom_icon_file_posix & " " & monitor_dialog_position & " " & YTDL_simulate_log & " " & diag_Title_quoted & " " & is_Livestream_Flag & " " & screen_width & " " & screen_height & " " & DL_Use_YTDLP & " " & quoted form of path_to_MacYTDL & " " & DL_Delete_Partial & " " & ADL_Clear_Batch
	
	---- Show current download settings if user has specified that in Settings
	if DL_Show_Settings is true then
		set branch_execution to run_Utilities_handlers's show_settings(YTDL_subtitles, DL_Remux_original, DL_YTDL_auto_check, DL_STEmbed, DL_audio_only, YTDL_description, DL_Limit_Rate, DL_over_writes, DL_Thumbnail_Write, DL_verbose, DL_Thumbnail_Embed, DL_Add_Metadata, DL_Use_Proxy, DL_Use_Cookies, DL_Use_Custom_Template, DL_Use_Custom_Settings, DL_Remux_format, DL_TimeStamps, DL_Use_YTDLP, DL_Parallel, DL_discard_URL, DL_Dont_Use_Parts, DL_No_Warnings, YTDL_version, folder_chosen, theButtonQuitLabel, theButtonCancelLabel, theButtonDownloadLabel, DL_Show_Settings, MacYTDL_prefs_file, MacYTDL_custom_icon_file_posix, diag_Title, YTDL_Use_netrc, DL_Remux_Recode)
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
		if branch_execution is "Main" then return branch_execution
		-- ************************************************************************************************************************************************************		
		
		-- This bit doesn't make sense - "Settings" is not used at all - Decided to comment out for now
		--		if branch_execution is "Settings" then
		--			return "Settings"
		--		else
		return "Main"
		--		end if
		
		
		
		
		-- display dialog "netrc setting is " & YTDL_Use_netrc
		
		
		
		
	end if
	
	-- Prepare to call on the download Monitor - first get Monitor script location -- Monitor-bundle.scptd
	set myMonitorScriptAsString to quoted form of ((POSIX path of path_to_MacYTDL) & "Contents/Resources/Script Libraries/Monitor.scptd")
	
	-- PRODUCTION CALL - Call the download Monitor script which will run as a separate process and return so Main Dialog can be re-displayed - thus user can start any number of downloads
	do shell script "osascript -s s " & myMonitorScriptAsString & " " & my_params & " " & " > /dev/null 2> /dev/null &"
	
	-- TESTING CALL - Call the download Monitor script for testing - this formulation gets any errors back from Monitor, but holds execution until Monitor dialog is dismissed
	--do shell script "osascript -s s " & myMonitorScriptAsString & " " & my_params
	
	-- ************************************************************************************************************************************************************
	-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
	return "Main"
	--	main_dialog()
	-- ************************************************************************************************************************************************************	
	
end download_batch


---------------------------------------------------
--
-- 			Find and Replace
--
---------------------------------------------------

-- Handler to find-replace text inside a string
on replace_chars(this_text, search_string, replacement_string)
	set AppleScript's text item delimiters to the search_string
	set the item_list to every text item of this_text
	set AppleScript's text item delimiters to the replacement_string
	set this_text to the item_list as text
	set AppleScript's text item delimiters to ""
	return this_text
end replace_chars
