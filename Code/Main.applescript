-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  MacYTDL
--  A GUI for the Python scripts youtube-dl and yt-dlp.  Many thanks to Shane Stanley, Adam Albrec, kopurando and Michael Page
--  Trying to bring in useful functions in a pithy GUI with few AppleScript extensions and without AppleScriptObjC
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Include libraries - needed for Shane Staney's Dialog Toolkit
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use script "DialogToolkitMacYTDL"
-- use script "Myriad Tables Lib" version "1.0.13"
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
global alert_text_ytdl
global alert_text_ffmpeg
global path_to_MacYTDL
global shellPath
global downloadsFolder_Path
global Atomic_is_installed
global macYTDL_Atomic_file
global download_filename
global download_filename_new
global YTDL_log_file
global YTDL_simulate_file
global youtubedl_file
global ytdlp_file
global YTDL_exists
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
global DL_Remux_format
global DL_Remux_original
global DL_Add_Metadata
global DL_batch_status
global DL_Limit_Rate
global DL_Limit_Rate_Value
global DL_Show_Settings
global DL_Use_Cookies
global DL_Cookies_Location
global DL_Use_Proxy
global DL_Proxy_URL
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
global DTP_file
global Myriad_file
global Myriad_exists
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
global theNoRemuxLabel
global theDefaultLabel
global window_Position
global X_position
global Y_position
global run_Utilities_handlers


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
set path_to_MacYTDL to path to me as text
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
-- Users on macOS 10.10 to 10.14.6 need yt-dlp legacy install - also changes content of  Utilities dialog
-- If user on <10.12.1 will have expired certificates preventing FFmpeg download  <<== NOT SURE THIS IS CORRECT - DECIDED TO OMIT
-- Users on 12.3+ cannot use youtube-dl (because macOS no longer includes Python runtime)
-- Users on 10.13, 10.14 and 10.15 cannot use FFmpeg from Riedl as they are compiled for macOS 12+
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
set homebrew_Intel_ytdlp_file to ("usr:local:bin:yt-dlp" as text)
set macPorts_ytdlp_file to ("/opt/local/bin/yt-dlp" as text)
set youtubedl_file to ("/usr/local/bin/youtube-dl" as text)
set home_folder to (path to home folder) as text
set libraries_folder to home_folder & "Library:Script Libraries"
set DTP_file to libraries_folder & ":DialogToolkitMacYTDL.scptd"
set Myriad_file to libraries_folder & ":Myriad Tables Lib.scptd"
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

set batch_filename to "BatchFile.txt" as string
set batch_file to POSIX file (MacYTDL_preferences_path & batch_filename)


-- Get size of main screen so dialogs can be positioned
-- Passed to main_dialog via set_preferences when MacYTDL opened for 1st time or if MacYTDL prefs file has been deleted
-- Screen height is used for positioning ABC and SBS choosers and Monitor dialogs
set screen_size to get_screensize()
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
set theNoRemuxLabel to localized string "No remux" from table "MacYTDL"

-- Load utilities.scpt so that various handlers can be called
set path_to_Utilities to (path_to_MacYTDL & "Contents:Resources:Scripts:Utilities.scpt") as alias
set run_Utilities_handlers to load script path_to_Utilities

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
	
	-- Note: ytdlp_file can actually be yt-dlp or yt-dlp-legacy but is always named "yt-dlp" in the usr/local/bin folder - only use Homebrew yt-dlp install if there is no MacYTDL install - check for Homebrew install on both Intel and ARM Macs
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
	
	if exists file DTP_file then
		set DTP_exists to true
	else
		set DTP_exists to false
	end if
	
	if exists file Myriad_file then
		set Myriad_exists to true
	else
		set Myriad_exists to false
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
if YTDL_exists is false and ytdlp_exists is false and DTP_exists is false and Myriad_exists is false and ffmpeg_exists is false and ffprobe_exists is false and prefs_exists is false and homebrew_ytdlp_exists is false and homebrew_ffmpeg_exists is false and homebrew_ffprobe_exists is false then
	set theComponentsNotInstalledtTextLabel1 to localized string "It looks like you have not used MacYTDL before. A number of components must be installed for MacYTDL to run. There is more detail in the Help file. Would you like to install those components now ? Otherwise, Quit." from table "MacYTDL"
	set theComponentsNotInstalledtTextLabel2 to localized string "Note: Some components will be downloaded which might take a while and you will need to provide administrator credentials." from table "MacYTDL"
	tell me to activate
	set components_install_answ to button returned of (display dialog theComponentsNotInstalledtTextLabel1 & return & return & theComponentsNotInstalledtTextLabel2 with title diag_Title buttons {theButtonQuitLabel, theButtonYesLabel} default button 2 cancel button 1 with icon file MacYTDL_custom_icon_file giving up after 600)
	if components_install_answ is theButtonYesLabel then
		set YTDL_ytdlp_version to run_Utilities_handlers's check_ytdl_installed(usr_bin_folder, diag_Title, youtubedl_file, ytdlp_file, theButtonQuitLabel, theButtonYesLabel, path_to_MacYTDL, theButtonOKLabel, resourcesPath, show_yt_dlp, MacYTDL_custom_icon_file)
		set YTDL_version to word 1 of YTDL_ytdlp_version
		if word 2 of YTDL_ytdlp_version is "ytdl" then
			set YTDL_exists to true
			set ytdlp_exists to false
		else
			set YTDL_exists to false
			set ytdlp_exists to true
		end if
		run_Utilities_handlers's set_preferences(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version, MacYTDL_custom_icon_file)
		set prefs_exists to true
		delay 1
		run_Utilities_handlers's install_DTP(DTP_file, path_to_MacYTDL, resourcesPath)
		set DTP_exists to true
		delay 1
		run_Utilities_handlers's install_Myriad(Myriad_file, path_to_MacYTDL, resourcesPath)
		set Myriad_exists to true
		delay 1
		run_Utilities_handlers's install_ffmpeg_ffprobe(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os, user_system_arch, user_on_mid_os)
		set ffprobe_exists to true
		set ffmpeg_exists to true
		set ffmpeg_version_long to do shell script ffmpeg_file & " -version"
		run_Utilities_handlers's ask_user_install_service(path_to_MacYTDL, theButtonYesLabel, diag_Title, MacYTDL_custom_icon_file)
	else
		quit_MacYTDL()
	end if
end if

-- If one or more components are installed, indicates user has used MacYTDL before - check and install any missing components

-- Set up preferences if they don't exist - YTDL_version will contain "not installed" until cleanup below - ugly but a very rare case I hope
if prefs_exists is false then
	-- Prefs file doesn't exist - warn user it must be created for MacYTDL to work
	set theInstallPrefsTextLabel to localized string "The MacYTDL Preferences file is not present. To work, MacYTDL needs to create a file in your Preferences folder. Do you wish to continue ?" from table "MacYTDL"
	set Install_Prefs to button returned of (display dialog theInstallPrefsTextLabel buttons {theButtonNoLabel, theButtonYesLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
	if Install_Prefs is theButtonYesLabel then
		run_Utilities_handlers's set_preferences(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version, MacYTDL_custom_icon_file)
		set prefs_exists to true
	else if Install_Prefs is theButtonNoLabel then
		error number -128
	end if
end if

-- If user gets to here can assume Prefs exist so, check whether user has one of the old versions - if so, call set_preferences to fix - continue on if current version - will delete this one day
run_Utilities_handlers's check_settings(MacYTDL_prefs_file, old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version)

-- Get updated setting for installed downloader
tell application "System Events"
	tell property list file MacYTDL_prefs_file
		set setting_yt_dlp to value of property list item "Use_ytdlp"
	end tell
end tell

-- 4/3/23 - added test for absence of yt-dlp_macos_legacy - no longer offer to switch to youtube-dl
-- No downloader installed - must install yt-dlp and update settings
-- For some reason user has no downloaders or is missing desired downloader - if youtube-dl is missing force install of yt-dlp - include Homebrew test as it can be ARM
if YTDL_exists is false and ytdlp_exists is false and homebrew_ytdlp_exists is false then
	set theYTDLNotInstalledtTextLabel1 to localized string "No downloader is installed. MacYTDL cannot download videos. By default it uses the yt-dlp downloader. Would you like to install yt-dlp now ?" from table "MacYTDL"
	set theYTDLNotInstalledtTextLabel2 to localized string "Note: This download can take a while and you will probably need to provide administrator credentials." from table "MacYTDL"
	tell me to activate
	set yt_install_answ to button returned of (display dialog theYTDLNotInstalledtTextLabel1 & return & return & theYTDLNotInstalledtTextLabel2 with title diag_Title buttons {theButtonQuitLabel, theButtonYesLabel} default button 2 cancel button 1 with icon file MacYTDL_custom_icon_file giving up after 600)
	if yt_install_answ is theButtonYesLabel then
		set YTDL_ytdlp_version to run_Utilities_handlers's check_ytdl_installed(usr_bin_folder, diag_Title, youtubedl_file, ytdlp_file, theButtonQuitLabel, theButtonYesLabel, path_to_MacYTDL, theButtonOKLabel, resourcesPath, show_yt_dlp, MacYTDL_custom_icon_file)
		set YTDL_version to word 1 of YTDL_ytdlp_version
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
		set YTDL_ytdlp_version to run_Utilities_handlers's check_ytdl_installed(usr_bin_folder, diag_Title, youtubedl_file, ytdlp_file, theButtonQuitLabel, theButtonYesLabel, path_to_MacYTDL, theButtonOKLabel, resourcesPath, show_yt_dlp, MacYTDL_custom_icon_file)
		set YTDL_version to word 1 of YTDL_ytdlp_version
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

-- Check if DTP exists - install if not
if DTP_exists is false then
	set theInstallDTPTextLabel to localized string "MacYTDL needs a code library installed in your Libraries folder. It cannot function without that library. Do you wish to continue ?" from table "MacYTDL"
	set install_DTP to button returned of (display dialog theInstallDTPTextLabel buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
	if install_DTP is theButtonYesLabel then
		run_Utilities_handlers's install_DTP(DTP_file, path_to_MacYTDL, resourcesPath)
		set DTP_exists to true
		--	else if install_DTP is theButtonNoLabel then
		--		error number -128
	end if
end if

-- v1.26 - Check if Myriad Tables is installed - install if not - save user's choice to stop nagging every time they start MacYTDL
-- Decided to omit this install on startup - user is asked about it if they turn on "Get Formats List" in Settings()
--if Myriad_exists is false then
--	set theInstallMyriadTextLabel to localized string "MacYTDL needs a code library installed in your Libraries folder. It cannot show the \"Formats List\" without that library. Do you wish to install ?" from table "MacYTDL"
--	set install_Myriad to button returned of (display dialog theInstallMyriadTextLabel buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
--	if install_Myriad is theButtonYesLabel then
--		run_Utilities_handlers's install_Myriad(Myriad_file, path_to_MacYTDL, resourcesPath)
--		set Myriad_exists to true
--	end if
--end if

-- If user gets to here can assume DTP exists. Check whether DTP name is changed or new version of DTP available
run_Utilities_handlers's check_DTP(DTP_file, path_to_MacYTDL)

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
if ffprobe_exists is true or homebrew_ffprobe_exists is true then
	set ffprobe_version_long to do shell script shellPath & "  ffprobe -version"
	set AppleScript's text item delimiters to {"-", " "}
	set ffprobe_version to text item 3 of ffprobe_version_long
	set AppleScript's text item delimiters to ""
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

-- Set path and name for youtube-dl/yt-dlp simulated log file - a simulated youtube-dl/yt-dlp download puts all its feedback into this file - it's a generic file used for all downloads and so only contains detail on the most recent download - simulation helps find errors and problems before starting the download
set YTDL_simulate_file to MacYTDL_preferences_path & "ytdl_simulate.txt"

-- Is auto checking of youtube-dl/yt-dlp version on ? DL_Use_YTDLP contains "yt-dlp" or "youtube-dl"
tell application "System Events"
	tell property list file MacYTDL_prefs_file
		set DL_YTDL_auto_check to value of property list item "Auto_Check_YTDL_Update"
		set DL_Use_YTDLP to value of property list item "Use_ytdlp"
	end tell
end tell

-- Check on need to add new v1.21 YTDL/yt-dlp version to the prefs file
run_Utilities_handlers's check_settings_current(MacYTDL_prefs_file, DL_Use_YTDLP, MacYTDL_preferences_path, youtubedl_file, ytdlp_file)

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
	-- Need to set YTDL_version according to current script
	if DL_Use_YTDLP is "youtube-dl" then
		set YTDL_version to do shell script youtubedl_file & " --version"
	else if homebrew_ytdlp_exists is false then
		set YTDL_version to do shell script ytdlp_file & " --version"
	end if
	if length of YTDL_version is greater than 12 then
		set alert_text_ytdlLabel to localized string "Do you wish to update your nightly build of yt-dlp" from table "MacYTDL"
		set update_nightly_q to button returned of (display dialog (alert_text_ytdlLabel & " ?") with title diag_Title buttons {theButtonNoLabel, theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600)
		if update_nightly_q is theButtonOKLabel then
			-- Install nightly build - no need to check version as nightly builds are released almost every 24 hours
			try
				do shell script shellPath & " yt-dlp --update-to nightly" with administrator privileges
				-- trap case where user cancels credentials dialog
			on error number -128
				set cancel_update_flag to true
			end try
			if cancel_update_flag is false then
				set YTDL_version to do shell script shellPath & " yt-dlp --version"
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


main_dialog()

on main_dialog()
	
	--*****************  This is for testing variables as they come into and back to Main - beware some of these are not defined on all circumstances
	--	display dialog "video_URL: " & return & return & "called_video_URL: " & called_video_URL & return & return & "URL_user_entered: " & URL_user_entered & return & return & "URL_user_entered_clean: " & URL_user_entered_clean & return & return & "default_contents_text: "
	
	-- Read the preferences file to get current settings - if error probably because of missing prefs - error can be caused by user restoring old preferences file
	run_Utilities_handlers's read_settings(MacYTDL_prefs_file)
	
	-- Need to work through why I put this code here - deary me, a lack of documentation
	set DL_format to localized string DL_format from table "MacYTDL"
	set DL_subtitles_format to localized string DL_subtitles_format from table "MacYTDL"
	set DL_Remux_format to localized string DL_Remux_format from table "MacYTDL"
	set DL_audio_codec to localized string DL_audio_codec from table "MacYTDL"
	
	-- In rare cases, the prefs file had to be recreated (above) - need to clean up YTDL_version and YTDL_YTDLP_version
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
	on error errNum -- Not called from Service, should always be error -2753 (variable not defined) - refill URL so it's shown in dialog - will be blank if user has not pasted a URL
		set default_contents_text to URL_user_entered_clean
	end try
	
	set theDiagSettingsTextLabel to localized string "One-time settings:                                     Batches:" from table "MacYTDL"
	set accViewWidth to 450
	set accViewInset to 80
	
	-- Set buttons and controls
	set theButtonsHelpLabel to localized string "Help" from table "MacYTDL"
	set theButtonsUtilitiesLabel to localized string "Utilities" from table "MacYTDL"
	set theButtonsSettingsLabel to localized string "Settings" from table "MacYTDL"
	set theButtonsAdminLabel to localized string "Admin" from table "MacYTDL"
	set {theButtons, minWidth} to create buttons {theButtonsHelpLabel, theButtonsUtilitiesLabel, theButtonQuitLabel, theButtonsAdminLabel, theButtonsSettingsLabel, theButtonContinueLabel} button keys {"?", "u", "q", "<", ",", ""} default button 6
	if minWidth > accViewWidth then set accViewWidth to minWidth -- make sure buttons fit
	set theFieldLabel to localized string "Paste URL here" from table "MacYTDL"
	set {theField, theTop} to create field default_contents_text placeholder text theFieldLabel left inset accViewInset bottom 0 field width accViewWidth - accViewInset extra height 15
	set {theRule, theTop} to create rule theTop + 18 rule width accViewWidth
	set theCheckbox_Show_SettingsLabel to localized string "Show settings before download" from table "MacYTDL"
	set {theCheckbox_Show_Settings, theTop} to create checkbox theCheckbox_Show_SettingsLabel left inset accViewInset + 50 bottom (theTop + 10) max width 250 initial state DL_Show_Settings
	set theCheckbox_SubTitlesLabel to localized string "Subtitles for this download" from table "MacYTDL"
	set {theCheckbox_SubTitles, theTop} to create checkbox theCheckbox_SubTitlesLabel left inset accViewInset bottom (theTop + 15) max width 250 initial state DL_subtitles
	set theCheckbox_CredentialsLabel to localized string "Credentials for download" from table "MacYTDL"
	set {theCheckbox_Credentials, theTop} to create checkbox theCheckbox_CredentialsLabel left inset accViewInset bottom (theTop + 5) max width 200 without initial state
	set theCheckbox_DescriptionLabel to localized string "Download description" from table "MacYTDL"
	set {theCheckbox_Description, theTop} to create checkbox theCheckbox_DescriptionLabel left inset accViewInset bottom (theTop + 5) max width 175 initial state DL_description
	set theLabelledPopUpRemuxFileformat to localized string "Remux format:" from table "MacYTDL"
	if DL_Use_YTDLP is "yt-dlp" then
		set {main_thePopUp_FileFormat, main_formatlabel, theTop, popupLeft} to create labeled popup {theNoRemuxLabel, "mp4", "mkv", "flv", "webm", "mov", "avi", "ogg"} left inset accViewInset - 5 bottom (theTop + 5) popup width 100 max width 200 label text theLabelledPopUpRemuxFileformat popup left accViewInset - 5 initial choice DL_Remux_format
	else
		set {main_thePopUp_FileFormat, main_formatlabel, theTop, popupLeft} to create labeled popup {theNoRemuxLabel, "mp4", "mkv", "flv", "webm", "avi", "ogg"} left inset accViewInset - 5 bottom (theTop + 5) popup width 100 max width 200 label text theLabelledPopUpRemuxFileformat popup left accViewInset - 5 initial choice DL_Remux_format
	end if
	set thePathControlLabel to localized string "Change download folder:" from table "MacYTDL"
	set {thePathControl, pathLabel, theTop} to create labeled path control (POSIX path of downloadsFolder_Path) left inset accViewInset bottom (theTop + 5) control width 190 label text thePathControlLabel with pops up
	set theCheckbox_OpenBatchLabel to localized string "Open Batch functions" from table "MacYTDL"
	set {theCheckbox_OpenBatch, theTop, theBatchLabelWidth} to create checkbox theCheckbox_OpenBatchLabel left inset (accViewInset + 210) bottom (theTop - 40) max width 200 without initial state
	-- Increase width when localised text is longer than English
	set add_extra_dialog_width to 0
	if theBatchLabelWidth is greater than 158 then
		set add_extra_dialog_width to (theBatchLabelWidth - 158)
	end if
	set theCheckbox_AddToBatchLabel to localized string "Add URL to Batch" from table "MacYTDL"
	set {theCheckbox_AddToBatch, theTop} to create checkbox theCheckbox_AddToBatchLabel left inset (accViewInset + 210) bottom (theTop + 5) max width 200 initial state DL_batch_status
	set {diag_settings_prompt, theTop} to create label theDiagSettingsTextLabel left inset accViewInset bottom theTop + 8 max width accViewWidth control size regular size with bold type
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 60 view width 64 view height 64 scale image scale proportionally
	
	-- Display the dialog
	--	tell me to activate -- Is this really needed ?
	set {button_label_returned, button_number_returned, controls_results, finalPosition} to display enhanced window diag_Title acc view width (accViewWidth + add_extra_dialog_width) acc view height theTop acc view controls {theField, theCheckbox_Show_Settings, theCheckbox_SubTitles, theCheckbox_Credentials, theCheckbox_Description, main_thePopUp_FileFormat, main_formatlabel, thePathControl, theCheckbox_AddToBatch, theCheckbox_OpenBatch, pathLabel, diag_settings_prompt, theRule, MacYTDL_icon} buttons theButtons active field theField initial position window_Position
	
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
	set openBatch_chosen to item 10 of controls_results
	set DL_batch_status to item 9 of controls_results
	set folder_chosen to item 8 of controls_results
	set remux_format_choice to item 6 of controls_results
	set description_choice to item 5 of controls_results
	set credentials_choice to item 4 of controls_results
	set subtitles_choice to item 3 of controls_results
	set show_settings_choice to item 2 of controls_results
	set URL_user_entered_clean to item 1 of controls_results -- Needed to refill the URL box on return from Settings, Help etc.
	
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
		set_settings()
	else if button_number_returned is 4 then
		set branch_execution to run_Utilities_handlers's set_admin_settings(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version, MacYTDL_custom_icon_file, theButtonCancelLabel, window_Position, theButtonReturnLabel, MacYTDL_custom_icon_file_posix)
		if branch_execution is "Main" then main_dialog()
		if branch_execution is "Settings" then set_settings()
	else if button_number_returned is 2 then -- Show Utilities
		utilities()
	else if button_number_returned is 1 then -- Show Help
		set path_to_MacYTDL_alias to path_to_MacYTDL as alias
		set MacYTDL_help_file to (path to resource "Help.pdf" in bundle path_to_MacYTDL_alias) as string
		set MacYTDL_help_file_posix to POSIX path of MacYTDL_help_file
		tell application "System Events" to open file MacYTDL_help_file_posix
		main_dialog()
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
	if remux_format_choice is not theNoRemuxLabel then
		if DL_Use_YTDLP is "yt-dlp" then
			set YTDL_remux_format to "--recode-video " & remux_format_choice & " " & "--postprocessor-args \"ffmpeg:-codec copy\" "
		else
			set YTDL_remux_format to "--recode-video " & remux_format_choice & " " & "--postprocessor-args \"-codec copy\" "
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
		get_YTDL_credentials()
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
	-- If user wants QT compatibility, must turn off remux 
	if DL_QT_Compat is true then
		-- v1.27 - 12/6/24 - Testing different video converter - definitely faster - But, some online posts suggest quality is not good
		--		set YTDL_QT_Compat to "--recode-video \"mp4\" --ppa \"VideoConvertor:-vcodec h264_videotoolbox -acodec aac\" "
		set YTDL_QT_Compat to "--recode-video \"mp4\" --ppa \"VideoConvertor:-vcodec libx264 -acodec aac\" "
		set YTDL_remux_format to ""
	else
		set YTDL_QT_Compat to ""
	end if
	
	set YTDL_no_part to ""
	
	-- Set settings to enable audio only download - gets a format list - use post-processing if necessary - need to ignore all errors here which are usually due to missing videos etc. - only check first item of a playlist
	if DL_audio_only is true then
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
	
	check_download_folder(folder_chosen, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, diag_Title, MacYTDL_custom_icon_file, skip_Main_dialog)
	if DL_Use_Cookies is true then check_cookies_file(DL_Cookies_Location)
	
	-- Set variable to contain download folder path - value comes from runtime settings which gets initial value from preferences but which user can then change
	-- But first, if user has set download path to a file, use parent folder for downloads
	tell application "System Events" to set test_DL_folder to (get class of item (folder_chosen as text)) as text
	if test_DL_folder is "file" then
		-- Trim last part of path name
		set offset_to_file_name to last_offset(folder_chosen as text, "/")
		set folder_chosen to text 1 thru offset_to_file_name of folder_chosen
	end if
	
	-- Need to set up a dummy variable to take the URL when it is sent by Utilities/auto_download(). This is so that the old behaviour in which main_dialog reopens with a blank URL box after a download can be retained yet the URL is retained if user goes from Main to Settings/Utilities and back to Main
	set URL_user_entered_from_auto_download to ""
	
	set downloadsFolder_Path to folder_chosen
	
	if button_number_returned is 6 then -- Continue to download		
		if openBatch_chosen is true then
			open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
		else
			download_video(shellPath, path_to_MacYTDL, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, screen_width, screen_height, YTDL_simulate_file, URL_user_entered, URL_user_entered_from_auto_download, folder_chosen, diag_Title, DL_batch_status, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format_pref, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, skip_Main_dialog, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, theButtonReturnLabel, theButtonQuitLabel, theButtonContinueLabel, YTDL_QT_Compat, DL_Use_YTDLP, theBestLabel, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, user_on_old_os)
		end if
	end if
end main_dialog


---------------------------------------------------------------------------------------------
--
-- 	Download videos - called by Main dialog - calls monitor.scpt
--
---------------------------------------------------------------------------------------------
on download_video(shellPath, path_to_MacYTDL, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, screen_width, screen_height, YTDL_simulate_file, URL_user_entered, URL_user_entered_from_auto_download, folder_chosen, diag_Title, DL_batch_status, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format_pref, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, skip_Main_dialog, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, theButtonReturnLabel, theButtonQuitLabel, theButtonContinueLabel, YTDL_QT_Compat, DL_Use_YTDLP, theBestLabel, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch, user_on_old_os)
	
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
		tell me to activate
		set theURLBlankLabel to localized string "You need to paste a URL before selecting Download. Quit or OK to try again." from table "MacYTDL"
		set quit_or_return to button returned of (display dialog theURLBlankLabel buttons {theButtonQuitLabel, theButtonOKLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
		if quit_or_return is theButtonOKLabel then
			main_dialog()
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
				main_dialog()
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
			main_dialog()
		end if
	end if
	
	-- Fourth, test whether the URL is an iView or OnDemand page not supported by yt-dlp/youtube-dl - need nested if test for SBS given likely false positives from "-collection" in non-SBS URLs
	if URL_user_entered contains "https://iview.abc.net.au/category" or URL_user_entered contains "https://iview.abc.net.au/collection" or URL_user_entered is "'https://iview.abc.net.au/browse'" or URL_user_entered contains "https://iview.abc.net.au/channel" or URL_user_entered is "https://iview.abc.net.au" or URL_user_entered is "https://iview.abc.net.au/" then
		set theURLWarningiViewCategoryLabel to localized string "This is an iView page from which MacYTDL cannot download videos. Try an individual show." from table "MacYTDL"
		display dialog theURLWarningiViewCategoryLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		main_dialog()
	end if
	if URL_user_entered contains "https://iview.abc.net.au/show" and user_on_old_os is true then
		set theURLWarningiViewCategoryLabel to localized string "This is an iView show page which MacYTDL cannot display on OS X 10.10, 10.11 and 10.12. Try an individual show." from table "MacYTDL"
		display dialog theURLWarningiViewCategoryLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		main_dialog()
	end if
	if URL_user_entered contains "https://www.sbs.com.au/ondemand" then
		if URL_user_entered is "'https://www.sbs.com.au/ondemand'" or URL_user_entered is "'https://www.sbs.com.au/ondemand/tv-shows'" or URL_user_entered contains "https://www.sbs.com.au/ondemand/collection" or URL_user_entered contains "-collection" or URL_user_entered contains "https://www.sbs.com.au/ondemand/sport" or URL_user_entered contains "https://www.sbs.com.au/ondemand/movies" or URL_user_entered contains "https://www.sbs.com.au/ondemand/live" or URL_user_entered contains "https://www.sbs.com.au/ondemand/fifa-world-cup-2022" or URL_user_entered contains "https://www.sbs.com.au/ondemand/favourites" then
			set theURLWarningSBSCategoryLabel to localized string "This is an SBS OnDemand Category page from which MacYTDL cannot download videos. Try an individual show." from table "MacYTDL"
			display dialog theURLWarningSBSCategoryLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			if skip_Main_dialog is true then
				error number -128
			end if
			main_dialog()
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
			set NineNow_show_new to run_Utilities_handlers's replace_chars(NineNow_show_old, "-", "_")
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
				main_dialog()
			else
				set is_channel to true
			end if
		else
			set theYTChannelLabel to localized string "The URL you entered looks like a YouTube channel. You are using youtube-dl for your download. Currently, MacYTDL cannot download channels with youtube-dl." from table "MacYTDL"
			display dialog theYTChannelLabel buttons {theButtonReturnLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
			if skip_Main_dialog is true then
				error number -128
			end if
			main_dialog()
		end if
	end if
	
	-- Seventh, use simulated YTDL/yt-dlp run to look for errors reported back by YTDL, such as invalid URL which would otherwise stop MacYTDL
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
				set playlist_Simulate to do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; " & DL_Use_YTDLP & " --flat-playlist " & DL_Playlist_Items_Spec & YTDL_Use_Cookies & YTDL_No_Warnings & URL_user_entered_clean_quoted
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
				main_dialog()
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
				repeat with x from 1 to count paragraphs of playlist_Simulate
					if contents of paragraph x of playlist_Simulate begins with "[youtube:tab] Playlist" then
						set PL_simulate_Paragraph to paragraph (x) of playlist_Simulate
						exit repeat
					end if
				end repeat
				--set AppleScript's text item delimiters to {": Downloading", " videos"}       -- <== This code changed on 16/1/23
				set AppleScript's text item delimiters to {": Downloading ", " items "}
				set playlist_Number_Items to text item 2 of PL_simulate_Paragraph as integer
				set AppleScript's text item delimiters to {""}
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
					main_dialog()
				end if
			end if
		else if DL_Parallel is true then
			set parallel_playlist to true
			set playlist_Name to "Parallel playlist"
			-- User wants to download playlist in parallel - do a simulate but get different data back using --print to get playlist name, item URLs and item names - send output to file - show an alert first
			set playListAlertActionLabel to quoted form of "_"
			set playListAlertTitle to quoted form of (localized string "MacYTDL" from table "MacYTDL")
			set playListAlertMessage to quoted form of (localized string "  Please wait." from table "MacYTDL")
			set playListAlertSubtitle to quoted form of (localized string "Now checking detail of playlist. " from table "MacYTDL")
			set alerterPiD to do shell script quoted form of (resourcesPath & "alerter") & " -message " & playListAlertMessage & " -title " & playListAlertTitle & " -subtitle " & playListAlertSubtitle & " -sender com.apple.script.id.MacYTDL -actions " & playListAlertActionLabel & " -timeout 20 > /dev/null 2> /dev/null & echo $!"
			try
				do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --print '%(playlist_title)s##%(webpage_url)s##%(title)s.%(ext)s' " & DL_Playlist_Items_Spec & YTDL_No_Warnings & YTDL_Use_Cookies & URL_user_entered_clean_quoted & " 2>&1 &>" & YTDL_simulate_file & " ; exit 0"
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
				main_dialog()
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
			set playlist_Simulate to do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; " & DL_Use_YTDLP & " --flat-playlist " & DL_Playlist_Items_Spec & YTDL_Use_Cookies & YTDL_No_Warnings & URL_user_entered_clean_quoted
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
			main_dialog()
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
				main_dialog()
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
			main_dialog()
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
			main_dialog()
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
			main_dialog()
		end if
		set DL_formats_list to false
	end if
	
	-- Do a simulation to get back file names, get is_live status and disclose any errors or warnings
	-- URLs to iView and OnDemand show pages causes error => takes processing to Get_ABC_Episodes or Get_SBS_Episodes handlers
	-- If desired file format not available, advise user and ask what to do
	-- Other kinds of errors are reported to user asking what to do
	-- Takes a long time when simulating channels and playlists - users are warned earlier
	-- Exclude playlists when user has request parallel downloads - simulate file already contains required data
	set simulate_YTDL_output_template to run_Utilities_handlers's replace_chars(YTDL_output_template, " -o '%", " -o '%(is_live)s#%")
	if parallel_playlist is false then
		do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & YTDL_format_pref & DL_Playlist_Items_Spec & YTDL_credentials & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_No_Warnings & simulate_YTDL_output_template & " " & URL_user_entered_clean_quoted & " 2>&1 &>" & YTDL_simulate_file & " ; exit 0"
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
				main_dialog()
			end if
			set YTDL_Custom_Template to ""
			set YTDL_output_template to " -o '%(is_live)s#%(title)s.%(ext)s'"
		end if
		do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & YTDL_no_playlist & DL_Playlist_Items_Spec & YTDL_format_pref & YTDL_credentials & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_No_Warnings & simulate_YTDL_output_template & " " & URL_user_entered_clean_quoted & " 2>&1 &>" & YTDL_simulate_file & " ; exit 0"
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
		main_dialog()
	else if YTDL_simulate_log contains "Unsupported URL: https://7Plus.com.au" then
		set theURLWarning7PlusLabel to localized string "This is a 7Plus movie or a show page from which MacYTDL cannot download videos. If it's a show page, try an individual episode." from table "MacYTDL"
		display dialog theURLWarning7PlusLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		main_dialog()
	end if
	if YTDL_simulate_log contains "Unsupported URL: https://www.9now.com.au/live" then
		set theURLWarning7PlusLabel to localized string "Sorry, this is a 9Now live stream page from which MacYTDL cannot download videos." from table "MacYTDL"
		display dialog theURLWarning7PlusLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		main_dialog()
	else if YTDL_simulate_log contains "Unsupported URL: https://www.9now.com.au" then
		set theURLWarning9NowLabel to localized string "This is a 9Now Show page from which MacYTDL cannot download videos. Try an individual episode." from table "MacYTDL"
		display dialog theURLWarning9NowLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		main_dialog()
	end if
	if YTDL_simulate_log contains "Unsupported URL: https://10play.com.au/live" then
		set theURLWarning7PlusLabel to localized string "Sorry, this is a 10Play live stream page from which MacYTDL cannot download videos." from table "MacYTDL"
		display dialog theURLWarning7PlusLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		main_dialog()
	else if YTDL_simulate_log contains "Unsupported URL: https://10play.com.au" then
		set theURLWarning10playLabel to localized string "This is a 10Play Show page from which MacYTDL cannot download videos. Try an individual episode." from table "MacYTDL"
		display dialog theURLWarning10playLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		if skip_Main_dialog is true then
			error number -128
		end if
		main_dialog()
	end if
	-- Requested format not available - tell user - simulate again if necessary
	if YTDL_simulate_log contains "requested format not available" then
		set theFormatNotAvailLabel1 to localized string "Your preferred file format is not available. Would you like to cancel download and return, have your download remuxed into your preferred format or just download the best format available ?" from table "MacYTDL"
		set theFormatNotAvailLabel2 to localized string "{Note: 3gp format is not available - a request for 3gp will be remuxed into mp4.}" from table "MacYTDL"
		set theFormatNotAvailButtonRemuxLabel to localized string "Remux" from table "MacYTDL"
		set quit_or_return to button returned of (display dialog theFormatNotAvailLabel1 & return & theFormatNotAvailLabel2 buttons {theButtonReturnLabel, theFormatNotAvailButtonRemuxLabel, theButtonDownloadLabel} default button 3 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
		if quit_or_return is theButtonReturnLabel then
			main_dialog()
		else if quit_or_return is theButtonDownloadLabel then
			-- User wants to download the best format available so, set desired format to null - simulate again to get file name into simulate file 
			do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename " & YTDL_no_playlist & DL_Playlist_Items_Spec & YTDL_credentials & YTDL_No_Warnings & URL_user_entered_clean_quoted & " " & simulate_YTDL_output_template & " > /dev/null" & " &> " & YTDL_simulate_file
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
			do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename " & YTDL_no_playlist & DL_Playlist_Items_Spec & YTDL_credentials & YTDL_No_Warnings & URL_user_entered_clean_quoted & " " & simulate_YTDL_output_template & " > /dev/null" & " &> " & YTDL_simulate_file
			set YTDL_format to ""
			set remux_format_choice to DL_format
			if YTDL_format_pref is "3gp" then
				set remux_format_choice to "mp4"
			end if
			set YTDL_remux_format to "--recode-video " & remux_format_choice & " " & "--postprocessor-args \"-codec copy\" "
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
				set theURLErrorTextLabel4 to localized string theURLErrorTextLabelString & " " & "'" & playlist_Name & "':"
			else
				set theURLErrorTextLabel4 to ":"
			end if
			set theURLErrorTextLabel1 to localized string "There was an error with the URL you entered" from table "MacYTDL"
			set theURLErrorTextLabel2 to localized string "The error message was: " from table "MacYTDL"
			if skip_Main_dialog is true then
				set theURLErrorTextLabel3 to localized string "OK to give up or Download to try anyway." from table "MacYTDL"
				set quit_or_return to button returned of (display dialog theURLErrorTextLabel1 & " " & theURLErrorTextLabel4 & return & return & URL_user_entered & return & return & theURLErrorTextLabel2 & return & return & YTDL_simulate_log & return & theURLErrorTextLabel3 buttons {theButtonOKLabel, theButtonDownloadLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
				if quit_or_return is theButtonOKLabel then
					return
				else if quit_or_return is theButtonDownloadLabel then
					-- User wants to try to download ! Processing just continues from here down
				end if
			else
				set theURLErrorTextLabel3 to localized string "Quit, OK to return or Download to try anyway." from table "MacYTDL"
				set quit_or_return to button returned of (display dialog theURLErrorTextLabel1 & theURLErrorTextLabel4 & return & return & URL_user_entered & return & return & theURLErrorTextLabel2 & return & return & YTDL_simulate_log & return & theURLErrorTextLabel3 buttons {theButtonQuitLabel, theButtonOKLabel, theButtonDownloadLabel} default button 2 cancel button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
				if quit_or_return is theButtonOKLabel then
					main_dialog()
				else if quit_or_return is theButtonDownloadLabel then
					-- User wants to try to download ! Processing just continues from here down
				end if
			end if
		end if
	end if
	if YTDL_simulate_log contains "IOError: CRC check failed" then
		set theURLErrorTextLabel1 to localized string "There was an error with the URL you entered. The video might be DRM protected or it could be a network, VPN or macOS install issue. If the URL is correct, you may need to look more deeply into your network settings and macOS install." from table "MacYTDL"
		display dialog theURLErrorTextLabel1 buttons {theButtonOKLabel} with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		main_dialog()
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
		set branch_execution to run_Utilities_handlers's Get_ABC_Episodes(URL_user_entered, diag_Title, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, X_position, screen_height, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, theButtonReturnLabel, skip_Main_dialog, path_to_MacYTDL)
		if branch_execution is "Main" then main_dialog()
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
				main_dialog()
			else if skip_or_return is theButtonContinueLabel then
				set DL_formats_list to false
			end if
		end if
	end if
	
	-- *******************************************************************************************************************************************************
	-- v1.24 - Added workaround for SBS bug in yt-dlp - v1.26: removed test on is_SBS_bug_page
	--if YTDL_simulate_log contains "Unsupported URL: https://www.sbs.com.au/ondemand" or is_SBS_bug_page is true then
	-- if URL_user_entered contains "ondemand" then -- <<== v1.27 - Used for testing new SBS Chooser - just skips simulate stage
	-- *******************************************************************************************************************************************************
	if YTDL_simulate_log contains "Unsupported URL: https://www.sbs.com.au/ondemand" then
		-- If user uses URL from 'Featured' episode on a SBS Show page, trim trailing text of URL and treat like a Show page - NB Some featured videos are supported by youtube-dl/yt-dlp
		if URL_user_entered contains "?action=play" then
			set URL_user_entered to (text 1 thru -14 of URL_user_entered & "'")
		end if
		-- youtube-dl/yt-dlp cannot download from some SBS show links - mostly on the OnDemand home and search pages
		if YTDL_simulate_log contains "?play=" or URL_user_entered contains "ondemand/search" then
			set theOnDemandURLProblemLabel to localized string "MacYTDL cannot download video from an SBS OnDemand \"Play\" or Search links. Navigate to a \"Show\" page and try again." from table "MacYTDL"
			display dialog theOnDemandURLProblemLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 100
			if skip_Main_dialog is true then
				error number -128
			end if
			main_dialog()
		else
			set check_URL_ID to last word of URL_user_entered
			set length_check_URL_ID to length of check_URL_ID
			try
				set check_URL_number to check_URL_ID as number
				set is_ID to true
			on error errText number errNum
				set is_ID to false
			end try
			
			-- *******************************************************************************************************************************************************
			-- v1.26: commented out
			-- Form up URL and get file name - single URL for a particular video
			--			if is_SBS_bug_page is true then
			--				set URL_user_entered to ("https://www.sbs.com.au/api/v3/video_smil?id=" & check_URL_ID)
			--				set SBS_show_name to "This is a bug URL"
			--				set number_ABC_SBS_episodes to 1
			--				set SBS_workaround_page to do shell script "curl " & URL_user_entered
			--				if SBS_workaround_page contains "abstract" then
			--					set AppleScript's text item delimiters to {"title=\"", "\" abstract="}
			--					set download_filename to (text item 2 of SBS_workaround_page) & ".mp4"
			--				else
			--					set AppleScript's text item delimiters to {"title=\"", "\" copyright="}
			--					set download_filename to (text item 2 of SBS_workaround_page) & ".mp4"
			--				end if
			--				set AppleScript's text item delimiters to ""
			--				set download_filename_new to run_Utilities_handlers's replace_chars(download_filename, " ", "_")
			--				set download_date_time to get_Date_Time()
			--				set YTDL_log_file to MacYTDL_preferences_path & "youtube-dl_log-" & download_filename_new & "-" & download_date_time & ".txt"
			--				if YTDL_remux_format contains "recode" then set YTDL_remux_format to ""
			--				set YTDL_output_template to "-o '" & download_filename_new & ".%(ext)s'"
			--				-- If URL ends in a video ID and is not a "watch" URL, then user copied URL from an SBS "play" button - form into a watch URL and process without calling SBS chooser
			--			else if is_ID is true and length_check_URL_ID is greater than 7 and URL_user_entered does not contain "watch" then
			if is_ID is true and length_check_URL_ID is greater than 7 and URL_user_entered does not contain "watch" then
				set URL_user_entered to ("https://www.sbs.com.au/ondemand/watch/" & check_URL_ID)
				set SBS_show_name to "This is a watcher URL"
				set number_ABC_SBS_episodes to 1
			else
				
				-- The URL from an SBS Show Page - get the user to choose which episodes to download
				set branch_execution to run_Utilities_handlers's Get_SBS_Episodes(URL_user_entered, diag_Title, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, X_position, screen_height, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, theButtonReturnLabel, skip_Main_dialog, path_to_MacYTDL)
				
				if branch_execution is "Main" then
					main_dialog()
				else
					set SBS_show_URLs to branch_execution
				end if
				
				set SBS_show_indicator to "Yes"
				set URL_user_entered to SBS_show_URLs
				-- Bang a warning if user specifies needing a format list and selects more than one SBS episode
				set AppleScript's text item delimiters to " "
				set number_ABC_SBS_episodes to number of text items in SBS_show_URLs
				set AppleScript's text item delimiters to ""
				if number_ABC_SBS_episodes is greater than 1 and DL_formats_list is true then
					set theTooManyUELsLabel to localized string "Sorry, but MacYTDL cannot list formats for more than one SBS show. Would you like to cancel the download and return to the main dialog or skip the formats list and continue to download ?" from table "MacYTDL"
					set skip_or_return to button returned of (display dialog theTooManyUELsLabel buttons {theButtonReturnLabel, theButtonContinueLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
					if skip_or_return is theButtonReturnLabel then
						if skip_Main_dialog is true then
							error number -128
						end if
						main_dialog()
					else if skip_or_return is theButtonContinueLabel then
						set DL_formats_list to false
					end if
				end if
			end if
		end if
	end if
	
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
			set_File_Names(shellPath, YTDL_simulate_log, URL_user_entered, ABC_show_name, SBS_show_name, DL_Use_YTDLP, parallel_playlist)
		else if warning_quit_or_continue is theWarningButtonsMainLabel then -- <= Stop and return to Main dialog
			if skip_Main_dialog is true then
				error number -128
			end if
			main_dialog()
		end if
	else
		-- This is a non-warning download
		-- v1.24 add "set URL_user_entered to" because for some reason the URL_user_entered variable going forward in this handler is the old value instead of the value set in set_File_Names - affected SBS chooser cases which are workarounds
		set URL_user_entered to set_File_Names(shellPath, YTDL_simulate_log, URL_user_entered, ABC_show_name, SBS_show_name, DL_Use_YTDLP, parallel_playlist)
	end if
	--	end if
	
	-- If user asked for subtitles, get ytdl/yt-dlp to check whether they are available - if not, warn user - if available, check against format requested - convert if different
	-- v1.21.2, added URL_user_entered to variables specifically passed - fixes SBS OnDemand subtitles error - don't know why
	if subtitles_choice is true or DL_YTAutoST is true then
		set YTDL_subtitles to check_subtitles_download_available(shellPath, diag_Title, subtitles_choice, URL_user_entered, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, MacYTDL_custom_icon_file, DL_Use_YTDLP, theBestLabel)
	end if
	
	-- Call the formats chooser if in settings and no conflict with other settings - chosen_formats_list is returned containing the format ids to be requested and whether merged or not
	-- Currently just return a string but, maybe it would be better to return a list - although this handler would still need the try block for separating items
	-- If branch_execution is "Skip", download will proceed without formats specified
	-- v1.26 - Decided to put get_formats_list() into separate script file - because it is only script that requires Myriad Tables Lib
	set YTDL_formats_to_download to ""
	if DL_formats_list is true then
		set download_filename_formats to quoted form of download_filename
		set chosen_formats_list to ""
		set formats_reported to ""
		-- Need to get path to get_formats_list script file then run get_formats_list()
		set path_to_Formats_Chooser to (path_to_MacYTDL & "Contents:Resources:Scripts:Formats.scpt") as alias
		set run_Formats_Chooser_Handler to load script path_to_Formats_Chooser
		set chosen_formats_list to run_Formats_Chooser_Handler's formats_Chooser(URL_user_entered, diag_Title, theButtonCancelLabel, theButtonDownloadLabel, X_position, screen_height, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, theButtonReturnLabel, skip_Main_dialog, path_to_MacYTDL, DL_Use_YTDLP, shellPath, download_filename_formats, YTDL_credentials, window_Position, formats_reported, is_Livestream_Flag)
		-- Parse data returned from get_formats_list to separate out the formats list in the format "nnn+nnn" or "nnn,nnn %(format_id)s" 
		set AppleScript's text item delimiters to " "
		set branch_execution to text item 1 of chosen_formats_list
		set format_id_output_template to ""
		if branch_execution is "Main" then
			main_dialog()
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
	set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_Thumbnail_Write & YTDL_Thumbnail_Embed & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & " " & YTDL_formats_to_download & " ")
	
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
					set offset_to_file_name to last_offset(each_filename, "/") + 2
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
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & " " & YTDL_formats_to_download & " ")
						else if overwrite_continue_choice is theABCShowExistsButtonNewnameLabel then
							set YTDL_output_template_new to run_Utilities_handlers's replace_chars(YTDL_output_template, ".%(ext)s", "-2.%(ext)s")
							set set_new_download_filename to text 1 thru -5 of download_filename_new
							set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, set_new_download_filename, set_new_download_filename & "-2")
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template_new & " " & YTDL_QT_Compat & " " & YTDL_formats_to_download & " ")
						else if overwrite_continue_choice is theButtonReturnLabel then
							if DL_auto is false then
								my main_dialog()
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
					set offset_to_file_name to last_offset(each_filename, "/") + 2
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
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & " " & YTDL_formats_to_download & " ")
						else if overwrite_continue_choice is theShowExistsButtonNewnameLabel then
							set YTDL_output_template_new to run_Utilities_handlers's replace_chars(YTDL_output_template, ".%(ext)s", "-2.%(ext)s")
							set set_new_download_filename to text 1 thru -5 of download_filename_new
							set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, set_new_download_filename, set_new_download_filename & "-2")
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template_new & " " & YTDL_QT_Compat & " " & YTDL_formats_to_download & " ")
						else if overwrite_continue_choice is theButtonReturnLabel then
							if DL_auto is false then
								my main_dialog()
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
					set offset_to_file_name to last_offset(each_filename, "/") + 2
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
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & " " & YTDL_formats_to_download & " ")
						else if overwrite_continue_choice is theShowExistsButtonNewnameLabel then
							set YTDL_output_template_new to run_Utilities_handlers's replace_chars(YTDL_output_template, ".%(ext)s", "-2.%(ext)s")
							set set_new_download_filename to text 1 thru -5 of download_filename_new
							set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, set_new_download_filename, set_new_download_filename & "-2")
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template_new & " " & YTDL_QT_Compat & " " & YTDL_formats_to_download & " ")
						else if overwrite_continue_choice is theButtonReturnLabel then
							if DL_auto is false then
								my main_dialog()
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
	if DL_batch_status is true then
		add_To_Batch(URL_user_entered, download_filename, download_filename_new, YTDL_remux_format)
		-- add_To_Batch(URL_user_entered, download_filename)  -- Changed on 10/2/23
		-- add_To_Batch(URL_user_entered, download_filename_new, YTDL_remux_format) - v1.26 - need download_filname for multiple URL cases
	end if
	
	-- Prepare to call on the download Monitor - first get Monitor script location -- Monitor-bundle.scptd
	set myMonitorScriptAsString to quoted form of ((POSIX path of path_to_MacYTDL) & "Contents/Resources/Scripts/Monitor.scpt")
	
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
		set branch_execution to run_Utilities_handlers's show_settings(YTDL_subtitles, DL_Remux_original, DL_YTDL_auto_check, DL_STEmbed, DL_audio_only, YTDL_description, DL_Limit_Rate, DL_over_writes, DL_Thumbnail_Write, DL_verbose, DL_Thumbnail_Embed, DL_Add_Metadata, DL_Use_Proxy, DL_Use_Cookies, DL_Use_Custom_Template, DL_Use_Custom_Settings, remux_format_choice, DL_TimeStamps, DL_Use_YTDLP, DL_Parallel, DL_discard_URL, DL_Dont_Use_Parts, DL_No_Warnings, YTDL_version, folder_chosen, theButtonQuitLabel, theButtonCancelLabel, theButtonDownloadLabel, DL_Show_Settings, MacYTDL_prefs_file, MacYTDL_custom_icon_file_posix, diag_Title)
		if branch_execution is "Main" then main_dialog()
		if branch_execution is "Settings" then set_settings()
		if branch_execution is "Quit" then quit_MacYTDL()
	end if
	
	
	-- PRODUCTION CALL - Call the download Monitor script which will run as a separate process and return so Main Dialog can be re-displayed - thus user can start any number of downloads
	do shell script "osascript -s s " & myMonitorScriptAsString & " " & my_params & " " & " > /dev/null 2> /dev/null &"
	
	--	try
	--		--		-- TESTING CALL - Call the download Monitor script for testing - this formulation gets any errors back from Monitor, but holds execution until Monitor dialog is dismissed
	-- do shell script "osascript -s s " & myMonitorScriptAsString & " " & my_params & " 2>&1"
	--	on error errMSG
	--		display dialog "errMSG: " & errMSG
	--	end try
	
	
	-- After download, reset ABC & SBS URLs, show name and number_ABC_SBS_episodes so that correct file name is used for next download	
	-- v1.26 - Decided to change behaviour - retain/discard URL after a download
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
		main_dialog()
	end if
	
end download_video


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
			main_dialog()
		else if quit_or_return is theButtonQuitLabel then
			quit_MacYTDL()
		end if
	end try
	-- If user clicks "Continue" processing returns to after call to this handler and download process commences
end check_cookies_file


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
					main_dialog()
				end if
			else if quit_or_return is theButtonQuitLabel then
				quit_MacYTDL()
			end if
			check_download_folder(folder_chosen, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, diag_Title, MacYTDL_custom_icon_file, skip_Main_dialog)
		end try
	end if
	-- If user clicks "Continue" processing returns to after call to this handler and download process commences
end check_download_folder


------------------------------------------------------------
--
-- 	Try to get correct file names for use elsewhere
--
------------------------------------------------------------
on set_File_Names(shellPath, YTDL_simulate_log, URL_user_entered, ABC_show_name, SBS_show_name, DL_Use_YTDLP, parallel_playlist)
	
	-- Set download_filename_new which is used to show a name in the Monitor dialog and forms basis for log file name
	-- Set download_filename which is used by Adviser to open downloaded file (called download_filename_monitor)
	-- Reformat file name and add to name of log files - converting spaces to underscores to reduce need for quoting throughout code
	
	set num_paragraphs_log to count of paragraphs of YTDL_simulate_log
	set AppleScript's text item delimiters to " "
	set number_of_URLs to number of text items in URL_user_entered
	set AppleScript's text item delimiters to ""
	
	-- Get date and time so it can be added to log file name
	set download_date_time to get_Date_Time()
	
	-- First, look for non-iView show pages (but iView non-error single downloads are included)
	-- Trim extension off download filename that is in the simulate file - not implemented as it involves lots of changes to the following code
	--set download_filename_no_ext to text 1 thru ((YTDL_simulate_log's length) - (offset of "." in (the reverse of every character of YTDL_simulate_log) as text)) of YTDL_simulate_log
	if ABC_show_name is "" and SBS_show_name is "" then -- not an ABC or SBS show page
		if number_of_URLs is 1 and parallel_playlist is false then -- Single file download or playlist to be downloaded serially
			set download_filename to YTDL_simulate_log
			if YTDL_simulate_log does not contain "WARNING:" and YTDL_simulate_log does not contain "ERROR:" then --<= A single file or playlist download non-error and non-warning (iView and non-iView)
				if num_paragraphs_log is 2 then --<= A single file download (iView and non-iView) - need to trim ".mp4<para>" from end of file (which is a single line containing one file name)
					if YTDL_simulate_log contains "/" then
						set offsetOfLastSlash to last_offset(YTDL_simulate_log, "/") + 2
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
			
			
			
		else --<= This is a multiple file (iView and non-iView) download - don't distinguish between iView and others - covers warning and non-warning cases also parallel downloads
			
			
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
					set download_date_time to get_Date_Time()
					set YTDL_log_file to MacYTDL_preferences_path & "ytdl_log-" & download_filename_new & "-" & download_date_time & ".txt"
					-- if YTDL_remux_format contains "recode" then set YTDL_remux_format to ""  -- Poinless as YTDL_remux_format is not sent to this handler and is not global
					set YTDL_output_template to "-o '" & download_filename_new & ".%(ext)s'"
				else
					set theSBSsimulateFailedLabel to localized string "Something went wrong trying to download from SBS. The error was: " from table "MacYTDL"
					display dialog (theSBSsimulateFailedLabel & return & return & errMSG) buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
					main_dialog()
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
					main_dialog()
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


-----------------------------------------------------------------------
--
-- 		Check subtitles are available and in desired language
--
-----------------------------------------------------------------------
-- Handler to check that requested subtitles are available and apply conversion if not - called by download_video() when user requests subtitles or auto-subtitles
-- Might not need the duplication in this handler - leave till a later release - Handles ABC, SBS show URL and multiple URLs somewhat
on check_subtitles_download_available(shellPath, diag_Title, subtitles_choice, URL_user_entered, theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel, MacYTDL_custom_icon_file, DL_Use_YTDLP, theBestLabel)
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
	-- If user asked only for auto generated subtitles, warn if URL is not YouTube
	if auto_gen is true and author_gen is false and URL_for_subtitles_test does not contain "YouTube" and URL_for_subtitles_test does not contain "YouTu.be" then
		set theAutoSTWillNotWorkLabel to localized string "You have specified auto-generated subtitles but not from Youtube. It will not work. Do you want to try author generated subtitles, continue without subtitles or cancel this download and return to the Main dialog ?" from table "MacYTDL"
		set theButtonContinueGoAuthorLabel to localized string "Try author" from table "MacYTDL"
		set auto_subtitles_stop_or_continue to button returned of (display dialog theAutoSTWillNotWorkLabel buttons {theButtonContinueGoAuthorLabel, theButtonContinueLabel, theButtonReturnLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
		if auto_subtitles_stop_or_continue is theButtonReturnLabel then
			main_dialog()
		else if auto_subtitles_stop_or_continue is theButtonContinueGoAuthorLabel then
			set author_gen to true
			set auto_gen to false
		else if auto_subtitles_stop_or_continue is theButtonContinueLabel then
			set auto_gen to false
			return YTDL_subtitles
		end if
	end if
	
	-- If user asked for subtitles, get ytdl to check whether they are available - if not, warn user if so, test for kind and language
	set check_subtitles_available to do shell script shellPath & DL_Use_YTDLP & " --list-subs --ignore-errors " & URL_for_subtitles_test
	if check_subtitles_available does not contain "Language  formats" and check_subtitles_available does not contain "Language formats" and check_subtitles_available does not contain "Language Name" then
		set theSTNotAvailableLabel1 to localized string "There is no subtitle file available for your video (although it might be embedded)." from table "MacYTDL"
		set theSTNotAvailableLabel2 to localized string "You can quit, stop and return or download anyway." from table "MacYTDL"
		set subtitles_quit_or_continue to button returned of (display dialog theSTNotAvailableLabel1 & return & return & theSTNotAvailableLabel2 buttons {theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel} default button 3 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
		if subtitles_quit_or_continue is theButtonQuitLabel then
			quit_MacYTDL()
		else if subtitles_quit_or_continue is theButtonReturnLabel then
			main_dialog()
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
				main_dialog()
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
				main_dialog()
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
				quit_MacYTDL()
			else if subtitles_quit_or_continue is theButtonReturnLabel then
				main_dialog()
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
						main_dialog()
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
	--	set theCheckboxQTCompatLabel to localized string "QT compatible video" from table "MacYTDL"
	--	set {settings_theCheckbox_QT_Compat, theTop} to create checkbox theCheckboxQTCompatLabel left inset 70 bottom (theTop + 3) max width 200 initial state DL_QT_Compat
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
	set theLabeledPopupRemuxFormatLabel to localized string "Remux format:" from table "MacYTDL"
	if DL_Use_YTDLP is "yt-dlp" then
		set {settings_thePopUp_RemuxFormat, settings_remuxlabel, theTop} to create labeled popup {theNoRemuxLabel, "avi", "flv", "gif", "mkv", "mov", "mp4", "webm"} left inset 70 bottom (theTop + 3) popup width 100 max width 200 label text theLabeledPopupRemuxFormatLabel popup left 70 initial choice DL_Remux_format
	else
		set {settings_thePopUp_RemuxFormat, settings_remuxlabel, theTop} to create labeled popup {theNoRemuxLabel, "mp4", "mkv", "flv", "webm", "avi", "ogg"} left inset 70 bottom (theTop + 3) popup width 100 max width 200 label text theLabeledPopupRemuxFormatLabel popup left 70 initial choice DL_Remux_format
	end if
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
	set settings_allControls to {theSettingsRule, settings_theCheckbox_Use_CustomSettings, settings_theField_Custom_Settings, settings_theCheckbox_Use_CustomTemplate, settings_theField_Custom_Template, settings_theCheckBox_Use_Cookies, settings_theCookiesLocationPathControl, settings_theCheckBox_Use_Proxy, settings_theField_ProxyURL, settings_theCheckbox_Original, settings_thePopUp_RemuxFormat, settings_remuxlabel, settings_theCheckbox_Formats, settings_theCheckbox_Metadata, settings_theCheckbox_ThumbEmbed, settings_theCheckbox_ThumbWrite, settings_theCheckbox_AutoSubTitles, settings_thePopUp_SubTitlesFormat, settings_STFormatlabel, settings_theField_STLanguage, settings_language_label, settings_theCheckbox_STEmbed, settings_theCheckbox_SubTitles, settings_theCheckbox_AudioOnly, settings_theCheckbox_OverWrites, settings_thePopup_AudioCodec, settingsCodecLabel, settings_theCheckbox_Description, theSettingsAdminRule, settings_thePopUp_Resolution_Limit, settings_resolutionlabel, settings_thePopUp_FileFormat, settings_formatlabel, settings_thePathControl, settings_pathLabel, MacYTDL_icon, settings_prompt, theSettingsSTEndRule}
	
	-- Make sure MacYTDL is in front and show dialog - need to make dialog wider in some languages - use width returned from right most control
	tell me to activate
	if (popupSTFormatLeftDist + 50) is greater than accViewWidth then
		set calculatedAccViewWidth to (popupSTFormatLeftDist + 60)
	else
		set calculatedAccViewWidth to accViewWidth
	end if
	if (BoxCustSetLeftDist + 250) is greater than calculatedAccViewWidth then
		set calculatedAccViewWidth to (BoxCustSetLeftDist + 250)
	end if
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
		set settings_remux_format_choice to item 11 of settings_controls_results -- <= Remux format choice
		-- set settings_choice_12 to item 12 of settings_controls_results -- <= The Remux format popup label
		set settings_formats_list_choice to item 13 of settings_controls_results -- <= Get formats list choice
		set settings_metadata_choice to item 14 of settings_controls_results -- <= Add metadata choice
		set settings_thumb_embed_choice to item 15 of settings_controls_results -- <= Embed Thumbnails choice
		set settings_thumb_write_choice to item 16 of settings_controls_results -- <= Write Thumbnails choice
		set settings_autoST_choice to item 17 of settings_controls_results -- <= Auto-gen subtitles choice
		set settings_subtitlesformat_choice to item 18 of settings_controls_results -- <= Subtitles format choice
		-- set settings_STFormatlabel_choice to item 19 of settings_controls_results -- <= Subtitles format popup label
		set settings_subtitleslanguage_choice to item 20 of settings_controls_results -- <= Subtitles language choice
		-- set settings_subtitleslanguage_21 to item 21 of settings_controls_results -- <= Subtitles language field label
		set settings_stembed_choice to item 22 of settings_controls_results -- <= Embed subtitles choice
		set settings_subtitles_choice to item 23 of settings_controls_results -- <= Subtitles choice
		set settings_audio_only_choice to item 24 of settings_controls_results -- <= Audio only choice
		set settings_forceOW_choice to item 25 of settings_controls_results -- <= Force overwrites choice
		set settings_audio_codec_choice to item 26 of settings_controls_results -- <= Audio codec choice
		-- set settings_audiocodec_27 to item 27 of settings_controls_results -- <= Audio codec field label
		set settings_description_choice to item 28 of settings_controls_results -- <= Description choice
		-- set settings_choice_29 to item 29 of settings_controls_results -- <= The Admin rule
		set settings_resolution_choice to item 30 of settings_controls_results -- <= Maximum resolution choice
		-- set settings_choice_31 to item 31 of settings_controls_results -- <= The Format popup label
		set settings_format_choice to item 32 of settings_controls_results -- <= File format choice
		-- set settings_choice_33 to item 33 of settings_controls_results -- <= The Format popup label
		set settings_folder_choice to item 34 of settings_controls_results -- <= The download path choice
		-- set settings_choice_35 to item 35 of settings_controls_results -- <= The Path label
		-- set settings_choice_36 to item 36 of settings_controls_results -- <= The MacYTDL icon
		-- set settings_choice_37 to item 37 of settings_controls_results -- <= The Settings label
		-- set settings_choice_38 to item 38 of settings_controls_results -- <= The Subtitles end rule
		
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
				set value of property list item "Remux_Format" to settings_remux_format_choice
				set value of property list item "Resolution_Limit" to settings_resolution_choice
				set value of property list item "SubTitles" to settings_subtitles_choice
				set value of property list item "Subtitles_Format" to settings_subtitlesformat_choice
				set value of property list item "Subtitles_Language" to settings_subtitleslanguage_choice
				set value of property list item "Subtitles_YTAuto" to settings_autoST_choice
				set value of property list item "Thumbnail_Write" to settings_thumb_write_choice
				set value of property list item "SubTitles_Embedded" to settings_stembed_choice
			end tell
		end tell
		
		-- User wants a formats list - v1.26: check that Myriad Tables Lib is installed - if user switches off formats list toggle the saved setting - formats list and auto download seem to be compatible after all
		-- v1.26.1 – For some reaosn, formats list and auto download now crash on Sonoma as well as Monterey, but not Ventura - decided not to block for now
		if settings_formats_list_choice is true then
			if Myriad_exists is false then
				set theInstallMyriadTextLabel to localized string "MacYTDL needs a code library installed in your Libraries folder. It cannot show the \"Formats List\" without that library. Do you wish to install ?" from table "MacYTDL"
				set install_Myriad to button returned of (display dialog theInstallMyriadTextLabel buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
				if install_Myriad is theButtonYesLabel then
					run_Utilities_handlers's install_Myriad(Myriad_file, path_to_MacYTDL, resourcesPath)
					set Myriad_exists to true
					-- Now can go ahead and set the formats list setting
					tell application "System Events"
						tell property list file MacYTDL_prefs_file
							set value of property list item "Get_Formats_List" to true
						end tell
					end tell
				end if
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
			else
				tell application "System Events"
					tell property list file MacYTDL_prefs_file
						set value of property list item "Get_Formats_List" to true
					end tell
				end tell
			end if
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
			set offset_to_file_name to last_offset(settings_folder_choice as text, "/")
			set settings_folder_choice to text 1 thru offset_to_file_name of settings_folder_choice
		end if
		-- Now can go ahead and set the download folder setting
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "DownloadFolder" to settings_folder_choice
			end tell
		end tell
		
		-- Check for invalid choice of subtitles and embedding and if OK, save to preferences file -- v1.26 - Found no need to write subtitles
		--		if settings_subtitles_choice is false and settings_autoST_choice is false and settings_stembed_choice is true then
		--			set theSTsEmbeddedTogetherLabel to localized string "Sorry, you need to turn on subtitles if you want them embedded." from table "MacYTDL"
		--			display dialog theSTsEmbeddedTogetherLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		--			set_settings()
		--		end if
		
		-- Check for invalid choice of subtitles embedding and file format - v1.26 - Specific file format or remux not necessary for embedding subtitles
		--		if settings_stembed_choice is true and (settings_format_choice is not "mp4" and settings_format_choice is not "mkv" and settings_format_choice is not "webm" and settings_remux_format_choice is not "webm" and settings_remux_format_choice is not "mkv" and settings_remux_format_choice is not "mp4") then
		--			set theSTsEmbeddedFileformatLabel to localized string "Sorry, File format or Remux format must be mp4, mkv or webm for subtitles to be embedded." from table "MacYTDL"
		--			display dialog theSTsEmbeddedFileformatLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		--			set_settings()
		--		end if
		--		-- Now can go ahead and set the subtitles embedding settings
		--		tell application "System Events"
		--			tell property list file MacYTDL_prefs_file
		--				set value of property list item "SubTitles_Embedded" to settings_stembed_choice
		--			end tell
		--		end tell
		
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
			set branch_execution to run_Utilities_handlers's set_admin_settings(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version, MacYTDL_custom_icon_file, theButtonCancelLabel, window_Position, theButtonReturnLabel, MacYTDL_custom_icon_file_posix)
			if branch_execution is "Main" then main_dialog()
			if branch_execution is "Settings" then set_settings()
		end if
	end if
	
	main_dialog()
	
end set_settings


---------------------------------------------------
--
-- 		Check for youtube-dl/yt-dlp updates
--
---------------------------------------------------

-- Handler to check and update yt-dlp if user wishes - called by Utilities dialog to update script and switch to yt-dlp, the auto check on startup and the Warning dialog
-- v1.24 – Added code to enable switch from Homebrew to MacYTDL yt-dlp install
on check_ytdl(show_yt_dlp)
	-- Get version of yt-dlp available from GitHub - which has a different name to what is used by MacYTDL - get legacy version for users on 10.9-10.15 - Not called if user has Homebrew
	-- v1.24 - no longer offer to update youtube-dl
	set YTDL_site_URL to "https://github.com/yt-dlp/yt-dlp/releases"
	if show_yt_dlp is "yt-dlp" then
		set name_of_executable to "yt-dlp_macos"
	else if show_yt_dlp is "yt-dlp-legacy" then
		set name_of_executable to "yt-dlp_macos_legacy"
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
		main_dialog()
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
		main_dialog()
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
				set YTDL_update_text to "A new version of " & show_yt_dlp & " is available. You have version " & installedYTDL_version & ". The latest version is " & YTDL_version_check & return & return & "Would you like to install it now ?"
			end if
			tell me to activate
			set YTDL_install_answ to button returned of (display dialog YTDL_update_text buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if YTDL_install_answ is theButtonYesLabel then
				set installAlertActionLabel to quoted form of "_"
				set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
				set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
				set installAlertSubtitle to quoted form of ((localized string "Download and install of " from table "MacYTDL") & show_yt_dlp)
				do shell script resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
				try
					if homebrew_ytdlp_exists is true then
						do shell script "rm /usr/local/bin/yt-dlp" with administrator privileges
					end if
					do shell script "curl -L " & YTDL_site_URL & "/download/" & YTDL_version_check & "/" & name_of_executable & " -o /usr/local/bin/yt-dlp" with administrator privileges
				on error errMSG
					if errMSG does not contain "User canceled" then
						display dialog "There was an error in downloading the yt-dlp update. The error reported was " & errMSG
					end if
					main_dialog()
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


--------------------------------------------------------------------------
--
-- 		Are FFMpeg/FFprobe up-to-date - fork to relevant handler
--
--------------------------------------------------------------------------

-- Handler for forking FFmpeg & FFprobe version checks to ARM or Intel handlers - called by "Check for FFmpeg update" in Utilities Dialog
on check_ffmpeg()
	if user_system_arch is "Intel" then
		if show_yt_dlp is "yt-dlp-legacy" then
			check_ffmpeg_intel_OLD()
		else
			check_ffmpeg_intel()
		end if
	else
		check_ffmpeg_arm()
	end if
end check_ffmpeg

--------------------------------------------------------------------------
--
-- 		Are FFMpeg/FFprobe up-to-date - Intel
--
--------------------------------------------------------------------------

-- Handler for updating FFmpeg & FFprobe - called by "Check for FFmpeg update" in Utilities Dialog - assumes always have same version of both tools - NOW GETTING FFMPEG FROM MARTIN RIEDL'S SITE
on check_ffmpeg_intel()
	-- Get version of FFmpeg currently installed
	set ffmpeg_version_long to do shell script ffmpeg_file & " -version"
	set ffprobe_version_long to do shell script ffprobe_file & " -version"
	set AppleScript's text item delimiters to {"-", " "}
	set ffmpeg_version to text item 3 of ffmpeg_version_long
	set ffprobe_version to text item 3 of ffprobe_version_long
	set AppleScript's text item delimiters to ""
	set theFFmpegAlertUpToDateLabel to localized string "FFmpeg and FFprobe are up to date. Your installed version is " from table "MacYTDL"
	set alert_text_ffmpeg to theFFmpegAlertUpToDateLabel & ffmpeg_version
	-- Get version of FFmpeg available from web site - is also proxy for FFprobe version
	set ffmpeg_site to "https://ffmpeg.martin-riedl.de"
	try
		set FFmpeg_page to do shell script "curl " & ffmpeg_site & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
	on error errMSG
		set theFFmpegCurlErrorLabel to localized string "There was an error with looking for the FFmpeg web page. The error was: " & errMSG & ", and the URL that produced the error was: " & ffmpeg_site & ". Try again later and/or send a message to macytdl@gmail.com with the details." from table "MacYTDL"
		display dialog theFFmpegCurlErrorLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		main_dialog()
	end try
	-- Trap case in which user is offline
	if FFmpeg_page is "" then
		set theFFmpegDownloadProblemLabel to localized string "There was a problem with accessing FFmpeg. Perhaps you are not connected to the internet or the server is currently not available. Try again later." from table "MacYTDL"
		display dialog theFFmpegDownloadProblemLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		main_dialog()
	else
		set AppleScript's text item delimiters to {"macOS (Intel/amd64)"}
		set release_build_text_FFmpeg to paragraph 2 of text item 3 of FFmpeg_page
		set AppleScript's text item delimiters to {" "}
		set release_build_version_FFmpeg to text item 2 of release_build_text_FFmpeg
		set AppleScript's text item delimiters to {""}
		if release_build_version_FFmpeg is not equal to ffmpeg_version or release_build_version_FFmpeg is not equal to ffprobe_version then
			set theFFmpegOutDatedTextLabel1 to localized string "FFmpeg is out of date. You have version " from table "MacYTDL"
			set theFFmpegOutDatedTextLabel2 to localized string "The latest version is " from table "MacYTDL"
			set theFFmpegOutDatedTextLabel3 to localized string "Would you like to update it now ? If yes, this will also update FFprobe. Note: You may need to provide administrator credentials." from table "MacYTDL"
			set ffmpeg_install_text to theFFmpegOutDatedTextLabel1 & ffmpeg_version & ". " & theFFmpegOutDatedTextLabel2 & release_build_version_FFmpeg & return & return & theFFmpegOutDatedTextLabel3
			tell me to activate
			set ffmpeg_install_answ to button returned of (display dialog ffmpeg_install_text buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if ffmpeg_install_answ is theButtonYesLabel then
				run_Utilities_handlers's install_ffmpeg_ffprobe_intel(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os)
				set theFFmpegProbeAlertUpDatedLabel to localized string "FFmpeg and FFprobe have been updated. Your new version is " from table "MacYTDL"
				set alert_text_ffmpeg to theFFmpegProbeAlertUpDatedLabel & ffmpeg_version
			else
				set theFFmpegProbeAlertOutOfDateLabel to localized string "FFmpeg is out of date. Your installed version is " from table "MacYTDL"
				set alert_text_ffmpeg to "" & ffmpeg_version
			end if
		end if
	end if
end check_ffmpeg_intel

-- Install FFmpeg for users on macOS 10.14 and earlier
on check_ffmpeg_intel_OLD()
	-- Get version of FFmpeg currently installed
	set ffmpeg_version_long to do shell script ffmpeg_file & " -version"
	set ffprobe_version_long to do shell script ffprobe_file & " -version"
	set AppleScript's text item delimiters to {"-", " "}
	set ffmpeg_version to text item 3 of ffmpeg_version_long
	set ffprobe_version to text item 3 of ffprobe_version_long
	set AppleScript's text item delimiters to ""
	set theFFmpegAlertUpToDateLabel to localized string "FFmpeg and FFprobe are up to date. Your installed version is " from table "MacYTDL"
	set alert_text_ffmpeg to theFFmpegAlertUpToDateLabel & ffmpeg_version
	-- Get version of FFmpeg available from web site - is also proxy for FFprobe version
	set ffmpeg_site to "https://evermeet.cx/pub/ffmpeg/"
	try
		set FFmpeg_page to do shell script "curl " & ffmpeg_site & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
	on error errMSG
		set theFFmpegCurlErrorLabel to localized string "There was an error with looking for the FFmpeg web page. The error was: " & errMSG & ", and the URL that produced the error was: " & ffmpeg_site & ". Try again later and/or send a message to macytdl@gmail.com with the details." from table "MacYTDL"
		display dialog theFFmpegCurlErrorLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		main_dialog()
	end try
	-- Trap case in which user is offline
	if FFmpeg_page is "" then
		set theFFmpegDownloadProblemLabel to localized string "There was a problem with accessing FFmpeg. Perhaps you are not connected to the internet or the server is currently not available. Try again later." from table "MacYTDL"
		display dialog theFFmpegDownloadProblemLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		main_dialog()
	else
		set ffmpeg_version_start to (offset of "version" in FFmpeg_page) + 8
		set ffmpeg_version_end to (offset of "-tessus" in FFmpeg_page) - 1
		set ffmpeg_version_check to text ffmpeg_version_start thru ffmpeg_version_end of FFmpeg_page
		if ffmpeg_version_check is not equal to ffmpeg_version or ffmpeg_version_check is not equal to ffprobe_version then
			set theFFmpegOutDatedTextLabel1 to localized string "FFmpeg is out of date. You have version " from table "MacYTDL"
			set theFFmpegOutDatedTextLabel2 to localized string "The latest version is " from table "MacYTDL"
			set theFFmpegOutDatedTextLabel3 to localized string "Would you like to update it now ? If yes, this will also update FFprobe. Note: You may need to provide administrator credentials." from table "MacYTDL"
			set ffmpeg_install_text to theFFmpegOutDatedTextLabel1 & ffmpeg_version & ". " & theFFmpegOutDatedTextLabel2 & ffmpeg_version_check & return & return & theFFmpegOutDatedTextLabel3
			tell me to activate
			set ffmpeg_install_answ to button returned of (display dialog ffmpeg_install_text buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if ffmpeg_install_answ is theButtonYesLabel then
				run_Utilities_handlers's install_ffmpeg_ffprobe_intel_OLD(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os)
				set theFFmpegProbeAlertUpDatedLabel to localized string "FFmpeg and FFprobe have been updated. Your new version is " from table "MacYTDL"
				set alert_text_ffmpeg to theFFmpegProbeAlertUpDatedLabel & ffmpeg_version
			else
				set theFFmpegProbeAlertOutOfDateLabel to localized string "FFmpeg is out of date. Your installed version is " from table "MacYTDL"
				set alert_text_ffmpeg to "" & ffmpeg_version
			end if
		end if
	end if
end check_ffmpeg_intel_OLD


--------------------------------------------------------------------------
--
-- 		Are FFMpeg/FFprobe up-to-date - ARM
--
--------------------------------------------------------------------------

-- Handler for updating FFmpeg & FFprobe - called by "Check for FFmpeg update" in Utilities Dialog - assumes always have same version of both tools
on check_ffmpeg_arm()
	-- Get version of FFmpeg currently installed
	set ffmpeg_version_long to do shell script ffmpeg_file & " -version"
	set ffprobe_version_long to do shell script ffprobe_file & " -version"
	set AppleScript's text item delimiters to {"-", " "}
	set ffmpeg_version to text item 3 of ffmpeg_version_long
	set ffprobe_version to text item 3 of ffprobe_version_long
	set AppleScript's text item delimiters to ""
	set theFFmpegAlertUpToDateLabel to localized string "FFmpeg and FFprobe are up to date. Your installed version is " from table "MacYTDL"
	set alert_text_ffmpeg to theFFmpegAlertUpToDateLabel & ffmpeg_version
	-- Get version of FFmpeg available from web site - is also proxy for FFprobe version
	set ffmpeg_site to "https://ffmpeg.martin-riedl.de"
	try
		set FFmpeg_page to do shell script "curl " & ffmpeg_site & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
	on error errMSG
		set theFFmpegCurlErrorLabel to localized string "There was an error with looking for the FFmpeg web page. The error was: " & errMSG & ", and the URL that produced the error was: " & ffmpeg_site & ". Try again later and/or send a message to macytdl@gmail.com with the details." from table "MacYTDL"
		display dialog theFFmpegCurlErrorLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		main_dialog()
	end try
	-- Trap case in which user is offline
	if FFmpeg_page is "" then
		set theFFmpegDownloadProblemLabel to localized string "There was a problem with accessing FFmpeg. Perhaps you are not connected to the internet or the server is currently not available. Try again later." from table "MacYTDL"
		display dialog theFFmpegDownloadProblemLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		main_dialog()
	else
		set AppleScript's text item delimiters to {"macOS (Apple Silicon/arm64)"}
		set release_build_text_FFmpeg to paragraph 2 of text item 3 of FFmpeg_page
		set AppleScript's text item delimiters to {" "}
		set release_build_version_FFmpeg to text item 2 of release_build_text_FFmpeg
		set AppleScript's text item delimiters to {""}
		if release_build_version_FFmpeg is not equal to ffmpeg_version or release_build_version_FFmpeg is not equal to ffprobe_version then
			set theFFmpegOutDatedTextLabel1 to localized string "FFmpeg is out of date. You have version " from table "MacYTDL"
			set theFFmpegOutDatedTextLabel2 to localized string "The latest version is " from table "MacYTDL"
			set theFFmpegOutDatedTextLabel3 to localized string "Would you like to update it now ? If yes, this will also update FFprobe. Note: You may need to provide administrator credentials." from table "MacYTDL"
			set ffmpeg_install_text to theFFmpegOutDatedTextLabel1 & ffmpeg_version & ". " & theFFmpegOutDatedTextLabel2 & release_build_version_FFmpeg & return & return & theFFmpegOutDatedTextLabel3
			tell me to activate
			set ffmpeg_install_answ to button returned of (display dialog ffmpeg_install_text buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if ffmpeg_install_answ is theButtonYesLabel then
				run_Utilities_handlers's install_ffmpeg_ffprobe_arm(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os)
				set theFFmpegProbeAlertUpDatedLabel to localized string "FFmpeg and FFprobe have been updated. Your new version is " from table "MacYTDL"
				set alert_text_ffmpeg to theFFmpegProbeAlertUpDatedLabel & ffmpeg_version
			else
				set theFFmpegProbeAlertOutOfDateLabel to localized string "FFmpeg is out of date. Your installed version is " from table "MacYTDL"
				set alert_text_ffmpeg to "" & ffmpeg_version
			end if
		end if
	end if
end check_ffmpeg_arm


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
	set macYTDL_Atomic_file to ("usr:local:bin:AtomicParsley" as text)
	tell application "System Events"
		if (exists file macYTDL_Atomic_file) then
			set Atomic_is_installed to true
		else
			set Atomic_is_installed to false
		end if
	end tell
	
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
		set {utilities_theCheckbox_SwitchFFmpeg, theTop} to create label " " left inset accViewInset + 5 bottom (theTop - 17) max width minWidth - 100 aligns right aligned
	end if
	-- v1.27.1 - Hide FFmpeg update facility for users on OS X 10.10, 10.11 & 10.12 - they cannot use FFmpeg more recent than v6.0 (28/2/23), which is now installed by default
	if homebrew_ffmpeg_exists is false and user_on_old_os is false then
		set theCheckBoxCheckFFmpegLabel to localized string "Check for FFmpeg update" from table "MacYTDL"
		set theCheckBoxCheckFFmpegversion to theCheckBoxCheckFFmpegLabel & "   " & "(" & FFMpeg_version_installed & ")"
		set {utilities_theCheckbox_FFmpeg_Check, theTop} to create checkbox theCheckBoxCheckFFmpegversion left inset accViewInset bottom (theTop + 5) max width 250
	else
		set {utilities_theCheckbox_FFmpeg_Check, theTop} to create label " " left inset accViewInset + 5 bottom (theTop - 17) max width minWidth - 100 aligns left aligned
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
		set {utilities_theCheckbox_Switch_Scripts, theTop} to create label " " left inset accViewInset + 5 bottom (theTop - 17) max width minWidth - 100 aligns right aligned
		set utilities_DL_Use_YTDLP to "yt-dlp"
	end if
	
	-- Spanish, and I guess other languages, prefer different word order to English so, the old form was poor - anyway, youtube-dl is mostly dead
	--	set theCheckBoxOpenYTDLLabel to (localized string "Open" from table "MacYTDL") & " " & utilities_DL_Use_YTDLP & " " & (localized string "web page" from table "MacYTDL")
	set theCheckBoxOpenYTDLLabel to (localized string "Open yt-dlp web page" from table "MacYTDL")
	set {utilities_theCheckbox_YTDL_release, theTop} to create checkbox theCheckBoxOpenYTDLLabel left inset accViewInset bottom (theTop + 5) max width 200
	
	-- v1.24 - Hide yt-dlp updater if user currently using Homebrew or youtube-dl
	-- v1.25 - Provide for yt-dlp nightly builds
	if ytdlp_exists is true and (DL_Use_YTDLP is "yt-dlp" or DL_Use_YTDLP is "yt-dlp-legacy") then
		if ytdlp_kind is "stable" then
			set theCheckBoxCheckYTDLNightlyLabel to (localized string "Install" from table "MacYTDL") & " " & (localized string "nightly build" from table "MacYTDL")
			set theCheckBoxCheckYTDLNightlyVersion to theCheckBoxCheckYTDLNightlyLabel
			set theCheckBoxCheckYTDLLabel to (localized string "Update" from table "MacYTDL") & " " & (localized string "stable build" from table "MacYTDL")
			set theCheckBoxCheckYTDLversion to theCheckBoxCheckYTDLLabel & " " & "(" & theYTDLVersionInstalledlabel & ")"
			set minWidth to 465
		end if
		if ytdlp_kind is "nightly" then
			set theCheckBoxCheckYTDLNightlyLabel to (localized string "Update" from table "MacYTDL") & " " & (localized string "nightly build" from table "MacYTDL")
			set theCheckBoxCheckYTDLNightlyVersion to theCheckBoxCheckYTDLNightlyLabel & " " & "(" & theYTDLVersionInstalledlabel & ")"
			set theCheckBoxCheckYTDLLabel to (localized string "Install" from table "MacYTDL") & " " & (localized string "stable build" from table "MacYTDL")
			set theCheckBoxCheckYTDLversion to theCheckBoxCheckYTDLLabel
			set minWidth to 500
		end if
		set theCheckBoxDoNotUpdateYTDLLabel to localized string "Do not update" from table "MacYTDL"
		set theCheckBoxDoNotUpdateYTDLTextLabel to localized string "Update" from table "MacYTDL"
		set {utilities_theMatrix_YTDL_Check, theMatrixLabel, theTop, theMatrixWidth} to create labeled matrix {theCheckBoxDoNotUpdateYTDLLabel, theCheckBoxCheckYTDLversion, theCheckBoxCheckYTDLNightlyVersion} initial choice 1 bottom (theTop + 5) label text "yt-dlp" matrix left 100 max width 600
	else
		set {utilities_theCheckbox_YTDL_Check, theTop} to create label " " left inset accViewInset + 5 bottom (theTop - 17) max width minWidth - 100 aligns left aligned with multiline
		set {theMatrixLabel, theTop} to create label " " left inset accViewInset + 5 bottom (theTop - 17) max width minWidth - 100 aligns left aligned with multiline
		set {utilities_theMatrix_YTDL_Check, theTop} to create label " " left inset accViewInset + 5 bottom (theTop - 17) max width minWidth - 100 aligns left aligned with multiline
	end if
	set theCheckBoxOpenDLFolderLabel to localized string "Open download folder" from table "MacYTDL"
	set {utilities_theCheckbox_DL_Open, theTop} to create checkbox theCheckBoxOpenDLFolderLabel left inset accViewInset bottom (theTop + 5) max width 250
	set theCheckBoxOpenLogFolderLabel to localized string "Open log folder" from table "MacYTDL"
	set {utilities_theCheckbox_Logs_Open, theTop} to create checkbox theCheckBoxOpenLogFolderLabel left inset accViewInset bottom (theTop + 5) max width 250
	set {utilities_instruct, theTop} to create label instructions_text left inset accViewInset + 5 bottom (theTop + 10) max width minWidth - 100 aligns left aligned with multiline
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 50 view width 64 view height 64 scale image scale proportionally
	set {utilities_prompt, theTop} to create label utilities_diag_prompt left inset 0 bottom (theTop) max width minWidth aligns center aligned with bold type
	set utilities_allControls to {theUtilitiesRule, utilities_theCheckbox_Service_Install, utilities_theCheckbox_Atomic_Install, utilities_theCheckbox_SwitchFFmpeg, utilities_theCheckbox_FFmpeg_Check, utilities_theCheckbox_MacYTDL_Check, utilities_theCheckbox_Return_Defaults, utilities_theCheckbox_Restore_Settings, utilities_theCheckbox_Save_Settings, utilities_theCheckbox_Switch_Scripts, utilities_theCheckbox_YTDL_release, theMatrixLabel, utilities_theMatrix_YTDL_Check, utilities_theCheckbox_DL_Open, utilities_theCheckbox_Logs_Open, MacYTDL_icon, utilities_instruct, utilities_prompt}
	
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
		set utilities_FFmpeg_switch_choice to item 4 of utilities_controls_results -- <= Switch FFmpeg architecture
		set utilities_FFmpeg_check_choice to item 5 of utilities_controls_results -- <= Check FFmpeg version choice
		set utilities_MacYTDL_check_choice to item 6 of utilities_controls_results -- <= Check MacYTDL version choice
		set utilities_Return_Defaults_choice to item 7 of utilities_controls_results -- <= Return to default settings choice
		set utilities_Restore_Settings_choice to item 8 of utilities_controls_results -- <= Restore saved settings choice
		set utilities_Save_Settings_choice to item 9 of utilities_controls_results -- <= Save current settings choice
		set utilities_Switch_choice to item 10 of utilities_controls_results -- <= Switch downloaders choice
		set utilities_YTDL_webpage_choice to item 11 of utilities_controls_results -- <= Show YTDL/yt-dlp web page choice
		--set utilities_choice_12 to item 12 of utilities_controls_results -- <= Contains matrix label text
		set utilities_YTDL_check_choice to item 13 of utilities_controls_results -- <= Check/Install yt-dlp stable/nightly build
		set utilities_DL_folder_choice to item 14 of utilities_controls_results -- <= Open download folder choice
		set utilities_log_folder_choice to item 15 of utilities_controls_results -- <= Open log folder choice
		--set utilities_choice_16 to item 16 of utilities_controls_results -- <= Missing value [the icon]
		--set utilities_choice_17 to item 17 of utilities_controls_results -- <= Contains the "Instructions" text
		--set utilities_choice_18 to item 18 of utilities_controls_results -- <= Contains the "Utilities" heading
		
		-- Open log folder
		if utilities_log_folder_choice is true then
			-- Open the log folder in a Finder window positioned away from the MacYTDL main dialog which will re-appear
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
		-- v.25 - This section redesigned to handle installation/update of yt-dlp nightly builds
		if utilities_YTDL_check_choice contains "build" and utilities_FFmpeg_check_choice is true then
			set alert_text_ytdl to "NotSwitching"
			if utilities_YTDL_check_choice contains "stable" then
				check_ytdl(DL_Use_YTDLP)
			else if utilities_YTDL_check_choice contains "nightly" then
				-- Install nightly build - no need to check version as nightly builds are released almost every 24 hours
				try
					do shell script shellPath & " yt-dlp --update-to nightly" with administrator privileges
					-- trap case where user cancels credentials dialog
				on error number -128
					main_dialog()
				end try
				set YTDL_version to do shell script shellPath & " yt-dlp --version"
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
				check_ffmpeg()
			end if
			tell me to activate
			display dialog alert_text_ytdl & return & alert_text_ffmpeg with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		else if utilities_FFmpeg_check_choice is true and utilities_YTDL_check_choice contains "Do not update" then
			if ffmpeg_version is "Not installed" then
				run_Utilities_handlers's install_ffmpeg_ffprobe(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, resourcesPath, MacYTDL_custom_icon_file, user_on_old_os, user_system_arch, user_on_mid_os)
				set theFFmpegProbeInstalledAlertLabel to localized string "FFmpeg and FFprobe have been installed." from table "MacYTDL"
				set alert_text_ffmpeg to theFFmpegProbeInstalledAlertLabel
			else
				check_ffmpeg()
			end if
			tell me to activate
			display dialog alert_text_ffmpeg & return & return with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
			-- else if (utilities_YTDL_check_choice contains "Update yt-dlp stable" and utilities_FFmpeg_check_choice is not true then
		else if utilities_YTDL_check_choice contains "build" and utilities_FFmpeg_check_choice is not true then
			set alert_text_ytdl to "NotSwitching"
			if utilities_YTDL_check_choice contains "stable" then
				check_ytdl(DL_Use_YTDLP)
			else if utilities_YTDL_check_choice contains "nightly" then
				-- Install nightly build
				try
					do shell script shellPath & " yt-dlp --update-to nightly" with administrator privileges
					-- trap case where user cancels credentials dialog
				on error number -128
					main_dialog()
				end try
				set YTDL_version to do shell script shellPath & " yt-dlp --version"
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
				check_ytdl(show_yt_dlp)
			end if
			
			-- User currently using YTDL but has Homebrew install of yt-dlp - silently switch to the Homebrew install - use PATH to find both Intel and ARM Homebrew installs - hopefully a rare case
			if ytdlp_exists is false and homebrew_ytdlp_exists is true then
				set thePreferMainOrBrewYTDLPInstallTextLabel to localized string "You currently have a Homebrew install of yt-dlp. Do you wish to switch to a MacYTDL install ?" from table "MacYTDL"
				set choiceMainOrBrewYTDL to button returned of (display dialog thePreferMainOrBrewYTDLPInstallTextLabel with title diag_Title buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with icon file MacYTDL_custom_icon_file giving up after 600)
				if choiceMainOrBrewYTDL is theButtonYesLabel then
					check_ytdl(show_yt_dlp)
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
			set DL_Saved_Settings_Location_Alias to DL_Saved_Settings_Location as alias
			try
				set save_settings_file_name to (choose file name with prompt "Save MacYTDL Settings" & return & "Enter a file name and choose a location" default location DL_Saved_Settings_Location_Alias default name "Name for your saved settings")
			on error number -128 -- If user cancels, go back to Main dialog
				main_dialog()
			end try
			set save_settings_file_name_text to save_settings_file_name as text
			if text -5 thru -1 of save_settings_file_name_text is not "plist" then
				set save_settings_file_name_posix to quoted form of ((POSIX path of save_settings_file_name) & ".plist") -- Need quoted posix form to pass to do shell script
			else
				set save_settings_file_name_posix to quoted form of (POSIX path of save_settings_file_name)
			end if
			do shell script "cp -a " & MacYTDL_prefs_file & " " & save_settings_file_name_posix
			delay 1
			set last_colon_in_path to last_offset(save_settings_file_name_text, ":")
			set path_to_saved_settings_location to text 1 thru last_colon_in_path of save_settings_file_name_text
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Saved_Settings_Location" to path_to_saved_settings_location
				end tell
			end tell
		end if
		
		-- Restore settings from file - store restored settings name - is a literal OK for type ? - Keep current save settings location instead of what might be in restored settings file
		if utilities_Restore_Settings_choice is true then
			set DL_Saved_Settings_Location_Alias to DL_Saved_Settings_Location as alias
			-- v1.22 - Added repeat loop to prevent error on cp
			repeat
				try
					set restore_settings_file_name to choose file with prompt "Choose a settings file to restore:" default location DL_Saved_Settings_Location_Alias of type "plist"
				on error number -128 -- If user cancels, go back to Main dialog
					main_dialog()
					exit repeat
				end try
				set restore_settings_file_name_text to restore_settings_file_name as text
				set restore_settings_file_name_posix to quoted form of (POSIX path of restore_settings_file_name) -- Need quoted posix form to pass to do shell script
				if restore_settings_file_name_posix = quoted form of MacYTDL_prefs_file then
					set theCannotRestoreLabel to localized string "Sorry, can't restore settings file to itself. Try again ?" from table "MacYTDL"
					set restore_or_giveup to button returned of (display dialog theCannotRestoreLabel with title diag_Title buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with icon file MacYTDL_custom_icon_file giving up after 600)
					if restore_or_giveup is theButtonNoLabel then
						main_dialog()
						exit repeat
					end if
				else
					exit repeat
				end if
			end repeat
			
			set last_colon_in_path to last_offset(restore_settings_file_name_text, ":")
			set last_stop_in_path to last_offset(restore_settings_file_name_text, ".")
			set restored_settings_name to text (last_colon_in_path + 2) thru last_stop_in_path of restore_settings_file_name_text
			do shell script "cp -a " & restore_settings_file_name_posix & " " & MacYTDL_prefs_file
			run_Utilities_handlers's check_settings(MacYTDL_prefs_file, old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, theNoRemuxLabel, resourcesPath, show_yt_dlp, YTDL_version)
			-- Need to ensure restored settings are compatible with v1.21 and newer
			run_Utilities_handlers's check_settings_current(MacYTDL_prefs_file, DL_Use_YTDLP, MacYTDL_preferences_path, youtubedl_file, ytdlp_file)
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Name_Of_Settings_In_Use" to restored_settings_name
					set value of property list item "Saved_Settings_Location" to DL_Saved_Settings_Location
				end tell
			end tell
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
		
		-- Install/Remove Atomic Parsely
		if utilities_Atomic_choice is true then
			if Atomic_is_installed is false then
				if DL_Use_YTDLP is "yt-dlp" then
					set theDontNeedAPTextLabel to localized string "You are currently using yt-dlp and so there is no need for Atomic Parsley. Do you still wish to install Atomic Parsley ?" from table "MacYTDL"
					set reallyWantsAP to button returned of (display dialog theDontNeedAPTextLabel with title diag_Title buttons {theButtonNoLabel, theButtonYesLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600)
					if reallyWantsAP is theButtonNoLabel then main_dialog()
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
					set theAutoDLisOnLabel to localized string "You have the Auto downloads setting on. You can cancel and return to Main dialog or remove the Service and turn off auto downloads." from table "MacYTDL"
					set reallyWantsAPRemoved to button returned of (display dialog theAutoDLisOnLabel with title diag_Title buttons {theButtonReturnLabel, theButtonRemoveLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600)
					if reallyWantsAPRemoved is theButtonReturnLabel then main_dialog()
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
		
		-- Move all log files to Trash - split moves because mv fails "too many args" if there are too many files - try loop in case one of mv commands fails to find any files
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
	else if utilities_button_number_returned is 2 then
		set theUtilitiesUninstallLabel to localized string "Do you really want to remove MacYTDL ? Everything will be moved to the Trash." from table "MacYTDL"
		set really_remove_MacYTDL to display dialog theUtilitiesUninstallLabel buttons {theButtonYesLabel, theButtonNoLabel} with title diag_Title default button 2 with icon file MacYTDL_custom_icon_file giving up after 600
		set remove_answ to button returned of really_remove_MacYTDL
		if remove_answ is theButtonNoLabel then
			main_dialog()
		end if
		try
			-- If it exists, move AtomicParsley to Trash
			if Atomic_is_installed is true then
				do shell script "mv /usr/local/bin/AtomicParsley" & " ~/.trash/AtomicParsley" with administrator privileges
			end if
			if YTDL_exists is true then
				do shell script "mv " & POSIX path of youtubedl_file & " ~/.trash/youtube-dl" with administrator privileges
			end if
			if ytdlp_exists is true then
				do shell script "mv " & POSIX path of ytdlp_file & " ~/.trash/yt-dlp" with administrator privileges
			end if
			if ffprobe_exists is true then
				do shell script "mv " & POSIX path of ffprobe_file & " ~/.trash/ffprobe" with administrator privileges
			end if
			if ffmpeg_exists is true then
				do shell script "mv " & POSIX path of ffmpeg_file & " ~/.trash/ffmpeg" with administrator privileges
			end if
			if Myriad_exists is true then
				do shell script "mv " & quoted form of (POSIX path of Myriad_file) & " ~/.trash/MyriadTablesLib.scptd" with administrator privileges -- Quoted form because of space in "Script Libraries" folder name
			end if
			set path_to_macytdl_file to quoted form of (POSIX path of path_to_MacYTDL)
			do shell script "mv " & path_to_macytdl_file & " ~/.trash/MacYTDL.app" with administrator privileges
			-- trap case where user cancels credentials dialog
		on error number -128
			main_dialog()
		end try
		do shell script "mv " & POSIX path of MacYTDL_preferences_path & " ~/.trash/MacYTDL"
		do shell script "mv " & quoted form of (POSIX path of DTP_file) & " ~/.trash/DialogToolkitMacYTDL.scptd" -- Quoted form because of space in "Script Libraries" folder name
		-- If it exists, move the MacYTDL Service to Trash - Ditto the Defaults plist file
		set User_defaults_path to "Library/Preferences/com.apple.script.id.MacYTDL.plist"
		set macYTDL_defaults_preferences_file to (POSIX path of (path to home folder) & User_defaults_path)
		if isServiceInstalled is "Yes" then
			do shell script "mv " & quoted form of (macYTDL_service_file) & " ~/.trash/Send-URL-To-MacYTDL.workflow"
		end if
		tell application "System Events"
			if (the file macYTDL_defaults_preferences_file exists) then
				tell current application to do shell script "mv " & quoted form of (macYTDL_defaults_preferences_file) & " ~/.trash/com.apple.script.id.MacYTDL.plist"
			end if
		end tell
		set theUtilitiesMYTDLUninstalledLabel to localized string "MacYTDL is uninstalled. All components are in the Trash which you can empty when you wish. Cheers." from table "MacYTDL"
		set theUtilitiesMYTDLUninstalledByeLabel to localized string "Goodbye" from table "MacYTDL"
		set MacYTDL_custom_icon_file_Trash to (path_to_home_folder & ".Trash:MacYTDL.app:Contents:Resources:MacYTDL.icns") as string
		display dialog theUtilitiesMYTDLUninstalledLabel buttons {theUtilitiesMYTDLUninstalledByeLabel} default button 1 with icon file MacYTDL_custom_icon_file_Trash giving up after 600
		error number -128
		
		-- Show the About MacYTDL dialog
	else if utilities_button_number_returned is 3 then -- About
		my show_about()
	end if
	
	main_dialog()
	
end utilities


---------------------------------------------------------------------
--
-- 		Display About dialog - invoked in Utilities dialog
--
---------------------------------------------------------------------

-- Show user the About MacYTDL dialog
on show_about()
	-- Set variables for the settings dialog	
	set theButtonsAbout1Label to (localized string "MacYTDL is a simple AppleScript program for downloading videos from various web sites. It uses the" from table "MacYTDL") & " " & DL_Use_YTDLP & " " & (localized string "Python script as the download engine." from table "MacYTDL")
	set about_text_1 to theButtonsAbout1Label
	set theButtonsAbout2Label to localized string "Please post any questions or suggestions to github.com/section83/MacYTDL/issues" from table "MacYTDL"
	set theButtonsAbout3Label to localized string "Written by © Vincentius, " from table "MacYTDL"
	set theButtonsAbout4Label to localized string "With thanks to Shane Stanley, Adam Albrec, kopurando, Michael Page, Tombs and all MacYTDL users." from table "MacYTDL"
	set about_text_2 to theButtonsAbout2Label & return & return & theButtonsAbout3Label & MacYTDL_date & ". " & theButtonsAbout4Label
	set theButtonsAboutDiagLabel to localized string "About MacYTDL" from table "MacYTDL"
	set about_diag_prompt to theButtonsAboutDiagLabel
	set accViewWidth to 300
	set accViewInset to 0
	
	-- Set buttons and controls
	set theButtonsVisitLabel to localized string "Visit Site" from table "MacYTDL"
	set theButtonsEmailLabel to localized string "Send E-Mail" from table "MacYTDL"
	set {theButtons, minWidth} to create buttons {theButtonsVisitLabel, theButtonsEmailLabel, theButtonOKLabel} button keys {"v", "e", ""} default button 3
	if minWidth > accViewWidth then set accViewWidth to minWidth -- make sure buttons fit
	set {about_Rule, theTop} to create rule 10 rule width accViewWidth
	set {about_instruct_2, theTop} to create label about_text_2 left inset 5 bottom (theTop + 10) max width accViewWidth aligns left aligned with multiline
	set {about_instruct_1, theTop} to create label about_text_1 left inset 75 bottom (theTop + 10) max width accViewWidth - 75 aligns left aligned with multiline
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 60 view width 64 view height 64 scale image scale proportionally
	set {about_prompt, theTop} to create label about_diag_prompt left inset 0 bottom (theTop) max width minWidth aligns center aligned with bold type
	set about_allControls to {about_Rule, MacYTDL_icon, about_instruct_1, about_instruct_2, about_prompt}
	
	-- Make sure MacYTDL is in front and show dialog
	tell me to activate
	set {about_button_returned, about_button_number_returned, about_controls_results} to display enhanced window diag_Title buttons theButtons acc view width accViewWidth acc view height theTop acc view controls about_allControls
	if about_button_number_returned is 3 then -- OK
		main_dialog()
	end if
	-- Open MacYTDL release page (in default web browser) to manually check version
	if about_button_number_returned is 1 then -- Visit Site
		open location "https://github.com/section83/MacYTDL/"
	end if
	-- Open email message to author
	if about_button_number_returned is 2 then -- Send Email
		open location "mailto:macytdl@gmail.com?subject=MacYTDL%20Feedback%2FQuestion"
	end if
end show_about


---------------------------------------------------
--
-- 		Get user's credentials
--
---------------------------------------------------

-- User ticked the runtime settings to include credentials for next download
on get_YTDL_credentials()
	-- Set variables for the get credentials dialog	
	set theCredentialsInstructionsLabel to localized string "Enter your user name and password in the boxes below for the next download, skip credentials and continue to download or return to the Main dialog." from table "MacYTDL"
	set theCredentialsDiagPromptLabel to localized string "Credentials for next download" from table "MacYTDL"
	set instructions_text to theCredentialsInstructionsLabel
	set credentials_diag_prompt to theCredentialsDiagPromptLabel
	set accViewWidth to 275
	set accViewInset to 0
	
	-- Set buttons and controls
	set theButtonsCredSkipLabel to localized string "Skip" from table "MacYTDL"
	set {theButtons, minWidth} to create buttons {theButtonReturnLabel, theButtonsCredSkipLabel, theButtonOKLabel} button keys {"r", "s", ""} default button 3
	set theButtonsCredPasswordLabel to localized string "Password" from table "MacYTDL"
	set {theField_password, theTop} to create field "" placeholder text theButtonsCredPasswordLabel left inset accViewInset bottom 5 field width accViewWidth
	set theButtonsCredNameLabel to localized string "User name" from table "MacYTDL"
	set {theField_username, theTop} to create field "" placeholder text theButtonsCredNameLabel left inset accViewInset bottom (theTop + 20) field width accViewWidth
	set {utilities_instruct, theTop} to create label instructions_text left inset 75 bottom (theTop + 15) max width (accViewWidth - 75) aligns left aligned with multiline
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 60 view width 64 view height 64 scale image scale proportionally
	set {utilities_prompt, theTop} to create label credentials_diag_prompt left inset 0 bottom (theTop + 10) max width accViewWidth aligns center aligned with bold type
	set credentials_allControls to {theField_username, theField_password, MacYTDL_icon, utilities_instruct, utilities_prompt}
	
	-- Make sure MacYTDL is in front and show dialog
	tell me to activate
	set {credentials_button_returned, credentialsButtonNumberReturned, credentials_results} to display enhanced window diag_Title buttons theButtons acc view width accViewWidth acc view height theTop acc view controls credentials_allControls
	
	if credentialsButtonNumberReturned is 3 then
		-- Get control results from credentials dialog
		set theField_username_choice to item 1 of credentials_results -- <= User name
		set theField_password_choice to item 2 of credentials_results -- <= Password
		set YTDL_credentials to "--username " & theField_username_choice & " --password " & theField_password_choice & " "
		return YTDL_credentials
	else if credentialsButtonNumberReturned is 2 then
		-- Continue download without credentials
		set YTDL_credentials to ""
		return YTDL_credentials
	else
		main_dialog()
	end if
end get_YTDL_credentials


---------------------------------------------------
--
-- 	Write current URL(s) to batch file
--
---------------------------------------------------
-- Handler to write the user's pasted URL to the batch file for later download - called from download_video() - returns to main_dialog()
-- Creates file if need, adds URL, file name and remux format and a return each time
on add_To_Batch(URL_user_entered, download_filename, download_filename_new, YTDL_remux_format)
	-- Remove any quotes from around URL_user_entered - so it can be written out to the batch file
	if character 1 of URL_user_entered is "'" then
		set URL_user_entered_lines to text 2 thru -2 of URL_user_entered
	else
		set URL_user_entered_lines to URL_user_entered
	end if
	-- Change spaces to returns when URL_user_entered has more than one URL - then add file name and remux format setting as comment - used by Adviser to play 1st file
	set URL_user_entered_lines to text 1 thru end of (run_Utilities_handlers's replace_chars(URL_user_entered_lines, " ", return))
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
				set download_filename to run_Utilities_handlers's replace_chars(download_filename, old_extension, new_extension)
			else
				set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, old_extension, new_extension)
			end if
		end if
	end if
	set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, "_", " ")
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
		main_dialog()
	end try
	set theAddedToBatchLabel to localized string "The URL has been added to batch file." from table "MacYTDL"
	display dialog theAddedToBatchLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
	-- After adding to batch, reset ABC & SBS show name and number_ABC_SBS_episodes so that correct file name is used for next download
	-- v1.26 - Decided to change behaviour - retain/discard URL after adding to batch
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
	
	main_dialog()
end add_To_Batch


---------------------------------------------------------
--
-- 	Open batch processing dialog - called by Main
--
---------------------------------------------------------
-- Handler to open batch file processing dialog - called by Main dialog
on open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
	
	run_Utilities_handlers's read_settings(MacYTDL_prefs_file)
	set DL_format to localized string DL_format from table "MacYTDL"
	set DL_subtitles_format to localized string DL_subtitles_format from table "MacYTDL"
	set DL_Remux_format to localized string DL_Remux_format from table "MacYTDL"
	set DL_audio_codec to localized string DL_audio_codec from table "MacYTDL"
	
	-- Start by calculating tally of URLs currently saved in the batch file	
	set batch_tally_number to tally_batch()
	
	-- Set variables for the Batch functions dialog
	set theBatchFunctionsInstructionLabel to localized string "Choose to download list of URLs in batch file, clear the batch list, edit the batch list, remove last addition to the batch or return to Main dialog." from table "MacYTDL"
	set theBatchFunctionsDiagPromptLabel to localized string "Batch Functions" from table "MacYTDL"
	set instructions_text to theBatchFunctionsInstructionLabel
	set batch_diag_prompt to theBatchFunctionsDiagPromptLabel
	set accViewWidth to 500
	set accViewInset to 0
	
	-- Set buttons and controls
	set theButtonsEditLabel to localized string "Edit" from table "MacYTDL"
	set theButtonsClearLabel to localized string "Clear" from table "MacYTDL"
	set theButtonsRemoveLabel to localized string "Remove last item" from table "MacYTDL"
	set {theButtons, minWidth} to create buttons {theButtonReturnLabel, theButtonsEditLabel, theButtonsClearLabel, theButtonsRemoveLabel, theButtonDownloadLabel} button keys {"r", "e", "c", "U", "d"} default button 5
	if minWidth > accViewWidth then set accViewWidth to minWidth
	set {theBatchRule, theTop} to create rule 10 rule width accViewWidth
	set theNumberVideosLabel to localized string "Number of videos in batch: " from table "MacYTDL"
	set {batch_tally, theTop} to create label theNumberVideosLabel & batch_tally_number left inset 25 bottom (theTop + 15) max width 225 aligns left aligned
	set {batch_instruct, theTop} to create label instructions_text left inset 75 bottom (theTop + 30) max width minWidth - 75 aligns left aligned with multiline
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 60 view width 64 view height 64 scale image scale proportionally
	set {batch_prompt, theTop} to create label batch_diag_prompt left inset 0 bottom (theTop) max width minWidth aligns center aligned with bold type
	set batch_allControls to {theBatchRule, batch_tally, MacYTDL_icon, batch_instruct, batch_prompt}
	
	-- Make sure MacYTDL is in front and show dialog
	tell me to activate
	set {batch_button_returned, batchButtonNumberReturned, batch_controls_results} to display enhanced window diag_Title buttons theButtons acc view width minWidth acc view height theTop acc view controls batch_allControls initial position window_Position
	
	if batchButtonNumberReturned is 5 then
		-- Eventually, will have code here which will read the batch file and present user with list to choose from
		download_batch(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
	else if batchButtonNumberReturned is 2 then
		-- Check that there is a batch file
		tell application "System Events"
			set batch_file_test to batch_file as string
			if not (exists file batch_file_test) then
				set theNoBatchFileLabel to localized string "Sorry, there is no batch file." from table "MacYTDL"
				display dialog theNoBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
				my main_dialog()
			end if
		end tell
		set batch_file_posix to POSIX path of batch_file
		tell application "System Events" to open file batch_file_posix
		open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
	else if (batchButtonNumberReturned is 3) or ((batchButtonNumberReturned is 4) and (batch_tally_number is 1)) then
		clear_batch(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
	else if batchButtonNumberReturned is 4 then
		remove_last_from_batch(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
	end if
	
	main_dialog()
	
end open_batch_processing


---------------------------------------------------
--
-- 	Calculate tally of URLs saved in batch file
--
---------------------------------------------------
-- Handler to calculate tally of URLs saved in Batch file - called by Batch dialog and maybe Main too
on tally_batch()
	tell application "System Events"
		set batch_file_test to batch_file as string
		if not (exists file batch_file_test) then
			set number_of_URLs to 0
			return number_of_URLs
		end if
	end tell
	if (get eof file batch_file) is 0 then
		set number_of_URLs to 0
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
		main_dialog()
	end try
	return number_of_URLs
end tally_batch


-----------------------------------------------------------------------------
--
-- 	Download videos in Batch file - called by open_batch_processing
--
-----------------------------------------------------------------------------
-- Handler to download selection of URLs in Batch file - forms and calls youtube-dl/yt-dlp separately from the download_video handler
on download_batch(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
	
	-- Check that there is a batch file containing some URLs
	set no_batch_file to false
	set batch_file_test to batch_file as string
	tell application "System Events"
		if not (exists file batch_file_test) then set no_batch_file to true
	end tell
	if no_batch_file is true then
		set theNoBatchFileLabel to localized string "Sorry, there is no batch file." from table "MacYTDL"
		display dialog theNoBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		my open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
	end if
	if (get eof file batch_file) is 0 then
		set theEmptyBatchFileLabel to localized string "Sorry, the batch file is empty." from table "MacYTDL"
		display dialog theEmptyBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600
		open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
	end if
	
	-- Get date and time so it can be added to log file name
	set download_date_time to get_Date_Time()
	
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
			return
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
	
	-- v1.25.1 - added rough logic to get subtitles - previously never passed subtitles settings to the download
	-- If user wants for subtitles, pass current settings to download without checking - it is checked during add_To_batch()
	if subtitles_choice is true and DL_YTAutoST is false then
		set YTDL_subtitles to "--write-sub --sub-format " & DL_subtitles_format & " --sub-lang " & DL_STLanguage & " "
	end if
	if DL_YTAutoST is true and subtitles_choice is false then
		set YTDL_subtitles to "--write-auto-sub --sub-format " & DL_subtitles_format & " --sub-lang " & DL_STLanguage & " "
	end if
	if DL_YTAutoST is true and subtitles_choice is true then
		set YTDL_subtitles to "--write-auto-sub --write-sub --sub-format " & DL_subtitles_format & " --sub-lang " & DL_STLanguage & " "
	end if
	
	set YTDL_batch_file to quoted form of POSIX path of batch_file
	set YTDL_no_playlist to ""
	
	-- Set up download_filename_new to hold data required for parallel download - need to get URL, file name and log file pathname - it's delimited, not a list - repeat through content of batchfile.txt
	-- v1.27 - don't bother with parallel downloads if just one entry in BatchFile.txt
	set number_paragraphs to ((count of paragraphs of batch_file_contents) - 1) -- Always has a blank last paragraph
	if DL_Parallel is true and number_paragraphs is greater than 2 then
		set download_filename_new to ""
		repeat with x from 1 to number_paragraphs
			set AppleScript's text item delimiters to {"#", "$"}
			set download_batch_details to (paragraph x of batch_file_contents)
			set URL_user_entered_for_parallel to text item 1 of download_batch_details
			set download_filename_full to text item 2 of download_batch_details
			-- Trying to remove colons and spaces from file names as it might cause macOS trouble - the strange small colon DOES cause issues
			set download_filename_full to run_Utilities_handlers's replace_chars(download_filename_full, " ", "_")
			--			set download_filename_full to run_Utilities_handlers's replace_chars(download_filename_full, ":", "_-") -- Not sure whether this would make a mess of URLs
			set download_filename_full to run_Utilities_handlers's replace_chars(download_filename_full, "：", "_-")
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
	set download_filename to run_Utilities_handlers's replace_chars(download_filename, "_", " ")
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
		set YTDL_output_template to " -o '%(title)s.%(ext)s'"
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
	
	set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_Resolution_Limit & YTDL_Use_Parts & YTDL_No_Warnings & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_Thumbnail_Write & YTDL_Thumbnail_Embed & YTDL_metadata & YTDL_limit_rate_value & " " & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_Custom_Settings & YTDL_output_template & " " & YTDL_QT_Compat & " " & download_batch_parallel_serial)
	
	set my_params to quoted form of folder_chosen & " " & quoted form of MacYTDL_preferences_path & " " & YTDL_TimeStamps_quoted & " " & ytdl_settings & " " & URL_user_entered & " " & YTDL_log_file & " " & download_filename & " " & download_filename_new & " " & quoted form of MacYTDL_custom_icon_file_posix & " " & monitor_dialog_position & " " & YTDL_simulate_log & " " & diag_Title_quoted & " " & is_Livestream_Flag & " " & screen_width & " " & screen_height & " " & DL_Use_YTDLP & " " & quoted form of path_to_MacYTDL & " " & DL_Delete_Partial & " " & ADL_Clear_Batch
	
	---- Show current download settings if user has specified that in Settings
	if DL_Show_Settings is true then
		set branch_execution to run_Utilities_handlers's show_settings(YTDL_subtitles, DL_Remux_original, DL_YTDL_auto_check, DL_STEmbed, DL_audio_only, YTDL_description, DL_Limit_Rate, DL_over_writes, DL_Thumbnail_Write, DL_verbose, DL_Thumbnail_Embed, DL_Add_Metadata, DL_Use_Proxy, DL_Use_Cookies, DL_Use_Custom_Template, DL_Use_Custom_Settings, remux_format_choice, DL_TimeStamps, DL_Use_YTDLP, DL_Parallel, DL_discard_URL, DL_Dont_Use_Parts, DL_No_Warnings, YTDL_version, folder_chosen, theButtonQuitLabel, theButtonCancelLabel, theButtonDownloadLabel, DL_Show_Settings, MacYTDL_prefs_file, MacYTDL_custom_icon_file_posix, diag_Title)
		if branch_execution is "Main" then main_dialog()
		if branch_execution is "Settings" then set_settings()
		if branch_execution is "Quit" then quit_MacYTDL()
	end if
	
	-- Prepare to call on the download Monitor - first get Monitor script location -- Monitor-bundle.scptd
	set myMonitorScriptAsString to quoted form of ((POSIX path of path_to_MacYTDL) & "Contents/Resources/Scripts/Monitor.scpt")
	
	-- PRODUCTION CALL - Call the download Monitor script which will run as a separate process and return so Main Dialog can be re-displayed - thus user can start any number of downloads
	do shell script "osascript -s s " & myMonitorScriptAsString & " " & my_params & " " & " > /dev/null 2> /dev/null &"
	
	-- TESTING CALL - Call the download Monitor script for testing - this formulation gets any errors back from Monitor, but holds execution until Monitor dialog is dismissed
	--do shell script "osascript -s s " & myMonitorScriptAsString & " " & my_params
	
	main_dialog()
	
end download_batch


-------------------------------------------------------------
--
-- 	Clear batch file - called by open_batch_processing
--
-------------------------------------------------------------
-- Handler to clear all URLs from batch file - empties the file but does not delete it
on clear_batch(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
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
		open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
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
			main_dialog()
		end try
		main_dialog()
	end try
	open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
end clear_batch


--------------------------------------------------------------------------
--
-- 	Remove last batch addition - called by open_batch_processing
--
--------------------------------------------------------------------------
-- Handler to remove the most recent addition to batch file
on remove_last_from_batch(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
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
		open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
	end if
	try
		set batch_file_ref to missing value
		set batch_file_ref to open for access file batch_file with write permission
		set batch_URLs to read batch_file_ref from 1 as «class utf8»
		set batch_URLs to text 1 thru -4 of batch_URLs --<= remove last few characters to remove last return
		set last_URL_offset to last item of allOffset(batch_URLs, return) --<= Get last in list of offsets of returns
		set new_batch_contents to text 1 thru (last_URL_offset - 1) of batch_URLs --<= Trim off last URL
		set eof batch_file_ref to 0 --<= Empty the batch file
		write new_batch_contents & return to batch_file_ref as «class utf8» --<= Write out all URLs except the last
		close access batch_file_ref
	on error batch_errMsg number errorNumber
		set theBatchErrorLabel to localized string "There was an error: number " from table "MacYTDL"
		display dialog theBatchErrorLabel & errorNumber & " - " & batch_errMsg & "  batch_file: " & batch_file buttons {theButtonOKLabel} default button 1
		close access batch_file_ref
		main_dialog()
	end try
	open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_TimeStamps, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Settings, YTDL_Custom_Template, YTDL_no_part, YTDL_QT_Compat, DL_Use_YTDLP, YTDL_Resolution_Limit, YTDL_Use_Parts, YTDL_No_Warnings, ADL_Clear_Batch)
end remove_last_from_batch


----------------------------------------------------------------------------------------------------------------------------
--
-- 	Get screen height and width - using AppKit - called in preliminaries - also used in Monitor.scpt
--  Only loading AppKit when needed - simplifies changes to rest of code
--  Using NSScreen's mainScreen frame as does the Dialog Toolkit
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
-- 			Find All Offsets in String
--
---------------------------------------------------

-- Handler to find offsets items in a string
on allOffset(theString, thechar)
	set theString to theString as text
	set reverse_offsetList to {}
	repeat with i from 1 to length of theString
		if item i of theString is thechar then
			set end of reverse_offsetList to i
		end if
	end repeat
	return reverse_offsetList
end allOffset


-------------------------------------------------------------
--
-- 		Find offset of last search string in a String
--
-------------------------------------------------------------

-- Handler to find offset of last specified character in a string
on last_offset(the_object_string, the_search_string)
	try
		set len to count of the_object_string
		set reverses to reverse of characters of the_search_string as string
		set reversed to reverse of characters of the_object_string as string
		set last_occurrence_offset to len - (offset of reverses in reversed)
		if last_occurrence_offset > len then
			return 0
		end if
	on error
		return 0
	end try
	return last_occurrence_offset
end last_offset


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
