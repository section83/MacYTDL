-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  MacYTDL
--  A GUI for the Python scripts youtube-dl and YT-DLP.  Many thanks to Shane Stanley, Adam Albrec, kopurando and Michael Page
--  Trying to bring in useful functions in a pithy GUI with few AppleScript extensions and without AppleScriptObjC
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Include libraries - needed for Shane Staney's Dialog Toolkit
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use script "DialogToolkitMacYTDL" -- Yosemite (10.10) or later
property parent : AppleScript

-- Set variables and default values

-- Variables which need to be controlled across more than one handler
global diag_prompt
global diag_Title
global YTDL_version
global usr_bin_folder
global ffprobe_version
global ffmpeg_version
global python_version
global alert_text_ytdl
global alert_text_ffmpeg
global path_to_MacYTDL
global shellPath
global downloadsFolder_Path
global Atomic_is_installed
global macYTDL_Atomic_file
global download_filename
global download_filename_new
global YTDL_response_file
global YTDL_simulate_file
global youtubedl_file
global ytdlp_file
global YTDL_exists
global ytdlp_exists
global show_yt_dlp
global URL_user_entered
global ABC_show_URLs
global SBS_show_URLs
global ABC_show_name
global SBS_show_name
global playlist_Name
global myNum
global YTDL_output_template
global YTDL_format_pref
global old_version_prefs
global batch_file
global MacYTDL_prefs_file
global MacYTDL_custom_icon_file
global MacYTDL_custom_icon_file_posix
global macYTDL_service_file
global MacYTDL_preferences_path
global alerterPath
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
global MacYTDL_version
global MacYTDL_copyright
global MacYTDL_date
global newText
global ffprobe_file
global ffmpeg_file
global DTP_file
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
end tell
set MacYTDL_date_position to (offset of "," in MacYTDL_copyright) + 2
set MacYTDL_date to text MacYTDL_date_position thru end of MacYTDL_copyright
set MacYTDL_date_day to word 1 of MacYTDL_date
set MacYTDL_date_month to word 2 of MacYTDL_date
set MacYTDL_date_year to word 3 of MacYTDL_date
set thedateLabel to localized string MacYTDL_date_month
set MacYTDL_date to MacYTDL_date_day & " " & thedateLabel & " " & MacYTDL_date_year
set MacYTDL_version to get version of me

-- Set variable to contain path to Alerter
set alerterPath to POSIX path of (path_to_MacYTDL & "Contents:Resources:")
--display dialog path_to_MacYTDL & return & alerterPath -- <-- Left for testing
-- Set text for alerts that might be invoked before Main dialog
set alert_text_ytdl to "NotSwitching"

-- Set variable to contain user's macOS version - for Utilities, Settings and yt-dlp/YTDL install
set user_sysinfo to system info
set user_os_version to system version of user_sysinfo as string
considering numeric strings
	if user_os_version is greater than "10.14.6" then
		set show_yt_dlp to "YT-DLP"
	else
		set show_yt_dlp to "youtube-dl"
	end if
end considering

-- Add shellpath variable because otherwise script can't find youtube-dl/YT-DLP
set shellPath to "PATH=$PATH:/bin:/sbin:/usr/bin:/usr/local/bin:/usr/sbin:~/opt/bin:~/opt/sbin:/opt/local/bin:/opt/local/sbin:" & quoted form of (POSIX path of (path_to_MacYTDL & "::")) & "; "

-- Set to 0 the counter used to prevent monitor dialogs overlapping - on first use it is increased to one - thus monitor dialog starts at top of screen
set monitor_dialog_position to 0

-- Set path and name for custom icon for dialogs
set MacYTDL_custom_icon_file to (path to resource "applet.icns")
-- Set path and name for custom icon for enhanced window statements
set MacYTDL_custom_icon_file_posix to POSIX path of MacYTDL_custom_icon_file

-- Set variable for title of dialogs
set theVersionLabel to localized string "Version"
set diag_Title to "MacYTDL, " & theVersionLabel & " " & MacYTDL_version & ", " & MacYTDL_date

-- Variables for component installation status - doubling up with version if already installed - changed when components are installed
set YTDL_version to "Not installed"
set ffprobe_version to "Not installed"
set ffmpeg_version to "Not installed"
set Atomic_is_installed to false
set old_version_prefs to "No"

-- Variables for storing MacYTDL preferences, batch file, youtube-dl/YT-DLP, FFmpeg, FFprobe and DialogToolkitPlus locations
set usr_bin_folder to ("/usr/local/bin/" as text)
set ytdlp_file to ("/usr/local/bin/yt-dlp" as text)
set youtubedl_file to ("/usr/local/bin/youtube-dl" as text)
set home_folder to (path to home folder) as text
set libraries_folder to home_folder & "Library:Script Libraries"
set DTP_file to libraries_folder & ":DialogToolkitMacYTDL.scptd"
set MacYTDL_preferences_folder to "Library/Preferences/MacYTDL/"
set MacYTDL_preferences_path to (POSIX path of (path to home folder) & MacYTDL_preferences_folder)
set MacYTDL_prefs_file to MacYTDL_preferences_path & "MacYTDL.plist"
set ffmpeg_file to ("/usr/local/bin/ffmpeg" as text)
set ffprobe_file to ("/usr/local/bin/ffprobe" as text)
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

-- Variables for the most common dialog buttons and drop-down boxes - saves a little extra code in all the display dialogs
set theButtonOKLabel to localized string "OK"
set theButtonQuitLabel to localized string "Quit"
set theButtonDownloadLabel to localized string "Download"
set theButtonReturnLabel to localized string "Return"
set theButtonContinueLabel to localized string "Continue"
set theButtonCancelLabel to localized string "Cancel"
set theButtonNoLabel to localized string "No"
set theButtonYesLabel to localized string "Yes"
set theBestLabel to localized string "Best"
set theDefaultLabel to localized string "Default"

-- Load utilities.scpt so that various handlers can be called
set path_to_Utilities to (path_to_MacYTDL & "Contents:Resources:Scripts:Utilities.scpt") as alias
set run_Utilities_handlers to load script path_to_Utilities

-------------------------------------------------
--
-- 	Make sure components are in place
--
------------------------------------------------- 
-- Check which components are installed - if so, get versions - but, this can be wrong if user has both scripts installed
tell application "System Events"
	if exists file youtubedl_file then
		set YTDL_exists to true
	else
		set YTDL_exists to false
	end if
	if exists file ytdlp_file then
		set ytdlp_path_alias to POSIX file ytdlp_file as alias
		if size of ytdlp_path_alias is greater than 9000 then
			set ytdlp_exists to true
		else
			set ytdlp_exists to false
		end if
	else
		set ytdlp_exists to false
	end if
	if exists file DTP_file then
		set DTP_exists to true
	else
		set DTP_exists to false
	end if
	if exists file ffmpeg_file then
		set ffmpeg_exists to true
		set ffmpeg_version_long to do shell script ffmpeg_file & " -version"
		set ffmpeg_version_start to (offset of "version" in ffmpeg_version_long) + 8
		if ffmpeg_version_long contains "-tessus" then
			set ffmpeg_version_end to (offset of "-tessus" in ffmpeg_version_long) - 1
		else
			set ffmpeg_version_end to (offset of "Copyright" in ffmpeg_version_long) - 2
		end if
		set ffmpeg_version to text ffmpeg_version_start thru ffmpeg_version_end of ffmpeg_version_long
	else
		set ffmpeg_exists to false
	end if
	if exists file ffprobe_file then
		set ffprobe_exists to true
		set ffprobe_version_long to do shell script ffprobe_file & " -version"
		set ffprobe_version_start to (offset of "version" in ffprobe_version_long) + 8
		if ffprobe_version_long contains "-tessus" then
			set ffprobe_version_end to (offset of "-tessus" in ffprobe_version_long) - 1
		else
			set ffprobe_version_end to (offset of "Copyright" in ffprobe_version_long) - 2
		end if
		set ffprobe_version to text ffprobe_version_start thru ffprobe_version_end of ffprobe_version_long
	else
		set ffprobe_exists to false
	end if
	if exists file MacYTDL_prefs_file then
		set prefs_exists to true
	else
		set prefs_exists to false
	end if
end tell

-- If no components are installed, can assume it's the first time MacYTDL has been used - need to do a full installation of all components
if YTDL_exists is false and ytdlp_exists is false and DTP_exists is false and ffmpeg_exists is false and ffprobe_exists is false and prefs_exists is false then
	set theComponentsNotInstalledtTextLabel1 to localized string "It looks like you have not used MacYTDL before. A number of components must be installed for MacYTDL to run. There is more detail in the Help file. Would you like to install those components now ? Otherwise, Quit."
	set theComponentsNotInstalledtTextLabel2 to localized string "Note: Some components will be downloaded which might take a while and you will need to provide administrator credentials."
	tell me to activate
	set components_install_answ to button returned of (display dialog theComponentsNotInstalledtTextLabel1 & return & return & theComponentsNotInstalledtTextLabel2 with title diag_Title buttons {theButtonQuitLabel, theButtonYesLabel} default button 2 cancel button 1 with icon note giving up after 600)
	-- set components_install_answ to button returned of components_install
	if components_install_answ is theButtonYesLabel then
		set YTDL_version to run_Utilities_handlers's check_ytdl_installed(usr_bin_folder, diag_Title, youtubedl_file, ytdlp_file, theButtonQuitLabel, theButtonYesLabel, path_to_MacYTDL, theButtonOKLabel, alerterPath, show_yt_dlp)
		set YTDL_exists to true
		run_Utilities_handlers's set_preferences(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, alerterPath, show_yt_dlp)
		set prefs_exists to true
		delay 1
		run_Utilities_handlers's install_DTP(DTP_file, path_to_MacYTDL, alerterPath)
		set DTP_exists to true
		delay 1
		run_Utilities_handlers's check_ffmpeg_installed(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, ffmpeg_exists, ffprobe_exists, alerterPath)
		set ffprobe_exists to true
		set ffmpeg_exists to true
		run_Utilities_handlers's ask_user_install_service(path_to_MacYTDL, theButtonYesLabel, diag_Title, MacYTDL_custom_icon_file)
		-- Offer to install Atomic Parsley and Service if user is on macOS < 10.15 - Use show_yt_dlp as proxy for macOS version
		if show_yt_dlp is "youtube-dl" then
			run_Utilities_handlers's ask_user_install_Atomic(usr_bin_folder, path_to_MacYTDL, diag_Title, MacYTDL_custom_icon_file, theButtonOKLabel, theButtonYesLabel)
		end if
	else
		quit_MacYTDL()
	end if
end if

-- If one or more components are installed, indicates user has used MacYTDL before - check and install any missing components

-- Set up preferences if they don't exist
if prefs_exists is false then
	-- Prefs file doesn't exist - warn user it must be created for MacYTDL to work
	set theInstallPrefsTextLabel to localized string "The MacYTDL Preferences file is not present. To work, MacYTDL needs to create a file in your Preferences folder. Do you wish to continue ?"
	set Install_Prefs to button returned of (display dialog theInstallPrefsTextLabel buttons {theButtonNoLabel, theButtonYesLabel} default button 2 cancel button 1 with title diag_Title with icon note giving up after 600)
	if Install_Prefs is theButtonYesLabel then
		run_Utilities_handlers's set_preferences(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, alerterPath, show_yt_dlp)
		set prefs_exists to true
	else if Install_Prefs is theButtonNoLabel then
		error number -128
	end if
end if

-- If user gets to here can assume Prefs exist so, check whether user has one of the old versions - if so, call set_preferences to fix - continue on if current version - will delete this one day
tell application "System Events"
	try
		tell property list file MacYTDL_prefs_file
			set test_DL_subtitles to value of property list item "SubTitles"
		end tell
		-- Old version had string prefs while new version has boolean prefs for 4 items - call set_preferences to delete and recreate if user wishes
		-- This is quite old - should try to remove it and replace with something simpler
		if test_DL_subtitles is "Yes" or test_DL_subtitles is "No" then
			set old_version_prefs to "Yes"
			run_Utilities_handlers's set_preferences(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, alerterPath, show_yt_dlp)
		end if
	on error
		-- Means the plist file exists but there is a problem (eg. it's empty because of an earlier crash) - just delete it, re-create and populate as if replacing the old version
		set old_version_prefs to "Yes"
		run_Utilities_handlers's set_preferences(old_version_prefs, diag_Title, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, MacYTDL_version, MacYTDL_date, MacYTDL_preferences_path, path_to_MacYTDL, X_position, Y_position, theBestLabel, theDefaultLabel, alerterPath, show_yt_dlp)
	end try
	
	-- Check on need to add new v1.10 item to the prefs file
	tell property list file MacYTDL_prefs_file
		if not (exists property list item "Show_Settings_before_Download") then
			run_Utilities_handlers's add_v1_10_preference(MacYTDL_prefs_file)
		end if
	end tell
	-- Check on need to add new v1.11 item to the prefs file
	tell property list file MacYTDL_prefs_file
		if not (exists property list item "final_Position") then
			run_Utilities_handlers's add_v1_11_preference(MacYTDL_prefs_file, X_position, Y_position)
		end if
	end tell
	-- Check on need to add new v1.12.1 item to the prefs file
	tell property list file MacYTDL_prefs_file
		if not (exists property list item "Subtitles_Language") then
			run_Utilities_handlers's add_v1_12_1_preference(MacYTDL_prefs_file)
		end if
	end tell
	-- Check on need to add new v1.16 write-auto-sub item to the prefs file
	tell property list file MacYTDL_prefs_file
		if not (exists property list item "Subtitles_YTAuto") then
			run_Utilities_handlers's add_v1_16_preference(MacYTDL_prefs_file, theDefaultLabel)
		end if
	end tell
	-- Check on need to add new v1.17 proxy settings to the prefs file
	tell property list file MacYTDL_prefs_file
		if not (exists property list item "Use_Proxy") then
			run_Utilities_handlers's add_v1_17_preference(MacYTDL_prefs_file)
		end if
	end tell
	-- Check on need to add new v1.18 proxy settings to the prefs file
	tell property list file MacYTDL_prefs_file
		if not (exists property list item "Use_Cookies") then
			run_Utilities_handlers's add_v1_18_preference(MacYTDL_prefs_file)
		end if
	end tell
	-- Check on need to add new v1.19 YT-DLP settings to the prefs file
	tell property list file MacYTDL_prefs_file
		if not (exists property list item "Use_ytdlp") then
			run_Utilities_handlers's add_v1_19_preference(MacYTDL_prefs_file, show_yt_dlp)
		end if
	end tell
end tell

-- Install YTDL or YT-DLP if both do not exist according to macOS version or current setting if it exists - if either do not exist contrary to existing setting, offer to install - if the other exists offer to switch - catch case of library files being deleted
tell application "System Events"
	tell property list file MacYTDL_prefs_file
		set setting_yt_dlp to value of property list item "Use_ytdlp"
	end tell
end tell
-- User on older OS must have libraries installed to use YT-DLP - using "show_yt_dlp" as proxy for macOS version
if show_yt_dlp is "youtube-dl" and setting_yt_dlp is "yt-dlp" then
	set SSL_library_file to "/usr/local/lib/libssl.46.dylib"
	set crypto_library_file to "/usr/local/lib/libcrypto.44.dylib"
	set user_missing_libraries to false
	tell application "System Events"
		if ((not (exists file SSL_library_file)) or (not (exists file crypto_library_file))) then
			set user_missing_libraries to true
		end if
	end tell
	if user_missing_libraries is true then
		set theLibrariesNotInstalledtTextLabel to localized string "You are currently set to use YT-DLP. However, the two necessary library files are not installed. So, you can use MacYTDL, you will be switched to use youtube-dl. There is more detail in the Help file."
		display dialog theLibrariesNotInstalledtTextLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Use_ytdlp" to "youtube-dl"
			end tell
		end tell
	end if
end if
-- For some reason user has no downloaders or is missing desired downloader
if (YTDL_exists is false and ytdlp_exists is false) or (YTDL_exists is false and setting_yt_dlp is "youtube-dl") or (ytdlp_exists is false and setting_yt_dlp is "YT-DLP") then
	if (YTDL_exists is true and setting_yt_dlp is "YT-DLP") or (ytdlp_exists is true and setting_yt_dlp is "youtube-dl") then
		if setting_yt_dlp is "youtube-dl" then
			set switch_to to "YT-DLP"
		else
			set switch_to to "youtube-dl"
		end if
		set theYTDLYTDLPIsInstalledtTextLabel to localized string "You are currently set to download with " & setting_yt_dlp & " but, it is not installed. This may have been set according to the version of macOS you are using or because there was a fault in downloading YT-DLP. You do have " & switch_to & " installed. Would you like to switch downloaders or install " & setting_yt_dlp & "?"
		tell me to activate
		set yt_install_answ to button returned of (display dialog theYTDLYTDLPIsInstalledtTextLabel with title diag_Title buttons {theButtonQuitLabel, switch_to, setting_yt_dlp} default button 2 cancel button 1 with icon note giving up after 600)
		if yt_install_answ is switch_to then
			-- Update Use_ytdlp setting if user wants to use the currently installed downloader
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Use_ytdlp" to yt_install_answ
				end tell
			end tell
			-- Install the missing downloader if user wants to use that
		else if yt_install_answ is setting_yt_dlp then
			set alert_text_ytdl to "NotSwitching"
			set YTDL_version to run_Utilities_handlers's check_ytdl_installed(usr_bin_folder, diag_Title, youtubedl_file, ytdlp_file, theButtonQuitLabel, theButtonYesLabel, path_to_MacYTDL, theButtonOKLabel, alerterPath, setting_yt_dlp)
		else
			quit_MacYTDL()
		end if
	else
		-- No downloader is installed
		set theYTDLNotInstalledtTextLabel1 to localized string setting_yt_dlp & " is not installed."
		set theYTDLNotInstalledtTextLabel2 to localized string "Would you like to install it now ? If not, MacYTDL can't download videos. Note: This download can take a while and you will probably need to provide administrator credentials."
		tell me to activate
		set yt_install to display dialog theYTDLNotInstalledtTextLabel1 & return & return & theYTDLNotInstalledtTextLabel2 with title diag_Title buttons {theButtonQuitLabel, theButtonYesLabel} default button 2 cancel button 1 with icon note giving up after 600
		set yt_install_answ to button returned of yt_install
		if yt_install_answ is theButtonYesLabel then
			set YTDL_version to run_Utilities_handlers's check_ytdl_installed(usr_bin_folder, diag_Title, youtubedl_file, ytdlp_file, theButtonQuitLabel, theButtonYesLabel, path_to_MacYTDL, theButtonOKLabel, alerterPath, setting_yt_dlp)
			-- set YTDL_exists to true
		else
			quit_MacYTDL()
		end if
	end if
end if

-- Check if DTP exists - install if not
if DTP_exists is false then
	set theInstallDTPTextLabel to localized string "MacYTDL needs a code library installed in your Libraries folder. It cannot function without that library. Do you wish to continue ?"
	set install_DTP to button returned of (display dialog theInstallDTPTextLabel buttons {theButtonNoLabel, theButtonYesLabel} default button 2 cancel button 1 with title diag_Title with icon note giving up after 600)
	if install_DTP is theButtonYesLabel then
		run_Utilities_handlers's install_DTP(DTP_file, path_to_MacYTDL, alerterPath)
		set DTP_exists to true
	else if install_DTP is theButtonNoLabel then
		error number -128
	end if
end if

-- If user gets to here can assume DTP exists. Check whether DTP name is changed or new version of DTP available
run_Utilities_handlers's check_DTP(DTP_file, path_to_MacYTDL)

-- Install FFmpeg and FFprobe if either is missing - versions are updated earlier on if they exist
if ffmpeg_exists is false then
	set theInstallFFmpegTextLabel to localized string "FFmpeg is not installed. Would you like to install it now ? If not, MacYTDL can't run and will have to quit. Note: This download can take a while and you will probably need to provide administrator credentials."
	set Install_FFmpeg to button returned of (display dialog theInstallFFmpegTextLabel buttons {theButtonNoLabel, theButtonYesLabel} default button 2 cancel button 1 with title diag_Title with icon note giving up after 600)
	if Install_FFmpeg is theButtonYesLabel then
		run_Utilities_handlers's check_ffmpeg_installed(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, ffmpeg_exists, ffprobe_exists, alerterPath)
		set ffmpeg_exists to true
		set ffprobe_exists to true
	else if Install_FFmpeg is theButtonNoLabel then
		error number -128
	end if
end if
if ffprobe_exists is false then
	set theInstallFFprobeTextLabel to localized string "FFprobe is not installed. Would you like to install it now ? If not, MacYTDL can't run and will have to quit. Note: This download can take a while and you will probably need to provide administrator credentials."
	set Install_FFprobe to button returned of (display dialog theInstallFFprobeTextLabel buttons {theButtonNoLabel, theButtonYesLabel} default button 2 cancel button 1 with title diag_Title with icon note giving up after 600)
	if Install_FFprobe is theButtonYesLabel then
		run_Utilities_handlers's check_ffmpeg_installed(theButtonOKLabel, diag_Title, path_to_MacYTDL, usr_bin_folder, ffmpeg_exists, ffprobe_exists, alerterPath)
		set ffmpeg_exists to true
		set ffprobe_exists to true
	else if Install_FFprobe is theButtonNoLabel then
		error number -128
	end if
end if

-- Check version of Service if installed - update if old
run_Utilities_handlers's update_MacYTDLservice(path_to_MacYTDL)

-- Is Atomic Parsley installed ? [Needed for embedding thumbnails in mp4 and m4a files] - result is displayed in Utilities dialog - Is this needed for the Service ?
set macYTDL_Atomic_file to ("usr:local:bin:AtomicParsley" as text)
tell application "System Events"
	if (exists file macYTDL_Atomic_file) then
		set Atomic_is_installed to true
	else
		set Atomic_is_installed to false
	end if
end tell

-- Get Python version - is always installed and so don't need to test whether it is there - result shown in optional Show Settings dialog before download <= Which needs to be updated to show Python3 version if installed
set python_version to do shell script "python -c 'import platform; print(platform.python_version())'"

-- Set path and name for youtube-dl/YT-DLP simulated response file - a simulated youtube-dl/YT-DLP download puts all its feedback into this file - it's a generic file used for all downloads and so only contains detail on the most recent download - simulation helps find errors and problems before starting the download
set YTDL_simulate_file to MacYTDL_preferences_path & "youtube-dl_simulate.txt"

-- If auto checking of youtube-dl/YT-DLP version is on, do the check
tell application "System Events"
	tell property list file MacYTDL_prefs_file
		set DL_YTDL_auto_check to value of property list item "Auto_Check_YTDL_Update"
		set DL_Use_YTDLP to value of property list item "Use_ytdlp"
	end tell
end tell
if DL_YTDL_auto_check is true then
	-- Need to set YTDL_version according to current script
	if DL_Use_YTDLP is "youtube-dl" then
		set YTDL_version to do shell script youtubedl_file & " --version"
	else
		set YTDL_version to do shell script ytdlp_file & " --version"
	end if
	check_ytdl(DL_Use_YTDLP)
	set alert_text_ytdlLabel to localized string show_yt_dlp & " has been updated"
	if alert_text_ytdl contains alert_text_ytdlLabel then
		display dialog alert_text_ytdl with title diag_Title buttons theButtonOKLabel default button 1 with icon note giving up after 600
	end if
end if

-- Set ABC show name and episode count variables so they exist
set ABC_show_name to ""
set SBS_show_name to ""
set myNum to 0


main_dialog()

on main_dialog()
	
	--*****************  This is for testing variables as they come into and back to Main - beware some of these are not defined on all circumstances
	
	-- display dialog "video_URL: " & return & return & "called_video_URL: " & called_video_URL & return & return & "URL_user_entered: " & URL_user_entered & return & return & "URL_user_entered_clean: " & URL_user_entered_clean & return & return & "default_contents_text: "
	
	--*****************		
	
	-- Read the preferences file to get current settings
	run_Utilities_handlers's read_settings(MacYTDL_prefs_file)
	
	-- Need to set YTDL_version according to current script - because execution can come to here from Utilities which can switch scripts - but why not set in the handler which changes it ?
	if DL_Use_YTDLP is "youtube-dl" then
		set YTDL_version to do shell script youtubedl_file & " --version"
	else
		set YTDL_version to do shell script ytdlp_file & " --version"
	end if
	
	-- Set batch file status so that it persists while MacYTDL is running
	try
		if DL_batch_status is true then
			set DL_batch_status to true
		end if
	on error
		set DL_batch_status to false
	end try
	
	-- Test whether app was called by Service - error means not called and so there is no URL to be passed to the Main Dialog
	try
		-- Test whether URL provided by Service has been reset to blank on a previous pass through
		if called_video_URL is "" then
			set default_contents_text to URL_user_entered_clean
		else
			set default_contents_text to called_video_URL
		end if
		-- Need to reset the called_video_URL variable so that it doesn't over-write the URL text box after a later download
		set called_video_URL to ""
	on error errNum -- Not called from Service, should always be error -2753 (variable not defined) - refill URL so it's shown in dialog - will be blank if user has not pasted a URL
		set default_contents_text to URL_user_entered_clean
	end try
	
	set theDiagSettingsTextLabel to localized string "One-time settings:                                     Batches:"
	set accViewWidth to 450
	set accViewInset to 80
	
	-- Set buttons and controls
	set theButtonsHelpLabel to localized string "Help"
	set theButtonsUtilitiesLabel to localized string "Utilities"
	set theButtonsSettingsLabel to localized string "Settings"
	set {theButtons, minWidth} to create buttons {theButtonsHelpLabel, theButtonsUtilitiesLabel, theButtonQuitLabel, theButtonsSettingsLabel, theButtonContinueLabel} button keys {"?", "u", "q", "s", ""} default button 5
	if minWidth > accViewWidth then set accViewWidth to minWidth -- make sure buttons fit
	set theFieldLabel to localized string "Paste URL here"
	set {theField, theTop} to create field default_contents_text placeholder text theFieldLabel left inset accViewInset bottom 0 field width accViewWidth - accViewInset extra height 15
	set {theRule, theTop} to create rule theTop + 18 rule width accViewWidth
	set theCheckbox_Show_SettingsLabel to localized string "Show settings before download"
	set {theCheckbox_Show_Settings, theTop} to create checkbox theCheckbox_Show_SettingsLabel left inset accViewInset + 50 bottom (theTop + 10) max width 250 initial state DL_Show_Settings
	set theCheckbox_SubTitlesLabel to localized string "Subtitles for this download"
	set {theCheckbox_SubTitles, theTop} to create checkbox theCheckbox_SubTitlesLabel left inset accViewInset bottom (theTop + 15) max width 250 initial state DL_subtitles
	set theCheckbox_CredentialsLabel to localized string "Credentials for download"
	set {theCheckbox_Credentials, theTop} to create checkbox theCheckbox_CredentialsLabel left inset accViewInset bottom (theTop + 5) max width 200 without initial state
	set theCheckbox_DescriptionLabel to localized string "Download description"
	set {theCheckbox_Description, theTop} to create checkbox theCheckbox_DescriptionLabel left inset accViewInset bottom (theTop + 5) max width 175 initial state DL_description
	set theLabelledPopUpRemuxFileformat to localized string "Remux file format:"
	set {main_thePopUp_FileFormat, main_formatlabel, theTop} to create labeled popup {"No remux", "mp4", "mkv", "webm", "ogg", "avi", "flv"} left inset accViewInset - 5 bottom (theTop + 5) popup width 100 max width 200 label text theLabelledPopUpRemuxFileformat popup left accViewInset + 120 initial choice DL_Remux_format
	set thePathControlLabel to localized string "Change download folder:"
	set {thePathControl, pathLabel, theTop} to create labeled path control (POSIX path of downloadsFolder_Path) left inset accViewInset bottom (theTop + 5) control width 175 label text thePathControlLabel with pops up
	set theCheckbox_OpenBatchLabel to localized string "Open Batch functions"
	set {theCheckbox_OpenBatch, theTop} to create checkbox theCheckbox_OpenBatchLabel left inset (accViewInset + 210) bottom (theTop - 40) max width 200 without initial state
	set theCheckbox_AddToBatchLabel to localized string "Add URL to Batch"
	set {theCheckbox_AddToBatch, theTop} to create checkbox theCheckbox_AddToBatchLabel left inset (accViewInset + 210) bottom (theTop + 5) max width 200 initial state DL_batch_status
	set {diag_settings_prompt, theTop} to create label theDiagSettingsTextLabel left inset accViewInset bottom theTop + 8 max width accViewWidth control size regular size with bold type
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 60 view width 64 view height 64 scale image scale proportionally
	
	-- Display the dialog
	tell me to activate
	set {button_label_returned, button_number_returned, controls_results, finalPosition} to display enhanced window diag_Title acc view width accViewWidth acc view height theTop acc view controls {theField, theCheckbox_Show_Settings, theCheckbox_SubTitles, theCheckbox_Credentials, theCheckbox_Description, main_thePopUp_FileFormat, main_formatlabel, thePathControl, theCheckbox_AddToBatch, theCheckbox_OpenBatch, pathLabel, diag_settings_prompt, theRule, MacYTDL_icon} buttons theButtons active field theField initial position window_Position
	
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
	
	-- Has user moved the MacYTDL window - if so, save new position
	if finalPosition is not equal to window_Position then
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "final_Position" to finalPosition
			end tell
		end tell
	end if
	
	if button_number_returned is 4 then -- Show Settings
		set_settings(URL_user_entered_clean)
	else if button_number_returned is 2 then -- Show Utilities
		utilities()
	else if button_number_returned is 1 then -- Show Help
		set path_to_MacYTDL_alias to path_to_MacYTDL as alias
		set MacYTDL_help_file to (path to resource "Help.pdf" in bundle path_to_MacYTDL_alias) as string
		tell application "Finder"
			open file MacYTDL_help_file
		end tell
		main_dialog()
	end if
	
	-- Convert settings to format that can be used as youtube-dl/YT-DLP parameters + define variables
	if description_choice is true then
		set YTDL_description to "--write-description "
	else
		set YTDL_description to ""
	end if
	set YTDL_audio_only to ""
	set YTDL_audio_codec to ""
	if DL_over_writes is false then
		set YTDL_over_writes to "--no-overwrites "
	else
		set YTDL_over_writes to ""
	end if
	
	set YTDL_subtitles to ""
	
	if DL_STEmbed is true then
		set YTDL_STEmbed to "--embed-subs "
	else
		set YTDL_STEmbed to ""
	end if
	
	-- Prepare User's download settings - using current settings - YT-DLP prefers to have name of post processor
	if remux_format_choice is not "No remux" then
		if DL_Use_YTDLP is "YT-DLP" then
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
	if DL_Use_Custom_Template is true then
		set YTDL_Custom_Template to (DL_Custom_Template)
	else
		set YTDL_Custom_Template to ""
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
	
	check_download_folder(folder_chosen)
	if DL_Use_Cookies is true then check_cookies_file(DL_Cookies_Location)
	
	-- Set variable to contain download folder path - value comes from runtime settings which gets initial value from preferences but which user can then change
	-- But first, if user has set download path to a file, use parent folder for downloads
	tell application "System Events" to set test_DL_folder to (get class of item (folder_chosen as text)) as text
	if test_DL_folder is "file" then
		-- Trim last part of path name
		set offset_to_file_name to last_offset(folder_chosen as text, "/")
		set folder_chosen to text 1 thru offset_to_file_name of folder_chosen
	end if
	
	set downloadsFolder_Path to folder_chosen
	
	if button_number_returned is 5 then -- Continue to download
		if openBatch_chosen is true then
			open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
		else
			download_video(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
		end if
	end if
end main_dialog


---------------------------------------------------------------------------------------------
--
-- 	Download videos - called by Main dialog - calls monitor.scpt
--
---------------------------------------------------------------------------------------------

on download_video(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
	
	-- Remove any trailing slash in the URL - causes syntax error with code to follow
	if text -2 of URL_user_entered is "/" then
		set URL_user_entered to quoted form of (text 2 thru -3 of URL_user_entered) -- Why not just remove the trailing slash ??
	end if
	
	-- Do error checking on pasted URL
	-- First, is pasted URL blank ?
	if URL_user_entered is "" or URL_user_entered is "''" then
		tell me to activate
		set theURLBlankLabel to localized string "You need to paste a URL before selecting Download. Quit or OK to try again."
		set quit_or_return to button returned of (display dialog theURLBlankLabel buttons {theButtonQuitLabel, theButtonOKLabel} default button 2 cancel button 1 with title diag_Title with icon note giving up after 600)
		if quit_or_return is theButtonOKLabel then
			main_dialog()
		end if
	end if
	
	-- Second was pasted URL > 4 characters long but did not begin with "http"
	if length of URL_user_entered is greater than 4 then
		set test_URL to text 2 thru 5 of URL_user_entered
		if not test_URL is "http" then
			set theURLNothttpLabel1 to localized string "The URL"
			set theURLNothttpLabel2 to localized string "is not valid. It should begin with the letters http. You need to paste a valid URL before selecting Download. Quit or OK to try again."
			set quit_or_return to button returned of (display dialog theURLNothttpLabel1 & " \"" & URL_user_entered & "\" " & theURLNothttpLabel2 buttons {theButtonQuitLabel, theButtonOKLabel} default button 2 cancel button 1 with title diag_Title with icon note giving up after 600)
			if quit_or_return is theButtonOKLabel then
				main_dialog()
			end if
		end if
		
		-- Third, is length of pasted URL </= 4
	else
		set theURLTooShortLabel1 to localized string "The URL"
		set theURLTooShortLabel2 to localized string "is not valid. It should begin with the letters http. You need to paste a valid URL before selecting Download, Quit or OK to try again."
		set quit_or_return to button returned of (display dialog theURLTooShortLabel1 & " \"" & URL_user_entered & "\" " & theURLTooShortLabel2 buttons {theButtonQuitLabel, theButtonOKLabel} default button 2 cancel button 1 with title diag_Title with icon note giving up after 600)
		if quit_or_return is theButtonOKLabel then
			main_dialog()
		end if
	end if
	
	-- Fourth, test whether the URL is one of the Australian broadcasters and fashion ytdl command to get best series and file name
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
	
	-- Fifth, use simulated YTDL/YT-DLP run to look for errors reported back by YTDL, such as invalid URL which would otherwise stop MacYTDL
	-- Trap errors caused by ABC show pages - send processing to separate handler to collect episodes shown on that kind of page
	-- Also get any warnings that indicate an SBS show page and other issues
	-- But ignore revertions to the generic extractor
	-- Also get the file name from the simulate results - to be used in naming of responses file and detail that will be shown in the Monitor dialog
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
	
	-- Initialise indicator which will show whether URL is for an ABC or SBS show page - needed for over-writing code below
	set ABC_show_indicator to "No"
	set SBS_show_indicator to "No"
	set is_Livestream_Flag to "False"
	
	-- Use a simulation to get name of playlist and number of items for use later - test that cookies file works - warn user if there are more than 35 items in the playlist
	set YTDL_no_playlist to ""
	set playlist_Name to ""
	-- Does the URL point to a single playlist item ?
	if URL_user_entered_clean contains "&index=" and URL_user_entered_clean contains "youtu" then
		set YTDL_no_playlist to "--no-playlist "
	else if URL_user_entered_clean contains "playlist" or (URL_user_entered_clean contains "watch?" and URL_user_entered_clean contains "&list=") or (URL_user_entered_clean contains "?list=") then
		try
			set playlist_Simulate to do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; " & DL_Use_YTDLP & " --flat-playlist " & YTDL_Use_Cookies & URL_user_entered_clean_quoted
		on error error_Message
			set theErrorWithPlaylistLabel1 to "There was an error with the playlist. The error was: \""
			if DL_Use_Cookies is true and error_Message contains "playlist does not exist" then
				set theErrorWithPlaylistLabel2 to "This may have been caused by a faulty cookies file. Check the file and try again."
			else
				set theErrorWithPlaylistLabel2 to "Check the URL and try again."
			end if
			display dialog theErrorWithPlaylistLabel1 & error_Message & "\" " & theErrorWithPlaylistLabel2 buttons {theButtonReturnLabel} default button 1 with title diag_Title with icon note giving up after 600
			main_dialog()
		end try
		set AppleScript's text item delimiters to {"[download] Downloading playlist: ", return & "[youtube:tab] playlist ", return & "[youtube:tab] Downloading"}
		set playlist_Name to text item 2 of playlist_Simulate
		if playlist_Name contains "/" then
			set playlist_Name to run_Utilities_handlers's replace_chars(playlist_Name, "/", "_")
		end if
		-- For some reason, YTDL duplicates a line in the response to --flat-playlist for playlists that point to an item (including the youtu.be URLs), but not mixes or ordinary playlists – YT-DLP does not do that
		if DL_Use_YTDLP is "youtube-dl" then
			set AppleScript's text item delimiters to {": Downloading ", " videos"}
			if (URL_user_entered_clean contains "list=PL" or URL_user_entered_clean contains "list=OL") and (URL_user_entered_clean contains "watch?" or URL_user_entered_clean contains "//youtu.be/") then
				set playlist_Number_Items to text item 4 of playlist_Simulate as integer
			else
				set playlist_Number_Items to text item 3 of playlist_Simulate as integer
			end if
			set AppleScript's text item delimiters to {""}
		end if
		if DL_Use_YTDLP is "YT-DLP" then
			repeat with x from 1 to count paragraphs of playlist_Simulate
				if contents of paragraph x of playlist_Simulate begins with "[youtube:tab] playlist" then
					set PL_simulate_Paragraph to paragraph (x) of playlist_Simulate
					exit repeat
				end if
			end repeat
			set AppleScript's text item delimiters to {": Downloading", " videos"}
			set playlist_Number_Items to text item 2 of PL_simulate_Paragraph as integer
			set AppleScript's text item delimiters to {""}
		end if
		if playlist_Number_Items is greater than 35 then
			set theManyPlaylistItemsLabel1 to localized string "There are "
			set theManyPlaylistItemsLabel2 to localized string " items in playlist "
			set theManyPlaylistItemsLabel3 to localized string "It will take a long time to download. Do you wish to continue or return to the Main dialog ?"
			set quit_or_return to button returned of (display dialog theManyPlaylistItemsLabel1 & playlist_Number_Items & theManyPlaylistItemsLabel2 & "\"" & playlist_Name & "\". " & theManyPlaylistItemsLabel3 buttons {theButtonReturnLabel, theButtonContinueLabel} default button 2 with title diag_Title with icon note giving up after 600)
			if quit_or_return is theButtonReturnLabel then
				main_dialog()
			end if
		end if
		set AppleScript's text item delimiters to ""
	end if
	
	-- Do the simulation to get back file name and disclose any errors or warnings
	-- URLs to iView and OnDemand show pages causes error => takes processing to Get_ABC_Episodes or Get_SBS_Episodes handlers
	-- If desired file format not available, advise user and ask what to do
	-- Other kinds of errors are reported to user asking what to do
	
	do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & YTDL_format_pref & YTDL_credentials & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_output_template & " " & URL_user_entered_clean_quoted & " 2>&1 &>" & YTDL_simulate_file & " ; exit 0"
	set YTDL_simulate_response to read POSIX file YTDL_simulate_file as "utf8"
	
	if YTDL_simulate_response contains "Unsupported URL: https://iview.abc.net.au/show/" then
		-- Is the URL from an ABC Show Page ? - If so, get the user to choose which episodes to download
		set branch_execution to run_Utilities_handlers's Get_ABC_Episodes(URL_user_entered, diag_Title, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, X_position, screen_height, MacYTDL_custom_icon_file_posix, theButtonReturnLabel, path_to_MacYTDL)
		if branch_execution is "Main" then main_dialog()
		set ABC_show_indicator to "Yes"
		set URL_user_entered to ABC_show_URLs
	else if YTDL_simulate_response contains "Unsupported URL: https://www.sbs.com.au/ondemand" then
		-- If user uses URL from 'Featured' episode on a Show page, trim trailing text of URL and treat like a Show page - NB Some featured videos are supported by youtube-dl/YT-DLP
		if URL_user_entered contains "?action=play" then
			set URL_user_entered to (text 1 thru -14 of URL_user_entered & "'")
		end if
		-- youtube-dl/YT-DLP cannot download from some SBS show links - mostly on the OnDemand home and search pages
		if YTDL_simulate_response contains "?play=" or URL_user_entered contains "ondemand/search" then
			set theOnDemandURLProblemLabel to localized string "MacYTDL cannot download video from an SBS OnDemand \"Play\" or Search links. Navigate to a \"Show\" page and try again."
			display dialog theOnDemandURLProblemLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 100
			main_dialog()
		else if URL_user_entered contains "/ondemand/movie/" then
			-- YT-DLP/youtube-dl cannot download from standard SBS movie pages but, can if the URL is reformed using the ID
			set AppleScript's text item delimiters to "/"
			set SBS_movie_ID to text 1 thru -2 of (last text item of URL_user_entered)
			set URL_user_entered to quoted form of ("https://www.sbs.com.au/ondemand/watch/" & SBS_movie_ID)
			set AppleScript's text item delimiters to ""
			-- Now have the correct URL - simulate again to get file name into simulate file 
			do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename " & YTDL_credentials & URL_user_entered & " " & YTDL_output_template & " > /dev/null" & " &> " & YTDL_simulate_file
			set YTDL_simulate_response to read POSIX file YTDL_simulate_file as "utf8"
		else
			-- The URL from an SBS Show Page - get the user to choose which episodes to download
			set branch_execution to run_Utilities_handlers's Get_SBS_Episodes(URL_user_entered, diag_Title, theButtonOKLabel, theButtonCancelLabel, theButtonDownloadLabel, X_position, screen_height, MacYTDL_custom_icon_file_posix, theButtonReturnLabel, path_to_MacYTDL)
			if branch_execution is "Main" then main_dialog()
			set SBS_show_indicator to "Yes"
			set URL_user_entered to SBS_show_URLs
		end if
	else if YTDL_simulate_response contains "Unsupported URL: https://7Plus.com.au" then
		set theURLWarning7PlusLabel to localized string "This is a 7Plus Show page from which MacYTDL cannot download videos. Try an individual episode."
		display dialog theURLWarning7PlusLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
		main_dialog()
	else if YTDL_simulate_response contains "Unsupported URL: https://www.9now.com.au" then
		set theURLWarning9NowLabel to localized string "This is a 9Now Show page from which MacYTDL cannot download videos. Try an individual episode."
		display dialog theURLWarning9NowLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
		main_dialog()
	else if YTDL_simulate_response contains "Unsupported URL: https://10play.com.au" then
		set theURLWarning10playLabel to localized string "This is a 10 play Show page from which MacYTDL cannot download videos. Try an individual episode."
		display dialog theURLWarning10playLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
		main_dialog()
	else if YTDL_simulate_response contains "requested format not available" then
		set theFormatNotAvailLabel1 to localized string "Your preferred file format is not available. Would you like to cancel download and return, have your download remuxed into your preferred format or just download the best format available ?"
		set theFormatNotAvailLabel2 to localized string "{Note: 3gp format is not available - a request for 3gp will be remuxed into mp4.}"
		set theFormatNotAvailButtonRemuxLabel to localized string "Remux"
		set quit_or_return to button returned of (display dialog theFormatNotAvailLabel1 & return & theFormatNotAvailLabel2 buttons {theButtonReturnLabel, theFormatNotAvailButtonRemuxLabel, theButtonDownloadLabel} default button 3 with title diag_Title with icon note giving up after 600)
		if quit_or_return is theButtonReturnLabel then
			main_dialog()
		else if quit_or_return is theButtonDownloadLabel then
			-- User wants to download the best format available so, set desired format to null - simulate again to get file name into simulate file 
			do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename " & YTDL_credentials & URL_user_entered_clean_quoted & " " & YTDL_output_template & " > /dev/null" & " &> " & YTDL_simulate_file
			set YTDL_format to ""
			set YTDL_simulate_response to read POSIX file YTDL_simulate_file as "utf8"
		else if quit_or_return is "Remux" then
			-- User wants download remuxed to preferred format - simulate again to get file name into similate file - set desired format to null so that YTDL automatically downloads best available and set remux parameters
			do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename " & YTDL_credentials & URL_user_entered_clean_quoted & " " & YTDL_output_template & " > /dev/null" & " &> " & YTDL_simulate_file
			set YTDL_format to ""
			set remux_format_choice to DL_format
			if YTDL_format_pref is "3gp" then
				set remux_format_choice to "mp4"
			end if
			set YTDL_remux_format to "--recode-video " & remux_format_choice & " " & "--postprocessor-args \"-codec copy\" "
			set YTDL_simulate_response to read POSIX file YTDL_simulate_file as "utf8"
		end if
	else if YTDL_simulate_response contains "ERROR:" then
		if playlist_Name is not "" then
			set theURLErrorTextLabel4 to localized string " for the playlist '" & playlist_Name & "':"
		else
			set theURLErrorTextLabel4 to ":"
		end if
		set theURLErrorTextLabel1 to localized string "There was an error with the URL you entered"
		set theURLErrorTextLabel2 to localized string "The error message was: "
		set theURLErrorTextLabel3 to localized string "Quit, OK to return or Download to try anyway."
		set quit_or_return to button returned of (display dialog theURLErrorTextLabel1 & theURLErrorTextLabel4 & return & return & URL_user_entered & return & return & theURLErrorTextLabel2 & return & return & YTDL_simulate_response & return & theURLErrorTextLabel3 buttons {theButtonQuitLabel, theButtonOKLabel, theButtonDownloadLabel} default button 2 cancel button 1 with title diag_Title with icon note giving up after 600)
		if quit_or_return is theButtonOKLabel then
			main_dialog()
		else if quit_or_return is theButtonDownloadLabel then
			-- User wants to try to download ! Processing just continues from here down
		end if
	else if YTDL_simulate_response contains "IOError: CRC check failed" then
		set theURLErrorTextLabel1 to localized string "There was an error with the URL you entered. The video might be DRM protected or it could be a network, VPN or macOS install issue. If the URL is correct, you may need to look more deeply into your network settings and macOS install."
		display dialog theURLErrorTextLabel1 buttons {theButtonOKLabel} with title diag_Title with icon note giving up after 600
		main_dialog()
	end if
	
	-- Sixth - check whether URL points to a live stream - for SBS (Australia) only option is to use content of URL
	if URL_user_entered contains "sbs.com.au/ondemand" and URL_user_entered contains "-live-stream" then
		set is_Livestream_Flag to "True"
		set YTDL_no_part to "--no-part "
	else if URL_user_entered does not contain "sbs.com.au/ondemand" then
		set is_live_simulate to do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename -o '%(is_live)s'  " & URL_user_entered & " ; exit 0"
		if is_live_simulate contains "True" then
			set is_Livestream_Flag to "True"
			set YTDL_no_part to "--no-part "
		else if URL_user_entered contains "sbs.com.au/ondemand" and URL_user_entered contains "-live-stream" then
			set is_Livestream_Flag to "True"
			set YTDL_no_part to "--no-part "
		end if
	end if
	
	-- Seventh, look for any warnings in simulate file. Get filename from the simulate response file
	-- Don't show warning to user if it's just the fallback to generic extractor - that happens too often to be useful
	-- Because extension can be different, exclude that from file name
	-- Currently testing method for doing that (getting download_filename) - might not work if file extension is not 3 characters (eg. ts)
	-- Might remove the extraneous dot characters in file names if they prove a problem
	
	set simulate_warnings to ""
	repeat with aPara in (paragraphs of YTDL_simulate_response)
		if aPara contains "WARNING:" and aPara does not contain "Falling back on generic information" then
			if simulate_warnings is "" then
				set simulate_warnings to aPara
			else
				set simulate_warnings to simulate_warnings & return & aPara
			end if
		end if
	end repeat
	if simulate_warnings is not "" then
		set theURLWarningTextLabel1 to DL_Use_YTDLP & (localized string " has given a warning on the URL you entered:")
		set theURLWarningTextLabel2 to localized string "The warning message(s) was: "
		set theURLWarningTextLabel3 to (localized string "Your copy of") & " " & DL_Use_YTDLP & " " & (localized string "might be out of date. You can check that or, you can return to the main dialog or continue to see what happens.")
		set theWarningButtonsCheckLabel to localized string "Check for Updates"
		set theWarningButtonsMainLabel to localized string "Main"
		set warning_quit_or_continue to button returned of (display dialog theURLWarningTextLabel1 & return & return & URL_user_entered & return & return & theURLWarningTextLabel2 & return & return & simulate_warnings & return & theURLWarningTextLabel3 buttons {theWarningButtonsMainLabel, theWarningButtonsCheckLabel, theButtonContinueLabel} default button 3 with title diag_Title with icon note giving up after 600)
		if warning_quit_or_continue is theWarningButtonsCheckLabel then
			set alert_text_ytdl to "NotSwitching"
			check_ytdl(DL_Use_YTDLP)
			check_ffmpeg()
			display dialog alert_text_ytdl & alert_text_ffmpeg with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
			main_dialog()
		else if warning_quit_or_continue is theButtonContinueLabel then -- <= Ignore warning - try DL - get filename from last paragraph of simulate file
			set_File_Names(YTDL_simulate_response)
		else if warning_quit_or_continue is theWarningButtonsMainLabel then -- <= Stop and return to Main dialog
			main_dialog()
		end if
	else
		-- This is a non-warning download
		set_File_Names(YTDL_simulate_response)
	end if
	
	-- If user asked for subtitles, get ytdl to check whether they are available - if not, warn user - if available, check against format requested - convert if different	
	if subtitles_choice is true or DL_YTAutoST is true then
		set YTDL_subtitles to check_subtitles_download_available(subtitles_choice)
	end if
	
	-- Set the YTDL settings into one variable - makes it easier to maintain - ensure spaces are where needed - quoted to enable passing to Monitor script
	set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_Thumbnail_Write & YTDL_Thumbnail_Embed & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_output_template & " ")
	
	-- Always check whether download file exists and if so ask user what to do - YTDL refuses to overwrite and so that's done manually
	-- Beware ! This section doesn't cope with part download files which are left to klag YTDL - they should be automatically deleted but, anything can happen
	if YTDL_over_writes is "--no-overwrites " then
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
						set theABCShowExistsLabel1 to localized string "A file for the ABC show"
						set theABCShowExistsLabel2 to localized string "already exists."
						set theABCShowExistsLabel3 to localized string "Do you want to continue anyway, download with a different name or stop and return to the main dialog ?"
						set theABCShowExistsButtonOverwriteLabel to localized string "Overwrite"
						set theABCShowExistsButtonNewnameLabel to localized string "New name"
						set overwrite_continue_choice to button returned of (display dialog theABCShowExistsLabel1 & " \"" & each_filename & "\" " & theABCShowExistsLabel2 & return & return & theABCShowExistsLabel3 buttons {theABCShowExistsButtonOverwriteLabel, theABCShowExistsButtonNewnameLabel, theButtonReturnLabel} default button 3 with title diag_Title with icon note giving up after 600)
						if overwrite_continue_choice is theABCShowExistsButtonOverwriteLabel then
							-- Have to manually remove existing file because YTDL always refuses to overwrite
							set search_for_download to search_for_download as text
							set file_to_delete to quoted form of (POSIX path of (downloadsFolder_Path & "/" & search_for_download))
							do shell script "mv " & file_to_delete & " ~/.trash/"
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_output_template & " ")
						else if overwrite_continue_choice is theABCShowExistsButtonNewnameLabel then
							set YTDL_output_template_new to run_Utilities_handlers's replace_chars(YTDL_output_template, ".%(ext)s", "-2.%(ext)s")
							set set_new_download_filename to text 1 thru -5 of download_filename_new
							set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, set_new_download_filename, set_new_download_filename & "-2")
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_output_template_new & " ")
						else if overwrite_continue_choice is theButtonReturnLabel then
							my main_dialog()
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
						set theShowExistsLabel1 to localized string "A file for the SBS show"
						set theShowExistsLabel2 to localized string "already exists."
						set theShowExistsLabel3 to localized string "Do you want to continue anyway, download with a different name or stop and return to the main dialog ?"
						set theShowExistsButtonOverwriteLabel to localized string "Overwrite"
						set theShowExistsButtonNewnameLabel to localized string "New name"
						set overwrite_continue_choice to button returned of (display dialog theShowExistsLabel1 & " \"" & each_filename & "\" " & theShowExistsLabel2 & return & return & theShowExistsLabel3 buttons {theShowExistsButtonOverwriteLabel, theShowExistsButtonNewnameLabel, theButtonReturnLabel} default button 3 with title diag_Title with icon note giving up after 600)
						if overwrite_continue_choice is theShowExistsButtonOverwriteLabel then
							-- Have to manually remove existing file because YTDL always refuses to overwrite
							set search_for_download to search_for_download as text
							set file_to_delete to quoted form of (POSIX path of (downloadsFolder_Path & "/" & search_for_download))
							do shell script "mv " & file_to_delete & " ~/.trash/"
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_output_template & " ")
						else if overwrite_continue_choice is theShowExistsButtonNewnameLabel then
							set YTDL_output_template_new to run_Utilities_handlers's replace_chars(YTDL_output_template, ".%(ext)s", "-2.%(ext)s")
							set set_new_download_filename to text 1 thru -5 of download_filename_new
							set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, set_new_download_filename, set_new_download_filename & "-2")
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_output_template_new & " ")
						else if overwrite_continue_choice is theButtonReturnLabel then
							my main_dialog()
						end if
					end if
				end if
			end repeat
			-- Need to revert download_filename_new to just show_name to be passed for the Monitor and Adviser dialogs - but only for the multiple downloads !!!
			if (count of paragraphs of download_filename_new_plain) is greater than 1 then
				set download_filename_new to SBS_show_name
			end if
		else
			repeat with each_filename in (get paragraphs of YTDL_simulate_response)
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
						set theShowExistsWarningTextLabel1 to localized string "The file"
						set theShowExistsWarningTextLabel2 to localized string "already exists."
						set theShowExistsWarningTextLabel3 to localized string "Do you want to continue anyway, download with a different name or stop and return to the main dialog ?"
						set theShowExistsButtonOverwriteLabel to localized string "Overwrite"
						set theShowExistsButtonNewnameLabel to localized string "New name"
						set overwrite_continue_choice to button returned of (display dialog theShowExistsWarningTextLabel1 & " \"" & each_filename & "\" " & theShowExistsWarningTextLabel2 & return & return & theShowExistsWarningTextLabel3 buttons {theShowExistsButtonOverwriteLabel, theShowExistsButtonNewnameLabel, theButtonReturnLabel} default button 3 with title diag_Title with icon note giving up after 600)
						if overwrite_continue_choice is theShowExistsButtonOverwriteLabel then
							-- Have to manually remove existing file because YTDL always refuses to overwrite
							set search_for_download to search_for_download as text
							set file_to_delete to quoted form of (POSIX path of (downloadsFolder_Path & "/" & search_for_download))
							do shell script "mv " & file_to_delete & " ~/.trash/"
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_output_template & " ")
						else if overwrite_continue_choice is theShowExistsButtonNewnameLabel then
							set YTDL_output_template_new to run_Utilities_handlers's replace_chars(YTDL_output_template, ".%(ext)s", "-2.%(ext)s")
							set set_new_download_filename to text 1 thru -5 of download_filename_new
							set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, set_new_download_filename, set_new_download_filename & "-2")
							set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_playlist & YTDL_no_part & YTDL_output_template_new & " ")
						else if overwrite_continue_choice is theButtonReturnLabel then
							my main_dialog()
						end if
					end if
				end if
			end repeat
		end if
	end if
	
	-- Add the URL and file name to the batch file
	if DL_batch_status is true then
		add_To_Batch(URL_user_entered, download_filename)
	end if
	
	-- Prepare to call on the download Monitor - first get Monitor script location -- Monitor-bundle.scptd
	set myMonitorScriptAsString to quoted form of ((POSIX path of path_to_MacYTDL) & "Contents/Resources/Scripts/Monitor.scpt")
	
	-- Increment the monitor dialog position number - used by monitor.scpt for positioning monitor dialogs	
	set monitor_dialog_position to (monitor_dialog_position + 1)
	
	-- Pull together all the parameters to be sent to the Monitor script
	-- Set URL to quoted form so that Monitor will parse myParams correctly when URLs come from the Get_ABC_Episodes and Get_SBS_Episodes handlers - but not for single episode iView show pages
	if ABC_show_name is not "" or SBS_show_name is not "" then
		set URL_user_entered to quoted form of URL_user_entered
	end if
	
	-- Put diag title, file and path names into quotes as they are not passed to Monitor correctly when they contain apostrophes or spaces
	set download_filename to quoted form of download_filename
	set download_filename_new to quoted form of download_filename_new
	set YTDL_response_file to quoted form of YTDL_response_file
	set YTDL_simulate_response to text 1 thru -2 of YTDL_simulate_response
	set YTDL_simulate_response to quoted form of YTDL_simulate_response
	set diag_Title_quoted to quoted form of diag_Title
	
	-- Form up parameters for the following do shell script		
	set my_params to quoted form of downloadsFolder_Path & " " & quoted form of MacYTDL_preferences_path & " " & ytdl_settings & " " & URL_user_entered & " " & YTDL_response_file & " " & download_filename & " " & download_filename_new & " " & quoted form of MacYTDL_custom_icon_file_posix & " " & monitor_dialog_position & " " & YTDL_simulate_response & " " & diag_Title_quoted & " " & is_Livestream_Flag & " " & screen_width & " " & screen_height & " " & DL_Use_YTDLP
	
	-- Show current download settings if user has specified that in Settings
	if DL_Show_Settings is true then
		
		-- Convert boolean settings to text to enable list of current settings to be shown intelligibly in "Show Settings" dialog
		if YTDL_subtitles contains "--write-sub" then
			set MDDL_subtitles to "Yes"
		else
			set MDDL_subtitles to "No"
		end if
		if YTDL_subtitles contains "--write-auto-sub" then
			set MDDL_Auto_subtitles to "Yes"
		else
			set MDDL_Auto_subtitles to "No"
		end if
		if DL_Remux_original is true then
			set MDDL_Remux_original to "Yes"
		else
			set MDDL_Remux_original to "No"
		end if
		if DL_YTDL_auto_check is true then
			set MDDL_YTDL_auto_check to "Yes"
		else
			set MDDL_YTDL_auto_check to "No"
		end if
		if DL_STEmbed is true then
			set MDDL_STEmbed to "Yes"
		else
			set MDDL_STEmbed to "No"
		end if
		if DL_audio_only is true then
			set MDDL_audio_only to "Yes"
		else
			set MDDL_audio_only to "No"
		end if
		if YTDL_description is "--write-description " then
			set MDDL_description to "Yes"
		else
			set MDDL_description to "No"
		end if
		if DL_Limit_Rate is true then
			set MDDL_Limit_Rate to DL_Limit_Rate_Value & " MB/sec"
		else
			set MDDL_Limit_Rate to "No"
		end if
		if DL_over_writes is false then
			set MDDL_over_writes to "No"
		else
			set MDDL_over_writes to "Yes"
		end if
		if DL_Thumbnail_Write is true then
			set MDDL_Thumbnail_Write to "Yes "
		else
			set MDDL_Thumbnail_Write to "No"
		end if
		if DL_verbose is true then
			set MDDL_verbose to "Yes"
		else
			set MDDL_verbose to "No"
		end if
		if DL_Thumbnail_Embed is true then
			set MDDL_Thumbnail_Embed to "Yes"
		else
			set MDDL_Thumbnail_Embed to "No"
		end if
		if DL_Add_Metadata is true then
			set MDDL_Add_Metadata to "Yes"
		else
			set MDDL_Add_Metadata to "No"
		end if
		if DL_Use_Proxy is true then
			set MDDL_Use_Proxy to DL_Proxy_URL
		else
			set MDDL_Use_Proxy to "No"
		end if
		if DL_Use_Cookies is true then
			set MDDL_Use_Cookies to DL_Cookies_Location
		else
			set MDDL_Use_Cookies to "No"
		end if
		if DL_Use_Custom_Template is true then
			set MDDL_Use_Template to DL_Custom_Template
		else
			set MDDL_Use_Template to "No"
		end if
		
		-- Set contents of optional subtitles embedded status and format - only shows if subtitles are requested
		-- Ditto with whether to keep original after remuxing, embedded thumbnails, proxy, cookies and template
		set subtitles_embedded_pref to ""
		if MDDL_subtitles is "Yes" then
			set theShowSettingsPromptTextSTEmbedLabel to localized string "Embedded:"
			set subtitles_embedded_pref to return & theShowSettingsPromptTextSTEmbedLabel & tab & tab & tab & MDDL_STEmbed
		end if
		set subtitles_format_pref to ""
		if DL_subtitles is true and DL_STEmbed is false then
			set theShowSettingsPromptTextSTFormatLabel to localized string "Format:"
			set subtitles_format_pref to tab & tab & theShowSettingsPromptTextSTFormatLabel & tab & tab & DL_subtitles_format
		end if
		set keep_original_pref to ""
		if DL_Remux_format is not "No remux" or YTDL_subtitles contains "convert" then
			set theShowSettingsPromptTextKeepOrigtLabel to localized string "Keep original file(s):"
			set keep_original_pref to return & theShowSettingsPromptTextKeepOrigtLabel & tab & MDDL_Remux_original
		end if
		set theShowSettingsPromptTextEmbedThumbLabel to localized string "Embed thumbnails:"
		set thumbnails_embed_pref to theShowSettingsPromptTextEmbedThumbLabel & tab & MDDL_Thumbnail_Embed
		
		-- Set variables for the Show Settings dialog
		set theShowSettingsPromptTextFolderLabel to localized string "Download folder:"
		set theShowSettingsPromptTextYTDLLabel to DL_Use_YTDLP & " " & (localized string "version:")
		set theShowSettingsPromptTextFFmpegLabel to localized string "FFmpeg version:"
		set theShowSettingsPromptTextPythonLabel to localized string "Python version:"
		set theShowSettingsPromptTextFormatLabel to localized string "Download file format:"
		set theShowSettingsPromptTextAudioLabel to localized string "Audio only:"
		set theShowSettingsPromptTextDescriptionLabel to localized string "Description:"
		set theShowSettingsPromptTextSTLabel to localized string "Download subtitles:"
		set theShowSettingsPromptTextAutoSTLabel to localized string "Auto subtitles:"
		set theShowSettingsPromptTextRemuxLabel to localized string "Remux download:"
		set theShowSettingsPromptTextThumbsLabel to localized string "Write thumbnails:"
		set theShowSettingsPromptTextVerboseLabel to localized string "Verbose feedback:"
		set theShowSettingsPromptTextMetaDataLabel to localized string "Add metadata:"
		set theShowSettingsPromptTextOverWriteLabel to localized string "Over-write existing:"
		set theShowSettingsPromptTextLimitSpeedLabel to localized string "Limit download speed:"
		set theShowSettingsPromptTextUseProxyLabel to localized string "Use proxy:"
		set theShowSettingsPromptTextUseCookiesLabel to localized string "Use cookies:"
		set theShowSettingsPromptTextUseTemplateLabel to localized string "Custom template:"
		set diag_prompt_text_1 to theShowSettingsPromptTextFolderLabel & tab & tab & folder_chosen & return & theShowSettingsPromptTextYTDLLabel & tab & YTDL_version & return & theShowSettingsPromptTextFFmpegLabel & tab & tab & ffmpeg_version & return & theShowSettingsPromptTextPythonLabel & tab & tab & python_version & return & theShowSettingsPromptTextFormatLabel & tab & DL_format & return & theShowSettingsPromptTextAudioLabel & tab & tab & tab & MDDL_audio_only & return & theShowSettingsPromptTextDescriptionLabel & tab & tab & tab & MDDL_description & return & theShowSettingsPromptTextSTLabel & tab & MDDL_subtitles & subtitles_format_pref & subtitles_embedded_pref & return & theShowSettingsPromptTextAutoSTLabel & tab & tab & MDDL_Auto_subtitles & return & theShowSettingsPromptTextRemuxLabel & tab & tab & remux_format_choice & keep_original_pref & return & theShowSettingsPromptTextThumbsLabel & tab & tab & MDDL_Thumbnail_Write & return & thumbnails_embed_pref & return & theShowSettingsPromptTextVerboseLabel & tab & MDDL_verbose & return & theShowSettingsPromptTextMetaDataLabel & tab & tab & MDDL_Add_Metadata & return & theShowSettingsPromptTextOverWriteLabel & tab & MDDL_over_writes & return & theShowSettingsPromptTextLimitSpeedLabel & tab & MDDL_Limit_Rate & return & theShowSettingsPromptTextUseProxyLabel & tab & tab & tab & MDDL_Use_Proxy & return & theShowSettingsPromptTextUseCookiesLabel & tab & tab & tab & MDDL_Use_Cookies & return & theShowSettingsPromptTextUseTemplateLabel & tab & tab & MDDL_Use_Template
		set show_settings_diag_promptLabel to localized string "Settings for this download"
		set show_settings_diag_prompt to show_settings_diag_promptLabel
		set accViewWidth to 375
		set accViewInset to 70
		
		-- Set buttons and controls
		set theButtonsShowSettingsEditLabel to localized string "Edit settings"
		set {theButtons, minWidth} to create buttons {theButtonQuitLabel, theButtonsShowSettingsEditLabel, theButtonCancelLabel, theButtonDownloadLabel} button keys {"q", "e", "c", "d"} default button 4
		if minWidth > accViewWidth then set accViewWidth to minWidth
		set {theShowSettingsRule, theTop} to create rule 10 rule width accViewWidth
		set show_settings_theCheckboxLabel to localized string "Show settings before download"
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
		
		if showSettingsButtonNumberReturned is 3 then
			main_dialog()
		else if showSettingsButtonNumberReturned is 2 then
			set_settings(URL_user_entered_clean)
		else if showSettingsButtonNumberReturned is 1 then
			quit_MacYTDL()
		end if
		
		-- If user chooses to Download processing continues to next line of code
		
	end if
	
	-- PRODUCTION CALL - Call the download Monitor script which will run as a separate process and return so Main Dialog can be re-displayed - thus user can start any number of downloads
	do shell script "osascript -s s " & myMonitorScriptAsString & " " & my_params & " " & " > /dev/null 2> /dev/null &"
	
	-- TESTING CALL - Call the download Monitor script for testing - this formulation gets any errors back from Monitor, but holds execution until Monitor dialog is dismissed
	-- do shell script "osascript -s s " & myMonitorScriptAsString & " " & my_params
	
	-- After download, reset URLs so text box is blank and old URL not used again, ABC & SBS show name and myNum so that correct file name is used for next download
	set URL_user_entered to ""
	set ABC_show_name to ""
	set SBS_show_name to ""
	set SBS_show_URLs to ""
	set ABC_show_URLs to ""
	set URL_user_entered_clean to ""
	set myNum to 0
	set the clipboard to ""
	
	main_dialog()
	
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
		set theCookiesFileMissingLabel to localized string "Your cookies file is not available. You can make it available then click on Continue, return to set a new cookies location or quit."
		set quit_or_return to button returned of (display dialog theCookiesFileMissingLabel buttons {theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel} default button 2 cancel button 1 with title diag_Title with icon note giving up after 600)
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
-- Check that download folder is available - in case user has not mounted an external volume or has moved/renamed the folder
on check_download_folder(folder_chosen)
	if folder_chosen = downloadsFolder_Path then
		set downloadsFolder_Path_posix to (POSIX file downloadsFolder_Path)
		try
			set downloadsFolder_Path_alias to downloadsFolder_Path_posix as alias
		on error
			set theDownloadFolderMissingLabel to localized string "Your download folder is not available. You can make it available then click on Continue, return to set a new download folder or quit."
			set quit_or_return to button returned of (display dialog theDownloadFolderMissingLabel buttons {theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel} default button 2 cancel button 1 with title diag_Title with icon note giving up after 600)
			if quit_or_return is theButtonReturnLabel then
				main_dialog()
			else if quit_or_return is theButtonQuitLabel then
				quit_MacYTDL()
			end if
		end try
	end if
	-- If user clicks "Continue" processing returns to after call to this handler and download process commences
end check_download_folder


------------------------------------------------------------
--
-- 	Try to get correct file names for use elsewhere
--
------------------------------------------------------------
on set_File_Names(YTDL_simulate_response)
	
	-- Set download_filename_new which is used to show a name in the Monitor dialog and forms basis for response file name
	-- Set download_filename which is used by Adviser to open downloaded file (called download_filename_monitor)
	-- Reformat file name and add to name of responses file - converting spaces to underscores to reduce need for quoting throughout code
	
	set num_paragraphs_response to count of paragraphs of YTDL_simulate_response
	set AppleScript's text item delimiters to " "
	set number_of_URLs to number of text items in URL_user_entered
	set AppleScript's text item delimiters to ""
	
	-- Get date and time so it can be added to response file name
	set download_date_time to get_Date_Time()
	
	-- First, look for non-View show pages (but iView non-error single downloads are included)
	if ABC_show_name is "" and SBS_show_name is "" then -- not an ABC or SBS show page
		if number_of_URLs is 1 then -- Single file download or playlist
			set download_filename to YTDL_simulate_response
			if YTDL_simulate_response does not contain "WARNING:" and YTDL_simulate_response does not contain "ERROR:" then --<= A single file or playlist download non-error and non-warning (iView and non-iView)
				if num_paragraphs_response is 2 then --<= A single file download (iView and non-iView) - need to trim ".mp4<para>" from end of file (which is a single line containing one file name)
					if YTDL_simulate_response contains "/" then
						set offsetOfLastSlash to last_offset(YTDL_simulate_response, "/") + 2
						set download_filename_only to text offsetOfLastSlash thru -2 of YTDL_simulate_response
						set download_filename_trimmed to text offsetOfLastSlash thru -6 of YTDL_simulate_response
					else
						set download_filename_only to text 1 thru -2 of YTDL_simulate_response
						set download_filename_trimmed to text 1 thru -6 of YTDL_simulate_response
					end if
					set download_filename_trimmed to run_Utilities_handlers's replace_chars(download_filename_trimmed, " ", "_")
					set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_only, " ", "_")
					set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-" & download_filename_trimmed & "-" & download_date_time & ".txt"
				else --<= Probably a Youtube playlist - but beware as there can be playlists on other sites
					if playlist_Name is not "" then
						set download_filename_new to playlist_Name
						set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, " ", "_")
					else
						set download_filename_new to "the-playlist"
					end if
					set download_filename to YTDL_simulate_response
					set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-" & download_filename_new & "-" & download_date_time & ".txt"
				end if
			else if YTDL_simulate_response contains "WARNING:" and YTDL_simulate_response does not contain "ERROR:" then --<= Single file download but simulate.txt contains WARNING(S)  (iView and non-iView) - need to trim warning paras and ".mp4<para>" from end of simulate response
				set numParas to count paragraphs in YTDL_simulate_response
				set YTDL_simulate_response to paragraph (numParas - 1) of YTDL_simulate_response
				set download_filename to YTDL_simulate_response
				if text -1 thru -6 of YTDL_simulate_response contains "." then
					set download_filename_trimmed to text 1 thru -6 of YTDL_simulate_response
				else
					set download_filename_trimmed to download_filename
				end if
				set download_filename_new to run_Utilities_handlers's replace_chars(download_filename, " ", "_")
				set download_filename_trimmed to run_Utilities_handlers's replace_chars(download_filename_trimmed, " ", "_")
				set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-" & download_filename_trimmed & "-" & download_date_time & ".txt"
			else if YTDL_simulate_response contains "ERROR:" then --<= Single file download or playlist but simulate.txt contains ERROR (iView and non-iView) - need a generic file name for non-playlists
				if playlist_Name is not "" then
					set download_filename_new to playlist_Name
					set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, " ", "_")
				else
					set download_filename_new to "the-error-download"
				end if
				set download_filename to YTDL_simulate_response
				set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-" & download_filename_new & "-" & download_date_time & ".txt"
			end if
		else --<= This is a multiple file (iView and non-iView) download - don't distinguish between iView and others - covers warning and non-warning cases
			set download_filename to YTDL_simulate_response
			set download_filename_new to "the multiple videos"
			set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-Multiple_download_on-" & download_date_time & ".txt"
		end if
	else if ABC_show_name is not "" then
		-- Second, look for iView show page downloads (which are all ERROR: cases)	
		if myNum is 0 then
			-- Look for iView single show page downloads - no episodes are shown on these pages - so, have to simulate to get file name - there is usually no separate series name available as the show is also the series
			set download_filename to text 1 thru -1 of (do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & URL_user_entered & " " & YTDL_output_template)
			set download_filename_new to run_Utilities_handlers's replace_chars(download_filename, " ", "_")
			set download_filename_trimmed to text 1 thru -5 of download_filename_new
			set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-" & download_filename_trimmed & "-" & download_date_time & ".txt"
		else if myNum is 1 then
			-- Look for iView single episode page downloads - just one episode is shown on these pages - so, have to simulate to get file name
			set download_filename to text 1 thru -1 of (do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & URL_user_entered & " " & YTDL_output_template)
			set download_filename_new to run_Utilities_handlers's replace_chars(download_filename, " ", "_")
			set download_filename_trimmed to text 1 thru -5 of download_filename_new
			set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-" & download_filename_trimmed & "-" & download_date_time & ".txt"
		else
			-- Look for iView episode show page downloads - two or more episodes are shown on web page and so ABC_show_name is populated in Get_ABC_episodes handler			
			set download_filename to text 1 thru -1 of (do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & ABC_show_URLs & " " & YTDL_output_template)
			set download_filename_new to run_Utilities_handlers's replace_chars(download_filename, " ", "_")
			set ABC_show_name_underscore to run_Utilities_handlers's replace_chars(ABC_show_name, " ", "_")
			set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-" & ABC_show_name_underscore & "-" & download_date_time & ".txt"
		end if
	else if SBS_show_name is not "" then
		-- Second, look for SBS show page downloads (which are all ERROR: cases)	
		if myNum is 1 then
			-- Look for SBS single episode page downloads - just one episode is shown on these pages - so, have to simulate to get file name
			set download_filename to text 1 thru -1 of (do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & URL_user_entered & " " & YTDL_output_template)
			set download_filename_new to run_Utilities_handlers's replace_chars(download_filename, " ", "_")
			set download_filename_trimmed to text 1 thru -5 of download_filename_new
			set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-" & download_filename_trimmed & "-" & download_date_time & ".txt"
		else
			-- Look for OnDemand episode show page downloads - two or more episodes are shown on web page and so SBS_show_name is populated in Get_SBS_episodes handler			
			set download_filename to text 1 thru -1 of (do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; export LC_CTYPE=UTF-8 ; " & DL_Use_YTDLP & " --get-filename --ignore-errors " & SBS_show_URLs & " " & YTDL_output_template)
			set download_filename_new to run_Utilities_handlers's replace_chars(download_filename, " ", "_")
			set SBS_show_name_underscore to run_Utilities_handlers's replace_chars(SBS_show_name, " ", "_")
			set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-" & SBS_show_name_underscore & "-" & download_date_time & ".txt"
		end if
	end if
	
	-- Make sure there are no colons in the file name - can happen with iView and maybe others - ytdl converts colons into "_-" so, this must also
	set download_filename_new to run_Utilities_handlers's replace_chars(download_filename_new, ":", "_-")
	
	-- **************** Dialog to show variable values set by this handler
	-- display dialog "num_paragraphs_response: " & num_paragraphs_response & return & return & "number_of_URLs: " & number_of_URLs & return & return & "URL_user_entered: " & URL_user_entered & return & return & "show_name: " & show_name & return & return & "myNum: " & myNum & return & return & "download_filename_new: " & download_filename_new & return & return & "YTDL_response_file: " & YTDL_response_file
	-- ***************** 
	
end set_File_Names


-----------------------------------------------------------------------
--
-- 		Check subtitles are available and in desired language
--
-----------------------------------------------------------------------
-- Handler to check that requested subtitles are available and apply conversion if not - called by download_video() when user requests subtitles or auto-subtitles
-- Might not need the duplication in this handler - leave till a later release - Handles ABC, SBS show URL and multiple URLs somewhat
on check_subtitles_download_available(subtitles_choice)
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
		set theAutoSTWillNotWorkLabel to localized string "You have specified auto-generated subtitles but not from Youtube. It will not work. Do you want to try author generated subtitles, continue without subtitles or cancel this download and return to the Main dialog ?"
		set theButtonContinueGoAuthorLabel to localized string "Try author"
		set auto_subtitles_stop_or_continue to button returned of (display dialog theAutoSTWillNotWorkLabel buttons {theButtonContinueGoAuthorLabel, theButtonContinueLabel, theButtonReturnLabel} default button 1 with title diag_Title with icon note giving up after 600)
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
	if check_subtitles_available does not contain "Language formats" then
		set theSTNotAvailableLabel1 to localized string "There is no subtitle file available for your video (although it might be embedded)."
		set theSTNotAvailableLabel2 to localized string "You can quit, stop and return or download anyway."
		set subtitles_quit_or_continue to button returned of (display dialog theSTNotAvailableLabel1 & return & return & theSTNotAvailableLabel2 buttons {theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel} default button 3 with title diag_Title with icon note giving up after 600)
		if subtitles_quit_or_continue is theButtonQuitLabel then
			quit_MacYTDL()
		else if subtitles_quit_or_continue is theButtonReturnLabel then
			main_dialog()
		else
			return YTDL_subtitles
		end if
	else if check_subtitles_available contains "Language formats" then
		-- Subtitles are available - check what kind and consider w.r.t settings
		-- Auto-gen requested but only author-gen available - what to do ?
		if auto_gen is true and author_gen is false and check_subtitles_available does not contain "Available automatic captions for" and check_subtitles_available contains "Available subtitles for" then
			set theNoAutoYesAuthorLabel to localized string "You have specified auto-generated subtitles but only author generated are available. Do you want author generated subtitles, continue without subtitles or cancel this download and return to the Main dialog ?"
			set theButtonContinueGoAuthorLabel to localized string "Get author"
			set auto_subtitles_stop_or_continue to button returned of (display dialog theAutoSTWillNotWorkLabel buttons {theButtonContinueGoAuthorLabel, theButtonContinueLabel, theButtonReturnLabel} default button 1 with title diag_Title with icon note giving up after 600)
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
			set theNoAutoYesAuthorLabel to localized string "You have specified author-generated subtitles but only auto-generated are available. Do you want auto-generated subtitles, continue without subtitles or cancel this download and return to the Main dialog ?"
			set theButtonContinueGoAutoLabel to localized string "Get auto"
			set auto_subtitles_stop_or_continue to button returned of (display dialog theNoAutoYesAuthorLabel buttons {theButtonContinueGoAutoLabel, theButtonContinueLabel, theButtonReturnLabel} default button 1 with title diag_Title with icon note giving up after 600)
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
		set response_ST_paragraphs to paragraphs of check_subtitles_available
		set show_languages_avail to ""
		set AppleScript's text item delimiters to "  "
		repeat with response_subtitle_paragraph in response_ST_paragraphs
			-- Loop thru all paragraphs - collect those which contain subtitle info - look @ all paragraphs because can have >1 download - collate languages avail into one variable
			if response_subtitle_paragraph contains "      " or character 3 of response_subtitle_paragraph is "-" then
				set subtitles_info to subtitles_info & response_subtitle_paragraph & return
				set lang_code to text item 1 of response_subtitle_paragraph
				set show_languages_avail to show_languages_avail & lang_code & ", "
			end if
		end repeat
		set AppleScript's text item delimiters to ""
		
		-- Isolate case when both author-gen and auto-gen are available but user requests wrong one due to language non-availability
		if subtitles_info does not contain (DL_STLanguage & " ") then
			set theSTLangNotAvailableLabel1 to localized string "There is no subtitle file in your preferred language "
			set theSTLangNotAvailableLabel2 to localized string "These languages are available: "
			set theSTLangNotAvailableLabel3 to localized string "You can quit, cancel your download (then go to Settings to change language) or download anyway."
			set subtitles_quit_or_continue to button returned of (display dialog theSTLangNotAvailableLabel1 & "\"" & DL_STLanguage & "\". " & theSTLangNotAvailableLabel2 & return & return & show_languages_avail & return & return & theSTLangNotAvailableLabel3 buttons {theButtonQuitLabel, theButtonReturnLabel, theButtonContinueLabel} default button 3 with title diag_Title with icon note giving up after 600)
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
					set theButtonContinueGoLabel to localized string "Get author"
					set alt_lang_avail to "Y"
				end if
				if author_gen_subtitles does not contain (DL_STLanguage & " ") and auto_gen_subtitles contains (DL_STLanguage & " ") and auto_gen is false then
					set dialog_1_text to "author-generated "
					set dialog_2_text to "auto-generated "
					set dialog_3_text to auto_gen_subtitles
					set theButtonContinueGoLabel to localized string "Get auto"
					set alt_lang_avail to "Y"
				end if
				if alt_lang_avail is "Y" then
					set theSTLangNotAvailableLabel1 to localized string "There is no " & dialog_1_text & "subtitle file in your preferred language "
					set theSTLangNotAvailableLabel2 to localized string " But, " & dialog_2_text & "subtitles are available."
					set theSTLangNotAvailableLabel3 to localized string "You cancel your download, download " & dialog_2_text & "subtitles or download without subtitles."
					set subtitles_quit_or_continue to button returned of (display dialog theSTLangNotAvailableLabel1 & "\"" & DL_STLanguage & "\". " & theSTLangNotAvailableLabel2 & return & return & theSTLangNotAvailableLabel3 buttons {theButtonReturnLabel, theButtonContinueGoLabel, theButtonContinueLabel} default button 3 with title diag_Title with icon note giving up after 600)
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
		-- Is desired format available - if so continue - if not convert - conversion can currently handle only src, ass, lrc and vtt - passing best, dfxp or ttml uses YTDL's own choice
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
				set YTDL_subtitles to "--write-auto-sub --sub-format " & DL_subtitles_format & " " & "--sub-lang " & DL_STLanguage & " "
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
				set YTDL_subtitles to "--write-auto-sub --write-sub --sub-format " & DL_subtitles_format & " " & "--sub-lang " & DL_STLanguage & " "
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
	set AppleScript's text item delimiters to " "
	set the item_list to every text item of download_date_time
	set AppleScript's text item delimiters to "_"
	set download_date_time to the item_list as string
	set AppleScript's text item delimiters to ":"
	set the item_list to every text item of download_date_time
	set AppleScript's text item delimiters to "_"
	set download_date_time to the item_list as string
	set AppleScript's text item delimiters to ","
	set the item_list to every text item of download_date_time
	set AppleScript's text item delimiters to "_"
	set download_date_time to the item_list as string
	set AppleScript's text item delimiters to "__"
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

-- Handler for showing dialog to set various MacYTDL and youtube-dl/YT-DLP settings
-- Setting for overwrites is hidden until YTDL developers decide what to do with overwrites problem (see Pull Request 20405)
on set_settings(URL_user_entered_clean)
	run_Utilities_handlers's read_settings(MacYTDL_prefs_file)
	
	-- Set variables for the settings dialog	
	set theSettingsDiagPromptLabel to localized string "Settings"
	set settings_diag_prompt to theSettingsDiagPromptLabel
	set accViewWidth to 450
	set accViewInset to 0
	
	-- Set buttons and controls
	set theButtonsSaveLabel to localized string "Save Settings"
	set {theButtons, minWidth} to create buttons {theButtonCancelLabel, theButtonsSaveLabel} button keys {"c", ""} default button 2
	--if minWidth > accViewWidth then set accViewWidth to minWidth --<= Not needed as two buttons narrower than the dialog - keep in case things change
	set {theSettingsRule, theTop} to create rule 10 rule width accViewWidth
	set theCheckboxShowSettingsLabel to localized string "Show settings before download"
	set {settings_theCheckbox_Show_Settings, theTop} to create checkbox theCheckboxShowSettingsLabel left inset 70 bottom (theTop + 10) max width 200 initial state DL_Show_Settings
	set theFieldCustomTemplateLabel to localized string "Custom file name template"
	set {settings_theField_Custom_Template, theTop} to create field DL_Custom_Template left inset 230 bottom (theTop + 10) field width 200 placeholder text theFieldCustomTemplateLabel
	set theCheckBoxUseCustomTemplateLabel to localized string "Use custom template"
	set {settings_theCheckbox_Use_CustomTemplate, theTop} to create checkbox theCheckBoxUseCustomTemplateLabel left inset 70 bottom (theTop - 20) max width 150 initial state DL_Use_Custom_Template
	set {settings_theCookiesLocationPathControl, theTop} to create path control (POSIX path of DL_Cookies_Location) left inset 250 bottom (theTop + 5) control width 150 with pops up
	set theCheckboxUseCookiesLabel to localized string "Use cookies"
	set {settings_theCheckBox_Use_Cookies, the Top} to create checkbox theCheckboxUseCookiesLabel left inset 70 bottom (theTop - 20) max width 150 initial state DL_Use_Cookies
	set theFieldProxyURLPlaceholderLabel to localized string "No URL set"
	set {settings_theField_ProxyURL, theTop} to create field DL_Proxy_URL left inset 175 bottom (theTop + 5) field width 250 placeholder text theFieldProxyURLPlaceholderLabel
	set theCheckboxUseProxyLabel to localized string "Use proxy"
	set {settings_theCheckBox_Use_Proxy, the Top} to create checkbox theCheckboxUseProxyLabel left inset 70 bottom (theTop - 18) max width 100 initial state DL_Use_Proxy
	set {settings_theField_LimitRateValue, theTop} to create field DL_Limit_Rate_Value left inset 300 bottom (theTop + 5) field width 40
	set theCheckboxLimitRateLabel to localized string "Limit download speed (MB/sec)"
	set {settings_theCheckbox_Limit_Rate, theTop} to create checkbox theCheckboxLimitRateLabel left inset 70 bottom (theTop - 18) max width 200 initial state DL_Limit_Rate
	set theCheckboxKeepOriginalLabel to localized string "Keep original video and/or subtitles file"
	set {settings_theCheckbox_Original, theTop} to create checkbox theCheckboxKeepOriginalLabel left inset 70 bottom (theTop + 8) max width 200 initial state DL_Remux_original
	set theLabeledPopupRemuxFormatLabel to localized string "Remux format:"
	set {settings_thePopUp_RemuxFormat, settings_remuxlabel, theTop} to create labeled popup {"No remux", "mp4", "mkv", "webm", "ogg", "avi", "flv"} left inset 70 bottom (theTop + 5) popup width 100 max width 200 label text theLabeledPopupRemuxFormatLabel popup left 170 initial choice DL_Remux_format
	set theCheckboxMetadataLabel to localized string "Add metadata"
	set {settings_theCheckbox_Metadata, theTop} to create checkbox theCheckboxMetadataLabel left inset 70 bottom (theTop + 5) max width 250 initial state DL_Add_Metadata
	set theCheckboxVerboseLabel to localized string "Verbose logging"
	set {settings_theCheckbox_Verbose, theTop} to create checkbox theCheckboxVerboseLabel left inset 70 bottom (theTop + 5) max width 250 initial state DL_verbose
	set theCheckboxEmbedThumbsLabel to localized string "Embed thumbnails"
	set {settings_theCheckbox_ThumbEmbed, theTop} to create checkbox theCheckboxEmbedThumbsLabel left inset 280 bottom (theTop + 5) max width 250 initial state DL_Thumbnail_Embed
	set theCheckboxWriteThumbsLabel to localized string "Write thumbnails"
	set {settings_theCheckbox_ThumbWrite, theTop} to create checkbox theCheckboxWriteThumbsLabel left inset 70 bottom (theTop - 18) max width 250 initial state DL_Thumbnail_Write
	set theCheckboxDLAutoSTsLabel to localized string "Auto-generated subtitles"
	set {settings_theCheckbox_AutoSubTitles, theTop} to create checkbox theCheckboxDLAutoSTsLabel left inset 70 bottom (theTop + 5) max width 250 initial state DL_YTAutoST
	set theCheckboxEmbedSTsLabel to localized string "Embed subtitles"
	set {settings_theCheckbox_STEmbed, theTop} to create checkbox theCheckboxEmbedSTsLabel left inset 70 bottom (theTop + 5) max width 250 initial state DL_STEmbed
	set theLabeledFieldSTsLangLabel to localized string "Subtitles language:"
	set {settings_theField_STLanguage, settings_language_label, theTop, fieldLeft} to create side labeled field DL_STLanguage left inset 70 bottom (theTop + 5) total width 200 label text theLabeledFieldSTsLangLabel field left 0
	set theLabeledPopUpSTsFormatLabel to localized string "Subtitles format:"
	set {settings_thePopUp_SubTitlesFormat, settings_STFormatlabel, theTop} to create labeled popup {theBestLabel, "srt", "vtt", "ass", "lrc", "ttml", "dfxp"} left inset 245 bottom (theTop) popup width 65 max width 250 label text theLabeledPopUpSTsFormatLabel popup left 385 initial choice DL_subtitles_format
	set theCheckboxDLSTsLabel to localized string "Download subtitles"
	set {settings_theCheckbox_SubTitles, theTop} to create checkbox theCheckboxDLSTsLabel left inset 70 bottom (theTop - 20) max width 250 initial state DL_subtitles
	set theCheckboxCheckYTDLOnStartLabel to (localized string "Check") & " " & DL_Use_YTDLP & " " & (localized string "version on startup")
	set {settings_theCheckbox_Auto_YTDL_Check, theTop} to create checkbox theCheckboxCheckYTDLOnStartLabel left inset 70 bottom (theTop + 5) max width 250 initial state DL_YTDL_auto_check
	-- set {settings_theCheckbox_OverWrites, theTop} to create checkbox "Over-write existing files" left inset 70 bottom (theTop + 5) max width 250 initial state DL_over_writes
	set theLabeledPopupCodecLabel to localized string "Audio format:"
	set {settings_thePopup_AudioCodec, settingsCodecLabel, theTop} to create labeled popup {theBestLabel, "aac", "flac", "mp3", "m4a", "opus", "vorbis", "wav"} left inset 220 bottom (theTop + 2) popup width 90 max width 200 label text theLabeledPopupCodecLabel popup left 350 initial choice DL_audio_codec
	set theCheckboxAudioOnlyLabel to localized string "Audio only"
	set {settings_theCheckbox_AudioOnly, theTop} to create checkbox theCheckboxAudioOnlyLabel left inset 70 bottom (theTop - 22) max width 250 initial state DL_audio_only
	set theCheckboxDLDescriptionLabel to localized string "Download description"
	set settings_theCheckbox_DescriptionLabel to localized string theCheckboxDLDescriptionLabel
	set {settings_theCheckbox_Description, theTop} to create checkbox settings_theCheckbox_DescriptionLabel left inset 70 bottom (theTop + 5) max width 250 initial state DL_description
	set theLabeledPopUpFileFormatLabel to localized string "File format:"
	if diag_Title contains "Versión" then
		-- Reposition file format popup if language is Spanish
		set fileFormat_popup_left_value to 205
	else
		set fileFormat_popup_left_value to 150
	end if
	set {settings_thePopUp_FileFormat, settings_formatlabel, theTop} to create labeled popup {theDefaultLabel, "mp4", "webm", "ogg", "3gp", "flv"} left inset 70 bottom (theTop + 5) popup width 90 max width 200 label text theLabeledPopUpFileFormatLabel popup left fileFormat_popup_left_value initial choice DL_format
	set theLabelPathChangeDLFolderLabel to localized string "Change download folder:"
	set {settings_thePathControl, settings_pathLabel, theTop} to create labeled path control (POSIX path of downloadsFolder_Path) left inset 70 bottom (theTop + 10) control width 150 label text theLabelPathChangeDLFolderLabel with pops up
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 50 view width 64 view height 64 scale image scale proportionally
	set {settings_prompt, theTop} to create label settings_diag_prompt left inset 0 bottom (theTop) max width accViewWidth aligns center aligned with bold type
	set settings_allControls to {theSettingsRule, settings_theCheckbox_Show_Settings, settings_theCheckbox_Use_CustomTemplate, settings_theField_Custom_Template, settings_theCheckBox_Use_Cookies, settings_theCookiesLocationPathControl, settings_theCheckBox_Use_Proxy, settings_theField_ProxyURL, settings_theCheckbox_Limit_Rate, settings_theField_LimitRateValue, settings_theCheckbox_Original, settings_thePopUp_RemuxFormat, settings_remuxlabel, settings_theCheckbox_Metadata, settings_theCheckbox_Verbose, settings_theCheckbox_ThumbEmbed, settings_theCheckbox_ThumbWrite, settings_theCheckbox_AutoSubTitles, settings_thePopUp_SubTitlesFormat, settings_STFormatlabel, settings_theField_STLanguage, settings_language_label, settings_theCheckbox_STEmbed, settings_theCheckbox_SubTitles, settings_theCheckbox_Auto_YTDL_Check, settings_theCheckbox_AudioOnly, settings_thePopup_AudioCodec, settingsCodecLabel, settings_theCheckbox_Description, settings_thePopUp_FileFormat, settings_formatlabel, settings_thePathControl, settings_pathLabel, MacYTDL_icon, settings_prompt}
	
	-- Make sure MacYTDL is in front and show dialog
	tell me to activate
	set {settings_button_returned, settings_button_number_returned, settings_controls_results} to display enhanced window diag_Title buttons theButtons acc view width accViewWidth acc view height theTop acc view controls settings_allControls initial position window_Position
	
	if settings_button_number_returned is 2 then -- Save Settings
		-- Get control results from settings dialog - numbered choice variables are not used but help ensure correct values go into prefs file
		--set settings_choice_1 to item 1 of settings_controls_results -- <= The ruled line
		set settings_show_settings_choice to item 2 of settings_controls_results -- <= Show settings before download choice
		set settings_use_custom_template_choice to item 3 of settings_controls_results -- <= Use custom template choice
		set settings_custom_template_choice to item 4 of settings_controls_results -- <= The custom template to use
		set settings_use_cookies_choice to item 5 of settings_controls_results -- <= Use proxy choice
		set settings_cookies_location_choice to item 6 of settings_controls_results -- <= The proxy URL
		set settings_use_proxy_choice to item 7 of settings_controls_results -- <= Use proxy choice
		set settings_proxy_URL_choice to item 8 of settings_controls_results -- <= The proxy URL
		set settings_limit_rate_choice to item 9 of settings_controls_results -- <= Limit rate choice
		set settings_limit_rate_value_choice to item 10 of settings_controls_results -- <= Limit rate value choice
		set settings_original_choice to item 11 of settings_controls_results -- <= Keep original after remux choice
		set settings_remux_format_choice to item 12 of settings_controls_results -- <= Remux format choice
		-- set settings_choice_13 to item 13 of settings_controls_results -- <= The Remux format popup label
		set settings_metadata_choice to item 14 of settings_controls_results -- <= Add metadata choice
		set settings_verbose_choice to item 15 of settings_controls_results -- <= Verbose choice
		set settings_thumb_embed_choice to item 16 of settings_controls_results -- <= Embed Thumbnails choice
		set settings_thumb_write_choice to item 17 of settings_controls_results -- <= Write Thumbnails choice
		set settings_autoST_choice to item 18 of settings_controls_results -- <= Auto-gen subtitles choice
		set settings_subtitlesformat_choice to item 19 of settings_controls_results -- <= Subtitles format choice
		-- set settings_STFormatlabel_choice to item 20 of settings_controls_results -- <= Subtitles format popup label
		set settings_subtitleslanguage_choice to item 21 of settings_controls_results -- <= Subtitles language choice
		-- set settings_subtitleslanguage_22 to item 22 of settings_controls_results -- <= Subtitles language field label
		set settings_stembed_choice to item 23 of settings_controls_results -- <= Embed subtitles choice
		set settings_subtitles_choice to item 24 of settings_controls_results -- <= Subtitles choice
		set settings_YTDL_auto_choice to item 25 of settings_controls_results -- <= Auto check YTDL version on startup choice
		set settings_audio_only_choice to item 26 of settings_controls_results -- <= Audio only choice
		set settings_audio_codec_choice to item 27 of settings_controls_results -- <= Audio codec choice
		-- set settings_audiocodec_28 to item 28 of settings_controls_results -- <= Audio codec field label
		set settings_description_choice to item 29 of settings_controls_results -- <= Description choice
		set settings_format_choice to item 30 of settings_controls_results -- <= File format choice
		-- set settings_choice_31 to item 31 of settings_controls_results -- <= The Format popup label
		set settings_folder_choice to item 32 of settings_controls_results -- <= The download path choice
		-- set settings_choice_33 to item 33 of settings_controls_results -- <= The Path label
		-- set settings_choice_34 to item 34 of settings_controls_results -- <= The MacYTDL icon
		-- set settings_choice_35 to item 35 of settings_controls_results -- <= Contains the "About" text
		
		-- Save new settings to preferences file - no error checking needed for these
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Remux_Format" to settings_remux_format_choice
				set value of property list item "FileFormat" to settings_format_choice
				set value of property list item "Over-writes allowed" to false
				set value of property list item "Verbose" to settings_verbose_choice
				set value of property list item "Audio_Only" to settings_audio_only_choice
				set value of property list item "Audio_Codec" to settings_audio_codec_choice
				set value of property list item "Description" to settings_description_choice
				set value of property list item "Thumbnail_Write" to settings_thumb_write_choice
				set value of property list item "Subtitles_YTAuto" to settings_autoST_choice
				set value of property list item "Subtitles_Language" to settings_subtitleslanguage_choice
				set value of property list item "Subtitles_Format" to settings_subtitlesformat_choice
				set value of property list item "SubTitles" to settings_subtitles_choice
				set value of property list item "Auto_Check_YTDL_Update" to settings_YTDL_auto_choice
				set value of property list item "Add_Metadata" to settings_metadata_choice
				set value of property list item "Show_Settings_before_Download" to settings_show_settings_choice
			end tell
		end tell
		
		-- Check proxy URL starts with a valid protocol
		if settings_proxy_URL_choice is not "" then
			set protocol_chosen to text 1 thru 5 of settings_proxy_URL_choice
			if protocol_chosen is not "http:" and protocol_chosen is not "https" and protocol_chosen is not "socks" then
				set theNeedValidProtocolLabel to localized string "Sorry, you need a valid protocol for a proxy URL (http, https or socks)."
				display dialog theNeedValidProtocolLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
				set_settings(URL_user_entered_clean)
			end if
		end if
		-- Check that user has a valid proxy URL if Use Proxy is on
		if settings_use_proxy_choice is true and settings_proxy_URL_choice is "" then
			set theMustProvideProxyURLLabel to localized string "Sorry, you need a proxy URL to use a proxy for downloads."
			display dialog theMustProvideProxyURLLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
			set_settings(URL_user_entered_clean)
		end if
		-- Now can go ahead and set the proxy settings
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Proxy_URL" to settings_proxy_URL_choice
				set value of property list item "Use_Proxy" to settings_use_proxy_choice
			end tell
		end tell
		
		-- Check that user has supplied cookies location if use cookies is on
		if settings_use_cookies_choice is true and settings_cookies_location_choice is "/No Cookie File" then
			set theMustProvideProxyLocationLabel to localized string "Sorry, you need to give the location of your cookies file."
			display dialog theMustProvideProxyLocationLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
			set_settings(URL_user_entered_clean)
		end if
		-- Now can go ahead and set the cookies settings
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Use_Cookies" to settings_use_cookies_choice
				set value of property list item "Cookies_Location" to settings_cookies_location_choice
			end tell
		end tell
		
		-- Check that user has supplied custom template - add .%(ext)s if necessary
		if settings_use_custom_template_choice is true and settings_custom_template_choice is "" then
			set theMustProvideCustomTemplateLabel to localized string "Sorry, you have not provided a custom file name template."
			display dialog theMustProvideCustomTemplateLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
			set_settings(URL_user_entered_clean)
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
		
		-- If user has set download path to a file, use parent folder for downloads
		tell application "System Events" to set test_DL_folder to (get class of item (settings_folder_choice as text)) as text
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
		
		-- Check for valid download limit rate - if limit rate is true then the rate value must be positive real number
		try
			set settings_limit_rate_value_choice to settings_limit_rate_value_choice as real
		on error
			set theLimitRateInvalidLabel to localized string "Sorry, you need a positive real number to limit download speed."
			display dialog theLimitRateInvalidLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
			set_settings(URL_user_entered_clean)
		end try
		if settings_limit_rate_choice is true and (settings_limit_rate_value_choice is "" or settings_limit_rate_value_choice is less than or equal to 0) then
			set theLimitRateInvalidLabel to localized string "Sorry, you need a positive real number to limit download speed."
			display dialog theLimitRateInvalidLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
			set_settings(URL_user_entered_clean)
		end if
		-- Now can go ahead and set the download speed settings
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Limit_Rate" to settings_limit_rate_choice
				set value of property list item "Limit_Rate_Value" to settings_limit_rate_value_choice
			end tell
		end tell
		
		-- Check for invalid choice of subtitles and embedding and if OK, save to preferences file
		if settings_subtitles_choice is false and settings_autoST_choice is false and settings_stembed_choice is true then
			set theSTsEmbeddedTogetherLabel to localized string "Sorry, you need to turn on subtitles if you want them embedded."
			display dialog theSTsEmbeddedTogetherLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
			set_settings(URL_user_entered_clean)
		end if
		
		-- Check for invalid choice of subtitles embedding and file format
		if settings_stembed_choice is true and (settings_format_choice is not "mp4" and settings_format_choice is not "mkv" and settings_format_choice is not "webm" and settings_remux_format_choice is not "webm" and settings_remux_format_choice is not "mkv" and settings_remux_format_choice is not "mp4") then
			set theSTsEmbeddedFileformatLabel to localized string "Sorry, File format or Remux format must be mp4, mkv or webm for subtitles to be embedded."
			display dialog theSTsEmbeddedFileformatLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
			set_settings(URL_user_entered_clean)
		end if
		-- Now can go ahead and set the subtitles embedding settings
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "SubTitles_Embedded" to settings_stembed_choice
			end tell
		end tell
		
		--	Check whether subtitles will be converted - to determine whether keep original is valid
		if settings_subtitles_choice is true and settings_subtitlesformat_choice is not theBestLabel and settings_subtitlesformat_choice is not "ttml" and settings_subtitlesformat_choice is not "dfxp" then
			set subtitles_being_converted to true
		else
			set subtitles_being_converted to false
		end if
		
		-- Check for invalid choice of keep original after remux or subtitles converted and if OK, save to preferences file
		if settings_original_choice is true and (settings_remux_format_choice is "No remux" and subtitles_being_converted is false) then
			set theSTsKeepFormatLabel to localized string "Sorry, you need to choose a remux format or choose to download a particular subtitles format if you want to keep the original."
			display dialog theSTsKeepFormatLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
			set_settings(URL_user_entered_clean)
		end if
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Keep_Remux_Original" to settings_original_choice
			end tell
		end tell
		
		-- Can set embed thumbnail to true if user is using YT-DLP or user is using youtube-dl, Atomic is installed and audio format is mp3 or m4a
		if settings_thumb_embed_choice is true and ((DL_Use_YTDLP is "YT-DLP") or (DL_Use_YTDLP is "youtube-dl" and Atomic_is_installed is true and settings_audio_only_choice is true and (settings_audio_codec_choice is "mp3" or settings_audio_codec_choice is "m4a"))) then
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Thumbnail_Embed" to true
				end tell
			end tell
			-- If Atomic is not installed, cannot set embed thumbnails
		else if settings_thumb_embed_choice is true and Atomic_is_installed is false and DL_Use_YTDLP is "youtube-dl" then
			set theSTsEmbedFormatLabel to localized string "Sorry, to embed thumbnails, you need to install Atomic Parsley. You can do that in Utilities."
			display dialog theSTsEmbedFormatLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
			set_settings(URL_user_entered_clean)
		else if settings_thumb_embed_choice is true and DL_Use_YTDLP is "youtube-dl" and (settings_audio_only_choice is false or (settings_audio_codec_choice is not "mp3" and settings_audio_codec_choice is not "m4a")) then
			set theSTsEmbedFormatLabel to localized string "Sorry, to embed thumbnails, you need to specify audio only and use mp3 or m4a audio format."
			display dialog theSTsEmbedFormatLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
			set_settings(URL_user_entered_clean)
		end if
		-- User wants Embedding off - set settings and return to Main
		if settings_thumb_embed_choice is false then
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Thumbnail_Embed" to false
				end tell
			end tell
		end if
	end if
	
	main_dialog()
	
end set_settings


---------------------------------------------------
--
-- 		Check for youtube-dl/YT-DLP updates
--
---------------------------------------------------

-- Handler to check and update youtube-dl/YT-DLP if user wishes - called by Utilities dialog to update script and switch scripts, the auto check on startup and the Warning dialog
on check_ytdl(Use_YTDLP)
	-- Get version of YTDL/YT-DLP available from GitHub - which has a different name to what is used by MacYTDL
	if Use_YTDLP is "YT-DLP" then
		set YTDL_site_URL to "https://github.com/yt-dlp/yt-dlp/releases"
		set name_of_executable to "yt-dlp_macos"
	else
		set YTDL_site_URL to "https://github.com/ytdl-org/youtube-dl/releases"
		set name_of_executable to "youtube-dl"
	end if
	set YTDL_releases_page to do shell script "curl " & YTDL_site_URL & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
	set theYTDLUpToDateLabel to localized string Use_YTDLP & " is up to date. Your current version is "
	set switch_flag to false
	if alert_text_ytdl is "Switching" then set switch_flag to true
	set alert_text_ytdl to theYTDLUpToDateLabel & YTDL_version
	-- Trap case in which user is offline
	if YTDL_releases_page is "" then
		set theYTDLPageErrorLabel to localized string "There was a problem with looking for " & Use_YTDLP & ". Perhaps you are not connected to the internet or GitHub is currently not available."
		display dialog theYTDLPageErrorLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon note giving up after 600
		main_dialog()
	else
		set ytdl_version_start to (offset of "Latest" in YTDL_releases_page)
		set YTDL_version_check to text (ytdl_version_start - 11) thru (ytdl_version_start - 2) of YTDL_releases_page
		if YTDL_version_check is not equal to YTDL_version then
			-- If the macOS version of YT-DLP is missing and user is not switching return execution – if user switching download the 22/10/21 version
			if Use_YTDLP is "YT-DLP" and YTDL_releases_page does not contain "yt-dlp_macos" then
				if switch_flag is false then
					return
				else
					set YTDL_version_check to "2021.10.22"
				end if
			end if
			if switch_flag is true then
				set YTDL_update_text to "To switch to " & Use_YTDLP & " it will need to be installed. Would you like to download it now ?"
			else
				set YTDL_update_text to "A new version of " & Use_YTDLP & " is available. You have version " & YTDL_version & ". The current version is " & YTDL_version_check & return & return & "Would you like to download it now ?"
			end if
			tell me to activate
			set YTDL_install_answ to button returned of (display dialog YTDL_update_text buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with title diag_Title with icon note giving up after 600)
			if YTDL_install_answ is theButtonYesLabel then
				set installAlertActionLabel to quoted form of "_"
				set installAlertTitle to quoted form of (localized string "MacYTDL installation:")
				set installAlertMessage to quoted form of (localized string "started.  Please wait.")
				set installAlertSubtitle to quoted form of ((localized string "Download and install of ") & Use_YTDLP)
				do shell script alerterPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 5 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
				try
					do shell script "curl -L " & YTDL_site_URL & "/download/" & YTDL_version_check & "/" & name_of_executable & " -o /usr/local/bin/" & Use_YTDLP with administrator privileges
					do shell script "chmod a+x /usr/local/bin/" & Use_YTDLP with administrator privileges
					if Use_YTDLP is "YT-DLP" then
						set ytdlp_exists to true
					else
						set YTDL_exists to true
					end if
					-- trap case where user cancels credentials dialog
				on error number -128
					main_dialog()
				end try
				set YTDL_version to YTDL_version_check
				set theYTDLUpDatedLabel to localized string " has been updated. Your new version is "
				set alert_text_ytdl to Use_YTDLP & theYTDLUpDatedLabel & YTDL_version
			else
				set theYTDLOutOfDateLabel to localized string " is out of date. Your current version is "
				set alert_text_ytdl to Use_YTDLP & theYTDLOutOfDateLabel & YTDL_version
			end if
		end if
	end if
end check_ytdl


---------------------------------------------------
--
-- 			Is FFMpeg up-to-date ?
--
---------------------------------------------------

-- Handler for updating FFmpeg & FFprobe - called by "Check updates" in Utilities Dialog - assumes always have same version of both tools
on check_ffmpeg()
	-- Get version of FFmpeg currently installed
	set ffmpeg_version_long to do shell script ffmpeg_file & " -version"
	set ffmpeg_version_start to (offset of "version" in ffmpeg_version_long) + 8
	set ffmpeg_version_end to (offset of "-tessus" in ffmpeg_version_long) - 1
	set ffmpeg_version to text ffmpeg_version_start thru ffmpeg_version_end of ffmpeg_version_long
	set theFFmpegAlertUpToDateLabel to localized string "FFmpeg and FFprobe are up to date. Your current version is "
	set alert_text_ffmpeg to theFFmpegAlertUpToDateLabel & ffmpeg_version
	-- Get version of FFmpeg available from web site
	set ffmpeg_site to "https://evermeet.cx/pub/ffmpeg/"
	set ffprobe_site to "https://evermeet.cx/pub/ffprobe/"
	set FFmpeg_page to do shell script "curl " & ffmpeg_site & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
	-- Trap case in which user is offline
	if FFmpeg_page is "" then
		set theFFmpegDownloadProblemLabel to localized string "There was a problem with accessing FFmpeg. Perhaps you are not connected to the internet or the server is currently not available. Try again later."
		display dialog theFFmpegDownloadProblemLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon note giving up after 600
		main_dialog()
	else
		set ffmpeg_version_start to (offset of "version" in FFmpeg_page) + 8
		set ffmpeg_version_end to (offset of "-tessus" in FFmpeg_page) - 1
		set ffmpeg_version_check to text ffmpeg_version_start thru ffmpeg_version_end of FFmpeg_page
		if ffmpeg_version_check is not equal to ffmpeg_version then
			set theFFmpegOutDatedTextLabel1 to localized string "FFmpeg is out of date. You have version "
			set theFFmpegOutDatedTextLabel2 to localized string "The current version is "
			set theFFmpegOutDatedTextLabel3 to localized string "Would you like to update it now ? If yes, this will also update FFprobe. Note: You may need to provide administrator credentials."
			set ffmpeg_install_text to theFFmpegOutDatedTextLabel1 & ffmpeg_version & ". " & theFFmpegOutDatedTextLabel2 & ffmpeg_version_check & return & return & theFFmpegOutDatedTextLabel3
			tell me to activate
			set ffmpeg_install_answ to button returned of (display dialog ffmpeg_install_text buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with title diag_Title with icon note giving up after 600)
			if ffmpeg_install_answ is theButtonYesLabel then
				set installAlertActionLabel to quoted form of "_"
				set installAlertTitle to quoted form of (localized string "MacYTDL installation:")
				set installAlertMessage to quoted form of (localized string "started.  Please wait.")
				set installAlertSubtitle to quoted form of (localized string "Download and install of FFmpeg")
				do shell script alerterPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 5 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
				set ffmpeg_download_file to quoted form of (usr_bin_folder & "ffmpeg-" & ffmpeg_version_check & ".zip")
				do shell script "curl -L " & ffmpeg_site & "ffmpeg-" & ffmpeg_version_check & ".zip" & " -o " & ffmpeg_download_file with administrator privileges
				try
					do shell script "unzip -o " & ffmpeg_download_file & " -d " & usr_bin_folder with administrator privileges
					do shell script "chmod a+x /usr/local/bin/ffmpeg" with administrator privileges
					do shell script "rm " & ffmpeg_download_file with administrator privileges
					set ffprobe_version_new to ffmpeg_version_check
					set ffprobe_download_file to quoted form of (usr_bin_folder & "ffprobe-" & ffprobe_version_new & ".zip")
					set installAlertActionLabel to quoted form of "_"
					set installAlertTitle to quoted form of (localized string "MacYTDL installation:")
					set installAlertMessage to quoted form of (localized string "started.  Please wait.")
					set installAlertSubtitle to quoted form of (localized string "Download and install of FFprobe")
					do shell script alerterPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 5 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
					set ffprobe_download_file to quoted form of (usr_bin_folder & "ffprobe-" & ffprobe_version_new & ".zip")
					do shell script "curl -L " & ffprobe_site & "ffprobe-" & ffprobe_version_new & ".zip" & " -o " & ffprobe_download_file with administrator privileges
					set ffprobe_version to ffmpeg_version_check
					do shell script "unzip -o " & ffprobe_download_file & " -d " & usr_bin_folder with administrator privileges
					do shell script "chmod a+x /usr/local/bin/ffprobe" with administrator privileges
					do shell script "rm " & ffprobe_download_file with administrator privileges
				on error errStr number errorNumber
					if errorNumber is -128 then
						-- User cancels credentials dialog
						try
							do shell script "rm " & ffmpeg_download_file with administrator privileges
						end try
						main_dialog()
					else
						-- trap any other kind of error including "Operation not permitted"
						try
							do shell script "rm " & ffmpeg_download_file with administrator privileges
						end try
						set theFFmpegUpdateProblemTextLabel1 to localized string "There was a problem with installing FFmpeg. This was the error message: "
						set theFFmpegUpdateProblemTextLabel2 to localized string "You can run MacYTDL and change settings but downloads will not work until FFmpeg is installed. When you next start MacYTDL, it will try again to install FFmpeg."
						display dialog theFFmpegUpdateProblemTextLabel1 & errorNumber & " " & errStr & return & return & theFFmpegUpdateProblemTextLabel2 buttons {theButtonOKLabel} default button 1 with title diag_Title with icon note giving up after 600
					end if
				end try
				set ffmpeg_version to ffmpeg_version_check
				set theFFmpegProbeAlertUpDatedLabel to localized string "FFmpeg and FFprobe have been updated. Your new version is "
				set alert_text_ffmpeg to theFFmpegProbeAlertUpDatedLabel & ffmpeg_version
			else
				set theFFmpegProbeAlertOutOfDateLabel to localized string "FFmpeg is out of date. Your current version is "
				set alert_text_ffmpeg to "" & ffmpeg_version
			end if
		end if
	end if
end check_ffmpeg


---------------------------------------------------
--
-- 		Perform various utilities
--
---------------------------------------------------

-- Handler for MacYTDL utility operations called by the Utilities button on Main dialog
on utilities()
	
	run_Utilities_handlers's read_settings(MacYTDL_prefs_file)
	
	-- Test for Service and Atomic installs
	set isServiceInstalled to "Yes"
	tell application "System Events"
		set services_Folder to (POSIX path of (path to home folder) & "/Library/Services/")
		set macYTDL_service_file to services_Folder & "Send-URL-To-MacYTDL.workflow"
		if not (exists the file macYTDL_service_file) then
			set isServiceInstalled to "No"
		end if
	end tell
	tell application "System Events"
		set macYTDL_Atomic_file to ("usr:local:bin:AtomicParsley" as text)
		if (exists file macYTDL_Atomic_file) then
			set Atomic_is_installed to true
		else
			set Atomic_is_installed to false
		end if
	end tell
	
	-- Set youtube-dl/YT-DLP and FFmpeg version installed text - to show in Utilities dialog
	set theVersionInstalledLabel to localized string "Installed:"
	set theYTDLVersionInstalledlabel to theVersionInstalledLabel & " v" & YTDL_version
	set FFMpeg_version_installed to theVersionInstalledLabel & " v" & ffmpeg_version
	
	-- Set variables for the Utilities dialog
	set theInstructionsTextLabel to localized string "Choose the utility(ies) you would like to run then click 'Start'"
	set instructions_text to theInstructionsTextLabel
	set theDiagPromptLabel to localized string "Utilities"
	set utilities_diag_prompt to theDiagPromptLabel
	set accViewWidth to 600
	set accViewInset to 75
	
	-- Set buttons and controls
	set theButtonsDeleteLogsLabel to localized string "Delete logs"
	set theButtonsUninstallLabel to localized string "Uninstall"
	set theButtonsAboutLabel to localized string "About MacYTDL"
	set theButtonsStartLabel to localized string "Start"
	set {theButtons, minWidth} to create buttons {theButtonsDeleteLogsLabel, theButtonsUninstallLabel, theButtonsAboutLabel, theButtonCancelLabel, theButtonsStartLabel} button keys {"d", "U", "a", "c", ""} default button 5
	if minWidth > accViewWidth then set accViewWidth to minWidth
	set {theUtilitiesRule, theTop} to create rule 10 rule width accViewWidth
	-- Set up alternatives for Service and AtomicParsley
	if isServiceInstalled is "Yes" then
		set theCheckBoxRemoveServiceLabel to localized string "Remove Service"
		set {utilities_theCheckbox_Service_Install, theTop} to create checkbox theCheckBoxRemoveServiceLabel left inset accViewInset bottom (theTop + 5) max width 250
	else
		set theCheckBoxInstallServiceLabel to localized string "Install Service"
		set {utilities_theCheckbox_Service_Install, theTop} to create checkbox theCheckBoxInstallServiceLabel left inset accViewInset bottom (theTop + 5) max width 250
	end if
	if Atomic_is_installed is true then
		set theCheckBoxRemoveAtomicLabel to localized string "Remove Atomic Parsley"
		set {utilities_theCheckbox_Atomic_Install, theTop} to create checkbox theCheckBoxRemoveAtomicLabel left inset accViewInset bottom (theTop + 5) max width 250
	else
		set theCheckBoxInstallAtomicLabel to localized string "Install Atomic Parsley"
		set {utilities_theCheckbox_Atomic_Install, theTop} to create checkbox theCheckBoxInstallAtomicLabel left inset accViewInset bottom (theTop + 5) max width 250
	end if
	set theCheckBoxCheckFFmpegLabel to localized string "Check for FFmpeg update"
	set theCheckBoxCheckFFmpegversion to theCheckBoxCheckFFmpegLabel & "    " & "(" & FFMpeg_version_installed & ")"
	set {utilities_theCheckbox_FFmpeg_Check, theTop} to create checkbox theCheckBoxCheckFFmpegversion left inset accViewInset bottom (theTop + 5) max width 250
	set theCheckBoxCheckMacYTDLLabel to localized string "Check for MacYTDL update"
	set {utilities_theCheckbox_MacYTDL_Check, theTop} to create checkbox theCheckBoxCheckMacYTDLLabel left inset accViewInset bottom (theTop + 5) max width 200
	-- Setup YTDL switcher
	if DL_Use_YTDLP is "YT-DLP" then
		set theCheckBoxSwitchScriptsLabel to localized string "Switch to youtube-dl"
	else
		set theCheckBoxSwitchScriptsLabel to localized string "Switch to YT-DLP"
	end if
	set {utilities_theCheckbox_Switch_Scripts, theTop} to create checkbox theCheckBoxSwitchScriptsLabel left inset accViewInset bottom (theTop + 5) max width 250
	set theCheckBoxOpenYTDLLabel to (localized string "Open") & " " & DL_Use_YTDLP & " " & (localized string "web page")
	set {utilities_theCheckbox_YTDL_release, theTop} to create checkbox theCheckBoxOpenYTDLLabel left inset accViewInset bottom (theTop + 5) max width 200
	set theCheckBoxCheckYTDLLabel to (localized string "Check for") & " " & DL_Use_YTDLP & " " & (localized string "update")
	set theCheckBoxCheckYTDLversion to theCheckBoxCheckYTDLLabel & "    " & "(" & theYTDLVersionInstalledlabel & ")"
	set {utilities_theCheckbox_YTDL_Check, theTop} to create checkbox theCheckBoxCheckYTDLversion left inset accViewInset bottom (theTop + 5) max width 250
	set theCheckBoxOpenDLFolderLabel to localized string "Open download folder"
	set {utilities_theCheckbox_DL_Open, theTop} to create checkbox theCheckBoxOpenDLFolderLabel left inset accViewInset bottom (theTop + 5) max width 250
	set theCheckBoxOpenLogFolderLabel to localized string "Open log folder"
	set {utilities_theCheckbox_Logs_Open, theTop} to create checkbox theCheckBoxOpenLogFolderLabel left inset accViewInset bottom (theTop + 5) max width 250
	set {utilities_instruct, theTop} to create label instructions_text left inset accViewInset + 5 bottom (theTop + 10) max width minWidth - 100 aligns left with multiline
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 50 view width 64 view height 64 scale image scale proportionally
	set {utilities_prompt, theTop} to create label utilities_diag_prompt left inset 0 bottom (theTop) max width minWidth aligns center aligned with bold type
	set utilities_allControls to {theUtilitiesRule, utilities_theCheckbox_Service_Install, utilities_theCheckbox_Atomic_Install, utilities_theCheckbox_FFmpeg_Check, utilities_theCheckbox_MacYTDL_Check, utilities_theCheckbox_Switch_Scripts, utilities_theCheckbox_YTDL_release, utilities_theCheckbox_YTDL_Check, utilities_theCheckbox_DL_Open, utilities_theCheckbox_Logs_Open, MacYTDL_icon, utilities_instruct, utilities_prompt}
	
	-- Make sure MacYTDL is in front and show dialog
	tell me to activate
	set {utilities_button_returned, utilities_button_number_returned, utilities_controls_results} to display enhanced window diag_Title buttons theButtons acc view width minWidth acc view height theTop acc view controls utilities_allControls initial position window_Position
	
	if utilities_button_number_returned is 5 then -- Start
		-- Get control results from utilities dialog - numbered choice variables are not used but help ensure correct utilities are run
		-- set utilities_choice_1 to item 1 of utilities_controls_results -- <= Missing value [the rule]
		set utilities_Service_choice to item 2 of utilities_controls_results -- <= Install Service choice
		set utilities_Atomic_choice to item 3 of utilities_controls_results -- <= Install Atomic Parsley choice
		set utilities_FFmpeg_check_choice to item 4 of utilities_controls_results -- <= Check FFmpeg version choice
		set utilities_MacYTDL_check_choice to item 5 of utilities_controls_results -- <= Check MacYTDL version choice
		set utilities_Switch_choice to item 6 of utilities_controls_results -- <= Install Service choice
		set utilities_YTDL_webpage_choice to item 7 of utilities_controls_results -- <= Show YTDL/YT-DLP web page choice
		set utilities_YTDL_check_choice to item 8 of utilities_controls_results -- <= Check YTDL version choice
		set utilities_DL_folder_choice to item 9 of utilities_controls_results -- <= Open download folder choice
		set utilities_log_folder_choice to item 10 of utilities_controls_results -- <= Open log folder choice
		--set utilities_Atomic_status_choice_11 to item 11 of utilities_controls_results -- <= Atomic status indicator
		--set utilities_service_status_choice_12 to item 12 of utilities_controls_results -- <= Service status indicator
		--set utilities_choice_13 to item 13 of utilities_controls_results -- <= Missing value [the icon]
		--set utilities_choice_14 to item 14 of utilities_controls_results -- <= Contains the "Instructions" text
		
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
			check_download_folder(downloadsFolder_Path)
			-- Open the downloads folder in a Finder window positioned away from the MacYTDL main dialog which will re-appear - Assistive Access not needed as Finder windows have position properties
			tell application "Finder"
				activate
				open (downloadsFolder_Path as POSIX file) -- <= Had to read prefs again to get this working - something to do with this path in Main Dialog
				set the position of the front Finder window to {100, 100} -- <= This DOES work but is ugly - it opens the window then moves it to a location which should not overlap Main Dialog
			end tell
		end if
		
		-- Open youtube-dl/YT-DLP web page (in default web browser)
		if utilities_YTDL_webpage_choice is true then
			if DL_Use_YTDLP is "youtube-dl" then
				open location "https://github.com/ytdl-org/youtube-dl"
			else
				open location "https://github.com/yt-dlp/yt-dlp"
			end if
		end if
		
		-- Need to show the version checked dialog before returning to Main dialog
		-- Do selected combination of version checks - Provide for each possible combination of check boxes
		if utilities_YTDL_check_choice is true and utilities_FFmpeg_check_choice is true then
			set alert_text_ytdl to "NotSwitching"
			check_ytdl(DL_Use_YTDLP)
			if ffmpeg_version is "Not installed" then
				check_ffmpeg_installed()
				set theFFmpegProbeInstalledAlertLabel to localized string "FFmpeg and FFprobe have been installed."
				set alert_text_ffmpeg to theFFmpegProbeInstalledAlertLabel
			else
				check_ffmpeg()
			end if
			tell me to activate
			display dialog alert_text_ytdl & return & alert_text_ffmpeg with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
		else if utilities_FFmpeg_check_choice is true and utilities_YTDL_check_choice is false then
			if ffmpeg_version is "Not installed" then
				check_ffmpeg_installed()
				set theFFmpegProbeInstalledAlertLabel to localized string "FFmpeg and FFprobe have been installed."
				set alert_text_ffmpeg to theFFmpegProbeInstalledAlertLabel
			else
				check_ffmpeg()
			end if
			tell me to activate
			display dialog alert_text_ffmpeg & return & return with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
		else if utilities_YTDL_check_choice is true and utilities_FFmpeg_check_choice is false then
			set alert_text_ytdl to "NotSwitching"
			check_ytdl(DL_Use_YTDLP)
			tell me to activate
			display dialog alert_text_ytdl & return with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
		end if
		
		-- Check for MacYTDL update
		if utilities_MacYTDL_check_choice is true then
			run_Utilities_handlers's check_MacYTDL(downloadsFolder_Path, diag_Title, theButtonOKLabel, theButtonNoLabel, theButtonYesLabel, MacYTDL_version)
		end if
		
		-- Switch from youtube-dl to YT-DLP or vice versa - install script if not installed + change the "Use_ytdlp" setting + but prevent switching if OS<10.15 & library files not installed - Use show_yt_dlp as proxy for macOS version
		if utilities_Switch_choice is true then
			if show_yt_dlp is "youtube-dl" then
				set SSL_library_file to "/usr/local/lib/libssl.46.dylib"
				set crypto_library_file to "/usr/local/lib/libcrypto.44.dylib"
				set user_missing_libraries to false
				tell application "System Events"
					if (not (exists file SSL_library_file)) or (not (exists file crypto_library_file)) then
						set user_missing_libraries to true
					end if
				end tell
				if user_missing_libraries is true then
					set theLibrariesNotInstalledTextLabel to localized string "Because your Mac is running an old version of macOS, to use YT-DLP, you need to install two system library files or install Python3 and other dependencies. There is more detail in the Help file."
					display dialog theLibrariesNotInstalledTextLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
					main_dialog()
				end if
			end if
			set alert_text_ytdl to "Switching"
			if DL_Use_YTDLP is "YT-DLP" then
				set user_wants_switch to "youtube-dl"
			else
				set user_wants_switch to "YT-DLP"
			end if
			if (user_wants_switch is "YT-DLP" and ytdlp_exists is false) or (user_wants_switch is "youtube-dl" and YTDL_exists is false) then
				check_ytdl(user_wants_switch)
			end if
			-- Update Use_ytdlp setting if user installs new version or already has user_wants_switch installed
			if alert_text_ytdl does not contain "is out of date" then
				tell application "System Events"
					tell property list file MacYTDL_prefs_file
						set value of property list item "Use_ytdlp" to user_wants_switch
					end tell
				end tell
			end if
		end if
		
		-- Install/Remove Atomic Parsely
		if utilities_Atomic_choice is true then
			if Atomic_is_installed is false then
				if DL_Use_YTDLP is "YT-DLP" then
					set theDontNeedAPTextLabel to localized string "You are currently using YT-DLP and so there is no need for Atomic Parsley. Do you still wish to install Atomic Parsley ?"
					set reallyWantsAP to button returned of (display dialog theDontNeedAPTextLabel with title diag_Title buttons {theButtonNoLabel, theButtonYesLabel} default button 1 with icon note giving up after 600)
					if reallyWantsAP is theButtonNoLabel then main_dialog()
				end if
				run_Utilities_handlers's install_MacYTDLatomic(diag_Title, theButtonOKLabel, path_to_MacYTDL, usr_bin_folder)
				set Atomic_is_installed to true
				tell me to activate
			else if Atomic_is_installed is true then
				run_Utilities_handlers's remove_MacYTDLatomic(path_to_MacYTDL, theButtonOKLabel, diag_Title)
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
				set theServiceInstalledLabel to localized string "The MacYTDL Service is installed."
				display dialog theServiceInstalledLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 100
			else if isServiceInstalled is "Yes" then
				-- Service is installed - user wants to remove it
				run_Utilities_handlers's remove_MacYTDLservice()
				tell me to activate
				set theServiceRemovedLabel to localized string "The MacYTDL Service has been removed."
				display dialog theServiceRemovedLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 100
			end if
		end if
		
		-- Move all log files to Trash - split moves because mv fails "too many args" if there are too many files - try loop in case one of mv commands fails to find any files
	else if utilities_button_number_returned is 1 then -- Delete logs
		try
			do shell script "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_response-[ABCDEabcde]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_response-[FGHIJKLMNfghijklmn]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_response-[OPQRSTUVWXYZopqrstuvwxyz]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_response-[1234567890#~!@$%^]*" & " ~/.trash/" & " ; " & "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_response-*" & " ~/.trash/"
		end try
		set theUtilitiesDeleteLogsLabel to localized string "All MacYTDL log files are now in the Trash."
		display dialog theUtilitiesDeleteLogsLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 100
		
		-- Uninstall all MacYTDL files - move files to Trash
	else if utilities_button_number_returned is 2 then
		set theUtilitiesUninstallLabel to localized string "Do you really want to remove MacYTDL ? Everything will be moved to the Trash."
		set really_remove_MacYTDL to display dialog theUtilitiesUninstallLabel buttons {theButtonYesLabel, theButtonNoLabel} with title diag_Title default button 2 with icon note giving up after 600
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
			do shell script "mv " & POSIX path of ffprobe_file & " ~/.trash/ffprobe" with administrator privileges
			do shell script "mv " & POSIX path of ffmpeg_file & " ~/.trash/ffmpeg" with administrator privileges
			set path_to_macytdl_file to quoted form of (POSIX path of path_to_MacYTDL)
			do shell script "mv " & path_to_macytdl_file & " ~/.trash/MacYTDL.app" with administrator privileges
			-- trap case where user cancels credentials dialog
		on error number -128
			main_dialog()
		end try
		do shell script "mv " & POSIX path of MacYTDL_preferences_path & " ~/.trash/MacYTDL"
		do shell script "mv " & quoted form of (POSIX path of DTP_file) & " ~/.trash/DialogToolkitMacYTDL.scptd" -- Quoted form because of space in "Script Libraries" folder name
		-- If it exists, move the MacYTDL Service to Trash - Ditto the Defaults plist file
		set macYTDL_service_file to services_Folder & "Send-URL-To-MacYTDL.workflow"
		set User_defaults_path to "Library/Preferences/com.apple.script.id.MacYTDL.plist"
		set macYTDL_defaults_preferences_file to (POSIX path of (path to home folder) & User_defaults_path)
		tell application "System Events"
			if (the file macYTDL_service_file exists) then
				tell current application to do shell script "mv " & quoted form of (macYTDL_service_file) & " ~/.trash/Send-URL-To-MacYTDL.workflow"
			end if
			if (the file macYTDL_defaults_preferences_file exists) then
				tell current application to do shell script "mv " & quoted form of (macYTDL_defaults_preferences_file) & " ~/.trash/com.apple.script.id.MacYTDL.plist"
			end if
		end tell
		set theUtilitiesMYTDLUninstalledLabel to localized string "MacYTDL is uninstalled. All components are in the Trash which you can empty when you wish. Cheers."
		set theUtilitiesMYTDLUninstalledByeLabel to localized string "Goodbye"
		display dialog theUtilitiesMYTDLUninstalledLabel buttons {theUtilitiesMYTDLUninstalledByeLabel} default button 1 with icon note giving up after 600
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
	set theButtonsAbout1Label to (localized string "MacYTDL is a simple AppleScript program for downloading videos from various web sites. It uses the") & " " & DL_Use_YTDLP & " " & (localized string "Python script as the download engine.")
	set about_text_1 to theButtonsAbout1Label
	set theButtonsAbout2Label to localized string "Please post any questions or suggestions to github.com/section83/MacYTDL/issues"
	set theButtonsAbout3Label to localized string "Written by © Vincentius, "
	set theButtonsAbout4Label to localized string "With thanks to Shane Stanley, Adam Albrec, kopurando, Michael Page, Tombs and all MacYTDL users."
	set about_text_2 to theButtonsAbout2Label & return & return & theButtonsAbout3Label & MacYTDL_date & ". " & theButtonsAbout4Label
	set theButtonsAboutDiagLabel to localized string "About MacYTDL"
	set about_diag_prompt to theButtonsAboutDiagLabel
	set accViewWidth to 300
	set accViewInset to 0
	
	-- Set buttons and controls
	set theButtonsVisitLabel to localized string "Visit Site"
	set theButtonsEmailLabel to localized string "Send E-Mail"
	set {theButtons, minWidth} to create buttons {theButtonsVisitLabel, theButtonsEmailLabel, theButtonOKLabel} button keys {"v", "e", ""} default button 3
	set {about_Rule, theTop} to create rule 10 rule width accViewWidth
	set {about_instruct_2, theTop} to create label about_text_2 left inset 5 bottom (theTop + 10) max width accViewWidth aligns left with multiline
	set {about_instruct_1, theTop} to create label about_text_1 left inset 75 bottom (theTop + 10) max width accViewWidth - 75 aligns left with multiline
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
	set theCredentialsInstructionsLabel to localized string "Enter your user name and password in the boxes below for the next download, skip credentials and continue to download or return to the Main dialog."
	set theCredentialsDiagPromptLabel to localized string "Credentials for next download"
	set instructions_text to theCredentialsInstructionsLabel
	set credentials_diag_prompt to theCredentialsDiagPromptLabel
	set accViewWidth to 275
	set accViewInset to 0
	
	-- Set buttons and controls
	set theButtonsCredSkipLabel to localized string "Skip"
	set {theButtons, minWidth} to create buttons {theButtonReturnLabel, theButtonsCredSkipLabel, theButtonOKLabel} button keys {"r", "s", ""} default button 3
	set theButtonsCredPasswordLabel to localized string "Password"
	set {theField_password, theTop} to create field "" placeholder text theButtonsCredPasswordLabel left inset accViewInset bottom 5 field width accViewWidth
	set theButtonsCredNameLabel to localized string "User name"
	set {theField_username, theTop} to create field "" placeholder text theButtonsCredNameLabel left inset accViewInset bottom (theTop + 20) field width accViewWidth
	set {utilities_instruct, theTop} to create label instructions_text left inset 75 bottom (theTop + 15) max width (accViewWidth - 75) aligns left with multiline
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
-- Handler to write the user's selected URL to the batch file for later download
-- Creates file if need, adds URL and a return each time
on add_To_Batch(URL_user_entered, download_filename)
	-- Remove any quotes from around URL_user_entered - so it can be written out to the batch file
	if character 1 of URL_user_entered is "'" then
		set URL_user_entered_lines to text 2 thru -2 of URL_user_entered
	else
		set URL_user_entered_lines to URL_user_entered
	end if
	-- Change spaces to returns when URL_user_entered has more than one URL - then add file name as comment - used by Adviser to play 1st file
	set URL_user_entered_lines to text 1 thru end of (run_Utilities_handlers's replace_chars(URL_user_entered_lines, " ", return))
	set count_of_URLs to count of paragraphs in URL_user_entered_lines
	if count_of_URLs is greater than 1 then
		set URL_user_entered_forming to ""
		repeat with i from 1 to count_of_URLs
			set URL_user_entered_forming to URL_user_entered_forming & paragraph i of URL_user_entered_lines & "#" & paragraph i of download_filename & return
		end repeat
	else
		set download_filename to text 1 thru -2 of download_filename
		set URL_user_entered_forming to URL_user_entered_lines & "#" & download_filename & return
	end if
	set batch_filename to "BatchFile.txt" as string
	set batch_file to POSIX file (MacYTDL_preferences_path & batch_filename) as «class furl»
	try
		set batch_refNum to missing value
		set batch_refNum to open for access batch_file with write permission
		write URL_user_entered_forming to batch_refNum starting at eof
		close access batch_refNum
	on error batch_errMsg
		set theBatchErrorLabel to localized string "There was an error: "
		display dialog theBatchErrorLabel & batch_errMsg
		close access batch_refNum
		main_dialog()
	end try
	set theAddedToBatchLabel to localized string "The URL has been added to batch file."
	display dialog theAddedToBatchLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon note giving up after 600
	-- After adding to batch, reset URLs so text box is blank and old URL not used again, ABC & SBS show name and myNum so that correct file name is used for next download
	set URL_user_entered to ""
	set ABC_show_name to ""
	set SBS_show_name to ""
	set SBS_show_URLs to ""
	set ABC_show_URLs to ""
	set URL_user_entered_clean to ""
	set myNum to 0
	set the clipboard to ""
	
	main_dialog()
end add_To_Batch


---------------------------------------------------------
--
-- 	Open batch processing dialog - called by Main
--
---------------------------------------------------------
-- Handler to open batch file processing dialog - called by Main dialog
on open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
	
	run_Utilities_handlers's read_settings(MacYTDL_prefs_file)
	
	-- Start by calculating tally of URLs currently saved in the batch file	
	set batch_tally_number to tally_batch()
	
	-- Set variables for the Batch functions dialog
	set theBatchFunctionsInstructionLabel to localized string "Choose to download list of URLs in batch file, clear the batch list, edit the batch list, remove last addition to the batch or return to Main dialog."
	set theBatchFunctionsDiagPromptLabel to localized string "MacYTDL Batch Functions"
	set instructions_text to theBatchFunctionsInstructionLabel
	set batch_diag_prompt to theBatchFunctionsDiagPromptLabel
	set accViewWidth to 500
	set accViewInset to 0
	
	-- Set buttons and controls
	set theButtonsEditLabel to localized string "Edit"
	set theButtonsClearLabel to localized string "Clear"
	set theButtonsRemoveLabel to localized string "Remove last item"
	set {theButtons, minWidth} to create buttons {theButtonReturnLabel, theButtonsEditLabel, theButtonsClearLabel, theButtonsRemoveLabel, theButtonDownloadLabel} button keys {"r", "e", "c", "U", "d"} default button 5
	if minWidth > accViewWidth then set accViewWidth to minWidth
	set {theBatchRule, theTop} to create rule 10 rule width accViewWidth
	set theNumberVideosLabel to localized string "Number of videos in batch: "
	set {batch_tally, theTop} to create label theNumberVideosLabel & batch_tally_number left inset 25 bottom (theTop + 15) max width 225 aligns left
	set {batch_instruct, theTop} to create label instructions_text left inset 75 bottom (theTop + 30) max width minWidth - 75 aligns left with multiline
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 60 view width 64 view height 64 scale image scale proportionally
	set {batch_prompt, theTop} to create label batch_diag_prompt left inset 0 bottom (theTop) max width minWidth aligns center aligned with bold type
	set batch_allControls to {theBatchRule, batch_tally, MacYTDL_icon, batch_instruct, batch_prompt}
	
	-- Make sure MacYTDL is in front and show dialog
	tell me to activate
	set {batch_button_returned, batchButtonNumberReturned, batch_controls_results} to display enhanced window diag_Title buttons theButtons acc view width minWidth acc view height theTop acc view controls batch_allControls initial position window_Position
	
	if batchButtonNumberReturned is 5 then
		-- Eventually, will have code here which will read the batch file and present user with list to choose from - but, would be best if had show name not just URL
		download_batch(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
	else if batchButtonNumberReturned is 2 then
		-- Check that there is a batch file
		tell application "System Events"
			set batch_file_test to batch_file as string
			if not (exists file batch_file_test) then
				set theNoBatchFileLabel to localized string "Sorry, there is no batch file."
				display dialog theNoBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon MacYTDL_custom_icon_file giving up after 600
				my main_dialog()
			end if
		end tell
		tell application "Finder"
			activate
			open batch_file
		end tell
		open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
	else if batchButtonNumberReturned is 3 then
		clear_batch(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
	else if batchButtonNumberReturned is 4 then
		remove_last_from_batch(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
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
		set batch_URLs to read batch_file_ref from 1
		set number_of_URLs to (count of paragraphs in batch_URLs) - 1
		close access batch_file_ref
	on error batch_errMsg
		set theBatchErrorLabel to localized string "There was an error: "
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
-- Handler to download selection of URLs in Batch file - forms and calls youtube-dl/YT-DLP separately from the download_video handler
on download_batch(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
	
	-- Check that there is a batch file containing some URLs
	tell application "System Events"
		set batch_file_test to batch_file as string
		if not (exists file batch_file_test) then
			set theNoBatchFileLabel to localized string "Sorry, there is no batch file."
			display dialog theNoBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon MacYTDL_custom_icon_file giving up after 600
			my open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
		end if
	end tell
	if (get eof file batch_file) is 0 then
		set theEmptyBatchFileLabel to localized string "Sorry, the batch file is empty."
		display dialog theEmptyBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon MacYTDL_custom_icon_file giving up after 600
		open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
	end if
	
	-- Get date and time so it can be added to response file name
	set download_date_time to get_Date_Time()
	
	-- Always set is_Livestream_Flag to false for batch downloads
	set is_Livestream_Flag to "False"
	
	-- Set name to be used for response file and monitor dialog - name is in comment section of each URL line - get first file name to pass to Adviser
	set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-Batch_download_on-" & download_date_time & ".txt"
	set batch_file_ref to missing value
	set batch_file_ref to open for access file batch_file
	set download_filename to item 2 of (read batch_file_ref from 1 before linefeed using delimiter "#")
	close access batch_file_ref
	
	-- set download_filename to "No File Name"
	set download_filename_new to "the saved batch"
	
	-- Put diag title, file and path names into quotes as they are not passed correctly when they contain apostrophes or spaces
	set diag_Title_quoted to quoted form of diag_Title
	set download_filename to quoted form of download_filename
	set download_filename_new to quoted form of download_filename_new
	set YTDL_response_file to quoted form of YTDL_response_file
	set YTDL_batch_file to quoted form of POSIX path of batch_file
	
	-- Set remaining variables needed by Monitor.scpt
	set YTDL_simulate_response to "Null"
	set URL_user_entered to "Null"
	if YTDL_Custom_Template is not "" then
		set YTDL_output_template to " -o '" & YTDL_Custom_Template & "'"
	else
		set YTDL_output_template to " -o '%(title)s.%(ext)s'"
	end if
	
	-- Increment the monitor dialog position number - used by monitor.scpt for positioning monitor dialogs	
	set monitor_dialog_position to (monitor_dialog_position + 1)
	
	-- Form up parameters to send to monitor.scpt - collect YTDL settings then merge with MacYTDL variables		
	set ytdl_settings to quoted form of (" --ignore-errors --newline " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_audio_codec & YTDL_over_writes & YTDL_Thumbnail_Write & YTDL_Thumbnail_Embed & YTDL_metadata & YTDL_limit_rate_value & YTDL_verbose & YTDL_Use_Proxy & YTDL_Use_Cookies & YTDL_no_part & YTDL_output_template & " --batch-file " & YTDL_batch_file)
	
	set my_params to quoted form of downloadsFolder_Path & " " & MacYTDL_preferences_path & " " & ytdl_settings & " " & URL_user_entered & " " & YTDL_response_file & " " & download_filename & " " & download_filename_new & " " & MacYTDL_custom_icon_file_posix & " " & monitor_dialog_position & " " & YTDL_simulate_response & " " & diag_Title_quoted & " " & is_Livestream_Flag & " " & screen_width & " " & screen_height & DL_Use_YTDLP
	
	-- Prepare to call on the download Monitor - first get Monitor script location -- Monitor-bundle.scptd
	set myMonitorScriptAsString to quoted form of ((POSIX path of path_to_MacYTDL) & "Contents/Resources/Scripts/Monitor.scpt")
	
	-- PRODUCTION CALL - Call the download Monitor script which will run as a separate process and return so Main Dialog can be re-displayed - thus user can start any number of downloads
	do shell script "osascript -s s " & myMonitorScriptAsString & " " & my_params & " " & " > /dev/null 2> /dev/null &"
	
	-- TESTING CALL - Call the download Monitor script for testing - this formulation gets any errors back from Monitor, but holds execution until Monitor dialog is dismissed
	-- do shell script "osascript -s s " & myMonitorScriptAsString & " " & my_params
	
	main_dialog()
	
end download_batch


-------------------------------------------------------------
--
-- 	Clear batch file - called by open_batch_processing
--
-------------------------------------------------------------
-- Handler to clear all URLs from batch file - empties the file but does not delete it
on clear_batch(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
	-- Check that there is a batch file
	tell application "System Events"
		set batch_file_test to batch_file as string
		if not (exists file batch_file_test) then
			set theNoBatchFileLabel to localized string "Sorry, there is no batch file."
			display dialog theNoBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon MacYTDL_custom_icon_file giving up after 600
			return
		end if
	end tell
	if (get eof file batch_file) is 0 then
		set theEmptyBatchFileLabel to localized string "Sorry, the batch file is empty."
		display dialog theEmptyBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon MacYTDL_custom_icon_file giving up after 600
		open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
	end if
	try
		set batch_file_ref to missing value
		set batch_file_ref to open for access file batch_file with write permission
		set eof batch_file_ref to 0
		close access batch_file_ref
	on error batch_errMsg
		set theBatchErrorLabel to localized string "There was an error: "
		display dialog theBatchErrorLabel & batch_errMsg & "batch_file: " & batch_file buttons {theButtonOKLabel} default button 1
		try
			close access batch_file_ref
		on error
			main_dialog()
		end try
		main_dialog()
	end try
	open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
end clear_batch


--------------------------------------------------------------------------
--
-- 	Remove last batch addition - called by open_batch_processing
--
--------------------------------------------------------------------------
-- Handler to remove the most recent addition to batch file
on remove_last_from_batch(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
	-- Check that there is a batch file
	tell application "System Events"
		set batch_file_test to batch_file as string
		if not (exists file batch_file_test) then
			set theNoBatchFileLabel to localized string "Sorry, there is no batch file."
			display dialog theNoBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon MacYTDL_custom_icon_file giving up after 600
			return
		end if
	end tell
	if (get eof file batch_file) is 0 then
		set theEmptyBatchFileLabel to localized string "Sorry, the batch file is empty."
		display dialog theEmptyBatchFileLabel with title diag_Title buttons {theButtonOKLabel} default button 1 with icon MacYTDL_custom_icon_file giving up after 600
		open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
	end if
	try
		set batch_file_ref to missing value
		set batch_file_ref to open for access file batch_file with write permission
		set batch_URLs to read batch_file_ref from 1
		set batch_URLs to text 1 thru -4 of batch_URLs --<= remove last few characters to remove last return
		set last_URL_offset to last item of allOffset(batch_URLs, return) --<= Get last in list of offsets of returns
		set new_batch_contents to text 1 thru (last_URL_offset - 1) of batch_URLs --<= Trim off last URL
		set eof batch_file_ref to 0 --<= Empty the batch file
		write new_batch_contents & return to batch_file_ref --<= Write out all URLs except the last
		close access batch_file_ref
	on error batch_errMsg
		set theBatchErrorLabel to localized string "There was an error: "
		display dialog theBatchErrorLabel & batch_errMsg & "batch_file: " & batch_file buttons {theButtonOKLabel} default button 1
		close access batch_file_ref
		main_dialog()
	end try
	open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_audio_codec, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_limit_rate_value, YTDL_verbose, YTDL_Use_Proxy, YTDL_Use_Cookies, YTDL_Custom_Template, YTDL_no_part)
end remove_last_from_batch


----------------------------------------------------------------------------------------------------------------------------
--
-- 	Get screen height and width - using AppKit - called in preliminaries - also used in Monitor.scpt
--
-- Using NSScreen's mainScreen frame as does the Dialog Toolkit
----------------------------------------------------------------------------------------------------------------------------
on get_screensize()
	script theScript
		property parent : a reference to current application
		use framework "AppKit"
		on get_screensize()
			try
				set mainScreenFrame to current application's NSScreen's mainScreen()'s frame() as list
				set screen_width to item 1 of item 2 of mainScreenFrame as integer
				set screen_height to item 2 of item 2 of mainScreenFrame as integer
				set X_position to (screen_width / 10)
			on error errtext
				display dialog "There was an error: " & errtext
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
on quit_MacYTDL()
	set called_video_URL to "" -- This doesn't seem to need a Continue statement to properly quit - perhaps because this is NOT a "Stay Open" app
	set default_contents_text to ""
	set YTDL_version to ""
	set monitor_dialog_position to ""
	set old_version_prefs to "No"
	set DL_batch_status to false
	error number -128
end quit_MacYTDL