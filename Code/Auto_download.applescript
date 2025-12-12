
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  MacYTDL
--  A GUI for the Python Script yt-dlp.  Many thanks to Shane Stanley.
--  This is contains handlers for the auto-download function of the MacYTDL Service
--  This script is loaded by the MacYTDL Service
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
property parent : AppleScript
-- use script "DialogToolkitMacYTDL" -- Yosemite (10.10) or later - 1.30, 5/12/25 - Currently not working - probably because of missing symlinks


-- Define variables to be filled by the read_settings() handler below - makes these variables available to main.scpt
global downloadsFolder_Path
global resourcesPath
global DL_Add_Metadata
global DL_Cookies_Location
global DL_audio_only
global DL_audio_codec
global DL_Clear_Batch
global DL_description
global DL_format
global DL_Limit_Rate
global DL_Limit_Rate_Value
global DL_over_writes
global DL_Remux_Recode
global DL_Remux_format
global DL_Remux_original
global DL_subtitles_format
global DL_subtitles
global DL_STLanguage
global DL_STEmbed
global DL_Thumbnail_Embed
global DL_Thumbnail_Write
global DL_verbose
global DL_Show_Settings
global DL_Use_Cookies
global DL_Proxy_URL
global DL_Use_Proxy
global DL_Use_netrc
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
global DL_YTDL_auto_check
global DL_YTAutoST
global YTDL_version
global DL_auto
global window_Position
--global myNum
global SBS_show_URLs
global SBS_show_name
global ABC_show_URLs
global ABC_show_name
-- global file_formats_selected
--global add_to_output_template
--global ffmpeg_version
--global ffprobe_version
global deno_version
global MacYTDL_preferences_path
global download_filename_new
global playlist_Name
global download_filename
global YTDL_log_file


-- On run handler in case I need to use it in the auto-download process
-- handler_to_run would be passed from the Service
--on run {handler_to_run}
--	display dialog "This should not appear !!"
--end run


---------------------------------------------------
--
--			Auto-download
--
---------------------------------------------------

-- Handler called by Service to do the auto download
on auto_Download(MacYTDL_prefs_file, URL_user_entered_clean, path_to_MacYTDL)
	
	
	--	try
	
	-- v1.29.2 - 10/5/25 - Copied localization method from Monitor.scpt - tested on Mac Mini - Works
	set pathToBundleShort to (path_to_MacYTDL & ":") as text
	
	my read_settings(MacYTDL_prefs_file)
	
	-- Added deno_version in v1.30, 2/11/25 - less complicated way of getting deno_version
	-- 29/11/25 - Copied code from Preliminaries in order to properly set deno_version
	set deno_file to ("usr:local:bin:deno" as text)
	tell application "System Events"
		if exists file deno_file then
			--			try
			set deno_version to do shell script "usr/local/bin/deno --version"
			set deno_version to word 2 of deno_version
			--			end try
		else
			set deno_version to "Not installed"
		end if
	end tell
	--set deno_version to word 2 of (do shell script "/usr/local/bin/deno --version")
	
	set DL_format to localized string DL_format in bundle file pathToBundleShort from table "MacYTDL"
	set DL_subtitles_format to localized string DL_subtitles_format in bundle file pathToBundleShort from table "MacYTDL"
	set DL_Remux_format to localized string DL_Remux_format in bundle file pathToBundleShort from table "MacYTDL"
	--	set theNoRemuxLabel to localized string "No remux" in bundle file pathToBundleShort from table "MacYTDL" -- 1.29.2 - 8/5/25 - added for consistency with other localisations -- v1.30, 24/11/25 - Changed to theRecode_RemuxLabel
	-- set theRecode_RemuxLabel to localized string "N/R" in bundle file pathToBundleShort from table "MacYTDL" - v1.30, 25/11/25 - Seems this label isn't used anywhere
	set theBestLabel to localized string "Best" in bundle file pathToBundleShort from table "MacYTDL"
	set theDefaultLabel to localized string "Default" in bundle file pathToBundleShort from table "MacYTDL" -- 1.29.2 - 8/5/25 - added for consistency with other localisations
	set DL_audio_codec to localized string DL_audio_codec in bundle file pathToBundleShort from table "MacYTDL"
	--	set DL_format to localized string DL_format from table "MacYTDL"
	--	set DL_subtitles_format to localized string DL_subtitles_format from table "MacYTDL"
	--	set theBestLabel to localized string "Best" from table "MacYTDL"
	--	set DL_audio_codec to localized string DL_audio_codec from table "MacYTDL"
	
	-- Lock out Show Settings function - auto_download should be quick and not interrupted by dialogs
	set DL_Show_Settings to false
	
	
	-- v1.30, 29/11/25 - No longer need to load main.scpt as all required handlers are inside this script bundle
	-- *****************************************************************************
	-- These preliminary bits might end up in a separate handler which is also called by Main - to reduce duplication
	-- *****************************************************************************	
	--	set path_to_Main to (path_to_MacYTDL & ":Contents:Resources:Scripts:Main.scpt") as alias	
	-- *****************************************************************************
	-- Just loading main.scpt until a better way is settled - probably an osascript call into background
	--	set run_Main_handlers to load script path_to_Main
	-- *****************************************************************************	
	
	set resourcesPath to POSIX path of (path_to_MacYTDL & ":Contents:Resources:")
	set shellPath to "PATH=$PATH:/bin:/sbin:/usr/bin:/usr/local/bin:/usr/sbin:~/opt/bin:~/opt/sbin:/opt/local/bin:/opt/local/sbin:" & quoted form of (POSIX path of (path_to_MacYTDL & "::")) & "; "
	set MacYTDL_preferences_folder to "Library/Preferences/MacYTDL/"
	set MacYTDL_preferences_path to (POSIX path of (path to home folder) & MacYTDL_preferences_folder)
	set YTDL_simulate_file to MacYTDL_preferences_path & "ytdl_simulate.txt"
	-- set monitor_dialog_position to 0
	set bundle_file to (path_to_MacYTDL & ":contents:Info.plist") as string
	tell application "System Events"
		set MacYTDL_copyright to value of property list item "NSHumanReadableCopyright" of contents of property list file bundle_file
		set MacYTDL_version to value of property list item "CFBundleShortVersionString" of contents of property list file bundle_file
	end tell
	set MacYTDL_date_position to (offset of "," in MacYTDL_copyright) + 2
	set MacYTDL_date to text MacYTDL_date_position thru end of MacYTDL_copyright
	set MacYTDL_date_day to word 1 of MacYTDL_date
	set MacYTDL_date_month to word 2 of MacYTDL_date
	set MacYTDL_date_year to word 3 of MacYTDL_date
	set thedateLabel to localized string MacYTDL_date_month from table "MacYTDL"
	set MacYTDL_date to MacYTDL_date_day & " " & thedateLabel & " " & MacYTDL_date_year
	set theVersionLabel to localized string "Version" from table "MacYTDL"
	set diag_Title to "MacYTDL, " & theVersionLabel & " " & MacYTDL_version & ", " & MacYTDL_date
	-- Set path and name for custom icon for dialogs
	set MacYTDL_custom_icon_file to (path_to_MacYTDL & ":Contents:Resources:macytdl.icns")
	-- Set path and name for custom icon for enhanced window statements
	set MacYTDL_custom_icon_file_posix to POSIX path of MacYTDL_custom_icon_file
	set screen_size to my get_screensize()
	set X_position to item 1 of screen_size as integer
	--	set Y_position to item 2 of screen_size as integer
	set screen_width to item 3 of screen_size as integer
	set screen_height to item 4 of screen_size as integer
	
	-- Trim any trailing spaces from URL entered by user - reduces errors later on
	if URL_user_entered_clean is not "" and URL_user_entered_clean is not " " then
		if text item -1 of URL_user_entered_clean is " " then set URL_user_entered_clean to text 1 thru -2 of URL_user_entered_clean
	end if
	set URL_user_entered to quoted form of URL_user_entered_clean -- Quoted form needed in case the URL contains ampersands etc - but really need to get quoted form of each URL when more than one	
	-- Convert settings to format that can be used as youtube-dl/yt-dlp parameters + define variables
	if DL_description is true then
		set YTDL_description to "--write-description "
	else
		set YTDL_description to ""
	end if
	set YTDL_audio_only to ""
	set YTDL_audio_codec to ""
	if DL_over_writes is true and DL_Use_YTDLP is "yt-dlp" then
		set YTDL_over_writes to "--force-overwrites "
	else
		set YTDL_over_writes to ""
	end if
	
	set YTDL_subtitles to ""
	set YTDL_credentials to ""
	set DL_batch_status to false
	
	if DL_STEmbed is true then
		set YTDL_STEmbed to "--embed-subs "
	else
		set YTDL_STEmbed to ""
	end if
	
	-- Prepare User's download settings - using current settings - yt-dlp prefers to have name of post processor
	-- if DL_Remux_format is not "No remux" then -- 1.29.2 - 8/5/25 - Changed to localized Default label
	-- Using "--recode-video" for youtube-dl
	-- v1.30, 24/11/25 - Added facility for recode-video - retaining DL_Remux_format but changing "No remux" to "N/R"
	if DL_Remux_Recode is "Remux" then
		if DL_Use_YTDLP is "yt-dlp" then
			set YTDL_recode_remux to "--remux-video " & DL_Remux_format & " "
		else
			set YTDL_recode_remux to "--recode-video " & DL_Remux_format & " "
		end if
	else if DL_Remux_Recode is "Recode" then
		if DL_Use_YTDLP is "yt-dlp" then
			set YTDL_recode_remux to "--recode-video " & DL_Remux_format & " "
		else
			set YTDL_recode_remux to "--recode-video " & DL_Remux_format & " "
		end if
	else
		set YTDL_recode_remux to ""
	end if
	if DL_Remux_original is true then
		set YTDL_Remux_original to "--keep-video "
	else
		set YTDL_Remux_original to ""
	end if
	-- Set YTDL format parameter desired format + set separate YTDL_format_pref variable for use in simulate stage
	--	if DL_format is not "Default" then -- 1.29.2 - 8/5/25 - Needed to use localized Default label
	if DL_format is not theDefaultLabel then
		set YTDL_format to "-f bestvideo[ext=" & DL_format & "]+bestaudio/best[ext=" & DL_format & "]/best "
		set YTDL_format_pref to "-f " & DL_format & " "
	else
		set YTDL_format_pref to ""
		set YTDL_format to ""
	end if
	--	Set format sort parameter to desired maximum - not used in Simulate
	if DL_Resolution_Limit is theBestLabel then
		set YTDL_Resolution_Limit to ""
	else
		set YTDL_Resolution_Limit to "-S \"res:" & DL_Resolution_Limit & "\" "
	end if
	if DL_Thumbnail_Embed is true then
		set YTDL_Thumbnail_Embed to "--embed-thumbnail "
	else
		set YTDL_Thumbnail_Embed to ""
	end if
	if DL_Thumbnail_Write is true then
		set YTDL_Thumbnail_Write to "--write-thumbnail "
	else
		set YTDL_Thumbnail_Write to ""
	end if
	if DL_verbose is true then
		set YTDL_verbose to "--verbose "
	else
		set YTDL_verbose to ""
	end if
	if DL_TimeStamps is true then
		set YTDL_TimeStamps to resourcesPath & "ets"
	else
		set YTDL_TimeStamps to ""
	end if
	if DL_Limit_Rate is true then
		set YTDL_limit_rate_value to ("--limit-rate " & DL_Limit_Rate_Value & "m ")
	else
		set YTDL_limit_rate_value to ""
	end if
	if DL_Add_Metadata is true then
		set YTDL_metadata to "--add-metadata "
	else
		set YTDL_metadata to ""
	end if
	if DL_No_Warnings is true then
		set YTDL_No_Warnings to "--no-warnings "
	else
		set YTDL_No_Warnings to ""
	end if
	if DL_Dont_Use_Parts is true then
		set YTDL_Use_Parts to "--no-part "
	else
		set YTDL_Use_Parts to ""
	end if
	if DL_Clear_Batch is true then
		set ADL_Clear_Batch to "true"
	else
		set ADL_Clear_Batch to "false"
	end if
	if DL_Use_Proxy is true then
		set YTDL_Use_Proxy to ("--proxy " & DL_Proxy_URL & " ")
	else
		set YTDL_Use_Proxy to ""
	end if
	if DL_Use_Cookies is true then
		set YTDL_Use_Cookies to ("--cookies " & DL_Cookies_Location & " ")
	else
		set YTDL_Use_Cookies to ""
	end if
	if DL_Use_Custom_Settings is true then
		set YTDL_Custom_Settings to (DL_Custom_Settings & " ")
	else
		set YTDL_Custom_Settings to ""
	end if
	if DL_Use_Custom_Template is true then
		set YTDL_Custom_Template to DL_Custom_Template
	else
		set YTDL_Custom_Template to ""
	end if
	if DL_Use_netrc is true then
		set YTDL_Use_netrc to "--netrc "
	else
		set YTDL_Use_netrc to ""
	end if
	-- If user wants QT compatibility, must turn off remux 
	if DL_QT_Compat is true then
		set YTDL_QT_Compat to "--recode-video \"mp4\" --ppa \"VideoConvertor:-vcodec libx264 -acodec aac\""
		set YTDL_remux_format to ""
	else
		set YTDL_QT_Compat to ""
	end if
	
	set YTDL_no_part to ""
	
	-- Set settings to enable audio only download - gets a format list - use post-processing if necessary - need to ignore all errors here which are usually due to missing videos etc.
	if DL_audio_only is true then
		try
			set YTDL_get_formats to do shell script shellPath & DL_Use_YTDLP & " --list-formats --ignore-errors " & URL_user_entered & " 2>&1"
		on error errStr
			set YTDL_get_formats to errStr
		end try
		-- To get a straight audio-only download - rely on YTDL to get best available audio only file - if user also requests remux, container will contain audio in best format
		if YTDL_get_formats contains "audio only" and DL_audio_codec is theBestLabel then
			set YTDL_audio_only to "--format bestaudio "
			set YTDL_format to ""
		else
			-- If audio only file not available and/or user wants specific format, extract audio only file in desired format from best container and, if needed, convert in post-processing to desired format
			set YTDL_audio_codec to "--extract-audio --audio-format " & DL_audio_codec & " --audio-quality 0 "
		end if
	end if
	
	-- Get version of current macOS install - used in download_video() to block iView chooser for users on OS X 10.10, 10.11 and 10.12
	set user_os_version to system version of (system info) as string
	if user_os_version is less than "10.13" then
		set user_on_old_os to true
	else
		set user_on_old_os to false
	end if
	
	-- Generalise the DL_Use_YTDLP variable - only need the legacy form when updating the yt-dlp script
	if DL_Use_YTDLP is "yt-dlp-legacy" then
		set DL_Use_YTDLP to "yt-dlp"
	else
		set DL_Use_YTDLP to DL_Use_YTDLP
	end if
	
	
	set theButtonOKLabel to localized string "OK" from table "MacYTDL"
	set theButtonCancelLabel to localized string "Cancel" from table "MacYTDL"
	set theButtonDownloadLabel to localized string "Download" from table "MacYTDL"
	set theButtonReturnLabel to localized string "Return" from table "MacYTDL"
	set theButtonQuitLabel to localized string "Quit" from table "MacYTDL"
	set theButtonContinueLabel to localized string "Continue" from table "MacYTDL"
	set path_to_MacYTDL to (path_to_MacYTDL & ":")
	
	set skip_Main_dialog to true
	
	my check_download_folder(downloadsFolder_Path, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, diag_Title, MacYTDL_custom_icon_file, skip_Main_dialog)
	if DL_Use_Cookies is true then my check_cookies_file(DL_Cookies_Location)
	
	
	-- v1.30, 24/11/25 - Rejigged to implement recode-video - changed YTDL_remux_format to YTDL_recode_remux which basically has same content
	--	run_Main_handlers's download_video(shellPath, path_to_MacYTDL, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, screen_width, screen_height, YTDL_simulate_file, URL_user_entered, URL_user_entered_clean, downloadsFolder_Path, diag_Title, DL_batch_status, DL_Remux_format, DL_subtitles, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format_pref, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, skip_Main_dialog, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, theButtonReturnLabel, theButtonQuitLabel, theButtonContinueLabel, YTDL_QT_Compat, DL_Use_YTDLP, theBestLabel, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, user_on_old_os, X_position, deno_version, YTDL_Use_netrc, YTDL_version)
	my download_video(shellPath, path_to_MacYTDL, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, screen_width, screen_height, YTDL_simulate_file, URL_user_entered, URL_user_entered_clean, downloadsFolder_Path, diag_Title, DL_batch_status, DL_Remux_format, DL_subtitles, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format_pref, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, skip_Main_dialog, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, theButtonReturnLabel, theButtonQuitLabel, theButtonContinueLabel, YTDL_QT_Compat, DL_Use_YTDLP, theBestLabel, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, user_on_old_os, X_position, deno_version, YTDL_Use_netrc, YTDL_version)
	
	--	on error errMsg
	--		display dialog "Error in auto_Download handler: " & errMsg
	--	end try
	
	
end auto_Download

----------------------------------------------------------------------------------------------------
--
-- 	Check cookies - called by main_dialog and utilities - if user turns on use_cookies
--
----------------------------------------------------------------------------------------------------
-- Check cookies file is available - in case user has not mounted an external volume or has moved/renamed the file/folder
on check_cookies_file(DL_Cookies_Location)
	set cookies_Path_posix to (POSIX file DL_Cookies_Location)
	try
		set cookies_Path_alias to cookies_Path_posix as alias
	on error
		set theCookiesFileMissingLabel to localized string "Your cookies file is not available. You can make it available then click on Continue, return to set a new cookies location or quit." from table "MacYTDL"
		set quit_or_return to button returned of (display dialog theCookiesFileMissingLabel buttons {theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
		if quit_or_return is theButtonReturnLabel then
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			return "Main"
			-- my main_dialog()
			-- ************************************************************************************************************************************************************		
			
		else if quit_or_return is theButtonQuitLabel then
			my quit_MacYTDL()
		end if
	end try
	-- If user clicks "Continue" processing returns to after call to this handler and download process commences
end check_cookies_file


---------------------------------------------------
--
-- 		Get current preference settings
--
---------------------------------------------------

-- Handler for reading the users' preferences file - called by auto_download()
on read_settings(MacYTDL_prefs_file)
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			set DL_Add_Metadata to value of property list item "Add_Metadata"
			set DL_TimeStamps to value of property list item "Add_TimeStamps"
			set DL_audio_only to value of property list item "Audio_Only"
			set DL_audio_codec to value of property list item "Audio_Codec"
			set DL_YTDL_auto_check to value of property list item "Auto_Check_YTDL_Update"
			set DL_auto to value of property list item "Auto_Download"
			set DL_Clear_Batch to value of property list item "Clear_Batch"
			set DL_Cookies_Location to value of property list item "Cookies_Location"
			set DL_Custom_Template to value of property list item "Custom_Output_Template"
			set DL_Custom_Settings to value of property list item "Custom_Settings"
			set DL_Delete_Partial to value of property list item "Delete_Partial"
			set DL_description to value of property list item "Description"
			set DL_discard_URL to value of property list item "Discard_URL"
			set DL_Dont_Use_Parts to value of property list item "Dont_Use_Parts"
			set downloadsFolder_Path to value of property list item "DownloadFolder"
			set DL_format to value of property list item "FileFormat"
			set window_Position to value of property list item "final_Position"
			set DL_formats_list to value of property list item "Get_Formats_List"
			set DL_Remux_original to value of property list item "Keep_Remux_Original"
			set DL_Limit_Rate to value of property list item "Limit_Rate"
			set DL_Limit_Rate_Value to value of property list item "Limit_Rate_Value"
			set DL_QT_Compat to value of property list item "Make_QuickTime_Compat"
			set DL_Settings_In_Use to value of property list item "Name_Of_Settings_In_Use"
			set DL_No_Warnings to value of property list item "No_Warnings"
			set DL_over_writes to value of property list item "Over-writes allowed"
			set DL_Parallel to value of property list item "Parallel"
			set DL_Proxy_URL to value of property list item "Proxy_URL"
			set DL_Remux_Recode to value of property list item "Remux_Recode"
			set DL_Remux_format to value of property list item "Remux_Format"
			set DL_Resolution_Limit to value of property list item "Resolution_Limit"
			set DL_Saved_Settings_Location to value of property list item "Saved_Settings_Location"
			set DL_Show_Settings to value of property list item "Show_Settings_before_Download"
			set DL_subtitles to value of property list item "SubTitles"
			set DL_subtitles_format to value of property list item "Subtitles_Format"
			set DL_STEmbed to value of property list item "SubTitles_Embedded"
			set DL_STLanguage to value of property list item "Subtitles_Language"
			set DL_YTAutoST to value of property list item "Subtitles_YTAuto"
			set DL_Thumbnail_Embed to value of property list item "Thumbnail_Embed"
			set DL_Thumbnail_Write to value of property list item "Thumbnail_Write"
			set DL_Use_Cookies to value of property list item "Use_Cookies"
			set DL_Use_Custom_Settings to value of property list item "Use_Custom_Settings"
			set DL_Use_Custom_Template to value of property list item "Use_Custom_Output_Template"
			set DL_Use_Proxy to value of property list item "Use_Proxy"
			set DL_Use_netrc to value of property list item "Use_netrc"
			set DL_Use_YTDLP to value of property list item "Use_ytdlp"
			set DL_verbose to value of property list item "Verbose"
			set YTDL_version to value of property list item "YTDL_YTDLP_version"
		end tell
	end tell
end read_settings


----------------------------------------------------------------------------------------------------
--
-- 	Check downloads folder - called by main_dialog and utilities
--
----------------------------------------------------------------------------------------------------
-- Check that download folder is available - in case user has not mounted an external volume or has moved/renamed the folder - user must cancel or make folder available
on check_download_folder(folder_chosen, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, diag_Title, MacYTDL_custom_icon_file, skip_Main_dialog)
	if folder_chosen = downloadsFolder_Path then
		set downloadsFolder_Path_posix to (POSIX file downloadsFolder_Path)
		try
			set downloadsFolder_Path_alias to downloadsFolder_Path_posix as alias
		on error
			set theDownloadFolderMissingLabel to localized string "Your download folder is not available. You can make it available then click on Continue, return to set a new download folder or quit." from table "MacYTDL"
			set quit_or_return to button returned of (display dialog theDownloadFolderMissingLabel buttons {theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if quit_or_return is theButtonReturnLabel then
				if skip_Main_dialog is true then
					error number -128
				else
					
					-- ************************************************************************************************************************************************************
					-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
					set branch_execution to "Main"
					return branch_execution
					--				return "Main"  -- <= This might not have been effective
					-- my main_dialog()
					-- ************************************************************************************************************************************************************		
					
				end if
			else if quit_or_return is theButtonQuitLabel then
				my quit_MacYTDL()
			end if
			set branch_execution to my check_download_folder(folder_chosen, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, diag_Title, MacYTDL_custom_icon_file, skip_Main_dialog)
		end try
	end if
	-- Added next line in v1.29.3 - straps and laces approach
	set branch_execution to "Null"
	return branch_execution
	-- If user clicks "Continue" processing returns to after call to this handler and download process commences
end check_download_folder


---------------------------------------------------------------------------------------------
--
-- 	Download videos - called by Main dialog - calls monitor.scpt
--
---------------------------------------------------------------------------------------------
on download_video(shellPath, path_to_MacYTDL, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, screen_width, screen_height, YTDL_simulate_file, URL_user_entered, URL_user_entered_from_auto_download, folder_chosen, diag_Title, DL_batch_status, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format_pref, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, skip_Main_dialog, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, theButtonReturnLabel, theButtonQuitLabel, theButtonContinueLabel, YTDL_QT_Compat, DL_Use_YTDLP, theBestLabel, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, user_on_old_os, X_position, deno_version, YTDL_Use_netrc, YTDL_version)
	
	if URL_user_entered_from_auto_download is not "" then
		set URL_user_entered_clean to URL_user_entered_from_auto_download
	end if
	
	-- Decided to change number_ABC_SBS_episodes into a flag - to make easier later code
	--	set number_ABC_SBS_episodes to 0
	set number_ABC_SBS_episodes to ""
	
	-- Remove any trailing slash in the URL - causes syntax error with code to follow
	if text -2 of URL_user_entered is "/" then
		set URL_user_entered to quoted form of (text 2 thru -3 of URL_user_entered) -- Why not just remove the trailing slash ??
	end if
	
	-- Do error checking on pasted URL
	-- First, is pasted URL blank ?
	if URL_user_entered is "" or URL_user_entered is "''" then
		tell me to activate -- Not sure this achieves anything -- 29/3/25 - Decommented to hopefully solve "User interaction disallowed" problem for user
		set theURLBlankLabel to localized string "You need to paste a URL before selecting Download. Quit or OK to try again." from table "MacYTDL"
		set quit_or_return to button returned of (display dialog theURLBlankLabel buttons {theButtonQuitLabel, theButtonOKLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
		if quit_or_return is theButtonOKLabel then
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			return "Main"
			--	main_dialog()
			-- ************************************************************************************************************************************************************		
			
		end if
	end if
	
	-- Second was pasted URL > 4 characters long but did not begin with "http"
	if length of URL_user_entered is greater than 4 then
		set test_URL to text 2 thru 5 of URL_user_entered
		if not test_URL is "http" then
			set theURLNothttpLabel1 to localized string "The URL" from table "MacYTDL"
			set theURLNothttpLabel2 to localized string "is not valid. It should begin with the letters http. You need to paste a valid URL before selecting Download. Quit or OK to try again." from table "MacYTDL"
			set quit_or_return to button returned of (display dialog theURLNothttpLabel1 & " \"" & URL_user_entered & "\" " & theURLNothttpLabel2 buttons {theButtonQuitLabel, theButtonOKLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if quit_or_return is theButtonOKLabel then
				if skip_Main_dialog is true then
					error number -128
				end if
				
				-- ************************************************************************************************************************************************************
				-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
				return "Main"
				--	main_dialog()
				-- ************************************************************************************************************************************************************		
				
			end if
		end if
		
		-- Third, is length of pasted URL </= 4
	else
		set theURLTooShortLabel1 to localized string "The URL" from table "MacYTDL"
		set theURLTooShortLabel2 to localized string "is not valid. It should begin with the letters http. You need to paste a valid URL before selecting Download, Quit or OK to try again." from table "MacYTDL"
		set quit_or_return to button returned of (display dialog theURLTooShortLabel1 & " \"" & URL_user_entered & "\" " & theURLTooShortLabel2 buttons {theButtonQuitLabel, theButtonOKLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
		if quit_or_return is theButtonOKLabel then
			if skip_Main_dialog is true then
				error number -128
			end if
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			return "Main"
			--	main_dialog()
			-- ************************************************************************************************************************************************************		
			
		end if
	end if
	
	-- Fourth, test whether the URL is an iView or OnDemand page not supported by yt-dlp
	if URL_user_entered contains "https://iview.abc.net.au/category" or URL_user_entered contains "https://iview.abc.net.au/collection" or URL_user_entered is "'https://iview.abc.net.au/browse'" or URL_user_entered contains "https://iview.abc.net.au/channel" or URL_user_entered is "https://iview.abc.net.au" or URL_user_entered is "https://iview.abc.net.au/" then
		set theURLWarningiViewCategoryLabel to localized string "This is an iView page from which MacYTDL cannot download videos. Try an individual show." from table "MacYTDL"
		display dialog theURLWarningiViewCategoryLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
		return "Main"
		--	main_dialog()
		-- ************************************************************************************************************************************************************		
		
	end if
	-- v1.30, 30/11/25 - This If/End block does not apply to the new Service process
	--	if URL_user_entered contains "https://iview.abc.net.au/show" and user_on_old_os is true then
	--		set theURLWarningiViewCategoryLabel to localized string "This is an iView show page which MacYTDL cannot display on OS X 10.10, 10.11 and 10.12. Try an individual show." from table "MacYTDL"
	--		display dialog theURLWarningiViewCategoryLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
	--		if skip_Main_dialog is true then
	--			error number -128
	--		end if
	
	-- ************************************************************************************************************************************************************
	-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
	--		return "Main"
	--	main_dialog()
	-- ************************************************************************************************************************************************************		
	
	--	end if
	-- Need nested if test for SBS given likely false positives from "-collection" in non-SBS URLs
	if URL_user_entered contains "https://www.sbs.com.au/ondemand" then
		if URL_user_entered is "'https://www.sbs.com.au/ondemand'" or URL_user_entered is "'https://www.sbs.com.au/ondemand/tv-shows'" or URL_user_entered contains "https://www.sbs.com.au/ondemand/collection" or URL_user_entered contains "-collection" or URL_user_entered contains "https://www.sbs.com.au/ondemand/sport" or URL_user_entered contains "https://www.sbs.com.au/ondemand/movies" or URL_user_entered contains "https://www.sbs.com.au/ondemand/live" or URL_user_entered contains "https://www.sbs.com.au/ondemand/fifa-world-cup-2022" or URL_user_entered contains "https://www.sbs.com.au/ondemand/favourites" then
			set theURLWarningSBSCategoryLabel to localized string "This is an SBS OnDemand Category page from which MacYTDL cannot download videos. Try an individual show." from table "MacYTDL"
			display dialog theURLWarningSBSCategoryLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			if skip_Main_dialog is true then
				error number -128
			end if
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			return "Main"
			--	main_dialog()
			-- ************************************************************************************************************************************************************		
			
		end if
	end if
	
	
	-- Fifth, test whether the URL is one of the Australian broadcasters and fashion ytdl command to get best series and file name
	-- ABC usually has the series name separate - so, need to add series parameter to the output template - movies and single show pages just repeat the show name which is OK for now
	-- ITV also has the series name and season available separately - movies repeat the series name and show season as "NA" which is OK 
	-- SBS and tenplay usually have the series name in the title - so, no need to add the series parameter
	-- 9Now is a detective story to find the show name - have to parse the URL
	-- 7Plus is also a detective story to find the show name - but, the extractor now finds the series name in the web page title
	-- 7Plus can also have extractor problems - shows can be AES-SAMPLE encrypted etc. At present DRM issues cannot be solved.
	
	-- Standard output template for most sites
	set YTDL_output_template to " -o '%(title)s.%(ext)s'"
	if YTDL_Custom_Template is not "" then
		set YTDL_output_template to " -o '" & YTDL_Custom_Template & "'"
	else
		if URL_user_entered contains "ABC" then
			set YTDL_output_template to " -o '%(series)s-%(title)s.%(ext)s'"
		else if URL_user_entered contains "ITV" then
			set YTDL_output_template to " -o '%(series)s-%(season)s-%(title)s.%(ext)s'"
		else if URL_user_entered contains "9Now" then
			set URL_user_entered_sans_q to text 1 thru -2 of URL_user_entered
			set AppleScript's text item delimiters to "/"
			set NineNow_URL_items to every text item of URL_user_entered_sans_q
			set AppleScript's text item delimiters to ""
			set NineNow_show_old to text 1 thru end of item 4 of NineNow_URL_items
			set NineNow_show_new to my replace_chars(NineNow_show_old, "-", "_")
			set YTDL_output_template to " -o '" & NineNow_show_new & "-%(title)s.%(ext)s'"
		else if URL_user_entered contains "7Plus" then
			set YTDL_output_template to " -o '%(series)s-%(title)s.%(ext)s'"
		end if
	end if
	
	-- Sixth, is the URL a YouTube channel - if so warn user it may contain a great many videos and take hours to work - but youtube-dl makes a mess of channels so, send those users back to Main
	set is_channel to false
	if URL_user_entered_clean contains "https://www.youtube.com/c/" or URL_user_entered_clean contains "https://www.youtube.com/channel/" or URL_user_entered_clean contains "https://www.youtube.com/user/" or URL_user_entered_clean contains "https://www.youtube.com/@" then
		if DL_Use_YTDLP is "yt-dlp" then
			set theYTChannelLabel to localized string "The URL you entered looks like a YouTube channel. Most channels have a great many videos, some have hundreds. It may take hours to check and download each video. Do you really wish to continue or return to the Main dialog ?" from table "MacYTDL"
			set quit_or_return to button returned of (display dialog theYTChannelLabel buttons {theButtonReturnLabel, theButtonContinueLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if quit_or_return is theButtonReturnLabel then
				if skip_Main_dialog is true then
					error number -128
				end if
				
				-- ************************************************************************************************************************************************************
				-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
				return "Main"
				--	main_dialog()
				-- ************************************************************************************************************************************************************						
			else
				set is_channel to true
			end if
		else
			set theYTChannelLabel to localized string "The URL you entered looks like a YouTube channel. You are using youtube-dl for your download. Currently, MacYTDL cannot download channels with youtube-dl." from table "MacYTDL"
			display dialog theYTChannelLabel buttons {theButtonReturnLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
			if skip_Main_dialog is true then
				error number -128
			end if
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			return "Main"
			--	main_dialog()
			-- ************************************************************************************************************************************************************		
			
		end if
	end if
	
	
	-- v1.30, 17/11/25 - Convert tabs, returns and line breaks into spaces => enables multiple and parallel downloads with existing code
	if URL_user_entered_clean contains tab then
		set URL_user_entered_clean to my replace_chars(URL_user_entered_clean, tab, " ")
		set URL_user_entered to my replace_chars(URL_user_entered, tab, " ")
	else if URL_user_entered_clean contains return then
		set URL_user_entered_clean to my replace_chars(URL_user_entered_clean, return, " ")
		set URL_user_entered to my replace_chars(URL_user_entered, return, " ")
	else if URL_user_entered_clean contains linefeed then
		set URL_user_entered_clean to my replace_chars(URL_user_entered_clean, linefeed, " ")
		set URL_user_entered to my replace_chars(URL_user_entered, linefeed, " ")
	end if
	
	
	-- v1.30, 30/11/25 - Provide user with a way to choose episodes in iView seasons - yt-dlp treats all iView show pages as playlists
	-- Replace hyphens with colon to indicate a range
	-- Replace spaces and semi-colons with commas to indicate individual items
	-- Remove characters not relevant to episode choice
	-- Auto-download stops if user cancels
	-- Add result to user's existing custom settings
	-- Look for "/show/" in URL which excludes live streams, category pages
	-- 3/12/25 - Added curl of web page in order to exclude non-TV shows and to get show name
	set ABC_show_name to ""
	if URL_user_entered contains "https://iview.abc.net.au/show/" then
		set ABC_show_page to do shell script "curl " & URL_user_entered_clean
		set find_show_type_delimiter_before to "\",\"@type\":\""
		set find_show_type_delimiter_after to "\",\"name\":\""
		set find_show_name_delimiter_before to "\",\"title\":{\"title\":\""
		set find_show_name_delimiter_after to "\"},\"program\":{\""
		set AppleScript's text item delimiters to {find_show_type_delimiter_before, find_show_type_delimiter_after}
		set iView_show_type to text item 2 of ABC_show_page
		set AppleScript's text item delimiters to ""
		-- ************************************************************************************************************************************************************
		-- display dialog "iView_show_type: " & iView_show_type
		-- ************************************************************************************************************************************************************
		if iView_show_type is not "Movie" and iView_show_type is not "TVEpisode" then
			set AppleScript's text item delimiters to {find_show_name_delimiter_before, find_show_name_delimiter_after}
			set ABC_show_name to text item 2 of ABC_show_page
			set AppleScript's text item delimiters to ""
			set theiViewAskForEpisodesLabel1 to localized string "This is an iView show" from table "MacYTDL"
			set theiViewAskForEpisodesLabel2 to localized string "To choose episodes, type the episode number(s) in the box below (commas to separate episode numbers and colons for a range). For all episodes leave the box blank." from table "MacYTDL"
			set iViewEpisodeChoice to display dialog (theiViewAskForEpisodesLabel1 & ", “" & ABC_show_name & "”. " & theiViewAskForEpisodesLabel2) buttons {theButtonCancelLabel, theButtonOKLabel} default answer "" default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
			if button returned of iViewEpisodeChoice is theButtonOKLabel then
				set iViewEpisodesChoice to text returned of iViewEpisodeChoice
				set download_filename_new to ABC_show_name
				set number_ABC_SBS_episodes to "Playlist"
				if iViewEpisodesChoice is not "" then
					set number_ABC_SBS_episodes to "Episodes"
					set iViewEpisodesChoice to cleanString(iViewEpisodesChoice)
					set iViewEpisodesChoice to my replace_chars(iViewEpisodesChoice, {"  ", " ", ",,", ";", ", ", "	"}, ",")
					set iViewEpisodesChoice to my replace_chars(iViewEpisodesChoice, {"-", " - "}, ":")
					if character 1 of iViewEpisodesChoice is "," or character 1 of iViewEpisodesChoice is ":" then
						set iViewEpisodesChoice to characters 2 thru end of iViewEpisodesChoice as text
					end if
					if character -1 of iViewEpisodesChoice is "," or character -1 of iViewEpisodesChoice is ":" then
						set iViewEpisodesChoice to characters 1 thru -2 of iViewEpisodesChoice as text
					end if
					set YTDL_Custom_Settings to DL_Custom_Settings & " --playlist-items " & iViewEpisodesChoice
				end if
			end if
		end if
	end if
	
	--	if ABC_show_indicator is "Yes" then
	--		if (count of paragraphs of download_filename_new_plain) is greater than 1 then
	--			set download_filename_new to ABC_show_name
	--			if DL_Parallel is true then
	--				set download_filename_new to download_filename_new & "$$"
	--			end if
	--		end if
	--	end if
	
	
	--NEED TO SORT OUT FILE NAME THAT GOES INTO THE MONITOR !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	
	
	
	
	
	
	-- Seventh, use simulated YTDL/yt-dlp run to look for errors such as invalid URL which would otherwise stop MacYTDL
	-- Trap errors caused by ABC show pages - send processing to separate handler to collect episodes shown on that kind of page or warn user
	-- Also get any warnings that indicate an SBS show page and other issues
	-- But ignore revertions to the generic extractor
	-- Also get the file name from the simulate results - to be used in naming of log files and detail that will be shown in the Monitor dialog
	-- Also get other details including formats available	
	
	-- Put single quotes around each URL - mainly because the ampersand in some Youtube URLs ends up being treated as a delimiter - this is also done in the Monitor
	set AppleScript's text item delimiters to " "
	set number_of_URLs to number of text items in URL_user_entered_clean
	if number_of_URLs is greater than 1 then
		set URL_user_entered_clean_quoted to ""
		repeat with current_URL in text items of URL_user_entered_clean
			-- set current_URL to quoted form of current_URL --<= Doesn't stick thru later processes !
			set current_URL to "'" & current_URL & "'"
			set URL_user_entered_clean_quoted to URL_user_entered_clean_quoted & current_URL & " "
		end repeat
	else
		set URL_user_entered_clean_quoted to quoted form of URL_user_entered_clean
	end if
	set AppleScript's text item delimiters to ""
	
	-- Playlists: Use a simulation to get name of playlist and number of items - test that cookies file works - warn user if there are more than 20 items in the playlist
	-- v1.26 - Use alternative simulate when user wants parallel downloads - Initialise parallel_playlist flag so those cases can be excluded from standard simulate
	set YTDL_no_playlist to ""
	set playlist_Name to ""
	set DL_Playlist_Items_Spec to ""
	set alerterPiD to ""
	set parallel_playlist to false
	-- Implement user's request for certain playlist items - if use custom settings is on
	if (DL_Custom_Settings contains "playlist-items" or DL_Custom_Settings contains "-I") and DL_Use_Custom_Settings is true then
		-- Tricky
		set AppleScript's text item delimiters to " "
		set num_custom_settings_items to count of text items in DL_Custom_Settings
		repeat with i from 1 to num_custom_settings_items
			if text item (i) of DL_Custom_Settings is "-I" or text item (i) of DL_Custom_Settings is "--playlist-items" then
				set DL_Playlist_Items_Spec to ("--playlist-items " & text item (i + 1) of DL_Custom_Settings & " ")
				exit repeat
			end if
		end repeat
		set AppleScript's text item delimiters to ""
	end if
	-- Does the URL point to a single playlist item ? 
	if URL_user_entered_clean contains "&index=" and URL_user_entered_clean contains "youtu" then
		set YTDL_no_playlist to "--no-playlist "
		-- Does the URL point to a playlist ? If so, warn user to wait while the playlist is checked for warnings and errors
	else if URL_user_entered_clean contains "playlist" or (URL_user_entered_clean contains "watch?" and URL_user_entered_clean contains "&list=") or (URL_user_entered_clean contains "?list=") then
		if DL_Parallel is false then
			set playListAlertActionLabel to quoted form of "_"
			set playListAlertTitle to quoted form of (localized string "MacYTDL" from table "MacYTDL")
			set playListAlertMessage to quoted form of (localized string "  Please wait." from table "MacYTDL")
			set playListAlertSubtitle to quoted form of (localized string "Now checking detail of playlist. " from table "MacYTDL")
			set alerterPiD to do shell script quoted form of (resourcesPath & "alerter") & " -message " & playListAlertMessage & " -title " & playListAlertTitle & " -subtitle " & playListAlertSubtitle & " -sender com.apple.script.id.MacYTDL -actions " & playListAlertActionLabel & " -timeout 20 > /dev/null 2> /dev/null & echo $!"
			try
				set playlist_Simulate to do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; " & DL_Use_YTDLP & " --flat-playlist " & DL_Playlist_Items_Spec & YTDL_Use_netrc & YTDL_Use_Cookies & YTDL_No_Warnings & URL_user_entered_clean_quoted
				try
					do shell script "kill " & alerterPiD
				end try
			on error error_Message
				try
					do shell script "kill " & alerterPiD
				end try
				set theErrorWithPlaylistLabel1 to "There was an error with the playlist. The error was: \""
				if DL_Use_Cookies is true and error_Message contains "playlist does not exist" then
					set theErrorWithPlaylistLabel2 to "This may have been caused by a faulty cookies file. Check the file and try again."
				else
					set theErrorWithPlaylistLabel2 to "Check the URL and try again."
				end if
				display dialog theErrorWithPlaylistLabel1 & error_Message & "\" " & theErrorWithPlaylistLabel2 buttons {theButtonReturnLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
				if skip_Main_dialog is true then
					error number -128
				end if
				
				-- ************************************************************************************************************************************************************
				-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
				return "Main"
				--	main_dialog()
				-- ************************************************************************************************************************************************************		
				
			end try
			--			set AppleScript's text item delimiters to {"[download] Downloading playlist: ", return & "[youtube:tab] Playlist "} -- v1.26 - updated for change to format of data returned by "--flat-playlist"
			set AppleScript's text item delimiters to {"[download] Finished downloading playlist: "}
			set playlist_Name to text item 2 of playlist_Simulate
			if playlist_Name contains "/" then
				set playlist_Name to my replace_chars(playlist_Name, "/", "_")
			end if
			
			-- Get number of items in playlist - find paragraph containing number - warn user if more than 20 items
			-- For some reason, YTDL duplicates a line in the log to --flat-playlist for playlists that point to an item (including the youtu.be URLs), but not mixes or ordinary playlists – yt-dlp does not do that
			if DL_Use_YTDLP is "youtube-dl" then
				set AppleScript's text item delimiters to {": Downloading ", " videos"}
				if (URL_user_entered_clean contains "list=PL" or URL_user_entered_clean contains "list=OL") and (URL_user_entered_clean contains "watch?" or URL_user_entered_clean contains "//youtu.be/") then
					set playlist_Number_Items to text item 4 of playlist_Simulate as integer
				else
					set playlist_Number_Items to text item 3 of playlist_Simulate as integer
				end if
				set AppleScript's text item delimiters to {""}
			end if
			if DL_Use_YTDLP is "yt-dlp" then
				--	repeat with x from 1 to count paragraphs of playlist_Simulate
				--		if contents of paragraph x of playlist_Simulate begins with "[youtube:tab] Playlist" then -- This is specific to YouTube which serves a line containing playlist item count - yt-dlp uses different log markers with other sites
				--			set PL_simulate_Paragraph to paragraph (x) of playlist_Simulate
				--			exit repeat
				--		end if
				--	end repeat
				--set AppleScript's text item delimiters to {": Downloading", " videos"}       -- <== This code changed on 16/1/23
				--	set AppleScript's text item delimiters to {": Downloading ", " items "}
				--	set playlist_Number_Items to text item 2 of PL_simulate_Paragraph as integer
				
				-- v1.30, 11/11/25 - Added repeat loop to stop crashes on non-YouTube playlists
				set PL_starting_point to (offset of " items" in playlist_Simulate) - 1
				set test_char to ""
				set playlist_Number_Items to ""
				repeat
					set test_char to character PL_starting_point in playlist_Simulate
					if test_char is " " then exit repeat
					set playlist_Number_Items to (test_char & playlist_Number_Items)
					set PL_starting_point to PL_starting_point - 1
				end repeat
				set playlist_Number_Items to playlist_Number_Items as integer
				--	set AppleScript's text item delimiters to {""}
			end if
			if playlist_Number_Items is greater than 20 then
				try
					if alerterPiD is not "" then do shell script "kill " & alerterPiD
				end try
				set theManyPlaylistItemsLabel1 to localized string "There are " from table "MacYTDL"
				set theManyPlaylistItemsLabel2 to localized string " items in playlist " from table "MacYTDL"
				set theManyPlaylistItemsLabel3 to localized string "It will take a long time to download. Do you wish to continue or return to the Main dialog ?" from table "MacYTDL"
				set quit_or_return to button returned of (display dialog theManyPlaylistItemsLabel1 & playlist_Number_Items & theManyPlaylistItemsLabel2 & "\"" & playlist_Name & "\". " & theManyPlaylistItemsLabel3 buttons {theButtonReturnLabel, theButtonContinueLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
				if quit_or_return is theButtonReturnLabel then
					if skip_Main_dialog is true then
						error number -128
					end if
					
					-- ************************************************************************************************************************************************************
					-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
					return "Main"
					--	main_dialog()
					-- ************************************************************************************************************************************************************		
					
				end if
			end if
		else if DL_Parallel is true then
			set parallel_playlist to true
			set playlist_Name to "Parallel playlist"
			-- User wants to download playlist in parallel - do a simulate but get different data back using --print to get playlist name, item URLs and item names - send output to simulate file - show an alert also
			set playListAlertActionLabel to quoted form of "_"
			set playListAlertTitle to quoted form of (localized string "MacYTDL" from table "MacYTDL")
			set playListAlertMessage to quoted form of (localized string "  Please wait." from table "MacYTDL")
			set playListAlertSubtitle to quoted form of (localized string "Now checking detail of playlist. " from table "MacYTDL")
			set alerterPiD to do shell script quoted form of (resourcesPath & "alerter") & " -message " & playListAlertMessage & " -title " & playListAlertTitle & " -subtitle " & playListAlertSubtitle & " -sender com.apple.script.id.MacYTDL -actions " & playListAlertActionLabel & " -timeout 20 > /dev/null 2> /dev/null & echo $!"
			try
				do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --print '%(playlist_title)s##%(webpage_url)s##%(title)s.%(ext)s' " & DL_Playlist_Items_Spec & YTDL_Use_netrc & YTDL_No_Warnings & YTDL_Use_Cookies & URL_user_entered_clean_quoted & " 2>&1 &>" & quoted form of YTDL_simulate_file & " ; exit 0"
				try
					do shell script "kill " & alerterPiD
				end try
			on error error_Message
				try
					do shell script "kill " & alerterPiD
				end try
				set theErrorWithPlaylistLabel1 to "There was an error with the playlist. The error was: \""
				if DL_Use_Cookies is true and error_Message contains "playlist does not exist" then
					set theErrorWithPlaylistLabel2 to "This may have been caused by a faulty cookies file. Check the file and try again."
				else
					set theErrorWithPlaylistLabel2 to "Check the URL and try again."
				end if
				display dialog theErrorWithPlaylistLabel1 & error_Message & "\" " & theErrorWithPlaylistLabel2 buttons {theButtonReturnLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
				if skip_Main_dialog is true then
					error number -128
				end if
				
				-- ************************************************************************************************************************************************************
				-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
				return "Main"
				--	main_dialog()
				-- ************************************************************************************************************************************************************		
				
			end try
		end if
		set AppleScript's text item delimiters to ""
	end if
	
	set alerterPiD to ""
	-- Does the URL point to an entire channel - might be entire channel or a "tab" - either way must check for number of videos - warn if "playlist" or "featured" tab
	-- URL_user_entered_clean does not end with "streams"
	if playlist_Name is "" and DL_Use_YTDLP is "yt-dlp" and is_channel is true then
		set playListAlertActionLabel to quoted form of "_"
		set playListAlertTitle to quoted form of (localized string "MacYTDL" from table "MacYTDL")
		set playListAlertMessage to quoted form of (localized string "  Please wait." from table "MacYTDL")
		set playListAlertSubtitle to quoted form of (localized string "Now checking detail of channel. " from table "MacYTDL")
		set alerterPiD to do shell script quoted form of (resourcesPath & "alerter") & " -message " & playListAlertMessage & " -title " & playListAlertTitle & " -subtitle " & playListAlertSubtitle & " -sender com.apple.script.id.MacYTDL -actions " & playListAlertActionLabel & " -timeout 10 > /dev/null 2> /dev/null & echo $!"
		try
			set playlist_Simulate to do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; " & DL_Use_YTDLP & " --flat-playlist " & DL_Playlist_Items_Spec & YTDL_Use_netrc & YTDL_Use_Cookies & YTDL_No_Warnings & URL_user_entered_clean_quoted
		on error error_Message
			try
				do shell script "kill " & alerterPiD
			end try
			set theErrorWithPlaylistLabel1 to "There was an error with the channel. The error was: \""
			if DL_Use_Cookies is true and error_Message contains "channel does not exist" then
				set theErrorWithPlaylistLabel2 to "This may have been caused by a faulty cookies file. Check the file and try again."
			else
				set theErrorWithPlaylistLabel2 to "Check the URL and try again."
			end if
			display dialog theErrorWithPlaylistLabel1 & error_Message & "\" " & theErrorWithPlaylistLabel2 buttons {theButtonReturnLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
			if skip_Main_dialog is true then
				error number -128
			end if
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			return "Main"
			--	main_dialog()
			-- ************************************************************************************************************************************************************		
			
		end try
		-- Parse channel simulate log for channel name and number of videos - most logs will have "Videos: " once but some will have "Topic: " once - so far, none have both - assume number of videos is at end of same paragraph
		-- Have to repeat through paragraphs in playlist_Simulate because layout varies and there are multiple occurrences of most delimiters - luckily only need the first found paragraph 
		repeat with x from 1 to count paragraphs of playlist_Simulate
			if (contents of paragraph x of playlist_Simulate contains " - Videos: Downloading ") or (contents of paragraph x of playlist_Simulate contains " - Topic: Downloading ") then
				set playlist_details to paragraph (x) of playlist_Simulate
				exit repeat
			end if
		end repeat
		set AppleScript's text item delimiters to {"[youtube:tab] Playlist ", " - Videos: Downloading ", " - Topic: Downloading "}
		set playlist_Name to text item 2 of playlist_details
		set AppleScript's text item delimiters to {" "}
		set playlist_Number_Items to last text item of playlist_details as integer
		set AppleScript's text item delimiters to {""}
		if playlist_Name contains "/" then
			set playlist_Name to my replace_chars(playlist_Name, "/", "_")
		end if
		if playlist_Number_Items is greater than 20 then
			try
				if alerterPiD is not "" then do shell script "kill " & alerterPiD
			end try
			set theManyPlaylistItemsLabel1 to localized string "There are " from table "MacYTDL"
			set theManyPlaylistItemsLabel2 to localized string " items in channel " from table "MacYTDL"
			set theManyPlaylistItemsLabel3 to localized string "It will take a long time to download. Do you wish to continue or return to the Main dialog ?" from table "MacYTDL"
			set quit_or_return to button returned of (display dialog theManyPlaylistItemsLabel1 & playlist_Number_Items & theManyPlaylistItemsLabel2 & "\"" & playlist_Name & "\". " & theManyPlaylistItemsLabel3 buttons {theButtonReturnLabel, theButtonContinueLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if quit_or_return is theButtonReturnLabel then
				if skip_Main_dialog is true then
					error number -128
				end if
				
				-- ************************************************************************************************************************************************************
				-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
				return "Main"
				--	main_dialog()
				-- ************************************************************************************************************************************************************		
				
			end if
		end if
	end if
	
	-- Error checking DL_formats_list before the simulate (which takes time)
	if number_of_URLs is greater than 1 and DL_formats_list is true then
		set theTooManyUELsLabel to localized string "Sorry, but MacYTDL cannot list formats for more than one URL. Would you like to cancel the download and return to the main dialog or skip the formats list and continue to download ?" from table "MacYTDL"
		set skip_or_return to button returned of (display dialog theTooManyUELsLabel buttons {theButtonReturnLabel, theButtonContinueLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
		if skip_or_return is theButtonReturnLabel then
			if skip_Main_dialog is true then
				error number -128
			end if
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			return "Main"
			--	main_dialog()
			-- ************************************************************************************************************************************************************		
			
		end if
		set DL_formats_list to false
	end if
	if playlist_Name is not "" and DL_formats_list is true then
		set thePlaylistAndListLabel to localized string "Sorry, but MacYTDL cannot list formats for playlists. Would you like to cancel the download and return to the main dialog or skip the formats list and continue to download ?" from table "MacYTDL"
		set skip_or_return to button returned of (display dialog thePlaylistAndListLabel buttons {theButtonReturnLabel, theButtonContinueLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
		if skip_or_return is theButtonReturnLabel then
			if skip_Main_dialog is true then
				error number -128
			end if
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			return "Main"
			--	main_dialog()
			-- ************************************************************************************************************************************************************		
			
		end if
		set DL_formats_list to false
	end if
	if is_channel is true and DL_formats_list is true then
		set thePlaylistAndListLabel to localized string "Sorry, but MacYTDL cannot list formats for channels. Would you like to cancel the download and return to the main dialog or skip the formats list and continue to download ?" from table "MacYTDL"
		set skip_or_return to button returned of (display dialog thePlaylistAndListLabel buttons {theButtonReturnLabel, theButtonContinueLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
		if skip_or_return is theButtonReturnLabel then
			if skip_Main_dialog is true then
				error number -128
			end if
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			return "Main"
			--	main_dialog()
			-- ************************************************************************************************************************************************************		
			
		end if
		set DL_formats_list to false
	end if
	
	-- Do a simulation to get back file names, get is_live status and disclose any errors or warnings
	-- URLs to iView and OnDemand show pages causes error => takes processing to Get_ABC_Episodes or Get_SBS_Episodes handlers
	-- If desired file format not available, advise user and ask what to do
	-- Other kinds of errors are reported to user asking what to do
	-- Takes a long time when simulating channels and playlists - users are warned earlier
	-- Exclude playlists when user has requested parallel downloads - simulate file already contains required data
	set simulate_YTDL_output_template to my replace_chars(YTDL_output_template, " -o '%", " -o '%(is_live)s#%")
	if parallel_playlist is false then
		do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & YTDL_format_pref & DL_Playlist_Items_Spec & YTDL_credentials & YTDL_Use_netrc & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_No_Warnings & simulate_YTDL_output_template & " " & URL_user_entered_clean_quoted & " 2>&1 &>" & quoted form of YTDL_simulate_file & " ; exit 0"
		-- Added delay as one user gets end of file errors which might be due to simulate file not being ready
	end if
	delay 1
	try
		set YTDL_simulate_log to read POSIX file YTDL_simulate_file as «class utf8»
	on error errMSG
		display dialog "Error in reading simulate file: " & YTDL_simulate_file & return & "The error reported was " & errMSG
	end try
	
	-- Check whether URL points to a live stream - add "no-part" so that file is playable - exclude playlists as by definition they can't be live streams - then strip out is_live response
	-- v1.26: force --no-part ignoring user's setting - so that saved file is immediately playable
	set is_Livestream_Flag to "False"
	if playlist_Name is "" then
		if YTDL_simulate_log contains "True#" then
			set is_Livestream_Flag to "True"
			set YTDL_no_part to "--no-part "
		end if
	end if
	
	-- Why is this here ? Very odd - maybe a crude way of dismissing an alert which otherwise doesn't close
	try
		if alerterPiD is not "" then do shell script "kill " & alerterPiD
	end try
	
	-- If file name is too long, remove user's custom output template or truncate to 190 characters then redo simulation - exclude playlists & multiple downloads
	-- Not sure if the "195" figure allows for warnings and remux settings which are also in the simulate log
	if (length of YTDL_simulate_log is greater than 195) and ((count of paragraphs in YTDL_simulate_log) is less than 3) then
		if YTDL_Custom_Template is not "" then
			set theFileNameTooLongLabel to localized string "With your custom file name output template, the total length of the log file name is too long. Would you like to exclude your custom template then continue or return to Main ?" from table "MacYTDL"
			set quit_or_return to button returned of (display dialog theFileNameTooLongLabel buttons {theButtonReturnLabel, theButtonContinueLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if quit_or_return is theButtonReturnLabel then
				if skip_Main_dialog is true then
					error number -128
				end if
				
				-- ************************************************************************************************************************************************************
				-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
				return "Main"
				--	main_dialog()
				-- ************************************************************************************************************************************************************		
				
			end if
			set YTDL_Custom_Template to ""
			set YTDL_output_template to " -o '%(is_live)s#%(title)s.%(ext)s'"
		end if
		do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & YTDL_no_playlist & DL_Playlist_Items_Spec & YTDL_format_pref & YTDL_credentials & YTDL_Use_netrc & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_No_Warnings & simulate_YTDL_output_template & " " & URL_user_entered_clean_quoted & " 2>&1 &>" & quoted form of YTDL_simulate_file & " ; exit 0"
		-- Added delay as one user gets end of file errors which might be due to simulate file not being ready
		delay 1
		try
			set YTDL_simulate_log to read POSIX file YTDL_simulate_file as «class utf8»
		on error errMSG
			display dialog "Error in reading simulate file: " & YTDL_simulate_file & return & "The error reported was " & errMSG
		end try
	end if
	
	-- Fix output template and file names used in Monitor and Adviser for cases where there is no series - e.g. ABC Radio doesn't have series detail
	if YTDL_simulate_log contains "#NA-" and (URL_user_entered contains "ABC" or URL_user_entered contains "ITV" or URL_user_entered contains "7Plus") then
		set YTDL_simulate_log to my replace_chars(YTDL_simulate_log, "NA-", "") -- Removes placeholder when there is no series name - put there by output template for ABC, ITV & 7Plus
		set YTDL_output_template to " -o '%(title)s.%(ext)s'"
	end if
	
	if YTDL_simulate_log contains "Unsupported URL: https://7plus.com.au/live-tv" then
		set theURLWarning7PlusLabel to localized string "Sorry, this is a 7Plus live stream page from which MacYTDL cannot download videos." from table "MacYTDL"
		display dialog theURLWarning7PlusLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		
		-- ****************************************************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return "Main"
		--	main_dialog()
		-- ****************************************************************************************************************************************************************************************************
		
	else if YTDL_simulate_log contains "Unsupported URL: https://7Plus.com.au" then
		set theURLWarning7PlusLabel to localized string "This is a 7Plus movie or a show page from which MacYTDL cannot download videos. If it's a show page, try an individual episode." from table "MacYTDL"
		display dialog theURLWarning7PlusLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		
		-- ****************************************************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return "Main"
		--	main_dialog()
		-- ****************************************************************************************************************************************************************************************************
		
	end if
	if YTDL_simulate_log contains "Unsupported URL: https://www.9now.com.au/live" then
		set theURLWarning7PlusLabel to localized string "Sorry, this is a 9Now live stream page from which MacYTDL cannot download videos." from table "MacYTDL"
		display dialog theURLWarning7PlusLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		
		-- ****************************************************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return "Main"
		--	main_dialog()
		-- ****************************************************************************************************************************************************************************************************
		
	else if YTDL_simulate_log contains "Unsupported URL: https://www.9now.com.au" then
		set theURLWarning9NowLabel to localized string "This is a 9Now Show page from which MacYTDL cannot download videos. Try an individual episode." from table "MacYTDL"
		display dialog theURLWarning9NowLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		
		-- ****************************************************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return "Main"
		--	main_dialog()
		-- ****************************************************************************************************************************************************************************************************
		
	end if
	-- v1.30, 13/11/25 - Trap SBS show pages which are currently not supported
	if YTDL_simulate_log contains "Unsupported URL: https://www.sbs.com.au/" then
		set theURLWarning9NowLabel to localized string "This is an SBS Show page from which MacYTDL cannot download videos. Try an individual episode." from table "MacYTDL"
		display dialog theURLWarning9NowLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		
		-- ****************************************************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return "Main"
		--	main_dialog()
		-- ****************************************************************************************************************************************************************************************************
		
	end if
	-- v1.30, 13/11/25 - Trap iView show pages which are currently not supported - should be very few as most are playlists
	if YTDL_simulate_log contains "Unsupported URL: https://iview.abc.net.au/" then
		set theURLWarning9NowLabel to localized string "This is an iView Show page from which MacYTDL cannot auto-download videos. Try an individual episode." from table "MacYTDL"
		display dialog theURLWarning9NowLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		
		-- ****************************************************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return "Main"
		--	main_dialog()
		-- ****************************************************************************************************************************************************************************************************
		
	end if
	if YTDL_simulate_log contains "Unsupported URL: https://10play.com.au/live" then
		set theURLWarning7PlusLabel to localized string "Sorry, this is a 10Play live stream page from which MacYTDL cannot download videos." from table "MacYTDL"
		display dialog theURLWarning7PlusLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		
		-- ****************************************************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return "Main"
		--	main_dialog()
		-- ****************************************************************************************************************************************************************************************************
		
	else if YTDL_simulate_log contains "Unsupported URL: https://10play.com.au" then
		set theURLWarning10playLabel to localized string "Sorry, this is a 10Play Show or Movie page from which MacYTDL cannot download videos. If it's a show, try an individual episode." from table "MacYTDL"
		display dialog theURLWarning10playLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		
		-- ****************************************************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return "Main"
		--	main_dialog()
		-- ****************************************************************************************************************************************************************************************************
		
	end if
	-- Requested format not available - tell user - simulate again if necessary
	if YTDL_simulate_log contains "requested format not available" then
		set theFormatNotAvailLabel1 to localized string "Your preferred file format is not available. Would you like to cancel download and return, have your download remuxed into your preferred format or just download the best format available ?" from table "MacYTDL"
		set theFormatNotAvailLabel2 to localized string "{Note: 3gp format is not available - a request for 3gp will be remuxed into mp4.}" from table "MacYTDL"
		set theFormatNotAvailButtonRemuxLabel to localized string "Remux" from table "MacYTDL"
		set quit_or_return to button returned of (display dialog theFormatNotAvailLabel1 & return & theFormatNotAvailLabel2 buttons {theButtonReturnLabel, theFormatNotAvailButtonRemuxLabel, theButtonDownloadLabel} default button 3 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
		if quit_or_return is theButtonReturnLabel then
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			return "Main"
			--	main_dialog()
			-- ************************************************************************************************************************************************************		
			
		else if quit_or_return is theButtonDownloadLabel then
			-- User wants to download the best format available so, set desired format to null - simulate again to get file name into simulate file 
			do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename " & YTDL_no_playlist & DL_Playlist_Items_Spec & YTDL_credentials & YTDL_Use_netrc & YTDL_No_Warnings & URL_user_entered_clean_quoted & " " & simulate_YTDL_output_template & " > /dev/null" & " &> " & quoted form of YTDL_simulate_file
			set YTDL_format to ""
			-- Added delay as one user gets end of file errors which might be due to simulate file not being ready
			delay 1
			try
				set YTDL_simulate_log to read POSIX file YTDL_simulate_file as «class utf8»
			on error errMSG
				display dialog "Error in reading simulate file: " & YTDL_simulate_file & return & "The error reported was " & errMSG
			end try
		else if quit_or_return is "Remux" then
			-- User wants download remuxed to preferred format - simulate again to get file name into similate file - set desired format to null so that YTDL automatically downloads best available and set remux parameters
			do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename " & YTDL_no_playlist & DL_Playlist_Items_Spec & YTDL_credentials & YTDL_Use_netrc & YTDL_No_Warnings & URL_user_entered_clean_quoted & " " & simulate_YTDL_output_template & " > /dev/null" & " &> " & quoted form of YTDL_simulate_file
			set YTDL_format to ""
			set DL_Remux_format to DL_format
			if YTDL_format_pref is "3gp" then
				set DL_Remux_format to "mp4"
			end if
			-- set YTDL_remux_format to "--recode-video " & remux_format_choice & " " & "--postprocessor-args \"-codec copy\" "  -- v1.28 - 6/10/24
			--  set YTDL_recode_remux to "--remux-video " & remux_format_choice & " " -- v1.30, 25/11/25 - Changed to provide for recode/remux
			set YTDL_recode_remux to DL_Remux_Recode & " " & DL_Remux_format & " "
			delay 1
			try
				set YTDL_simulate_log to read POSIX file YTDL_simulate_file as «class utf8»
			on error errMSG
				display dialog "Error in reading simulate file: " & YTDL_simulate_file & return & "The error reported was " & errMSG
			end try
		end if
	end if
	
	-- Remove the is_live status from the simulate log - crude but effective - hopefully, there are no valid cases where file name includes "NA-"
	set YTDL_simulate_log to my replace_chars(YTDL_simulate_log, "True#", "")
	set YTDL_simulate_log to my replace_chars(YTDL_simulate_log, "False#", "")
	set YTDL_simulate_log to my replace_chars(YTDL_simulate_log, "NA#", "") -- Removes placeholder when there is no is_live returned by simulate
	
	-- *******************************************************************************************************************************************************
	-- v1.24: trap errors caused by SBS OnDemand problem - v1.25: yt-dlp is fixed but, leaving in place in case fix is undone by SBS - v1.26: comment out
	--	set is_SBS_bug_page to false
	-- *******************************************************************************************************************************************************
	-- Try to exclude errors caused by iView URL that bang an error but need to be processed anyway - advise user of other errors
	if YTDL_simulate_log contains "ERROR:" and YTDL_simulate_log does not contain "Unsupported URL: https://www.sbs.com.au/ondemand" and YTDL_simulate_log does not contain "Unsupported URL: https://iview.abc.net.au/show" then
		-- Extractor error cases are skipped – because that error is a bug in yt-dlp
		if URL_user_entered_clean contains "https://iview.abc.net.au/show" and YTDL_simulate_log contains "An extractor error has occurred" then
			-- Do nothing
			-- *******************************************************************************************************************************************************
			--		else if URL_user_entered_clean contains "https://www.sbs.com.au/ondemand/" and YTDL_simulate_log contains "HTTP Error 403: Forbidden" then
			--			set is_SBS_bug_page to true
			-- *******************************************************************************************************************************************************
		else
			if playlist_Name is not "" then
				set theURLErrorTextLabelString to localized string "for the playlist" from table "MacYTDL"
				set theURLErrorTextLabel4 to localized string " " & theURLErrorTextLabelString & " " & "'" & playlist_Name & "':"
			else
				set theURLErrorTextLabel4 to ":"
			end if
			set theURLErrorTextLabel1 to localized string "There was an error with the URL you entered" from table "MacYTDL"
			set theURLErrorTextLabel2 to localized string "The error message was: " from table "MacYTDL"
			if skip_Main_dialog is true then
				set theURLErrorTextLabel3 to localized string "OK to give up or Download to try anyway." from table "MacYTDL"
				set quit_or_return to button returned of (display dialog theURLErrorTextLabel1 & " " & theURLErrorTextLabel4 & return & return & URL_user_entered & return & return & theURLErrorTextLabel2 & return & return & YTDL_simulate_log & return & theURLErrorTextLabel3 buttons {theButtonOKLabel, theButtonDownloadLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
				if quit_or_return is theButtonOKLabel then
					return "Main"
				else if quit_or_return is theButtonDownloadLabel then
					-- User wants to try to download ! Processing just continues from here down
				end if
			else
				if YTDL_simulate_log contains "Use --cookies-from-browser" then
					set theURLErrorTextLabel3 to localized string "Quit or OK to return." from table "MacYTDL"
					set quit_or_return to button returned of (display dialog theURLErrorTextLabel1 & theURLErrorTextLabel4 & return & return & URL_user_entered & return & return & theURLErrorTextLabel2 & return & return & YTDL_simulate_log & return & theURLErrorTextLabel3 buttons {theButtonQuitLabel, theButtonOKLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
				else
					set theURLErrorTextLabel3 to localized string "Quit, OK to return or Download to try anyway." from table "MacYTDL"
					set quit_or_return to button returned of (display dialog theURLErrorTextLabel1 & theURLErrorTextLabel4 & return & return & URL_user_entered & return & return & theURLErrorTextLabel2 & return & return & YTDL_simulate_log & return & theURLErrorTextLabel3 buttons {theButtonQuitLabel, theButtonOKLabel, theButtonDownloadLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
				end if
				if quit_or_return is theButtonOKLabel then
					
					-- ************************************************************************************************************************************************************
					-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
					return "Main"
					--	main_dialog()
					-- ************************************************************************************************************************************************************		
					
				else if quit_or_return is theButtonDownloadLabel then
					-- User wants to try to download ! Processing just continues from here down
				end if
			end if
		end if
	end if
	if YTDL_simulate_log contains "IOError: CRC check failed" then
		set theURLErrorTextLabel1 to localized string "There was an error with the URL you entered. The video might be DRM protected or it could be a network, VPN or macOS install issue. If the URL is correct, you may need to look more deeply into your network settings and macOS install." from table "MacYTDL"
		display dialog theURLErrorTextLabel1 buttons {theButtonOKLabel} with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
		return "Main"
		--	main_dialog()
		-- ************************************************************************************************************************************************************		
		
	end if
	
	
	-- Eighth - If URL points to YouTube, and user has recent version of yt-dlp, check that Deno is installed - if not, offer to install
	if (URL_user_entered_clean contains "youtube" or URL_user_entered_clean contains "youtu.be") and deno_version is "Not installed" then
		considering numeric strings
			if YTDL_version is greater than "2025.10.22" then
				set theButtonInstall to localized string "Install Deno"
				set install_deno_query to button returned of (display dialog (localized string "You need Deno installed to be sure of downloading from YouTube. Do you wish Deno to be installed, return to Main dialog or try without Deno ?") buttons {theButtonReturnLabel, theButtonContinueLabel, theButtonInstall} with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
				if install_deno_query is theButtonInstall then
					set deno_version to my install_update_Deno(deno_version, user_system_arch, resourcesPath, path_to_MacYTDL, theButtonOKLabel, MacYTDL_custom_icon_file, diag_Title)
				else if install_deno_query is theButtonReturnLabel then
					return "Main"
				else
					-- Continue and try downloading anyway
				end if
			end if
		end considering
	end if
	
	
	-- *****************************************************************************
	-- Setting ABC and SBS show page variables here for now - might change if this handler moves to utilities
	-- *****************************************************************************	
	-- Set ABC show name and episode count variables so they exist - Initialise indicators which will show whether URL is for an ABC or SBS show page - needed for overwriting code below
	--	set ABC_show_name to ""
	set SBS_show_name to ""
	set ABC_show_indicator to "No"
	set SBS_show_indicator to "No"
	
	-- Is the URL from an ABC or SBS Show Page ? - If so, get the user to choose which episodes to download - Warn user if URL is an Oz commercial FTA show page
	-- v1.27.1 – Exclude users on OS X 10.10, 10.11 & 10.12 - they have an out of date version of curl that lacks updated certificates
	-- v1.30, 29/11/25 - Lock out iView Chooser as auto_download should not be interrupted by dialogs
	--	if URL_user_entered_clean contains "iview.abc.net.au/show/" and user_on_old_os is false then
	--		-- Add a "/" to end of iView URLs so that they are treated correctly both by code to follow and yt-dlp - This might change if yt-dlp changes
	--		if last character of URL_user_entered_clean is not "/" then
	--			set URL_user_entered_clean to (URL_user_entered_clean & "/")
	--		end if
	--		set branch_execution to my Get_ABC_Episodes(URL_user_entered, diag_Title, "theButtonOKLabel", theButtonCancelLabel, theButtonDownloadLabel, X_position, screen_height, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, theButtonReturnLabel, skip_Main_dialog, path_to_MacYTDL, screen_width)
	--		
	--		-- ************************************************************************************************************************************************************
	--		-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
	--		if branch_execution is "Main" then return "Main"
	--		--	main_dialog()
	--		-- ************************************************************************************************************************************************************		
	--		
	--		-- ABC_show_URLs is global and so is accessable after it is populated in Get_ABC_Episodes()
	--		set ABC_show_indicator to "Yes"
	--		set URL_user_entered to ABC_show_URLs
	--		-- Bang a warning if user specifies needing a format list and selects more than one ABC episode
	--		set AppleScript's text item delimiters to " "
	--		set number_ABC_SBS_episodes to number of text items in ABC_show_URLs
	--		set AppleScript's text item delimiters to ""
	--		if number_ABC_SBS_episodes is greater than 1 and DL_formats_list is true then
	--			set theTooManyUELsLabel to localized string "Sorry, but MacYTDL cannot list formats for more than one ABC show. Would you like to cancel the download and return to the main dialog or skip the formats list and continue to-- download ?" from table "MacYTDL"
	--			set skip_or_return to button returned of (display dialog theTooManyUELsLabel buttons {theButtonReturnLabel, theButtonContinueLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
	--			if skip_or_return is theButtonReturnLabel then
	--				if skip_Main_dialog is true then
	--					error number -128
	--				end if
	--				
	--				-- ************************************************************************************************************************************************************
	--				-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
	--				return "Main"
	--				--	main_dialog()
	--				-- ************************************************************************************************************************************************************		
	--				
	--			else if skip_or_return is theButtonContinueLabel then
	--				set DL_formats_list to false
	--			end if
	--		end if
	--	end if
	
	
	-- *******************************************************************************************************************************************************
	-- 
	-- v1.30, 19/11/25 -  Gave up for now trying to disentangle the html code used by SBS. Even getting video indexes for one season is just too hard right now. Can still download individual shows.
	--
	-- *******************************************************************************************************************************************************
	-- *******************************************************************************************************************************************************
	-- v1.24 - Added workaround for SBS bug in yt-dlp - v1.26: removed test on is_SBS_bug_page
	--if YTDL_simulate_log contains "Unsupported URL: https://www.sbs.com.au/ondemand" or is_SBS_bug_page is true then
	-- if URL_user_entered contains "ondemand" then -- <<== v1.27 - Used for testing new SBS Chooser - just skips simulate stage
	-- *******************************************************************************************************************************************************
	--	if YTDL_simulate_log contains "Unsupported URL: https://www.sbs.com.au/ondemand" then
	--		-- If user uses URL from 'Featured' episode on a SBS Show page, trim trailing text of URL and treat like a Show page - NB Some featured videos are supported by youtube-dl/yt-dlp
	--		if URL_user_entered contains "?action=play" then
	--			set URL_user_entered to (text 1 thru -14 of URL_user_entered & "'")
	--		end if
	--		-- youtube-dl/yt-dlp cannot download from some SBS show links - mostly on the OnDemand home and search pages
	--		if YTDL_simulate_log contains "?play=" or URL_user_entered contains "ondemand/search" then
	--			set theOnDemandURLProblemLabel to localized string "MacYTDL cannot download video from an SBS OnDemand \"Play\" or Search links. Navigate to a \"Show\" page and try again." from table "MacYTDL"
	--			display dialog theOnDemandURLProblemLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 100
	--			if skip_Main_dialog is true then
	--				error number -128
	--			end if
	--			
	--			-- ************************************************************************************************************************************************************
	--			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
	--			return "Main"
	--			--	main_dialog()
	--			-- ************************************************************************************************************************************************************		
	--			
	--		else
	--			set check_URL_ID to last word of URL_user_entered
	--			set length_check_URL_ID to length of check_URL_ID
	--			try
	--				set check_URL_number to check_URL_ID as number
	--				set is_ID to true
	--			on error errText number errNum
	--				set is_ID to false
	--			end try
	--			
	--			if is_ID is true and length_check_URL_ID is greater than 7 and URL_user_entered does not contain "watch" then
	--				set URL_user_entered to ("https://www.sbs.com.au/ondemand/watch/" & check_URL_ID)
	--				set SBS_show_name to "This is a watcher URL"
	--				set number_ABC_SBS_episodes to 1
	--			else
	--				
	--				-- The URL from an SBS Show Page - get the user to choose which episodes to download
	--				set branch_execution to my Get_SBS_Episodes(URL_user_entered, diag_Title, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, X_position, screen_height, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, theButtonReturnLabel, skip_Main_dialog, path_to_MacYTDL)
	--				
	--				if branch_execution is "Main" then
	--					
	--					-- ************************************************************************************************************************************************************
	--					-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
	--					-- v1.29/3 - Added branch_execution to return statement in case it's an issue - this  might break downloading
	--					return branch_execution
	--					--	main_dialog()
	--					-- ************************************************************************************************************************************************************		
	--					
	--				else
	--					set SBS_show_URLs to branch_execution
	--				end if
	--				
	--				set SBS_show_indicator to "Yes"
	--				set URL_user_entered to SBS_show_URLs
	--				-- Bang a warning if user specifies needing a format list and selects more than one SBS episode
	--				set AppleScript's text item delimiters to " "
	--				set number_ABC_SBS_episodes to number of text items in SBS_show_URLs
	--				set AppleScript's text item delimiters to ""
	--				if number_ABC_SBS_episodes is greater than 1 and DL_formats_list is true then
	--					set theTooManyUELsLabel to localized string "Sorry, but MacYTDL cannot list formats for more than one SBS show. Would you like to cancel the download and return to the main dialog or skip the formats list and continue to download ?" from table "MacYTDL"
	--					set skip_or_return to button returned of (display dialog theTooManyUELsLabel buttons {theButtonReturnLabel, theButtonContinueLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
	--					if skip_or_return is theButtonReturnLabel then
	--						if skip_Main_dialog is true then
	--							error number -128
	--						end if
	--						
	--						-- ************************************************************************************************************************************************************
	--						-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
	--						return "Main"
	--						--	main_dialog()
	--						-- ************************************************************************************************************************************************************		
	--						
	--					else if skip_or_return is theButtonContinueLabel then
	--						set DL_formats_list to false
	--					end if
	--				end if
	--			end if
	--		end if
	--	end if
	
	-- Seventh, look for any more warnings in simulate file. Get filename from the simulate log file
	-- Don't show warning to user if it's just the fallback to generic extractor - that happens too often to be useful - same with the "Futurewarning" and non-available subtitles
	-- Because extension can be different, exclude that from file name
	-- Currently testing method for doing that (getting download_filename) - might not work if file extension is not 3 characters (eg. ts)
	-- Might remove the extraneous dot characters in file names if they prove a problem
	
	set simulate_warnings to ""
	repeat with aPara in (paragraphs of YTDL_simulate_log)
		-- if aPara contains "WARNING:" then -- <= Used for testing
		if aPara contains "WARNING:" and aPara does not contain "Falling back on generic information" and aPara does not contain "Incomplete data received" and aPara does not contain "Ignoring subtitle tracks found in the HLS manifest" and aPara does not contain "FutureWarning:" then
			if simulate_warnings is "" then
				set simulate_warnings to aPara
			else
				set simulate_warnings to simulate_warnings & return & aPara
			end if
		end if
	end repeat
	-- *******************************************************************************************************************************************************
	-- v1.24 - Exclude SBS workaround URLs from warning advices and from set_File_Names() - BUT, exiting from SBS Chooser doesn't flag workaround - v1.26: commented out
	--	if is_SBS_bug_page is false then
	-- *******************************************************************************************************************************************************
	if simulate_warnings is not "" then
		set theURLWarningTextLabel1 to DL_Use_YTDLP & (localized string " has given a warning on the URL you entered:" from table "MacYTDL")
		set theURLWarningTextLabel2 to localized string "The warning message(s) was: " from table "MacYTDL"
		set theURLWarningTextLabel3 to (localized string "You can return to the main dialog or continue to see what happens." from table "MacYTDL")
		set theWarningButtonsMainLabel to localized string "Main" from table "MacYTDL"
		set warning_quit_or_continue to button returned of (display dialog theURLWarningTextLabel1 & return & return & URL_user_entered & return & return & theURLWarningTextLabel2 & return & return & simulate_warnings & return & return & theURLWarningTextLabel3 buttons {theWarningButtonsMainLabel, theButtonContinueLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
		if warning_quit_or_continue is theButtonContinueLabel then -- <= Ignore warning - try DL - get filename from last paragraph of simulate file
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			--  set_File_Names(shellPath, YTDL_simulate_log, URL_user_entered, ABC_show_name, SBS_show_name, DL_Use_YTDLP, parallel_playlist)
			set branch_execution to my set_File_Names(shellPath, YTDL_simulate_log, URL_user_entered, ABC_show_name, SBS_show_name, DL_Use_YTDLP, parallel_playlist, number_of_URLs)
			if branch_execution is "Main" then return "Main"
			-- ************************************************************************************************************************************************************		
			
		else if warning_quit_or_continue is theWarningButtonsMainLabel then -- <= Stop and return to Main dialog
			if skip_Main_dialog is true then
				error number -128
			end if
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			return "Main"
			--	main_dialog()
			-- ************************************************************************************************************************************************************		
			
		end if
	else
		-- This is a non-warning download
		-- v1.24 add "set URL_user_entered to" because for some reason the URL_user_entered variable going forward in this handler is the old value instead of the value set in set_File_Names - affected SBS chooser cases which are workarounds
		set URL_user_entered to my set_File_Names(shellPath, YTDL_simulate_log, URL_user_entered, ABC_show_name, SBS_show_name, DL_Use_YTDLP, parallel_playlist, number_of_URLs)
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
		if URL_user_entered is "Main" then return "Main"
		-- ************************************************************************************************************************************************************		
		
	end if
	--	end if
	
	-- If user asked for subtitles, get ytdl/yt-dlp to check whether they are available - if not, warn user - if available, check against format requested - convert if different
	-- v1.21.2, added URL_user_entered to variables specifically passed - fixes SBS OnDemand subtitles error - don't know why
	if subtitles_choice is true or DL_YTAutoST is true then
		set YTDL_subtitles to my check_subtitles_download_available(shellPath, diag_Title, subtitles_choice, URL_user_entered, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, MacYTDL_custom_icon_file, DL_Use_YTDLP, theBestLabel, URL_user_entered_clean)
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
		if YTDL_subtitles is "Main" then return "Main"
		-- ************************************************************************************************************************************************************		
		
	end if
	
	-- Call the formats chooser if in settings and no conflict with other settings - chosen_formats_list is returned containing the format ids to be requested and whether merged or not
	-- Currently just return a string but, maybe it would be better to return a list - although this handler would still need the try block for separating items
	-- If branch_execution is "Skip", download will proceed without formats specified
	-- v1.26 - Decided to put get_formats_list() into separate script file - because it is only script that requires Myriad Tables Lib
	-- v1.30, 13/11/25 - skip the formats chooser if user wants to add to batch
	-- v1.30, 29/11/25 - Lock out format chooser for auto_downloads which should not be interupted by dialogs
	--	set YTDL_formats_to_download to ""
	--	if DL_formats_list is true and DL_batch_status is false then
	--		set download_filename_formats to quoted form of download_filename
	--		set chosen_formats_list to ""
	--		set formats_reported to ""
	--		-- Commented out as Formats library now used instead of loaded - v1.30, 5/11/25
	--		-- Need to get path to get_formats_list script file then run get_formats_list()
	--		-- set path_to_Formats_Chooser to (path_to_MacYTDL & "Contents:Resources:Scripts:Formats.scpt") as alias
	--		-- set run_Formats_Chooser_Handler to load script path_to_Formats_Chooser
	--		set chosen_formats_list to run_Formats_Chooser_Handler's formats_Chooser(URL_user_entered, diag_Title, theButtonCancelLabel, theButtonDownloadLabel, X_position, screen_height, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, theButtonReturnLabel, skip_Main_dialog, path_to_MacYTDL, DL_Use_YTDLP, shellPath, download_filename_formats, YTDL_credentials, window_Position, formats_reported, is_Livestream_Flag, YTDL_Use_netrc)
	--		-- Parse data returned from get_formats_list to separate out the formats list in the format "nnn+nnn" or "nnn,nnn %(format_id)s" 
	--		set AppleScript's text item delimiters to " "
	--		set branch_execution to text item 1 of chosen_formats_list
	--		set format_id_output_template to ""
	--		if branch_execution is "Main" then
	--			
	--			-- ************************************************************************************************************************************************************
	--			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
	--			return "Main"
	--			--	main_dialog()
	--			-- ************************************************************************************************************************************************************		
	--			
	--		else if branch_execution is "Skip" then
	--			set YTDL_formats_to_download to ""
	--		else if branch_execution is "Download" then
	--			try
	--				set YTDL_formats_to_download to " --format " & text item 2 of chosen_formats_list
	--			end try
	--			if YTDL_formats_to_download contains "," then
	--				set format_id_output_template to text item 3 of chosen_formats_list -- Contains "%(format_id)s" if user has asked to not merge but to download and retain each format
	--			end if
	--		end if
	--		set AppleScript's text item delimiters to ""
	--		if format_id_output_template is not "" then
	--			set YTDL_output_template to my replace_chars(YTDL_output_template, ".%(ext)s", "." & format_id_output_template & ".%(ext)s")
	--		end if
	--	end if
	
	-- Set the YTDL settings into one variable - makes it easier to maintain - ensure spaces are where needed - quoted to enable passing to Monitor script
	-- v1.30, 29/11/25 - Removed YTDL_formats_to_download - not relevant to auto_download
	--	set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_recode_remux & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_Thumbnail_Write & YTDL_Thumbnail_Embed & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & " " & YTDL_formats_to_download & " " & YTDL_Use_netrc & " ")
	set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_recode_remux & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_Thumbnail_Write & YTDL_Thumbnail_Embed & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & " " & YTDL_Use_netrc & " ")
	
	-- Does user want to be able to delete existing files – by default YTDL/yt-dlp refuse to delete existing + continue partially completed downloads
	-- Beware ! This section doesn't cope with part download files which are left to klag YTDL - they should be automatically deleted but, anything can happen
	-- THIS HAS BUGS - SOMETIMES DOESN'T FIND EXISTING FILES
	if DL_over_writes is true then
		set downloadsFolder_Path_posix to (POSIX file downloadsFolder_Path)
		set downloadsFolder_Path_alias to downloadsFolder_Path_posix as alias
		
		-- Look for file of same name in downloads folder - use file names saved in the simulate file - there can be one or a number	
		-- But, first check whether it's an ABC show page - because the simulate result for those comes from the set_File_Names handler - same for SBS
		set search_for_download to {}
		
		if ABC_show_indicator is "Yes" then
			set download_filename_new_plain to my replace_chars(download_filename_new, "_", " ")
			repeat with each_filename in (get paragraphs of download_filename_new_plain)
				set each_filename to each_filename as text
				if each_filename contains "/" then
					set offset_to_file_name to (my last_offset(each_filename, "/")) + 2
					set each_filename to text offset_to_file_name thru end of each_filename
				end if
				set length_each_filename to count words of each_filename
				if length_each_filename is not 0 then
					try
						tell application "Finder"
							set search_for_download to (name of files in downloadsFolder_Path_alias where name contains each_filename)
						end tell
					end try
					if search_for_download is not {} then
						set theABCShowExistsLabel1 to localized string "A file for the ABC show" from table "MacYTDL"
						set theABCShowExistsLabel2 to localized string "already exists." from table "MacYTDL"
						set theABCShowExistsLabel3 to localized string "Do you want to continue anyway, download with a different name or stop and return to the main dialog ?" from table "MacYTDL"
						set theABCShowExistsButtonOverwriteLabel to localized string "Overwrite" from table "MacYTDL"
						set theABCShowExistsButtonNewnameLabel to localized string "New name" from table "MacYTDL"
						set overwrite_continue_choice to button returned of (display dialog theABCShowExistsLabel1 & " \"" & each_filename & "\" " & theABCShowExistsLabel2 & return & return & theABCShowExistsLabel3 buttons {theABCShowExistsButtonOverwriteLabel, theABCShowExistsButtonNewnameLabel, theButtonReturnLabel} default button 3 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
						if overwrite_continue_choice is theABCShowExistsButtonOverwriteLabel then
							-- Have to manually remove existing file because YTDL always refuses to overwrite
							set search_for_download to search_for_download as text
							set file_to_delete to quoted form of (POSIX path of (downloadsFolder_Path & "/" & search_for_download))
							do shell script "mv " & file_to_delete & " ~/.trash/"
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_recode_remux & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & " " & YTDL_Use_netrc & " ")
						else if overwrite_continue_choice is theABCShowExistsButtonNewnameLabel then
							set YTDL_output_template_new to my replace_chars(YTDL_output_template, ".%(ext)s", "-2.%(ext)s")
							set set_new_download_filename to text 1 thru -5 of download_filename_new
							set download_filename_new to my replace_chars(download_filename_new, set_new_download_filename, set_new_download_filename & "-2")
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_recode_remux & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template_new & " " & YTDL_QT_Compat & " " & YTDL_Use_netrc & " ")
						else if overwrite_continue_choice is theButtonReturnLabel then
							if DL_auto is false then
								
								-- ************************************************************************************************************************************************************
								-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
								return "Main"
								-- my main_dialog()
								-- ************************************************************************************************************************************************************		
								
							else
								error number -128
							end if
						end if
					end if
				end if
			end repeat
			-- Need to revert download_filename_new to just show_name to be passed for the Monitor and Adviser dialogs - but only for the multiple downloads !!!
			if (count of paragraphs of download_filename_new_plain) is greater than 1 then
				set download_filename_new to ABC_show_name
			end if
		else if SBS_show_indicator is "Yes" then
			set download_filename_new_plain to my replace_chars(download_filename_new, "_", " ")
			repeat with each_filename in (get paragraphs of download_filename_new_plain)
				set each_filename to each_filename as text
				if each_filename contains "/" then
					set offset_to_file_name to (my last_offset(each_filename, "/")) + 2
					set each_filename to text offset_to_file_name thru end of each_filename
				end if
				set length_each_filename to count words of each_filename
				if length_each_filename is not 0 then
					try
						tell application "Finder"
							set search_for_download to (name of files in downloadsFolder_Path_alias where name contains each_filename)
						end tell
					end try
					if search_for_download is not {} then
						set theShowExistsLabel1 to localized string "A file for the SBS show" from table "MacYTDL"
						set theShowExistsLabel2 to localized string "already exists." from table "MacYTDL"
						set theShowExistsLabel3 to localized string "Do you want to continue anyway, download with a different name or stop and return to the main dialog ?" from table "MacYTDL"
						set theShowExistsButtonOverwriteLabel to localized string "Overwrite" from table "MacYTDL"
						set theShowExistsButtonNewnameLabel to localized string "New name" from table "MacYTDL"
						set overwrite_continue_choice to button returned of (display dialog theShowExistsLabel1 & " \"" & each_filename & "\" " & theShowExistsLabel2 & return & return & theShowExistsLabel3 buttons {theShowExistsButtonOverwriteLabel, theShowExistsButtonNewnameLabel, theButtonReturnLabel} default button 3 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
						if overwrite_continue_choice is theShowExistsButtonOverwriteLabel then
							-- Have to manually remove existing file because YTDL always refuses to overwrite
							set search_for_download to search_for_download as text
							set file_to_delete to quoted form of (POSIX path of (downloadsFolder_Path & "/" & search_for_download))
							do shell script "mv " & file_to_delete & " ~/.trash/"
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_recode_remux & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & " " & YTDL_Use_netrc & " ")
						else if overwrite_continue_choice is theShowExistsButtonNewnameLabel then
							set YTDL_output_template_new to my replace_chars(YTDL_output_template, ".%(ext)s", "-2.%(ext)s")
							set set_new_download_filename to text 1 thru -5 of download_filename_new
							set download_filename_new to my replace_chars(download_filename_new, set_new_download_filename, set_new_download_filename & "-2")
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_recode_remux & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template_new & " " & YTDL_QT_Compat & " " & YTDL_Use_netrc & " ")
						else if overwrite_continue_choice is theButtonReturnLabel then
							if DL_auto is false then
								
								-- ************************************************************************************************************************************************************
								-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
								return "Main"
								-- my main_dialog()
								-- ************************************************************************************************************************************************************		
								
							else
								error number -128
							end if
						end if
					end if
				end if
			end repeat
			-- Need to revert download_filename_new to just show_name to be passed for the Monitor and Adviser dialogs - but only for the multiple downloads !!!
			if (count of paragraphs of download_filename_new_plain) is greater than 1 then
				set download_filename_new to SBS_show_name
			end if
		else
			repeat with each_filename in (get paragraphs of YTDL_simulate_log)
				set each_filename to each_filename as text
				if each_filename contains "/" then
					set offset_to_file_name to (my last_offset(each_filename, "/")) + 2
					set each_filename to text offset_to_file_name thru end of each_filename
				end if
				set length_each_filename to count words of each_filename
				if length_each_filename is not 0 then
					try
						tell application "Finder"
							set search_for_download to (name of files in downloadsFolder_Path_alias where name contains each_filename)
						end tell
					end try
					if search_for_download is not {} then
						set theShowExistsWarningTextLabel1 to localized string "The file" from table "MacYTDL"
						set theShowExistsWarningTextLabel2 to localized string "already exists." from table "MacYTDL"
						set theShowExistsWarningTextLabel3 to localized string "Do you want to continue anyway, download with a different name or stop and return to the main dialog ?" from table "MacYTDL"
						set theShowExistsButtonOverwriteLabel to localized string "Overwrite" from table "MacYTDL"
						set theShowExistsButtonNewnameLabel to localized string "New name" from table "MacYTDL"
						set overwrite_continue_choice to button returned of (display dialog theShowExistsWarningTextLabel1 & " \"" & each_filename & "\" " & theShowExistsWarningTextLabel2 & return & return & theShowExistsWarningTextLabel3 buttons {theShowExistsButtonOverwriteLabel, theShowExistsButtonNewnameLabel, theButtonReturnLabel} default button 3 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
						if overwrite_continue_choice is theShowExistsButtonOverwriteLabel then
							-- Have to manually remove existing file because YTDL always refuses to overwrite
							set search_for_download to search_for_download as text
							set file_to_delete to quoted form of (POSIX path of (downloadsFolder_Path & "/" & search_for_download))
							do shell script "mv " & file_to_delete & " ~/.trash/"
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_recode_remux & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & " " & YTDL_Use_netrc & " ")
						else if overwrite_continue_choice is theShowExistsButtonNewnameLabel then
							set YTDL_output_template_new to my replace_chars(YTDL_output_template, ".%(ext)s", "-2.%(ext)s")
							set set_new_download_filename to text 1 thru -5 of download_filename_new
							set download_filename_new to my replace_chars(download_filename_new, set_new_download_filename, set_new_download_filename & "-2")
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_recode_remux & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template_new & " " & YTDL_QT_Compat & " " & YTDL_Use_netrc & " ")
						else if overwrite_continue_choice is theButtonReturnLabel then
							if DL_auto is false then
								
								-- ************************************************************************************************************************************************************
								-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
								return "Main"
								-- my main_dialog()
								-- ************************************************************************************************************************************************************		
								
							else
								error number -128
							end if
						end if
					end if
				end if
			end repeat
		end if
	end if
	-- ************************************************************************************************************************************************************
	-- This is the end of the over-write section
	-- ************************************************************************************************************************************************************
	
	
	-- Need to revert download_filename_new to just show_name to be passed for the Monitor and Adviser dialogs - but only for the multiple downloads !!!
	-- Added in v1.24 - don't know why I didn't notice a problem with Monitor as this was needed for years !
	-- v1.26 - Add parallel download flag to download_filename_new - Monitor does all heavy lifting to initiate parallel downloads from iView
	set download_filename_new_plain to my replace_chars(download_filename_new, "_", " ")
	
	-- v1.30, 29/11/25 - Commented out at iView and SBS chooser not to interrupt auto download
	--	if ABC_show_indicator is "Yes" then
	--		if (count of paragraphs of download_filename_new_plain) is greater than 1 then
	--			set download_filename_new to ABC_show_name
	--			if DL_Parallel is true then
	--				set download_filename_new to download_filename_new & "$$"
	--			end if
	--		end if
	--	end if
	--	if SBS_show_indicator is "Yes" then
	--		if (count of paragraphs of download_filename_new_plain) is greater than 1 then
	--			set download_filename_new to SBS_show_name
	--			if DL_Parallel is true then
	--				set download_filename_new to download_filename_new & "$$"
	--			end if
	--		end if
	--	end if
	
	-- v1.30, 29/11/25 - Batches not relevant to auto-download
	-- Add the URL and file name to the batch file if requested
	-- This is done after simulate, ABC/SBS chooser and Formats Chooser
	-- Returns back to main_dialog() so, none of the following code is processed
	--	if DL_batch_status is true then
	--		if is_Livestream_Flag is "True" then
	--			set theURLisLiveLabel to localized string "Sorry, live streams cannot be added for batch download." from table "MacYTDL"
	--			display dialog theURLisLiveLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
	--			if skip_Main_dialog is true then
	--				error number -128
	--			end if
	--			
	--			-- ************************************************************************************************************************************************************
	--			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
	--			return "Main"
	--			-- my main_dialog()
	--			-- ************************************************************************************************************************************************************		
	--			
	--		end if
	--		
	--		-- ************************************************************************************************************************************************************
	--		-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
	--		--  add_To_Batch(URL_user_entered, download_filename, download_filename_new, YTDL_remux_format)
	--		set branch_execution to run_Batch_Handlers's add_To_Batch(URL_user_entered, download_filename, download_filename_new, YTDL_recode_remux, MacYTDL_preferences_path, diag_Title, theButtonOKLabel, MacYTDL_custom_icon_file)
	--		if branch_execution is "Main" then return "Main" -- add_To_Batch always returns to Main
	--		-- ************************************************************************************************************************************************************		
	--		
	--		-- add_To_Batch(URL_user_entered, download_filename)  -- Changed on 10/2/23
	--		-- add_To_Batch(URL_user_entered, download_filename_new, YTDL_remux_format) - v1.26 - need download_filname for multiple URL cases
	--	end if
	
	-- Prepare to call on the download Monitor - first get Monitor script location -- Monitor-bundle.scptd
	-- Changed location of Monitor script - v1.30, 5/11/25
	-- set myMonitorScriptAsString to quoted form of ((POSIX path of path_to_MacYTDL) & "Contents/Resources/Scripts/Monitor.scpt")
	set myMonitorScriptAsString to quoted form of ((POSIX path of path_to_MacYTDL) & "Contents/Resources/Script Libraries/Monitor.scptd")
	
	-- Get number of current downloads underway - each download spawns 2 osascript processes - send to monitor.scpt for positioning monitor dialogs
	try -- In a try block to catch error of nil pids returned
		set monitor_dialogs_list to do shell script "pgrep -f osascript"
		set monitor_dialog_position to ((count of paragraphs in monitor_dialogs_list) / 2) + 1
	on error
		set monitor_dialog_position to 1
	end try
	
	-- Pull together all the parameters to be sent to the Monitor script
	-- Set URL to quoted form so that Monitor will parse myParams correctly when URLs come from the Get_ABC_Episodes and Get_SBS_Episodes handlers - but not for single episode iView show pages
	if ABC_show_name is not "" or SBS_show_name is not "" then
		set URL_user_entered to quoted form of URL_user_entered
	end if
	
	-- Put diag title, file and path names into quotes as they are not passed to Monitor correctly when they contain apostrophes or spaces
	set download_filename to quoted form of download_filename
	set download_filename_new to quoted form of download_filename_new
	set YTDL_log_file to quoted form of YTDL_log_file
	set YTDL_simulate_log to text 1 thru -2 of YTDL_simulate_log
	set YTDL_simulate_log to quoted form of YTDL_simulate_log
	set diag_Title_quoted to quoted form of diag_Title
	set YTDL_TimeStamps_quoted to quoted form of YTDL_TimeStamps
	
	-- Form up parameters for the following do shell script
	set my_params to quoted form of downloadsFolder_Path & " " & quoted form of MacYTDL_preferences_path & " " & YTDL_TimeStamps_quoted & " " & ytdl_settings & " " & URL_user_entered & " " & YTDL_log_file & " " & download_filename & " " & download_filename_new & " " & quoted form of MacYTDL_custom_icon_file_posix & " " & monitor_dialog_position & " " & YTDL_simulate_log & " " & diag_Title_quoted & " " & is_Livestream_Flag & " " & screen_width & " " & screen_height & " " & DL_Use_YTDLP & " " & quoted form of path_to_MacYTDL & " " & DL_Delete_Partial & " " & ADL_Clear_Batch
	
	-- v1.30, 29/11/25 - Lock out Show Settings as auto-download not to be interrupted by dialogs
	---- Show current download settings if user has specified that in Settings
	--	if DL_Show_Settings is true then
	--		set branch_execution to my show_settings(YTDL_subtitles, DL_Remux_original, DL_YTDL_auto_check, DL_STEmbed, DL_audio_only, YTDL_description, DL_Limit_Rate, DL_over_writes, DL_Thumbnail_Write, DL_verbose, DL_Thumbnail_Embed, DL_Add_Metadata, DL_Use_Proxy, DL_Use_Cookies, DL_Use_Custom_Template, DL_Use_Custom_Settings, DL_Remux_format, DL_TimeStamps, DL_Use_YTDLP, DL_Parallel, DL_discard_URL, DL_Dont_Use_Parts, DL_No_Warnings, YTDL_version, folder_chosen, theButtonQuitLabel, theButtonCancelLabel, theButtonDownloadLabel, DL_Show_Settings, MacYTDL_prefs_file, MacYTDL_custom_icon_file_posix, diag_Title, YTDL_Use_netrc, DL_Remux_Recode)
	--		
	--		-- ************************************************************************************************************************************************************
	--		-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
	--		if branch_execution is "Main" then return "Main"
	--		--  main_dialog()
	--		-- ************************************************************************************************************************************************************		
	--		
	--		if branch_execution is "Settings" then set branch_execution to set_settings()
	--		if branch_execution is "Main" then return "Main" -- v1.30, 25/11/25 - User exits Settings and returns to Main instead of going to download
	--		if branch_execution is "Quit" then quit_MacYTDL()
	--	end if
	
	
	-- PRODUCTION CALL - Call the download Monitor script which will run as a separate process and return so Main Dialog can be re-displayed - thus user can start any number of downloads
	do shell script "osascript -s s " & myMonitorScriptAsString & " " & my_params & " " & " > /dev/null 2> /dev/null &"
	
	--	try
	--		TESTING CALL - Call the download Monitor script for testing - this formulation gets any errors back from Monitor, but holds execution until Monitor dialog is dismissed
	-- do shell script "osascript -s s " & myMonitorScriptAsString & " " & my_params & " 2>&1"
	--	on error errMSG
	--		display dialog "errMSG: " & errMSG
	--	end try
	
	
	-- After download, reset ABC & SBS URLs, show name and number_ABC_SBS_episodes so that correct file name is used for next download	
	-- v1.26 - Decided to change behaviour - retain/discard URL after a download - it's the user's choice
	if DL_discard_URL is true then
		set URL_user_entered to ""
		set URL_user_entered_clean to ""
	end if
	--	set ABC_show_name to ""
	--	set SBS_show_name to ""
	--	set SBS_show_URLs to ""
	--	set ABC_show_URLs to ""
	--	set number_ABC_SBS_episodes to 0
	-- set the clipboard to ""
	
	-- This is needed so using Service doesn't invoke the Main Dialog
	if skip_Main_dialog is false then
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
		return "Main"
		-- my main_dialog()
		-- ************************************************************************************************************************************************************		
		
	end if
	
end download_video


------------------------------------------------------------
--
-- 	Try to get correct file names for use elsewhere
--
------------------------------------------------------------
on set_File_Names(shellPath, YTDL_simulate_log, URL_user_entered, ABC_show_name, SBS_show_name, DL_Use_YTDLP, parallel_playlist, number_of_URLs)
	
	-- Set download_filename_new which is used to show a name in the Monitor dialog and forms basis for log file name
	-- Set download_filename which is used by Adviser to open downloaded file (called download_filename_monitor)
	-- Reformat file name and add to name of log files - converting spaces to underscores to reduce need for quoting throughout code
	
	-- v1.30, 17/11/25 - Commented out as number_of_URLs variable is available earlier in download_video()
	--	set AppleScript's text item delimiters to " "
	--	set number_of_URLs to number of text items in URL_user_entered
	--	set AppleScript's text item delimiters to ""
	
	set num_paragraphs_log to count of paragraphs of YTDL_simulate_log
	
	-- Get date and time so it can be added to log file name
	set download_date_time to my get_Date_Time()
	
	-- First, look for non-iView show pages (but iView non-error single downloads are included)
	-- Trim extension off download filename that is in the simulate file - not implemented as it involves lots of changes to the following code
	--set download_filename_no_ext to text 1 thru ((YTDL_simulate_log's length) - (offset of "." in (the reverse of every character of YTDL_simulate_log) as text)) of YTDL_simulate_log
	if ABC_show_name is "" and SBS_show_name is "" then -- not an ABC or SBS show page
		if number_of_URLs is 1 and parallel_playlist is false then -- Single file download or playlist to be downloaded serially
			set download_filename to YTDL_simulate_log
			if YTDL_simulate_log does not contain "WARNING:" and YTDL_simulate_log does not contain "ERROR:" then --<= A single file or playlist download non-error and non-warning (iView and non-iView)
				if num_paragraphs_log is 2 then --<= A single file download (iView and non-iView) - need to trim ".mp4<para>" from end of file (which is a single line containing one file name)
					if YTDL_simulate_log contains "/" then
						set offsetOfLastSlash to (my last_offset(YTDL_simulate_log, "/")) + 2
						set download_filename_only to text offsetOfLastSlash thru -2 of YTDL_simulate_log
						set download_filename_trimmed to text offsetOfLastSlash thru ((YTDL_simulate_log's length) - (offset of "." in (the reverse of every character of YTDL_simulate_log) as text)) of YTDL_simulate_log
					else
						set download_filename_only to text 1 thru -2 of YTDL_simulate_log
						set download_filename_trimmed to text 1 thru ((YTDL_simulate_log's length) - (offset of "." in (the reverse of every character of YTDL_simulate_log) as text)) of YTDL_simulate_log
					end if
					set download_filename_trimmed to my replace_chars(download_filename_trimmed, " ", "_")
					set download_filename_new to my replace_chars(download_filename_only, " ", "_")
					set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_trimmed & "-" & download_date_time & ".txt"
				else --<= Probably a Youtube playlist - but beware as there can be playlists on other sites
					if playlist_Name is not "" then
						set download_filename_new to playlist_Name
						set download_filename_new to my replace_chars(download_filename_new, " ", "_")
					else
						set download_filename_new to "the-playlist"
					end if
					set download_filename to YTDL_simulate_log
					set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_new & "-" & download_date_time & ".txt"
				end if
			else if YTDL_simulate_log contains "WARNING:" and YTDL_simulate_log does not contain "ERROR:" then --<= Single file download or playlist but simulate.txt contains WARNING(S)  (iView and non-iView) - need to trim warning paras and ".mp4<para>" from end of simulate log - but Futurewarning warnings have reverse layout in simulate log
				if YTDL_simulate_log contains "FutureWarning:" then
					set YTDL_simulate_log to paragraph 1 of YTDL_simulate_log
				else
					set numParas to count paragraphs in YTDL_simulate_log
					-- Assumes that 1st para is a warning and there are no others
					set YTDL_simulate_log to paragraph (numParas - 1) of YTDL_simulate_log
				end if
				set download_filename to YTDL_simulate_log
				if text -1 thru -6 of YTDL_simulate_log contains "." then
					set download_filename_trimmed to text 1 thru ((YTDL_simulate_log's length) - (offset of "." in (the reverse of every character of YTDL_simulate_log) as text)) of YTDL_simulate_log
				else
					set download_filename_trimmed to download_filename
				end if
				-- If it's a playlist, put playlist_name into download_filename_new which is passed to Monitor and into YTDL_log_file which is the name of the log file
				if playlist_Name is not "" then
					set download_filename_new to playlist_Name
					set download_filename_new to my replace_chars(download_filename_new, " ", "_")
					set download_filename_trimmed to download_filename_new
				else
					set download_filename_new to my replace_chars(download_filename, " ", "_")
					set download_filename_trimmed to my replace_chars(download_filename_trimmed, " ", "_")
				end if
				set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_trimmed & "-" & download_date_time & ".txt"
			else if YTDL_simulate_log contains "ERROR:" then --<= Single file download or playlist but simulate.txt contains ERROR (iView and non-iView) - need a generic file name for non-playlists
				if playlist_Name is not "" then
					set download_filename_new to playlist_Name
					set download_filename_new to my replace_chars(download_filename_new, " ", "_")
				else
					set download_filename_new to "the-error-download"
				end if
				set download_filename to YTDL_simulate_log
				set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_new & "-" & download_date_time & ".txt"
			end if
			
			
		else
			-- This is a multiple file (iView and non-iView) download - don't distinguish between iView and others - covers warning and non-warning cases also parallel downloads
			
			-- *******************************************************************************************************************************************************
			-- v1.26 - Building details needed for parallel downloads - form up records for download_filename_new variable which will contain everything needed for parallel downloads
			-- DL_parallel is set using user's preference
			-- Playlists probably have 1 URL and so need a separate if/end if block  - anyway, simulate created above already has data needed for parallel downloads
			-- *******************************************************************************************************************************************************
			if DL_Parallel is true and parallel_playlist is false then
				set download_filename to YTDL_simulate_log
				set URL_user_entered_for_parallel_multiple to text 2 thru -2 of URL_user_entered -- Need to remove single quotes around URLs
				set download_filename_new to ""
				set URL_counter to 1
				-- Need to remove warning paragraphs from simulate log while forming up file names with URLs - warnings can be anywhere but usually before the name of the related video
				set number_paragraphs to ((count of paragraphs of YTDL_simulate_log) - 1)
				repeat with x from 1 to number_paragraphs
					if paragraph x of YTDL_simulate_log does not contain "WARNING:" then
						set download_filename_full to (paragraph x of YTDL_simulate_log)
						-- Trying to remove colons and spaces from file names as it might cause macOS trouble - although it hasn't up till now - the strange small colon DOES cause issues
						-- Not sure whether this would make a mess of some URLs
						set download_filename_full to my replace_chars(download_filename_full, " ", "_")
						set download_filename_full to my replace_chars(download_filename_full, ":", "_-") -- Not sure whether this would make a mess of URLs
						set download_filename_full to my replace_chars(download_filename_full, "：", "_-")
						-- Need to trim off ".[extension]" from file name before adding to name of log file
						set download_filename_trimmed to text 1 thru ((download_filename_full's length) - (offset of "." in (the reverse of every character of download_filename_full) as text)) of download_filename_full
						set AppleScript's text item delimiters to {" "} -- There are spaces between the URLs in URL_user_entered_for_parallel_multiple
						set URL_user_entered_for_parallel to (text item URL_counter of URL_user_entered_for_parallel_multiple)
						set AppleScript's text item delimiters to {""} -- This is needed to prevent "reverse of" adding a space between each character as it's a list being coerced to text
						set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_trimmed & "-" & download_date_time & ".txt"
						set download_filename_new to download_filename_new & download_filename_full & "##" & URL_user_entered_for_parallel & "##" & YTDL_log_file & return
						set URL_counter to URL_counter + 1 -- Unlike "x", URL_counter has to be manually incremented
					end if
				end repeat
				
				--display dialog "download_filename_full: " & download_filename_full & return & return & "URL_user_entered_for_parallel_multiple: " & URL_user_entered_for_parallel_multiple & return & return & "download_filename_new: " & download_filename_new
				
				-- This is code is used if user doesn't want parallel downloads i.e. serial				
			else if DL_Parallel is false then
				set download_filename to YTDL_simulate_log
				set download_filename_new to "the multiple videos"
				set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-Multiple_download_on-" & download_date_time & ".txt"
			end if
		end if
		-- User wants parallel download of a playlist - download_filename_new needs to contain playlist name as well as URL, file name and log file name - YTDL_simulate_log has all the data needed
		if parallel_playlist is true then
			set download_filename to "Parallel downloads"
			set download_filename_new to ""
			-- Need to exclude warning paragraphs in simulate log while forming up file names with URLs - warnings are usually at the beginning of the simulate log
			-- v1.27 – Need to exclude errors – private YouTube videos especially can cause yt-dlp to report an error which makes a muck of the simulate log - crude change made in a hurry
			set number_paragraphs to ((count of paragraphs of YTDL_simulate_log) - 1)
			repeat with x from 1 to number_paragraphs
				if paragraph x of YTDL_simulate_log does not contain "WARNING:" then
					set download_filename_full to (paragraph x of YTDL_simulate_log)
					-- Parse out components needed to send to Monitor
					set AppleScript's text item delimiters to {"##"}
					set playlist_Name to text item 1 of download_filename_full
					if download_filename_full does not contain "ERROR: " then
						set URL_user_entered_for_parallel to text item 2 of download_filename_full
						set parallel_download_filename to text item 3 of download_filename_full
					end if
					set AppleScript's text item delimiters to {""}
					
					-- Trying to remove colons and spaces from file names as it might cause macOS trouble = the strange small colon and the double // DO cause issues
					set parallel_download_filename to my replace_chars(parallel_download_filename, " ", "_")
					set parallel_download_filename to my replace_chars(parallel_download_filename, ":", "_") -- Not sure whether this would make a mess of URLs
					set parallel_download_filename to my replace_chars(parallel_download_filename, "：", "_")
					set parallel_download_filename to my replace_chars(parallel_download_filename, "//", "-")
					
					-- Need to trim off ".[extension]" from file name before adding to name of log file
					set download_filename_trimmed to text 1 thru ((parallel_download_filename's length) - (offset of "." in (the reverse of every character of parallel_download_filename) as text)) of parallel_download_filename
					set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_trimmed & "-" & download_date_time & ".txt"
					
					-- Add a unique delimiter to signify this is a playlist parallel download - used by Monitor
					set download_filename_new to download_filename_new & playlist_Name & "#$" & parallel_download_filename & "##" & URL_user_entered_for_parallel & "##" & YTDL_log_file & return
				end if
			end repeat
			
			--display dialog "download_filename_full: " & download_filename_full & return & return & "URL_user_entered_for_parallel_multiple: " & URL_user_entered_for_parallel_multiple & return & return & "download_filename_new: " & download_filename_new
		end if
		-- *******************************************************************************************************************************************************
		
	else if ABC_show_name is not "" then
		set download_filename to ABC_show_name
		set download_filename_new to my replace_chars(download_filename, " ", "_")
		set ABC_show_name_underscore to my replace_chars(ABC_show_name, " ", "_")
		set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & ABC_show_name_underscore & "-" & download_date_time & ".txt"
		
		-- Second, look for iView show page downloads - this currently simulates on the playlist URLs
		--		if number_ABC_SBS_episodes is 0 then
		--			-- Look for iView single show page downloads - no episodes are shown on these pages - so, have to simulate to get file name - there is usually no separate series name available as the show is also the series
		--			set download_filename to last paragraph of (do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & URL_user_entered & " " & YTDL_output_template)
		--			set download_filename_new to my replace_chars(download_filename, " ", "_")
		--			set download_filename_trimmed to text 1 thru ((download_filename's length) - (offset of "." in (the reverse of every character of download_filename) as text)) of download_filename
		--			set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_trimmed & "-" & download_date_time & ".txt"
		--		else if number_ABC_SBS_episodes is 1 then
		--			-- Look for iView single episode page downloads - just one episode is shown on these pages - so, have to simulate to get file name
		--			set download_filename to text 1 thru -1 of (do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & URL_user_entered & " " & YTDL_output_template)
		--			set download_filename_new to my replace_chars(download_filename, " ", "_")
		--			-- The following line is odd as the simulate log contains lots of rubbish - don't understand how this passed testing
		--			--	set download_filename_trimmed to text 1 thru ((YTDL_simulate_log's length) - (offset of "." in (the reverse of every character of YTDL_simulate_log) as text)) of YTDL_simulate_log
		--			set download_filename_trimmed to text 1 thru ((download_filename_new's length) - (offset of "." in (the reverse of every character of download_filename_new) as text)) of download_filename_new
		--			set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_trimmed & "-" & download_date_time & ".txt"
		--		else
		--			-- The ABC_show_URLs variable is currently not defined
		--			-- Look for iView episode show page downloads - two or more episodes are shown on web page and so ABC_show_name is populated in download_video handler above
		--			set download_filename to text 1 thru -1 of (do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & ABC_show_URLs & " " & YTDL_output_template)
		--			set download_filename_new to my replace_chars(download_filename, " ", "_")
		--			set ABC_show_name_underscore to my replace_chars(ABC_show_name, " ", "_")
		--			set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & ABC_show_name_underscore & "-" & download_date_time & ".txt"			
		--		end if
	else if SBS_show_name is not "" then
		-- Second, look for SBS show page downloads (which are all ERROR: cases)	
		if number_ABC_SBS_episodes is 1 then
			-- Look for SBS single episode page downloads - just one episode is shown on these pages - so, have to simulate to get file name
			-- *******************************************************************************************************************************************************
			-- v1.24 - added try block as SBS changes can cause a crash - can use same workaround code as above for a single file download
			try
				set download_filename to text 1 thru -1 of (do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & URL_user_entered & " " & YTDL_output_template)
			on error errMSG
				if errMSG contains "ERROR: [ThePlatform]" or errMSG contains "HTTP Error 403: Forbidden" then
					set check_URL_ID to last word of URL_user_entered
					set URL_user_entered to ("https://www.sbs.com.au/api/v3/video_smil?id=" & check_URL_ID)
					set SBS_show_name to "This is a bug URL"
					set number_ABC_SBS_episodes to 1
					set SBS_workaround_page to do shell script "curl " & URL_user_entered
					if SBS_workaround_page contains "abstract" then
						set AppleScript's text item delimiters to {"title=\"", "\" abstract="}
						set download_filename to (text item 2 of SBS_workaround_page) & ".mp4"
					else
						set AppleScript's text item delimiters to {"title=\"", "\" copyright="}
						set download_filename to (text item 2 of SBS_workaround_page) & ".mp4"
					end if
					set AppleScript's text item delimiters to ""
					set download_filename_new to my replace_chars(download_filename, " ", "_")
					set download_date_time to my get_Date_Time()
					set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_new & "-" & download_date_time & ".txt"
					-- if YTDL_remux_format contains "recode" then set YTDL_remux_format to ""  -- Poinless as YTDL_remux_format is not sent to this handler and is not global
					set YTDL_output_template to "-o '" & download_filename_new & ".%(ext)s'"
				else
					set theSBSsimulateFailedLabel to localized string "Something went wrong trying to download from SBS. The error was: " from table "MacYTDL"
					display dialog (theSBSsimulateFailedLabel & return & return & errMSG) buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
					
					-- ************************************************************************************************************************************************************
					-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
					return "Main"
					-- my main_dialog()
					-- ************************************************************************************************************************************************************		
					
				end if
			end try
			set download_filename_new to my replace_chars(download_filename, " ", "_")
			-- *******************************************************************************************************************************************************
			-- v1.24 - Cases where a single episode comes from SBS Chooser need to have the log file name formed differently
			if YTDL_simulate_log contains "ERROR: Unsupported URL: https://www.sbs.com.au/ondemand" then
				set download_filename_trimmed to download_filename_new
				set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_trimmed & "-" & download_date_time & ".txt"
			else
				set download_filename_trimmed to text 1 thru ((YTDL_simulate_log's length) - (offset of "." in (the reverse of every character of YTDL_simulate_log) as text)) of YTDL_simulate_log
				set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_trimmed & "-" & download_date_time & ".txt"
			end if
		else
			
			-- *******************************************************************************************************************************************************
			-- v1.24 - added try block as SBS changes can cause a crash - can't use multiple file names in output template - use autonumber instead
			try
				set download_filename to text 1 thru -1 of (do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & SBS_show_URLs & " " & YTDL_output_template)
			on error errMSG
				if errMSG contains "ERROR: [ThePlatform]" or errMSG contains "HTTP Error 403: Forbidden" then
					set URL_user_entered to my replace_chars(URL_user_entered, "https://www.sbs.com.au/ondemand/watch/", "https://www.sbs.com.au/api/v3/video_smil?id=")
					set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & SBS_show_name & "-" & download_date_time & ".txt"
					--	if YTDL_remux_format contains "recode" then set YTDL_remux_format to ""
					set YTDL_output_template to "-o '" & SBS_show_name & "-%(autonumber)s.%(ext)s'"
				else
					set theSBSsimulateFailedLabel to localized string "Something went wrong trying to download from SBS. The error was: " from table "MacYTDL"
					display dialog (theSBSsimulateFailedLabel & return & return & errMSG) buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
					
					-- ************************************************************************************************************************************************************
					-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
					return "Main"
					-- my main_dialog()
					-- ************************************************************************************************************************************************************		
					
				end if
			end try
			
			-- Setting download_filename_new and download_filename to SBS_show_name as can't do a simulate to get file name  - why do a simulate if it's not used ?
			-- v1.26 => Decided to treat SBS same as iView
			--			set download_filename_new to my replace_chars(SBS_show_name, " ", "_")
			--			set download_filename to SBS_show_name
			set download_filename_new to my replace_chars(download_filename, " ", "_")
			set SBS_show_name_underscore to my replace_chars(SBS_show_name, " ", "_")
			set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & SBS_show_name_underscore & "-" & download_date_time & ".txt"
		end if
		-- *******************************************************************************************************************************************************
	end if
	
	-- Make sure there are no colons in the file name - can happen with iView and maybe others - ytdl converts colons into "_-" so, this must also
	-- 1.26 - commented out because of conflict with parallel processing code
	--	set download_filename_new to my replace_chars(download_filename_new, ":", "_-")
	
	-- **************** Dialog to show variable values set by this handler - set up for iView URLs
	-- display dialog "num_paragraphs_log: " & num_paragraphs_log & return & return & "number_of_URLs: " & number_of_URLs & return & return & "URL_user_entered: " & URL_user_entered & return & return & "ABC_show_name: " & ABC_show_name & return & return & "number_ABC_SBS_episodes: " & number_ABC_SBS_episodes & return & return & "download_filename_new: " & download_filename_new & return & return & "YTDL_log_file: " & YTDL_log_file
	-- ***************** 
	
	-- 1.24 – Added this return statement as for some reason the value in URL_user_entered set in this handler was being ignored in download_video() for SBS Chooser workaround cases
	-- Might be able to remove this soon as SBS workaround no longer in use
	return URL_user_entered
	
end set_File_Names



-----------------------------------------------------------------------
--
-- 		Check subtitles are available and in desired language
--
-----------------------------------------------------------------------
-- Handler to check that requested subtitles are available and apply conversion if not - called by download_video() when user requests subtitles or auto-subtitles
-- Might not need the duplication in this handler - leave till a later release - Handles ABC, SBS show URL and multiple URLs somewhat
on check_subtitles_download_available(shellPath, diag_Title, subtitles_choice, URL_user_entered, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, MacYTDL_custom_icon_file, DL_Use_YTDLP, theBestLabel, URL_user_entered_clean)
	-- Initialise the subtitles parameter - will go into the YTDL call - will merging settings for author and auto generated STs - Initialise local vars for use in this handler leaving user's settings unchanged
	set YTDL_subtitles to ""
	set author_gen to subtitles_choice
	set auto_gen to DL_YTAutoST
	-- Need to use different URL variable for ABC and SBS shows - different treatment of quotes
	if ABC_show_name is "" and SBS_show_name is "" then
		set URL_for_subtitles_test to URL_user_entered_clean
	else
		set URL_for_subtitles_test to URL_user_entered
	end if
	-- v1.28 - Need to get URLs from batch file
	if URL_user_entered contains "--batch" then
		set URL_for_subtitles_test to URL_user_entered
	end if
	-- If user asked only for auto generated subtitles, warn if URL is not YouTube
	if auto_gen is true and author_gen is false and URL_for_subtitles_test does not contain "YouTube" and URL_for_subtitles_test does not contain "YouTu.be" then
		set theAutoSTWillNotWorkLabel to localized string "You have specified auto-generated subtitles but not from Youtube. It will not work. Do you want to try author generated subtitles, continue without subtitles or cancel this download and return to the Main dialog ?" from table "MacYTDL"
		set theButtonContinueGoAuthorLabel to localized string "Try author" from table "MacYTDL"
		set auto_subtitles_stop_or_continue to button returned of (display dialog theAutoSTWillNotWorkLabel buttons {theButtonContinueGoAuthorLabel, theButtonContinueLabel, theButtonReturnLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
		if auto_subtitles_stop_or_continue is theButtonReturnLabel then
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			return "Main"
			--  main_dialog()
			-- ************************************************************************************************************************************************************		
			
		else if auto_subtitles_stop_or_continue is theButtonContinueGoAuthorLabel then
			set author_gen to true
			set auto_gen to false
		else if auto_subtitles_stop_or_continue is theButtonContinueLabel then
			set auto_gen to false
			return YTDL_subtitles
		end if
	end if
	
	-- If user asked for subtitles, get yt-dlp to check whether they are available - if not, warn user if so, test for kind and language
	set check_subtitles_available to do shell script shellPath & DL_Use_YTDLP & " --list-subs --ignore-errors " & URL_for_subtitles_test
	if check_subtitles_available does not contain "Language  formats" and check_subtitles_available does not contain "Language formats" and check_subtitles_available does not contain "Language Name" then
		set theSTNotAvailableLabel1 to localized string "There is no subtitle file available for your video (although it might be embedded)." from table "MacYTDL"
		set theSTNotAvailableLabel2 to localized string "You can quit, stop and return or download anyway." from table "MacYTDL"
		set subtitles_quit_or_continue to button returned of (display dialog theSTNotAvailableLabel1 & return & return & theSTNotAvailableLabel2 buttons {theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel} default button 3 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
		if subtitles_quit_or_continue is theButtonQuitLabel then
			my quit_MacYTDL()
		else if subtitles_quit_or_continue is theButtonReturnLabel then
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			return "Main"
			--  main_dialog()
			-- ************************************************************************************************************************************************************		
			
		else
			return YTDL_subtitles
		end if
	else if check_subtitles_available contains "Language  formats" or check_subtitles_available contains "Language formats" or check_subtitles_available contains "Language Name" then
		-- Subtitles are available - check what kind and consider w.r.t settings
		-- Auto-gen requested but only author-gen available - what to do ?
		if auto_gen is true and author_gen is false and check_subtitles_available does not contain "Available automatic captions for" and check_subtitles_available contains "Available subtitles for" then
			set theNoAutoYesAuthorLabel to localized string "You have specified auto-generated subtitles but only author generated are available. Do you want author generated subtitles, continue without subtitles or cancel this download and return to the Main dialog ?" from table "MacYTDL"
			set theButtonContinueGoAuthorLabel to localized string "Get author" from table "MacYTDL"
			set auto_subtitles_stop_or_continue to button returned of (display dialog theAutoSTWillNotWorkLabel buttons {theButtonContinueGoAuthorLabel, theButtonContinueLabel, theButtonReturnLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if auto_subtitles_stop_or_continue is theButtonReturnLabel then
				
				-- ************************************************************************************************************************************************************
				-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
				return "Main"
				--  main_dialog()
				-- ************************************************************************************************************************************************************		
				
			else if auto_subtitles_stop_or_continue is theButtonContinueGoAuthorLabel then
				set author_gen to true
				set auto_gen to false
			else if auto_subtitles_stop_or_continue is theButtonContinueLabel then
				set auto_gen to false
				return YTDL_subtitles
			end if
			-- Or, author-gen requested but only auto-gen available - what to do ?
		else if auto_gen is false and author_gen is true and check_subtitles_available contains "Available automatic captions for" and check_subtitles_available does not contain "Available subtitles for" then
			set theNoAutoYesAuthorLabel to localized string "You have specified author-generated subtitles but only auto-generated are available. Do you want auto-generated subtitles, continue without subtitles or cancel this download and return to the Main dialog ?" from table "MacYTDL"
			set theButtonContinueGoAutoLabel to localized string "Get auto" from table "MacYTDL"
			set auto_subtitles_stop_or_continue to button returned of (display dialog theNoAutoYesAuthorLabel buttons {theButtonContinueGoAutoLabel, theButtonContinueLabel, theButtonReturnLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if auto_subtitles_stop_or_continue is theButtonReturnLabel then
				
				-- ************************************************************************************************************************************************************
				-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
				return "Main"
				--  main_dialog()
				-- ************************************************************************************************************************************************************		
				
			else if auto_subtitles_stop_or_continue is theButtonContinueGoAutoLabel then
				set author_gen to false
				set auto_gen to true
			else if auto_subtitles_stop_or_continue is theButtonContinueLabel then
				set author_gen to false
				return YTDL_subtitles
			end if
		end if
		
		-- Check against language and format requested - convert if different - there can be more than one format available - warn user if desired language not available
		-- Parse check_subtitles_available to get list of languages and formats that are available
		set subtitles_info to ""
		set log_ST_paragraphs to paragraphs of check_subtitles_available
		set show_languages_avail to ""
		set AppleScript's text item delimiters to "  "
		repeat with log_subtitle_paragraph in log_ST_paragraphs
			-- Loop thru all paragraphs - collect those which contain subtitle info - look @ all paragraphs because can have >1 download - collate languages avail into one variable
			if log_subtitle_paragraph contains "      " or character 3 of log_subtitle_paragraph is "-" then
				set subtitles_info to subtitles_info & log_subtitle_paragraph & return
				set lang_code to text item 1 of log_subtitle_paragraph
				set show_languages_avail to show_languages_avail & lang_code & ", "
			end if
		end repeat
		set AppleScript's text item delimiters to ""
		
		-- Isolate case when both author-gen and auto-gen are available but user requests wrong one due to language non-availability
		if subtitles_info does not contain (DL_STLanguage & " ") then
			set theSTLangNotAvailableLabel1 to localized string "There is no subtitle file in your preferred language " from table "MacYTDL"
			set theSTLangNotAvailableLabel2 to localized string "These languages are available: " from table "MacYTDL"
			set theSTLangNotAvailableLabel3 to localized string "You can quit, cancel your download (then go to Settings to change language) or download anyway." from table "MacYTDL"
			set subtitles_quit_or_continue to button returned of (display dialog theSTLangNotAvailableLabel1 & "\"" & DL_STLanguage & "\". " & theSTLangNotAvailableLabel2 & return & return & show_languages_avail & return & return & theSTLangNotAvailableLabel3 buttons {theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel} default button 3 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if subtitles_quit_or_continue is theButtonQuitLabel then
				my quit_MacYTDL()
			else if subtitles_quit_or_continue is theButtonReturnLabel then
				
				-- ************************************************************************************************************************************************************
				-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
				return "Main"
				--  main_dialog()
				-- ************************************************************************************************************************************************************		
				
			end if
		else
			set AppleScript's text item delimiters to {"Available automatic captions for", "Available subtitles for"}
			if (count of text items in check_subtitles_available) is 3 then
				-- YTDL always reports auto-gen availability before author-gen
				set alt_lang_avail to "N"
				set auto_gen_subtitles to text item 2 of check_subtitles_available
				set author_gen_subtitles to text item 3 of check_subtitles_available
				if author_gen_subtitles contains (DL_STLanguage & " ") and auto_gen_subtitles does not contain (DL_STLanguage & " ") and author_gen is false then
					set dialog_1_text to "auto-generated "
					set dialog_2_text to "author-generated "
					set dialog_3_text to author_gen_subtitles
					set theButtonContinueGoLabel to localized string "Get author" from table "MacYTDL"
					set alt_lang_avail to "Y"
				end if
				if author_gen_subtitles does not contain (DL_STLanguage & " ") and auto_gen_subtitles contains (DL_STLanguage & " ") and auto_gen is false then
					set dialog_1_text to "author-generated "
					set dialog_2_text to "auto-generated "
					set dialog_3_text to auto_gen_subtitles
					set theButtonContinueGoLabel to localized string "Get auto" from table "MacYTDL"
					set alt_lang_avail to "Y"
				end if
				if alt_lang_avail is "Y" then
					set theSTLangNotAvailableLabel1a to localized string "There is no" from table "MacYTDL"
					set theSTLangNotAvailableLabel1b to localized string "subtitle file in your preferred language" from table "MacYTDL"
					set theSTLangNotAvailableLabel1 to localized string theSTLangNotAvailableLabel1a & " " & dialog_1_text & theSTLangNotAvailableLabel1b & " "
					set theSTLangNotAvailableLabel2a to localized string "But" from table "MacYTDL"
					set theSTLangNotAvailableLabel2b to localized string "subtitles are available." from table "MacYTDL"
					set theSTLangNotAvailableLabel2 to localized string theSTLangNotAvailableLabel2a & " " & dialog_2_text & theSTLangNotAvailableLabel2b
					set theSTLangNotAvailableLabel3a to localized string "You cancel your download, download " from table "MacYTDL"
					set theSTLangNotAvailableLabel3b to localized string "subtitles or download without subtitles." from table "MacYTDL"
					set theSTLangNotAvailableLabel3 to theSTLangNotAvailableLabel3a & dialog_2_text & theSTLangNotAvailableLabel3b
					set subtitles_quit_or_continue to button returned of (display dialog theSTLangNotAvailableLabel1 & "\"" & DL_STLanguage & "\". " & theSTLangNotAvailableLabel2 & return & return & theSTLangNotAvailableLabel3 buttons {theButtonReturnLabel, theButtonContinueGoLabel, theButtonContinueLabel} default button 3 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
					if subtitles_quit_or_continue is theButtonContinueGoLabel then
						if dialog_2_text is "author-generated " then
							set author_gen to true
							set auto_gen to false
						else if dialog_2_text is "auto-generated " then
							set author_gen to false
							set auto_gen to true
						end if
					else if subtitles_quit_or_continue is theButtonReturnLabel then
						
						-- ************************************************************************************************************************************************************
						-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
						return "Main"
						--  main_dialog()
						-- ************************************************************************************************************************************************************		
						
					else if subtitles_quit_or_continue is theButtonContinueLabel then
						return YTDL_subtitles
					end if
				end if
			end if
			set AppleScript's text item delimiters to ""
		end if
		
		-- If desired language is available or user choose to continue anyway, processing continues here - YTDL returns a warning if lang not available but continues to download
		-- Is desired format available - if so continue - if not convert - conversion can currently handle only srt, ass, lrc and vtt - passing best, dfxp or ttml uses YTDL's own choice
		-- For author generated STs
		if author_gen is true and auto_gen is false then
			if subtitles_info does not contain DL_subtitles_format and DL_subtitles_format is not theBestLabel and DL_subtitles_format is not "ttml" and DL_subtitles_format is not "dfxp" then
				set YTDL_subtitles to "--write-sub --convert-subs " & DL_subtitles_format & " " & "--sub-lang " & DL_STLanguage & " "
			else if DL_subtitles_format is theBestLabel then
				set YTDL_subtitles to "--write-sub --sub-format best " & "--sub-lang " & DL_STLanguage & " "
			else if DL_subtitles_format is "dfxp" then
				set YTDL_subtitles to "--write-sub --sub-format dfxp " & "--sub-lang " & DL_STLanguage & " "
			else if DL_subtitles_format is "ttml" then
				set YTDL_subtitles to "--write-sub --sub-format ttml " & "--sub-lang " & DL_STLanguage & " "
			else
				-- Site does provide format user wants
				set YTDL_subtitles to "--write-sub --sub-format " & DL_subtitles_format & " " & "--sub-lang " & DL_STLanguage & " "
			end if
		end if
		-- For auto-generated STs
		if author_gen is false and auto_gen is true then
			if subtitles_info does not contain DL_subtitles_format and DL_subtitles_format is not theBestLabel and DL_subtitles_format is not "ttml" and DL_subtitles_format is not "dfxp" then
				set YTDL_subtitles to "--write-auto-sub --convert-subs " & DL_subtitles_format & " " & "--sub-lang " & DL_STLanguage & " "
			else if DL_subtitles_format is theBestLabel then
				set YTDL_subtitles to "--write-auto-sub --sub-format best " & "--sub-lang " & DL_STLanguage & " "
			else if DL_subtitles_format is "dfxp" then
				set YTDL_subtitles to "--write-auto-sub --sub-format dfxp " & "--sub-lang " & DL_STLanguage & " "
			else if DL_subtitles_format is "ttml" then
				set YTDL_subtitles to "--write-auto-sub --sub-format ttml " & "--sub-lang " & DL_STLanguage & " "
			else
				-- Site does provide format user wants
				set YTDL_subtitles to "--write-auto-sub --sub-format " & DL_subtitles_format & " --sub-lang " & DL_STLanguage & " "
			end if
		end if
		-- Ask for both kinds of STs
		if author_gen is true and auto_gen is true then
			if subtitles_info does not contain DL_subtitles_format and DL_subtitles_format is not theBestLabel and DL_subtitles_format is not "ttml" and DL_subtitles_format is not "dfxp" then
				set YTDL_subtitles to "--write-auto-sub --write-sub --convert-subs " & DL_subtitles_format & " " & "--sub-lang " & DL_STLanguage & " "
			else if DL_subtitles_format is theBestLabel then
				set YTDL_subtitles to "--write-auto-sub --write-sub --sub-format best " & "--sub-lang " & DL_STLanguage & " "
			else if DL_subtitles_format is "dfxp" then
				set YTDL_subtitles to "--write-auto-sub --write-sub --sub-format dfxp " & "--sub-lang " & DL_STLanguage & " "
			else if DL_subtitles_format is "ttml" then
				set YTDL_subtitles to "--write-auto-sub --write-sub --sub-format ttml " & "--sub-lang " & DL_STLanguage & " "
			else
				-- Site does provide format user wants
				set YTDL_subtitles to "--write-auto-sub --write-sub --sub-format " & DL_subtitles_format & " --sub-lang " & DL_STLanguage & " "
			end if
		end if
		return YTDL_subtitles
	end if
end check_subtitles_download_available


--------------------------------------------------------------------------
--
-- 		Does user wish to install/update Deno ?
--
--------------------------------------------------------------------------

-- Handler for installing/updating Deno - Added in v1.30, 1/11/25
-- Assuming for now that Deno version number is sourced from Preliminaries, before main_dialog() - Oops what about auto-download ??
-- deno_version contains current version installed or "Not installed"
-- Currently sourcing Deno from deno.land. If there are problems will change to GitHub.
on install_update_Deno(deno_version, user_system_arch, resourcesPath, path_to_MacYTDL, theButtonOKLabel, MacYTDL_custom_icon_file, diag_Title)
	-- Result of next line will be formatted like "v2.5.6" - so we add the leading v character to deno_version
	set deno_current_version to do shell script "curl -s https://dl.deno.land/release-latest.txt"
	if deno_current_version is not ("v" & deno_version) then
		if user_system_arch is "Intel" then
			set deno_download_site to "https://dl.deno.land/release/" & deno_current_version & "/deno-x86_64-apple-darwin.zip"
			-- set deno_download_site to "https://github.com/denoland/deno/releases/download/" & deno_current_version & "/deno-x86_64-apple-darwin.zip"
		else
			set deno_download_site to "https://dl.deno.land/release/" & deno_current_version & "/deno-aarch64-apple-darwin.zip"
			-- set deno_download_site to "https://github.com/denoland/deno/releases/download/" & deno_current_version & "/deno-aarch64-apple-darwin.zip"
		end if
		set installAlertActionLabel to quoted form of "_"
		set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
		set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
		set installAlertSubtitle to quoted form of (localized string "Installing Deno" from table "MacYTDL")
		do shell script resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
		try
			do shell script "curl -L " & deno_download_site & " -o /usr/local/bin/deno.zip" with administrator privileges
			do shell script "unzip -o /usr/local/bin/deno.zip -d /usr/local/bin/" with administrator privileges
			do shell script "rm /usr/local/bin/deno.zip" with administrator privileges
			set deno_version to text 2 thru end of deno_current_version
			display dialog ((localized string "Deno is installed and up-to-date. You have version ") & deno_version) buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		on error number -128
			-- User cancels credentials dialog - just return to Main dialog
			set theYTDLInstallCancelLabel to localized string "You've cancelled installing Deno. You can install/update Deno in the Utilities dialog." in bundle file path_to_MacYTDL from table "MacYTDL"
			display dialog theYTDLInstallCancelLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		end try
	else
		display dialog ((localized string "Deno is up-to-date. You have version ") & deno_version) buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		return deno_version
	end if
	return deno_version
end install_update_Deno


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


-------------------------------------------------------------
--
-- 		Find offset of last search string in a String
--
-------------------------------------------------------------

-- Handler to find offset of last specified character in a string
-- v1.28 - Took quite a lot of testing to get this working correctly - don't know what the purpose of the reverses variable was
on last_offset(the_object_string, the_search_string)
	try
		set len to count of the_object_string
		set list_characters to characters of the_object_string as string
		set reversed to reverse of characters of the_object_string as string
		--		display dialog "the_object_string: " & the_object_string & return & "len: " & len & return & "list_characters: " & list_characters & return & "the_search_string: " & the_search_string & return & "reversed: " & reversed
		set last_occurrence_offset to len - (offset of the_search_string in reversed)
		if last_occurrence_offset > len then
			return 0
		end if
	on error
		return 0
	end try
	--	display dialog "the_object_string: " & the_object_string & return & "len: " & len & return & "the_search_string: " & the_search_string & return & "reversed: " & reversed & return & "last_occurrence_offset: " & last_occurrence_offset
	return last_occurrence_offset
end last_offset


---------------------------------------------------
--
-- 				Date and time
--
---------------------------------------------------

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


---------------------------------------------------
--
-- 				Clean text from string
--
---------------------------------------------------

-- Handler to remove non-numeric and delimiter characters from a string
on cleanString(input_String)
	set legalCharacters to {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", ",", " ", "-", "	"}
	set thePrefix to characters of input_String as text
	set theOutput to ""
	repeat with thisChr from 1 to (get count of characters in thePrefix)
		set theChr to character thisChr of thePrefix
		if theChr is in legalCharacters then
			set theOutput to theOutput & theChr
		end if
	end repeat
	return theOutput
end cleanString


----------------------------------------------------------------------------------------------------------------------------
--
-- 	Get screen height and width - using AppKit - called in preliminaries - also used in Monitor.scpt
--  Only loading AppKit when needed - simplifies changes to rest of code
--  Using NSScreen's mainScreen frame as does the Dialog Toolkit
--  X-position and Y-position are used for default location of dialogs on screen
----------------------------------------------------------------------------------------------------------------------------
on get_screensize()
	script theScript
		property parent : a reference to current application
		use framework "AppKit"
		on get_screensize()
			try
				set mainScreenFrame to current application's NSScreen's mainScreen()'s frame()
				set screen_width to current application's NSWidth(mainScreenFrame)
				set screen_height to current application's NSHeight(mainScreenFrame)
				set X_position to (screen_width / 10)
			on error errText
				display dialog "There was an error: " & errText
				set X_position to 50
			end try
			set Y_position to 50
			return X_position & Y_position & screen_width & screen_height
		end get_screensize
	end script
	return theScript's get_screensize()
end get_screensize


---------------------------------------------------
--
-- 		Empty these variables on Quit
--
---------------------------------------------------

-- Found that contents of these these variables persisted - so, empty them to stop them affecting a later instance of MacYTDL
-- This doesn't seem to need a Continue statement to properly quit - perhaps because this is NOT a "Stay Open" app and does not use a "on quit" handler
on quit_MacYTDL()
	set called_video_URL to ""
	set default_contents_text to ""
	set YTDL_version to ""
	set monitor_dialog_position to ""
	set old_version_prefs to "No"
	set DL_batch_status to false
	--quit -- doesn't seem to add anything - might be relevant for enhanced applets in an "on quit"
	error number -128
end quit_MacYTDL
