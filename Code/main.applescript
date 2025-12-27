-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  MacYTDL
--  A GUI for the Python scripts youtube-dl and yt-dlp.  Many thanks to Shane Stanley, Adam Albrec, kopurando and Michael Page
--  Trying to bring in useful functions in a pithy GUI with few AppleScript extensions and without AppleScriptObjC
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Include libraries - needed for Shane Staney's Dialog Toolkit and MacYTDL libraries
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use script "DialogToolkitMacYTDL"
-- use script "Myriad Tables Lib" version "1.0.13" -- Not needed as Myriad is only used by Formats.scptd
-- Use script requires libraries to be stored in /Contents/Resources/Script Libraries/, to be "scptd" files and for symlinks to be in place
-- symlinks are added to all script libaries by Shane Stanley's Make-symlinks script copied from "Embedding script libraries that call other libraries" on LNSW forum
use script "Utilities2"
use run_Utilities_handlers : script "Utilities"
use run_Batch_Handlers : script "batch"
use run_Formats_Chooser_Handler : script "Formats"
property parent : AppleScript


-- Set variables and default values
-- Variables which need to be controlled across more than one handler
global diag_prompt
global diag_Title
global YTDL_version
global usr_bin_folder
global ffmpeg_version_long
global ffprobe_version
global ffmpeg_version
global deno_version
global alert_text_ytdl
global alert_text_ffmpeg
global path_to_MacYTDL
global shellPath
global downloadsFolder_Path
global Atomic_is_installed
global macYTDL_Atomic_file
global deno_file
global download_filename
global download_filename_new
global YTDL_log_file
global YTDL_simulate_file
global youtubedl_file
global ytdlp_file
global YTDL_exists
global deno_exists
global ytdlp_exists
global ffmpeg_exists
global ffprobe_exists
global homebrew_ytdlp_exists
global homebrew_ffmpeg_exists
global homebrew_ffprobe_exists
global show_yt_dlp
global user_system_arch
global user_on_123
global user_on_old_os
global user_on_mid_os
global URL_user_entered
global ABC_show_URLs
global SBS_show_URLs
global ABC_show_name
global SBS_show_name
global playlist_Name
global number_ABC_SBS_episodes
global YTDL_output_template
global YTDL_format_pref
global old_version_prefs
global batch_file
global MacYTDL_prefs_file
global MacYTDL_custom_icon_file
global MacYTDL_custom_icon_file_posix
global macYTDL_service_file
global MacYTDL_preferences_path
global resourcesPath
global YTDL_credentials
global DL_audio_only
global DL_audio_codec
global DL_YTDL_auto_check
global DL_over_writes
global DL_subtitles
global DL_subtitles_format
global DL_YTAutoST
global DL_Thumbnail_Write
global DL_Thumbnail_Embed
global DL_verbose
global DL_description
global DL_format
global DL_STLanguage
global DL_STEmbed
global DL_Remux_Recode
global DL_Remux_format
global DL_Remux_original
global theNoRemuxLabel
global DL_Add_Metadata
global DL_batch_status
global DL_Limit_Rate
global DL_Limit_Rate_Value
global DL_Show_Settings
global DL_Use_Cookies
global DL_Cookies_Location
global DL_Use_Proxy
global DL_Proxy_URL
global DL_Use_netrc
global DL_Use_Custom_Template
global DL_Custom_Template
global DL_Use_YTDLP
global DL_TimeStamps
global DL_Use_Custom_Settings
global DL_Custom_Settings
global DL_auto
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
global MacYTDL_version
global MacYTDL_copyright
global MacYTDL_date
global ffprobe_file
global ffmpeg_file
-- global DTP_file  -- No longer need to install - v1.30, 5/11/25
-- global Myriad_file  -- No longer need to install - v1.30, 5/11/25
-- global Myriad_exists  -- No longer need to install - v1.30, 5/11/25
global called_video_URL
global monitor_dialog_position
global screen_width
global screen_height
global theButtonContinueLabel
global theButtonDownloadLabel
global theButtonOKLabel
global theButtonQuitLabel
global theButtonReturnLabel
global theButtonCancelLabel
global theButtonNoLabel
global theButtonYesLabel
global theBestLabel
global theDefaultLabel
global window_Position
global X_position
global Y_position
--global run_Utilities_handlers
--global run_Batch_Handlers


-------------------------------------------------
--
-- 			Set up variables
--
-------------------------------------------------

-- Set up a variable which will store URL entered while user goes into other functions: Settings, Help, Utilities, errors. It is reset if user downloads a video.
global URL_user_entered_clean
set URL_user_entered_clean to ""

-- Accept URL to be downloaded from the MacYTDL Service, assign to a new variable which is available to this script
on called_by_service(video_URL)
	tell me to activate
	set called_video_URL to video_URL
	run
end called_by_service

-- Variables for this applet's version, date and author
-- v1.30, 20/11/25 - Need to prevent MacYTDL being run from inside a DMG
set path_to_MacYTDL to path to me as text
set path_to_MacYTDL_posix to POSIX path of path_to_MacYTDL
if path_to_MacYTDL_posix contains "/Volumes/MacYTDL" then
	display dialog "Sorry, MacYTDL cannot be run from within a DMG file. Copy MacYTDL to \"Applications\" and try again" buttons "OK" with icon stop
	error number -128
end if
set bundle_file to (path_to_MacYTDL & "contents:Info.plist") as string
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

-- Set variable to contain path to Alerter and ets
set resourcesPath to POSIX path of (path_to_MacYTDL & "Contents:Resources:")
-- Set text for alerts that might be invoked before Main dialog
set alert_text_ytdl to "NotSwitching"

-- Set variables to contain user's macOS version - for Utilities, Settings, FFmpeg install and yt-dlp install
-- Users on macOS 10.10 to 10.14.6 need yt-dlp legacy install - cannot install past version 2025.08.11 - also changes content of  Utilities dialog
-- If user on <10.12.1 will have expired certificates preventing FFmpeg download  <<== NOT SURE THIS IS CORRECT - DECIDED TO OMIT
-- Users on 12.3+ cannot use youtube-dl (because macOS no longer includes Python runtime)
-- Users on 10.13, 10.14, 10.15 and 11 cannot use FFmpeg from Riedl as they are compiled for macOS 12+
-- Users on 10.10, 10.11 and 10.12 cannot use FFmpeg after v6.0 (because they lack Metal API & Core Image is located inside Quartz.framework)
set user_sysinfo to system info
set user_os_version to system version of user_sysinfo as string
considering numeric strings
	if user_os_version is greater than "10.9.5" and user_os_version is less than "10.15" then
		set show_yt_dlp to "yt-dlp-legacy"
	else
		set show_yt_dlp to "yt-dlp"
	end if
	if user_os_version is greater than "12.2.1" then
		set user_on_123 to true
	else
		set user_on_123 to false
	end if
	if user_os_version is less than "10.13" then
		set user_on_old_os to true
	else
		set user_on_old_os to false
	end if
	if user_os_version is greater than "10.12.6" and user_os_version is less than "12.0" then
		set user_on_mid_os to true
	else
		set user_on_mid_os to false
	end if
end considering

-- Get system architecture – controls whether to download Intel or ARM version of FFmpeg/FFprobe
set user_system_arch to (do shell script "arch")
if user_system_arch is not "arm64" then set user_system_arch to "Intel"

-- Add shellpath variable because otherwise script can't find youtube-dl/yt-dlp
set shellPath to "PATH=$PATH:/bin:/sbin:/usr/bin:/usr/local/bin:/usr/sbin:~/opt/bin:~/opt/sbin:/opt/local/bin:/opt/local/sbin:/opt/homebrew/bin:" & quoted form of (POSIX path of (path_to_MacYTDL & "::")) & "; "

-- Set path and name for custom icon for dialogs
set MacYTDL_custom_icon_file to (path to resource "macytdl.icns") as string
-- Set path and name for custom icon for enhanced window statements
set MacYTDL_custom_icon_file_posix to POSIX path of MacYTDL_custom_icon_file

-- Set variable for title of dialogs
set theVersionLabel to localized string "Version" from table "MacYTDL"
set diag_Title to "MacYTDL, " & theVersionLabel & " " & MacYTDL_version & ", " & MacYTDL_date

-- Variables for component installation status - doubling up with version if already installed - changed when components are installed
set YTDL_version to "Not installed"
set ffprobe_version to "Not installed"
set ffmpeg_version to "Not installed"
set Atomic_is_installed to false
set old_version_prefs to "No"

-- Variables for storing MacYTDL preferences, batch file, youtube-dl/yt-dlp, FFmpeg, FFprobe and DialogToolkitPlus locations
set usr_bin_folder to ("/usr/local/bin/" as text)
set ytdlp_file to ("/usr/local/bin/yt-dlp" as text)
set homebrew_ARM_ytdlp_file to ("/opt/homebrew/bin/yt-dlp" as text)
set homebrew_Intel_ytdlp_file to ("usr:local:bin:yt-dlp" as text) -- Why is path not HFS ?
set macPorts_ytdlp_file to ("/opt/local/bin/yt-dlp" as text)
set youtubedl_file to ("/usr/local/bin/youtube-dl" as text)
set home_folder to (path to home folder) as text
-- set libraries_folder to home_folder & "Library:Script Libraries"          --  No longer need to install - v1.30, 5/11/25
-- set DTP_file to libraries_folder & ":DialogToolkitMacYTDL.scptd"           --  No longer need to install - v1.30, 5/11/25
-- set Myriad_file to libraries_folder & ":Myriad Tables Lib.scptd"         -- No longer need to install - v1.30, 5/11/25
set MacYTDL_preferences_folder to "Library/Preferences/MacYTDL/"
set MacYTDL_preferences_path to (POSIX path of (path to home folder) & MacYTDL_preferences_folder)
set MacYTDL_prefs_file to MacYTDL_preferences_path & "MacYTDL.plist"
set ffmpeg_file to ("/usr/local/bin/ffmpeg" as text)
set ffprobe_file to ("/usr/local/bin/ffprobe" as text)
set homebrew_ARM_ffmpeg_file to ("/opt/homebrew/bin/ffmpeg" as text)
set homebrew_Intel_ffmpeg_file to ("usr:local:bin:ffmpeg" as text)
set homebrew_ARM_ffprobe_file to ("/opt/homebrew/bin/ffprobe" as text)
set homebrew_Intel_ffprobe_file to ("usr:local:bin:ffprobe" as text)
set macPorts_ffmpeg_file to ("/opt/local/bin/ffmpeg" as text)
set macPorts_ffprobe_file to ("/opt/local/bin/ffprobe" as text)
set deno_file to ("usr:local:bin:deno" as text)

set batch_filename to "BatchFile.txt" as string
set batch_file to POSIX file (MacYTDL_preferences_path & batch_filename)

-- Load utilities.scpt so that various handlers can be called
--set path_to_Utilities to (path_to_MacYTDL & "Contents:Resources:Scripts:Utilities.scpt") as alias
--set run_Utilities_handlers to load script path_to_Utilities

-- Get size of main screen so dialogs can be positioned
-- Passed to main_dialog via set_preferences when MacYTDL opened for 1st time or if MacYTDL prefs file has been deleted
-- Screen height is used for positioning ABC and SBS choosers and Monitor dialogs
set screen_size to run_Utilities_handlers's get_screensize()
set X_position to item 1 of screen_size as integer
set Y_position to item 2 of screen_size as integer
set screen_width to item 3 of screen_size as integer
set screen_height to item 4 of screen_size as integer
-- display dialog (screen_width & return & screen_height) as string

-- Variables for the most common dialog buttons and drop-down boxes - saves a little extra code in all the get_dialogs
set theButtonOKLabel to localized string "OK" from table "MacYTDL"
set theButtonQuitLabel to localized string "Quit" from table "MacYTDL"
set theButtonDownloadLabel to localized string "Download" from table "MacYTDL"
set theButtonReturnLabel to localized string "Return" from table "MacYTDL"
set theButtonContinueLabel to localized string "Continue" from table "MacYTDL"
set theButtonCancelLabel to localized string "Cancel" from table "MacYTDL"
set theButtonNoLabel to localized string "No" from table "MacYTDL"
set theButtonYesLabel to localized string "Yes" from table "MacYTDL"
set theBestLabel to localized string "Best" from table "MacYTDL"
set theDefaultLabel to localized string "Default" from table "MacYTDL"
set theNoRemuxLabel to localized string "N/R" from table "MacYTDL" -- <= v1.30, 25/11/25 - Changed from "No remux" - Decided not to rename


-------------------------------------------------
--
-- 	Make sure components are in place
--
------------------------------------------------- 
-- Check which components are installed - check for Homebrew and MacPorts - if yt-dlp is small it is a faulty install
tell application "System Events"
	if exists file youtubedl_file then
		set YTDL_exists to true
	else
		set YTDL_exists to false
	end if
	
	-- Note: ytdlp_file is always named "yt-dlp" in the usr/local/bin folder - only use Homebrew yt-dlp install if there is no MacYTDL install - check for Homebrew install on both Intel and ARM Macs
	if exists file ytdlp_file then
		set ytdlp_path_alias to POSIX file ytdlp_file as alias
		
		set its_type to file type of disk item homebrew_Intel_ytdlp_file
		
		-- Is this a Homebrew install on Intel or MacPorts install ? Homebrew normally adds a symlink to /usr/local/bin/ on Intel Macs - MacPorts adds a symlink to /opt/local/bin/
		if its_type is "slnk" then
			set homebrew_ytdlp_exists to true
			set ytdlp_exists to false
		end if
		
		-- Is it a complete normal install ?
		if size of ytdlp_path_alias is greater than 9000 then
			set homebrew_ytdlp_exists to false
			set ytdlp_exists to true
		end if
		
		-- Is it a faulty normal install ? Rare case in which MacYTDL install of yt-dlp is faulty and left a stub - Intel Homebrew installs are smaller than 9000 and so are excluded from this test
		if size of ytdlp_path_alias is less than 9000 and its_type is not "slnk" then
			set homebrew_ytdlp_exists to false
			set ytdlp_exists to false
		end if
		-- Nothing in /usr/local/bin - look for Homebrew on ARM Macs
	else if exists file homebrew_ARM_ytdlp_file then
		set ytdlp_exists to false
		set homebrew_ytdlp_exists to true
		set ytdlp_file to ("/opt/homebrew/bin/yt-dlp" as text)
		-- Nothing in /opt/homebrew/bin - look for MacPorts - same location for Intel and ARM Macs - use homebrew_ytdlp_exists as proxy for both HomeBrew and MacPorts - simplifies coding everywhere
		-- Assume that any file in /opt/local/bin/ is a MacPorts install
	else if exists file macPorts_ytdlp_file then
		set ytdlp_exists to false
		set homebrew_ytdlp_exists to true
		set ytdlp_file to ("/opt/local/bin/yt-dlp" as text)
	else
		set ytdlp_exists to false
		set homebrew_ytdlp_exists to false
	end if
	
	-- v1.30, 5/11/25 - Commented out as DTP is no longer installed
	--	if exists file DTP_file then
	--	set DTP_exists to true
	--	else
	--		set DTP_exists to false
	--	end if
	
	-- v1.30, 5/11/25 - Commented out as Myriad is no longer installed
	--	if exists file Myriad_file then
	--		set Myriad_exists to true
	--	else
	--		set Myriad_exists to false
	--	end if
	
	if exists file deno_file then
		set deno_exists to true
	else
		set deno_exists to false
	end if
	
	if exists file ffmpeg_file then
		-- Is this a Homebrew install on Intel ?
		set its_type_ffmpeg to file type of disk item homebrew_Intel_ffmpeg_file
		if its_type_ffmpeg is "slnk" then
			set homebrew_ffmpeg_exists to true
			set ffmpeg_exists to false
		else
			set homebrew_ffmpeg_exists to false
			set ffmpeg_exists to true
		end if
		-- Nothing in /usr/local/bin - look for Homebrew on ARM Macs
	else if exists file homebrew_ARM_ffmpeg_file then
		set ffmpeg_exists to false
		set homebrew_ffmpeg_exists to true
		set ffmpeg_file to ("/opt/homebrew/bin/ffmpeg" as text)
		-- Nothing in /opt/homebrew/bin - look for MacPorts install - homebrew_ffmpeg_exists used as proxy for MacPorts install
	else if exists file macPorts_ffmpeg_file then
		set ffmpeg_exists to false
		set homebrew_ffmpeg_exists to true
		set ffmpeg_file to ("/opt/local/bin/ffmpeg" as text)
	else
		set ffmpeg_exists to false
		set homebrew_ffmpeg_exists to false
	end if
	
	if exists file ffprobe_file then
		-- Is this a Homebrew install on Intel ?
		set its_type_ffmprobe to file type of disk item homebrew_Intel_ffprobe_file
		if its_type_ffmprobe is "slnk" then
			set homebrew_ffprobe_exists to true
			set ffprobe_exists to false
		else
			set homebrew_ffprobe_exists to false
			set ffprobe_exists to true
		end if
		-- Nothing in /usr/local/bin - look for Homebrew on ARM Macs
	else if exists file homebrew_ARM_ffprobe_file then
		set ffprobe_exists to false
		set homebrew_ffprobe_exists to true
		set ffprobe_file to ("/opt/homebrew/bin/ffprobe" as text)
		-- Nothing in /opt/homebrew/bin - look for MacPorts install - homebrew_ffprobe_exists used as proxy for MacPorts install
	else if exists file macPorts_ffprobe_file then
		set ffprobe_exists to false
		set homebrew_ffprobe_exists to true
		set ffprobe_file to ("/opt/local/bin/ffprobe" as text)
	else
		set ffprobe_exists to false
		set homebrew_ffprobe_exists to false
	end if
	
	if exists file MacYTDL_prefs_file then
		set prefs_exists to true
	else
		set prefs_exists to false
	end if
	
end tell

-- If no components are installed, can assume it's the first time MacYTDL has been used - need to do a full installation of all components - include Homebrew test as it can be ARM
-- Removed checks for libraries - v1.30, 5/11/25
--if YTDL_exists is false and ytdlp_exists is false and DTP_exists is false and Myriad_exists is false and ffmpeg_exists is false and ffprobe_exists is false and prefs_exists is false and homebrew_ytdlp_exists is false and homebrew_ffmpeg_exists is false and homebrew_ffprobe_exists is false then
if YTDL_exists is false and ytdlp_exists is false and ffmpeg_exists is false and ffprobe_exists is false and prefs_exists is false and homebrew_ytdlp_exists is false and homebrew_ffmpeg_exists is false and homebrew_ffprobe_exists is false and deno_exists is false then
	set theComponentsNotInstalledtTextLabel1 to localized string "It looks like you have not used MacYTDL before. A number of components must be installed for MacYTDL to run. There is more detail in the Help file. Would you like to install those components now ? Otherwise, Quit." from table "MacYTDL"
	set theComponentsNotInstalledtTextLabel2 to localized string "Note: Some components will be downloaded which might take a while and you will need to provide administrator credentials." from table "MacYTDL"
	tell me to activate
	set components_install_answ to button returned of (display dialog theComponentsNotInstalledtTextLabel1 & return & return & theComponentsNotInstalledtTextLabel2 with title diag_Title buttons {theButtonQuitLabel, theButtonYesLabel} default button 2 cancel button 1 with icon file MacYTDL_custom_icon_file giving up after 600)
	if components_install_answ is theButtonYesLabel then
		-- 1.30, 14/11/15 - Not a good idea to have a variable with the same name as a plist entry
		-- set YTDL_ytdlp_version to run_Utilities_handlers's check_ytdl_installed(usr_bin_folder, diag_Title, youtubedl_file, ytdlp_file, theButtonQuitLabel, theButtonYesLabel, path_to_MacYTDL, theButtonOKLabel, resourcesPath, show_yt_dlp, MacYTDL_custom_icon_file)
		set YTDL_version to run_Utilities_handlers's check_ytdl_installed(usr_bin_folder, diag_Title, youtubedl_file, ytdlp_file, theButtonQuitLabel, theButtonYesLabel, path_to_MacYTDL, theButtonOKLabel, resourcesPath, show_yt_dlp, MacYTDL_custom_icon_file)
		--		set YTDL_version to word 1 of YTDL_ytdlp_version
		-- Follow test was used when YTDL could be installed - no longer the case
		--		if word 2 of YTDL_ytdlp_version is "ytdl" then
		--			set YTDL_exists to true
		--			set ytdlp_exists to false
		--		else
		set YTDL_exists to false
		set ytdlp_exists to true
		--		end if
		run_Utilities_handlers's set_preferences(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version, MacYTDL_custom_icon_file)
		set prefs_exists to true
		-- v1.30, 5/11/25 - Commented out as DTP is no longer installed
		--		delay 1
		--		run_Utilities_handlers's install_DTP(DTP_file, path_to_MacYTDL, resourcesPath)
		--	set DTP_exists to true
		-- v1.30, 5/11/25 - Commented out as Myriad is no longer installed
		--	delay 1
		--	run_Utilities_handlers's install_Myriad(Myriad_file, path_to_MacYTDL, resourcesPath)
		-- set Myriad_exists to true
		delay 1
		run_Utilities_handlers's install_ffmpeg_ffprobe(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os, user_system_arch, user_on_mid_os)
		set ffprobe_exists to true
		set ffmpeg_exists to true
		set ffmpeg_version_long to do shell script ffmpeg_file & " -version"
		run_Utilities_handlers's ask_user_install_service(path_to_MacYTDL, theButtonYesLabel, diag_Title, MacYTDL_custom_icon_file)
		-- Added in v1.30, 1/11/25 - part of implementing Deno which is required by yt-dlp
		set install_Deno_question to button returned of (display dialog (localized string "Deno is recommended if you wish to download from YouTube. Do you wish to install Deno ?") with title diag_Title buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with icon file MacYTDL_custom_icon_file giving up after 600)
		set deno_version to "Not installed"
		if install_Deno_question is theButtonYesLabel then
			set deno_version to script "Utilities2"'s install_update_Deno(deno_version, user_system_arch, resourcesPath, path_to_MacYTDL, theButtonOKLabel, MacYTDL_custom_icon_file, diag_Title, MacYTDL_prefs_file)
			set deno_exists to true
		end if
	else
		quit_MacYTDL()
	end if
end if

-- If one or more components are installed, indicates user has used MacYTDL before - check and install any missing components

-- Set up preferences if they don't exist - YTDL_version will contain "not installed" if it is not installed
if prefs_exists is false then
	-- Prefs file doesn't exist - warn user it must be created for MacYTDL to work
	set theInstallPrefsTextLabel to localized string "The MacYTDL Preferences file is not present. To work, MacYTDL needs to create a file in your Preferences folder. Do you wish to continue ?" from table "MacYTDL"
	set Install_Prefs to button returned of (display dialog theInstallPrefsTextLabel buttons {theButtonNoLabel, theButtonYesLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
	if Install_Prefs is theButtonYesLabel then
		set YTDL_version to run_Utilities_handlers's get_ytdlp_version()
		run_Utilities_handlers's set_preferences(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version, MacYTDL_custom_icon_file)
		set prefs_exists to true
	else if Install_Prefs is theButtonNoLabel then
		error number -128
	end if
end if

-- If user gets to here can assume Prefs exist so, check whether user has an old version
-- v1.29 - Using the new check_settings handler which might be a bit quicker
run_Utilities_handlers's check_settings(diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, resourcesPath, show_yt_dlp, MacYTDL_prefs_file, theBestLabel, theDefaultLabel, X_position, Y_position, theNoRemuxLabel, MacYTDL_custom_icon_file)

-- Get updated setting for installed downloader
tell application "System Events"
	tell property list file MacYTDL_prefs_file
		set setting_yt_dlp to value of property list item "Use_ytdlp"
	end tell
end tell

-- 4/3/23 - added test for absence of yt-dlp_macos_legacy - no longer offer to switch to youtube-dl
-- No downloader installed - must install yt-dlp and update settings
-- For some reason user has no downloader or is missing desired downloader - if youtube-dl is missing force install of yt-dlp - include Homebrew test as it can be ARM
if YTDL_exists is false and ytdlp_exists is false and homebrew_ytdlp_exists is false then
	set theYTDLNotInstalledtTextLabel1 to localized string "No downloader is installed. MacYTDL cannot download videos. By default it uses the yt-dlp downloader. Would you like to install yt-dlp now ?" from table "MacYTDL"
	set theYTDLNotInstalledtTextLabel2 to localized string "Note: This download can take a while and you will probably need to provide administrator credentials." from table "MacYTDL"
	tell me to activate
	set yt_install_answ to button returned of (display dialog theYTDLNotInstalledtTextLabel1 & return & return & theYTDLNotInstalledtTextLabel2 with title diag_Title buttons {theButtonQuitLabel, theButtonYesLabel} default button 2 cancel button 1 with icon file MacYTDL_custom_icon_file giving up after 600)
	if yt_install_answ is theButtonYesLabel then
		-- 1.30, 14/11/15 - Not a good idea to have a variable with the same name as a plist entry
		-- set YTDL_ytdlp_version to run_Utilities_handlers's check_ytdl_installed(usr_bin_folder, diag_Title, youtubedl_file, ytdlp_file, theButtonQuitLabel, theButtonYesLabel, path_to_MacYTDL, theButtonOKLabel, resourcesPath, show_yt_dlp, MacYTDL_custom_icon_file)
		set YTDL_version to run_Utilities_handlers's check_ytdl_installed(usr_bin_folder, diag_Title, youtubedl_file, ytdlp_file, theButtonQuitLabel, theButtonYesLabel, path_to_MacYTDL, theButtonOKLabel, resourcesPath, show_yt_dlp, MacYTDL_custom_icon_file)
		-- set YTDL_version to word 1 of YTDL_ytdlp_version
		set ytdlp_exists to true
		-- Need to generalise show_yt_dlp so that only "youtube-dl" or "yt-dlp" is stored in plist
		if show_yt_dlp is "yt-dlp-legacy" then
			set ytdlp_install_show_yt_dlp to "yt-dlp"
		else
			set ytdlp_install_show_yt_dlp to show_yt_dlp
		end if
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Use_ytdlp" to ytdlp_install_show_yt_dlp
				set value of property list item "YTDL_YTDLP_version" to YTDL_version
			end tell
		end tell
	else
		quit_MacYTDL()
	end if
end if

-- YTDL installed contrary to setting - offer switch to yt-dlp - update setting if user chooses not to switch - probably a very rare case
if ytdlp_exists is false and homebrew_ytdlp_exists is false and YTDL_exists is true and (setting_yt_dlp is "yt-dlp" or setting_yt_dlp is "yt-dlp-legacy") then
	set switch_to to "yt-dlp"
	set theYTDLYTDLPIsInstalledtTextLabel to localized string "You are currently set to download with yt-dlp but, it is not installed. This may have been set according to the version of macOS you are using or because there was a fault in downloading yt-dlp. You do have youtube-dl installed. Would you like to switch to yt-dlp" from table "MacYTDL"
	tell me to activate
	set yt_install_answ to button returned of (display dialog theYTDLYTDLPIsInstalledtTextLabel & " ?" with title diag_Title buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with icon file MacYTDL_custom_icon_file giving up after 600)
	if yt_install_answ is theButtonYesLabel then
		-- 1.30, 14/11/15 - Not a good idea to have a variable with the same name as a plist entry
		-- set YTDL_ytdlp_version to run_Utilities_handlers's check_ytdl_installed(usr_bin_folder, diag_Title, youtubedl_file, ytdlp_file, theButtonQuitLabel, theButtonYesLabel, path_to_MacYTDL, theButtonOKLabel, resourcesPath, show_yt_dlp, MacYTDL_custom_icon_file)
		set YTDL_version to run_Utilities_handlers's check_ytdl_installed(usr_bin_folder, diag_Title, youtubedl_file, ytdlp_file, theButtonQuitLabel, theButtonYesLabel, path_to_MacYTDL, theButtonOKLabel, resourcesPath, show_yt_dlp, MacYTDL_custom_icon_file)
		-- set YTDL_version to word 1 of YTDL_ytdlp_version
		set ytdlp_exists to true
		-- Need to generalise show_yt_dlp so that only "youtube-dl" or "yt-dlp" is stored in plist
		if show_yt_dlp is "yt-dlp-legacy" then
			set ytdlp_install_show_yt_dlp to "yt-dlp"
		else
			set ytdlp_install_show_yt_dlp to show_yt_dlp
		end if
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Use_ytdlp" to ytdlp_install_show_yt_dlp
				set value of property list item "YTDL_YTDLP_version" to YTDL_version
			end tell
		end tell
	else
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Use_ytdlp" to "youtube-dl"
			end tell
		end tell
	end if
end if

-- yt-dlp installed contrary to setting - silently update the setting - probably a very rare case
if (ytdlp_exists is true or homebrew_ytdlp_exists is true) and setting_yt_dlp is "youtube-dl" then
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			set value of property list item "Use_ytdlp" to "yt-dlp"
		end tell
	end tell
end if

-- v1.30, 5/11/25 - Commented out as DTP is no longer installed
-- Check if DTP exists - install if not
--if DTP_exists is false then
--	set theInstallDTPTextLabel to localized string "MacYTDL needs a code library installed in your Libraries folder. It cannot function without that library. Do you wish to continue ?" from table "MacYTDL"
--	set install_DTP to button returned of (display dialog theInstallDTPTextLabel buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
--	if install_DTP is theButtonYesLabel then
--		run_Utilities_handlers's install_DTP(DTP_file, path_to_MacYTDL, resourcesPath)
--		set DTP_exists to true
--		--	else if install_DTP is theButtonNoLabel then
--		--		error number -128
--	end if
--end if


-- v1.30, 5/11/25 - Commented out as DTP is no longer installed
-- If user gets to here can assume DTP exists. Check whether DTP name is changed or new version of DTP available
-- run_Utilities_handlers's check_DTP(DTP_file, path_to_MacYTDL)

-- Install FFmpeg and FFprobe if either is missing - versions are updated earlier on if they exist
if ffmpeg_exists is false and homebrew_ffmpeg_exists is false then
	set theInstallFFmpegTextLabel to localized string "FFmpeg is not installed. Would you like to install it now ? If not, MacYTDL can't run and will have to quit. Note: This download can take a while and you will probably need to provide administrator credentials." from table "MacYTDL"
	set Install_FFmpeg to button returned of (display dialog theInstallFFmpegTextLabel buttons {theButtonQuitLabel, theButtonYesLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
	if Install_FFmpeg is theButtonYesLabel then
		run_Utilities_handlers's install_ffmpeg_ffprobe(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os, user_system_arch, user_on_mid_os)
		set ffmpeg_exists to true
		set ffprobe_exists to true
		set ffmpeg_version_long to do shell script ffmpeg_file & " -version"
	else if Install_FFmpeg is theButtonNoLabel then
		error number -128
	end if
end if
if ffprobe_exists is false and homebrew_ffprobe_exists is false then
	set theInstallFFprobeTextLabel to localized string "FFprobe is not installed. Would you like to install it now ? If not, MacYTDL can't run and will have to quit. Note: This download can take a while and you will probably need to provide administrator credentials." from table "MacYTDL"
	set Install_FFprobe to button returned of (display dialog theInstallFFprobeTextLabel buttons {theButtonQuitLabel, theButtonYesLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
	if Install_FFprobe is theButtonYesLabel then
		run_Utilities_handlers's install_ffmpeg_ffprobe(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os, user_system_arch, user_on_mid_os)
		set ffmpeg_exists to true
		set ffprobe_exists to true
		set ffmpeg_version_long to do shell script ffmpeg_file & " -version"
	else if Install_FFprobe is theButtonNoLabel then
		error number -128
	end if
end if

-- v1.27.1 - Added try block to trap faulty FFmpeg installs - caused by bug sometime in past - Ugghh
if ffmpeg_exists is true or homebrew_ffmpeg_exists is true then
	try
		set ffmpeg_version_long to do shell script shellPath & "  ffmpeg -version"
	on error
		set theWrongFFmpegInstalledTextLabel to localized string "It looks like there is a problem with your installed copy of FFmpeg. Click on Install to replace that copy or Quit."
		set theButtonInstallLabel to localized string "Install"
		set FFmpeg_wrong_install_answ to button returned of (display dialog theWrongFFmpegInstalledTextLabel with title diag_Title buttons {theButtonQuitLabel, theButtonInstallLabel} default button 2 cancel button 1 with icon file MacYTDL_custom_icon_file giving up after 600)
		if FFmpeg_wrong_install_answ is theButtonInstallLabel then
			run_Utilities_handlers's install_ffmpeg_ffprobe(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os, user_system_arch, user_on_mid_os)
			set ffmpeg_version_long to do shell script shellPath & "  ffmpeg -version"
		else
			quit_MacYTDL()
		end if
	end try
	set AppleScript's text item delimiters to {"-", " "}
	set ffmpeg_version to text item 3 of ffmpeg_version_long
	set AppleScript's text item delimiters to ""
end if
-- v1.29 - Decided to speed up a bit by not getting FFprobe version from binary - should always be the same ass FFmpeg
if ffprobe_exists is true or homebrew_ffprobe_exists is true then
	--	set ffprobe_version_long to do shell script shellPath & "  ffprobe -version"
	--	set AppleScript's text item delimiters to {"-", " "}
	--	set ffprobe_version to text item 3 of ffprobe_version_long
	set ffprobe_version to ffmpeg_version
	--	set AppleScript's text item delimiters to ""
end if

-- User might have accidentally deleted Deno - have to read setting to find out - NB Deno is not required for MacYTDL so, it remains optional
tell application "System Events"
	tell property list file MacYTDL_prefs_file
		set deno_version to value of property list item "Deno_version"
	end tell
end tell
if deno_exists is false and deno_version is not "Refused" and deno_version is not "Not installed" then
	set theInstallDenoTextLabel to localized string "Deno is not installed. Would you like to install it now ? Note: You will probably need to provide administrator credentials." from table "MacYTDL"
	set Install_Deno to button returned of (display dialog theInstallDenoTextLabel buttons {theButtonNoLabel, theButtonYesLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
	if Install_Deno is theButtonYesLabel then
		set deno_version to script "Utilities2"'s install_update_Deno("Not installed", user_system_arch, resourcesPath, path_to_MacYTDL, theButtonOKLabel, MacYTDL_custom_icon_file, diag_Title, MacYTDL_prefs_file)
		set deno_exists to true
	else if Install_Deno is theButtonNoLabel then
		set deno_version to "Refused"
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Deno_version" to "Refused"
			end tell
		end tell
	end if
end if

-- Is Atomic Parsley installed ? [Needed by youtube-dl for embedding thumbnails in mp4 and m4a files] - result is displayed in Utilities dialog
set macYTDL_Atomic_file to ("usr:local:bin:AtomicParsley" as text)
tell application "System Events"
	if (exists file macYTDL_Atomic_file) then
		set Atomic_is_installed to true
	else
		set Atomic_is_installed to false
	end if
end tell

-- Added in v1.30, 1/11/25 - part of implementation of Deno, needed by yt-dlp - hopefully, getting Deno version on every startup is not too slow - but seems to slow startup on old Macs
-- v1.30, 16/12/25 - Realised that Deno version had to be stored in user's plist - Bum
-- v1.30, 18/12/25 - Realised that we need to test for existance of deno_file - user might accidentally delete it - added code to bulk existence checks above
--set deno_file to ("usr:local:bin:deno" as text)
--tell application "System Events"
--	if exists file deno_file then
--		try
--			set deno_version to do shell script shellPath & "deno --version"
--			set deno_version to word 2 of deno_version
--		end try
--	else
--		set deno_version to "Not installed"
--	end if
--end tell

-- Is auto checking of youtube-dl/yt-dlp version on ? DL_Use_YTDLP contains "yt-dlp" or "youtube-dl"
tell application "System Events"
	tell property list file MacYTDL_prefs_file
		set DL_YTDL_auto_check to value of property list item "Auto_Check_YTDL_Update"
		set DL_Use_YTDLP to value of property list item "Use_ytdlp"
	end tell
end tell

-- Set path and name for youtube-dl/yt-dlp simulated log file - a simulated youtube-dl/yt-dlp download puts all its feedback into this file - it's a generic file used for all downloads and so only contains detail on the most recent download - simulation helps find errors and problems before starting the download
set YTDL_simulate_file to MacYTDL_preferences_path & "ytdl_simulate.txt"

-- Check version of Service if installed - update if old
run_Utilities_handlers's update_MacYTDLservice(path_to_MacYTDL, MacYTDL_prefs_file, show_yt_dlp)

-- Check if user is on macOS 12.3+ and using youtube-dl - they need to switch to yt-dlp or quit
if user_on_123 is true and DL_Use_YTDLP is "youtube-dl" then
	set warning_YTDL_not_working to localized string "Sorry, \"youtube-dl\" does not work in macOS 12.3 and above. Would you like to switch to \"yt-dlp\" or Quit ?" from table "MacYTDL"
	set theButtonSwitchLabel to localized string "Switch" from table "MacYTDL"
	set switch_or_quit to button returned of (display dialog warning_YTDL_not_working buttons {theButtonQuitLabel, theButtonSwitchLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
	if switch_or_quit is theButtonSwitchLabel then
		if (ytdlp_exists is false and homebrew_ytdlp_exists is false) then check_ytdl(show_yt_dlp)
		set YTDL_version to do shell script ytdlp_file & " --version"
		-- Need to generalise show_yt_dlp so that only "youtube-dl" or "yt-dlp" is stored in plist
		if show_yt_dlp is "yt-dlp-legacy" then
			set switched_show_yt_dlp to "yt-dlp"
		else
			set switched_show_yt_dlp to show_yt_dlp
		end if
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Use_ytdlp" to switched_show_yt_dlp
				set value of property list item "YTDL_YTDLP_version" to YTDL_version
			end tell
		end tell
	end if
end if

-- Do the auto check - but not if user has Homebrew or MacPorts installed - this code might need some more nuance
if DL_YTDL_auto_check is true then
	set cancel_update_flag to false
	-- Need to set YTDL_version according to current install
	-- v1.29 - Decided to omit this version check as it takes too much time - can assume that current user's YTDL-YTDLP_version is correct or very close
	--	if DL_Use_YTDLP is "youtube-dl" then
	--		set YTDL_version to do shell script youtubedl_file & " --version"
	--	else if homebrew_ytdlp_exists is false then
	--		set YTDL_version to do shell script ytdlp_file & " --version"
	--	end if
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			set YTDL_version to value of property list item "YTDL_YTDLP_version"
		end tell
	end tell
	if length of YTDL_version is greater than 12 then
		set alert_text_ytdlLabel to localized string "Do you wish to update your nightly build of yt-dlp" from table "MacYTDL"
		set update_nightly_q to button returned of (display dialog (alert_text_ytdlLabel & " ?") with title diag_Title buttons {theButtonNoLabel, theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600)
		if update_nightly_q is theButtonOKLabel then
			-- Install nightly build - no need to check version as nightly builds are released usually every few days
			-- v1.29 - Install unpacked version of latest nightly build
			try
				--	do shell script shellPath & " yt-dlp --update-to nightly" with administrator privileges
				--	set download_URL to "https://github.com/yt-dlp/yt-dlp-nightly-builds/releases/latest/download/yt-dlp_macos.zip"
				--	set ytdlp_download_file to "/usr/local/bin/yt-dlp_macos.zip"  -- <= Hard coding this enabled SD to save the compiled script
				if show_yt_dlp is "yt-dlp" then
					do shell script "curl -L https://github.com/yt-dlp/yt-dlp-nightly-builds/releases/latest/download/yt-dlp_macos.zip -o /usr/local/bin/yt-dlp_macos.zip" with administrator privileges
					set installAlertActionLabel to quoted form of "_"
					set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
					set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
					set installAlertSubtitle to quoted form of ((localized string "Download and install of " from table "MacYTDL") & show_yt_dlp)
					do shell script resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
					do shell script "unzip -o /usr/local/bin/yt-dlp_macos.zip -d /usr/local/bin/" with administrator privileges
					do shell script "mv /usr/local/bin/yt-dlp_macos /usr/local/bin/yt-dlp" with administrator privileges
					do shell script "rm /usr/local/bin/yt-dlp_macos.zip" with administrator privileges
				else if show_yt_dlp is "yt-dlp-legacy" then
					--	set download_URL to "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos_legacy"
					--		do shell script "curl -L  https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos_legacy  -o /usr/local/bin/yt-dlp" with administrator privileges
					do shell script "curl -L  https://github.com/yt-dlp/yt-dlp/releases/download/2025.08.11/yt-dlp_macos_legacy  -o /usr/local/bin/yt-dlp" with administrator privileges
					do shell script "chmod a+x /usr/local/bin/yt-dlp" with administrator privileges
				end if
				-- trap case where user cancels credentials dialog
			on error number -128
				set cancel_update_flag to true
			end try
			if cancel_update_flag is false then
				-- v1.30, 14/11/25 - Now getting yt-dlp version from release web page - seems faster
				--	set YTDL_version to do shell script "/usr/local/bin/yt-dlp --version"
				set YTDL_site_URL to "https://github.com/yt-dlp/yt-dlp-nightly-builds/releases"
				set YTDL_releases_page to do shell script "curl " & YTDL_site_URL & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
				set AppleScript's text item delimiters to "Latest"
				set YTDL_releases_text to text item 1 of YTDL_releases_page
				set numParas to count paragraphs in YTDL_releases_text
				set version_para to paragraph (numParas) of YTDL_releases_text
				set AppleScript's text item delimiters to " "
				set YTDL_version to text item 3 of version_para
				set AppleScript's text item delimiters to ""
				tell application "System Events"
					tell property list file MacYTDL_prefs_file
						set value of property list item "YTDL_YTDLP_version" to YTDL_version
					end tell
				end tell
				set alert_text_ytdl to "has been updated"
			end if
		end if
	else if homebrew_ytdlp_exists is false and cancel_update_flag is false then
		check_ytdl(DL_Use_YTDLP)
	else
		set alert_text_ytdlLabel to localized string "Sorry, auto update cannot be used for Homebrew/MacPorts installs of yt-dlp." from table "MacYTDL"
		display dialog alert_text_ytdlLabel with title diag_Title buttons theButtonOKLabel default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
	end if
	set alert_text_ytdlLabel to localized string "has been updated" from table "MacYTDL"
	if alert_text_ytdl contains alert_text_ytdlLabel then
		display dialog DL_Use_YTDLP & " " & (alert_text_ytdl & ".") with title diag_Title buttons theButtonOKLabel default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
	end if
end if

-- Set ABC show name and episode count variables so they exist
set ABC_show_name to ""
set SBS_show_name to ""
set number_ABC_SBS_episodes to 0


-- Test of not repeating localizations with every call to main_dialog()
set theButtonsHelpLabel to localized string "Help" from table "MacYTDL"
set theButtonsUtilitiesLabel to localized string "Utilities" from table "MacYTDL"
set theButtonsSettingsLabel to localized string "Settings" from table "MacYTDL"
set theButtonsAdminLabel to localized string "Admin" from table "MacYTDL"
set theFieldLabel to localized string "Paste URL here" from table "MacYTDL"
set theCheckbox_Show_SettingsLabel to localized string "Show settings before download" from table "MacYTDL"
set theCheckbox_SubTitlesLabel to localized string "Subtitles for this download" from table "MacYTDL"
set theCheckbox_CredentialsLabel to localized string "Credentials for download" from table "MacYTDL"
set theCheckbox_DescriptionLabel to localized string "Download description" from table "MacYTDL"
set thePathControlLabel to localized string "Change download folder:" from table "MacYTDL"
set theCheckbox_OpenBatchLabel to localized string "Open Batch functions" from table "MacYTDL"
set theCheckbox_AddToBatchLabel to localized string "Add URL to Batch" from table "MacYTDL"
set theDiagSettingsTextLabel to localized string "One-time settings:                                     Batches:" from table "MacYTDL"


-- ************************************************************************************************************************************************************
-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow - Batch functions, Admin, Settings and Utilities return flow back here
repeat
	main_dialog(theButtonsHelpLabel, theButtonsUtilitiesLabel, theButtonsSettingsLabel, theButtonsAdminLabel, theFieldLabel, theCheckbox_Show_SettingsLabel, theCheckbox_SubTitlesLabel, theCheckbox_CredentialsLabel, theCheckbox_DescriptionLabel, thePathControlLabel, theCheckbox_OpenBatchLabel, theCheckbox_AddToBatchLabel, theDiagSettingsTextLabel)
end repeat
-- ************************************************************************************************************************************************************

on main_dialog(theButtonsHelpLabel, theButtonsUtilitiesLabel, theButtonsSettingsLabel, theButtonsAdminLabel, theFieldLabel, theCheckbox_Show_SettingsLabel, theCheckbox_SubTitlesLabel, theCheckbox_CredentialsLabel, theCheckbox_DescriptionLabel, thePathControlLabel, theCheckbox_OpenBatchLabel, theCheckbox_AddToBatchLabel, theDiagSettingsTextLabel)
	
	--*****************  This is for testing variables as they come into and back to Main - beware some of these are not defined on all circumstances
	--	display dialog "video_URL: " & return & return & "called_video_URL: " & called_video_URL & return & return & "URL_user_entered: " & URL_user_entered & return & return & "URL_user_entered_clean: " & URL_user_entered_clean & return & return & "default_contents_text: "
	
	-- Read the preferences file to get current settings - if error probably because of missing prefs - error can be caused by user restoring preferences file which is in old format
	run_Utilities_handlers's read_settings(MacYTDL_prefs_file)
	
	-- Need to work through why I put this code here - deary me, a lack of documentation - originally intended to fix a translation issue but, does it cause one ?
	set DL_format to localized string DL_format from table "MacYTDL"
	set DL_subtitles_format to localized string DL_subtitles_format from table "MacYTDL"
	set DL_Remux_format to localized string DL_Remux_format from table "MacYTDL"
	set DL_audio_codec to localized string DL_audio_codec from table "MacYTDL"
	
	-- In rare cases, the prefs file had to be recreated (above) - need to clean up YTDL_version and YTDL_YTDLP_version
	-- v1.29 - 27/9/24 - might be able to remove this code block while implementing new Settings arrangement
	if YTDL_version is "Not installed" then
		if DL_Use_YTDLP is "youtube-dl" then
			set YTDL_version to do shell script youtubedl_file & " --version"
		else
			set YTDL_version to do shell script ytdlp_file & " --version"
		end if
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "YTDL_YTDLP_version" to YTDL_version
			end tell
		end tell
	end if
	
	-- Set batch file status so that it persists while MacYTDL is running - Can't remember why this is necessary
	try
		if DL_batch_status is true then
			set DL_batch_status to true
		end if
	on error
		set DL_batch_status to false
	end try
	
	-- URL is emptied after download started - otherwise it should stay available so that it can be passed to/from Settings and Utilities
	-- Test whether app was called by Service - error means not called and so there is no URL to be passed to the Main Dialog
	try
		-- Test whether URL provided by Service has been reset to blank on a previous pass through - called_video_URL contains URL sent by Service
		if called_video_URL is "" then
			set default_contents_text to URL_user_entered_clean
		else
			set default_contents_text to called_video_URL
		end if
		-- Need to reset the called_video_URL variable so that it doesn't overwrite the URL text box after a later download
		set called_video_URL to ""
	on error errnum -- Not called from Service, should always be error -2753 (variable not defined) - refill URL so it's shown in dialog - will be blank if user has not pasted a URL
		set default_contents_text to URL_user_entered_clean
	end try
	
	set accViewWidth to 450
	set accViewInset to 80
	
	-- Set buttons and controls
	set {theButtons, minWidth} to create buttons {theButtonsHelpLabel, theButtonsUtilitiesLabel, theButtonQuitLabel, theButtonsAdminLabel, theButtonsSettingsLabel, theButtonContinueLabel} button keys {"?", "u", "q", "<", ",", ""} default button 6
	if minWidth > accViewWidth then set accViewWidth to minWidth -- make sure buttons fit
	set {theField, theTop} to create field default_contents_text placeholder text theFieldLabel left inset accViewInset bottom 0 field width accViewWidth - accViewInset extra height 15
	set {theRule, theTop} to create rule theTop + 18 rule width accViewWidth
	set {theCheckbox_Show_Settings, theTop} to create checkbox theCheckbox_Show_SettingsLabel left inset accViewInset + 50 bottom (theTop + 10) max width 250 initial state DL_Show_Settings
	set {theCheckbox_SubTitles, theTop} to create checkbox theCheckbox_SubTitlesLabel left inset accViewInset bottom (theTop + 15) max width 250 initial state DL_subtitles
	set {theCheckbox_Credentials, theTop} to create checkbox theCheckbox_CredentialsLabel left inset accViewInset bottom (theTop + 5) max width 200 without initial state
	set {theCheckbox_Description, theTop} to create checkbox theCheckbox_DescriptionLabel left inset accViewInset bottom (theTop + 5) max width 175 initial state DL_description
	
	-- v1.30, 25/11/25 - No longer have remux as runtime setting => User must use Settings dialog
	--	set theLabelledPopUpRemuxFileformat to localized string "Remux format:" from table "MacYTDL"
	--	if DL_Use_YTDLP is "yt-dlp" then
	--		set {main_thePopUp_FileFormat, main_formatlabel, theTop, popupLeft} to create labeled popup {theNoRemuxLabel, "avi", "flv", "gif", "mkv", "mov", "mp4", "webm", "aiff", "flac", "m4a", "mka", "mp3", "ogg", "wav"} left inset accViewInset - 5 bottom (theTop + 5) popup width 100 max width 200 label text theLabelledPopUpRemuxFileformat popup left accViewInset - 5 initial choice DL_Remux_format
	--	else
	--		set {main_thePopUp_FileFormat, main_formatlabel, theTop, popupLeft} to create labeled popup {theNoRemuxLabel, "mp4", "mkv", "flv", "webm", "avi", "ogg"} left inset accViewInset - 5 bottom (theTop + 5) popup width 100 max width 200 label text theLabelledPopUpRemuxFileformat popup left accViewInset - 5 initial choice DL_Remux_format
	--	end if
	set {thePathControl, pathLabel, theTop} to create labeled path control (POSIX path of downloadsFolder_Path) left inset accViewInset bottom (theTop + 5) control width 190 label text thePathControlLabel with pops up
	set {theCheckbox_OpenBatch, theTop, theBatchLabelWidth} to create checkbox theCheckbox_OpenBatchLabel left inset (accViewInset + 210) bottom (theTop - 40) max width 200 without initial state
	-- Increase width when localised text is longer than English
	set add_extra_dialog_width to 0
	if theBatchLabelWidth is greater than 158 then
		set add_extra_dialog_width to (theBatchLabelWidth - 158)
	end if
	set {theCheckbox_AddToBatch, theTop} to create checkbox theCheckbox_AddToBatchLabel left inset (accViewInset + 210) bottom (theTop + 5) max width 200 initial state DL_batch_status
	set {diag_settings_prompt, theTop} to create label theDiagSettingsTextLabel left inset accViewInset bottom theTop + 8 max width accViewWidth control size regular size with bold type
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 60 view width 64 view height 64 scale image scale proportionally
	
	-- Display the dialog
	tell me to activate -- Is this really needed ? Turning off hasn't stopped icon bouncing in Dock after showing Help file -- 29/3/25 - decommented this line in hope of solving problem for user who gets “User interaction disallowed” error
	-- v1.30, 25/11/25 - No longer provide Remux as runtime option
	--	set {button_label_returned, button_number_returned, controls_results, finalPosition} to display enhanced window diag_Title acc view width (accViewWidth + add_extra_dialog_width) acc view height theTop acc view controls {theField, theCheckbox_Show_Settings, theCheckbox_SubTitles, theCheckbox_Credentials, theCheckbox_Description, main_thePopUp_FileFormat, main_formatlabel, thePathControl, theCheckbox_AddToBatch, theCheckbox_OpenBatch, pathLabel, diag_settings_prompt, theRule, MacYTDL_icon} buttons theButtons active field theField initial position window_Position
	set {button_label_returned, button_number_returned, controls_results, finalPosition} to display enhanced window diag_Title acc view width (accViewWidth + add_extra_dialog_width) acc view height theTop acc view controls {theField, theCheckbox_Show_Settings, theCheckbox_SubTitles, theCheckbox_Credentials, theCheckbox_Description, thePathControl, theCheckbox_AddToBatch, theCheckbox_OpenBatch, pathLabel, diag_settings_prompt, theRule, MacYTDL_icon} buttons theButtons active field theField initial position window_Position
	
	-- Has user moved the MacYTDL window - if so, save new position
	if finalPosition is not equal to window_Position then
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "final_Position" to finalPosition
			end tell
		end tell
	end if
	
	if button_number_returned is 3 then -- Quit
		quit_MacYTDL()
	end if
	
	-- Get control results from Main dialog
	set URL_user_entered_clean to item 1 of controls_results -- Needed to refill the URL box on return from Settings, Help etc.
	set show_settings_choice to item 2 of controls_results
	set subtitles_choice to item 3 of controls_results
	set credentials_choice to item 4 of controls_results
	set description_choice to item 5 of controls_results
	--	set remux_format_choice to item 6 of controls_results   --   No longer have remux as runtime option
	set folder_chosen to item 6 of controls_results
	set DL_batch_status to item 7 of controls_results
	set openBatch_chosen to item 8 of controls_results
	
	-- Load batch handlers if required
	--	if openBatch_chosen is true or DL_batch_status is true then
	--		set path_to_Batch_Handlers to (path_to_MacYTDL & "Contents:Resources:Scripts:batch.scpt") as alias
	--		set run_Batch_Handlers to load script path_to_Batch_Handlers
	--	end if
	
	-- Trim any trailing spaces from URL entered by user - reduces errors later on
	if URL_user_entered_clean is not "" and URL_user_entered_clean is not " " then
		if text item -1 of URL_user_entered_clean is " " then set URL_user_entered_clean to text 1 thru -2 of URL_user_entered_clean
	end if
	
	set URL_user_entered to quoted form of URL_user_entered_clean -- Quoted form needed in case the URL contains ampersands etc - but really need to get quoted form of each URL when more than one
	
	-- Does user wish to see settings before download - save choice - the setting will be queried before download starts
	if show_settings_choice is not equal to DL_Show_Settings then
		set DL_Show_Settings to show_settings_choice
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Show_Settings_before_Download" to show_settings_choice
			end tell
		end tell
	end if
	
	if button_number_returned is 5 then -- Show Settings
		set branch_execution to set_settings()
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return
		-- ************************************************************************************************************************************************************
		
	else if button_number_returned is 4 then
		set branch_execution to run_Utilities_handlers's set_admin_settings(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version, MacYTDL_custom_icon_file, theButtonCancelLabel, window_Position, theButtonReturnLabel, MacYTDL_custom_icon_file_posix, theButtonOKLabel)
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow - This returns to the loop which starts main_dialog() again or diverts to set_settings()
		if branch_execution is "Main" then return branch_execution
		if branch_execution is "Settings" then set branch_execution to set_settings()
		--		if branch_execution is "Main" then main_dialog()
		return branch_execution
		-- ************************************************************************************************************************************************************		
		
	else if button_number_returned is 2 then -- Show Utilities
		utilities()
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return
		-- ************************************************************************************************************************************************************
		
	else if button_number_returned is 1 then -- Show Help
		set path_to_MacYTDL_alias to path_to_MacYTDL as alias
		set MacYTDL_help_file to (path to resource "Help.pdf" in bundle path_to_MacYTDL_alias) as string
		set MacYTDL_help_file_posix to POSIX path of MacYTDL_help_file
		tell application "System Events" to open file MacYTDL_help_file_posix
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return
		--	main_dialog()
		-- ************************************************************************************************************************************************************		
		
	end if
	
	-- Convert settings to format that can be used as youtube-dl/yt-dlp parameters + define variables
	if description_choice is true then
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
	
	if DL_STEmbed is true then
		set YTDL_STEmbed to "--embed-subs "
	else
		set YTDL_STEmbed to ""
	end if
	
	-- Prepare User's download settings - using current settings - yt-dlp prefers to have name of post processor
	-- v1.28 - Found that FFmpeg added "-codec copy" to ST converter which then failed -- found that -codec copy was not needed anyway -- youtube-dl doesn't have remux-video, use recode-video
	-- v1.30 - Added recode_video facility - replaced by better version
	--	if remux_format_choice is not theNoRemuxLabel then
	--		if DL_Use_YTDLP is "yt-dlp" then
	--			--			set YTDL_remux_format to "--recode-video " & remux_format_choice & " " & "--postprocessor-args \"ffmpeg:-codec copy\" "
	--			--			set YTDL_remux_format to "--recode-video " & remux_format_choice & " " & "--postprocessor-args \"ffmpeg:vcodec copy acodec copy\" "    -- <= FFmpeg makes a hash of this applying ppa to subtitle conversion !
	--			set YTDL_remux_format to "--remux-video " & remux_format_choice & " "
	--		else
	--			--			set YTDL_remux_format to "--recode-video " & remux_format_choice & " " & "--postprocessor-args \"-codec copy\" "
	--			set YTDL_remux_format to "--recode-video " & remux_format_choice & " "
	--		end if
	--	else
	--		set YTDL_remux_format to ""
	--	end if
	
	-- v1.30 - Added recode_video facility
	if DL_Remux_Recode is "Remux" then
		if DL_Use_YTDLP is "yt-dlp" then
			set YTDL_recode_remux to "--remux-video " & DL_Remux_format & " "
		else
			set YTDL_recode_remux to "--recode-video " & DL_Remux_format & " "
		end if
	else if DL_Remux_Recode is "Recode" then
		set YTDL_recode_remux to "--recode-video " & DL_Remux_format & " "
	else
		set YTDL_recode_remux to ""
	end if
	
	if DL_Remux_original is true then
		set YTDL_Remux_original to "--keep-video "
	else
		set YTDL_Remux_original to ""
	end if
	-- Set YTDL format parameter desired format + set separate YTDL_format_pref variable for use in simulate stage
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
	else if DL_audio_only is true then
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
	set YTDL_credentials to ""
	if credentials_choice is true then
		-- v1.29.3 - 13/6/25 - Added code needed to return to Main dialog
		set YTDL_credentials to run_Utilities_handlers's get_YTDL_credentials(theButtonReturnLabel, theButtonOKLabel, MacYTDL_custom_icon_file_posix, diag_Title, MacYTDL_custom_icon_file)
		if YTDL_credentials is "Main" then return
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
		-- v1.27 - 12/6/24 - Testing different video converter "videotoolbox"- definitely faster - But, some online posts suggest quality is not good - anyway, might be deprecated
		--		set YTDL_QT_Compat to "--recode-video \"mp4\" --ppa \"VideoConvertor:-vcodec h264_videotoolbox -acodec aac\" "
		-- v1.30, 2/12/25 - Changed from --recode-video to --exec to force FFmpeg to recode when container is already in mp4 format - note, QT compatible videos will also be converted
		-- set YTDL_QT_Compat to "--recode-video \"mp4\" --ppa \"VideoConvertor:-vcodec libx264 -acodec aac\" "
		set YTDL_QT_Compat to "--exec \"ffmpeg -i %(filepath)q -c:v libx264 -c:a aac -f mp4 %(filepath)q.mp4\" "
		set YTDL_recode_remux to ""
	else
		set YTDL_QT_Compat to ""
	end if
	
	set YTDL_no_part to ""
	
	-- Set settings to enable audio only download - gets a format list - use post-processing if necessary - need to ignore all errors here which are usually due to missing videos etc. - only check first item of a playlist
	-- v1.30, 14/11/25 - Decided to skip this block if user wants batch functions
	if DL_audio_only is true and openBatch_chosen is false then
		set one_playlist_item to ""
		if URL_user_entered_clean contains "playlist" or (URL_user_entered_clean contains "watch?" and URL_user_entered_clean contains "&list=") or (URL_user_entered_clean contains "?list=") then
			set one_playlist_item to "--playlist-items 1 "
		end if
		try
			set YTDL_get_formats to do shell script shellPath & DL_Use_YTDLP & " --list-formats --ignore-errors " & one_playlist_item & URL_user_entered & " 2>&1"
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
	
	-- Tell download_video handler that it should return to main_dialog when finished - auto_download tells download_video to skip main and just close	
	set skip_Main_dialog to false
	
	-- ************************************************************************************************************************************************************
	-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
	--	check_download_folder(folder_chosen, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, diag_Title, MacYTDL_custom_icon_file, skip_Main_dialog)
	set branch_execution to check_download_folder(folder_chosen, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, diag_Title, MacYTDL_custom_icon_file, skip_Main_dialog)
	if branch_execution is "Main" then return
	-- ************************************************************************************************************************************************************
	
	if DL_Use_Cookies is true then
		set branch_execution to run_Utilities_handlers's check_cookies_file(DL_Cookies_Location)
		if branch_execution is "Quit" then quit_MacYTDL()
		if branch_execution is "Main" then return "Main"
	end if
	
	
	-- Set variable to contain download folder path - value comes from runtime settings which gets initial value from preferences but which user can then change
	-- But first, if user has set download path to a file, use parent folder for downloads
	tell application "System Events" to set test_DL_folder to (get class of item (folder_chosen as text)) as text
	if test_DL_folder is "file" then
		-- Trim last part of path name
		set offset_to_file_name to run_Utilities_handlers's last_offset(folder_chosen as text, "/")
		set folder_chosen to text 1 thru offset_to_file_name of folder_chosen
	end if
	
	-- Need to set up a dummy variable to take the URL when it is sent by Utilities/auto_download(). This is so that the old behaviour in which main_dialog reopens with a blank URL box after a download can be retained yet the URL is retained if user goes from Main to Settings/Utilities and back to Main
	set URL_user_entered_from_auto_download to ""
	
	set downloadsFolder_Path to folder_chosen
	
	-- v1.30, 25/11/25 changed YTDL_remux_format to YTDL_recode_remux - YTDL_remux_format has been replaced with YTDL_recode_remux and DL_Remux_format now controls both recode and remux
	if button_number_returned is 6 then -- Continue to download	or batch functions	
		if openBatch_chosen is true then
			set branch_execution to run_Batch_Handlers's open_batch_processing(folder_chosen, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, batch_file, theButtonOKLabel, theButtonReturnLabel, theButtonDownloadLabel, MacYTDL_custom_icon_file_posix, diag_Title, window_Position, MacYTDL_custom_icon_file, screen_width, screen_height, YTDL_Use_netrc, deno_version, YTDL_version)
			
			--			display dialog "branch_execution is: " & branch_execution
			-- This next line doesn't make sense - It never happens
			--	if branch_execution is "Settings" then set_settings()
			
		else
			download_video(shellPath, path_to_MacYTDL, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, screen_width, screen_height, YTDL_simulate_file, URL_user_entered, URL_user_entered_from_auto_download, folder_chosen, diag_Title, DL_batch_status, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format_pref, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, skip_Main_dialog, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, theButtonReturnLabel, theButtonQuitLabel, theButtonContinueLabel, YTDL_QT_Compat, DL_Use_YTDLP, theBestLabel, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, user_on_old_os, X_position, deno_version, YTDL_Use_netrc, YTDL_version)
			set branch_execution to "Main" -- This probably not necessary but, well, belt and braces principle applies
		end if
	end if
end main_dialog


---------------------------------------------------------------------------------------------
--
-- 	Download videos - called by Main dialog - calls monitor.scpt
--
---------------------------------------------------------------------------------------------
on download_video(shellPath, path_to_MacYTDL, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, screen_width, screen_height, YTDL_simulate_file, URL_user_entered, URL_user_entered_from_auto_download, folder_chosen, diag_Title, DL_batch_status, DL_Remux_format, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format_pref, YTDL_format, YTDL_recode_remux, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, skip_Main_dialog, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, theButtonReturnLabel, theButtonQuitLabel, theButtonContinueLabel, YTDL_QT_Compat, DL_Use_YTDLP, theBestLabel, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, user_on_old_os, X_position, deno_version, YTDL_Use_netrc, YTDL_version)
	
	if URL_user_entered_from_auto_download is not "" then
		set URL_user_entered_clean to URL_user_entered_from_auto_download
	end if
	
	set number_ABC_SBS_episodes to 0
	
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
	if URL_user_entered contains "https://iview.abc.net.au/show" and user_on_old_os is true then
		set theURLWarningiViewCategoryLabel to localized string "This is an iView show page which MacYTDL cannot display on OS X 10.10, 10.11 and 10.12. Try an individual show." from table "MacYTDL"
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
			-- v1.30, 23/12/25 - Output templates to test what iView provide
			set YTDL_output_template to "-o '%(series)s_%(season_number)s_%(episode)s.%(ext)s'"
			--	set YTDL_output_template to " -o '%(episode)s_%(tags)s_%(categories)s_%(media_type)s_%(channel)s_%(alt_title)s_%(fulltitle)s_%(series)s_%(title)s.%(ext)s'"
			-- set YTDL_output_template to " -o '%(series)s-%(title)s.%(ext)s'"
		else if URL_user_entered contains "ITV" then
			set YTDL_output_template to " -o '%(series)s-%(season)s-%(title)s.%(ext)s'"
		else if URL_user_entered contains "9Now" then
			set URL_user_entered_sans_q to text 1 thru -2 of URL_user_entered
			set AppleScript's text item delimiters to "/"
			set NineNow_URL_items to every text item of URL_user_entered_sans_q
			set AppleScript's text item delimiters to ""
			set NineNow_show_old to text 1 thru end of item 4 of NineNow_URL_items
			set NineNow_show_new to run_Utilities_handlers's replace_chars(NineNow_show_old, "-", "_")
			set YTDL_output_template to " -o '" & NineNow_show_new & "-%(title)s.%(ext)s'"
		else if URL_user_entered contains "7Plus" then
			set YTDL_output_template to " -o '%(series)s-%(title)s.%(ext)s'"
		end if
	end if
	
	-- v1.30, 5/11/25 - Sixth - If URL points to YouTube, and user has recent version of yt-dlp, check that Deno is installed - if not, offer to install
	-- v1.30, 16/12/25 - Note that Deno_version can be "Refused" so that Deno install is offered only once
	-- v1.30, 21/12/25 - Added if block to cover case when one user installs Deno but another runs MacYTDL and so Deno existance inconsistant with user's plist
	if (URL_user_entered_clean contains "youtube" or URL_user_entered_clean contains "youtu.be") and deno_version is "Not installed" then
		if deno_exists is true then
			-- Get verison of installed Deno and update plist
			set deno_version to word 2 of (do shell script "/usr/local/bin/Deno -v") as text
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Deno_version" to deno_version
				end tell
			end tell
		else
			considering numeric strings
				if YTDL_version is greater than "2025.10.22" then
					set theButtonInstall to localized string "Install Deno"
					set install_deno_query to button returned of (display dialog (localized string "You need Deno installed to be sure of downloading from YouTube. Do you wish Deno to be installed, return to Main dialog or try without Deno ?") buttons {theButtonReturnLabel, theButtonContinueLabel, theButtonInstall} with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
					if install_deno_query is theButtonInstall then
						set deno_version to script "Utilities2"'s install_update_Deno(deno_version, user_system_arch, resourcesPath, path_to_MacYTDL, theButtonOKLabel, MacYTDL_custom_icon_file, diag_Title, MacYTDL_prefs_file)
						set deno_exists to true
						-- For some reason, yt-dlp doesn't see the Deno binary immediately after Deno has been installed. Hopefully a small delay will be enough to enable Deno to be seen
						delay 2
					else if install_deno_query is theButtonReturnLabel then
						-- User did not want to install - Set deno_version to "Refused" so this is not offered again
						tell application "System Events"
							tell property list file MacYTDL_prefs_file
								set value of property list item "Deno_version" to "Refused"
							end tell
						end tell
						return "Main"
					else
						-- Continue and try downloading anyway - Set deno_version to "Refused" so this is not offered again
						tell application "System Events"
							tell property list file MacYTDL_prefs_file
								set value of property list item "Deno_version" to "Refused"
							end tell
						end tell
					end if
				end if
			end considering
		end if
	end if
	
	
	-- Seventh, is the URL a YouTube channel - if so warn user it may contain a great many videos and take hours to work - but youtube-dl makes a mess of channels so, send those users back to Main
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
	
	
	-- v1.30, 17/11/25 - Convert commas, tabs, returns and line breaks into spaces => enables multiple and parallel downloads with existing code
	if URL_user_entered_clean contains tab then
		set URL_user_entered_clean to run_Utilities_handlers's replace_chars(URL_user_entered_clean, tab, " ")
		set URL_user_entered to run_Utilities_handlers's replace_chars(URL_user_entered, tab, " ")
	else if URL_user_entered_clean contains return then
		set URL_user_entered_clean to run_Utilities_handlers's replace_chars(URL_user_entered_clean, return, " ")
		set URL_user_entered to run_Utilities_handlers's replace_chars(URL_user_entered, return, " ")
	else if URL_user_entered_clean contains linefeed then
		set URL_user_entered_clean to run_Utilities_handlers's replace_chars(URL_user_entered_clean, linefeed, " ")
		set URL_user_entered to run_Utilities_handlers's replace_chars(URL_user_entered, linefeed, " ")
	else if URL_user_entered_clean contains "," then
		set URL_user_entered_clean to run_Utilities_handlers's replace_chars(URL_user_entered_clean, ",", " ")
		set URL_user_entered to run_Utilities_handlers's replace_chars(URL_user_entered, ",", " ")
	end if
	
	
	-- Eighth, use simulated YTDL/yt-dlp run to look for errors such as invalid URL which would otherwise stop MacYTDL
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
				set playlist_Name to run_Utilities_handlers's replace_chars(playlist_Name, "/", "_")
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
			set playlist_Name to run_Utilities_handlers's replace_chars(playlist_Name, "/", "_")
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
	set simulate_YTDL_output_template to run_Utilities_handlers's replace_chars(YTDL_output_template, " -o '%", " -o '%(is_live)s#%")
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
		set YTDL_simulate_log to run_Utilities_handlers's replace_chars(YTDL_simulate_log, "NA-", "") -- Removes placeholder when there is no series name - put there by output template for ABC, ITV & 7Plus
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
	-- v1.30, 13/11/25 - Trap SBS show pages which are currently not supported at all
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
	set YTDL_simulate_log to run_Utilities_handlers's replace_chars(YTDL_simulate_log, "True#", "")
	set YTDL_simulate_log to run_Utilities_handlers's replace_chars(YTDL_simulate_log, "False#", "")
	set YTDL_simulate_log to run_Utilities_handlers's replace_chars(YTDL_simulate_log, "NA#", "") -- Removes placeholder when there is no is_live returned by simulate
	
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
	
	
	-- *****************************************************************************
	-- Setting ABC and SBS show page variables here for now - might change if this handler moves to utilities
	-- *****************************************************************************	
	-- Set ABC show name and episode count variables so they exist - Initialise indicators which will show whether URL is for an ABC or SBS show page - needed for overwriting code below
	set ABC_show_name to ""
	set SBS_show_name to ""
	set ABC_show_indicator to "No"
	set SBS_show_indicator to "No"
	
	-- Is the URL from an ABC or SBS Show Page ? - If so, get the user to choose which episodes to download - Warn user if URL is an Oz commercial FTA show page
	-- v1.27.1 – Exclude users on OS X 10.10, 10.11 & 10.12 - they have an out of date version of curl that lacks updated certificates
	if URL_user_entered_clean contains "iview.abc.net.au/show/" and user_on_old_os is false then
		-- Add a "/" to end of iView URLs so that they are treated correctly both by code to follow and yt-dlp - This might change if yt-dlp changes
		if last character of URL_user_entered_clean is not "/" then
			set URL_user_entered_clean to (URL_user_entered_clean & "/")
		end if
		set branch_execution to run_Utilities_handlers's Get_ABC_Episodes(URL_user_entered, diag_Title, "theButtonOKLabel", theButtonCancelLabel, theButtonDownloadLabel, X_position, screen_height, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, theButtonReturnLabel, skip_Main_dialog, path_to_MacYTDL, screen_width)
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
		if branch_execution is "Main" then return "Main"
		--	main_dialog()
		-- ************************************************************************************************************************************************************		
		
		-- ABC_show_URLs is global and so is accessable after it is populated in Get_ABC_Episodes()
		set ABC_show_indicator to "Yes"
		set URL_user_entered to ABC_show_URLs
		-- Bang a warning if user specifies needing a format list and selects more than one ABC episode
		set AppleScript's text item delimiters to " "
		set number_ABC_SBS_episodes to number of text items in ABC_show_URLs
		set AppleScript's text item delimiters to ""
		if number_ABC_SBS_episodes is greater than 1 and DL_formats_list is true then
			set theTooManyUELsLabel to localized string "Sorry, but MacYTDL cannot list formats for more than one ABC show. Would you like to cancel the download and return to the main dialog or skip the formats list and continue to download ?" from table "MacYTDL"
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
				
			else if skip_or_return is theButtonContinueLabel then
				set DL_formats_list to false
			end if
		end if
	end if
	
	
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
	--				set branch_execution to run_Utilities_handlers's Get_SBS_Episodes(URL_user_entered, diag_Title, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, X_position, screen_height, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, theButtonReturnLabel, skip_Main_dialog, path_to_MacYTDL)
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
			set branch_execution to set_File_Names(shellPath, YTDL_simulate_log, URL_user_entered, ABC_show_name, SBS_show_name, DL_Use_YTDLP, parallel_playlist, number_of_URLs)
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
		set URL_user_entered to set_File_Names(shellPath, YTDL_simulate_log, URL_user_entered, ABC_show_name, SBS_show_name, DL_Use_YTDLP, parallel_playlist, number_of_URLs)
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
		if URL_user_entered is "Main" then return "Main"
		-- ************************************************************************************************************************************************************		
		
	end if
	--	end if
	
	-- If user asked for subtitles, get ytdl/yt-dlp to check whether they are available - if not, warn user - if available, check against format requested - convert if different
	-- v1.21.2, added URL_user_entered to variables specifically passed - fixes SBS OnDemand subtitles error - don't know why
	if subtitles_choice is true or DL_YTAutoST is true then
		set YTDL_subtitles to run_Utilities_handlers's check_subtitles_download_available(shellPath, diag_Title, subtitles_choice, URL_user_entered, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, MacYTDL_custom_icon_file, DL_Use_YTDLP, theBestLabel, URL_user_entered_clean)
		
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
	set YTDL_formats_to_download to ""
	if DL_formats_list is true and DL_batch_status is false then
		set download_filename_formats to quoted form of download_filename
		set chosen_formats_list to ""
		set formats_reported to ""
		-- Commented out as Formats library now 'used' instead of loaded - v1.30, 5/11/25
		-- Need to get path to get_formats_list script file then run get_formats_list()
		-- set path_to_Formats_Chooser to (path_to_MacYTDL & "Contents:Resources:Scripts:Formats.scpt") as alias
		-- set run_Formats_Chooser_Handler to load script path_to_Formats_Chooser
		set chosen_formats_list to run_Formats_Chooser_Handler's formats_Chooser(URL_user_entered, diag_Title, theButtonCancelLabel, theButtonDownloadLabel, X_position, screen_height, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, theButtonReturnLabel, skip_Main_dialog, path_to_MacYTDL, DL_Use_YTDLP, shellPath, download_filename_formats, YTDL_credentials, window_Position, formats_reported, is_Livestream_Flag, YTDL_Use_netrc)
		-- Parse data returned from get_formats_list to separate out the formats list in the format "nnn+nnn" or "nnn,nnn %(format_id)s" 
		set AppleScript's text item delimiters to " "
		set branch_execution to text item 1 of chosen_formats_list
		set format_id_output_template to ""
		if branch_execution is "Main" then
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			return "Main"
			--	main_dialog()
			-- ************************************************************************************************************************************************************		
			
		else if branch_execution is "Skip" then
			set YTDL_formats_to_download to ""
		else if branch_execution is "Download" then
			try
				set YTDL_formats_to_download to " --format " & text item 2 of chosen_formats_list
			end try
			if YTDL_formats_to_download contains "," then
				set format_id_output_template to text item 3 of chosen_formats_list -- Contains "%(format_id)s" if user has asked to not merge but to download and retain each format
			end if
		end if
		set AppleScript's text item delimiters to ""
		if format_id_output_template is not "" then
			set YTDL_output_template to run_Utilities_handlers's replace_chars(YTDL_output_template, ".%(ext)s", "." & format_id_output_template & ".%(ext)s")
		end if
	end if
	
	-- Set the YTDL settings into one variable - makes it easier to maintain - ensure spaces are where needed - quoted to enable passing to Monitor script
	set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_recode_remux & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_Thumbnail_Write & YTDL_Thumbnail_Embed & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & " " & YTDL_formats_to_download & " " & YTDL_Use_netrc & " ")
	
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
			set download_filename_new_plain to run_Utilities_handlers's replace_chars(download_filename_new, "_", " ")
			repeat with each_filename in (get paragraphs of download_filename_new_plain)
				set each_filename to each_filename as text
				if each_filename contains "/" then
					set offset_to_file_name to (run_Utilities_handlers's last_offset(each_filename, "/")) + 2
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
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_recode_remux & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & " " & YTDL_formats_to_download & " " & YTDL_Use_netrc & " ")
						else if overwrite_continue_choice is theABCShowExistsButtonNewnameLabel then
							set YTDL_output_template_new to run_Utilities_handlers's replace_chars(YTDL_output_template, ".%(ext)s", "-2.%(ext)s")
							set set_new_download_filename to text 1 thru -5 of download_filename_new
							set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, set_new_download_filename, set_new_download_filename & "-2")
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_recode_remux & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template_new & " " & YTDL_QT_Compat & " " & YTDL_formats_to_download & " " & YTDL_Use_netrc & " ")
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
			set download_filename_new_plain to run_Utilities_handlers's replace_chars(download_filename_new, "_", " ")
			repeat with each_filename in (get paragraphs of download_filename_new_plain)
				set each_filename to each_filename as text
				if each_filename contains "/" then
					set offset_to_file_name to (run_Utilities_handlers's last_offset(each_filename, "/")) + 2
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
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_recode_remux & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & " " & YTDL_formats_to_download & " " & YTDL_Use_netrc & " ")
						else if overwrite_continue_choice is theShowExistsButtonNewnameLabel then
							set YTDL_output_template_new to run_Utilities_handlers's replace_chars(YTDL_output_template, ".%(ext)s", "-2.%(ext)s")
							set set_new_download_filename to text 1 thru -5 of download_filename_new
							set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, set_new_download_filename, set_new_download_filename & "-2")
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_recode_remux & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template_new & " " & YTDL_QT_Compat & " " & YTDL_formats_to_download & " " & YTDL_Use_netrc & " ")
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
					set offset_to_file_name to (run_Utilities_handlers's last_offset(each_filename, "/")) + 2
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
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_recode_remux & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & " " & YTDL_formats_to_download & " " & YTDL_Use_netrc & " ")
						else if overwrite_continue_choice is theShowExistsButtonNewnameLabel then
							set YTDL_output_template_new to run_Utilities_handlers's replace_chars(YTDL_output_template, ".%(ext)s", "-2.%(ext)s")
							set set_new_download_filename to text 1 thru -5 of download_filename_new
							set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, set_new_download_filename, set_new_download_filename & "-2")
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_recode_remux & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template_new & " " & YTDL_QT_Compat & " " & YTDL_formats_to_download & " " & YTDL_Use_netrc & " ")
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
	
	-- Need to revert download_filename_new to just show_name to be passed for the Monitor and Adviser dialogs - but only for the multiple downloads !!!
	-- Added in v1.24 - don't know why I didn't notice a problem with Monitor as this was needed for years !
	-- v1.26 - Add parallel download flag to download_filename_new - Monitor does all heavy lifting to initiate parallel downloads from iView
	set download_filename_new_plain to run_Utilities_handlers's replace_chars(download_filename_new, "_", " ")
	if ABC_show_indicator is "Yes" then
		if (count of paragraphs of download_filename_new_plain) is greater than 1 then
			set download_filename_new to ABC_show_name
			if DL_Parallel is true then
				set download_filename_new to download_filename_new & "$$"
			end if
		end if
	end if
	if SBS_show_indicator is "Yes" then
		if (count of paragraphs of download_filename_new_plain) is greater than 1 then
			set download_filename_new to SBS_show_name
			if DL_Parallel is true then
				set download_filename_new to download_filename_new & "$$"
			end if
		end if
	end if
	
	-- Add the URL and file name to the batch file if requested
	-- This is done after simulate, ABC/SBS chooser and Formats Chooser
	-- Returns back to main_dialog() so, none of the following code is processed
	if DL_batch_status is true then
		if is_Livestream_Flag is "True" then
			set theURLisLiveLabel to localized string "Sorry, live streams cannot be added for batch download." from table "MacYTDL"
			display dialog theURLisLiveLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			if skip_Main_dialog is true then
				error number -128
			end if
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			return "Main"
			-- my main_dialog()
			-- ************************************************************************************************************************************************************		
			
		end if
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
		--  add_To_Batch(URL_user_entered, download_filename, download_filename_new, YTDL_remux_format)
		set branch_execution to run_Batch_Handlers's add_To_Batch(URL_user_entered, download_filename, download_filename_new, YTDL_recode_remux, MacYTDL_preferences_path, diag_Title, theButtonOKLabel, MacYTDL_custom_icon_file)
		if branch_execution is "Main" then return "Main" -- add_To_Batch always returns to Main
		-- ************************************************************************************************************************************************************		
		
		-- add_To_Batch(URL_user_entered, download_filename)  -- Changed on 10/2/23
		-- add_To_Batch(URL_user_entered, download_filename_new, YTDL_remux_format) - v1.26 - need download_filname for multiple URL cases
	end if
	
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
	
	---- Show current download settings if user has specified that in Settings
	if DL_Show_Settings is true then
		set branch_execution to run_Utilities_handlers's show_settings(YTDL_subtitles, DL_Remux_original, DL_YTDL_auto_check, DL_STEmbed, DL_audio_only, YTDL_description, DL_Limit_Rate, DL_over_writes, DL_Thumbnail_Write, DL_verbose, DL_Thumbnail_Embed, DL_Add_Metadata, DL_Use_Proxy, DL_Use_Cookies, DL_Use_Custom_Template, DL_Use_Custom_Settings, DL_Remux_format, DL_TimeStamps, DL_Use_YTDLP, DL_Parallel, DL_discard_URL, DL_Dont_Use_Parts, DL_No_Warnings, YTDL_version, folder_chosen, theButtonQuitLabel, theButtonCancelLabel, theButtonDownloadLabel, DL_Show_Settings, MacYTDL_prefs_file, MacYTDL_custom_icon_file_posix, diag_Title, YTDL_Use_netrc, DL_Remux_Recode)
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
		if branch_execution is "Main" then return "Main"
		--  main_dialog()
		-- ************************************************************************************************************************************************************		
		
		if branch_execution is "Settings" then set branch_execution to set_settings()
		if branch_execution is "Main" then return "Main" -- v1.30, 25/11/25 - User exits Settings and returns to Main instead of going to download
		if branch_execution is "Quit" then quit_MacYTDL()
	end if
	
	
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
	set ABC_show_name to ""
	set SBS_show_name to ""
	set SBS_show_URLs to ""
	set ABC_show_URLs to ""
	set number_ABC_SBS_episodes to 0
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
				quit_MacYTDL()
			end if
			set branch_execution to check_download_folder(folder_chosen, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, diag_Title, MacYTDL_custom_icon_file, skip_Main_dialog)
		end try
	end if
	-- Added next line in v1.29.3 - straps and laces approach
	set branch_execution to "Null"
	return branch_execution
	-- If user clicks "Continue" processing returns to after call to this handler and download process commences
end check_download_folder


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
	set download_date_time to run_Utilities_handlers's get_Date_Time()
	
	-- First, look for non-iView show pages (but iView non-error single downloads are included)
	-- Trim extension off download filename that is in the simulate file - not implemented as it involves lots of changes to the following code
	--set download_filename_no_ext to text 1 thru ((YTDL_simulate_log's length) - (offset of "." in (the reverse of every character of YTDL_simulate_log) as text)) of YTDL_simulate_log
	if ABC_show_name is "" and SBS_show_name is "" then -- not an ABC or SBS show page
		if number_of_URLs is 1 and parallel_playlist is false then -- Single file download or playlist to be downloaded serially
			set download_filename to YTDL_simulate_log
			if YTDL_simulate_log does not contain "WARNING:" and YTDL_simulate_log does not contain "ERROR:" then --<= A single file or playlist download non-error and non-warning (iView and non-iView)
				if num_paragraphs_log is 2 then --<= A single file download (iView and non-iView) - need to trim ".mp4<para>" from end of file (which is a single line containing one file name)
					if YTDL_simulate_log contains "/" then
						set offsetOfLastSlash to (run_Utilities_handlers's last_offset(YTDL_simulate_log, "/")) + 2
						set download_filename_only to text offsetOfLastSlash thru -2 of YTDL_simulate_log
						set download_filename_trimmed to text offsetOfLastSlash thru ((YTDL_simulate_log's length) - (offset of "." in (the reverse of every character of YTDL_simulate_log) as text)) of YTDL_simulate_log
					else
						set download_filename_only to text 1 thru -2 of YTDL_simulate_log
						set download_filename_trimmed to text 1 thru ((YTDL_simulate_log's length) - (offset of "." in (the reverse of every character of YTDL_simulate_log) as text)) of YTDL_simulate_log
					end if
					set download_filename_trimmed to run_Utilities_handlers's replace_chars(download_filename_trimmed, " ", "_")
					set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_only, " ", "_")
					set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_trimmed & "-" & download_date_time & ".txt"
				else --<= Probably a Youtube playlist - but beware as there can be playlists on other sites
					if playlist_Name is not "" then
						set download_filename_new to playlist_Name
						set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, " ", "_")
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
					set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, " ", "_")
					set download_filename_trimmed to download_filename_new
				else
					set download_filename_new to run_Utilities_handlers's replace_chars(download_filename, " ", "_")
					set download_filename_trimmed to run_Utilities_handlers's replace_chars(download_filename_trimmed, " ", "_")
				end if
				set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_trimmed & "-" & download_date_time & ".txt"
			else if YTDL_simulate_log contains "ERROR:" then --<= Single file download or playlist but simulate.txt contains ERROR (iView and non-iView) - need a generic file name for non-playlists
				if playlist_Name is not "" then
					set download_filename_new to playlist_Name
					set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, " ", "_")
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
						set download_filename_full to run_Utilities_handlers's replace_chars(download_filename_full, " ", "_")
						set download_filename_full to run_Utilities_handlers's replace_chars(download_filename_full, ":", "_-") -- Not sure whether this would make a mess of URLs
						set download_filename_full to run_Utilities_handlers's replace_chars(download_filename_full, "：", "_-")
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
					set parallel_download_filename to run_Utilities_handlers's replace_chars(parallel_download_filename, " ", "_")
					set parallel_download_filename to run_Utilities_handlers's replace_chars(parallel_download_filename, ":", "_") -- Not sure whether this would make a mess of URLs
					set parallel_download_filename to run_Utilities_handlers's replace_chars(parallel_download_filename, "：", "_")
					set parallel_download_filename to run_Utilities_handlers's replace_chars(parallel_download_filename, "//", "-")
					
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
		-- Second, look for iView show page downloads (which are all ERROR: cases)	
		if number_ABC_SBS_episodes is 0 then
			-- Look for iView single show page downloads - no episodes are shown on these pages - so, have to simulate to get file name - there is usually no separate series name available as the show is also the series
			set download_filename to last paragraph of (do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & URL_user_entered & " " & YTDL_output_template)
			set download_filename_new to run_Utilities_handlers's replace_chars(download_filename, " ", "_")
			set download_filename_trimmed to text 1 thru ((download_filename's length) - (offset of "." in (the reverse of every character of download_filename) as text)) of download_filename
			set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_trimmed & "-" & download_date_time & ".txt"
		else if number_ABC_SBS_episodes is 1 then
			-- Look for iView single episode page downloads - just one episode is shown on these pages - so, have to simulate to get file name
			set download_filename to text 1 thru -1 of (do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & URL_user_entered & " " & YTDL_output_template)
			set download_filename_new to run_Utilities_handlers's replace_chars(download_filename, " ", "_")
			-- The following line is odd as the simulate log contains lots of rubbish - don't understand how this passed testing
			--	set download_filename_trimmed to text 1 thru ((YTDL_simulate_log's length) - (offset of "." in (the reverse of every character of YTDL_simulate_log) as text)) of YTDL_simulate_log
			set download_filename_trimmed to text 1 thru ((download_filename_new's length) - (offset of "." in (the reverse of every character of download_filename_new) as text)) of download_filename_new
			set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_trimmed & "-" & download_date_time & ".txt"
		else
			-- Look for iView episode show page downloads - two or more episodes are shown on web page and so ABC_show_name is populated in Get_ABC_episodes handler
			set download_filename to text 1 thru -1 of (do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & ABC_show_URLs & " " & YTDL_output_template)
			set download_filename_new to run_Utilities_handlers's replace_chars(download_filename, " ", "_")
			set ABC_show_name_underscore to run_Utilities_handlers's replace_chars(ABC_show_name, " ", "_")
			set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & ABC_show_name_underscore & "-" & download_date_time & ".txt"
		end if
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
					set download_filename_new to run_Utilities_handlers's replace_chars(download_filename, " ", "_")
					set download_date_time to run_Utilities_handlers's get_Date_Time()
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
			set download_filename_new to run_Utilities_handlers's replace_chars(download_filename, " ", "_")
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
					set URL_user_entered to run_Utilities_handlers's replace_chars(URL_user_entered, "https://www.sbs.com.au/ondemand/watch/", "https://www.sbs.com.au/api/v3/video_smil?id=")
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
			--			set download_filename_new to run_Utilities_handlers's replace_chars(SBS_show_name, " ", "_")
			--			set download_filename to SBS_show_name
			set download_filename_new to run_Utilities_handlers's replace_chars(download_filename, " ", "_")
			set SBS_show_name_underscore to run_Utilities_handlers's replace_chars(SBS_show_name, " ", "_")
			set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & SBS_show_name_underscore & "-" & download_date_time & ".txt"
		end if
		-- *******************************************************************************************************************************************************
	end if
	
	-- Make sure there are no colons in the file name - can happen with iView and maybe others - ytdl converts colons into "_-" so, this must also
	-- 1.26 - commented out because of conflict with parallel processing code
	--	set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, ":", "_-")
	
	-- **************** Dialog to show variable values set by this handler - set up for iView URLs
	-- display dialog "num_paragraphs_log: " & num_paragraphs_log & return & return & "number_of_URLs: " & number_of_URLs & return & return & "URL_user_entered: " & URL_user_entered & return & return & "ABC_show_name: " & ABC_show_name & return & return & "number_ABC_SBS_episodes: " & number_ABC_SBS_episodes & return & return & "download_filename_new: " & download_filename_new & return & return & "YTDL_log_file: " & YTDL_log_file
	-- ***************** 
	
	-- 1.24 – Added this return statement as for some reason the value in URL_user_entered set in this handler was being ignored in download_video() for SBS Chooser workaround cases
	-- Might be able to remove this soon as SBS workaround no longer in use
	return URL_user_entered
	
end set_File_Names


---------------------------------------------------
--
-- 				Set Settings
--
---------------------------------------------------

-- Handler for showing dialog to set various MacYTDL and youtube-dl/yt-dlp settings
on set_settings()
	-- In case user accidentally deletes the prefs plist file
	tell application "System Events"
		if exists file MacYTDL_prefs_file then
			run_Utilities_handlers's read_settings(MacYTDL_prefs_file)
		else
			run_Utilities_handlers's set_preferences(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version, MacYTDL_custom_icon_file)
			set prefs_exists to true
		end if
	end tell
	set DL_format to localized string DL_format from table "MacYTDL"
	set DL_subtitles_format to localized string DL_subtitles_format from table "MacYTDL"
	set DL_Remux_format to localized string DL_Remux_format from table "MacYTDL"
	set DL_audio_codec to localized string DL_audio_codec from table "MacYTDL"
	
	-- Set variables for the settings dialog	
	set theSettingsDiagPromptLabel to localized string "Settings" from table "MacYTDL"
	set theSettingsBUttonAdminLabel to localized string "Admin" from table "MacYTDL"
	set settings_diag_prompt to theSettingsDiagPromptLabel
	set accViewWidth to 450
	set accViewInset to 0
	
	-- Set buttons and controls
	set theButtonsSaveLabel to localized string "Save Settings" from table "MacYTDL"
	set {theButtons, minWidth} to create buttons {theButtonCancelLabel, theSettingsBUttonAdminLabel, theButtonsSaveLabel} button keys {".", "<", ""} default button 3
	--if minWidth > accViewWidth then set accViewWidth to minWidth --<= Not needed as two buttons always narrower than the dialog - keep in case things change
	set {theSettingsRule, theTop} to create rule 3 rule width accViewWidth
	set theCheckBoxUseCustomSettingsLabel to localized string "Use custom settings" from table "MacYTDL"
	set {settings_theCheckbox_Use_CustomSettings, theTop, BoxCustSetLeftDist} to create checkbox theCheckBoxUseCustomSettingsLabel left inset 70 bottom (theTop + 3) max width 150 initial state DL_Use_Custom_Settings
	set theFieldCustomSettingsLabel to localized string "Custom settings" from table "MacYTDL"
	set {settings_theField_Custom_Settings, theTop} to create field DL_Custom_Settings left inset (BoxCustSetLeftDist + 70) bottom (theTop - 20) field width 200 placeholder text theFieldCustomSettingsLabel
	set theCheckBoxUseCustomTemplateLabel to localized string "Use custom template" from table "MacYTDL"
	set {settings_theCheckbox_Use_CustomTemplate, theTop, CustTempPopLeftDist} to create checkbox theCheckBoxUseCustomTemplateLabel left inset 70 bottom (theTop + 3) max width 150 initial state DL_Use_Custom_Template
	set theFieldCustomTemplateLabel to localized string "Custom file name template" from table "MacYTDL"
	set {settings_theField_Custom_Template, theTop} to create field DL_Custom_Template left inset (CustTempPopLeftDist + 70) bottom (theTop - 20) field width 200 placeholder text theFieldCustomTemplateLabel
	set {settings_theCookiesLocationPathControl, theTop} to create path control (POSIX path of DL_Cookies_Location) left inset 205 bottom (theTop + 1) control width 225 with pops up
	set theCheckboxUseCookiesLabel to localized string "Use cookies" from table "MacYTDL"
	set {settings_theCheckBox_Use_Cookies, theTop} to create checkbox theCheckboxUseCookiesLabel left inset 70 bottom (theTop - 25) max width 150 initial state DL_Use_Cookies
	set theCheckboxUseProxyLabel to localized string "Use proxy" from table "MacYTDL"
	set {settings_theCheckBox_Use_Proxy, theTop, ProxyCheckBoxWidth} to create checkbox theCheckboxUseProxyLabel left inset 70 bottom (theTop + 3) max width 100 initial state DL_Use_Proxy
	set theFieldProxyURLPlaceholderLabel to localized string "No URL set" from table "MacYTDL"
	set {settings_theField_ProxyURL, theTop} to create field DL_Proxy_URL left inset (ProxyCheckBoxWidth + 70) bottom (theTop - 20) field width 250 placeholder text theFieldProxyURLPlaceholderLabel
	set theCheckboxForceOWLabel to localized string "Force overwrites" from table "MacYTDL"
	set {settings_theCheckbox_OverWrites, theTop} to create checkbox theCheckboxForceOWLabel left inset 70 bottom (theTop + 3) max width 250 initial state DL_over_writes
	set theCheckboxGetFormatsListLabel to localized string "Get formats list" from table "MacYTDL"
	set {settings_theCheckbox_Formats, theTop} to create checkbox theCheckboxGetFormatsListLabel left inset 70 bottom (theTop + 3) max width 250 initial state DL_formats_list
	set theCheckboxKeepOriginalLabel to localized string "Keep original video and/or subtitles file" from table "MacYTDL"
	set {settings_theCheckbox_Original, theTop} to create checkbox theCheckboxKeepOriginalLabel left inset 70 bottom (theTop + 3) max width 200 initial state DL_Remux_original
	
	-- v1.30, 25/11/25 - Changed to recode/remux facility
	set theLabeledPopupRemuxFormatLabel to localized string "Format:" from table "MacYTDL"
	if DL_Use_YTDLP is "yt-dlp" then
		-- 19/4/25 - v1.29.2 - added audio container formats - no error checking to prevent incompatible codec and container combinations
		set {settings_thePopUp_RemuxFormat, settings_remuxlabel, theTop} to create labeled popup {theNoRemuxLabel, "avi", "flv", "gif", "mkv", "mov", "mp4", "webm", "aiff", "flac", "m4a", "mka", "mp3", "ogg", "wav"} left inset 250 bottom (theTop + 38) popup width 100 max width 200 label text theLabeledPopupRemuxFormatLabel popup left 70 initial choice DL_Remux_format
	else
		set {settings_thePopUp_RemuxFormat, settings_remuxlabel, theTop} to create labeled popup {theNoRemuxLabel, "mp4", "mkv", "flv", "webm", "avi", "ogg"} left inset 200 bottom (theTop + 38) popup width 100 max width 250 label text theLabeledPopupRemuxFormatLabel popup left 70 initial choice DL_Remux_format
	end if
	set theMatrixRecodeRemuxLabel to localized string "Remux/Recode" from table "MacYTDL"
	set theConvertLabel to localized string "Convert" from table "MacYTDL"
	set theNoChangeLabel to localized string "No change" from table "MacYTDL"
	set theRemuxLabel to localized string "Remux" from table "MacYTDL"
	set theRecodeLabel to localized string "Recode" from table "MacYTDL"
	set {settings_theMatrix_Recode_Remux, theMatrixLabel, theTop, theMatrixWidth} to create labeled matrix {theNoChangeLabel, theRemuxLabel, theRecodeLabel} bottom (theTop - 61) initial choice DL_Remux_Recode label text theConvertLabel matrix left 127 max width 250
	
	set theCheckboxMetadataLabel to localized string "Add metadata" from table "MacYTDL"
	set {settings_theCheckbox_Metadata, theTop} to create checkbox theCheckboxMetadataLabel left inset 70 bottom (theTop + 3) max width 250 initial state DL_Add_Metadata
	set theCheckboxEmbedThumbsLabel to localized string "Embed thumbnails" from table "MacYTDL"
	set {settings_theCheckbox_ThumbEmbed, theTop} to create checkbox theCheckboxEmbedThumbsLabel left inset 280 bottom (theTop + 1) max width 250 initial state DL_Thumbnail_Embed
	set theCheckboxWriteThumbsLabel to localized string "Write thumbnails" from table "MacYTDL"
	set {settings_theCheckbox_ThumbWrite, theTop} to create checkbox theCheckboxWriteThumbsLabel left inset 70 bottom (theTop - 18) max width 250 initial state DL_Thumbnail_Write
	set theLabeledPopupCodecLabel to localized string "Audio format:" from table "MacYTDL"
	set {settings_thePopup_AudioCodec, settingsCodecLabel, theTop} to create labeled popup {theBestLabel, "aac", "alac", "flac", "mp3", "m4a", "opus", "vorbis", "wav"} left inset 220 bottom (theTop - 2) popup width 90 max width 200 label text theLabeledPopupCodecLabel popup left 220 initial choice DL_audio_codec
	set theCheckboxAudioOnlyLabel to localized string "Audio only" from table "MacYTDL"
	set {settings_theCheckbox_AudioOnly, theTop} to create checkbox theCheckboxAudioOnlyLabel left inset 70 bottom (theTop - 21) max width 250 initial state DL_audio_only
	set settings_theCheckbox_DescriptionLabel to localized string "Download description" from table "MacYTDL"
	set {settings_theCheckbox_Description, theTop} to create checkbox settings_theCheckbox_DescriptionLabel left inset 70 bottom (theTop + 3) max width 250 initial state DL_description
	set {theSettingsAdminRule, theTop} to create rule (theTop + 1) left inset 70 rule width (accViewWidth - 70)
	set theCheckboxDLAutoSTsLabel to localized string "Auto-generated subtitles" from table "MacYTDL"
	set {settings_theCheckbox_AutoSubTitles, theTop} to create checkbox theCheckboxDLAutoSTsLabel left inset 70 bottom (theTop + 3) max width 250 initial state DL_YTAutoST
	set theCheckboxEmbedSTsLabel to localized string "Embed subtitles" from table "MacYTDL"
	set {settings_theCheckbox_STEmbed, theTop} to create checkbox theCheckboxEmbedSTsLabel left inset 70 bottom (theTop + 3) max width 250 initial state DL_STEmbed
	set theLabeledFieldSTsLangLabel to localized string "Subtitles language:" from table "MacYTDL"
	set {settings_theField_STLanguage, settings_language_label, theTop, fieldSTLangLeft} to create side labeled field DL_STLanguage left inset 70 bottom (theTop + 3) total width 200 label text theLabeledFieldSTsLangLabel field left 0
	set theCheckboxDLSTsLabel to localized string "Download subtitles" from table "MacYTDL"
	set {settings_theCheckbox_SubTitles, theTop, STCheckBoxWidth} to create checkbox theCheckboxDLSTsLabel left inset 70 bottom (theTop + 3) max width 250 initial state DL_subtitles
	set theLabeledPopUpSTsFormatLabel to localized string "Subtitles format:" from table "MacYTDL"
	set {settings_thePopUp_SubTitlesFormat, settings_STFormatlabel, theTop, popupSTFormatLeftDist} to create labeled popup {theBestLabel, "srt", "vtt", "ass", "lrc", "ttml", "dfxp", "srv3"} left inset (STCheckBoxWidth + 77) bottom (theTop - 23) popup width 65 max width 250 label text theLabeledPopUpSTsFormatLabel popup left (STCheckBoxWidth + 77) initial choice DL_subtitles_format
	set {theSettingsSTEndRule, theTop} to create rule (theTop + 1) left inset 70 rule width (accViewWidth - 70)
	set theLabeledPopUpResolutionLimitLabel to localized string "Maximum resolution:" from table "MacYTDL"
	set {settings_thePopUp_Resolution_Limit, settings_resolutionlabel, theTop, popupLeft} to create labeled popup {theBestLabel, "2560", "1920", "1080", "720", "480"} left inset 70 bottom (theTop + 3) popup width 75 max width 400 label text theLabeledPopUpResolutionLimitLabel popup left 70 initial choice DL_Resolution_Limit
	set theLabeledPopUpFileFormatLabel to localized string "File format:" from table "MacYTDL"
	set {settings_thePopUp_FileFormat, settings_formatlabel, theTop, popupLeft} to create labeled popup {theDefaultLabel, "mp4", "webm", "ogg", "3gp", "flv"} left inset 70 bottom (theTop + 3) popup width 90 max width 400 label text theLabeledPopUpFileFormatLabel popup left 70 initial choice DL_format
	--set show_DL_format to localized string DL_format from table "MacYTDL"
	--set {settings_thePopUp_FileFormat, settings_formatlabel, theTop, popupLeft} to create labeled popup {theDefaultLabel, "mp4", "webm", "ogg", "3gp", "flv"} left inset 70 bottom (theTop + 3) popup width 90 max width 400 label text theLabeledPopUpFileFormatLabel popup left 70 initial choice show_DL_format
	set theLabelPathChangeDLFolderLabel to localized string "Change download folder:" from table "MacYTDL"
	set {settings_thePathControl, settings_pathLabel, theTop} to create labeled path control (POSIX path of downloadsFolder_Path) left inset 70 bottom (theTop + 8) control width 150 label text theLabelPathChangeDLFolderLabel with pops up
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 50 view width 64 view height 64 scale image scale proportionally
	set {settings_prompt, theTop} to create label settings_diag_prompt left inset 0 bottom (theTop - 5) max width accViewWidth aligns center aligned with bold type
	set settings_allControls to {theSettingsRule, settings_theCheckbox_Use_CustomSettings, settings_theField_Custom_Settings, settings_theCheckbox_Use_CustomTemplate, settings_theField_Custom_Template, settings_theCheckBox_Use_Cookies, settings_theCookiesLocationPathControl, settings_theCheckBox_Use_Proxy, settings_theField_ProxyURL, settings_theCheckbox_Original, theMatrixLabel, settings_theMatrix_Recode_Remux, settings_thePopUp_RemuxFormat, settings_remuxlabel, settings_theCheckbox_Formats, settings_theCheckbox_Metadata, settings_theCheckbox_ThumbEmbed, settings_theCheckbox_ThumbWrite, settings_theCheckbox_AutoSubTitles, settings_thePopUp_SubTitlesFormat, settings_STFormatlabel, settings_theField_STLanguage, settings_language_label, settings_theCheckbox_STEmbed, settings_theCheckbox_SubTitles, settings_theCheckbox_AudioOnly, settings_theCheckbox_OverWrites, settings_thePopup_AudioCodec, settingsCodecLabel, settings_theCheckbox_Description, theSettingsAdminRule, settings_thePopUp_Resolution_Limit, settings_resolutionlabel, settings_thePopUp_FileFormat, settings_formatlabel, settings_thePathControl, settings_pathLabel, MacYTDL_icon, settings_prompt, theSettingsSTEndRule}
	
	-- Make sure MacYTDL is in front and show dialog - need to make dialog wider in some languages - use width returned from right most control
	if (popupSTFormatLeftDist + 50) is greater than accViewWidth then
		set calculatedAccViewWidth to (popupSTFormatLeftDist + 60)
	else
		set calculatedAccViewWidth to accViewWidth
	end if
	if (BoxCustSetLeftDist + 250) is greater than calculatedAccViewWidth then
		set calculatedAccViewWidth to (BoxCustSetLeftDist + 250)
	end if
	tell me to activate
	set {settings_button_returned, settings_button_number_returned, settings_controls_results, finalPosition} to display enhanced window diag_Title buttons theButtons acc view width calculatedAccViewWidth acc view height theTop acc view controls settings_allControls initial position window_Position
	
	-- Has user moved the MacYTDL window - if so, save new position
	if finalPosition is not equal to window_Position then
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "final_Position" to finalPosition
			end tell
		end tell
	end if
	
	if settings_button_number_returned is 3 or settings_button_number_returned is 2 then -- Save Settings and return to Main or Admin
		-- Get control results from settings dialog - numbered choice variables are not used but help ensure correct values go into prefs file
		-- set settings_choice_1 to item 1 of settings_controls_results -- <= The ruled line
		set settings_use_custom_settings_choice to item 2 of settings_controls_results -- <= Use custom settings choice
		set settings_custom_settings_choice to item 3 of settings_controls_results -- <= The custom settings to use
		set settings_use_custom_template_choice to item 4 of settings_controls_results -- <= Use custom template choice
		set settings_custom_template_choice to item 5 of settings_controls_results -- <= The custom template to use
		set settings_use_cookies_choice to item 6 of settings_controls_results -- <= Use proxy choice
		set settings_cookies_location_choice to item 7 of settings_controls_results -- <= The proxy URL
		set settings_use_proxy_choice to item 8 of settings_controls_results -- <= Use proxy choice
		set settings_proxy_URL_choice to item 9 of settings_controls_results -- <= The proxy URL
		set settings_original_choice to item 10 of settings_controls_results -- <= Keep original after remux choice
		-- set settings_choice_11 to item 11 of settings_controls_results -- <= Remux/Recode matrix label
		set settings_remux_recode_choice to item 12 of settings_controls_results -- <= Remux/Recode choice
		set settings_remux_format_choice to item 13 of settings_controls_results -- <= Remux/Recode format choice
		-- set settings_choice_14 to item 14 of settings_controls_results -- <= The Remux format popup label
		set settings_formats_list_choice to item 15 of settings_controls_results -- <= Get formats list choice
		set settings_metadata_choice to item 16 of settings_controls_results -- <= Add metadata choice
		set settings_thumb_embed_choice to item 17 of settings_controls_results -- <= Embed Thumbnails choice
		set settings_thumb_write_choice to item 18 of settings_controls_results -- <= Write Thumbnails choice
		set settings_autoST_choice to item 19 of settings_controls_results -- <= Auto-gen subtitles choice
		set settings_subtitlesformat_choice to item 20 of settings_controls_results -- <= Subtitles format choice
		-- set settings_STFormatlabel_choice to item 21 of settings_controls_results -- <= Subtitles format popup label
		set settings_subtitleslanguage_choice to item 22 of settings_controls_results -- <= Subtitles language choice
		-- set settings_subtitleslanguage_23 to item 23 of settings_controls_results -- <= Subtitles language field label
		set settings_stembed_choice to item 24 of settings_controls_results -- <= Embed subtitles choice
		set settings_subtitles_choice to item 25 of settings_controls_results -- <= Subtitles choice
		set settings_audio_only_choice to item 26 of settings_controls_results -- <= Audio only choice
		set settings_forceOW_choice to item 27 of settings_controls_results -- <= Force overwrites choice
		set settings_audio_codec_choice to item 28 of settings_controls_results -- <= Audio codec choice
		-- set settings_audiocodec_29 to item 29 of settings_controls_results -- <= Audio codec field label
		set settings_description_choice to item 30 of settings_controls_results -- <= Description choice
		-- set settings_choice_31 to item 31 of settings_controls_results -- <= The Admin rule
		set settings_resolution_choice to item 32 of settings_controls_results -- <= Maximum resolution choice
		-- set settings_choice_33 to item 33 of settings_controls_results -- <= The Format popup label
		set settings_format_choice to item 34 of settings_controls_results -- <= File format choice
		-- set settings_choice_35 to item 35 of settings_controls_results -- <= The Format popup label
		set settings_folder_choice to item 36 of settings_controls_results -- <= The download path choice
		-- set settings_choice_37 to item 37 of settings_controls_results -- <= The Path label
		-- set settings_choice_38 to item 38 of settings_controls_results -- <= The MacYTDL icon
		-- set settings_choice_39 to item 39 of settings_controls_results -- <= The Settings label
		-- set settings_choice_40 to item 40 of settings_controls_results -- <= The Subtitles end rule
		
		-- display dialog "settings_remux_recode_choice: " & settings_remux_recode_choice & return & "settings_remux_format_choice: " & settings_remux_format_choice
		
		-- Save new settings to preferences file - no error checking needed for these
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Add_Metadata" to settings_metadata_choice
				set value of property list item "Audio_Only" to settings_audio_only_choice
				set value of property list item "Audio_Codec" to settings_audio_codec_choice
				set value of property list item "Description" to settings_description_choice
				set value of property list item "FileFormat" to settings_format_choice
				set value of property list item "Keep_Remux_Original" to settings_original_choice
				set value of property list item "Over-writes allowed" to settings_forceOW_choice
				set value of property list item "Resolution_Limit" to settings_resolution_choice
				set value of property list item "SubTitles" to settings_subtitles_choice
				set value of property list item "Subtitles_Format" to settings_subtitlesformat_choice
				set value of property list item "Subtitles_Language" to settings_subtitleslanguage_choice
				set value of property list item "Subtitles_YTAuto" to settings_autoST_choice
				set value of property list item "Thumbnail_Write" to settings_thumb_write_choice
				set value of property list item "SubTitles_Embedded" to settings_stembed_choice
			end tell
		end tell
		
		-- v1.30, 25/11/25 - Check that format is specified if user wants recode or remux
		if (settings_remux_recode_choice is "Recode" or settings_remux_recode_choice is "Remux") and settings_remux_format_choice is theNoRemuxLabel then
			set theNeedFormatLabel to localized string "Sorry, you need to choose a format for a" from table "MacYTDL"
			display dialog (theNeedFormatLabel & " " & settings_remux_recode_choice) with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			set_settings()
		else
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Remux_Recode" to settings_remux_recode_choice
					set value of property list item "Remux_Format" to settings_remux_format_choice
				end tell
			end tell
		end if
		
		-- User wants a formats list - v1.26: check that Myriad Tables Lib is installed - if user switches off formats list toggle the saved setting
		-- v1.26.1 – For some reaosn, formats list and auto download now crash on Sonoma as well as Monterey, but not Ventura - decided not to block for now
		if settings_formats_list_choice is true then
			-- Commented out for v1.30, 5/11/25 as DTP is no longer installed
			--	if Myriad_exists is false then
			--		set theInstallMyriadTextLabel to localized string "MacYTDL needs a code library installed in your Libraries folder. It cannot show the \"Formats List\" without that library. Do you wish to install ?" from table "MacYTDL"
			--		set install_Myriad to button returned of (display dialog theInstallMyriadTextLabel buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			--		if install_Myriad is theButtonYesLabel then
			--			run_Utilities_handlers's install_Myriad(Myriad_file, path_to_MacYTDL, resourcesPath)
			--			set Myriad_exists to true
			--			-- Now can go ahead and set the formats list setting
			--			tell application "System Events"
			--				tell property list file MacYTDL_prefs_file
			--					set value of property list item "Get_Formats_List" to true
			--				end tell
			--			end tell
			--		end if
			-- v1.26 - Seems that formats list and auto download are compatible after all
			--			else if DL_auto is true then
			--				set theChooseListAutoTextLabel to localized string "Sorry, but the Formats List is incompatible with Automatic dowloads. Which would you prefer ?" from table "MacYTDL"
			--				set choosel_ListAuto to button returned of (display dialog theChooseListAutoTextLabel buttons {"List", "Auto", "Neither"} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			--				if choosel_ListAuto is "Neither" then
			--					tell application "System Events"
			--						tell property list file MacYTDL_prefs_file
			--							set value of property list item "Auto_Download" to false
			--							set value of property list item "Get_Formats_List" to false
			--						end tell
			--					end tell
			--				else if choosel_ListAuto is "List" then
			--					tell application "System Events"
			--						tell property list file MacYTDL_prefs_file
			--							set value of property list item "Auto_Download" to false
			--							set value of property list item "Get_Formats_List" to true
			--						end tell
			--					end tell
			--				else if choosel_ListAuto is "Auto" then
			--					tell application "System Events"
			--						tell property list file MacYTDL_prefs_file
			--							set value of property list item "Auto_Download" to true
			--							set value of property list item "Get_Formats_List" to false
			--						end tell
			--					end tell
			--				end if
			--	else
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Get_Formats_List" to true
				end tell
			end tell
		end if
		if settings_formats_list_choice is false and DL_formats_list is true then
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Get_Formats_List" to false
				end tell
			end tell
		end if
		
		-- Check proxy URL starts with a valid protocol
		if settings_proxy_URL_choice is not "" then
			set protocol_chosen to text 1 thru 5 of settings_proxy_URL_choice
			if protocol_chosen is not "http:" and protocol_chosen is not "https" and protocol_chosen is not "socks" then
				set theNeedValidProtocolLabel to localized string "Sorry, you need a valid protocol for a proxy URL (http, https or socks)." from table "MacYTDL"
				display dialog theNeedValidProtocolLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
				set_settings()
			end if
		end if
		-- Check that user has a valid proxy URL if Use Proxy is on
		if settings_use_proxy_choice is true and settings_proxy_URL_choice is "" then
			set theMustProvideProxyURLLabel to localized string "Sorry, you need a proxy URL to use a proxy for downloads." from table "MacYTDL"
			display dialog theMustProvideProxyURLLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			set_settings()
		end if
		-- Now can go ahead and set the proxy settings
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Proxy_URL" to settings_proxy_URL_choice
				set value of property list item "Use_Proxy" to settings_use_proxy_choice
			end tell
		end tell
		
		-- Check that user has supplied cookies location if use cookies is on
		set theNoCookieFileLabel to localized string "No Cookie File" from table "MacYTDL"
		if settings_use_cookies_choice is true and settings_cookies_location_choice is ("/" & theNoCookieFileLabel) then
			set theMustProvideCookiesLocationLabel to localized string "Sorry, you need to give the location of your cookies file." from table "MacYTDL"
			display dialog theMustProvideCookiesLocationLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			set_settings()
		end if
		-- Ask if user wants to blank out the cookies location
		if settings_use_cookies_choice is false and DL_Use_Cookies is true then
			set theAskBlankCookiesLocationLabel to localized string "You have turned off \"Use cookies\". Do you wish to remove the current cookies location ?" from table "MacYTDL"
			set blankCookiesLocation to button returned of (display dialog theAskBlankCookiesLocationLabel with title diag_Title buttons {theButtonNoLabel, theButtonYesLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600)
			if blankCookiesLocation is theButtonYesLabel then set settings_cookies_location_choice to ("/" & theNoCookieFileLabel)
		end if
		-- Now can go ahead and set the cookies settings
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Use_Cookies" to settings_use_cookies_choice
				set value of property list item "Cookies_Location" to settings_cookies_location_choice
			end tell
		end tell
		
		-- Check that user has supplied custom template - add .%(ext)s if necessary
		if settings_use_custom_template_choice is true and (settings_custom_template_choice is "" or settings_custom_template_choice is " ") then
			set theMustProvideCustomTemplateLabel to localized string "Sorry, you have not provided a custom file name template." from table "MacYTDL"
			display dialog theMustProvideCustomTemplateLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			set_settings()
		end if
		if settings_custom_template_choice is not equal to "" and settings_custom_template_choice does not end with ".%(ext)s" then
			set settings_custom_template_choice to settings_custom_template_choice & ".%(ext)s"
		end if
		-- Now can go ahead and set the custom output template settings
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Use_Custom_Output_Template" to settings_use_custom_template_choice
				set value of property list item "Custom_Output_Template" to settings_custom_template_choice
			end tell
		end tell
		
		-- Check that user has supplied custom settings
		if settings_use_custom_settings_choice is true and settings_custom_settings_choice is "" then
			set theMustProvideCustomSettingsLabel to localized string "Sorry, you have not provided custom settings." from table "MacYTDL"
			display dialog theMustProvideCustomSettingsLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			set_settings()
		end if
		-- Now can go ahead and set the custom settings settings
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Use_Custom_Settings" to settings_use_custom_settings_choice
				set value of property list item "Custom_Settings" to settings_custom_settings_choice
			end tell
		end tell
		
		-- User must make DL folder available - If download path is to a file, use parent folder for downloads
		set test_DL_folder to ""
		repeat until test_DL_folder is "file" or test_DL_folder is "folder" or test_DL_folder is "disk" or test_DL_folder is "«class cfol»" or test_DL_folder is "alias"
			try
				tell application "System Events" to set test_DL_folder to (get class of item (settings_folder_choice as text)) as text
			on error
				set theDownloadFolderMissingLabel to localized string "Your download folder is not available. You can make it available then click on Continue, return to set a new download folder or quit." from table "MacYTDL"
				set quit_or_return to button returned of (display dialog theDownloadFolderMissingLabel buttons {theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
				if quit_or_return is theButtonReturnLabel then
					set_settings()
				else if quit_or_return is theButtonQuitLabel then
					quit_MacYTDL()
				end if
			end try
		end repeat
		if test_DL_folder is "file" then
			-- Trim last part of path name and use parent for downloads 
			set offset_to_file_name to run_Utilities_handlers's last_offset(settings_folder_choice as text, "/")
			set settings_folder_choice to text 1 thru offset_to_file_name of settings_folder_choice
		end if
		-- Now can go ahead and set the download folder setting
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "DownloadFolder" to settings_folder_choice
			end tell
		end tell
		
		-- Can set embed thumbnail to true if user is using yt-dlp or (user is using youtube-dl, Atomic is installed and audio format is mp3 or m4a)
		if settings_thumb_embed_choice is true and ((DL_Use_YTDLP is "yt-dlp") or (DL_Use_YTDLP is "youtube-dl" and Atomic_is_installed is true and settings_audio_only_choice is true and (settings_audio_codec_choice is "mp3" or settings_audio_codec_choice is "m4a"))) then
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Thumbnail_Embed" to true
				end tell
			end tell
			-- If Atomic is not installed, cannot set embed thumbnails
		else if settings_thumb_embed_choice is true and Atomic_is_installed is false and DL_Use_YTDLP is "youtube-dl" then
			set theSTsEmbedFormatLabel to localized string "Sorry, to embed thumbnails, you need to install Atomic Parsley. You can do that in Utilities." from table "MacYTDL"
			display dialog theSTsEmbedFormatLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			set_settings()
		else if settings_thumb_embed_choice is true and DL_Use_YTDLP is "youtube-dl" and (settings_audio_only_choice is false or (settings_audio_codec_choice is not "mp3" and settings_audio_codec_choice is not "m4a")) then
			set theSTsEmbedFormatLabel to localized string "Sorry, to embed thumbnails, you need to specify audio only and use mp3 or m4a audio format." from table "MacYTDL"
			display dialog theSTsEmbedFormatLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			set_settings()
		end if
		-- User wants Embedding off - set settings and return to Main
		if settings_thumb_embed_choice is false then
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Thumbnail_Embed" to false
				end tell
			end tell
		end if
		if settings_button_number_returned is 2 then -- Go to Admin
			set branch_execution to run_Utilities_handlers's set_admin_settings(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version, MacYTDL_custom_icon_file, theButtonCancelLabel, window_Position, theButtonReturnLabel, MacYTDL_custom_icon_file_posix, theButtonOKLabel)
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
			if branch_execution is "Main" then return branch_execution
			--			if branch_execution is "Main" then main_dialog()
			-- ************************************************************************************************************************************************************
			
			if branch_execution is "Settings" then set branch_execution to set_settings()
		end if
	end if
	
	-- Trying to reduce looping of handlers
	-- return  -- This would return processing to location from where it was called which is after the main dialog
	
	-- ************************************************************************************************************************************************************
	-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
	set branch_execution to "Main"
	return branch_execution
	--	main_dialog()
	-- ************************************************************************************************************************************************************
	
	
end set_settings


---------------------------------------------------
--
-- 		Check for youtube-dl/yt-dlp updates
--
---------------------------------------------------

-- Handler to check and update yt-dlp if user wishes - called by Utilities dialog to update script and switch to yt-dlp, the auto check on startup and the Warning dialog - Not called if user has Homebrew
-- v1.24 - No longer offer to update youtube-dl
-- v1.24 – Added code to enable switch from Homebrew to MacYTDL yt-dlp install
-- v1.29 - Changed yt-dlp install for users on macOS 10.15+ to unpacked
-- v1.29.3 - No longer offer to update yt-dlp for users on 10.14 and earlier - update only to 2025.08.11
-- v1.30, 16/12/25 - Fixed typo in if test on "User cancelled"
on check_ytdl(show_yt_dlp)
	-- Get version of yt-dlp available from GitHub - which has a different name to what is used by MacYTDL - get legacy version for users on 10.9-10.15 who have old version
	set YTDL_site_URL to "https://github.com/yt-dlp/yt-dlp/releases"
	if show_yt_dlp is "yt-dlp" then
		set name_of_executable to "yt-dlp_macos"
		--	else if show_yt_dlp is "yt-dlp-legacy" then
		--		set name_of_executable to "yt-dlp_macos_legacy"
	end if
	try
		set YTDL_releases_page to do shell script "curl " & YTDL_site_URL & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
	on error errMSG
		set theYTDLCurlErrorLabel1 to localized string "There was an error with looking for the " from table "MacYTDL"
		set theYTDLCurlErrorLabel2 to localized string " web page. The error was: " from table "MacYTDL"
		set theYTDLCurlErrorLabel3 to localized string ", and the URL that produced the error was: " from table "MacYTDL"
		set theYTDLCurlErrorLabel4 to localized string "Try again later and/or send a message to macytdl@gmail.com with the details." from table "MacYTDL"
		set theYTDLCurlErrorLabel to theYTDLCurlErrorLabel1 & show_yt_dlp & theYTDLCurlErrorLabel2 & errMSG & theYTDLCurlErrorLabel3 & YTDL_site_URL & ". " & theYTDLCurlErrorLabel4
		display dialog theYTDLCurlErrorLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return "Main"
		--	main_dialog()
		-- ************************************************************************************************************************************************************
		
	end try
	
	-- The plist file normally has the correct version number of the installed YTDL_version - but, because settings are on a user basis, on multi-user Macs this can be out-of-date
	if DL_Use_YTDLP is "yt-dlp" or DL_Use_YTDLP is "yt-dlp-legacy" then
		set installedYTDL_version to do shell script ytdlp_file & " --version"
	else
		set installedYTDL_version to do shell script youtubedl_file & " --version"
	end if
	if installedYTDL_version is not YTDL_version then
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "YTDL_YTDLP_version" to installedYTDL_version
			end tell
		end tell
		set YTDL_version to installedYTDL_version -- Added on 9/6/23 - seems like a good idea
	end if
	
	set theYTDLUpToDateLabela to localized string " is up to date. Your installed version is " from table "MacYTDL"
	set theYTDLUpToDateLabel to show_yt_dlp & theYTDLUpToDateLabela
	set switch_flag to false
	if alert_text_ytdl is "Switching" then set switch_flag to true
	set alert_text_ytdl to theYTDLUpToDateLabel & installedYTDL_version
	-- Trap case in which user is offline or some other problem in reaching yt-dlp
	if YTDL_releases_page is "" then
		set theYTDLPageErrorLabel1 to localized string "There was a problem with looking for " from table "MacYTDL"
		set theYTDLPageErrorLabel2 to localized string "Perhaps you are not connected to the internet or GitHub is currently not available." from table "MacYTDL"
		set theYTDLPageErrorLabel to theYTDLPageErrorLabel1 & show_yt_dlp & ". " & theYTDLPageErrorLabel2
		display dialog theYTDLPageErrorLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return "Main"
		--	main_dialog()
		-- ************************************************************************************************************************************************************
		
	else
		set AppleScript's text item delimiters to "Latest"
		set YTDL_releases_text to text item 1 of YTDL_releases_page
		set numParas to count paragraphs in YTDL_releases_text
		set version_para to paragraph (numParas) of YTDL_releases_text
		set AppleScript's text item delimiters to " "
		set YTDL_version_check to text item 2 of version_para
		set AppleScript's text item delimiters to ""
		if YTDL_version_check is not equal to installedYTDL_version or homebrew_ytdlp_exists is true then
			if switch_flag is true then
				set YTDL_update_text to "To switch to " & show_yt_dlp & " it will need to be installed. Would you like to install it now ?"
			else
				if show_yt_dlp is "yt-dlp-legacy" then set YTDL_version_check to "2025.08.11"
				set YTDL_update_text to "A new version of " & show_yt_dlp & " is available. You have version " & installedYTDL_version & ". The latest version is " & YTDL_version_check & return & return & "Would you like to install it now ?"
			end if
			tell me to activate
			set YTDL_install_answ to button returned of (display dialog YTDL_update_text buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if YTDL_install_answ is theButtonYesLabel then
				try
					if homebrew_ytdlp_exists is true then
						do shell script "rm /usr/local/bin/yt-dlp" with administrator privileges
					end if
					-- v1.29 - Users on macOS 10.15+ get the unpacked version
					-- do shell script "curl -L " & YTDL_site_URL & "/download/" & YTDL_version_check & "/" & name_of_executable & " -o /usr/local/bin/yt-dlp" with administrator privileges
					if show_yt_dlp is "yt-dlp" then
						do shell script "curl -L https://github.com/yt-dlp/yt-dlp-nightly-builds/releases/latest/download/yt-dlp_macos.zip -o /usr/local/bin/yt-dlp_macos.zip" with administrator privileges
						-- v1.29.2 - 9/6/25 - Moved alert so it shows after user enters credentials
						set installAlertActionLabel to quoted form of "_"
						set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
						set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
						set installAlertSubtitle to quoted form of ((localized string "Download and install of " from table "MacYTDL") & show_yt_dlp)
						do shell script resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
						do shell script "unzip -o /usr/local/bin/yt-dlp_macos.zip -d /usr/local/bin/" with administrator privileges
						do shell script "mv /usr/local/bin/yt-dlp_macos /usr/local/bin/yt-dlp" with administrator privileges
						do shell script "rm /usr/local/bin/yt-dlp_macos.zip" with administrator privileges
					else if show_yt_dlp is "yt-dlp-legacy" then
						-- do shell script "curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos_legacy -o /usr/local/bin/yt-dlp" with administrator privileges -- v1.29.3 - update to final version of legacy version
						do shell script "curl -L  https://github.com/yt-dlp/yt-dlp/releases/download/2025.08.11/yt-dlp_macos_legacy  -o /usr/local/bin/yt-dlp" with administrator privileges
						set installAlertActionLabel to quoted form of "_"
						set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
						set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
						set installAlertSubtitle to quoted form of ((localized string "Download and install of " from table "MacYTDL") & show_yt_dlp)
					end if
				on error errMSG
					if errMSG does not contain "User cancelled." then
						display dialog "There was an error in downloading the yt-dlp update. The error reported was " & errMSG
					end if
					
					-- ************************************************************************************************************************************************************
					-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
					return "Main"
					--	main_dialog()
					-- ************************************************************************************************************************************************************
					
				end try
				do shell script "chmod a+x /usr/local/bin/yt-dlp" with administrator privileges
				if show_yt_dlp is "yt-dlp" or show_yt_dlp is "yt-dlp-legacy" then
					set ytdlp_exists to true
				else
					set YTDL_exists to true
				end if
				set YTDL_version to YTDL_version_check
				tell application "System Events"
					tell property list file MacYTDL_prefs_file
						set value of property list item "YTDL_YTDLP_version" to YTDL_version
					end tell
				end tell
				set theYTDLUpDatedLabel to localized string " has been updated. Your new version is " from table "MacYTDL"
				set alert_text_ytdl to show_yt_dlp & theYTDLUpDatedLabel & YTDL_version
			else
				set theYTDLOutOfDateLabel to localized string " installed has not been changed. Your installed version is " from table "MacYTDL"
				set alert_text_ytdl to show_yt_dlp & theYTDLOutOfDateLabel & YTDL_version
			end if
		end if
	end if
end check_ytdl


---------------------------------------------------
--
-- 		Perform various utilities
--
---------------------------------------------------

-- Handler for MacYTDL utility operations called by the Utilities button on Main dialog
on utilities()
	
	run_Utilities_handlers's read_settings(MacYTDL_prefs_file)
	set DL_format to localized string DL_format from table "MacYTDL"
	set DL_subtitles_format to localized string DL_subtitles_format from table "MacYTDL"
	set DL_Remux_format to localized string DL_Remux_format from table "MacYTDL"
	set DL_audio_codec to localized string DL_audio_codec from table "MacYTDL"
	
	-- Test for Service and Atomic installs
	set isServiceInstalled to "Yes"
	set path_to_home_folder to (path to home folder)
	set services_Folder_nonPosix to (path_to_home_folder & "Library:Services:") as text
	set macYTDL_service_file_nonPosix to services_Folder_nonPosix & "Send-URL-To-MacYTDL.workflow"
	set services_Folder to (POSIX path of (path to home folder) & "/Library/Services/")
	set macYTDL_service_file to services_Folder & "Send-URL-To-MacYTDL.workflow"
	tell application "System Events"
		if not (exists the file macYTDL_service_file) then
			set isServiceInstalled to "No"
		end if
	end tell
	
	-- This should not be needed as it's always done during startup - commented out in v1.30, 1/11/25
	--	set macYTDL_Atomic_file to ("usr:local:bin:AtomicParsley" as text)
	--	tell application "System Events"
	--		if (exists file macYTDL_Atomic_file) then
	--			set Atomic_is_installed to true
	--		else
	--			set Atomic_is_installed to false
	--		end if
	--	end tell
	
	-- Set youtube-dl/yt-dlp and FFmpeg version installed text - to show in Utilities dialog - use number of items to set nightly/stable build flag
	set AppleScript's text item delimiters to "."
	set version_Kind_Check to count of text items in YTDL_version
	set AppleScript's text item delimiters to ""
	set ytdlp_kind to "stable"
	if version_Kind_Check is 4 then set ytdlp_kind to "nightly"
	set theVersionInstalledLabel to localized string "Installed:" from table "MacYTDL"
	set theYTDLVersionInstalledlabel to theVersionInstalledLabel & " v" & YTDL_version
	set FFMpeg_version_installed to theVersionInstalledLabel & " v" & ffmpeg_version
	set theCurrentInstalledLabel to localized string "Current:" from table "MacYTDL"
	set current_settings_installed to "(" & theCurrentInstalledLabel & " " & DL_Settings_In_Use & ")"
	
	-- Set variables for the Utilities dialog
	set theInstructionsTextLabel to localized string "Choose the utility(ies) you would like to run then click 'Start'" from table "MacYTDL"
	set instructions_text to theInstructionsTextLabel
	set theDiagPromptLabel to localized string "Utilities" from table "MacYTDL"
	set utilities_diag_prompt to theDiagPromptLabel
	set accViewWidth to 450
	set accViewInset to 75
	
	-- Set buttons and controls
	set theButtonsDeleteLogsLabel to localized string "Delete logs" from table "MacYTDL"
	set theButtonsUninstallLabel to localized string "Uninstall" from table "MacYTDL"
	set theButtonsAboutLabel to localized string "About MacYTDL" from table "MacYTDL"
	set theButtonsStartLabel to localized string "Start" from table "MacYTDL"
	set {theButtons, minWidth} to create buttons {theButtonsDeleteLogsLabel, theButtonsUninstallLabel, theButtonsAboutLabel, theButtonCancelLabel, theButtonsStartLabel} button keys {"d", "U", "a", ".", ""} default button 5
	-- Make sure dialog is wide enough to show buttons
	if minWidth > accViewWidth then set accViewWidth to minWidth
	set {theUtilitiesRule, theTop} to create rule 10 rule width accViewWidth
	-- Set up alternatives for Service and AtomicParsley
	if isServiceInstalled is "Yes" then
		set theCheckBoxRemoveServiceLabel to localized string "Remove Service" from table "MacYTDL"
		set {utilities_theCheckbox_Service_Install, theTop} to create checkbox theCheckBoxRemoveServiceLabel left inset accViewInset bottom (theTop + 5) max width 250
	else
		set theCheckBoxInstallServiceLabel to localized string "Install Service" from table "MacYTDL"
		set {utilities_theCheckbox_Service_Install, theTop} to create checkbox theCheckBoxInstallServiceLabel left inset accViewInset bottom (theTop + 5) max width 250
	end if
	if Atomic_is_installed is true then
		set theCheckBoxRemoveAtomicLabel to localized string "Remove Atomic Parsley" from table "MacYTDL"
		set {utilities_theCheckbox_Atomic_Install, theTop} to create checkbox theCheckBoxRemoveAtomicLabel left inset accViewInset bottom (theTop + 5) max width 250
	else
		set theCheckBoxInstallAtomicLabel to localized string "Install Atomic Parsley" from table "MacYTDL"
		set {utilities_theCheckbox_Atomic_Install, theTop} to create checkbox theCheckBoxInstallAtomicLabel left inset accViewInset bottom (theTop + 5) max width 250
	end if
	
	-- Added in v1.30, 1/11/25 & 16/12/25, part of iomplementation of Deno - needed if yt-dlp is more recent than 2025.10.22 - only way for Refusniks to install Deno
	if deno_version is "Not installed" or deno_version is "Refused" then
		considering numeric strings
			if YTDL_version is greater than "2025.10.22" then
				set theCheckBoxDenoLabel to localized string "Install Deno"
				set {utilities_theCheckbox_Deno, theTop} to create checkbox theCheckBoxDenoLabel left inset accViewInset bottom (theTop + 5) max width 250
			else
				set {utilities_theCheckbox_Deno, theTop} to create label "" left inset accViewInset + 5 bottom (theTop - 17) max width minWidth - 100 aligns right aligned
			end if
		end considering
	else
		set theCheckBoxDenoLabel to (localized string "Check for Deno update") & "     (" & (localized string "Installed: " & deno_version) & ")"
		set {utilities_theCheckbox_Deno, theTop} to create checkbox theCheckBoxDenoLabel left inset accViewInset bottom (theTop + 5) max width 250
	end if
	
	--	set AppleScript's text item delimiters to {"-", " "}
	-- set ffmpeg_version_arch to text item 4 of ffmpeg_version_long                  -- v1.27 - 26/5/24 - Version text provided by Martin Rieldl is different
	--	set AppleScript's text item delimiters to ""
	set switch_FFmpeg to "No"
	-- v1.22 - show FFmpeg arch switcher if user on Apple Silicon                   -- v1.27 - 26/5/24 - Version text provided by Martin Rieldl is different
	set installed_FFmpeg_arch to "ARM"
	--	if ffmpeg_version_arch is "tessus" then                   -- v1.27 - 26/5/24 - Version text provided by Martin Rieldl is different
	if ffmpeg_version_long contains "ffmpeg_amd64" then
		set installed_FFmpeg_arch to "Intel"
		set new_FFmpeg_arch to "ARM"
	else
		set new_FFmpeg_arch to "Intel"
	end if
	
	-- v1.24 - disable FFmpeg items if Homebrew installs are in place
	if user_system_arch is "arm64" and homebrew_ffmpeg_exists is false then
		set theCheckBoxSwitchFFmpegLabel2 to localized string "Switch FFmpeg to" from table "MacYTDL"
		set theCheckBoxSwitchFFmpegLabel to theCheckBoxSwitchFFmpegLabel2 & " " & new_FFmpeg_arch
		set {utilities_theCheckbox_SwitchFFmpeg, theTop} to create checkbox theCheckBoxSwitchFFmpegLabel left inset accViewInset bottom (theTop + 5) max width 200
	else
		set {utilities_theCheckbox_SwitchFFmpeg, theTop} to create label "" left inset accViewInset + 5 bottom (theTop - 17) max width minWidth - 100 aligns right aligned
	end if
	-- v1.27.1 - Hide FFmpeg update facility for users on OS X 10.10, 10.11 & 10.12 - they cannot use FFmpeg more recent than v6.0 (28/2/23), which is now installed by default
	if homebrew_ffmpeg_exists is false and user_on_old_os is false then
		set theCheckBoxCheckFFmpegLabel to localized string "Check for FFmpeg update" from table "MacYTDL"
		set theCheckBoxCheckFFmpegversion to theCheckBoxCheckFFmpegLabel & "   " & "(" & FFMpeg_version_installed & ")"
		set {utilities_theCheckbox_FFmpeg_Check, theTop} to create checkbox theCheckBoxCheckFFmpegversion left inset accViewInset bottom (theTop + 5) max width 250
	else
		if homebrew_ytdlp_exists is true then
			set {utilities_theCheckbox_FFmpeg_Check, theTop} to create label "Found Homebrew/MacPorts install of FFmpeg" left inset accViewInset + 5 bottom (theTop + 5) max width minWidth - 100 aligns left aligned
		else
			set {utilities_theCheckbox_FFmpeg_Check, theTop} to create label "" left inset accViewInset + 5 bottom (theTop - 17) max width minWidth - 100 aligns left aligned
		end if
	end if
	set theCheckBoxCheckMacYTDLLabel to localized string "Check for MacYTDL update" from table "MacYTDL"
	set {utilities_theCheckbox_MacYTDL_Check, theTop} to create checkbox theCheckBoxCheckMacYTDLLabel left inset accViewInset bottom (theTop + 5) max width 250
	set theCheckBoxReturnDefaultsLabel to localized string "Return to default settings" from table "MacYTDL"
	set {utilities_theCheckbox_Return_Defaults, theTop} to create checkbox theCheckBoxReturnDefaultsLabel left inset accViewInset bottom (theTop + 5) max width 250
	set theCheckBoxRestoreSettingsLabel to localized string "Restore settings" from table "MacYTDL"
	set {utilities_theCheckbox_Restore_Settings, theTop} to create checkbox theCheckBoxRestoreSettingsLabel & "  " & current_settings_installed left inset accViewInset bottom (theTop + 5) max width 200
	set theCheckBoxSaveSettingsLabel to localized string "Save current settings" from table "MacYTDL"
	set {utilities_theCheckbox_Save_Settings, theTop} to create checkbox theCheckBoxSaveSettingsLabel left inset accViewInset bottom (theTop + 5) max width 250
	
	-- v1.24 - Show yt-dlp switcher if user currently using youtube-dl
	if DL_Use_YTDLP is "youtube-dl" then
		set theCheckBoxSwitchScriptsLabel to localized string "Switch to yt-dlp" from table "MacYTDL"
		set {utilities_theCheckbox_Switch_Scripts, theTop} to create checkbox theCheckBoxSwitchScriptsLabel left inset accViewInset bottom (theTop + 5) max width 250
		set utilities_DL_Use_YTDLP to "youtube-dl"
	else
		set {utilities_theCheckbox_Switch_Scripts, theTop} to create label "" left inset accViewInset + 5 bottom (theTop - 17) max width minWidth - 100 aligns right aligned
		set utilities_DL_Use_YTDLP to "yt-dlp"
	end if
	
	-- Spanish, and I guess other languages, prefer different word order to English so, the old form was poor - anyway, youtube-dl is mostly dead
	--	set theCheckBoxOpenYTDLLabel to (localized string "Open" from table "MacYTDL") & " " & utilities_DL_Use_YTDLP & " " & (localized string "web page" from table "MacYTDL")
	set theCheckBoxOpenYTDLLabel to (localized string "Open yt-dlp web page" from table "MacYTDL")
	set {utilities_theCheckbox_YTDL_release, theTop} to create checkbox theCheckBoxOpenYTDLLabel left inset accViewInset bottom (theTop + 5) max width 200
	
	-- v1.24 - Hide yt-dlp updater if user currently using Homebrew or youtube-dl
	-- v1.25 - Provide for yt-dlp nightly builds
	-- v1.28 - Flag that Homebrew/Macports install of yt-dlp/FFmpeg has been found
	-- v1.29.3 - No longer offer to update yt-dlp-legacy if they have latest legacy version 2025.08.11
	--	if ytdlp_exists is true and (DL_Use_YTDLP is "yt-dlp" or DL_Use_YTDLP is "yt-dlp-legacy") then
	if ytdlp_exists is true and DL_Use_YTDLP is "yt-dlp" then
		set theCheckBoxDoNotUpdateYTDLLabel to localized string "Do not update" from table "MacYTDL"
		set theCheckBoxDoNotUpdateYTDLTextLabel to localized string "Update" from table "MacYTDL"
		if ytdlp_kind is "stable" then
			set theCheckBoxCheckYTDLNightlyLabel to (localized string "Install" from table "MacYTDL") & " " & (localized string "nightly build" from table "MacYTDL")
			set theCheckBoxCheckYTDLNightlyVersion to theCheckBoxCheckYTDLNightlyLabel
			set theCheckBoxCheckYTDLLabel to theCheckBoxDoNotUpdateYTDLTextLabel & " " & (localized string "stable build" from table "MacYTDL")
			set theCheckBoxCheckYTDLversion to theCheckBoxCheckYTDLLabel & " " & "(" & theYTDLVersionInstalledlabel & ")"
			set minWidth to 465
		end if
		if ytdlp_kind is "nightly" then
			set theCheckBoxCheckYTDLNightlyLabel to theCheckBoxDoNotUpdateYTDLTextLabel & " " & (localized string "nightly build" from table "MacYTDL")
			set theCheckBoxCheckYTDLNightlyVersion to theCheckBoxCheckYTDLNightlyLabel & " " & "(" & theYTDLVersionInstalledlabel & ")"
			set theCheckBoxCheckYTDLLabel to (localized string "Install" from table "MacYTDL") & " " & (localized string "stable build" from table "MacYTDL")
			set theCheckBoxCheckYTDLversion to theCheckBoxCheckYTDLLabel
			set minWidth to 500
		end if
		set {utilities_theMatrix_YTDL_Check, theMatrixLabel, theTop, theMatrixWidth} to create labeled matrix {theCheckBoxDoNotUpdateYTDLLabel, theCheckBoxCheckYTDLversion, theCheckBoxCheckYTDLNightlyVersion} initial choice 1 bottom (theTop + 5) label text "yt-dlp" matrix left 100 max width 700
	else if ytdlp_exists is true and DL_Use_YTDLP is "yt-dlp-legacy" and YTDL_version is not "2025.08.11" then
		-- User on old version of yt-dlp_legacy - offer to update - can only update to final stable version
		set minWidth to 465
		-- Need to assign utilities_theMatrix_YTDL_Check as a checkbox for users on macOS 10.14 and earlier
		set {theMatrixLabel, theTop} to create label "" left inset accViewInset bottom (theTop - 17) max width minWidth - 100 aligns left aligned
		set theCheckBoxUpdateYTDLTextLabel to "Update yt-dlp" & " " & "(" & theYTDLVersionInstalledlabel & ")"
		set {utilities_theMatrix_YTDL_Check, theTop} to create checkbox theCheckBoxUpdateYTDLTextLabel left inset accViewInset bottom (theTop + 5) max width 200
	else
		if homebrew_ytdlp_exists is true then
			set {theMatrixLabel, theTop} to create label "Found Homebrew/MacPorts install of yt-dlp" left inset accViewInset + 5 bottom (theTop + 5) max width minWidth - 100 aligns left aligned with multiline
		else
			set {theMatrixLabel, theTop} to create label "" left inset accViewInset + 5 bottom (theTop - 17) max width minWidth - 100 aligns left aligned with multiline
		end if
		set {utilities_theCheckbox_YTDL_Check, theTop} to create label "" left inset accViewInset + 5 bottom (theTop - 17) max width minWidth - 100 aligns left aligned with multiline
		set {utilities_theMatrix_YTDL_Check, theTop} to create label "" left inset accViewInset + 5 bottom (theTop - 17) max width minWidth - 100 aligns left aligned with multiline
	end if
	set theCheckBoxOpenDLFolderLabel to localized string "Open download folder" from table "MacYTDL"
	set {utilities_theCheckbox_DL_Open, theTop} to create checkbox theCheckBoxOpenDLFolderLabel left inset accViewInset bottom (theTop + 5) max width 250
	set theCheckBoxOpenLogFolderLabel to localized string "Open log folder" from table "MacYTDL"
	set {utilities_theCheckbox_Logs_Open, theTop} to create checkbox theCheckBoxOpenLogFolderLabel left inset accViewInset bottom (theTop + 5) max width 250
	set {utilities_instruct, theTop} to create label instructions_text left inset accViewInset + 5 bottom (theTop + 10) max width minWidth - 100 aligns left aligned with multiline
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 50 view width 64 view height 64 scale image scale proportionally
	set {utilities_prompt, theTop} to create label utilities_diag_prompt left inset 0 bottom (theTop) max width minWidth aligns center aligned with bold type
	set utilities_allControls to {theUtilitiesRule, utilities_theCheckbox_Service_Install, utilities_theCheckbox_Atomic_Install, utilities_theCheckbox_Deno, utilities_theCheckbox_SwitchFFmpeg, utilities_theCheckbox_FFmpeg_Check, utilities_theCheckbox_MacYTDL_Check, utilities_theCheckbox_Return_Defaults, utilities_theCheckbox_Restore_Settings, utilities_theCheckbox_Save_Settings, utilities_theCheckbox_Switch_Scripts, utilities_theCheckbox_YTDL_release, theMatrixLabel, utilities_theMatrix_YTDL_Check, utilities_theCheckbox_DL_Open, utilities_theCheckbox_Logs_Open, MacYTDL_icon, utilities_instruct, utilities_prompt}
	
	-- Make sure MacYTDL is in front and show dialog with correct width
	tell me to activate
	set {utilities_button_returned, utilities_button_number_returned, utilities_controls_results, finalPosition} to display enhanced window diag_Title buttons theButtons acc view width accViewWidth acc view height theTop acc view controls utilities_allControls initial position window_Position
	
	-- Has user moved the Utilities window - if so, save new position
	if finalPosition is not equal to window_Position then
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "final_Position" to finalPosition
			end tell
		end tell
	end if
	
	if utilities_button_number_returned is 5 then -- Start
		-- Get control results from utilities dialog - numbered choice variables are not used but help ensure correct utilities are run
		-- set utilities_choice_1 to item 1 of utilities_controls_results -- <= Missing value [the rule]
		set utilities_Service_choice to item 2 of utilities_controls_results -- <= Install Service choice
		set utilities_Atomic_choice to item 3 of utilities_controls_results -- <= Install Atomic Parsley choice
		set utilities_Deno_choice to item 4 of utilities_controls_results -- <= Install/Update Deno choice
		set utilities_FFmpeg_switch_choice to item 5 of utilities_controls_results -- <= Switch FFmpeg architecture
		set utilities_FFmpeg_check_choice to item 6 of utilities_controls_results -- <= Check FFmpeg version choice
		set utilities_MacYTDL_check_choice to item 7 of utilities_controls_results -- <= Check MacYTDL version choice
		set utilities_Return_Defaults_choice to item 8 of utilities_controls_results -- <= Return to default settings choice
		set utilities_Restore_Settings_choice to item 9 of utilities_controls_results -- <= Restore saved settings choice
		set utilities_Save_Settings_choice to item 10 of utilities_controls_results -- <= Save current settings choice
		set utilities_Switch_choice to item 11 of utilities_controls_results -- <= Switch downloaders choice
		set utilities_YTDL_webpage_choice to item 12 of utilities_controls_results -- <= Show YTDL/yt-dlp web page choice
		--set utilities_choice_13 to item 13 of utilities_controls_results -- <= Contains matrix label text
		set utilities_YTDL_check_choice to item 14 of utilities_controls_results -- <= Check/Install yt-dlp stable/nightly build		
		set utilities_DL_folder_choice to item 15 of utilities_controls_results -- <= Open download folder choice
		set utilities_log_folder_choice to item 16 of utilities_controls_results -- <= Open log folder choice
		--set utilities_choice_17 to item 17 of utilities_controls_results -- <= Missing value [the icon]
		--set utilities_choice_18 to item 18 of utilities_controls_results -- <= Contains the "Instructions" text
		--set utilities_choice_19 to item 19 of utilities_controls_results -- <= Contains the "Utilities" heading
		
		-- Open log folder
		if utilities_log_folder_choice is true then
			-- Open the log folder in a Finder window - main dialog will re-appear
			tell application "Finder"
				activate
				open (MacYTDL_preferences_path as POSIX file)
				set the position of the front Finder window to {200, 200}
			end tell
		end if
		
		-- Open downloads folder - make sure it's available
		if utilities_DL_folder_choice is true then
			-- Tell utilities handler that it should return to main_dialog when finished - auto_download tells utilities to skip main and just close	
			set skip_Main_dialog to false
			check_download_folder(downloadsFolder_Path, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, diag_Title, MacYTDL_custom_icon_file, skip_Main_dialog)
			-- Open the downloads folder in a Finder window positioned away from the MacYTDL main dialog which will re-appear - Assistive Access not needed as Finder windows have position properties
			tell application "Finder"
				activate
				open (downloadsFolder_Path as POSIX file) -- <= Had to read prefs again to get this working - something to do with this path in Main Dialog
				set the position of the front Finder window to {100, 100} -- <= This DOES work but is ugly - it opens the window then moves it to a location which should not overlap Main Dialog
			end tell
		end if
		
		-- Do selected combination of yt-dlp and FFmpeg version checks - Provide for each possible combination of choices
		-- Need to show the version checked dialog before returning to Main dialog
		-- v1.25 - This section redesigned to handle installation/update of yt-dlp nightly builds
		-- v1.29 - Install unpacked yt-dlp for users on 10.15+
		if (utilities_YTDL_check_choice contains "build" or utilities_YTDL_check_choice is true) and utilities_FFmpeg_check_choice is true then
			set alert_text_ytdl to "NotSwitching"
			if utilities_YTDL_check_choice contains "stable" or utilities_YTDL_check_choice is true then
				
				-- ************************************************************************************************************************************************************
				-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
				-- check_ytdl(DL_Use_YTDLP)
				set branch_execution to check_ytdl(DL_Use_YTDLP)
				if branch_execution is "Main" then return
				-- ************************************************************************************************************************************************************
				
			else if utilities_YTDL_check_choice contains "nightly" then
				-- Install nightly build - no need to check version as nightly builds are released almost every 24 hours
				try
					--	do shell script shellPath & " yt-dlp --update-to nightly" with administrator privileges
					if show_yt_dlp is "yt-dlp" then
						do shell script "curl -L https://github.com/yt-dlp/yt-dlp-nightly-builds/releases/latest/download/yt-dlp_macos.zip -o  /usr/local/bin/yt-dlp_macos.zip" with administrator privileges
						-- v1.29.2 - 9/6/25 - Moved the alert so it overlaps more with admin credentials dialog
						set installAlertActionLabel to quoted form of "_"
						set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
						set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
						set installAlertSubtitle to quoted form of ((localized string "Download and update of " from table "MacYTDL") & show_yt_dlp)
						do shell script resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
						do shell script "unzip -o /usr/local/bin/yt-dlp_macos.zip -d /usr/local/bin/" with administrator privileges
						do shell script "mv /usr/local/bin/yt-dlp_macos /usr/local/bin/yt-dlp" with administrator privileges
						do shell script "rm /usr/local/bin/yt-dlp_macos.zip" with administrator privileges
					else if show_yt_dlp is "yt-dlp-legacy" and YTDL_version is not "2025.08.11" then
						-- 1.29.2 - 10/3/25 - Simplified curl - no need really to put source file path into a variable
						--	set download_URL to "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos_legacy"
						--	do shell script "curl -L " & download_URL & " -o /usr/local/bin/yt-dlp" with administrator privileges
						-- 1.29.3 - update to final legacy version published
						do shell script "curl -L https://github.com/yt-dlp/yt-dlp/releases/download/2025.08.11/yt-dlp_macos_legacy -o /usr/local/bin/yt-dlp" with administrator privileges
						do shell script "chmod a+x /usr/local/bin/yt-dlp" with administrator privileges
					end if
					-- trap case where user cancels credentials dialog
				on error number -128
					
					-- ************************************************************************************************************************************************************
					-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
					return
					--	main_dialog()
					-- ************************************************************************************************************************************************************
					
				end try
				--  v1.30, 14/11/25 - Now getting yt-dlp version from release web page - seems faster
				--	set YTDL_version to do shell script "/usr/local/bin/yt-dlp --version"
				set YTDL_site_URL to "https://github.com/yt-dlp/yt-dlp-nightly-builds/releases"
				set YTDL_releases_page to do shell script "curl " & YTDL_site_URL & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
				set AppleScript's text item delimiters to "Latest"
				set YTDL_releases_text to text item 1 of YTDL_releases_page
				set numParas to count paragraphs in YTDL_releases_text
				set version_para to paragraph (numParas) of YTDL_releases_text
				set AppleScript's text item delimiters to " "
				set YTDL_version to text item 3 of version_para
				set AppleScript's text item delimiters to ""
				tell application "System Events"
					tell property list file MacYTDL_prefs_file
						set value of property list item "YTDL_YTDLP_version" to YTDL_version
					end tell
				end tell
				set theYTDLUpDatedLabel to localized string "has been updated to the most recent nightly build. Your new version is " from table "MacYTDL"
				set alert_text_ytdl to "yt-dlp " & theYTDLUpDatedLabel & YTDL_version
			end if
			if ffmpeg_version is "Not installed" then
				run_Utilities_handlers's install_ffmpeg_ffprobe(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os, user_system_arch, user_on_mid_os)
				set theFFmpegProbeInstalledAlertLabel to localized string "FFmpeg and FFprobe have been installed." from table "MacYTDL"
				set alert_text_ffmpeg to theFFmpegProbeInstalledAlertLabel
			else
				
				-- ************************************************************************************************************************************************************
				-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
				--  check_ffmpeg()
				set alert_text_ffmpeg to run_Utilities_handlers's check_ffmpeg(user_system_arch, show_yt_dlp, ffmpeg_file, ffprobe_file, theButtonOKLabel, diag_Title, MacYTDL_custom_icon_file, theButtonNoLabel, theButtonYesLabel, usr_bin_folder, resourcesPath, user_on_old_os, path_to_MacYTDL)
				if alert_text_ffmpeg is "Main" then return
				-- ************************************************************************************************************************************************************
				
			end if
			tell me to activate
			display dialog alert_text_ytdl & return & alert_text_ffmpeg with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		else if utilities_FFmpeg_check_choice is true and utilities_YTDL_check_choice contains "Do not update" then
			if ffmpeg_version is "Not installed" then
				run_Utilities_handlers's install_ffmpeg_ffprobe(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os, user_system_arch, user_on_mid_os)
				set theFFmpegProbeInstalledAlertLabel to localized string "FFmpeg and FFprobe have been installed." from table "MacYTDL"
				set alert_text_ffmpeg to theFFmpegProbeInstalledAlertLabel
			else
				
				-- ************************************************************************************************************************************************************
				-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
				--  check_ffmpeg()
				set alert_text_ffmpeg to run_Utilities_handlers's check_ffmpeg(user_system_arch, show_yt_dlp, ffmpeg_file, ffprobe_file, theButtonOKLabel, diag_Title, MacYTDL_custom_icon_file, theButtonNoLabel, theButtonYesLabel, usr_bin_folder, resourcesPath, user_on_old_os, path_to_MacYTDL)
				if alert_text_ffmpeg is "Main" then return
				-- ************************************************************************************************************************************************************
				
			end if
			tell me to activate
			display dialog alert_text_ffmpeg & return & return with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			-- else if (utilities_YTDL_check_choice contains "Update yt-dlp stable" and utilities_FFmpeg_check_choice is not true then
		else if (utilities_YTDL_check_choice contains "build" or utilities_YTDL_check_choice is true) and utilities_FFmpeg_check_choice is not true then
			set alert_text_ytdl to "NotSwitching"
			if utilities_YTDL_check_choice contains "stable" or utilities_YTDL_check_choice is true then
				
				-- ************************************************************************************************************************************************************
				-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
				-- check_ytdl(DL_Use_YTDLP)
				set branch_execution to check_ytdl(DL_Use_YTDLP)
				if branch_execution is "Main" then return
				-- ************************************************************************************************************************************************************
				
			else if utilities_YTDL_check_choice contains "nightly" then
				-- Install nightly build
				-- v1.29 - Install unpacked yt-dlp for users on 10.15+
				set installAlertActionLabel to quoted form of "_"
				set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
				set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
				set installAlertSubtitle to quoted form of ((localized string "Download and update of " from table "MacYTDL") & show_yt_dlp)
				do shell script resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
				try
					--	do shell script shellPath & " yt-dlp --update-to nightly" with administrator privileges -- Switched to using unpacked yt-dlp
					-- v1.29.3 - No longer update legacy with nightly version - no longer available
					if show_yt_dlp is "yt-dlp" then
						do shell script "curl -L https://github.com/yt-dlp/yt-dlp-nightly-builds/releases/latest/download/yt-dlp_macos.zip -o  /usr/local/bin/yt-dlp_macos.zip" with administrator privileges
						do shell script "unzip -o /usr/local/bin/yt-dlp_macos.zip -d /usr/local/bin/" with administrator privileges
						do shell script "mv /usr/local/bin/yt-dlp_macos /usr/local/bin/yt-dlp" with administrator privileges
						do shell script "rm /usr/local/bin/yt-dlp_macos.zip" with administrator privileges
						do shell script "chmod a+x /usr/local/bin/yt-dlp" with administrator privileges
					end if
					-- trap case where user cancels credentials dialog
				on error number -128
					
					-- ************************************************************************************************************************************************************
					-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
					return
					--	main_dialog()
					-- ************************************************************************************************************************************************************
					
				end try
				-- v1.30, 14/11/25 - Now getting yt-dlp version from release web page - seems faster
				--	set YTDL_version to do shell script "/usr/local/bin/yt-dlp --version"
				set YTDL_site_URL to "https://github.com/yt-dlp/yt-dlp-nightly-builds/releases"
				set YTDL_releases_page to do shell script "curl " & YTDL_site_URL & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
				set AppleScript's text item delimiters to "Latest"
				set YTDL_releases_text to text item 1 of YTDL_releases_page
				set numParas to count paragraphs in YTDL_releases_text
				set version_para to paragraph (numParas) of YTDL_releases_text
				set AppleScript's text item delimiters to " "
				set YTDL_version to text item 3 of version_para
				set AppleScript's text item delimiters to ""
				tell application "System Events"
					tell property list file MacYTDL_prefs_file
						set value of property list item "YTDL_YTDLP_version" to YTDL_version
					end tell
				end tell
				set theYTDLUpDatedLabel to localized string "has been updated to the most recent nightly build. Your new version is " from table "MacYTDL"
				set alert_text_ytdl to "yt-dlp " & theYTDLUpDatedLabel & YTDL_version
			end if
			tell me to activate
			display dialog alert_text_ytdl & return with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		end if
		
		-- Added in v1.22
		-- Switch FFmpeg architecture
		if utilities_FFmpeg_switch_choice is true then
			set theFFmpegSwitchLabel to localized string "Switch FFmpeg and FFprobe from" from table "MacYTDL"
			set theFFmpegToLabel to localized string " to " from table "MacYTDL"
			-- set theFFmpegSwitchLabel to localized string "Switch FFmpeg and FFprobe from " & installed_FFmpeg_arch & " to " & new_FFmpeg_arch & "?" from table "MacYTDL"
			set switch_FFmpeg to button returned of (display dialog (theFFmpegSwitchLabel & " " & installed_FFmpeg_arch & theFFmpegToLabel & new_FFmpeg_arch & " ?") buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if switch_FFmpeg is theButtonYesLabel then
				run_Utilities_handlers's install_ffmpeg_ffprobe(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os, new_FFmpeg_arch, user_on_mid_os)
				set ffmpeg_version_long to do shell script ffmpeg_file & " -version"
				set AppleScript's text item delimiters to {"-", " "}
				set ffmpeg_version to text item 3 of ffmpeg_version_long
				set AppleScript's text item delimiters to ""
			end if
		end if
		
		-- Open youtube-dl/yt-dlp web page (in default web browser)
		if utilities_YTDL_webpage_choice is true then
			if DL_Use_YTDLP is "youtube-dl" then
				open location "https://github.com/ytdl-org/youtube-dl"
			else
				open location "https://github.com/yt-dlp/yt-dlp"
			end if
		end if
		
		-- Switch from youtube-dl to yt-dlp - only available if YTDL is installed (checked before Main) and is the current setting - if Homebrew yt-dlp installed, silently switch from YTDL to the Homebrew-yt-dlp install (rare case I expect)
		-- v1.24 - No longer offer to switch to youtube-dl
		if utilities_Switch_choice is true then
			set alert_text_ytdl to "Switching"
			set user_wants_switch to "yt-dlp"
			
			-- User currently using YTDL and has no form of yt-dlp
			if ytdlp_exists is false and homebrew_ytdlp_exists is false then
				
				-- ************************************************************************************************************************************************************
				-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
				-- check_ytdl(DL_Use_YTDLP)
				set branch_execution to check_ytdl(DL_Use_YTDLP)
				if branch_execution is "Main" then return
				-- ************************************************************************************************************************************************************
				
			end if
			
			-- User currently using YTDL but has Homebrew install of yt-dlp - silently switch to the Homebrew install - use PATH to find both Intel and ARM Homebrew installs - hopefully a rare case
			if ytdlp_exists is false and homebrew_ytdlp_exists is true then
				set thePreferMainOrBrewYTDLPInstallTextLabel to localized string "You currently have a Homebrew install of yt-dlp. Do you wish to switch to a MacYTDL install ?" from table "MacYTDL"
				set choiceMainOrBrewYTDL to button returned of (display dialog thePreferMainOrBrewYTDLPInstallTextLabel with title diag_Title buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with icon file MacYTDL_custom_icon_file giving up after 600)
				if choiceMainOrBrewYTDL is theButtonYesLabel then
					
					-- ************************************************************************************************************************************************************
					-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
					-- check_ytdl(DL_Use_YTDLP)
					set branch_execution to check_ytdl(DL_Use_YTDLP)
					if branch_execution is "Main" then return
					-- ************************************************************************************************************************************************************
					
				end if
			end if
			
			-- Update Use_ytdlp setting if user switches to yt-dlp - use show_yt_dlp as source of which yt-dlp was installed
			if alert_text_ytdl does not contain "is out of date" then
				set YTDL_version to do shell script ytdlp_file & " --version"
				-- Need to generalise show_yt_dlp so that only "youtube-dl" or "yt-dlp" is stored in plist
				if show_yt_dlp is "yt-dlp-legacy" then
					set switched_show_yt_dlp to "yt-dlp"
				else
					set switched_show_yt_dlp to show_yt_dlp
				end if
				tell application "System Events"
					tell property list file MacYTDL_prefs_file
						set value of property list item "Use_ytdlp" to switched_show_yt_dlp
						set value of property list item "YTDL_YTDLP_version" to YTDL_version
					end tell
				end tell
			end if
		end if
		
		-- Save current settings to file - retain saved settings location and name - might need to remove any weird extension chosen by user but leave for now
		if utilities_Save_Settings_choice is true then
			set branch_execution to run_Utilities_handlers's save_settings(DL_Saved_Settings_Location, diag_Title, theButtonReturnLabel, MacYTDL_custom_icon_file, theButtonOKLabel, MacYTDL_prefs_file, MacYTDL_preferences_path)
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 7/6/25 - First version of repeat loop to control flow
			if branch_execution is "Main" then return
			-- ************************************************************************************************************************************************************
		end if
		
		-- Restore settings from file - store restored settings name - is a literal OK for type ? - Keep current save settings location instead of what might be in restored settings file
		if utilities_Restore_Settings_choice is true then
			set branch_execution to run_Utilities_handlers's restore_settings(DL_Saved_Settings_Location, diag_Title, theButtonReturnLabel, MacYTDL_custom_icon_file, theButtonOKLabel, MacYTDL_prefs_file, MacYTDL_preferences_path, theButtonNoLabel, theButtonYesLabel, MacYTDL_version, MacYTDL_date, path_to_MacYTDL, resourcesPath, show_yt_dlp, theBestLabel, theDefaultLabel, X_position, Y_position, theNoRemuxLabel)
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 7/6/25 - First version of repeat loop to control flow
			if branch_execution is "Main" then return
			-- ************************************************************************************************************************************************************			
		end if
		
		-- Return to default settings - Delete current settings file and rebuild default settings
		if utilities_Return_Defaults_choice is true then
			set theReturnSettingsLabel to localized string "Do you really want to return to the default settings ?" from table "MacYTDL"
			set Really_Return_To_Defaults to button returned of (display dialog theReturnSettingsLabel with title diag_Title buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with icon file MacYTDL_custom_icon_file giving up after 600)
			if Really_Return_To_Defaults is theButtonYesLabel then
				run_Utilities_handlers's set_preferences(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version, MacYTDL_custom_icon_file)
			end if
		end if
		
		-- Check for MacYTDL update
		if utilities_MacYTDL_check_choice is true then
			-- Tell utilities handler that it should return to main_dialog when finished - auto_download tells utilities to skip main and just close	
			set skip_Main_dialog to false
			check_download_folder(downloadsFolder_Path, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, diag_Title, MacYTDL_custom_icon_file, skip_Main_dialog)
			run_Utilities_handlers's check_MacYTDL(downloadsFolder_Path, diag_Title, theButtonOKLabel, theButtonNoLabel, theButtonYesLabel, MacYTDL_version, MacYTDL_custom_icon_file)
		end if
		
		-- Install/Update Deno - added in v1.30, 1/11/25, part of Deno implementation for yt-dlp
		if utilities_Deno_choice is true then
			set deno_version to script "Utilities2"'s install_update_Deno(deno_version, user_system_arch, resourcesPath, path_to_MacYTDL, theButtonOKLabel, MacYTDL_custom_icon_file, diag_Title, MacYTDL_prefs_file)
		end if
		
		-- Install/Remove Atomic Parsely
		if utilities_Atomic_choice is true then
			if Atomic_is_installed is false then
				if DL_Use_YTDLP is "yt-dlp" then
					set theDontNeedAPTextLabel to localized string "You are currently using yt-dlp and so there is no need for Atomic Parsley. Do you still wish to install Atomic Parsley ?" from table "MacYTDL"
					set reallyWantsAP to button returned of (display dialog theDontNeedAPTextLabel with title diag_Title buttons {theButtonNoLabel, theButtonYesLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600)
					
					-- ************************************************************************************************************************************************************
					-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
					if reallyWantsAP is theButtonNoLabel then return "Main"
					--	if reallyWantsAP is theButtonNoLabel then main_dialog()
					-- ************************************************************************************************************************************************************		
					
				end if
				run_Utilities_handlers's install_MacYTDLatomic(diag_Title, theButtonOKLabel, path_to_MacYTDL, usr_bin_folder)
				set Atomic_is_installed to true
				tell me to activate
			else if Atomic_is_installed is true then
				run_Utilities_handlers's remove_MacYTDLatomic(path_to_MacYTDL, theButtonOKLabel, diag_Title, MacYTDL_custom_icon_file)
				set Atomic_is_installed to false
				tell application "System Events"
					tell property list file MacYTDL_prefs_file
						set value of property list item "Thumbnail_Embed" to false
					end tell
				end tell
				tell me to activate
			end if
		end if
		
		-- Install/Remove Service
		if utilities_Service_choice is true then
			if isServiceInstalled is "No" then
				-- Service is not installed - user wants to install it
				run_Utilities_handlers's install_MacYTDLservice(path_to_MacYTDL)
				tell me to activate
				set theServiceInstalledLabel to localized string "The MacYTDL Service is installed." from table "MacYTDL"
				display dialog theServiceInstalledLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 100
			else if isServiceInstalled is "Yes" then
				-- Service is installed - user wants to remove it - but warn user if auto_download setting must be off before removing Service
				if DL_auto is true then
					set theButtonRemoveLabel to localized string "Remove" from table "MacYTDL"
					set theAutoDLisOnLabel to localized string "You have the Auto downloads setting on. Auto downloads will not work if the Service is removed. You can cancel and return to Main dialog or remove the Service and turn off auto downloads." from table "MacYTDL"
					set reallyWantsAPRemoved to button returned of (display dialog theAutoDLisOnLabel with title diag_Title buttons {theButtonReturnLabel, theButtonRemoveLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600)
					
					-- ************************************************************************************************************************************************************
					-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
					if reallyWantsAPRemoved is theButtonReturnLabel then return "Main"
					--	if reallyWantsAPRemoved is theButtonReturnLabel then main_dialog()
					-- ************************************************************************************************************************************************************		
					
					set Service_file_plist to (macYTDL_service_file_nonPosix & ":Contents:info.plist")
					tell application "System Events"
						set new_value to "Send-URL-To-MacYTDL"
						tell property list file Service_file_plist
							set value of property list item "default" of property list item "NSMenuItem" of property list item 1 of property list items of contents to new_value
						end tell
						tell property list file MacYTDL_prefs_file
							set value of property list item "Auto_Download" to false
						end tell
					end tell
				end if
				run_Utilities_handlers's remove_MacYTDLservice()
				tell me to activate
				set theServiceRemovedLabel to localized string "The MacYTDL Service has been removed." from table "MacYTDL"
				display dialog theServiceRemovedLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 100
			end if
		end if
		
		-- Move all log files to Trash - split moves because mv fails "too many args" if there are too many files - try loop in case one of mv commands fails to find any files - look for all 3 name forms of log file used by MacYTDL
	else if utilities_button_number_returned is 1 then -- Delete logs
		try
			do shell script "mv " & POSIX path of MacYTDL_preferences_path & "ytdl_log-[ABCDEabcde]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "ytdl_log-[FGHIJKLMNfghijklmn]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "ytdl_log-[OPQRSTUVWXYZopqrstuvwxyz]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "ytdl_log-[1234567890#~!@$%^]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "ytdl_log-*" & " ~/.trash/"
		end try
		try
			do shell script "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_log-[ABCDEabcde]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_log-[FGHIJKLMNfghijklmn]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_log-[OPQRSTUVWXYZopqrstuvwxyz]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_log-[1234567890#~!@$%^]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_log-*" & " ~/.trash/"
		end try
		try
			do shell script "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_response-[ABCDEabcde]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_response-[FGHIJKLMNfghijklmn]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_response-[OPQRSTUVWXYZopqrstuvwxyz]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_response-[1234567890#~!@$%^]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_response-*" & " ~/.trash/"
		end try
		set theUtilitiesDeleteLogsLabel to localized string "All MacYTDL log files are now in the Trash." from table "MacYTDL"
		display dialog theUtilitiesDeleteLogsLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 100
		
		-- Uninstall all MacYTDL files - move files to Trash
		-- v1.28 - 14/9/24 - added code to delete MacYTDL files in other user accounts
		-- v1.29 - Remove "_internal" folder - it is installed by unpacked yt-dlp
	else if utilities_button_number_returned is 2 then
		set theUtilitiesUninstallLabel to localized string "Do you really want to remove MacYTDL ? Everything will be moved to the Trash." from table "MacYTDL"
		set really_remove_MacYTDL to display dialog theUtilitiesUninstallLabel buttons {theButtonYesLabel, theButtonNoLabel} with title diag_Title default button 2 with icon file MacYTDL_custom_icon_file giving up after 600
		set remove_answ to button returned of really_remove_MacYTDL
		if remove_answ is theButtonNoLabel then
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
			return "Main"
			--	main_dialog()
			-- ************************************************************************************************************************************************************
			
		end if
		try
			-- If they exist, move components to Trash
			-- v1.30, 16/12/25 - Added block to remove Deno if installed
			if Atomic_is_installed is true then
				do shell script "mv /usr/local/bin/AtomicParsley" & " ~/.trash/AtomicParsley" with administrator privileges
			end if
			if YTDL_exists is true then
				do shell script "mv " & POSIX path of youtubedl_file & " ~/.trash/youtube-dl" with administrator privileges
			end if
			if ytdlp_exists is true then
				do shell script "mv " & POSIX path of ytdlp_file & " ~/.trash/yt-dlp" with administrator privileges
			end if
			if deno_version is not "Not installed" and deno_version is not "Refused" then
				do shell script "mv " & POSIX path of deno_file & " ~/.trash/deno" with administrator privileges
			end if
			if ffprobe_exists is true then
				do shell script "mv " & POSIX path of ffprobe_file & " ~/.trash/ffprobe" with administrator privileges
			end if
			if ffmpeg_exists is true then
				do shell script "mv " & POSIX path of ffmpeg_file & " ~/.trash/ffmpeg" with administrator privileges
			end if
			-- Move MacYTDL to Trash
			set path_to_macytdl_file to quoted form of (POSIX path of path_to_MacYTDL)
			do shell script "mv " & path_to_macytdl_file & " ~/.trash/MacYTDL.app" with administrator privileges
			-- trap case where user cancels credentials dialog
		on error number -128
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
			return "Main"
			--	main_dialog()
			-- ************************************************************************************************************************************************************
			
		end try
		-- v1.29 - Move the "_internal" folder to Trash - ignore error if the folder doesn't exist
		try
			do shell script "mv /usr/local/bin/_internal ~/.trash/internal" with administrator privileges
		end try
		-- Move the defaults plist file created by macOS to Trash
		set User_defaults_path to "Library/Preferences/com.apple.script.id.MacYTDL.plist"
		set macYTDL_defaults_preferences_file to (POSIX path of (path to home folder) & User_defaults_path)
		tell application "System Events"
			if (the file macYTDL_defaults_preferences_file exists) then
				tell current application to do shell script "mv " & quoted form of (macYTDL_defaults_preferences_file) & " ~/.trash/com.apple.script.id.MacYTDL.plist"
			end if
		end tell
		-- v1.28 - 20/9/24 - Move all users' MacYTDL files and folders to Trash - add user name as prefix to trashed files & folders
		-- Expended to include all users' MacYTDL files
		-- Use try blocks to skip cases where other user does not have those files
		tell application "System Events"
			set allTtheUsers to every user
		end tell
		repeat with user_account in allTtheUsers
			set the_Users_Name to name of user_account
			set user_prefs_location to "/Users/" & the_Users_Name & "/Library/Preferences/MacYTDL"
			try
				do shell script "mv " & user_prefs_location & " ~/.trash/" & (the_Users_Name & "-MacYTDL") with administrator privileges
			end try
			set user_DTP_location to "/Users/" & the_Users_Name & "/Library/Script Libraries/DialogToolkitMacYTDL.scptd"
			try
				do shell script "mv " & quoted form of user_DTP_location & " ~/.trash/" & (the_Users_Name & "-DialogToolkitMacYTDL.scptd") with administrator privileges -- Quoted form because of space in "Script Libraries" folder name
			end try
			set user_Service_location to "/Users/" & the_Users_Name & "/Library/Services/Send-URL-To-MacYTDL.workflow"
			try
				do shell script "mv " & quoted form of user_Service_location & " ~/.trash/" & (the_Users_Name & "-Send-URL-To-MacYTDL.workflow") with administrator privileges
			end try
			set user_Myriad_location to "/Users/" & the_Users_Name & "/Library/Script Libraries/Myriad Tables Lib.scptd"
			try
				do shell script "mv " & quoted form of user_Myriad_location & " ~/.trash/" & quoted form of (the_Users_Name & "-Myriad Tables Lib.scptd") with administrator privileges
			end try
		end repeat
		-- Say goodbye
		set theUtilitiesMYTDLUninstalledLabel to localized string "MacYTDL is uninstalled. All components are in the Trash which you can empty when you wish. Cheers." from table "MacYTDL"
		set theUtilitiesMYTDLUninstalledByeLabel to localized string "Goodbye" from table "MacYTDL"
		set MacYTDL_custom_icon_file_Trash to (path_to_home_folder & ".Trash:MacYTDL.app:Contents:Resources:MacYTDL.icns") as string
		display dialog theUtilitiesMYTDLUninstalledLabel buttons {theUtilitiesMYTDLUninstalledByeLabel} default button 1 with icon file MacYTDL_custom_icon_file_Trash giving up after 600
		error number -128
		
		-- Show the About MacYTDL dialog
	else if utilities_button_number_returned is 3 then -- About
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		run_Utilities_handlers's show_about(DL_Use_YTDLP, MacYTDL_date, theButtonOKLabel, diag_Title, MacYTDL_custom_icon_file_posix)
		-- show_about()
		-- ************************************************************************************************************************************************************		
		
	end if
	
	-- ************************************************************************************************************************************************************
	-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
	return "Main"
	--	main_dialog()
	-- ************************************************************************************************************************************************************
	
end utilities


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
