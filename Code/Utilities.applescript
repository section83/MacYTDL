---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  MacYTDL
--  A GUI for the Python Scripts youtube-dl and yt-dlp.  Many thanks to Shane Stanley.
--  This is contains utilities for installing components etc.
--  Handlers in this script are called by main.scpt
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Include libraries
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use script "DialogToolkitMacYTDL"
property parent : AppleScript

-- Define variables to be filled by the read_settings() handler below - makes these variables available to main.scpt
global DL_audio_only
global DL_audio_codec
global DL_YTDL_auto_check
global DL_description
global downloadsFolder_Path
global resourcesPath
global DL_format
global DL_Remux_original
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
global window_Position
global myNum
global SBS_show_URLs
global SBS_show_name
global ABC_show_URLs
global ABC_show_name
global file_formats_selected
global add_to_output_template
global ffmpeg_version
global ffprobe_version


-- On run handler in case I need to use it in the auto-download process
-- handler_to_run would be passed from the Service
--on run {handler_to_run}
--	display dialog "This should not appear !!"
--end run


---------------------------------------------------
--
--			Auto-download
--
-- Might move this to a separate script file one day so
-- Service doesn't need to load all the other handlers in this script file
--
---------------------------------------------------

-- Handler called by Service to do the auto download
on auto_Download(MacYTDL_prefs_file, URL_user_entered_clean, path_to_MacYTDL)
	
	
	--	try
	
	read_settings(MacYTDL_prefs_file)
	set DL_format to localized string DL_format from table "MacYTDL"
	set DL_subtitles_format to localized string DL_subtitles_format from table "MacYTDL"
	set DL_Remux_format to localized string DL_Remux_format from table "MacYTDL"
	set theBestLabel to localized string "Best" from table "MacYTDL"
	set DL_audio_codec to localized string DL_audio_codec from table "MacYTDL"
	set DL_Show_Settings to false
	
	-- *****************************************************************************
	-- These preliminary bits might end up in a separate handler which is also called by Main - to reduce duplication
	-- *****************************************************************************
	
	set path_to_Main to (path_to_MacYTDL & ":Contents:Resources:Scripts:Main.scpt") as alias
	
	-- *****************************************************************************
	-- Just loading main.scpt until a better way is settled - probably an osascript call into background
	set run_Main_handlers to load script path_to_Main
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
	set screen_size to run_Main_handlers's get_screensize()
	set X_position to item 1 of screen_size as integer
	set Y_position to item 2 of screen_size as integer
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
	if DL_Remux_format is not "No remux" then
		if DL_Use_YTDLP is "yt-dlp" then
			set YTDL_remux_format to "--recode-video " & DL_Remux_format & " " & "--postprocessor-args \"ffmpeg:-codec copy\" "
		else
			set YTDL_remux_format to "--recode-video " & DL_Remux_format & " " & "--postprocessor-args \"-codec copy\" "
		end if
	else
		set YTDL_remux_format to ""
	end if
	if DL_Remux_original is true then
		set YTDL_Remux_original to "--keep-video "
	else
		set YTDL_Remux_original to ""
	end if
	-- Set YTDL format parameter desired format + set separate YTDL_format_pref variable for use in simulate stage
	if DL_format is not "Default" then
		set YTDL_format to "-f bestvideo[ext=" & DL_format & "]+bestaudio/best[ext=" & DL_format & "]/best "
		set YTDL_format_pref to "-f " & DL_format & " "
	else
		set YTDL_format_pref to ""
		set YTDL_format to ""
	end if
	--	Set format sort parameter to desired maximum - not used in Simulate
	if DL_Resolution_Limit is "Best" then
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
	
	run_Main_handlers's check_download_folder(downloadsFolder_Path, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, diag_Title, MacYTDL_custom_icon_file, skip_Main_dialog)
	if DL_Use_Cookies is true then run_Main_handlers's check_cookies_file(DL_Cookies_Location)
	
	
	-- *****************************************************************************
	-- download_video might end up being moved to Utilities
	-- *****************************************************************************	
	
	run_Main_handlers's download_video(shellPath, path_to_MacYTDL, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, screen_width, screen_height, YTDL_simulate_file, URL_user_entered, URL_user_entered_clean, downloadsFolder_Path, diag_Title, DL_batch_status, DL_Remux_format, DL_subtitles, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format_pref, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, skip_Main_dialog, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, theButtonReturnLabel, theButtonQuitLabel, theButtonContinueLabel, YTDL_QT_Compat, DL_Use_YTDLP, theBestLabel, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
	
	--	on error errMsg
	--		display dialog "Error in auto_Download handler: " & errMsg
	--	end try
	
	
end auto_Download


-- If version of DTP library is old, replace with new - called on startup - uses short version
on check_DTP(DTP_file, path_to_MacYTDL)
	set DTP_library_MacYTDL to quoted form of ((POSIX path of path_to_MacYTDL) & "Contents/Resources/Script Libraries/DialogToolkitMacYTDL.scptd")
	set libraries_folder to quoted form of (POSIX path of (path to home folder) & "Library/Script Libraries/")
	set libraries_folder_nonposix to text 3 thru -2 of (POSIX path of libraries_folder)
	set DTP_library_MacYTDL_trimmed to text 2 thru -2 of DTP_library_MacYTDL
	set DTP_library_MacYTDL_trimmed_nonposix to POSIX file DTP_library_MacYTDL_trimmed as string
	set alias_new_DTP_file to DTP_library_MacYTDL_trimmed_nonposix as alias
	set alias_DTP_file to DTP_file as alias
	tell application "System Events"
		set old_DTP_version to get the short version of alias_DTP_file
		set new_DTP_version to get the short version of alias_new_DTP_file
	end tell
	if old_DTP_version is not new_DTP_version then
		do shell script "rm -R " & (quoted form of (POSIX path of DTP_file))
		do shell script "cp -a " & DTP_library_MacYTDL & " " & libraries_folder
	end if
end check_DTP


---------------------------------------------------
--
--			Install youtube-dl/yt-dlp
--
---------------------------------------------------

-- Handler to install yt-dlp - install if user agrees but can't run MacYTDL without it - when needed is called by main thread before Main dialog displayed - Return the version and name of tool installed - Not called if user has Homebrew
-- v1.24 - No longer installing youtube-dl - but, note, users who have it can keep it
on check_ytdl_installed(usr_bin_folder, diag_Title, youtubedl_file, ytdlp_file, theButtonQuitLabel, theButtonYesLabel, path_to_MacYTDL, theButtonOKLabel, resourcesPath, show_yt_dlp, MacYTDL_custom_icon_file)
	set installAlertActionLabel to quoted form of "_"
	set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
	set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
	set installAlertSubtitle to quoted form of (localized string "Download and install of " & show_yt_dlp from table "MacYTDL")
	do shell script resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
	tell me to activate
	-- Make the /usr/local/bin/ folder if it doesn't exist
	try
		tell application "System Events"
			if not (exists folder usr_bin_folder) then
				tell current application to do shell script "mkdir -p " & usr_bin_folder with administrator privileges
			end if
		end tell
	end try
	-- If user is on 10.15+ install yt-dlp otherwise install yt-dlp-legacy
	try
		set theYTDLDownloadProblemFlag to ""
		set ytdlp_file_install to ("/usr/local/bin/yt-dlp" as text)
		set YTDL_site_URL to "https://github.com/yt-dlp/yt-dlp/releases"
		set YTDL_releases_page to do shell script "curl " & YTDL_site_URL & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
		if YTDL_releases_page is "" then
			set theYTDLDownloadProblemFlag to "NoReturnFromCurl"
			error number -128
		end if
		set AppleScript's text item delimiters to "Latest"
		set YTDL_releases_text to text item 1 of YTDL_releases_page
		set numParas to count paragraphs in YTDL_releases_text
		set version_para to paragraph (numParas) of YTDL_releases_text
		set AppleScript's text item delimiters to " "
		set YTDL_version_check to text item 2 of version_para
		set AppleScript's text item delimiters to ""
		
		-- User on 10.15+ - install universal yt-dlp - can probably simplify if tests here but, leave as is for clarity
		-- 4/3/23 - Now assuming the yt-dlp_macos is in place - because YTDL_releases_page no longer shows by default all the assets including the macOS executables
		if show_yt_dlp is "yt-dlp" then
			set curl_YTDLP to ("curl -L " & YTDL_site_URL & "/download/" & YTDL_version_check & "/yt-dlp_macos" & " -o /usr/local/bin/yt-dlp")
		end if
		
		-- User on 10.9-10.14.6 - install yt-dlp-legacy
		if show_yt_dlp is "yt-dlp-legacy" then
			set curl_YTDLP to ("curl -L " & YTDL_site_URL & "/download/" & YTDL_version_check & "/yt-dlp_macos_legacy" & " -o /usr/local/bin/yt-dlp")
		end if
		try
			do shell script curl_YTDLP with administrator privileges
			do shell script "chmod a+x /usr/local/bin/yt-dlp" with administrator privileges
		on error number 6
			-- Trap cases in which user is not able to access the web site
			set theYTDLDownloadProblemFlag to "NoReturnFromDownload"
			error number -128
		end try
		
		set YTDL_ytdlp_version to (do shell script ytdlp_file_install & " --version") & " ytdlp"
		
	on error number -128
		if theYTDLDownloadProblemFlag is "NoReturnFromCurl" then
			set theYTDLDownloadProblemLabel to localized string "There was a problem with downloading yt-dlp. Perhaps you are not connected to the internet, you have a rule in LittleSnitch denying connection or the server is currently not available. When you are sure you are connected to the internet, re-open MacYTDL then try to install yt-dlp." in bundle file path_to_MacYTDL from table "MacYTDL"
			display dialog theYTDLDownloadProblemLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		else if theYTDLDownloadProblemFlag is "NoReturnFromDownload" then
			set theYTDLDownloadProblemLabel to localized string "There was a problem with downloading yt-dlp. Perhaps you are not connected to the internet or the server is currently not available. When you are sure you are connected to the internet, re-open MacYTDL then try to install yt-dlp." in bundle file path_to_MacYTDL from table "MacYTDL"
			display dialog theYTDLDownloadProblemLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		else
			-- User cancels credentials dialog - just quit as can't run MacYTDL without yt-dlp
			set theYTDLInstallCancelLabel to localized string "You've cancelled installing yt-dlp. If you wish to use MacYTDL, restart and enter your administrator credentials when asked so that yt-dlp can be installed." in bundle file path_to_MacYTDL from table "MacYTDL"
			display dialog theYTDLInstallCancelLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		end if
		error number -128
	end try
end check_ytdl_installed


---------------------------------------------------
--
-- 			Install FFMpeg & FFprobe - Fork
--
---------------------------------------------------

-- Handler for forking to correct FFmpeg and FFprobe installer - called by main thread on startup if either or both FF files are missing
on install_ffmpeg_ffprobe(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os, user_system_arch)
	if user_system_arch is "Intel" then
		install_ffmpeg_ffprobe_intel(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os)
	else
		install_ffmpeg_ffprobe_arm(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os)
	end if
end install_ffmpeg_ffprobe

---------------------------------------------------
--
-- 			Install FFMpeg & FFprobe - ARM64
--
---------------------------------------------------

-- Handler for installing FFmpeg and FFprobe - called by install_ffmpeg_ffprobe() - for users on Apple Silicon
on install_ffmpeg_ffprobe_arm(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os)
	set ffmpeg_site to "https://ffmpeg.martin-riedl.de"
	set ffprobe_site to "https://ffmpeg.martin-riedl.de"
	set FFmpeg_page to do shell script "curl " & ffmpeg_site & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
	-- Trap case in which user is offline
	if FFmpeg_page is "" then
		set theFFmpegDownloadProblemLabel to localized string "There was a problem with downloading FFmpeg. Perhaps you are not connected to the internet or the server is currently not available. MacYTDL can't run and will have to quit. When you are sure you are connected to the internet, re-open MacYTDL. MacYTDL, will then try to install FFmpeg." in bundle file path_to_MacYTDL from table "MacYTDL"
		display dialog theFFmpegDownloadProblemLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		error number -128
	else
		set AppleScript's text item delimiters to {"macOS (Apple Silicon/arm64)"}
		set release_build_text_FFmpeg to paragraph 2 of text item 3 of FFmpeg_page
		set AppleScript's text item delimiters to {" "}
		set release_build_version_FFmpeg to text item 2 of release_build_text_FFmpeg
		set AppleScript's text item delimiters to {""}
		set installAlertActionLabel to quoted form of "_"
		set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
		set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
		set installAlertSubtitle to quoted form of (localized string "Download and install of FFmpeg" from table "MacYTDL")
		do shell script quoted form of resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
		set ffmpeg_download_file to quoted form of (usr_bin_folder & "ffmpeg.zip")
		try
			-- Download latest FFmpeg zip file to usr/local/bin, unzip, fix permissions, rm zip file
			set ffmpeg_arm_latest to "https://ffmpeg.martin-riedl.de/redirect/latest/macos/arm64/release/ffmpeg.zip"
			do shell script "curl -L " & ffmpeg_arm_latest & " -o " & ffmpeg_download_file with administrator privileges
			do shell script "unzip -o " & ffmpeg_download_file & " -d " & usr_bin_folder with administrator privileges
			do shell script "rm " & ffmpeg_download_file with administrator privileges
			set ffmpeg_version to release_build_version_FFmpeg
		on error errStr number errorNumber
			if errorNumber is -128 then
				-- User cancels credentials dialog
				try
					do shell script "rm " & ffmpeg_download_file with administrator privileges
				end try
			else
				-- trap any other kind of error including "Operation not permitted" and trap case in which zip file is not downloaded and saved
				try
					do shell script "rm " & ffmpeg_download_file with administrator privileges
				end try
				set theFFmpegInstallProblemTextLabel1 to localized string "There was a problem with installing FFmpeg. This was the error message: " in bundle file path_to_MacYTDL from table "MacYTDL"
				set theFFmpegInstallProblemTextLabel2 to localized string "MacYTDL can't run and will have to quit. When you next start MacYTDL, it will try again to install FFmpeg." in bundle file path_to_MacYTDL from table "MacYTDL"
				display dialog "" & errorNumber & " " & errStr & return & return & theFFmpegInstallProblemTextLabel2 buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
			end if
			error number -128
		end try
		set installAlertActionLabel to quoted form of "_"
		set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
		set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
		set installAlertSubtitle to quoted form of (localized string "Download and install of FFprobe" from table "MacYTDL")
		do shell script quoted form of resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
		set ffprobe_download_file to quoted form of (usr_bin_folder & "ffprobe.zip")
		set ffprobe_site_latest to "https://ffmpeg.martin-riedl.de/redirect/latest/macos/arm64/release/ffprobe.zip"
		try
			do shell script "curl -L " & ffprobe_site_latest & " -o " & ffprobe_download_file with administrator privileges
			do shell script "unzip -o " & ffprobe_download_file & " -d " & usr_bin_folder with administrator privileges
			do shell script "rm " & ffprobe_download_file with administrator privileges
			set ffprobe_version to release_build_version_FFmpeg
		on error errStr number errorNumber
			if errorNumber is -128 then
				-- User cancels credentials dialog
				try
					do shell script "rm " & ffprobe_download_file with administrator privileges
				end try
			else
				-- trap any other kind of error including "Operation not permitted"
				try
					do shell script "rm " & ffmpeg_download_file with administrator privileges
				end try
				set theFFProbeInstallProblemTextLabel1 to localized string "There was a problem with installing FFprobe. This was the error message: " in bundle file path_to_MacYTDL from table "MacYTDL"
				set theFFProbeInstallProblemTextLabel2 to localized string "MacYTDL can't run and will have to quit. When you next start MacYTDL, it will try again to install FFprobe." in bundle file path_to_MacYTDL from table "MacYTDL"
				display dialog theFFProbeInstallProblemTextLabel1 & errorNumber & " " & errStr & return & return & theFFProbeInstallProblemTextLabel2 buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
			end if
			error number -128
		end try
	end if
end install_ffmpeg_ffprobe_arm

---------------------------------------------------
--
-- 			Install FFMpeg & FFprobe - Intel
--
---------------------------------------------------

-- Handler for installing FFmpeg and FFprobe - called by install_ffmpeg_ffprobe() - for users on Intel Macs
on install_ffmpeg_ffprobe_intel(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os)
	set ffmpeg_site to "https://ffmpeg.martin-riedl.de"
	set ffprobe_site to "https://ffmpeg.martin-riedl.de"
	set FFmpeg_page to do shell script "curl " & ffmpeg_site & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
	-- Trap case in which user is offline
	if FFmpeg_page is "" then
		set theFFmpegDownloadProblemLabel to localized string "There was a problem with downloading FFmpeg. Perhaps you are not connected to the internet or the server is currently not available. MacYTDL can't run and will have to quit. When you are sure you are connected to the internet, re-open MacYTDL. MacYTDL, will then try to install FFmpeg." in bundle file path_to_MacYTDL from table "MacYTDL"
		display dialog theFFmpegDownloadProblemLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		error number -128
	else
		set AppleScript's text item delimiters to {"macOS (Intel/amd64)"}
		set release_build_text_FFmpeg to paragraph 2 of text item 3 of FFmpeg_page
		set AppleScript's text item delimiters to {" "}
		set release_build_version_FFmpeg to text item 2 of release_build_text_FFmpeg
		set AppleScript's text item delimiters to {""}
		set installAlertActionLabel to quoted form of "_"
		set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
		set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
		set installAlertSubtitle to quoted form of (localized string "Download and install of FFmpeg" from table "MacYTDL")
		do shell script quoted form of resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
		set ffmpeg_download_file to quoted form of (usr_bin_folder & "ffmpeg.zip")
		try
			-- Download latest FFmpeg zip file to usr/local/bin, unzip, fix permissions, rm zip file
			set ffmpeg_arm_latest to "https://ffmpeg.martin-riedl.de/redirect/latest/macos/amd64/release/ffmpeg.zip"
			do shell script "curl -L " & ffmpeg_arm_latest & " -o " & ffmpeg_download_file with administrator privileges
			do shell script "unzip -o " & ffmpeg_download_file & " -d " & usr_bin_folder with administrator privileges
			do shell script "rm " & ffmpeg_download_file with administrator privileges
			set ffmpeg_version to release_build_version_FFmpeg
		on error errStr number errorNumber
			if errorNumber is -128 then
				-- User cancels credentials dialog
				try
					do shell script "rm " & ffmpeg_download_file with administrator privileges
				end try
			else
				-- trap any other kind of error including "Operation not permitted" and trap case in which zip file is not downloaded and saved
				try
					do shell script "rm " & ffmpeg_download_file with administrator privileges
				end try
				set theFFmpegInstallProblemTextLabel1 to localized string "There was a problem with installing FFmpeg. This was the error message: " in bundle file path_to_MacYTDL from table "MacYTDL"
				set theFFmpegInstallProblemTextLabel2 to localized string "MacYTDL can't run and will have to quit. When you next start MacYTDL, it will try again to install FFmpeg." in bundle file path_to_MacYTDL from table "MacYTDL"
				display dialog "" & errorNumber & " " & errStr & return & return & theFFmpegInstallProblemTextLabel2 buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
			end if
			error number -128
		end try
		set installAlertActionLabel to quoted form of "_"
		set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
		set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
		set installAlertSubtitle to quoted form of (localized string "Download and install of FFprobe" from table "MacYTDL")
		do shell script quoted form of resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
		set ffprobe_download_file to quoted form of (usr_bin_folder & "ffprobe.zip")
		set ffprobe_site_latest to "https://ffmpeg.martin-riedl.de/redirect/latest/macos/amd64/release/ffprobe.zip"
		try
			do shell script "curl -L " & ffprobe_site_latest & " -o " & ffprobe_download_file with administrator privileges
			do shell script "unzip -o " & ffprobe_download_file & " -d " & usr_bin_folder with administrator privileges
			do shell script "rm " & ffprobe_download_file with administrator privileges
			set ffprobe_version to release_build_version_FFmpeg
		on error errStr number errorNumber
			if errorNumber is -128 then
				-- User cancels credentials dialog
				try
					do shell script "rm " & ffprobe_download_file with administrator privileges
				end try
			else
				-- trap any other kind of error including "Operation not permitted"
				try
					do shell script "rm " & ffmpeg_download_file with administrator privileges
				end try
				set theFFProbeInstallProblemTextLabel1 to localized string "There was a problem with installing FFprobe. This was the error message: " in bundle file path_to_MacYTDL from table "MacYTDL"
				set theFFProbeInstallProblemTextLabel2 to localized string "MacYTDL can't run and will have to quit. When you next start MacYTDL, it will try again to install FFprobe." in bundle file path_to_MacYTDL from table "MacYTDL"
				display dialog theFFProbeInstallProblemTextLabel1 & errorNumber & " " & errStr & return & return & theFFProbeInstallProblemTextLabel2 buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
			end if
			error number -128
		end try
	end if
end install_ffmpeg_ffprobe_intel

-- Handler for installing FFmpeg and FFprobe - called by install_ffmpeg_ffprobe() - for users on Intel
on install_ffmpeg_ffprobe_intel_OLD(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os)
	set ffmpeg_site to "https://evermeet.cx/pub/ffmpeg/"
	set ffprobe_site to "https://evermeet.cx/pub/ffprobe/"
	set FFmpeg_page to do shell script "curl " & ffmpeg_site & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
	-- Trap case in which user is offline
	if FFmpeg_page is "" then
		set theFFmpegDownloadProblemLabel to localized string "There was a problem with downloading FFmpeg. Perhaps you are not connected to the internet or the server is currently not available. MacYTDL can't run and will have to quit. When you are sure you are connected to the internet, re-open MacYTDL. MacYTDL, will then try to install FFmpeg." in bundle file path_to_MacYTDL from table "MacYTDL"
		display dialog theFFmpegDownloadProblemLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		error number -128
	else
		set ffmpeg_version_start to (offset of "version" in FFmpeg_page) + 8
		set ffmpeg_version_end to (offset of "-tessus" in FFmpeg_page) - 1
		set ffmpeg_version_new to text ffmpeg_version_start thru ffmpeg_version_end of FFmpeg_page
		set installAlertActionLabel to quoted form of "_"
		set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
		set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
		set installAlertSubtitle to quoted form of (localized string "Download and install of FFmpeg" from table "MacYTDL")
		do shell script quoted form of resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
		set ffmpeg_download_file to quoted form of (usr_bin_folder & "ffmpeg-" & ffmpeg_version_new & ".zip")
		try
			set ignore_certifcates to ""
			if user_on_old_os is true then set ignore_certifcates to " -k "
			-- Download latest FFmpeg zip file to usr/local/bin, unzip, fix permissions, rm zip file
			do shell script "curl -L " & ffmpeg_site & "ffmpeg-" & ffmpeg_version_new & ".zip" & ignore_certifcates & " -o " & ffmpeg_download_file with administrator privileges
			do shell script "unzip -o " & ffmpeg_download_file & " -d " & usr_bin_folder with administrator privileges
			do shell script "chmod a+x /usr/local/bin/ffmpeg" with administrator privileges
			do shell script "rm " & ffmpeg_download_file with administrator privileges
			set ffmpeg_version to ffmpeg_version_new
		on error errStr number errorNumber
			if errorNumber is -128 then
				-- User cancels credentials dialog
				try
					do shell script "rm " & ffmpeg_download_file with administrator privileges
				end try
			else
				-- trap any other kind of error including "Operation not permitted" and trap case in which zip file is not downloaded and saved
				try
					do shell script "rm " & ffmpeg_download_file with administrator privileges
				end try
				set theFFmpegInstallProblemTextLabel1 to localized string "There was a problem with installing FFmpeg. This was the error message: " in bundle file path_to_MacYTDL from table "MacYTDL"
				set theFFmpegInstallProblemTextLabel2 to localized string "MacYTDL can't run and will have to quit. When you next start MacYTDL, it will try again to install FFmpeg." in bundle file path_to_MacYTDL from table "MacYTDL"
				display dialog "" & errorNumber & " " & errStr & return & return & theFFmpegInstallProblemTextLabel2 buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
			end if
			error number -128
		end try
		set installAlertActionLabel to quoted form of "_"
		set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
		set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
		set installAlertSubtitle to quoted form of (localized string "Download and install of FFprobe" from table "MacYTDL")
		do shell script quoted form of resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
		set ffprobe_version_new to ffmpeg_version_new
		set ffprobe_download_file to quoted form of (usr_bin_folder & "ffprobe-" & ffprobe_version_new & ".zip")
		set ignore_certifcates to ""
		if user_on_old_os is true then set ignore_certifcates to " -k "
		do shell script "curl -L " & ffprobe_site & "ffprobe-" & ffprobe_version_new & ".zip" & ignore_certifcates & " -o " & ffprobe_download_file with administrator privileges
		try
			do shell script "unzip -o " & ffprobe_download_file & " -d " & usr_bin_folder with administrator privileges
			do shell script "chmod a+x /usr/local/bin/ffprobe" with administrator privileges
			do shell script "rm " & ffprobe_download_file with administrator privileges
			set ffprobe_version to ffprobe_version_new
		on error errStr number errorNumber
			if errorNumber is -128 then
				-- User cancels credentials dialog
				try
					do shell script "rm " & ffprobe_download_file with administrator privileges
				end try
			else
				-- trap any other kind of error including "Operation not permitted"
				try
					do shell script "rm " & ffmpeg_download_file with administrator privileges
				end try
				set theFFProbeInstallProblemTextLabel1 to localized string "There was a problem with installing FFprobe. This was the error message: " in bundle file path_to_MacYTDL from table "MacYTDL"
				set theFFProbeInstallProblemTextLabel2 to localized string "MacYTDL can't run and will have to quit. When you next start MacYTDL, it will try again to install FFprobe." in bundle file path_to_MacYTDL from table "MacYTDL"
				display dialog theFFProbeInstallProblemTextLabel1 & errorNumber & " " & errStr & return & return & theFFProbeInstallProblemTextLabel2 buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
			end if
			error number -128
		end try
	end if
end install_ffmpeg_ffprobe_intel_OLD


------------------------------------------------------------------------------------
--
-- 		Install/Update Dialog Toolkit - must be installed for MacYTDL to work
--
------------------------------------------------------------------------------------

-- Handler to install Shane Stanley's Dialog Toolkit Plus in user's Script Library - as altered for MacYTDL - delete version before alterations - update if new version available
-- Can't rely on copy in Resources because Monitor dialog (running from osascript) cannot see locations inside this applet
on install_DTP(DTP_file, path_to_MacYTDL, resourcesPath)
	set installAlertActionLabel to quoted form of "_"
	set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
	set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
	set installAlertSubtitle to quoted form of (localized string "Installing Dialog Toolkit" from table "MacYTDL")
	do shell script resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
	set libraries_folder to (POSIX path of (path to home folder) & "Library/Script Libraries/")
	set libraries_folder_quoted to quoted form of libraries_folder
	set DTP_library_MacYTDL to quoted form of ((POSIX path of path_to_MacYTDL) & "Contents/Resources/Script Libraries/DialogToolkitMacYTDL.scptd") as string
	tell application "System Events"
		if not (the folder libraries_folder exists) then
			tell current application to do shell script "mkdir " & libraries_folder_quoted
		end if
	end tell
	do shell script "cp -R " & DTP_library_MacYTDL & " " & libraries_folder_quoted
end install_DTP


------------------------------------------------------------------------------------------------------------------------------------------
--
-- 		Install Myriad Tables Lib - must be installed for formats.scpt to work with Auto download
--
------------------------------------------------------------------------------------------------------------------------------------------

-- Handler to install Shane Stanley's Myriad Tables Lib in user's Script Library - called on startup and by set_settings()
-- Can't use copy in Resources because the Service (which might call formats.scpt) cannot see script libraries inside this applet
on install_Myriad(Myriad_file, path_to_MacYTDL, resourcesPath)
	set installAlertActionLabel to quoted form of "_"
	set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
	set installAlertMessage to quoted form of (localized string "started." from table "MacYTDL")
	set installAlertSubtitle to quoted form of (localized string "Installing Myriad Tables Lib" from table "MacYTDL")
	do shell script resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 5 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
	set libraries_folder to (POSIX path of (path to home folder) & "Library/Script Libraries/")
	set libraries_folder_quoted to quoted form of libraries_folder
	set Myriad_library_MacYTDL to quoted form of ((POSIX path of path_to_MacYTDL) & "Contents/Resources/Script Libraries/Myriad Tables Lib.scptd") as string
	tell application "System Events"
		if not (the folder libraries_folder exists) then
			tell current application to do shell script "mkdir " & libraries_folder_quoted
		end if
	end tell
	do shell script "cp -R " & Myriad_library_MacYTDL & " " & libraries_folder_quoted
end install_Myriad


---------------------------------------------------
--
-- 		Check for MacYTDL updates
--
---------------------------------------------------

-- Handler that checks for new version of MacYTDL and downloads if user agrees - called by Utilities()
on check_MacYTDL(downloadsFolder_Path, diag_Title, theButtonOKLabel, theButtonNoLabel, theButtonYesLabel, MacYTDL_version, MacYTDL_custom_icon_file)
	-- Get version of MacYTDL available from GitHub
	-- If user is offline or another error, returns to main_dialog()
	set MacYTDL_site_URL to "https://github.com/section83/MacYTDL/releases/"
	try
		set MacYTDL_releases_page to do shell script "curl " & MacYTDL_site_URL & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
	on error errMsg
		set theMacYTDLCurlErrorLabel to localized string "There was an error with looking for the MacYTDL web page. The error was: " & errMsg & ", and the URL that produced the error was: " & MacYTDL_site_URL & ". Try again later and/or send a message to macytdl@gmail.com with the details." from table "MacYTDL"
		display dialog theMacYTDLCurlErrorLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
	end try
	if MacYTDL_releases_page is "" then
		set theMacYTDLPageErrorLabel to localized string "There was a problem with checking for MacYTDL updates. Perhaps you are not connected to the internet or GitHub is currently not available." from table "MacYTDL"
		display dialog theMacYTDLPageErrorLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
	else
		set MacYTDL_version_start to (offset of "Version" in MacYTDL_releases_page) + 8
		set MacYTDL_version_end to (offset of " – " in MacYTDL_releases_page) - 1
		set MacYTDL_version_check to text MacYTDL_version_start thru MacYTDL_version_end of MacYTDL_releases_page
		if MacYTDL_version_check is not equal to MacYTDL_version then
			set theMacYTDLNewVersionAvailLabel1 to localized string "A new version of MacYTDL is available. You have version" from table "MacYTDL"
			set theMacYTDLNewVersionAvailLabel2 to localized string "The latest version is" from table "MacYTDL"
			set theMacYTDLNewVersionAvailLabel3 to localized string "Would you like to download it now ?" from table "MacYTDL"
			set MacYTDL_update_text to theMacYTDLNewVersionAvailLabel1 & " " & MacYTDL_version & ". " & theMacYTDLNewVersionAvailLabel2 & " " & MacYTDL_version_check & "." & return & return & theMacYTDLNewVersionAvailLabel3
			tell me to activate
			set MacYTDL_install_answ to button returned of (display dialog MacYTDL_update_text buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if MacYTDL_install_answ is theButtonYesLabel then
				set MacYTDL_download_file to quoted form of (downloadsFolder_Path & "/MacYTDL-v" & MacYTDL_version_check & ".dmg")
				do shell script "curl -L " & MacYTDL_site_URL & "download/" & MacYTDL_version_check & "/MacYTDL-v" & MacYTDL_version_check & ".dmg -o " & MacYTDL_download_file
				set theMacYTDLDownloadedTextLabel1 to localized string "A copy of version" from table "MacYTDL"
				set theMacYTDLDownloadedTextLabel2 to localized string "of MacYTDL has been saved into your MacYTDL downloads folder." from table "MacYTDL"
				display dialog theMacYTDLDownloadedTextLabel1 & " " & MacYTDL_version_check & " " & theMacYTDLDownloadedTextLabel2 with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			end if
		else
			set theMacYTDLUpToDateLabel to localized string "Your copy of MacYTDL is up to date. It is version " from table "MacYTDL"
			display dialog theMacYTDLUpToDateLabel & MacYTDL_version with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		end if
	end if
end check_MacYTDL


---------------------------------------------------
--
-- 	Invite user to install AtomicParsley
--
---------------------------------------------------

-- If AtomicParsley is not installed, ask user if they want it.  If so, go to install_MacYTDLatomic handler.  Only applies if user has youtube-dl.
on ask_user_install_Atomic(usr_bin_folder, path_to_MacYTDL, diag_Title, MacYTDL_custom_icon_file, theButtonOKLabel, theButtonYesLabel)
	tell me to activate
	set macYTDL_Atomic_file to usr_bin_folder & "AtomicParsley"
	tell application "System Events"
		if not (exists file macYTDL_Atomic_file) then
			set no_Parsley to "No"
		else
			set no_Parsley to "Yes"
		end if
	end tell
	if no_Parsley is "No" then
		set theAtomicNotInstalledTextlabel1 to localized string "Atomic Parsley is not installed. It's not critical but enables thumbnail images provided by web sites to be embedded in downloaded files." in bundle file path_to_MacYTDL from table "MacYTDL"
		set theAtomicNotInstalledTextlabel2 to localized string "Would you like Atomic Parsley installed ? You can install it later on if you prefer. Note: You may need to provide administrator credentials." in bundle file path_to_MacYTDL from table "MacYTDL"
		set theAtomicNotInstalledButtonNolabel to localized string "No thanks" in bundle file path_to_MacYTDL from table "MacYTDL"
		set Install_Atomic_text to theAtomicNotInstalledTextlabel1 & return & return & theAtomicNotInstalledTextlabel2
		set Install_MacYTDL_Atomic to button returned of (display dialog Install_Atomic_text buttons {theAtomicNotInstalledButtonNolabel, theButtonYesLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
		if Install_MacYTDL_Atomic is theButtonYesLabel then
			my install_MacYTDLatomic(diag_Title, theButtonOKLabel, path_to_MacYTDL, usr_bin_folder)
		end if
	end if
end ask_user_install_Atomic


---------------------------------------------------
--
-- 	Install Atomic Parsley
--
---------------------------------------------------

-- Handler for installing Atomic Parsley and updating Service menu - copy from Resource folder to /user/local/bin - separated out to avoid conflict with System Events - also called by Utilities dialog
on install_MacYTDLatomic(diag_Title, theButtonOKLabel, path_to_MacYTDL, usr_bin_folder)
	set getAtomic to quoted form of (POSIX path of path_to_MacYTDL) & "Contents/Resources/AtomicParsley"
	try
		do shell script "cp -R " & getAtomic & " " & usr_bin_folder with administrator privileges
		-- trap case where user cancels credentials dialog
	on error number -128
		return
	end try
end install_MacYTDLatomic


---------------------------------------------------
--
-- 	Remove Atomic Parsley
--
---------------------------------------------------

on remove_MacYTDLatomic(path_to_MacYTDL, theButtonOKLabel, diag_Title, MacYTDL_custom_icon_file)
	set getAtomic to quoted form of (POSIX path of path_to_MacYTDL) & "Contents/Resources/AtomicParsley"
	try
		do shell script "mv /usr/local/bin/AtomicParsley" & " ~/.trash/AtomicParsley" with administrator privileges
		set theAtomicRemovedlabel to localized string "Atomic Parsley has been removed." in bundle file path_to_MacYTDL from table "MacYTDL"
		display dialog theAtomicRemovedlabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 100
		-- trap case where user cancels credentials dialog
	on error number -128
		return
	end try
end remove_MacYTDLatomic


---------------------------------------------------
--
-- 		Invite user to install Service
--
---------------------------------------------------

-- Ask user if they would like the MacYTDL service installed. If so, copy from Resource folder to user's Services folder - only ask once
on ask_user_install_service(path_to_MacYTDL, theButtonYesLabel, diag_Title, MacYTDL_custom_icon_file)
	tell me to activate
	set services_Folder to (POSIX path of (path to home folder) & "/Library/Services/")
	set macYTDL_service_file to services_Folder & "Send-URL-To-MacYTDL.workflow"
	tell application "System Events"
		if not (exists file macYTDL_service_file) then
			set theInstallServiceTextLabel1 to localized string "The MacYTDL Service is not installed. It's not critical but enables calling MacYTDL from within the web browser and you can also assign a keystroke shortcut to copy a video URL and run MacYTDL. However, after the Service is installed, you will need to grant Assistive Access to another part of MacYTDL. There are instructions in the Help file." in bundle file path_to_MacYTDL from table "MacYTDL"
			set theInstallServiceTextLabel2 to localized string "Would you like the Service installed ? You can install the Service later on if you prefer." in bundle file path_to_MacYTDL from table "MacYTDL"
			set theServiceNotInstalledButtonNolabel to localized string "No thanks" in bundle file path_to_MacYTDL from table "MacYTDL"
			set Install_service_buttons to {theServiceNotInstalledButtonNolabel, theButtonYesLabel}
			set Install_MacYTDL_service to button returned of (display dialog theInstallServiceTextLabel1 & return & return & theInstallServiceTextLabel2 buttons Install_service_buttons default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if Install_MacYTDL_service is theButtonYesLabel then
				my install_MacYTDLservice(path_to_MacYTDL)
			end if
		end if
	end tell
end ask_user_install_service


---------------------------------------------------
--
-- 			Install Service
--
---------------------------------------------------

-- Handler for installing the Service and updating Services menu - called by ask_user_install_service() when first running MacYTDL; by Settings and Utilities dialogs
on install_MacYTDLservice(path_to_MacYTDL)
	set services_Folder to (POSIX path of (path to home folder) & "Library/Services")
	tell application "System Events"
		if not (the folder services_Folder exists) then
			tell current application to do shell script "mkdir -p " & services_Folder
		end if
	end tell
	set getURL_service to quoted form of (POSIX path of path_to_MacYTDL) & "Contents/Resources/Send-URL-To-MacYTDL.workflow"
	do shell script "cp -R " & getURL_service & " " & services_Folder & ";sleep 1;killall pbs;/System/Library/CoreServices/pbs -flush"
end install_MacYTDLservice


------------------------------------------------------------------------------------------------------------------
--
-- 	Check version of MacYTDL Service - update if old version - called when starting MacYTDL
--
------------------------------------------------------------------------------------------------------------------
-- Check whether Service is installed and if so, which version - if version is old, update to new - if auto-downloads turned on and user on 10.15+ update NSMenuItem
on update_MacYTDLservice(path_to_MacYTDL, MacYTDL_prefs_file, show_yt_dlp)
	set Service_exists_flag to "No"
	set user_services_file_posix to (POSIX path of (path to home folder) & "Library/Services/Send-URL-To-MacYTDL.workflow")
	set user_services_Folder_nonposix to ((path to home folder as text) & "Library:Services:")
	set user_service_file_nonposix to (user_services_Folder_nonposix & "Send-URL-To-MacYTDL.workflow")
	set new_Services_Version_file_nonposix to (path_to_MacYTDL & "Contents:Resources:Send-URL-To-MacYTDL.workflow:Contents:Version.txt")
	set version_from_Bundled_Service to read file new_Services_Version_file_nonposix as text
	set new_Service_file_nonposix_string to (path_to_MacYTDL & "Contents:Resources:Send-URL-To-MacYTDL.workflow") as text
	tell application "System Events"
		if exists file user_service_file_nonposix then
			set Service_exists_flag to "Yes"
		end if
	end tell
	if Service_exists_flag is "Yes" then
		set version_from_users_Service to ""
		try
			set user_service_version_file_nonposix to (user_services_Folder_nonposix & "Send-URL-To-MacYTDL.workflow:Contents:Version.txt")
			set version_from_users_Service to read file user_service_version_file_nonposix as text
		on error errMsg number errnum
			if errnum is -1700 or errnum is -43 then
				set version_from_users_Service to "NoVersion"
			end if
		end try
		if (version_from_users_Service is not equal to version_from_Bundled_Service) then
			do shell script "rm -R " & quoted form of (user_services_file_posix)
			do shell script "cp -R " & (quoted form of (POSIX path of new_Service_file_nonposix_string)) & " " & (quoted form of user_services_file_posix) & ";sleep 1;killall pbs;/System/Library/CoreServices/pbs -flush"
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set DL_auto to value of property list item "Auto_Download"
				end tell
			end tell
			-- v1.25 – took out yt-dlp-legacy to isolate Macs in 10.14 and lower
			-- if DL_auto is true and (show_yt_dlp is "yt-dlp" or show_yt_dlp is "yt-dlp-legacy") then
			if DL_auto is true and show_yt_dlp is "yt-dlp" then
				set new_value to "Download Video Now"
				set Service_file_plist_file to ((path to home folder) & "Library:Services:Send-URL-To-MacYTDL.workflow:Contents:info.plist") as text
				tell application "System Events"
					tell property list file Service_file_plist_file
						set value of property list item "default" of property list item "NSMenuItem" of property list item 1 of property list items of contents to new_value
					end tell
				end tell
			end if
		end if
	end if
end update_MacYTDLservice


---------------------------------------------------
--
-- 	User wants to remove MacYTDL Service
--
---------------------------------------------------

on remove_MacYTDLservice()
	set services_Folder to (POSIX path of (path to home folder) & "Library/Services/")
	set macYTDL_service_file to services_Folder & "Send-URL-To-MacYTDL.workflow"
	tell application "System Events"
		if (the file macYTDL_service_file exists) then
			tell current application to do shell script "rm -R " & quoted form of (macYTDL_service_file) & ";sleep 1;killall pbs;/System/Library/CoreServices/pbs -flush"
		end if
	end tell
end remove_MacYTDLservice


---------------------------------------------------
--
-- 	Check that settings file is up-to-date
--
---------------------------------------------------
-- Check whether Settings file is up to date - call relevant handlers to add missing items - Called my Main and Utilities
on check_settings(MacYTDL_prefs_file, old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version)
	tell application "System Events"
		try
			tell property list file MacYTDL_prefs_file
				set test_DL_subtitles to value of property list item "SubTitles"
			end tell
			-- Old version had string prefs while new version has boolean prefs for 4 items - call set_preferences to delete and recreate if user wishes
			-- This is quite old - should try to remove it and replace with something simpler
			if test_DL_subtitles is "Yes" or test_DL_subtitles is "No" then
				set old_version_prefs to "Yes"
				my set_preferences(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version)
			end if
		on error
			-- Means the plist file exists but there is a problem (eg. it's empty because of an earlier crash) - just delete it, re-create and populate as if replacing the old version
			set old_version_prefs to "Yes"
			my set_preferences(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version)
		end try
		
		-- Check on need to add new v1.10 item to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "Show_Settings_before_Download") then
				my add_v1_10_preference(MacYTDL_prefs_file)
			end if
		end tell
		-- Check on need to add new v1.11 item to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "final_Position") then
				my add_v1_11_preference(MacYTDL_prefs_file, X_position, Y_position)
			end if
		end tell
		-- Check on need to add new v1.12.1 item to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "Subtitles_Language") then
				my add_v1_12_1_preference(MacYTDL_prefs_file)
			end if
		end tell
		-- Check on need to add new v1.16 write-auto-sub item to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "Subtitles_YTAuto") then
				my add_v1_16_preference(MacYTDL_prefs_file, theBestLabel)
			end if
		end tell
		-- Check on need to add new v1.17 proxy settings to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "Use_Proxy") then
				my add_v1_17_preference(MacYTDL_prefs_file)
			end if
		end tell
		-- Check on need to add new v1.18 proxy settings to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "Use_Cookies") then
				my add_v1_18_preference(MacYTDL_prefs_file)
			end if
		end tell
		-- Check on need to add new v1.19 yt-dlp settings to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "Use_ytdlp") then
				my add_v1_19_preference(MacYTDL_prefs_file, show_yt_dlp)
			end if
		end tell
		-- Check on need to add new v1.20 timestamps setting to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "Add_TimeStamps") then
				my add_v1_20_preference(MacYTDL_prefs_file)
			end if
		end tell
		-- Check on need to add new v1.23 Quicktime caompatibility setting to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "Make_QuickTime_Compat") then
				my add_v1_23_preference(MacYTDL_prefs_file)
			end if
		end tell
		-- Check on need to add new v1.24 get formats list setting to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "Get_Formats_List") then
				my add_v1_24_preference(MacYTDL_prefs_file)
			end if
		end tell
		-- Check on need to add new v1.26 get formats list setting to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "Discard_URL") then
				my add_v1_26_preference(MacYTDL_prefs_file, theBestLabel)
			end if
		end tell
		-- Check on need to add new v1.27 clear batch setting to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "Clear_Batch") then
				my add_v1_27_preference(MacYTDL_prefs_file)
			end if
		end tell
	end tell
end check_settings

-------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- 	Handlers to update format of Preferences file for v1.10, 1.11, 1.12.1, 1.16, 1.17, 1.18, 1.19, 1.20, 1.21, 1.23, v1.24 and v1.26
--
-------------------------------------------------------------------------------------------------------------------------------------------------------

on add_v1_10_preference(MacYTDL_prefs_file)
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:boolean, name:"Show_Settings_before_Download", value:true}
		end tell
	end tell
end add_v1_10_preference

on add_v1_11_preference(MacYTDL_prefs_file, X_position, Y_position)
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:list, name:"final_Position", value:{X_position, Y_position}}
		end tell
	end tell
end add_v1_11_preference

on add_v1_12_1_preference(MacYTDL_prefs_file)
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:string, name:"Subtitles_Language", value:"en"}
		end tell
	end tell
end add_v1_12_1_preference

on add_v1_16_preference(MacYTDL_prefs_file, theBestLabel)
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:boolean, name:"Subtitles_YTAuto", value:false}
			make new property list item at end with properties {kind:string, name:"Audio_Codec", value:theBestLabel}
			make new property list item at end with properties {kind:boolean, name:"Limit_Rate", value:false}
			make new property list item at end with properties {kind:real, name:"Limit_Rate_Value", value:0}
		end tell
	end tell
end add_v1_16_preference

on add_v1_17_preference(MacYTDL_prefs_file)
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:boolean, name:"Use_Proxy", value:false}
			make new property list item at end with properties {kind:string, name:"Proxy_URL", value:""}
		end tell
	end tell
end add_v1_17_preference

on add_v1_18_preference(MacYTDL_prefs_file)
	set theNoCookielabel to localized string "No Cookie File" from table "MacYTDL"
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:boolean, name:"Use_Cookies", value:false}
			make new property list item at end with properties {kind:string, name:"Cookies_Location", value:("/" & theNoCookielabel)}
			make new property list item at end with properties {kind:boolean, name:"Use_Custom_Output_Template", value:false}
			make new property list item at end with properties {kind:string, name:"Custom_Output_Template", value:""}
		end tell
	end tell
end add_v1_18_preference

on add_v1_19_preference(MacYTDL_prefs_file, show_yt_dlp)
	-- Need to generalise show_yt_dlp so that only "youtube-dl" or "yt-dlp" is stored in plist
	if show_yt_dlp is "yt-dlp-legacy" then
		set preferences_show_yt_dlp to "yt-dlp"
	else
		set preferences_show_yt_dlp to show_yt_dlp
	end if
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:string, name:"Use_ytdlp", value:preferences_show_yt_dlp}
		end tell
	end tell
end add_v1_19_preference

on add_v1_20_preference(MacYTDL_prefs_file)
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:string, name:"Add_TimeStamps", value:false}
			make new property list item at end with properties {kind:boolean, name:"Use_Custom_Settings", value:false}
			make new property list item at end with properties {kind:string, name:"Custom_Settings", value:""}
		end tell
	end tell
end add_v1_20_preference

on add_v1_21_preference(MacYTDL_prefs_file, YTDL_version, MacYTDL_preferences_path)
	-- Need HFS path to preferences for location of saved settings
	set MacYTDL_preferences_path_nonPosix to POSIX file MacYTDL_preferences_path as text
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:string, name:"YTDL_YTDLP_version", value:YTDL_version}
			make new property list item at end with properties {kind:boolean, name:"Auto_Download", value:false}
			make new property list item at end with properties {kind:string, name:"Saved_Settings_Location", value:MacYTDL_preferences_path_nonPosix}
			make new property list item at end with properties {kind:string, name:"Name_Of_Settings_In_Use", value:"MacYTDL"}
		end tell
	end tell
end add_v1_21_preference

on add_v1_23_preference(MacYTDL_prefs_file)
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:boolean, name:"Make_QuickTime_Compat", value:false}
		end tell
	end tell
end add_v1_23_preference

on add_v1_24_preference(MacYTDL_prefs_file)
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:boolean, name:"Get_Formats_List", value:false}
		end tell
	end tell
end add_v1_24_preference

on add_v1_26_preference(MacYTDL_prefs_file, theBestLabel)
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:boolean, name:"Discard_URL", value:false}
			make new property list item at end with properties {kind:string, name:"Resolution_Limit", value:theBestLabel}
			make new property list item at end with properties {kind:string, name:"Dont_Use_Parts", value:true}
			make new property list item at end with properties {kind:string, name:"Parallel", value:false}
			make new property list item at end with properties {kind:string, name:"No_Warnings", value:false}
			make new property list item at end with properties {kind:string, name:"Delete_Partial", value:false}
		end tell
	end tell
end add_v1_26_preference

on add_v1_27_preference(MacYTDL_prefs_file)
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:boolean, name:"Clear_Batch", value:false}
		end tell
	end tell
end add_v1_27_preference


---------------------------------------------------
--
-- 		Check v1.21 settings are in place
--
---------------------------------------------------
-- Check on need to add new v1.21 YTDL/yt-dlp version to the prefs file - called on startup and when user restores an old settings file
on check_settings_current(MacYTDL_prefs_file, DL_Use_YTDLP, MacYTDL_preferences_path, youtubedl_file, ytdlp_file)
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "YTDL_YTDLP_version") then
				if DL_Use_YTDLP is "youtube-dl" then
					set YTDL_version to do shell script youtubedl_file & " --version"
				else
					set YTDL_version to do shell script ytdlp_file & " --version"
				end if
				my add_v1_21_preference(MacYTDL_prefs_file, YTDL_version, MacYTDL_preferences_path)
			end if
			if not (exists property list item "Make_QuickTime_Compat") then
				my add_v1_23_preference(MacYTDL_prefs_file)
			end if
		end tell
	end tell
end check_settings_current


---------------------------------------------------
--
-- 		Get current preference settings
--
---------------------------------------------------

-- Handler for reading the users' preferences file - called by set_settings, utilities, open_batch_processing and main_dialog
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
			set DL_Proxy_URL to value of property list item "Proxy_URL"
			set DL_Remux_format to value of property list item "Remux_Format"
			set DL_Parallel to value of property list item "Parallel"
			set DL_Resolution_Limit to value of property list item "Resolution_Limit"
			set DL_Saved_Settings_Location to value of property list item "Saved_Settings_Location"
			set DL_Show_Settings to value of property list item "Show_Settings_before_Download"
			set DL_subtitles_format to value of property list item "Subtitles_Format"
			set DL_subtitles to value of property list item "SubTitles"
			set DL_STEmbed to value of property list item "SubTitles_Embedded"
			set DL_YTAutoST to value of property list item "Subtitles_YTAuto"
			set DL_STLanguage to value of property list item "Subtitles_Language"
			set DL_Thumbnail_Embed to value of property list item "Thumbnail_Embed"
			set DL_Thumbnail_Write to value of property list item "Thumbnail_Write"
			set DL_Use_Cookies to value of property list item "Use_Cookies"
			set DL_Use_Custom_Settings to value of property list item "Use_Custom_Settings"
			set DL_Use_Custom_Template to value of property list item "Use_Custom_Output_Template"
			set DL_Dont_Use_Parts to value of property list item "Dont_Use_Parts"
			set DL_Use_Proxy to value of property list item "Use_Proxy"
			set DL_Use_YTDLP to value of property list item "Use_ytdlp"
			set DL_verbose to value of property list item "Verbose"
			set YTDL_version to value of property list item "YTDL_YTDLP_version"
		end tell
	end tell
end read_settings


---------------------------------------------------------
--
-- 	 Create preference settings file with defaults
--
---------------------------------------------------------

-- Handler for creating preferences file and setting default preferences - called by Main if prefs don't exist or are faulty
on set_preferences(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version, MacYTDL_custom_icon_file)
	set installAlertActionLabel to quoted form of "_"
	set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
	set installAlertMessage to quoted form of (localized string "Please wait." from table "MacYTDL")
	set installAlertSubtitle to quoted form of (localized string "Creating MacYTDL preferences." from table "MacYTDL")
	do shell script quoted form of (resourcesPath & "alerter") & " -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
	-- Need to generalise show_yt_dlp so that only "youtube-dl" or "yt-dlp" is stored in plist
	if show_yt_dlp is "yt-dlp-legacy" then
		set preferences_show_yt_dlp to "yt-dlp"
	else
		set preferences_show_yt_dlp to show_yt_dlp
	end if
	set downloadsFolder to "Desktop"
	set downloadsFolder_Path to (POSIX path of (path to home folder) & downloadsFolder)
	if old_version_prefs is "Yes" then
		-- Prefs file is old or faulty - warn user it must be replaced for MacYTDL to work
		set theInstallMacYTDLPrefsTextLabel to localized string "The MacYTDL Preferences file needs to be replaced. To work, MacYTDL needs the latest version of the Preferences file. Do you wish to continue ?" in bundle file path_to_MacYTDL from table "MacYTDL"
		tell me to activate
		set ask_update to display dialog theInstallMacYTDLPrefsTextLabel buttons {theButtonNoLabel, theButtonYesLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		set Install_MacYTDL to button returned of ask_update
		if Install_MacYTDL is theButtonNoLabel then
			error number -128
		end if
		tell application "Finder"
			delete MacYTDL_prefs_file as POSIX file
		end tell
	else
		-- Set path to default downloads folder and create it
		tell application "System Events"
			if not (exists folder MacYTDL_preferences_path) then
				tell current application to do shell script "mkdir " & MacYTDL_preferences_path
			end if
		end tell
	end if
	-- Need HFS path to preferences for locaton of saved settings
	set MacYTDL_preferences_path_nonPosix to (POSIX file MacYTDL_preferences_path) as text
	-- Create new Preferences file and set the default preferences
	set theNoCookielabel to localized string "No Cookie File" from table "MacYTDL"
	tell application "System Events"
		set thePropertyListFile to make new property list file with properties {name:MacYTDL_prefs_file}
		tell property list items of thePropertyListFile
			make new property list item at end with properties {kind:string, name:"DownloadFolder", value:downloadsFolder_Path} -- <= Path has no trailing slash
			make new property list item at end with properties {kind:string, name:"FileFormat", value:theDefaultLabel}
			make new property list item at end with properties {kind:boolean, name:"Audio_Only", value:false}
			make new property list item at end with properties {kind:boolean, name:"Auto_Check_YTDL_Update", value:false}
			make new property list item at end with properties {kind:boolean, name:"SubTitles", value:false}
			make new property list item at end with properties {kind:boolean, name:"SubTitles_Embedded", value:false}
			make new property list item at end with properties {kind:string, name:"Subtitles_Format", value:theBestLabel}
			make new property list item at end with properties {kind:boolean, name:"Description", value:false}
			make new property list item at end with properties {kind:boolean, name:"Over-writes allowed", value:false}
			make new property list item at end with properties {kind:string, name:"Remux_Format", value:theNoRemuxLabel}
			make new property list item at end with properties {kind:boolean, name:"Keep_Remux_Original", value:false}
			make new property list item at end with properties {kind:boolean, name:"Thumbnail_Write", value:false}
			make new property list item at end with properties {kind:boolean, name:"Thumbnail_Embed", value:false}
			make new property list item at end with properties {kind:boolean, name:"Add_Metadata", value:false}
			make new property list item at end with properties {kind:boolean, name:"Verbose", value:false}
			make new property list item at end with properties {kind:boolean, name:"Show_Settings_before_Download", value:false}
			make new property list item at end with properties {kind:list, name:"final_Position", value:{X_position, Y_position}}
			make new property list item at end with properties {kind:string, name:"Subtitles_Language", value:"en"}
			make new property list item at end with properties {kind:boolean, name:"Subtitles_YTAuto", value:false}
			make new property list item at end with properties {kind:string, name:"Audio_Codec", value:theBestLabel}
			make new property list item at end with properties {kind:boolean, name:"Limit_Rate", value:false}
			make new property list item at end with properties {kind:real, name:"Limit_Rate_Value", value:0}
			make new property list item at end with properties {kind:boolean, name:"Use_Proxy", value:false}
			make new property list item at end with properties {kind:string, name:"Proxy_URL", value:""}
			make new property list item at end with properties {kind:boolean, name:"Use_Cookies", value:false}
			make new property list item at end with properties {kind:string, name:"Cookies_Location", value:("/" & theNoCookielabel)}
			make new property list item at end with properties {kind:boolean, name:"Use_Custom_Output_Template", value:false}
			make new property list item at end with properties {kind:string, name:"Custom_Output_Template", value:""}
			make new property list item at end with properties {kind:string, name:"Use_ytdlp", value:preferences_show_yt_dlp}
			make new property list item at end with properties {kind:boolean, name:"Add_TimeStamps", value:false}
			make new property list item at end with properties {kind:boolean, name:"Use_Custom_Settings", value:false}
			make new property list item at end with properties {kind:string, name:"Custom_Settings", value:""}
			make new property list item at end with properties {kind:string, name:"YTDL_YTDLP_version", value:YTDL_version}
			make new property list item at end with properties {kind:boolean, name:"Auto_Download", value:false}
			make new property list item at end with properties {kind:string, name:"Saved_Settings_Location", value:MacYTDL_preferences_path_nonPosix}
			make new property list item at end with properties {kind:string, name:"Name_Of_Settings_In_Use", value:"MacYTDL"}
			make new property list item at end with properties {kind:boolean, name:"Make_QuickTime_Compat", value:false}
			make new property list item at end with properties {kind:boolean, name:"Get_Formats_List", value:false}
			make new property list item at end with properties {kind:boolean, name:"Discard_URL", value:false}
			make new property list item at end with properties {kind:string, name:"Resolution_Limit", value:theBestLabel}
			make new property list item at end with properties {kind:string, name:"Dont_Use_Parts", value:false}
			make new property list item at end with properties {kind:string, name:"Parallel", value:false}
			make new property list item at end with properties {kind:string, name:"No_Warnings", value:false}
			make new property list item at end with properties {kind:string, name:"Delete_Partial", value:false}
			make new property list item at end with properties {kind:boolean, name:"Clear_Batch", value:false}
		end tell
	end tell
end set_preferences


---------------------------------------------------
--
-- 				Set Settings
--
---------------------------------------------------

-- Handler for showing dialog to set various MacYTDL and youtube-dl/yt-dlp settings
on set_admin_settings(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version, MacYTDL_custom_icon_file, theButtonCancelLabel, window_Position, theButtonReturnLabel, MacYTDL_custom_icon_file_posix)
	-- In case user accidentally deletes the prefs plist file
	tell application "System Events"
		if exists file MacYTDL_prefs_file then
			my read_settings(MacYTDL_prefs_file)
		else
			my set_preferences(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version, MacYTDL_custom_icon_file)
			set prefs_exists to true
		end if
	end tell
	set DL_format to localized string DL_format from table "MacYTDL"
	set DL_subtitles_format to localized string DL_subtitles_format from table "MacYTDL"
	set DL_Remux_format to localized string DL_Remux_format from table "MacYTDL"
	set DL_audio_codec to localized string DL_audio_codec from table "MacYTDL"
	
	-- Set variables for the settings dialog	
	set theAdminDiagPromptLabel to localized string "Admin" from table "MacYTDL"
	set admin_diag_prompt to theAdminDiagPromptLabel
	set accViewWidth to 450
	set accViewInset to 0
	
	-- Set buttons and controls
	set theButtonsSaveLabel to localized string "Save" from table "MacYTDL"
	set theSettingsButtonLabel to localized string "Settings" from table "MacYTDL"
	set {theButtons, minWidth} to create buttons {theButtonCancelLabel, theSettingsButtonLabel, theButtonsSaveLabel} button keys {".", ",", ""} default button 3
	--if minWidth > accViewWidth then set accViewWidth to minWidth --<= Not needed as two buttons always narrower than the dialog - keep in case things change
	set {theSettingsRule, theTop} to create rule 3 rule width accViewWidth
	-- set the CheckBoxYTDLPLabel to localized string "YT-DLP" from table "MacYTDL"
	set theCheckboxNoWarningsLabel to localized string "Suppress warnings from" from table "MacYTDL"
	--	set {settings_theCheckbox_No_Warnings, theTop} to create checkbox theCheckboxNoWarningsLabel left inset 70 bottom (theTop + 3) max width 200 initial state DL_No_Warnings
	set {settings_theCheckbox_No_Warnings, theTop} to create checkbox theCheckboxNoWarningsLabel & " " & "yt-dlp" left inset 70 bottom (theTop + 3) max width 200 initial state DL_No_Warnings
	set theCheckboxDeletPartialLabel to localized string "Delete partially downloaded files" from table "MacYTDL"
	set {settings_theCheckbox_Delete_Partial, theTop} to create checkbox theCheckboxDeletPartialLabel left inset 70 bottom (theTop + 3) max width 200 initial state DL_Delete_Partial
	--	set theCheckboxUsePartsLabel to localized string "Don't use \"part\" file names in download" from table "MacYTDL"
	set theCheckboxUsePartsLabel to localized string "Don't use “part file” names in download" from table "MacYTDL"
	set {settings_theCheckbox_Use_Parts, theTop} to create checkbox theCheckboxUsePartsLabel left inset 70 bottom (theTop + 3) max width 200 initial state DL_Dont_Use_Parts
	set theCheckboxClearBatchLabel to localized string "Clear completed URLs from batch file" from table "MacYTDL"
	set {settings_theCheckbox_ClearBatch, theTop} to create checkbox theCheckboxClearBatchLabel left inset 70 bottom (theTop + 3) max width 200 initial state DL_Clear_Batch
	set theCheckboxDiscardURLLabel to localized string "Discard URL after download" from table "MacYTDL"
	set {settings_theCheckbox_Discard_URL, theTop} to create checkbox theCheckboxDiscardURLLabel left inset 70 bottom (theTop + 3) max width 200 initial state DL_discard_URL
	set theCheckboxQTCompatLabel to localized string "QT compatible video" from table "MacYTDL"
	set {settings_theCheckbox_QT_Compat, theTop} to create checkbox theCheckboxQTCompatLabel left inset 70 bottom (theTop + 3) max width 200 initial state DL_QT_Compat
	set theCheckboxParallelLabel to localized string "Download videos in parallel" from table "MacYTDL"
	set {settings_theCheckbox_Parallel, theTop} to create checkbox theCheckboxParallelLabel left inset 70 bottom (theTop + 3) max width 200 initial state DL_Parallel
	set theCheckboxLimitRateLabel to localized string "Limit download speed (MB/sec)" from table "MacYTDL"
	set {settings_theCheckbox_Limit_Rate, theTop, RateBoxLeftDist} to create checkbox theCheckboxLimitRateLabel left inset 70 bottom (theTop + 3) max width 200 initial state DL_Limit_Rate
	set {settings_theField_LimitRateValue, theTop} to create field DL_Limit_Rate_Value left inset (RateBoxLeftDist + 70) bottom (theTop - 20) field width 40
	set theCheckboxAutoDownloadLabel to localized string "Automatic download" from table "MacYTDL"
	set {settings_theCheckbox_Auto_Download, theTop} to create checkbox theCheckboxAutoDownloadLabel left inset 70 bottom (theTop + 1) max width 200 initial state DL_auto
	set theCheckboxShowSettingsLabel to localized string "Show settings before download" from table "MacYTDL"
	set {settings_theCheckbox_Show_Settings, theTop} to create checkbox theCheckboxShowSettingsLabel left inset 70 bottom (theTop + 3) max width 200 initial state DL_Show_Settings
	-- Hide the legacy version of yt-dlp - too confusing otherwise
	if DL_Use_YTDLP is "yt-dlp-legacy" then
		set settings_DL_Use_YTDLP to "yt-dlp"
	else
		set settings_DL_Use_YTDLP to DL_Use_YTDLP
	end if
	set theCheckboxCheckYTDLOnStartLabel to (localized string "Check" from table "MacYTDL") & " " & settings_DL_Use_YTDLP & " " & (localized string "version on startup" from table "MacYTDL")
	set {settings_theCheckbox_Auto_YTDL_Check, theTop} to create checkbox theCheckboxCheckYTDLOnStartLabel left inset 70 bottom (theTop + 3) max width 250 initial state DL_YTDL_auto_check
	set theCheckboxTimeStampsLabel to localized string "Add timestamps to log" from table "MacYTDL"
	set {settings_theCheckbox_TimeStamps, theTop} to create checkbox theCheckboxTimeStampsLabel left inset 70 bottom (theTop + 3) max width 250 initial state DL_TimeStamps
	set theCheckboxVerboseLabel to localized string "Verbose logging" from table "MacYTDL"
	set {settings_theCheckbox_Verbose, theTop} to create checkbox theCheckboxVerboseLabel left inset 70 bottom (theTop + 3) max width 250 initial state DL_verbose
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 50 view width 64 view height 64 scale image scale proportionally
	set {settings_prompt, theTop} to create label admin_diag_prompt left inset 0 bottom (theTop - 5) max width accViewWidth aligns center aligned with bold type
	set settings_allControls to {theSettingsRule, settings_theCheckbox_No_Warnings, settings_theCheckbox_Delete_Partial, settings_theCheckbox_Use_Parts, settings_theCheckbox_Discard_URL, settings_theCheckbox_ClearBatch, settings_theCheckbox_QT_Compat, settings_theCheckbox_Parallel, settings_theCheckbox_Limit_Rate, settings_theField_LimitRateValue, settings_theCheckbox_Auto_Download, settings_theCheckbox_Show_Settings, settings_theCheckbox_Auto_YTDL_Check, settings_theCheckbox_TimeStamps, settings_theCheckbox_Verbose, MacYTDL_icon, settings_prompt}
	
	-- Make sure MacYTDL is in front and show dialog - need to make dialog wider in some languages - use width returned from right most control <= activate if necessary
	tell me to activate
	set calculatedAccViewWidth to accViewWidth
	set {settings_button_returned, settings_button_number_returned, settings_controls_results, finalPosition} to display enhanced window diag_Title buttons theButtons acc view width calculatedAccViewWidth acc view height theTop acc view controls settings_allControls initial position window_Position
	
	-- Has user moved the MacYTDL window - if so, save new position
	if finalPosition is not equal to window_Position then
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "final_Position" to finalPosition
			end tell
		end tell
	end if
	
	if settings_button_number_returned is 3 or settings_button_number_returned is 2 then -- Save Settings
		-- Get control results from settings dialog - numbered choice variables are not used but help ensure correct values go into prefs file
		--set settings_choice_1 to item 1 of settings_controls_results -- <= The ruled line
		set settings_No_Warnings_choice to item 2 of settings_controls_results -- <= Suppress warnings
		set settings_Delete_Partial_choice to item 3 of settings_controls_results -- <= Delete partial downloads choice
		set settings_DontUseParts_choice to item 4 of settings_controls_results -- <= Use parts in DL file names choice
		set settings_Discard_URL_choice to item 5 of settings_controls_results -- <= Discard URL on download choice
		set settings_Clear_Batch_choice to item 6 of settings_controls_results -- <= Discard URL on download choice
		set settings_QT_Compat_choice to item 7 of settings_controls_results -- <= Make download QT compatible
		set settings_parallel_choice to item 8 of settings_controls_results -- <= Download multiple videos in parallel
		set settings_limit_rate_choice to item 9 of settings_controls_results -- <= Limit rate choice
		set settings_limit_rate_value_choice to item 10 of settings_controls_results -- <= Limit rate value choice
		set settings_auto_download_choice to item 11 of settings_controls_results -- <= Automatic download using Service
		set settings_show_settings_choice to item 12 of settings_controls_results -- <= Show settings before download choice
		set settings_YTDL_auto_choice to item 13 of settings_controls_results -- <= Auto check YTDL version on startup choice
		set settings_timestamps_choice to item 14 of settings_controls_results -- <= Add timestamps choice
		set settings_verbose_choice to item 15 of settings_controls_results -- <= Verbose choice
		
		-- Save new settings to preferences file - no error checking needed for these
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "No_Warnings" to settings_No_Warnings_choice
				set value of property list item "Delete_Partial" to settings_Delete_Partial_choice
				set value of property list item "Clear_Batch" to settings_Clear_Batch_choice
				set value of property list item "Discard_URL" to settings_Discard_URL_choice
				set value of property list item "Make_QuickTime_Compat" to settings_QT_Compat_choice
				set value of property list item "Parallel" to settings_parallel_choice
				set value of property list item "Show_Settings_before_Download" to settings_show_settings_choice
				set value of property list item "Auto_Check_YTDL_Update" to settings_YTDL_auto_choice
				set value of property list item "Add_TimeStamps" to settings_timestamps_choice
				set value of property list item "Verbose" to settings_verbose_choice
			end tell
		end tell
		
		-- Reverse logic for Dont_Use_parts because using parts is the default
		if settings_DontUseParts_choice is true then
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Dont_Use_Parts" to true
				end tell
			end tell
		else
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Dont_Use_Parts" to false
				end tell
			end tell
		end if
		
		-- If user wants auto-downloads, check Service is installed - install Service if user wants - change NSMenuItem of Service to something more useful if user on macOS 10.15+ - show_yt_dlp is proxy for macOS version - Auto download and get formats list together causes a crash or similar
		set path_to_home_folder to (path to home folder)
		set services_Folder_nonPosix to (path_to_home_folder & "Library:Services:") as text
		set macYTDL_service_file_nonPosix to services_Folder_nonPosix & "Send-URL-To-MacYTDL.workflow"
		set Service_file_plist to (macYTDL_service_file_nonPosix & ":Contents:info.plist")
		set services_Folder to (POSIX path of (path to home folder) & "/Library/Services/")
		set macYTDL_service_file to services_Folder & "Send-URL-To-MacYTDL.workflow"
		set isServiceInstalled to "Yes"
		tell application "System Events"
			if not (exists the file macYTDL_service_file) then
				set isServiceInstalled to "No"
			end if
		end tell
		
		if settings_auto_download_choice is true then
			if isServiceInstalled is "Yes" then
				set new_value to "Download Video Now"
				tell application "System Events"
					tell property list file MacYTDL_prefs_file
						set value of property list item "Auto_Download" to true
					end tell
					-- if show_yt_dlp is "yt-dlp" or show_yt_dlp is "yt-dlp-legacy" then -- This do not work properly on macOS earlier than 10.15 - can take some time to be noticeable in Finder
					if show_yt_dlp is "yt-dlp" then
						try
							tell property list file Service_file_plist
								set value of property list item "default" of property list item "NSMenuItem" of property list item 1 of property list items of contents to new_value
							end tell
						on error errMsg
							display dialog "Trying to change Service menu - error: " & errMsg
						end try
					end if
				end tell
			end if
			if isServiceInstalled is "No" then
				set theNeedServiceLabel to localized string "Sorry, to have automatic downloads, you need to install the MacYTDL Service. Discard settings changes and return to Main, install the Service and turn on auto downloads or save all but Auto-download changes" from table "MacYTDL"
				set theButtonsInstallLabel to localized string "Install" from table "MacYTDL"
				set autoDLNeedService to button returned of (display dialog (theNeedServiceLabel & " ?") with title diag_Title buttons {theButtonReturnLabel, theButtonsInstallLabel, theButtonsSaveLabel} default button 2 with icon file MacYTDL_custom_icon_file giving up after 600)
				if autoDLNeedService is theButtonReturnLabel then
					set branch_execution to "Main"
					return branch_execution
				end if
				if autoDLNeedService is theButtonsInstallLabel then
					my install_MacYTDLservice(path_to_MacYTDL)
					set new_value to "Download Video Now"
					tell application "System Events"
						tell property list file MacYTDL_prefs_file
							set value of property list item "Auto_Download" to settings_auto_download_choice
						end tell
						-- if show_yt_dlp is "yt-dlp" or show_yt_dlp is "yt-dlp-legacy" then -- This does not work properly on macOS earlier than 10.15
						if show_yt_dlp is "yt-dlp" then
							try
								tell property list file Service_file_plist
									set value of property list item "default" of property list item "NSMenuItem" of property list item 1 of property list items of contents to new_value
								end tell
							end try
						end if
					end tell
				end if
				-- if autoDLNeedService is theButtonsSaveLabel -- processing will just continue and auto-download stay unchanged
			end if
			-- v1.26 - Don't know why isServiceInstalled is "Yes" test was here - Service will always be installed when Auto-dL is on and no need to test if auto_dl is already false
			--		else if settings_auto_download_choice is false and isServiceInstalled is "Yes" then
		else if settings_auto_download_choice is false then
			set new_value to "Send-URL-To-MacYTDL"
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Auto_Download" to false
				end tell
				--		if show_yt_dlp is "yt-dlp" or show_yt_dlp is "yt-dlp-legacy" then -- v1.26
				if show_yt_dlp is "yt-dlp" then
					try
						tell property list file Service_file_plist
							set value of property list item "default" of property list item "NSMenuItem" of property list item 1 of property list items of contents to new_value
						end tell
					end try
				end if
			end tell
			-- All this code was designed to cope with incompatibility of auto-DL and Get_Formats_list - but, turns out they are not so incompatible - leave in place just in case I'm wrong
			--			if DL_formats_list is true then
			--			set theChooseListAutoTextLabel to localized string "Sorry, but Automatic dowloads is incompatible with the Formats List. Which would you prefer ?" from table "MacYTDL"
			--			set choosel_ListAuto to button returned of (display dialog theChooseListAutoTextLabel buttons {"List", "Auto", "Neither"} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			--			if choosel_ListAuto is "Neither" then
			--				tell application "System Events"
			--					tell property list file MacYTDL_prefs_file
			--						set value of property list item "Auto_Download" to false
			--						set value of property list item "Get_Formats_List" to false
			--					end tell
			--				end tell
			--			end if
			--			if choosel_ListAuto is "Auto" then
			--				if isServiceInstalled is "Yes" then
			--					tell application "System Events"
			--						tell property list file MacYTDL_prefs_file
			--							set value of property list item "Auto_Download" to settings_auto_download_choice
			--						end tell
			--						-- if show_yt_dlp is "yt-dlp" or show_yt_dlp is "yt-dlp-legacy" then -- This do not work properly on macOS earlier than 10.15
			--						if show_yt_dlp is "yt-dlp" then
			--							set new_value to "Download Video Now"
			--							tell property list file Service_file_plist
			--								set value of property list item "default" of property list item "NSMenuItem" of property list item 1 of property list items of contents to new_value
			--							end tell
			--						end if
			--					end tell
			--				end if
			--				if isServiceInstalled is "No" then
			--					set theNeedServiceLabel to localized string "Sorry, to have automatic downloads, you need to install the MacYTDL Service. Discard settings changes and return to Main, install the Service and turn on auto downloads or save all but Auto-download changes" from table "MacYTDL"
			--					set theButtonsInstallLabel to localized string "Install" from table "MacYTDL"
			--					set autoDLNeedService to button returned of (display dialog (theNeedServiceLabel & " ?") with title diag_Title buttons {theButtonReturnLabel, theButtonsInstallLabel, theButtonsSaveLabel} default button 2 with icon file MacYTDL_custom_icon_file giving up after 600)
			--					if autoDLNeedService is theButtonReturnLabel then
			--						set branch_execution to "Main"
			--						return branch_execution
			--						--main_dialog()
			--					end if
			--					if autoDLNeedService is theButtonsInstallLabel then
			--						my install_MacYTDLservice(path_to_MacYTDL)
			--						tell application "System Events"
			--							tell property list file MacYTDL_prefs_file
			--								set value of property list item "Auto_Download" to settings_auto_download_choice
			--							end tell
			--							-- if show_yt_dlp is "yt-dlp" or show_yt_dlp is "yt-dlp-legacy" then -- This does not work properly on macOS earlier than 10.15
			--							if show_yt_dlp is "yt-dlp" then
			--								set new_value to "Download Video Now"
			--								tell property list file Service_file_plist
			--									set value of property list item "default" of property list item "NSMenuItem" of property list item 1 of property list items of contents to new_value
			--								end tell
			--							end if
			--						end tell
			--					end if
			--					-- if autoDLNeedService is theButtonsSaveLabel -- processing will just continue and auto-download stay unchanged
			--				end if
			--				tell application "System Events"
			--					tell property list file MacYTDL_prefs_file
			--						set value of property list item "Get_Formats_List" to false
			--					end tell
			--				end tell
			--			end if
			--			if choosel_ListAuto is "List" then
			--				tell application "System Events"
			--					tell property list file MacYTDL_prefs_file
			--						set value of property list item "Auto_Download" to false
			--						set value of property list item "Get_Formats_List" to true
			--					end tell
			--				end tell
			--			end if
			--			else
			--			tell application "System Events"
			--				tell property list file MacYTDL_prefs_file
			--					set value of property list item "Auto_Download" to true
			--				end tell
			--			end tell
			--			end if
			--		else if settings_auto_download_choice is false and isServiceInstalled is "Yes" then
			--			tell application "System Events"
			--				tell property list file MacYTDL_prefs_file
			--					set value of property list item "Auto_Download" to false
			--				end tell
			--				if show_yt_dlp is "yt-dlp" or show_yt_dlp is "yt-dlp-legacy" then
			--					set new_value to "Send-URL-To-MacYTDL"
			--					tell property list file Service_file_plist
			--						set value of property list item "default" of property list item "NSMenuItem" of property list item 1 of property list items of contents to new_value
			--					end tell
			--				end if
			--			end tell
		end if
		
		-- Check for valid download limit rate - if limit rate is true then the rate value must be positive real number
		try
			set settings_limit_rate_value_choice to settings_limit_rate_value_choice as real
		on error
			set theLimitRateInvalidLabel to localized string "Sorry, you need a positive real number to limit download speed." from table "MacYTDL"
			display dialog theLimitRateInvalidLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			set_settings()
		end try
		if settings_limit_rate_choice is true and (settings_limit_rate_value_choice is "" or settings_limit_rate_value_choice is less than or equal to 0) then
			set theLimitRateInvalidLabel to localized string "Sorry, you need a positive real number to limit download speed." from table "MacYTDL"
			display dialog theLimitRateInvalidLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			set_settings()
		end if
		-- Now can go ahead and set the download speed settings
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Limit_Rate" to settings_limit_rate_choice
				set value of property list item "Limit_Rate_Value" to settings_limit_rate_value_choice
			end tell
		end tell
		
		if settings_button_number_returned is 2 then -- Go to Settings
			set branch_execution to "Settings"
			return branch_execution
		end if
	end if
	
	set branch_execution to "Main"
	return branch_execution
	--main_dialog()
	
end set_admin_settings


---------------------------------------------------
--
-- 	Parse SBS OnDemand web page - Old version before v1.27
--
---------------------------------------------------
--Handler to parse SBS On Demand "Show" pages so as to get a list of episodes

on Get_SBS_Episodes(URL_user_entered, diag_Title, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, X_position, screen_height, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, theButtonReturnLabel, skip_Main_dialog, path_to_MacYTDL)
	
	-- Can only download from one show page at a time
	set AppleScript's text item delimiters to " "
	set number_of_URLs to number of text items in URL_user_entered
	set AppleScript's text item delimiters to ""
	if number_of_URLs is greater than 1 then
		set theOnDemandURLProblemLabel to localized string "It looks like you are trying to download from two or more separate SBS show pages at the same time. MacYTDL can't do that at present. Try just one show page URL at a time. There is more info in Help." in bundle file path_to_MacYTDL from table "MacYTDL"
		display dialog theOnDemandURLProblemLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 100
		set branch_execution to "Main"
		return branch_execution
	end if
	
	-- MUST remove any trailing slash - otherwise end up with empty Chooser - SBS does a redirection which doesn't work with this code at present
	if text -1 of URL_user_entered is "/" then
		set URL_user_entered to text 1 thru -2 of URL_user_entered
	end if
	
	-- Very old code in download_video() adss single quotes - remove them here rather than muck up all the old code
	if text 1 of URL_user_entered is "'" then
		set URL_user_entered to text 2 thru -2 of URL_user_entered
	end if
	
	-- Something wrong with URL or internet connection
	set SBS_show_page_landed to do shell script "curl " & URL_user_entered
	if SBS_show_page_landed is "" then
		set theOnDemandURLProblemLabel to localized string "There was a problem with the OnDemand URL. Make sure you've copied it correctly." in bundle file path_to_MacYTDL from table "MacYTDL"
		display dialog theOnDemandURLProblemLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 100
		set branch_execution to "Main"
		return branch_execution
	end if
	
	-- Set the various delimiters needed to separate seasons and episodes and get counts
	set SBS_show_name_delimiter to {"property=\"og:title\" content=\"", "\"><meta data-react-helmet=\"true\" property=\"og:description\""}
	set episode_delimiter_text to "\"TVEpisode\",\"url\":\""
	set episode_name_delimiter_text to {"\",\"name\":\"", "\",\"image\""}
	set episode_number_delimiter_text to {"episodeNumber\":", ",\"contentRating"}
	set season_delimiter_text to "\"TVSeason\",\"url\":\""
	set season_name_delimiter_text to {"\",\"name\":\"", "\",\"seasonNumber\""}
	set number_of_seasons_delimiter_text to {",\"numberOfSeasons\":", ",\"inLanguage\""}
	set number_of_episodes_in_season_delimiter_text to {",\"numberOfEpisodes\":", ",\"episode\":["}
	
	-- Get name of the show - convert ampersands, apostrophes and commas to displayable characters
	set AppleScript's text item delimiters to SBS_show_name_delimiter
	set SBS_show_name to text item 2 of SBS_show_page_landed
	set SBS_show_name to replace_chars(SBS_show_name, "&amp;#39;", "'")
	set SBS_show_name to replace_chars(SBS_show_name, "&#x27;", ",")
	set SBS_show_name to replace_chars(SBS_show_name, "&amp;amp;", "&")
	set SBS_show_name to replace_chars(SBS_show_name, "&amp;", "&")
	
	-- Test whether user is currently on a season tab page - if so, then strip off season and parse all episodes - will add "All episodes" checkbox to dialog
	set AppleScript's text item delimiters to "/"
	set user_on_tab_page to "false"
	set user_on_season_name to "All"
	set will_show_all_button to false
	
	-- User landed on a single season URL - Nonetheless, must process the main page and record name of landed season - need to curl both pages as season tab pages do not indicate whether there are other seasons
	if (count of text items in URL_user_entered) is greater than 6 then
		set user_on_tab_page to "true"
		set URL_user_entered_main to text items 1 thru 6 of URL_user_entered as text
		set SBS_show_page to do shell script "curl " & URL_user_entered_main
		set AppleScript's text item delimiters to season_name_delimiter_text
		set user_on_season_name to text item 2 of SBS_show_page_landed -- Get name of season that user landed on - will limit chooser to that season if there are more seasons
		set AppleScript's text item delimiters to number_of_seasons_delimiter_text -- Delimiter to get number of seasons - is 1 if landed on a single season URL
		set number_of_seasons to text item 2 of SBS_show_page as integer
		if number_of_seasons is not 1 then
			set will_show_all_button to true
		end if
	else
		set AppleScript's text item delimiters to number_of_seasons_delimiter_text
		set number_of_seasons to text item 2 of SBS_show_page_landed as integer
		set SBS_show_page to SBS_show_page_landed
	end if
	
	-- Set the base URL - all download URLs start with this followed by the ID
	set SBS_base_URL to "https://www.sbs.com.au/ondemand/watch/"
	
	-- Get number of seasons - used to populate lists and control repeat loop
	set AppleScript's text item delimiters to season_delimiter_text
	-- myNumSeasons contains the total number of seasons
	set myNumSeasons to the ((number of text items in SBS_show_page) - 1)
	
	-- Set and populate all list variables
	-- season_episode_list contains data to be fed into the choose: a list of seasons with each season name followed by a list of episodes
	--	set all_URLs_list to {}
	--	set all_URLs_list_Ref to a reference to all_URLs_list -- Can't get this working !
	set season_episode_list to {}
	set seasonName_list to {}
	set season_Occurences to {}
	set maxNumEpisodes to 0
	set landed_number_episodes to 0
	set totalNumberEpisodes to 0
	repeat (myNumSeasons) times
		set end of season_episode_list to ""
		set end of season_Occurences to ""
		set end of seasonName_list to ""
	end repeat
	
	-- Loop to collect season and episode details
	repeat with i from 1 to (myNumSeasons)
		-- Parse season name and add to list
		set item (i) of season_Occurences to text item (i + 1) of SBS_show_page -- Using the current season_delimiter_text delimiter - First text item is java code etc
		set AppleScript's text item delimiters to season_name_delimiter_text -- Extract season name from occurence instance
		set item (i) of seasonName_list to text item 2 of item (i) of season_Occurences --<= Get name of each season into list
		
		-- Must reset all episode list variables for each season - but not URL_list which will be in same order as all episodes in Chooser <<== THAT MIGHT CHANGE !!!!
		set episodeOccurrences to {}
		set ids_list to {}
		set episodename_list to {}
		set episode_URLs_list to {}
		set episodenumber_list to {}
		set AppleScript's text item delimiters to episode_delimiter_text -- To enable episodes in each season to be cunted and separated
		set myNumEpisodes to the ((number of text items in (item (i) of season_Occurences)) - 1)
		-- The maximum number of episodes controls height of dialog - for showing all seasons
		if myNumEpisodes is greater than maxNumEpisodes then set maxNumEpisodes to myNumEpisodes
		-- Use totalNumberEpisodes to test whether diaglog can display - currently not if more than 100
		set totalNumberEpisodes to totalNumberEpisodes + myNumEpisodes
		-- If user landed on a season URL, get number of episodes in that season to pass to Show_SBS_Chooser()
		if item (i) of seasonName_list is user_on_season_name then
			set landed_number_episodes to myNumEpisodes
		end if
		-- Need to empty episode list variables before re-populating
		repeat (myNumEpisodes) times
			set end of episodeOccurrences to ""
			set end of ids_list to ""
			set end of episodenumber_list to ""
			set end of episodename_list to ""
			set end of episode_URLs_list to ""
		end repeat
		-- Loop to collect episode details - for each seasons
		repeat with k from 1 to (myNumEpisodes)
			set item (k) of episodeOccurrences to text item (k + 1) of item (i) of season_Occurences -- Split out episode details for this season
			
			set AppleScript's text item delimiters to episode_name_delimiter_text -- Delimit episode name from occurence instance
			set item (k) of episodename_list to text item 2 of item (k) of episodeOccurrences --<= Get name of each episode into list		
			set temporary_URL to (text item 1 of item (k) of episodeOccurrences)
			set id_start to last_offset("/", temporary_URL) + 1 --  Can't assume every episode ID is 13 digits long so, search for it
			set item (k) of ids_list to text id_start thru (end of temporary_URL) of temporary_URL --<= Get ID of each episode
			
			-- Populate a list of URLs for the season
			set item (k) of episode_URLs_list to (SBS_base_URL & item (k) of ids_list)
			
			-- Populate list of episode numbers and names for this season
			set AppleScript's text item delimiters to episode_number_delimiter_text -- Extract episode number from occurence instance
			set item (k) of episodenumber_list to text item 2 of item (k) of episodeOccurrences --<= Get number of each episode into list		
			set item (k) of episodename_list to ((item (k) of episodenumber_list) & " " & (item (k) of episodename_list)) --<= Form number and name of each episode into list
			
			set AppleScript's text item delimiters to episode_delimiter_text -- Need to reset delimiter so as to form the next episode occurence
		end repeat
		
		-- Form up single list for showing in Chooser - each item contains a season name and a list of episodes and URLs
		set item (i) of season_episode_list to {item (i) of seasonName_list, episodename_list, episode_URLs_list}
		
		set AppleScript's text item delimiters to season_delimiter_text -- Need to reset delimiter so as to form the next season occurence
		
	end repeat
	
	-- Impose maximum number of episode on dialog - if user is not on a season tab - tell user to try a single season URL
	if totalNumberEpisodes is greater than 100 and user_on_tab_page is "false" then
		set the ButtonRecentSeasonLabel to localized string "Recent season" in bundle file path_to_MacYTDL from table "MacYTDL"
		set theTooManyLabel to localized string "There are more than 100 episodes of that SBS show, which is too many for the MacYTDL dialog. Try clicking on a single season tab to get the URL of an individual season and try again." in bundle file path_to_MacYTDL from table "MacYTDL"
		--		set SBS_Too_Many_DL to button returned of (display dialog theTooManyLabel with title diag_Title buttons {theButtonReturnLabel, ButtonRecentSeasonLabel} default button 2 with icon file MacYTDL_custom_icon_file giving up after 600)
		display dialog theTooManyLabel with title diag_Title buttons {theButtonReturnLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		--		if SBS_Too_Many_DL is theButtonReturnLabel then
		if skip_Main_dialog is true then error number -128
		set branch_execution to "Main"
		return branch_execution
		--		else
		--			set URL_user_entered to (URL_user_entered & "/" & (item 1 of seasonName_list))
		--		end if
	end if
	
	-- Crudely force hiding the Show All button when more than 100 episodes - even if user is on a season tab
	if totalNumberEpisodes is greater than 100 then
		set will_show_all_button to false
		set number_of_seasons to 1
	end if
	
	set AppleScript's text item delimiters to ""
	
	set branch_execution to Show_SBS_Chooser(screen_height, number_of_seasons, myNumSeasons, season_episode_list, user_on_season_name, maxNumEpisodes, X_position, episode_URLs_list, will_show_all_button, path_to_MacYTDL, MacYTDL_custom_icon_file_posix, diag_Title, skip_Main_dialog, landed_number_episodes, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file)
	--log SBS_controls_results as text
	
	--	set branch_execution to "Download"
	return branch_execution
	
	
	--	log "URLs ticked were: " & SBS_show_URLs	
	
end Get_SBS_Episodes

-- Show SBS chooser using variables set in Get_SBS_Episodes() - needs to be separate as it can be called twice in a single process of collecting SBS episode URLs
on Show_SBS_Chooser(screen_height, number_of_seasons, myNumSeasons, season_episode_list, user_on_season_name, maxNumEpisodes, X_position, episode_URLs_list, will_show_all_button, path_to_MacYTDL, MacYTDL_custom_icon_file_posix, diag_Title, skip_Main_dialog, landed_number_episodes, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file)
	-- Set buttons and controls - need to loop through episodes - Add "Show All" if user landed on a season tab and there are more seasons available
	--	global other_seasons_exist
	--	set will_show_all_button to false
	--	set other_seasons_exist to (count of items in season_episode_list)
	
	-- Initialise variables	
	set controlinset to 10
	set column_inset to 10
	set all_checkboxes to {}
	set all_SeasonLabels to {}
	set max_episode_width to 0
	
	-- Control "Show All" button - only show if on season tab and there are more seasons AND less than 100 episodes in total
	if will_show_all_button is true then
		set {theButtons, minWidth} to create buttons {"Cancel", "Show All", "Download"} button keys {".", "a", "d"} default button 3
	else
		set {theButtons, minWidth} to create buttons {"Cancel", "Download"} button keys {".", "d"} default button 2
	end if
	
	-- maxNumEpisodes has to be doubled because the "bottom" parameter is distance from bottom of dialog to bottom of control	
	-- For 8 episodes, theTop is 208 plus allowance to position above the Rule
	-- Dialog height is height of longest season or of the landed season
	if landed_number_episodes is 0 then
		set reset_theTop to (maxNumEpisodes * 2 * 10) + 64
		set theTop to (maxNumEpisodes * 2 * 10) + 64
	else
		set reset_theTop to (landed_number_episodes * 2 * 10) + 64
		set theTop to (landed_number_episodes * 2 * 10) + 64
	end if
	
	-- Set up factors to vary size of dialog according to screen height
	--	if screen_height is less than 900 then set height_conversion_factor to 1.25
	--	if screen_height is less than 1200 and screen_height is greater than 899 then set height_conversion_factor to 1.1
	--	if screen_height is less than 1600 and screen_height is greater than 1079 then set height_conversion_factor to 1
	--	if screen_height is less than 2304 and screen_height is greater than 1439 then set height_conversion_factor to 0.875
	--	if screen_height is greater than 2303 then set height_conversion_factor to 0.625
	--	set screen_height_points to screen_height * height_conversion_factor
	
	-- Show checkboxes for all the episodes on the chosen SBS show page - show boxes down and across the dialog starting at top left
	-- Trim off long episode titles if screen res is small and number of episodes more than 50
	set SBS_season_labels to {}
	set SBS_episodes_checkboxes_list to {}
	set SBS_URLs_list to {}
	--	set season_episode_list to reverse of season_episode_list -- Not used as now using natural order
	--	log season_episode_list
	
	-- Show checkboxes for all the episodes on the chosen SBS show - show boxes down and across the dialog
	-- Trim off long episode titles if screen res is small and number of episodes more than 50
	-- But display just the season if user landed on a season tab page	
	repeat with j from 1 to myNumSeasons
		set season_name_display to (item 1 of item (j) of season_episode_list)
		set {aSeasonLabel, theTop, season_width} to create label season_name_display left inset column_inset bottom (theTop) max width 200
		
		if user_on_season_name is "All" or user_on_season_name is season_name_display then
			set episodes_list to item (2) of item (j) of season_episode_list
			set URLs_list to item (3) of item (j) of season_episode_list
			set myNumSeasonEpisodes to count of items in episodes_list
			--			set episodes_list to reverse of episodes_list -- Now using natural order
			--			set URLs_list to reverse of URLs_list
			
			set max_episode_width to 0
			repeat with k from 1 to myNumSeasonEpisodes
				set episode_name_display to item (k) of episodes_list
				copy item (k) of URLs_list to end of SBS_URLs_list
				-- Reduce gap between seaosn and episode !? Why ? - anyway, it looks ok
				if k = 1 then
					set season_space to 5
				else
					set season_space to 0
				end if
				set {aCheckBoxEpisode, theTop, episode_width} to create checkbox episode_name_display left inset column_inset bottom (theTop - 40 - season_space) max width 270
				if episode_width is greater than max_episode_width then set max_episode_width to (episode_width + 5)
				set end of SBS_episodes_checkboxes_list to aCheckBoxEpisode
			end repeat
			-- Need to force a new column after showing all episodes for a season - and form up list of season labels - set inset for next colum to max width of previous column
			set controlinset to (max_episode_width + 5)
			if season_width is greater than controlinset then set controlinset to (season_width + 5) -- Not likely to be a problem
			set column_inset to column_inset + controlinset
			set the end of all_SeasonLabels to aSeasonLabel
		end if
		set theTop to reset_theTop
	end repeat
	
	if column_inset is less than 200 then set column_inset to 300
	--set column_inset to 300 -- Done for testing
	
	set theOnDemandInstructions1Label to localized string "Select which episodes of" in bundle file path_to_MacYTDL from table "MacYTDL"
	set theOnDemandInstructions2Label to localized string "that you wish to download then click on Download or press Return. You can select any combination." in bundle file path_to_MacYTDL from table "MacYTDL"
	set instructions_text to theOnDemandInstructions1Label & " \"" & SBS_show_name & "\", " & theOnDemandInstructions2Label
	
	-- Need to place instructions some amount above season headings - depends on how much depth the label takes - use max depth to find depth
	set instructions_Depth to max depth for label instructions_text max width (column_inset - 5)
	
	set {boxes_instruct, theInstructionsTop} to create label instructions_text left inset 10 bottom (theTop + 40) max width (column_inset - 5) aligns left aligned with multiline
	
	set diag_prompt to localized string "MacYTDL – Choose SBS Shows" in bundle file path_to_MacYTDL from table "MacYTDL"
	set {heading_label, theHeadingTop} to create label diag_prompt left inset 0 bottom (theInstructionsTop + 15) max width (column_inset + 10) aligns center aligned with bold type
	
	set {theEpisodesRule, theRuleTop} to create rule 10 rule width (column_inset + 10)
	
	set SBS_allControls to {heading_label, boxes_instruct, theEpisodesRule} & all_SeasonLabels & SBS_episodes_checkboxes_list
	
	-- Dialog neeeds to be wider than just the buttons
	if minWidth > column_inset then set column_inset to minWidth
	
	set {SBS_button_returned, SBSButtonNumberReturned, SBS_controls_results} to display enhanced window diag_Title buttons theButtons acc view width (column_inset + 10) acc view height (theHeadingTop) acc view controls SBS_allControls
	
	if number_of_seasons is 1 then
		set results_items_increment to 5
	else
		set results_items_increment to (myNumSeasons + 4)
	end if
	if will_show_all_button is true then set results_items_increment to 5 -- These are always single season cases
	
	if (SBSButtonNumberReturned is 2 and will_show_all_button is false) or (SBSButtonNumberReturned is 3 and will_show_all_button is true) then
		
		-- ********************************************************************************************************************************************************
		--		set SBS_controls_results to reverse of SBS_controls_results -- Not any more - now using natural order
		-- ********************************************************************************************************************************************************
		
		set SBS_choice_1 to item 1 of SBS_controls_results -- <= The Heading label
		set SBS_choice_2 to item 2 of SBS_controls_results -- <= The Instructions label
		set SBS_choice_3 to item 3 of SBS_controls_results -- <= Missing value [the rule]
		-- After theRule, the season labels are returned - Best to skip the season labels - but # of seasons varies
		set SBS_show_choices to (items results_items_increment thru end of SBS_controls_results)
		--set SBS_show_choices to reverse of SBS_show_choices -- <= Reverse choices to get URLs back into correct order - not used as now using natural order
		set SBS_show_URLs to ""
		
		-- set SBS_URLs_list to reverse of SBS_URLs_list  -- <= Reverse choices to get URLs back into correct order - not used as now using natural order
		
		repeat with z from 1 to count of SBS_show_choices
			if item z of SBS_show_choices is true then
				if z is 1 then
					set SBS_show_URLs to item 1 of SBS_URLs_list
				else
					set SBS_show_URLs to SBS_show_URLs & " " & item z of SBS_URLs_list
				end if
			end if
		end repeat
		
		if SBS_show_URLs is "" then
			set theCancelSBSLabel to localized string "You didn't select any SBS shows. Do you wish to download an SBS show or just return ?" in bundle file path_to_MacYTDL from table "MacYTDL"
			set SBS_cancel_DL to button returned of (display dialog theCancelSBSLabel with title diag_Title buttons {theButtonReturnLabel, theButtonDownloadLabel} default button 2 with icon file MacYTDL_custom_icon_file giving up after 600)
			if SBS_cancel_DL is theButtonReturnLabel then
				if skip_Main_dialog is true then error number -128
				set branch_execution to "Main"
				return branch_execution
			else
				set branch_execution to Show_SBS_Chooser(screen_height, number_of_seasons, myNumSeasons, season_episode_list, user_on_season_name, maxNumEpisodes, X_position, episode_URLs_list, will_show_all_button, path_to_MacYTDL, MacYTDL_custom_icon_file_posix, diag_Title, skip_Main_dialog, landed_number_episodes, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file)
				-- The recursion loops out here if user cancels 2nd instance of the SBS Chooser - cancel means user wants to return to Main Dialog
				if skip_Main_dialog is true and SBS_show_URLs is "" then error number -128
			end if
		else
			set branch_execution to SBS_show_URLs
		end if
		
		return branch_execution -- whatever is needed next
	end if
	
	-- If user wants all seasons, need to redisplay the Chooser - could pre-tick checkboxes but that might annoy as much as help
	if SBSButtonNumberReturned is 2 and will_show_all_button is true then
		
		--		log "User ticked more seasons box"
		-- set season_episode_list to reverse of season_episode_list -- Not ideal - crude but simplifies handling when showing all seasons - not used as now using natural order
		set user_on_season_name to "All"
		set will_show_all_button to false
		set landed_number_episodes to 0 -- So that dialog high enough for longest season
		set branch_execution to Show_SBS_Chooser(screen_height, number_of_seasons, myNumSeasons, season_episode_list, user_on_season_name, maxNumEpisodes, X_position, episode_URLs_list, will_show_all_button, path_to_MacYTDL, MacYTDL_custom_icon_file_posix, diag_Title, skip_Main_dialog, landed_number_episodes, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file)
		return branch_execution
	end if
	
	if SBSButtonNumberReturned is 1 then
		
		-- User clicked on "Cancel button"	
		
		if skip_Main_dialog is true then error number -128
		-- To make sure myNum doesn't cause SBS processing when not needed
		set maxNumEpisodes to 0
		set myNumSeasons to 0
		
		set branch_execution to "Main"
		return branch_execution
		
		-- Temporary escape
		--		error number -128
		
	end if
	
	
end Show_SBS_Chooser


--------------------------------------------------------
--
-- 	Parse ABC iView web page to get episodes
-- 
--------------------------------------------------------

-- Handler to parse ABC iView "Show" pages to get and show a list of episodes - ask user which episodes to download
on Get_ABC_Episodes(URL_user_entered, diag_Title, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, X_position, screen_height, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, theButtonReturnLabel, skip_Main_dialog, path_to_MacYTDL)
	-- Get the entire web page from user's chosen URL
	set ABC_show_page to do shell script "curl " & URL_user_entered
	if ABC_show_page is "" then
		set theiViewURLProblemLabel to localized string "There was a problem with the iView URLs. It looks like you tried to download from two or more separate show pages at the same time. MacYTDL can't do that at present. Try just one show page URL at a time. There is more info in Help." in bundle file path_to_MacYTDL from table "MacYTDL"
		display dialog theiViewURLProblemLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 100
		set branch_execution to "Main"
		return branch_execution
		return myNum
	end if
	-- Get name of the show - using web page to ensure what is shown is same as what user sees
	set start_show_name to (offset of "\\\"title\\\":\\\"" in ABC_show_page) + 12
	set end_show_name to (offset of "\\\",\\\"displayTitle\\\":\\\"" in ABC_show_page) - 1
	set ABC_show_name to text start_show_name thru end_show_name of ABC_show_page
	-- Get name of the show for use in accessing API web page
	set start_show_name_api to (offset of "canonicalUrl\":\"https://iview.abc.net.au/show/" in ABC_show_page) + 45
	set end_show_name_api to (offset of "\",\"contentType\"" in ABC_show_page) - 1
	set show_name_api to text start_show_name_api thru end_show_name_api of ABC_show_page
	-- Get the list of episodes from iView API and count number of episodes
	set iView_API_URL to "https://iview.abc.net.au/api/series/"
	set ABC_episodes_list to do shell script "curl " & iView_API_URL & show_name_api
	
	-- Are there any "Extras" videos ? If so, get text of extras API page and merge with episodes API page
	-- NB Does not find extras which are stored under a different show name - which happened with "Employable Me" and "about"
	set TID to text item delimiters
	set text item delimiters to "Extras"
	set are_there_extras to text items of ABC_show_page
	if (count are_there_extras) is greater than 0 then
		set show_name_api to show_name_api & "-extras"
		set ABC_extras_list to do shell script "curl " & iView_API_URL & show_name_api
		-- Add the word "Extra - " to title of each extra video
		set ABC_extras_list to replace_chars(ABC_extras_list, "\"title\":\"", "\"title\":\"Extra - ")
		set ABC_episodes_list to ABC_episodes_list & ABC_extras_list
	end if
	set text item delimiters to TID
	
	-- Count the number of occurrences (= number of episodes) - note that if none are found there is still 1 item
	set AppleScript's text item delimiters to "\"title\":\""
	set myNum to the (number of text items in ABC_episodes_list) - 1 -- <= Means we know how many loops to do to get all the episode URLs
	-- Initiate the three lists: occurrences, names and URLs
	set occurrences to {}
	set name_list to {}
	set URL_list to {}
	-- This bit seems to be necessary but I don't yet understand why -- mynum can be zero but causes no error
	repeat (myNum) times
		set end of occurrences to ""
		set end of name_list to ""
		set end of URL_list to ""
	end repeat
	
	-- If mynum is 0 (because there are no occurrences of episode title), assume this is a single show page with no separate episodes listed - Means only need to find the URL and then move to downloading - no need for the Choose ABC shows dialog - but, will need to make the file name later
	-- If myNum is 1, it's a single episode show page and can be treated in the same way
	-- BUT, WE DO HAVE THE SHOW NAME FOR THESE SO, THERE'S NO NEED FOR THE PALAVER
	-- Could also put the myNum cases into here too
	set ABC_base_URL to "https://iview.abc.net.au/show/"
	if myNum is 0 or myNum is 1 then
		set AppleScript's text item delimiters to "href\":\"programs\\"
		set show_URL_start to text 2 through end of text item 2 of ABC_episodes_list
		set AppleScript's text item delimiters to "\",\""
		set ABC_show_URLs_part to ABC_base_URL & text 1 through end of text item 1 of show_URL_start -- Get the URL (one)
		set ABC_show_URLs to replace_chars(ABC_show_URLs_part, "\\", "/video")
		set AppleScript's text item delimiters to ""
		if myNum is 0 then
			set YTDL_output_template to " -o '%(title)s.%(ext)s'"
		end if
		set branch_execution to "Download"
		return branch_execution
		return myNum
	else
		-- Populate the lists of names and URLs - Repeat for each occurrence of an episode found in the API call results
		repeat with i from 1 to myNum
			set item (i) of occurrences to text item (i + 1) of ABC_episodes_list --<= Get text of each occurrence - current delimiter is "\"title\":\""
			set AppleScript's text item delimiters to "\",\"href"
			set item (i) of name_list to text 1 through end of text item 1 of item (i) of occurrences --<= Get each episode name from each occurrence
			set AppleScript's text item delimiters to "href\":\"programs\\"
			set show_URL_start to text 2 through end of text item 2 of item (i) of occurrences --<= Get starting point for each URL
			set AppleScript's text item delimiters to "\",\""
			set item (i) of URL_list to ABC_base_URL & replace_chars(text 1 through end of text item 1 of show_URL_start, "\\", "/video") -- Get end of each URL from starting point to end of item
			set AppleScript's text item delimiters to "\"title\":\"" --<= Needed to get next occurrence
		end repeat
	end if
	set AppleScript's text item delimiters to ""
	
	-- Form up the Choose episodes dialog
	if myNum is greater than 0 then
		-- Reverse name_list as DTP code creates each checkbox strictly in the order processed - reversing the order of items in the list of checkboxes has no effect
		-- Note, some ABC show pages have episodes in reverse order anyway
		set reverse_name_list to reverse of name_list
		
		-- Set variables for the ABC episode choice dialog	
		set theiViewInstructions1Label to localized string "Select which episodes of" in bundle file path_to_MacYTDL from table "MacYTDL"
		set theiViewInstructions2Label to localized string "that you wish to download then click on Download or press Return. You can select any combination." in bundle file path_to_MacYTDL from table "MacYTDL"
		set instructions_text to theiViewInstructions1Label & " \"" & ABC_show_name & "\" " & theiViewInstructions2Label
		set theiViewShowsDiagPromptLabel to localized string "MacYTDL – Choose ABC Shows" in bundle file path_to_MacYTDL from table "MacYTDL"
		set diag_prompt to theiViewShowsDiagPromptLabel
		set accViewWidth to 0
		set accViewInset to 0
		
		-- Set buttons and controls - need to loop through episodes
		set {theButtons, minWidth} to create buttons {theButtonCancelLabel, theButtonDownloadLabel} button keys {".", "d"} default button 2
		set {theEpisodesRule, theTop} to create rule 10 rule width 900
		set ABC_Checkboxes to {}
		-- Add space between the rule and the first checkbox
		set theTop to theTop + 15
		set first_box to theTop
		set set_Width to 0
		set number_cols to 1
		
		-- Set up factors to vary size of dialog according to screen height
		set screen_height to screen_height as integer
		if screen_height is less than 900 then set height_conversion_factor to 1.25
		if screen_height is less than 1200 and screen_height is greater than 899 then set height_conversion_factor to 1.1
		if screen_height is less than 1600 and screen_height is greater than 1080 then set height_conversion_factor to 1
		if screen_height is less than 2304 and screen_height is greater than 1440 then set height_conversion_factor to 0.875
		if screen_height is greater than 2303 then set height_conversion_factor to 0.625
		set screen_height_points to screen_height * height_conversion_factor
		
		-- Show checkboxes for all the episodes on the chosen ABC show page - show boxes down and across the dialog
		-- Trim off long episode titles if screen res is small and number of episodes more than 50
		repeat with j from 1 to (myNum)
			if X_position is less than 160 and myNum is greater than 50 then
				if length of (item j of reverse_name_list) is greater than 30 then
					set episode_name_short to text 1 through 30 of (item j of reverse_name_list)
					set {aCheckbox, theTop, theWidth} to create checkbox episode_name_short left inset accViewInset bottom (theTop + 2) max width 270
				else
					set {aCheckbox, theTop, theWidth} to create checkbox (item j of reverse_name_list) left inset accViewInset bottom (theTop + 2) max width 270
				end if
			else
				set {aCheckbox, theTop, theWidth} to create checkbox (item j of reverse_name_list) left inset accViewInset bottom (theTop + 2) max width 270
			end if
			-- Need to get the width of the widest row in this column - adding up those widths gives the accViewWidth
			if set_Width is less than theWidth then
				set set_Width to theWidth
			end if
			-- Build the collection of checkboxes
			set end of ABC_Checkboxes to aCheckbox
			-- Increment window width and reset vertical and horizontal position of further checkboxes
			if theTop is greater than screen_height_points * 0.5 then
				set number_cols to number_cols + 1
				set at_Top to theTop
				set theTop to first_box
				set accViewInset to accViewInset + set_Width
				set accViewWidth to accViewWidth + set_Width
				set set_Width to 0
			end if
		end repeat
		-- One column - Need to reset distance to top of theRule to prevent a second blank column but retain distance to top of final checkbox
		-- And, make sure accesssory is wide enough to display the instructions
		if number_cols = 1 then
			set at_Top to theTop
			set theTop to first_box
			if accViewWidth is less than 260 then set accViewWidth to 300
		end if
		-- Dialog too narrow causes instructions to wrap too much
		if minWidth > accViewWidth then set accViewWidth to minWidth
		-- Need to force showing the last column - tricky
		if theTop > first_box then
			set accViewInset to accViewInset + set_Width
			set accViewWidth to accViewWidth + set_Width
		end if
		-- Create rest of the dialog
		set theCheckBoxAllLabel to localized string "All episodes" in bundle file path_to_MacYTDL from table "MacYTDL"
		set {ABC_all_episodes_theCheckbox, theTop} to create checkbox theCheckBoxAllLabel left inset 0 bottom (at_Top + 15) max width 270
		set icon_top to theTop
		set {boxes_instruct, theInstructionsTop} to create label instructions_text left inset 75 bottom (theTop + 20) max width accViewWidth - 75 aligns left aligned with multiline
		set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom icon_top + 20 view width 64 view height 64 scale image scale proportionally
		if theInstructionsTop is less than theTop then set theInstructionsTop to theTop
		set {boxes_prompt, theTop} to create label diag_prompt left inset 0 bottom (theInstructionsTop + 10) max width accViewWidth aligns center aligned with bold type
		set ABC_allControls to {theEpisodesRule, boxes_instruct, boxes_prompt, MacYTDL_icon, ABC_all_episodes_theCheckbox} & ABC_Checkboxes
		-- Make sure MacYTDL is in front and show dialog
		tell me to activate
		set {ABC_button_returned, ABCButtonNumberReturned, ABC_controls_results} to display enhanced window diag_Title buttons theButtons acc view width accViewWidth acc view height theTop acc view controls ABC_allControls
		
		if ABCButtonNumberReturned is 2 then
			-- Get checkbox results from ABC show dialog - process in reverse order - result will become "URL_user_entered" back in main_dialog()
			set ABC_choice_1 to item 1 of ABC_controls_results -- <= Missing value [the rule]
			set ABC_choice_2 to item 2 of ABC_controls_results -- <= Instructions
			set ABC_choice_3 to item 3 of ABC_controls_results -- <= Prompt
			set ABC_choice_4 to item 4 of ABC_controls_results -- <= Missing value [the icon]
			set ABC_choice_5 to item 5 of ABC_controls_results -- <= All episodes checkbox
			set ABC_show_choices to reverse of (items 6 thru end of ABC_controls_results) -- <= Reverse choices to get back into correct order
			-- Get URLs corresponding to selected shows
			set ABC_show_URLs to ""
			-- If all episodes selected, set ABC_show_URLs to content of URL_list
			if ABC_choice_5 then
				set save_delimiters to AppleScript's text item delimiters
				set AppleScript's text item delimiters to " "
				set ABC_show_URLs to URL_list as text
				set AppleScript's text item delimiters to save_delimiters
			else
				repeat with z from 1 to count of ABC_show_choices
					if item z of ABC_show_choices is true then
						if z is 1 then
							set ABC_show_URLs to item 1 of URL_list
						else
							set ABC_show_URLs to ABC_show_URLs & " " & item z of URL_list
						end if
					end if
				end repeat
			end if
			if ABC_show_URLs is "" then
				set theCancelABCLabel to localized string "You didn't select any ABC shows. Do you wish to download an ABC show or just return ?" in bundle file path_to_MacYTDL from table "MacYTDL"
				set ABC_cancel_DL to button returned of (display dialog theCancelABCLabel with title diag_Title buttons {theButtonReturnLabel, theButtonDownloadLabel} default button 2 with icon file MacYTDL_custom_icon_file giving up after 600)
				if ABC_cancel_DL is theButtonReturnLabel then
					if skip_Main_dialog is true then error number -128
					set branch_execution to "Main"
					return branch_execution
					return myNum
				else
					Get_ABC_Episodes(URL_user_entered, diag_Title, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, X_position, screen_height, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, theButtonReturnLabel, skip_Main_dialog, path_to_MacYTDL)
					-- The recursion loops out here if user cancels 2nd instance of the SBS Chooser - cancel means user wants to return
					if skip_Main_dialog is true and ABC_show_URLs is "" then error number -128
					set branch_execution to "Download"
					return branch_execution
					return myNum
				end if
			end if
			if text 1 of ABC_show_URLs is " " then
				set ABC_show_URLs to text 2 thru end of ABC_show_URLs
			end if
			set branch_execution to "Download"
			return branch_execution
			return myNum
		else
			if skip_Main_dialog is true then error number -128
			set myNum to 0 -- To make sure myNum doesn't cause ABC processing when not needed
			set branch_execution to "Main"
			return branch_execution
			return myNum
		end if
	end if
end Get_ABC_Episodes


---------------------------------------------------
--
-- 			Show settings before download
--
---------------------------------------------------

-- Handler to show current settings before commencing download if user has specified that in Settings
on show_settings(YTDL_subtitles, DL_Remux_original, DL_YTDL_auto_check, DL_STEmbed, DL_audio_only, YTDL_description, DL_Limit_Rate, DL_over_writes, DL_Thumbnail_Write, DL_verbose, DL_Thumbnail_Embed, DL_Add_Metadata, DL_Use_Proxy, DL_Use_Cookies, DL_Use_Custom_Template, DL_Use_Custom_Settings, remux_format_choice, DL_TimeStamps, DL_Use_YTDLP, DL_Parallel, DL_discard_URL, DL_Dont_Use_Parts, DL_No_Warnings, YTDL_version, folder_chosen, theButtonQuitLabel, theButtonCancelLabel, theButtonDownloadLabel, DL_Show_Settings, MacYTDL_prefs_file, MacYTDL_custom_icon_file_posix, diag_Title)
	
	-- Convert boolean settings to text to enable list of current settings to be shown intelligibly in "Show Settings" dialog - v1.27 - added localization for negative and affirmative
	set theAffirmativeLabel to localized string "Yes" from table "MacYTDL"
	set theNegativeLabel to localized string "No" from table "MacYTDL"
	
	if YTDL_subtitles contains "--write-sub" then
		set MDDL_subtitles to theAffirmativeLabel
	else
		set MDDL_subtitles to theNegativeLabel
	end if
	if YTDL_subtitles contains "--write-auto-sub" then
		set MDDL_Auto_subtitles to theAffirmativeLabel
	else
		set MDDL_Auto_subtitles to theNegativeLabel
	end if
	if DL_Remux_original is true then
		set MDDL_Remux_original to theAffirmativeLabel
	else
		set MDDL_Remux_original to theNegativeLabel
	end if
	if DL_YTDL_auto_check is true then
		set MDDL_YTDL_auto_check to theAffirmativeLabel
	else
		set MDDL_YTDL_auto_check to theNegativeLabel
	end if
	if DL_STEmbed is true then
		set MDDL_STEmbed to theAffirmativeLabel
	else
		set MDDL_STEmbed to theNegativeLabel
	end if
	if DL_audio_only is true then
		set MDDL_audio_only to theAffirmativeLabel
	else
		set MDDL_audio_only to theNegativeLabel
	end if
	if YTDL_description is "--write-description " then
		set MDDL_description to theAffirmativeLabel
	else
		set MDDL_description to theNegativeLabel
	end if
	if DL_Limit_Rate is true then
		set MDDL_Limit_Rate to DL_Limit_Rate_Value & " MB/sec"
	else
		set MDDL_Limit_Rate to theNegativeLabel
	end if
	if DL_over_writes is false then
		set MDDL_over_writes to theNegativeLabel
	else
		set MDDL_over_writes to theAffirmativeLabel
	end if
	if DL_Thumbnail_Write is true then
		set MDDL_Thumbnail_Write to tbeAffirmativeLabel
	else
		set MDDL_Thumbnail_Write to theNegativeLabel
	end if
	if DL_verbose is true then
		set MDDL_verbose to theAffirmativeLabel
	else
		set MDDL_verbose to theNegativeLabel
	end if
	if DL_Thumbnail_Embed is true then
		set MDDL_Thumbnail_Embed to theAffirmativeLabel
	else
		set MDDL_Thumbnail_Embed to theNegativeLabel
	end if
	if DL_Add_Metadata is true then
		set MDDL_Add_Metadata to theAffirmativeLabel
	else
		set MDDL_Add_Metadata to theNegativeLabel
	end if
	if DL_Use_Proxy is true then
		set MDDL_Use_Proxy to DL_Proxy_URL
	else
		set MDDL_Use_Proxy to theNegativeLabel
	end if
	if DL_Use_Cookies is true then
		set MDDL_Use_Cookies to DL_Cookies_Location
	else
		set MDDL_Use_Cookies to theNegativeLabel
	end if
	if DL_Use_Custom_Template is true then
		set MDDL_Use_Template to DL_Custom_Template
	else
		set MDDL_Use_Template to theNegativeLabel
	end if
	if DL_TimeStamps is true then
		set MDDL_TimeStamps to theAffirmativeLabel
	else
		set MDDL_TimeStamps to theNegativeLabel
	end if
	if DL_Use_Custom_Settings is true then
		set MDDL_Use_Settings to DL_Custom_Settings
	else
		set MDDL_Use_Settings to theNegativeLabel
	end if
	if DL_formats_list is true then
		set MDDL_DL_formats_list to theAffirmativeLabel
	else
		set MDDL_DL_formats_list to theNegativeLabel
	end if
	if DL_QT_Compat is true then
		set MDDL_DL_QT_Compat to theAffirmativeLabel
	else
		set MDDL_DL_QT_Compat to theNegativeLabel
	end if
	if DL_Parallel is true then
		set MDDL_Parallel to theAffirmativeLabel
	else
		set MDDL_Parallel to theNegativeLabel
	end if
	if DL_Dont_Use_Parts is true then
		set MDDL_No_Parts to theAffirmativeLabel
	else
		set MDDL_No_Parts to theNegativeLabel
	end if
	if DL_discard_URL is true then
		set MDDL_Discard_Partial to theAffirmativeLabel
	else
		set MDDL_Discard_Partial to theNegativeLabel
	end if
	if DL_No_Warnings is true then
		set MDDL_No_Warnings to theAffirmativeLabel
	else
		set MDDL_No_Warnings to theNegativeLabel
	end if
	
	-- Set contents of optional subtitles embedded status and format - only shows if subtitles are requested
	-- Ditto with whether to keep original after remuxing, embedded thumbnails, proxy, cookies and template
	set subtitles_embedded_pref to ""
	if MDDL_subtitles is theAffirmativeLabel then
		set theShowSettingsPromptTextSTEmbedLabel to localized string "Embedded:" from table "MacYTDL"
		set subtitles_embedded_pref to return & theShowSettingsPromptTextSTEmbedLabel & tab & tab & tab & MDDL_STEmbed
	end if
	set subtitles_format_pref to ""
	if DL_subtitles is true and DL_STEmbed is false then
		set theShowSettingsPromptTextSTFormatLabel to localized string "Format:" from table "MacYTDL"
		--		set subtitles_format_pref to tab & tab & theShowSettingsPromptTextSTFormatLabel & tab & tab & DL_subtitles_format
		set subtitles_format_pref to tab & tab & theShowSettingsPromptTextSTFormatLabel & tab & DL_subtitles_format
	end if
	set keep_original_pref to ""
	if DL_Remux_format is not "No remux" or YTDL_subtitles contains "convert" then
		set theShowSettingsPromptTextKeepOrigtLabel to localized string "Keep original file(s):" from table "MacYTDL"
		set keep_original_pref to return & theShowSettingsPromptTextKeepOrigtLabel & tab & MDDL_Remux_original
	end if
	set theShowSettingsPromptTextEmbedThumbLabel to localized string "Embed thumbnails:" from table "MacYTDL"
	set thumbnails_embed_pref to theShowSettingsPromptTextEmbedThumbLabel & tab & MDDL_Thumbnail_Embed
	
	-- Set variables for the Show Settings dialog
	set theShowSettingsPromptTextFolderLabel to localized string "Download folder:" from table "MacYTDL"
	--	if DL_Use_YTDLP is "yt-dlp" then
	--		set theShowSettingsPromptTextYTDLLabel to localized string "yt-dlp version:" from table "MacYTDL"
	--	else
	--		set theShowSettingsPromptTextYTDLLabel to localized string "youtube-dlp version:" from table "MacYTDL"
	--	end if
	set theShowSettingsPromptTextYTDLLabel to DL_Use_YTDLP & " " & (localized string "version:" from table "MacYTDL")
	set theShowSettingsPromptTextFFmpegLabel to localized string "FFmpeg version:" from table "MacYTDL"
	set theShowSettingsPromptTextFormatLabel to localized string "Download file format:" from table "MacYTDL"
	set theShowSettingsPromptTextAudioLabel to localized string "Audio only:" from table "MacYTDL"
	set theShowSettingsPromptTextDescriptionLabel to localized string "Description:" from table "MacYTDL"
	set theShowSettingsPromptTextSTLabel to localized string "Download subtitles:" from table "MacYTDL"
	set theShowSettingsPromptTextAutoSTLabel to localized string "Auto subtitles:" from table "MacYTDL"
	set theShowSettingsPromptTextRemuxLabel to localized string "Remux download:" from table "MacYTDL"
	set theShowSettingsPromptTextThumbsLabel to localized string "Write thumbnails:" from table "MacYTDL"
	set theShowSettingsPromptTextVerboseLabel to localized string "Verbose logging:" from table "MacYTDL"
	set theShowSettingsPromptTextTimeStampsLabel to localized string "Add timestamps:" from table "MacYTDL"
	set theShowSettingsPromptTextMetaDataLabel to localized string "Add metadata:" from table "MacYTDL"
	set theShowSettingsPromptTextOverWriteLabel to localized string "Force overwrites:" from table "MacYTDL"
	set theShowSettingsPromptTextLimitSpeedLabel to localized string "Limit download speed:" from table "MacYTDL"
	set theShowSettingsPromptTextUseProxyLabel to localized string "Use proxy:" from table "MacYTDL"
	set theShowSettingsPromptTextUseCookiesLabel to localized string "Use cookies:" from table "MacYTDL"
	set theShowSettingsPromptTextUseTemplateLabel to localized string "Custom template:" from table "MacYTDL"
	set theShowSettingsPromptTextUseSettingsLabel to localized string "Custom settings:" from table "MacYTDL"
	set theShowSettingsPromptTextDLQTLabel to localized string "QT compatible:" from table "MacYTDL"
	set theShowSettingsPromptTextGetFormatsLabel to localized string "Get formats list:" from table "MacYTDL"
	set theShowSettingsPromptTextParallelLabel to localized string "Parallel download:" from table "MacYTDL"
	set theShowSettingsPromptTextNoPartsLabel to localized string "No part files:" from table "MacYTDL"
	set theShowSettingsPromptTextNoPartialLabel to localized string "Delete partial files:" from table "MacYTDL"
	set theShowSettingsPromptTextNoWarningsLabel to localized string "Hide warnings:" from table "MacYTDL"
	set diag_prompt_text_1 to theShowSettingsPromptTextFolderLabel & tab & tab & folder_chosen & return & theShowSettingsPromptTextYTDLLabel & tab & tab & YTDL_version & return & theShowSettingsPromptTextFFmpegLabel & tab & tab & ffmpeg_version & return & theShowSettingsPromptTextFormatLabel & tab & DL_format & return & theShowSettingsPromptTextAudioLabel & tab & tab & tab & MDDL_audio_only & return & theShowSettingsPromptTextDescriptionLabel & tab & tab & tab & MDDL_description & return & theShowSettingsPromptTextSTLabel & tab & MDDL_subtitles & subtitles_format_pref & subtitles_embedded_pref & return & theShowSettingsPromptTextAutoSTLabel & tab & tab & MDDL_Auto_subtitles & return & theShowSettingsPromptTextRemuxLabel & tab & tab & remux_format_choice & keep_original_pref & return & theShowSettingsPromptTextThumbsLabel & tab & tab & MDDL_Thumbnail_Write & return & thumbnails_embed_pref & return & theShowSettingsPromptTextVerboseLabel & tab & tab & MDDL_verbose & return & theShowSettingsPromptTextTimeStampsLabel & tab & tab & MDDL_TimeStamps & return & theShowSettingsPromptTextMetaDataLabel & tab & tab & MDDL_Add_Metadata & return & theShowSettingsPromptTextOverWriteLabel & tab & tab & MDDL_over_writes & return & theShowSettingsPromptTextLimitSpeedLabel & tab & MDDL_Limit_Rate & return & theShowSettingsPromptTextDLQTLabel & tab & tab & MDDL_DL_QT_Compat & return & theShowSettingsPromptTextUseProxyLabel & tab & tab & tab & MDDL_Use_Proxy & return & theShowSettingsPromptTextUseCookiesLabel & tab & tab & tab & MDDL_Use_Cookies & return & theShowSettingsPromptTextGetFormatsLabel & tab & tab & MDDL_DL_formats_list & return & theShowSettingsPromptTextUseTemplateLabel & tab & tab & MDDL_Use_Template & return & theShowSettingsPromptTextUseSettingsLabel & tab & tab & MDDL_Use_Settings & return & theShowSettingsPromptTextParallelLabel & tab & tab & MDDL_Parallel & return & theShowSettingsPromptTextNoPartsLabel & tab & tab & tab & MDDL_No_Parts & return & theShowSettingsPromptTextNoPartialLabel & tab & MDDL_Discard_Partial & return & theShowSettingsPromptTextNoWarningsLabel & tab & tab & MDDL_No_Warnings
	set show_settings_diag_promptLabel to localized string "Settings for this download" from table "MacYTDL"
	set show_settings_diag_prompt to show_settings_diag_promptLabel
	set accViewWidth to 375
	set accViewInset to 70
	
	-- Set buttons and controls
	set theButtonsShowSettingsEditLabel to localized string "Edit settings" from table "MacYTDL"
	set {theButtons, minWidth} to create buttons {theButtonQuitLabel, theButtonsShowSettingsEditLabel, theButtonCancelLabel, theButtonDownloadLabel} button keys {"q", "e", ".", "d"} default button 4
	if minWidth > accViewWidth then set accViewWidth to minWidth
	set {theShowSettingsRule, theTop} to create rule 10 rule width accViewWidth
	set show_settings_theCheckboxLabel to localized string "Show settings before download" from table "MacYTDL"
	set {show_settings_theCheckbox, theTop} to create checkbox show_settings_theCheckboxLabel left inset 20 bottom (theTop + 15) max width accViewWidth initial state DL_Show_Settings
	set {diag_prompt_1, theTop} to create label diag_prompt_text_1 left inset accViewInset bottom theTop + 15 max width accViewWidth - 75 control size regular size
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 60 view width 64 view height 64 scale image scale proportionally
	set {show_settings_prompt, theTop} to create label show_settings_diag_prompt left inset 0 bottom theTop + 5 max width minWidth aligns center aligned with bold type
	
	set show_settings_allControls to {theShowSettingsRule, show_settings_theCheckbox, diag_prompt_1, MacYTDL_icon, show_settings_prompt}
	
	-- Make sure MacYTDL is in front and show dialog
	tell me to activate
	set {show_settings_button_returned, showSettingsButtonNumberReturned, show_settings_controls_results} to display enhanced window diag_Title buttons theButtons acc view width accViewWidth acc view height theTop acc view controls show_settings_allControls
	
	-- Update show settings setting if user has changed it		
	set show_settings_choice to item 2 of show_settings_controls_results -- <= User has changed the setting
	if show_settings_choice is not equal to DL_Show_Settings then
		set DL_Show_Settings to show_settings_choice
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Show_Settings_before_Download" to show_settings_choice
			end tell
		end tell
	end if
	set branch_execution to "Download"
	if showSettingsButtonNumberReturned is 3 then
		set branch_execution to "Main"
	else if showSettingsButtonNumberReturned is 2 then
		set branch_execution to "Settings"
	else if showSettingsButtonNumberReturned is 1 then
		set branch_execution to "Quit"
	end if
	return branch_execution
end show_settings


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
on last_offset(the_object_string, the_search_string)
	try
		set astid to AppleScript's text item delimiters
		set AppleScript's text item delimiters to the_object_string
		set last_occurrence_offset to (count the_search_string) - (count text item -1 of the_search_string)
		set AppleScript's text item delimiters to astid
		return last_occurrence_offset
	on error
		return 0
	end try
end last_offset
