-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  MacYTDL
--  A GUI for the Python Script youtube-dl (http://rg3.github.io/youtube-dl/).  Many thanks to Shane Stanley, Adam Albrec, kopurando and Michael Page
--  Trying to bring in useful functions in a pithy GUI with few AppleScript extensions and without AppleScriptObjC
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Include libraries - needed for Shane Staney's Dialog Toolkit
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use script "DialogToolkitMacYTDL" version "1.0" -- Yosemite (10.10) or later
property parent : AppleScript

-- Set variables and default values

-- Variables which will always go into the main, settings and/or utilities dialogs
global diag_prompt
global diag_Title
global YTDL_version
global usr_bin_folder
global ffprobe_version
global ffmpeg_version
global python_version
global alert_text_ytdl
global alert_text_ffmpeg
global shellPath
global downloadsFolder_Path
global Atomic_is_installed
global macYTDL_Atomic_file
global download_filename_new
global YTDL_response_file
global YTDL_simulate_file
global youtubedl_file
global URL_user_entered
global ABC_show_URLs
global show_name
global myNum
global YTDL_output_template
global old_version_prefs
global batch_file
global MacYTDL_prefs_file
global MacYTDL_custom_icon_file
global MacYTDL_custom_icon_file_posix
global macYTDL_service_file
global MacYTDL_preferences_path
global DL_audio_only
global YTDL_credentials
global DL_YTDL_auto_check
global DL_over_writes
global DL_subtitles
global DL_subtitles_format
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
global DL_Show_Settings
global MacYTDL_version
global MacYTDL_copyright
global MacYTDL_date
global newText
global ffprobe_file
global ffmpeg_file
global DTP_file
global called_video_URL
global monitor_dialog_position
global screen_height
global window_Position
global X_position
global Y_position


-------------------------------------------------
--
-- 			Set up  variables
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
set bundle_file to (path to me as text) & "contents:Info.plist"
tell application "System Events"
	set MacYTDL_copyright to value of property list item "NSHumanReadableCopyright" of contents of property list file bundle_file
end tell
set MacYTDL_date_position to (offset of "," in MacYTDL_copyright) + 2
set MacYTDL_date to text MacYTDL_date_position thru end of MacYTDL_copyright
set MacYTDL_version to get version of me

-- Add shellpath variable because otherwise script can't find youtube-dl
set shellPath to "PATH=$PATH:/bin:/sbin:/usr/bin:/usr/local/bin:/usr/sbin:~/opt/bin:~/opt/sbin:/opt/local/bin:/opt/local/sbin:" & quoted form of (POSIX path of ((path to me as text) & "::")) & "; "

-- Set to -1 the counter used to prevent monitor dialogs overlapping - on first use it is increased to zero - thus monitor dialog starts at top of screen
set monitor_dialog_position to -1

-- Set path and name for custom icon for dialogs
set MacYTDL_custom_icon_file to (path to resource "applet.icns")
-- Set path and name for custom icon for enhanced window statements
set MacYTDL_custom_icon_file_posix to POSIX path of MacYTDL_custom_icon_file

-- Set variable for title of dialogs
set diag_Title to "MacYTDL, version " & MacYTDL_version & ", " & MacYTDL_date

-- Variables for youtube-dl and MacYTDL component installation status - changed if components are installed
set YTDL_version to "Not installed"
set ffprobe_version to "Not installed"
set ffmpeg_version to "Not installed"
set make_library to "No"

-- Variables for storing youtube-dl, FFmpeg, FFprobe and DialogToolkitPlus locations
set usr_bin_folder to ("/usr/local/bin/" as text)
set youtubedl_file to ("/usr/local/bin/youtube-dl" as text)
set home_folder to (path to home folder) as text
set libraries_folder to home_folder & "Library:Script Libraries"
set DTP_file to libraries_folder & ":DialogToolkitMacYTDL.scptd"


-------------------------------------------------
--
-- 	Make sure components are in place
--
-------------------------------------------------

-- Get youtube-dl version if it exists - this will set YTDL_version if ytdl exists and so will not re-install when is called check_ytdl_installed
tell application "System Events"
	if exists file youtubedl_file then
		tell current application
			set YTDL_version to do shell script youtubedl_file & " --version"
		end tell
	end if
end tell

-- Call handler to check whether youtube-dl is installed
check_ytdl_installed()

-- Get size of screen so Main dialog can be positioned somewhat to the left of centre and Monitor dialog positioned better
tell application "Finder"
	set screen_bounds to bounds of window of desktop
	set screen_width to item 3 of screen_bounds as string
	set screen_height to item 4 of screen_bounds as string
end tell
set X_position to (screen_width / 10)
set Y_position to 50

-- Set path for MacYTDL support files - includes Preferences, youtube-dl responses, batch file and browser service - create folder, prefs file and set default prefs + check for and delete old version, if user wishes
set MacYTDL_preferences_folder to "Library/Preferences/MacYTDL/"
set MacYTDL_preferences_path to (POSIX path of (path to home folder) & MacYTDL_preferences_folder)
set MacYTDL_prefs_file to MacYTDL_preferences_path & "MacYTDL.plist"
set old_version_prefs to "No"
set batch_filepathname to "BatchFile.txt" as string
set batch_file to POSIX file (MacYTDL_preferences_path & batch_filepathname)
tell application "System Events"
	-- Check whether preferences exist - if not, probably because MacYTDL not run before or prefs have been deleted - call set_preferences to create and populate - also install the Service and Atomic Parsley
	if not (the file MacYTDL_prefs_file exists) then
		-- Preferences file does not exist - call set_preferences to create
		my set_preferences()
		my ask_user_install_service()
		my ask_user_install_Atomic()
	else
		-- Prefs exist so, check whether user has the old version - if so, call set_preferences to fix - continue on if current version
		try
			tell property list file MacYTDL_prefs_file
				set test_DL_subtitles to value of property list item "SubTitles"
			end tell
			-- Old version had string prefs while new version has boolean prefs for 4 items - call set_preferences to delete and recreate if user wishes
			if test_DL_subtitles is "Yes" or test_DL_subtitles is "No" then
				set old_version_prefs to "Yes"
				my set_preferences()
			end if
		on error
			-- Means the plist file exists but there is a problem (eg. it's empty because of an earlier crash) - just delete it, re-create and populate as if replacing the old version
			set old_version_prefs to "Yes"
			my set_preferences()
		end try
		-- Check on need to add new v1.2 items to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "SubTitles_Embedded") then
				my add_v1_2_preferences()
			end if
		end tell
		-- Check on need to add new v1.4 items to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "Remux_Format") then
				my add_v1_4_preferences()
			end if
		end tell
		-- Check on need to add new v1.5 items to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "Subtitles_Format") then
				my add_v1_5_preferences()
			end if
		end tell
		-- Check on need to add new v1.10 item to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "Show_Settings_before_Download") then
				my add_v1_10_preference()
			end if
		end tell
		-- Check on need to add new v1.11 item to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "final_Position") then
				my add_v1_11_preference()
			end if
		end tell
		-- Check on need to add new v1.12.1 item to the prefs file
		tell property list file MacYTDL_prefs_file
			if not (exists property list item "Subtitles_Language") then
				my add_v1_12_1_preference()
			end if
		end tell
	end if
end tell

-- Read the preferences file to get current settings
read_settings()

-- Check version of Service if installed - update if old
update_MacYTDLservice()

-- ffmpeg & ffprobe - are they installed and if so, which version
-- Get FFmpeg and FFprobe version if they exist
set ffprobe_file to ("/usr/local/bin/ffprobe" as text)
set ffmpeg_file to ("/usr/local/bin/ffmpeg" as text)
tell application "System Events"
	if exists file ffmpeg_file then
		set ffmpeg_version_long to do shell script ffmpeg_file & " -version"
		set ffmpeg_version_start to (offset of "version" in ffmpeg_version_long) + 8
		set ffmpeg_version_end to (offset of "-tessus" in ffmpeg_version_long) - 1
		set ffmpeg_version to text ffmpeg_version_start thru ffmpeg_version_end of ffmpeg_version_long
	end if
	if exists file ffprobe_file then
		set ffprobe_version_long to do shell script ffprobe_file & " -version"
		set ffprobe_version_start to (offset of "version" in ffprobe_version_long) + 8
		set ffprobe_version_end to (offset of "-tessus" in ffprobe_version_long) - 1
		set ffprobe_version to text ffprobe_version_start thru ffprobe_version_end of ffprobe_version_long
	end if
end tell

-- Call handler to install FFmpeg and FFprobe if not installed yet
if ffprobe_version is "Not installed" or ffmpeg_version is "Not installed" then
	check_ffmpeg_installed()
end if

-- Check whether DTP exists; if not, call DTP installer - also works if DTP name is changed
tell application "System Events"
	if not (the file DTP_file exists) then
		my install_DTP()
	end if
end tell

-- Is Atomic Parsley installed ? [Needed for embedding thmubnails in mp4 and m4a files] - result is displayed in Utilities dialog
set macYTDL_Atomic_file to ("usr:local:bin:AtomicParsley" as text)
tell application "System Events"
	if (exists file macYTDL_Atomic_file) then
		set Atomic_is_installed to true
	else
		set Atomic_is_installed to false
	end if
end tell

-- Get Python version - is always installed and so don't need to test whether it is there - result shown in optional Settings dialog before download
set python_version to do shell script "python -c 'import platform; print(platform.python_version())'"

-- Set path and name for youtube-dl simulated response file - a simulated youtube-dl download puts all its feedback into this file - it's a generic file used for all downloads and so only contains detail on the most recent download - simulation helps find errors and problems before starting the download
set YTDL_simulate_file to MacYTDL_preferences_path & "youtube-dl_simulate.txt"

-- If auto checking of youtube-dl version is on, do the check
if DL_YTDL_auto_check is true then
	check_ytdl()
	if alert_text_ytdl contains "youtube-dl has been updated" then
		display dialog alert_text_ytdl with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 600
	end if
end if

-- Set ABC show name and episode count variables so they exist
set show_name to ""
set myNum to 0


main_dialog()


on main_dialog()
	
	--*****************  This is for testing variables as they come into and back to Main - beware some of these are not defined on all circumstances
	
	-- display dialog "video_URL: " & return & return & "called_video_URL: " & called_video_URL & return & return & "URL_user_entered: " & URL_user_entered & return & return & "URL_user_entered_clean: " & URL_user_entered_clean & return & return & "default_contents_text: "
	
	--*****************		
	
	-- Read the preferences file to get current settings - including settings changed by set_settings()
	read_settings()
	
	
	-- Set batch file status so that it persists while MacYTDL is running
	try
		if DL_batch_status is true then
			set DL_batch_status to true
		end if
	on error
		-- Initialise DL_batch_status
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
	
	set diag_settings_text to "One-time settings:                                     Batches:"
	set accViewWidth to 450
	set accViewInset to 80
	
	-- Set buttons and controls
	set {theButtons, minWidth} to create buttons {"Help", "Utilities", "Quit", "Settings", "Continue"} button keys {"?", "u", "q", "s", ""} default button 5
	if minWidth > accViewWidth then set accViewWidth to minWidth -- make sure buttons fit
	set {theField, theTop} to create field default_contents_text placeholder text "Paste URL here" left inset accViewInset bottom 0 field width accViewWidth - accViewInset extra height 15
	set {theRule, theTop} to create rule theTop + 18 rule width accViewWidth
	set {theCheckbox_Show_Settings, theTop} to create checkbox "Show settings before download" left inset accViewInset + 50 bottom (theTop + 10) max width 250 initial state DL_Show_Settings
	set {theCheckbox_SubTitles, theTop} to create checkbox "Subtitles for this download" left inset accViewInset bottom (theTop + 15) max width 250 initial state DL_subtitles
	set {theCheckbox_Credentials, theTop} to create checkbox "Credentials for download" left inset accViewInset bottom (theTop + 5) max width 200 without initial state
	set {theCheckbox_Description, theTop} to create checkbox "Download description" left inset accViewInset bottom (theTop + 5) max width 175 initial state DL_description
	set {main_thePopUp_FileFormat, main_formatlabel, theTop} to create labeled popup {"No remux", "mp4", "mkv", "webm", "flv", "ogg", "avi", "aac", "flac", "mp3", "m4a", "opus", "vorbis", "wav"} left inset accViewInset - 5 bottom (theTop + 5) popup width 100 max width 200 label text "Remux file format:" popup left accViewInset + 120 initial choice DL_Remux_format
	set {thePathControl, pathLabel, theTop} to create labeled path control (POSIX path of downloadsFolder_Path) left inset accViewInset bottom (theTop + 5) control width accViewWidth - 280 label text "Change download folder" with pops up
	set {theCheckbox_OpenBatch, theTop} to create checkbox "Open Batch functions" left inset (accViewInset + 210) bottom (theTop - 40) max width 200 without initial state
	set {theCheckbox_AddToBatch, theTop} to create checkbox "Add URL to Batch file" left inset (accViewInset + 210) bottom (theTop + 5) max width 200 initial state DL_batch_status
	set {diag_settings_prompt, theTop} to create label diag_settings_text left inset accViewInset bottom theTop + 8 max width accViewWidth control size regular size with bold type
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 60 view width 64 view height 64 scale image scale proportionally
	
	-- Display the dialog
	tell me to activate
	set {button_returned, controls_results, finalPosition} to display enhanced window diag_Title acc view width accViewWidth acc view height theTop acc view controls {theField, theCheckbox_Show_Settings, theCheckbox_SubTitles, theCheckbox_Credentials, theCheckbox_Description, main_thePopUp_FileFormat, main_formatlabel, thePathControl, theCheckbox_AddToBatch, theCheckbox_OpenBatch, pathLabel, diag_settings_prompt, theRule, MacYTDL_icon} buttons theButtons active field theField initial position window_Position
	
	-- Get control results from dialog
	set openBatch_chosen to item 10 of controls_results
	set DL_batch_status to item 9 of controls_results
	set folder_chosen to item 8 of controls_results
	set remux_format_choice to item 6 of controls_results
	set description_choice to item 5 of controls_results
	set credentials_choice to item 4 of controls_results
	set subtitles_choice to item 3 of controls_results
	set show_settings_choice to item 2 of controls_results
	set URL_user_entered_clean to item 1 of controls_results -- Needed to refill the URL box on return from Settings, Help etc.
	set URL_user_entered to quoted form of item 1 of controls_results -- Quoted form needed in case the URL contains ampersands etc - but really need to get quoted form of each URL when more than one
	
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
	
	if button_returned is "Settings" then
		set_settings(URL_user_entered_clean)
	else if button_returned is "Utilities" then
		utilities()
	else if button_returned is "Help" then
		set MacYTDL_help_file to (path to resource "Help.pdf" in bundle (path to me)) as string
		tell application "Finder"
			open file MacYTDL_help_file
		end tell
		main_dialog()
	else if button_returned is "Quit" then
		quit_MacYTDL()
	end if
	
	-- Convert settings set in Main Dialog to format that can be used as youtube-dl parameters + define variables
	if description_choice is true then
		set YTDL_description to "--write-description "
	else
		set YTDL_description to ""
	end if
	set YTDL_audio_only to ""
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
	
	-- User's remux, format, thumbnail, verbose, credential and metadata settings
	if remux_format_choice is not "No remux" then
		set YTDL_remux_format to "--recode-video " & remux_format_choice & " " & "--postprocessor-args \"-codec copy\" "
	else
		set YTDL_remux_format to ""
	end if
	if DL_Remux_original is true then
		set YTDL_Remux_original to "--keep-video "
	else
		set YTDL_Remux_original to ""
	end if
	if DL_format is not "Default" then
		set YTDL_format to "-f bestvideo[ext=" & DL_format & "]+bestaudio/best[ext=" & DL_format & "]/best "
	else
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
	if DL_Add_Metadata is true then
		set YTDL_metadata to "--add-metadata "
	else
		set YTDL_metadata to ""
	end if
	-- Set settings to enable audio only download - gets a format list - use post-processing if necessary - need to ignore all errors here which are usually due to missing videos etc.
	if DL_audio_only is true then
		try
			set YTDL_get_formats to do shell script shellPath & "youtube-dl --list-formats --ignore-errors " & URL_user_entered & " 2>&1"
		on error errStr
			set YTDL_get_formats to errStr
		end try
		-- To get a straight audio-only download, user must not request a remux
		if YTDL_get_formats contains "audio only" then
			set YTDL_audio_only to "--format bestaudio "
			set YTDL_format to ""
			set YTDL_remux_format to ""
		else
			-- There is no audio only file available so, extract audio in post-processing with best format (which is default)
			set YTDL_remux_format to "--extract-audio  --audio-quality 0 "
		end if
	end if
	-- Whether or not audio-only is selected, if an audio remux is specified, set up a remux to desired audio format with highest quality
	if remux_format_choice is in {"aac", "flac", "mp3", "m4a", "opus", "vorbis", "wav"} then
		set YTDL_remux_format to "--extract-audio --audio-format " & remux_format_choice & " --audio-quality 0 "
	end if
	
	-- Set variable to contain download folder path - value comes from runtime settings which gets initial value from preferences but which user can then change
	set downloadsFolder_Path to folder_chosen
	
	if button_returned is "Continue" then
		if openBatch_chosen is true then
			open_batch_processing(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
		else
			download_video(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
		end if
	end if
end main_dialog


---------------------------------------------------------------------------------------------
--
-- 	Download videos - called by Main dialog - calls monitor.scpt
--
---------------------------------------------------------------------------------------------

on download_video(folder_chosen, remux_format_choice, subtitles_choice, YTDL_credentials, YTDL_subtitles, YTDL_STEmbed, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
	
	check_download_folder(folder_chosen)
	
	-- Remove any trailing slash in the URL - causes syntax error with code to follow
	if text -2 of URL_user_entered is "/" then
		set URL_user_entered to quoted form of (text 2 thru -3 of URL_user_entered) -- Why not just remove the trailing slash ??
	end if
	
	-- Do error checking on pasted URL
	-- First, is pasted URL blank ?
	if URL_user_entered is "" or URL_user_entered is "Paste URL here" then
		set quit_or_return to button returned of (display dialog "You need to paste a URL before selecting Download.  Quit or OK to try again." buttons {"Quit", "OK"} default button "OK" cancel button "Quit" with title diag_Title with icon note giving up after 600)
		if quit_or_return is "OK" then
			main_dialog()
		end if
	end if
	
	-- Second was pasted URL > 4 characters long but did not begin with "http"
	if length of URL_user_entered is greater than 4 then
		set test_URL to text 2 thru 5 of URL_user_entered
		if not test_URL is "http" then
			set quit_or_return to button returned of (display dialog "You entered \"" & URL_user_entered & "\" which is not a valid URL.  It should begin with the letters http.  You need to paste a valid URL before selecting Download.  Quit or OK to try again." buttons {"Quit", "OK"} default button "OK" cancel button "Quit" with title diag_Title with icon note giving up after 600)
			if quit_or_return is "OK" then
				main_dialog()
			end if
		end if
		
		-- Third, is length of pasted URL </= 4
	else
		set quit_or_return to button returned of (display dialog "You entered \"" & URL_user_entered & "\" which is not a valid URL.  You need to paste a valid URL before selecting Download.  Quit or OK to try again." buttons {"Quit", "OK"} default button "OK" cancel button "Quit" with title diag_Title with icon note giving up after 600)
		if quit_or_return is "OK" then
			main_dialog()
		end if
	end if
	
	-- Fourth, test whether the URL is one of the Australian broadcasters and fashion ytdl command to get best series and file name
	-- ABC usually has the series name separate - so, need to add series parameter to the output template - movies and single show pages just repeat the show name which is OK for now
	-- ITV also has the series name and season available separately - movies repeat the series name and show season as "NA" which is OK 
	-- SBS and tenplay usually have the series name in the title - so, no need to add the series parameter
	-- 9Now is a detective story to find the show name - have to parse the URL
	-- 7Plus is also a detective story to find the show name - but, the extractor now finds the series name in the web page title
	-- 7Plus can also have extractor problems - shows can be AES-SAMPLE encrypted etc.  At present DRM issues cannot be solved.
	
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
		set NineNow_show_new to replace_chars(NineNow_show_old, "-", "_")
		set YTDL_output_template to " -o '" & NineNow_show_new & "-%(title)s.%(ext)s'"
	else if URL_user_entered contains "7Plus" then
		set YTDL_output_template to " -o '%(series)s-%(title)s.%(ext)s'"
	else
		-- Standard output template for all other sites
		set YTDL_output_template to " -o '%(title)s.%(ext)s'"
	end if
	
	-- Fifth, use simulated YTDL run to look for errors reported back by YTDL, such as invalid URL which would otherwise stop MacYTDL
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
	
	-- Indicator which will show whether URL is for an ABC show page - needed for over-writing code below
	set ABC_show_indicator to "No"
	
	-- Initiate the simulation to get back file name and disclose any errors or warnings
	try
		-- set URL_user_entered_trimmed to items 2 thru -2 of URL_user_entered as string -- youtube-dl fails when there are quotes around multiple URLs - at least it only returns filename(s) for the first URL - unless each is quoted separately ! <= but is this needed given that URL_user_entered_clean is available already ? Seems to work without
		do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; " & "youtube-dl --get-filename --restrict-filenames --ignore-errors " & YTDL_credentials & URL_user_entered_clean_quoted & " " & YTDL_output_template & " > /dev/null" & " &> " & YTDL_simulate_file
	on error
		set YTDL_simulate_response to read POSIX file YTDL_simulate_file
		set AppleScript's text item delimiters to "ERROR:"
		set YTDL_simulate_response_Items to every text item of YTDL_simulate_response
		set AppleScript's text item delimiters to ""
		set URL_error to text 2 thru end of item 2 of YTDL_simulate_response_Items -- <= Seems to cause crash when a playlist is long				
		-- Is the URL from an ABC Show Page ? - If so, get the user to choose which episodes to download
		if URL_error contains "Unsupported URL: https://iview.abc.net.au/show/" then
			Get_ABC_Episodes(URL_user_entered)
			set ABC_show_indicator to "Yes"
			set URL_user_entered to ABC_show_URLs
		else
			set quit_or_return to button returned of (display dialog "There was an error with the URL you entered:" & return & return & URL_user_entered & return & return & "The error message was: " & return & return & URL_error & return & return & "Quit, OK to return or Download to try anyway." buttons {"Quit", "OK", "Download"} default button "OK" cancel button "Quit" with title diag_Title with icon note giving up after 600)
			if quit_or_return is "OK" then
				main_dialog()
			else if quit_or_return is "Download" then
				-- User wants to try to download !
			end if
		end if
	end try
	
	-- Sixth, look for any warnings in simulate file. If none, get filename from the simulate response file
	-- Don't show warning to user if it's just the fallback to generic extractor - that happens too often to be useful
	-- Because extension can be different, exclude that from file name
	-- Currently testing method for doing that (getting download_filename) - might not work if file extension is not 3 characters (eg. ts)
	-- Might remove the extraneous dot characters in file names if they prove a problem
	-- There is a warning for ABC iView when URL is for a multiple episode "show" page
	-- Also warning if URL is an SBS multiple episode show page - can't download from those as yet
	
	set YTDL_simulate_response to read POSIX file YTDL_simulate_file
	if YTDL_simulate_response contains "WARNING" then
		if YTDL_simulate_response does not contain "Falling back on generic information" then
			set warning_quit_or_continue to button returned of (display dialog "youtube-dl has given a warning on the URL you entered:" & return & return & URL_user_entered & return & return & "The warning message was: " & return & return & YTDL_simulate_response & return & "Your copy of youtube-dl might be out of date.   You can check that or, you can return to the main dialog or continue to see what happens." buttons {"Main", "Check for Updates", "Continue"} default button "Continue" with title diag_Title with icon note giving up after 600)
			if warning_quit_or_continue is "Check for Updates" then
				check_ytdl()
				check_ffmpeg()
				display dialog alert_text_ytdl & alert_text_ffmpeg with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 600
				main_dialog()
			else if warning_quit_or_continue is "Continue" then -- <= Ignore the warning and give the DL a try
				set_File_Names(YTDL_simulate_response)
			else if warning_quit_or_continue is "Main" then -- <= Stop and return to Main dialog
				main_dialog()
			end if
		else if YTDL_simulate_response contains "meta.ogTitle.unknown_video" then
			display dialog "This is an SBS \"Show\" page from which MacYTDL cannot download videos. Try an individual episode." with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 600
			main_dialog()
		else
			-- Simulate warning is just the fallback to generic extractor and so is ignored
			set_File_Names(YTDL_simulate_response)
		end if
	else
		-- This is a non-warning download
		set_File_Names(YTDL_simulate_response)
	end if
	
	-- If user asked for subtitles, get ytdl to check whether they are available - if not, warn user - if available, check against format requested - convert if different
	if subtitles_choice is true and URL_user_entered_clean is not equal to "" then
		set YTDL_subtitles to check_subtitles_download_available()
	end if
	
	-- Set the YTDL settings into one variable - makes it easier to maintain - ensure spaces are where needed - quoted to enable passing to Monitor script
	set ytdl_settings to quoted form of (" --restrict-filenames --ignore-errors --prefer-ffmpeg " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_over_writes & YTDL_Thumbnail_Write & YTDL_Thumbnail_Embed & YTDL_metadata & YTDL_verbose & YTDL_output_template & " ")
	
	-- If preference is to not over-write, check whether download file exists and if so ask user what to do then set youtube-dl settings accordingly
	-- Beware ! This section doesn't cope with part download files which are left to klag YTDL - they should be automatically deleted but, anything can happen
	if YTDL_over_writes is "--no-overwrites " then
		set downloadsFolder_Path_posix to (POSIX file downloadsFolder_Path)
		set downloadsFolder_Path_alias to downloadsFolder_Path_posix as alias
		
		-- Look for file of same name in downloads folder - use file names saved in the simulate file - there can be one or a number	
		-- But, first check whether it's an ABC show page - because the simulate file for those does not contain the file name
		if ABC_show_indicator is "Yes" then
			tell application "Finder"
				set search_for_download to files in downloadsFolder_Path_alias where name contains download_filename_new
				if search_for_download is not {} then
					set overwrite_continue_choice to button returned of (display dialog "A file for the ABC show \"" & show_name & "\" already exists" & return & return & "Do you want to continue anyway, download with a different name or stop and return to the main dialog ?" buttons {"Overwrite", "New name", "Cancel download"} default button "Cancel download" with title diag_Title with icon note giving up after 600)
					if overwrite_continue_choice is "Overwrite" then
						set ytdl_settings to quoted form of (" --restrict-filenames --ignore-errors --prefer-ffmpeg --no-continue " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_metadata & YTDL_verbose & YTDL_output_template & " ")
					else if overwrite_continue_choice is "New name" then
						set YTDL_output_template_new to my replace_chars(YTDL_output_template, "title)s", "title)s-2")
						set ytdl_settings to quoted form of (" --restrict-filenames --ignore-errors --prefer-ffmpeg " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_over_writes & YTDL_metadata & YTDL_verbose & YTDL_output_template_new & " ")
					else if overwrite_continue_choice is "Cancel download" then
						my main_dialog()
					end if
				end if
			end tell
		else
			repeat with each_filename in (get paragraphs of YTDL_simulate_response)
				set each_filename to each_filename as text
				set length_each_filename to count words of each_filename
				if length_each_filename is not 0 then
					tell application "Finder"
						set search_for_download to (files in downloadsFolder_Path_alias where name contains each_filename)
						if search_for_download is not {} then
							set overwrite_continue_choice to button returned of (display dialog "The file \"" & each_filename & "\" already exists" & return & return & "Do you want to continue anyway, download with a different name or stop and return to the main dialog ?" buttons {"Overwrite", "New name", "Cancel download"} default button "Cancel download" with icon note giving up after 600)
							if overwrite_continue_choice is "Overwrite" then
								set ytdl_settings to quoted form of (" --restrict-filenames --ignore-errors --prefer-ffmpeg --no-continue " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_metadata & YTDL_verbose & YTDL_output_template & " ")
							else if overwrite_continue_choice is "New name" then
								set YTDL_output_template_new to my replace_chars(YTDL_output_template, "title)s", "title)s-2")
								set ytdl_settings to quoted form of (" --restrict-filenames --ignore-errors --prefer-ffmpeg " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_over_writes & YTDL_metadata & YTDL_verbose & YTDL_output_template_new & " ")
							else if overwrite_continue_choice is "Cancel download" then
								my main_dialog()
							end if
						end if
					end tell
				end if
			end repeat
		end if
	end if
	
	-- Prepare to call on the download Monitor - first get Monitor script location -- Monitor-bundle.scptd
	set myMonitorScriptAsString to quoted form of ((POSIX path of (path to me)) & "Contents/Resources/Scripts/Monitor.scpt")
	-- Increment vertical position so successive monitors don't overlap - starts with 0
	set monitor_dialog_position to (monitor_dialog_position + 1)
	
	-- Pull together all the parameters to be sent to the Monitor script
	-- Set URL to quoted form so that Monitor will parse myParams correctly when URLs come from the Get_ABC_Episodes handler - but not for single episode iView show pages
	if show_name is not "" then
		set URL_user_entered to quoted form of URL_user_entered
	end if
	
	-- Put diag title, file and path names into quotes as they are not passed correctly when they contain apostrophes or spaces
	set download_filename_new to quoted form of download_filename_new
	set YTDL_response_file to quoted form of YTDL_response_file
	set YTDL_simulate_response to text 1 thru -2 of YTDL_simulate_response
	set YTDL_simulate_response to quoted form of YTDL_simulate_response
	set diag_Title_quoted to quoted form of diag_Title
	
	-- Form up parameters for the following do shell script		
	set my_params to quoted form of downloadsFolder_Path & " " & MacYTDL_preferences_path & " " & ytdl_settings & " " & URL_user_entered & " " & YTDL_response_file & " " & download_filename_new & " " & MacYTDL_custom_icon_file_posix & " " & monitor_dialog_position & " " & YTDL_simulate_response & " " & diag_Title_quoted
	
	if DL_batch_status is true then
		add_To_Batch(URL_user_entered, number_of_URLs)
	end if
	
	-- Show current download settings if user has specified that in Settings
	if DL_Show_Settings is true then
		
		-- Convert boolean settings to text to enable list of current settings to be shown intelligibly in "Show Settings" dialog
		if YTDL_subtitles contains "--write-sub" then
			set MDDL_subtitles to "Yes"
		else
			set MDDL_subtitles to "No"
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
			set MDDL_verbose to "Yes "
		else
			set MDDL_verbose to "No"
		end if
		if DL_Thumbnail_Embed is true then
			set MDDL_Thumbnail_Embed to "Yes "
		else
			set MDDL_Thumbnail_Embed to "No"
		end if
		if DL_Add_Metadata is true then
			set MDDL_Add_Metadata to "Yes "
		else
			set MDDL_Add_Metadata to "No"
		end if
		
		-- Set contents of optional subtitles embedded status and format - only shows if subtitles are requested
		-- Ditto with whether to keep original after remuxing and embedded thumbnails
		-- if DL_subtitles is true and DL_STEmbed is true then
		set subtitles_embedded_pref to ""
		if MDDL_subtitles is "Yes" then
			set subtitles_embedded_pref to return & "Embedded" & tab & tab & tab & MDDL_STEmbed
		end if
		set subtitles_format_pref to "No subtitles"
		if DL_subtitles is true and DL_STEmbed is false then
			set subtitles_format_pref to "Subtitles format" & tab & tab & DL_subtitles_format
		end if
		set keep_original_pref to ""
		if DL_Remux_format is not "No remux" or YTDL_subtitles contains "convert" then
			set keep_original_pref to return & "Keep original file(s)" & tab & MDDL_Remux_original
		end if
		set thumbnails_embed_pref to "Embed thumbnails" & tab & MDDL_Thumbnail_Embed
		
		-- Set variables for the Show Settings dialog	
		set diag_prompt_text_1 to "Download folder: " & tab & tab & folder_chosen & return & "youtube-dl version:" & tab & YTDL_version & return & "FFmpeg version:" & tab & tab & ffmpeg_version & return & "Python version:" & tab & tab & python_version & return & "Download file format:" & tab & DL_format & return & "Audio only:" & tab & tab & tab & MDDL_audio_only & return & "Description:" & tab & tab & tab & MDDL_description & return & "Download subtitles:" & tab & MDDL_subtitles & subtitles_embedded_pref & return & "Remux download:" & tab & tab & remux_format_choice & keep_original_pref & return & "Write thumbnails:" & tab & tab & MDDL_Thumbnail_Write & return & thumbnails_embed_pref & return & "Verbose feedback:" & tab & MDDL_verbose & return & "Add metadata:" & tab & tab & MDDL_Add_Metadata & return & "Over-write existing:" & tab & MDDL_over_writes
		set show_settings_diag_prompt to "Settings for this download"
		set accViewWidth to 500
		set accViewInset to 80
		
		-- Set buttons and controls
		set {theButtons, minWidth} to create buttons {"Quit", "Edit settings", "Cancel download", "Download"} button keys {"q", "e", "c", "d"} default button 4
		if minWidth > accViewWidth then set accViewWidth to minWidth
		set {theShowSettingsRule, theTop} to create rule 10 rule width accViewWidth
		set {show_settings_theCheckbox, theTop} to create checkbox "Show settings before download" left inset 20 bottom (theTop + 15) max width accViewWidth initial state DL_Show_Settings
		set {diag_prompt_1, theTop} to create label diag_prompt_text_1 left inset accViewInset bottom theTop + 15 max width accViewWidth control size regular size
		set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 60 view width 64 view height 64 scale image scale proportionally
		set {show_settings_prompt, theTop} to create label show_settings_diag_prompt left inset 0 bottom theTop + 5 max width minWidth aligns center aligned with bold type
		
		set show_settings_allControls to {theShowSettingsRule, show_settings_theCheckbox, diag_prompt_1, MacYTDL_icon, show_settings_prompt}
		
		-- Make sure MacYTDL is in front and show dialog
		tell me to activate
		set {show_settings_button_returned, show_settings_controls_results} to display enhanced window diag_Title buttons theButtons acc view width minWidth acc view height theTop acc view controls show_settings_allControls
		
		-- Update show settings setting if user has changed it		
		set show_settings_choice to item 2 of show_settings_controls_results -- <= Stop showing the download settings dialog
		if show_settings_choice is not equal to DL_Show_Settings then
			set DL_Show_Settings to show_settings_choice
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Show_Settings_before_Download" to show_settings_choice
				end tell
			end tell
		end if
		
		if show_settings_button_returned is "Cancel download" then
			main_dialog()
		else if show_settings_button_returned is "Edit settings" then
			set_settings(URL_user_entered_clean)
		else if show_settings_button_returned is "Quit" then
			quit_MacYTDL()
		end if
		
		-- If user chooses "Download" processing continues to next line of code
		
	end if
	
	
	-- PRODUCTION CALL - Call the download Monitor script which will run as a separate process and return so Main Dialog can be re-displayed - thus user can start any number of downloads
	do shell script "osascript -s s " & myMonitorScriptAsString & " " & my_params & " " & " > /dev/null 2> /dev/null &"
	
	-- TESTING CALL - Call the download Monitor script for testing - this formulation gets any errors back from Monitor, but holds execution until Monitor dialog is dismissed
	-- do shell script "osascript -s s " & myMonitorScriptAsString & " " & my_params
	
	-- After download, reset URLs so text box is blank and old URL not used again and myNum so that correct file name is used for next download
	set URL_user_entered to ""
	set ABC_show_URLs to ""
	set URL_user_entered_clean to ""
	set myNum to 0
	
	main_dialog()
	
end download_video


---------------------------------------------------------------------------------------
--
-- 	Check downloads folder - called by download_video and download_batch
--
---------------------------------------------------------------------------------------
-- Check that download folder is available - in case user has not mounted an external volume or has moved/renamed the folder
on check_download_folder(folder_chosen)
	if folder_chosen = downloadsFolder_Path then
		set downloadsFolder_Path_posix to (POSIX file downloadsFolder_Path)
		try
			set downloadsFolder_Path_alias to downloadsFolder_Path_posix as alias
		on error
			set quit_or_return to button returned of (display dialog "Your download folder is not available.  You can make it available then click on Continue, return to set a new download folder or quit." buttons {"Quit", "Return", "Continue"} default button "Return" cancel button "Quit" with title diag_Title with icon note giving up after 600)
			if quit_or_return is "Return" then
				main_dialog()
			else if quit_or_return is "Quit" then
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
	
	-- Set download_filename which is used to show a name in the Monitor dialog and forms basis for response file name
	-- Reformat file name and add to name of responses file - converting spaces to underscores to reduce need for quoting throughout code (and to be consistent with file name saved by YTDL)
	
	set num_paragraphs_response to count of paragraphs of YTDL_simulate_response
	set AppleScript's text item delimiters to " "
	set number_of_URLs to number of text items in URL_user_entered
	set AppleScript's text item delimiters to ""
	
	-- Get date and time so it can be added to response file name
	set download_date_time to get_Date_Time()
	
	-- First, look for non-View show pages (but iView non-error single downloads are INcluded)
	-- This section deals poorly with youtube playlists - including those with ampersands in them but should work
	if show_name is "" then -- not an iView show page
		if number_of_URLs is 1 then -- Not a multiple file download
			if YTDL_simulate_response does not contain "WARNING" then --<= A single file or playlist download non-error and non-warning (iView and non-iView)
				if num_paragraphs_response is 2 then --<= A single file download (iView and non-iView) - need to trim ".mp4<para>" from end of file (which is a single line containing one file name)
					set download_filename to text 1 thru -6 of YTDL_simulate_response
					set download_filename_new to replace_chars(download_filename, " ", "_")
					set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-" & download_filename_new & "-" & download_date_time & ".txt"
				else --<= Probably a Youtube playlist - but beware as there can be playlists on other sites - NB this also currently picks up single track downloads from Youtube playlists
					set download_filename_new to "the playlist"
					set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-" & download_filename_new & "-" & download_date_time & ".txt"
				end if
			else --<= Single file download but simulate.txt contains WARNING in first paragraph (iView and non-iView) - need to trim ".mp4<para>" from end of 2nd paragraph which is last line of file
				set download_filename to text 1 thru -5 of paragraph 2 of YTDL_simulate_response
				set download_filename_new to replace_chars(download_filename, " ", "_")
				set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-" & download_filename_new & "-" & download_date_time & ".txt"
			end if
		else --<= This is a multiple file (iView and non-iView) download - keep download filename simple - don't distinguish between iView and other - covers warning and non-warning cases (as it does not need filename from simulate.txt)
			set download_filename_new to "the multiple videos"
			set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-Multiple_download_on-" & download_date_time & ".txt"
		end if
	else
		
		-- Second, look for iView show page downloads (which are all ERROR cases)	
		if myNum is 0 then
			-- Look for iView single show page downloads - no episodes are shown on these pages - so, have to simulate to get file name - there is usually no separate series name available as the show is also the series
			set YTDL_output_template to " -o '%(title)s.%(ext)s'"
			set download_filename_new to text 1 thru -5 of (do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; " & "youtube-dl --get-filename --restrict-filenames " & URL_user_entered & " " & YTDL_output_template)
			set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-" & download_filename_new & "-" & download_date_time & ".txt"
		else if myNum is 1 then
			-- Look for iView single show page downloads - just single episodes are shown on these pages - so, have to simulate to get file name - there is usually no separate series name available as the show is also the series
			set YTDL_output_template_get_name to " -o '%(title)s.%(ext)s'"
			set download_filename to text 1 thru -5 of (do shell script shellPath & "cd " & quoted form of downloadsFolder_Path & " ; " & "youtube-dl --get-filename --restrict-filenames " & URL_user_entered & " " & YTDL_output_template_get_name)
			set show_name_new to replace_chars(show_name, " ", "_")
			set download_filename_new to show_name_new & "-" & download_filename
			set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-" & download_filename_new & "-" & download_date_time & ".txt"
		else
			-- Look for iView episode show page downloads - two or more episodes are shown on web page and so show_name is populated in Get_ABC_episodes handler
			set download_filename to show_name
			set download_filename_new to replace_chars(download_filename, " ", "_")
			set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-" & download_filename_new & "-" & download_date_time & ".txt"
		end if
	end if
	-- Make sure there are no colons in the file name - can happen with iView and maybe others - ytdl converts colons into "_-" so, this must also
	set download_filename_new to replace_chars(download_filename_new, ":", "_-")
	
	-- ***************** Dialog to show variable values set by this handler
	-- display dialog "num_paragraphs_response: " & num_paragraphs_response & return & return & "number_of_URLs: " & number_of_URLs & return & return & "URL_user_entered: " & URL_user_entered & return & return & "show_name: " & show_name & return & return & "myNum: " & myNum & return & return & "download_filename_new: " & download_filename_new & return & return & "YTDL_response_file: " & YTDL_response_file
	-- ***************** 
	
end set_File_Names


-----------------------------------------------------------------------
--
-- 		Check subtitles are available and in desired language
--
-----------------------------------------------------------------------
-- Handler to check that requested subtitles are available and apply conversion if not - called by download_video() when needed
-- Might not need the duplication in this handler - leave till a later release - Handles ABC show URL and multiple URLs somewhat
on check_subtitles_download_available()
	-- Initialise youtube-dl subtitles parameter 
	set YTDL_subtitles to ""
	-- Need to use different URL variable for ABC shows - different treatment of quotes
	if show_name is "" then
		set URL_for_subtitles_test to URL_user_entered_clean
	else
		set URL_for_subtitles_test to URL_user_entered
	end if
	-- If user asked for subtitles, get ytdl to check whether they are available - if not, warn user
	set check_subtitles_available to do shell script shellPath & "youtube-dl --list-subs --ignore-errors " & URL_for_subtitles_test
	if check_subtitles_available does not contain "Language formats" then
		set subtitles_quit_or_continue to button returned of (display dialog "There is no subtitle file available for your video (although it might be embedded)." & return & return & "You can quit, cancel your download or download anyway." buttons {"Quit", "Cancel download", "Continue"} default button "Continue" with title diag_Title with icon note giving up after 600)
		if subtitles_quit_or_continue is "Quit" then
			quit_MacYTDL()
		else if subtitles_quit_or_continue is "Cancel download" then
			main_dialog()
		else
			return YTDL_subtitles
		end if
	else if check_subtitles_available contains "Language formats" then
		-- Subtitles are available - check against language and format requested - convert if different - there can be more than one format available - warn user if desired language not available
		-- Parse check_subtitles_available to get list of languages and formats that are available		
		set subtitles_info to ""
		set response_ST_paragraphs to paragraphs of check_subtitles_available
		repeat with response_subtitle_paragraph in response_ST_paragraphs
			-- Might need a more descriminating if test below of YTDL response can have other 12 character paragrpahs
			if length of response_subtitle_paragraph is 12 then
				set subtitles_info to subtitles_info & response_subtitle_paragraph & return
			end if
		end repeat
		if subtitles_info does not contain (DL_STLanguage & " ") then
			set subtitles_quit_or_continue to button returned of (display dialog "There is no subtitle file in your preferred language " & "\"" & DL_STLanguage & "\".  These subtitles are available (for each video requested): " & return & return & "Code    Format" & return & subtitles_info & return & "You can quit, cancel your download (then go to Settings to change language) or download anyway." buttons {"Quit", "Cancel download", "Continue"} default button "Continue" with title diag_Title with icon note giving up after 600)
			if subtitles_quit_or_continue is "Quit" then
				quit_MacYTDL()
			else if subtitles_quit_or_continue is "Cancel download" then
				main_dialog()
			end if
		end if
		-- If desired language is available or user choose to continue anyway, processing continues here - YTDL returns a warning if lang not available but continues to download
		-- Is desired format available - if so continue - if not convert - conversion can currently handle only src, ass, lrc and vtt - passing best, dfxp or ttml uses YTDL's own choice
		if subtitles_info does not contain DL_subtitles_format and DL_subtitles_format is not "best" and DL_subtitles_format is not "ttml" and DL_subtitles_format is not "dfxp" then
			set YTDL_subtitles to "--write-sub --convert-subs " & DL_subtitles_format & " " & "--sub-lang " & DL_STLanguage & " "
		else if DL_subtitles_format is "best" then
			set YTDL_subtitles to "--write-sub --sub-format best " & "--sub-lang " & DL_STLanguage & " "
		else if DL_subtitles_format is "dfxp" then
			set YTDL_subtitles to "--write-sub --sub-format dfxp " & "--sub-lang " & DL_STLanguage & " "
		else if DL_subtitles_format is "ttml" then
			set YTDL_subtitles to "--write-sub --sub-format ttml " & "--sub-lang " & DL_STLanguage & " "
		else
			-- Site does provide format user wants
			set YTDL_subtitles to "--write-sub --sub-format " & DL_subtitles_format & " " & "--sub-lang " & DL_STLanguage & " "
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

-- Handler for setting various MacYTDL and youtube-dl settings
on set_settings(URL_user_entered_clean)
	read_settings()
	
	-- Set variables for the settings dialog	
	set settings_diag_prompt to "MacYTDL Settings"
	set accViewWidth to 450
	set accViewInset to 0
	
	-- Set buttons and controls
	set {theButtons, minWidth} to create buttons {"Cancel", "Save Settings"} button keys {"c", ""} default button 2
	--if minWidth > accViewWidth then set accViewWidth to minWidth --<= Not needed as two buttons narrower than the dialog - keep in case things change
	set {theSettingsRule, theTop} to create rule 10 rule width accViewWidth
	set {settings_theCheckbox_Show_Settings, theTop} to create checkbox "Show download settings before starting download" left inset 80 bottom (theTop + 10) max width 200 initial state DL_Show_Settings
	set {settings_theCheckbox_Original, theTop} to create checkbox "Keep original video and/or subtitles file" left inset 80 bottom (theTop + 10) max width 200 initial state DL_Remux_original
	set {settings_thePopUp_RemuxFormat, settings_remuxlabel, theTop} to create labeled popup {"No remux", "mp4", "mkv", "webm", "ogg", "avi", "flv", "aac", "flac", "mp3", "m4a", "opus", "vorbis", "wav"} left inset 80 bottom (theTop + 5) popup width 100 max width 200 label text "Remux format:" popup left 180 initial choice DL_Remux_format
	set {settings_theCheckbox_Metadata, theTop} to create checkbox "Add Metadata" left inset 80 bottom (theTop + 5) max width 250 initial state DL_Add_Metadata
	set {settings_theCheckbox_Verbose, theTop} to create checkbox "Verbose youtube-dl feedback" left inset 80 bottom (theTop + 5) max width 250 initial state DL_verbose
	-- Show the embed subtitles checkbox if AtomicParsley is installed
	if Atomic_is_installed is true then
		set {settings_theCheckbox_ThumbEmbed, theTop} to create checkbox "Embed thumbnails" left inset 280 bottom (theTop + 5) max width 250 initial state DL_Thumbnail_Embed
	else
		set {settings_theCheckbox_ThumbEmbed, theTop} to create label "" left inset 80 bottom (theTop + 5) max width 250
		
	end if
	set {settings_theCheckbox_ThumbWrite, theTop} to create checkbox "Write thumbnails" left inset 80 bottom (theTop - 18) max width 250 initial state DL_Thumbnail_Write
	set {settings_theCheckbox_STEmbed, theTop} to create checkbox "Embed subtitles" left inset 80 bottom (theTop + 5) max width 250 initial state DL_STEmbed
	set {settings_theField_STLanguage, settings_language_label, theTop, fieldLeft} to create side labeled field DL_STLanguage left inset 80 bottom (theTop + 5) total width 180 label text "Subtitles language:" field left 0
	set {settings_thePopUp_SubTitlesFormat, settings_STFormatlabel, theTop} to create labeled popup {"best", "srt", "vtt", "ass", "lrc", "ttml", "dfxp"} left inset 245 bottom (theTop) popup width 100 max width 200 label text "Subtitles format:" popup left 350 initial choice DL_subtitles_format
	set {settings_theCheckbox_SubTitles, theTop} to create checkbox "Download subtitles" left inset 80 bottom (theTop - 20) max width 250 initial state DL_subtitles
	set {settings_theCheckbox_Auto_YTDL_Check, theTop} to create checkbox "Check youtube-dl version on startup" left inset 80 bottom (theTop + 5) max width 250 initial state DL_YTDL_auto_check
	set {settings_theCheckbox_OverWrites, theTop} to create checkbox "Over-write existing files" left inset 80 bottom (theTop + 5) max width 250 initial state DL_over_writes
	set {settings_theCheckbox_AudioOnly, theTop} to create checkbox "Audio only" left inset 80 bottom (theTop + 5) max width 250 initial state DL_audio_only
	set {settings_theCheckbox_Description, theTop} to create checkbox "Download description" left inset 80 bottom (theTop + 5) max width 250 initial state DL_description
	set {settings_thePopUp_FileFormat, settings_formatlabel, theTop} to create labeled popup {"Default", "mp4", "mkv", "webm", "ogg", "avi", "3gp", "flv"} left inset 80 bottom (theTop + 5) popup width 100 max width 200 label text "File format:" popup left 160 initial choice DL_format
	set {settings_thePathControl, settings_pathLabel, theTop} to create labeled path control (POSIX path of downloadsFolder_Path) left inset 80 bottom (theTop + 10) control width 200 label text "Change download folder:" with pops up
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 50 view width 64 view height 64 scale image scale proportionally
	set {settings_prompt, theTop} to create label settings_diag_prompt left inset 0 bottom (theTop) max width accViewWidth aligns center aligned with bold type
	set settings_allControls to {theSettingsRule, settings_theCheckbox_Show_Settings, settings_theCheckbox_Original, settings_thePopUp_RemuxFormat, settings_remuxlabel, settings_theCheckbox_Metadata, settings_theCheckbox_Verbose, settings_theCheckbox_ThumbEmbed, settings_theCheckbox_ThumbWrite, settings_thePopUp_SubTitlesFormat, settings_STFormatlabel, settings_theField_STLanguage, settings_language_label, settings_theCheckbox_STEmbed, settings_theCheckbox_SubTitles, settings_theCheckbox_Auto_YTDL_Check, settings_theCheckbox_OverWrites, settings_theCheckbox_AudioOnly, settings_theCheckbox_Description, settings_thePopUp_FileFormat, settings_formatlabel, settings_thePathControl, settings_pathLabel, MacYTDL_icon, settings_prompt}
	
	-- Make sure MacYTDL is in front and show dialog
	tell me to activate
	set {settings_button_returned, settings_controls_results} to display enhanced window diag_Title buttons theButtons acc view width accViewWidth acc view height theTop acc view controls settings_allControls
	
	if settings_button_returned is "Save Settings" then
		-- Get control results from settings dialog - numbered choice variables are not used but help ensure correct values go into prefs file
		set settings_choice_1 to item 1 of settings_controls_results -- <= The ruled line
		set settings_show_settings_choice to item 2 of settings_controls_results -- <= Show settings before download choice
		set settings_original_choice to item 3 of settings_controls_results -- <= Keep original after remux choice
		set settings_remux_format_choice to item 4 of settings_controls_results -- <= Remux format choice
		set settings_choice_5 to item 5 of settings_controls_results -- <= The Remux format popup label
		set settings_metadata_choice to item 6 of settings_controls_results -- <= Add metadata choice
		set settings_verbose_choice to item 7 of settings_controls_results -- <= Verbose choice
		set settings_thumb_embed_choice to item 8 of settings_controls_results -- <= Embed Thumbnails choice
		set settings_thumb_write_choice to item 9 of settings_controls_results -- <= Write Thumbnails choice
		set settings_subtitlesformat_choice to item 10 of settings_controls_results -- <= Subtitles format choice
		set settings_STFormatlabel_choice to item 11 of settings_controls_results -- <= Subtitles format popup label
		set settings_subtitleslanguage_choice to item 12 of settings_controls_results -- <= Subtitles language choice
		set settings_subtitleslanguage_13 to item 13 of settings_controls_results -- <= Subtitles language field label
		set settings_stembed_choice to item 14 of settings_controls_results -- <= Embed subtitles choice
		set settings_subtitles_choice to item 15 of settings_controls_results -- <= Subtitles choice
		set settings_YTDL_auto_choice to item 16 of settings_controls_results -- <= Auto check YTDL version on startup choice
		set settings_over_writes_choice to item 17 of settings_controls_results -- <= Over-writes choice
		set settings_audio_only_choice to item 18 of settings_controls_results -- <= Audio only choice
		set settings_description_choice to item 19 of settings_controls_results -- <= Description choice
		set settings_format_choice to item 20 of settings_controls_results -- <= File format choice
		set settings_choice_21 to item 21 of settings_controls_results -- <= The Format popup label
		set settings_folder_choice to item 22 of settings_controls_results -- <= The download path choice
		set settings_choice_23 to item 23 of settings_controls_results -- <= The Path label
		set settings_choice_24 to item 24 of settings_controls_results -- <= The MacYTDL icon
		--		set settings_choice_25 to item 25 of settings_controls_results -- <= Contains the "About" text
		
		-- Save new settings to preferences file - no error checking needed for these
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "DownloadFolder" to settings_folder_choice
				set value of property list item "Remux_Format" to settings_remux_format_choice
				set value of property list item "FileFormat" to settings_format_choice
				set value of property list item "Over-writes allowed" to settings_over_writes_choice
				set value of property list item "Verbose" to settings_verbose_choice
				set value of property list item "Audio_Only" to settings_audio_only_choice
				set value of property list item "Description" to settings_description_choice
				set value of property list item "Thumbnail_Write" to settings_thumb_write_choice
				set value of property list item "Subtitles_Language" to settings_subtitleslanguage_choice
				set value of property list item "Subtitles_Format" to settings_subtitlesformat_choice
				set value of property list item "SubTitles" to settings_subtitles_choice
				set value of property list item "Auto_Check_YTDL_Update" to settings_YTDL_auto_choice
				set value of property list item "Add_Metadata" to settings_metadata_choice
				set value of property list item "Show_Settings_before_Download" to settings_show_settings_choice
			end tell
		end tell
		
		-- Check for invalid choice of subtitles and embedding and if OK, save to preferences file
		if settings_subtitles_choice is false and settings_stembed_choice is true then
			display dialog "Sorry, you need to turn on subtitles if you want them embedded." with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 600
			set_settings(URL_user_entered_clean)
		end if
		
		-- Check for invalid choice of subtitles embedding and file format
		if settings_stembed_choice is true and (settings_format_choice is not "mp4" and settings_format_choice is not "mkv" and settings_format_choice is not "webm" and settings_remux_format_choice is not "webm" and settings_remux_format_choice is not "mkv" and settings_remux_format_choice is not "mp4") then
			display dialog "Sorry, File format or Remux format must be mp4, mkv or webm for subtitles to be embedded." with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 600
			set_settings(URL_user_entered_clean)
		end if
		
		-- Now can go ahead and set the subtitles embedding settings
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "SubTitles_Embedded" to settings_stembed_choice
			end tell
		end tell
		
		--	Check whether subtitles will be converted - to determine whether keep original is valid
		if settings_subtitles_choice is true and settings_subtitlesformat_choice is not "best" and settings_subtitlesformat_choice is not "ttml" and settings_subtitlesformat_choice is not "dfxp" then
			set subtitles_being_converted to true
		else
			set subtitles_being_converted to false
		end if
		
		-- Check for invalid choice on keep original after remux or subtitles converted and if OK, save to preferences file
		if settings_original_choice is true and (settings_remux_format_choice is "No remux" and subtitles_being_converted is false) then
			display dialog "Sorry, you need to choose a remux format or choose to download a particular subtitles format if you want to keep the original." with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 600
			set_settings(URL_user_entered_clean)
		end if
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "Keep_Remux_Original" to settings_original_choice
			end tell
		end tell
		
		-- Check for invalid choice of embedding thumbnails in valid file formats (only works for mp3, mp4 and m4a files)
		-- Can set embed thumbnail to true if Atomic is installed and file format is mp4 OR remux format is mp3 or m4a
		-- Can set embed thumbnail to false if Atomic is installed and in any other combination if user wants it
		-- Error message if trying to set embed to true but file format is wrong
		-- If Atomic is not installed, embed thumbnail setting must be set to false
		if Atomic_is_installed is true then
			-- Embedding is true and file format is correct - set settings and return to Main
			if settings_thumb_embed_choice is true and (settings_format_choice is "mp4" or settings_remux_format_choice is "mp3" or settings_remux_format_choice is "m4a" or settings_remux_format_choice is "mp4") then
				tell application "System Events"
					tell property list file MacYTDL_prefs_file
						set value of property list item "Thumbnail_Embed" to settings_thumb_embed_choice
					end tell
				end tell
				-- Embedding is false - set settings and return to Main
			else if settings_thumb_embed_choice is false then
				tell application "System Events"
					tell property list file MacYTDL_prefs_file
						set value of property list item "Thumbnail_Embed" to settings_thumb_embed_choice
					end tell
				end tell
				-- Embedding is true but file format is wrong - display an error message return to Settings
			else if settings_thumb_embed_choice is true and (settings_format_choice is not "mp4" and settings_remux_format_choice is not "mp3" and settings_remux_format_choice is not "m4a" and settings_remux_format_choice is not "mp4") then
				display dialog "Sorry, to embed thumbnails, File format must be mp4 or Remux format must be mp3, mp4 or m4a." with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 600
				tell application "System Events"
					tell application "System Events"
						tell property list file MacYTDL_prefs_file
							set value of property list item "Thumbnail_Embed" to false
						end tell
					end tell
				end tell
				set_settings(URL_user_entered_clean)
			end if
		else
			-- Atomic not installed - set settings to false and return to Main - redundant but, ensures any glitches are corrected
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
-- 		Is youtube-dl installed ?
--
---------------------------------------------------

-- Handler to check if youtube-dl is installed - install if user agrees but can't run MacYTDL without it - called by main thread
on check_ytdl_installed()
	if YTDL_version is "Not installed" then
		set yt_install_diag_message to "youtube-dl is not installed." & return & return & "Would you like to install it now ?  If not, MacYTDL can't run and will have to quit.  Note: This download can take a while and you will probably need to provide administrator credentials."
		tell me to activate
		set yt_install to display dialog yt_install_diag_message with title diag_Title buttons {"Quit", "Yes"} default button "Yes" cancel button "Quit" with icon note giving up after 600
		set yt_install_answ to button returned of yt_install
		if yt_install_answ is "Yes" then
			-- Trial run of using notifications - might need to pull if users have alert style notifications and keep licking on the wrong thing
			-- Showing the notification using a shell script in background because otherwise it often just doesn't show !
			set myScriptAsString to "display notification \"Download and install of youtube-dl started.  Please wait, it will not be long.\" with title \"MacYTDL\""
			do shell script "osascript -e " & quoted form of myScriptAsString & " > /dev/null 2> /dev/null & "
			delay 1
			tell me to activate
			-- Make the /usr/local/bin/ folder if it doesn't exist
			try
				tell application "System Events"
					if not (exists folder usr_bin_folder) then
						tell current application to do shell script "mkdir -p " & usr_bin_folder with administrator privileges
					end if
				end tell
				-- Trap cases in which user is not able to access the web site - assume that's because they are offline
				try
					do shell script "curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl" with administrator privileges
				on error number 6
					display dialog "There was a problem with downloading youtube-dl. Perhaps you are not connected to the internet or the server is currently not available. When you are sure you are connected to the internet, re-open MacYTDL then try to install youtube-dl." buttons {"OK"} default button "OK" with title diag_Title with icon note giving up after 600
					quit_MacYTDL()
				end try
				do shell script "chmod a+x /usr/local/bin/youtube-dl" with administrator privileges
				-- trap case where user cancels credentials dialog - just quit as can't run MacYTDL without youtube-dl
			on error number -128
				display dialog "You've cancelled installing youtube-dl. If you wish to use MacYTDL, restart and enter your administrator credentials when asked so that youtube-dl can be installed." buttons {"OK"} default button "OK" with title diag_Title with icon note giving up after 600
				quit_MacYTDL()
			end try
			set YTDL_version to do shell script youtubedl_file & " --version"
		end if
	end if
end check_ytdl_installed


---------------------------------------------------
--
-- 		Is youtube-dl up-to-date ?
--
---------------------------------------------------

-- Handler to check and update youtube-dl if user wishes - called by Utilities dialog, the auto check on startup and the Warning dialog
-- Currently commented code uses GitHub releases page instead of the yt-dl.org page
on check_ytdl()
	-- Check version installed - done again because it might have been manually changed while MacYTDL remained open
	tell application "System Events"
		if exists file youtubedl_file then
			tell current application
				set YTDL_version to do shell script youtubedl_file & " --version"
			end tell
		else
			-- ytdl has been deleted since MacYTDL opened - offer to install
			set YTDL_version to "Not installed"
			my check_ytdl_installed()
			return
		end if
	end tell
	-- Trap YTDL internal server error - if error YTDL returns text saying so instead of version number - could work with other kinds of errors
	if length of YTDL_version is greater than 15 then
		display dialog "There was a problem with downloading youtube-dl. There seems to be a problem with the server. Wait a short while and try again." buttons {"OK"} default button "OK" with title diag_Title with icon note giving up after 600
		main_dialog()
	end if
	set alert_text_ytdl to "youtube-dl is up to date.  Your current version is " & YTDL_version
	-- set site to "https://github.com/ytdl-org/youtube-dl/releases"
	set site to "https://yt-dl.org"
	set YTDL_page to do shell script "curl " & site & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
	-- Trap case in which user is offline
	if YTDL_page is "" then
		display dialog "There was a problem with downloading youtube-dl. Perhaps you are not connected to the internet or the server is currently not available. You can run MacYTDL and change settings but downloads will not work until youtube-dl is installed. When you are sure you are connected to the internet, quit and re-open MacYTDL. MacYTDL, again, will then try to install youtube-dl." buttons {"OK"} default button "OK" with title diag_Title with icon note giving up after 600
		main_dialog()
	else
		-- set ytdl_version_start to (offset of "Latest release" in YTDL_page) + 18
		-- set ytdl_version_end to (offset of "Verified" in YTDL_page) - 14
		set ytdl_version_start to (offset of "(" in YTDL_page) + 2
		set ytdl_version_end to (offset of ")" in YTDL_page) - 1
		set YTDL_version_check to text ytdl_version_start thru ytdl_version_end of YTDL_page
		if YTDL_version_check is not equal to YTDL_version then
			set yt_alert_message to "youtube-dl is out of date. You have version " & YTDL_version & ".  The current version is " & YTDL_version_check & return & return & "Would you like to update youtube-dl ?  Note: You may need to provide administrator credentials."
			set yt_install_answ to button returned of (display dialog yt_alert_message buttons {"No", "Yes"} default button "Yes" with title diag_Title with icon note giving up after 600)
			if yt_install_answ is "Yes" then
				-- Trial run of using notifications - might need to pull if users have alert style notifications and keep licking on the wrong thing
				set myScriptAsString to "display notification \"Download and install of youtube-dl started.  Please wait, it will not be long.\" with title \"MacYTDL\""
				do shell script "osascript -e " & quoted form of myScriptAsString & " > /dev/null 2> /dev/null & "
				delay 1
				try
					-- do shell script "curl -L " & site & "/download/" & YTDL_version_check & "/youtube-dl" & " -o /usr/local/bin/youtube-dl" with administrator privileges
					do shell script "curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl" with administrator privileges
					do shell script "chmod a+x /usr/local/bin/youtube-dl" with administrator privileges
					-- trap case where user cancels credentials dialog
				on error number -128
					main_dialog()
				end try
				set YTDL_version to YTDL_version_check
				set alert_text_ytdl to "youtube-dl has been updated.  Your new version is " & YTDL_version
			else
				set alert_text_ytdl to "youtube-dl is out of date.  Your current version is " & YTDL_version
			end if
		end if
	end if
end check_ytdl


---------------------------------------------------
--
-- 		Check for MacYTDL updates
--
---------------------------------------------------

-- Handler that checks for new version of MacYTDL and downloads if user agrees - called by utilities
on check_MacYTDL()
	-- Get version of MacYTDL available from GitHub
	set MacYTDL_site_URL to "https://github.com/section83/MacYTDL/releases/"
	set MacYTDL_releases_page to do shell script "curl " & MacYTDL_site_URL & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
	-- Trap case in which user is offline
	if MacYTDL_releases_page is "" then
		display dialog "There was a problem with checking for MacYTDL updates. Perhaps you are not connected to the internet or GitHub is currently not available." buttons {"OK"} default button "OK" with title diag_Title with icon note giving up after 600
		main_dialog()
	else
		set MacYTDL_version_start to (offset of "Version" in MacYTDL_releases_page) + 8
		set MacYTDL_version_end to (offset of " Ð " in MacYTDL_releases_page) - 1
		set MacYTDL_version_check to text MacYTDL_version_start thru MacYTDL_version_end of MacYTDL_releases_page
		if MacYTDL_version_check is not equal to MacYTDL_version then
			set MacYTDL_update_text to "A new version of MacYTDL is available. You have version " & MacYTDL_version & ". The current version is " & MacYTDL_version_check & return & return & "Would you like to download it now ?"
			tell me to activate
			set MacYTDL_install_answ to button returned of (display dialog MacYTDL_update_text buttons {"No", "Yes"} default button "Yes" with title diag_Title with icon note giving up after 600)
			if MacYTDL_install_answ is "Yes" then
				set MacYTDL_download_file to quoted form of (downloadsFolder_Path & "/MacYTDL-v" & MacYTDL_version_check & ".dmg")
				do shell script "curl -L " & MacYTDL_site_URL & "download/v" & MacYTDL_version_check & "/MacYTDL-v" & MacYTDL_version_check & ".dmg -o " & MacYTDL_download_file
				set alert_text_update_MacYTDL to "A copy of version " & MacYTDL_version_check & " of MacYTDL has been saved into your MacYTDL downloads folder."
				display dialog alert_text_update_MacYTDL with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 600
			end if
		else
			display dialog "Your copy of MacYTDL is up to date.  It is version " & MacYTDL_version with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 600
		end if
	end if
end check_MacYTDL


---------------------------------------------------
--
-- 			Install FFMpeg
--
---------------------------------------------------

-- Handler for installing FFmpeg and FFprobe - called by main thread on startup if either FF file is missing
on check_ffmpeg_installed()
	set ffmpeg_site to "https://evermeet.cx/pub/ffmpeg/"
	set ffprobe_site to "https://evermeet.cx/pub/ffprobe/"
	set FFmpeg_page to do shell script "curl " & ffmpeg_site & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
	-- Trap case in which user is offline
	if FFmpeg_page is "" then
		display dialog "There was a problem with downloading FFmpeg. Perhaps you are not connected to the internet or the server is currently not available. You can run MacYTDL and change settings but downloads will not work until FFmpeg is installed. When you are sure you are connected to the internet, quit and re-open MacYTDL. MacYTDL, again, will then try to install FFmpeg." buttons {"OK"} default button "OK" with title diag_Title with icon note giving up after 600
		main_dialog()
	else
		set ffmpeg_version_start to (offset of "version" in FFmpeg_page) + 8
		set ffmpeg_version_end to (offset of "-tessus" in FFmpeg_page) - 1
		set ffmpeg_version_new to text ffmpeg_version_start thru ffmpeg_version_end of FFmpeg_page
		if ffprobe_version is "Not installed" and ffmpeg_version is "Not installed" then
			set ffmpeg_install_text to "FFmpeg and FFprobe are not installed." & return & return & "Would you like to install them now ?  If not, MacYTDL can't run and you should quit.  Note: Your downloads folder must be available and you may need to provide administrator credentials."
		else if ffmpeg_version is "Not installed" then
			set ffmpeg_install_text to "FFmpeg is not installed." & return & return & "Would you like to install it now ?  If not, MacYTDL can't run and you should quit.  Note: Your downloads folder must be available and you may need to provide administrator credentials."
		else if ffprobe_version is "Not installed" then
			set ffmpeg_install_text to "FFprobe is not installed." & return & return & "Would you like to install it now ?  If not, MacYTDL can't run and you should quit.  Note: Your downloads folder must be available and you may need to provide administrator credentials."
		end if
		tell me to activate
		set ffmpeg_install_query to display dialog ffmpeg_install_text buttons {"Quit", "Yes"} default button "Yes" cancel button "Quit" with title diag_Title with icon note giving up after 600
		set ffmpeg_install_answ to button returned of ffmpeg_install_query
		-- If user wants to install FFmpeg, download the latest Zip file to the Desktop, install then update the ffmpeg_version
		if ffmpeg_install_answ is "Yes" then
			check_download_folder(downloadsFolder_Path)
			if ffmpeg_version is "Not installed" then
				-- Trial run of using notifications - might need to pull if users have alert style notifications and keep licking on the wrong thing
				set myScriptAsString to "display notification \"Download and install of FFmpeg started.  Please wait, it might take a while.\" with title \"MacYTDL\""
				do shell script "osascript -e " & quoted form of myScriptAsString & " > /dev/null 2> /dev/null & "
				delay 1
				set ffmpeg_download_file to quoted form of (downloadsFolder_Path & "/ffmpeg-" & ffmpeg_version_new & ".zip")
				do shell script "curl -L " & ffmpeg_site & "ffmpeg-" & ffmpeg_version_new & ".zip" & " -o " & ffmpeg_download_file
				set copy_to_path to "/usr/local/bin/"
				try
					-- Extract FFmpeg to the usr/local/bin folder
					do shell script "unzip " & ffmpeg_download_file & " -d " & copy_to_path with administrator privileges
					do shell script "chmod a+x /usr/local/bin/ffmpeg" with administrator privileges
					do shell script "rm " & ffmpeg_download_file
					set ffmpeg_version to ffmpeg_version_new
				on error number -128
					-- trap case where user cancels credentials dialog
					do shell script "rm " & ffmpeg_download_file
					main_dialog()
				end try
			end if
			if ffprobe_version is "Not installed" then
				set myScriptAsString to "display notification \"Download and install of FFprobe started.  Please wait, it might take a while.\" with title \"MacYTDL\""
				do shell script "osascript -e " & quoted form of myScriptAsString & " > /dev/null 2> /dev/null & "
				delay 1
				set ffprobe_version_new to ffmpeg_version_new
				set ffprobe_download_file to quoted form of (downloadsFolder_Path & "/ffprobe-" & ffprobe_version_new & ".zip")
				do shell script "curl -L " & ffprobe_site & "ffprobe-" & ffprobe_version_new & ".zip" & " -o " & ffprobe_download_file
				set copy_to_path to "/usr/local/bin/"
				try
					-- Extract FFprobe to the usr/local/bin folder
					do shell script "unzip " & ffprobe_download_file & " -d " & copy_to_path with administrator privileges
					do shell script "chmod a+x /usr/local/bin/ffprobe" with administrator privileges
					do shell script "rm " & ffprobe_download_file
					set ffprobe_version to ffprobe_version_new
				on error number -128
					-- Trap case where user cancels admin credentials dialog
					do shell script "rm " & ffprobe_download_file
					main_dialog()
				end try
			end if
		end if
	end if
end check_ffmpeg_installed


---------------------------------------------------
--
-- 			Is FFMpeg up-to-date ?
--
---------------------------------------------------

-- Handler for updating FFmpeg & FFprobe - called by  "Check updates" in Utilities Dialog - assumes always have same version of both tools
on check_ffmpeg()
	-- Get version of FFmpeg currently installed
	set ffmpeg_version_long to do shell script ffmpeg_file & " -version"
	set ffmpeg_version_start to (offset of "version" in ffmpeg_version_long) + 8
	set ffmpeg_version_end to (offset of "-tessus" in ffmpeg_version_long) - 1
	set ffmpeg_version to text ffmpeg_version_start thru ffmpeg_version_end of ffmpeg_version_long
	set alert_text_ffmpeg to "FFmpeg and FFprobe are up to date.  Your current version is " & ffmpeg_version
	-- Get version of FFmpeg available from web site
	set ffmpeg_site to "https://evermeet.cx/pub/ffmpeg/"
	set ffprobe_site to "https://evermeet.cx/pub/ffprobe/"
	set FFmpeg_page to do shell script "curl " & ffmpeg_site & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
	-- Trap case in which user is offline
	if FFmpeg_page is "" then
		display dialog "There was a problem with accessing FFmpeg.  Perhaps you are not connected to the internet or the server is currently not available.  Try again later." buttons {"OK"} default button "OK" with title diag_Title with icon note giving up after 600
		main_dialog()
	else
		set ffmpeg_version_start to (offset of "version" in FFmpeg_page) + 8
		set ffmpeg_version_end to (offset of "-tessus" in FFmpeg_page) - 1
		set ffmpeg_version_check to text ffmpeg_version_start thru ffmpeg_version_end of FFmpeg_page
		if ffmpeg_version_check is not equal to ffmpeg_version then
			set ffmpeg_install_text to "FFmpeg is out of date. You have version " & ffmpeg_version & ".  The current version is " & ffmpeg_version_check & return & return & "Would you like to update it now ?  If yes, this will also update FFprobe.  Note: Your downloads folder must be available and you may need to provide administrator credentials."
			tell me to activate
			set ffmpeg_install_answ to button returned of (display dialog ffmpeg_install_text buttons {"No", "Yes"} default button "Yes" with title diag_Title with icon note giving up after 600)
			if ffmpeg_install_answ is "Yes" then
				-- Trial run of using notifications - might need to pull if users have alert style notifications and keep clicking on the wrong thing
				set myScriptAsString to "display notification \"Download and install of FFmpeg started.  Please wait, it might take a while.\" with title \"MacYTDL\""
				do shell script "osascript -e " & quoted form of myScriptAsString & " > /dev/null 2> /dev/null & "
				delay 1
				check_download_folder(downloadsFolder_Path)
				set ffmpeg_download_file to quoted form of (downloadsFolder_Path & "/ffmpeg-" & ffmpeg_version_check & ".zip")
				do shell script "curl -L " & ffmpeg_site & "ffmpeg-" & ffmpeg_version_check & ".zip" & " -o " & ffmpeg_download_file
				set copy_to_path to "/usr/local/bin/"
				try
					do shell script "unzip -o " & ffmpeg_download_file & " -d " & copy_to_path with administrator privileges
					do shell script "chmod a+x /usr/local/bin/ffmpeg" with administrator privileges
					do shell script "rm " & ffmpeg_download_file
					set ffprobe_version_new to ffmpeg_version_check
					set ffprobe_download_file to quoted form of (downloadsFolder_Path & "/ffprobe-" & ffprobe_version_new & ".zip")
					-- Trial run of using notifications - might need to pull if users have alert style notifications and keep clicking on the wrong thing
					set myScriptAsString to "display notification \"Download and install of FFprobe started.  Please wait, it might take a while.\" with title \"MacYTDL\""
					do shell script "osascript -e " & quoted form of myScriptAsString & " > /dev/null 2> /dev/null & "
					delay 1
					set ffprobe_download_file to quoted form of (downloadsFolder_Path & "/ffprobe-" & ffprobe_version_new & ".zip")
					do shell script "curl -L " & ffprobe_site & "ffprobe-" & ffprobe_version_new & ".zip" & " -o " & ffprobe_download_file
					set ffprobe_version to ffmpeg_version_check
					do shell script "unzip -o " & ffprobe_download_file & " -d " & copy_to_path with administrator privileges
					do shell script "chmod a+x /usr/local/bin/ffprobe" with administrator privileges
					do shell script "rm " & ffprobe_download_file
				on error number -128
					-- Trap case where user cancels admin credentials dialog
					main_dialog()
				end try
				set ffmpeg_version to ffmpeg_version_check
				set alert_text_ffmpeg to "FFmpeg and FFprobe have been updated.  Your new version is " & ffmpeg_version
			else
				set alert_text_ffmpeg to "FFmpeg is out of date. Your current version is " & ffmpeg_version
			end if
		end if
	end if
end check_ffmpeg


---------------------------------------------------
--
-- 		Get current preference settings
--
---------------------------------------------------

-- Handler for reading the users' preferences file - called by set_settings and main_dialog
on read_settings()
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			set DL_audio_only to value of property list item "Audio_Only"
			set DL_YTDL_auto_check to value of property list item "Auto_Check_YTDL_Update"
			set DL_description to value of property list item "Description"
			set downloadsFolder_Path to value of property list item "DownloadFolder"
			set DL_format to value of property list item "FileFormat"
			set DL_Remux_original to value of property list item "Keep_Remux_Original"
			set DL_over_writes to value of property list item "Over-writes allowed"
			set DL_Remux_format to value of property list item "Remux_Format"
			set DL_subtitles_format to value of property list item "Subtitles_Format"
			set DL_subtitles to value of property list item "SubTitles"
			set DL_STLanguage to value of property list item "Subtitles_Language"
			set DL_STEmbed to value of property list item "SubTitles_Embedded"
			set DL_Thumbnail_Embed to value of property list item "Thumbnail_Embed"
			set DL_Thumbnail_Write to value of property list item "Thumbnail_Write"
			set DL_verbose to value of property list item "Verbose"
			set DL_Show_Settings to value of property list item "Show_Settings_before_Download"
			set DL_Add_Metadata to value of property list item "Add_Metadata"
			set window_Position to value of property list item "final_Position"
		end tell
	end tell
	return downloadsFolder_Path
	return DL_format
	return DL_audio_only
	return DL_YTDL_auto_check
	return DL_subtitles
	return DL_subtitles_format
	return DL_STLanguage
	return DL_STEmbed
	return DL_description
	return DL_over_writes
	return DL_Remux_format
	return DL_Remux_original
	return DL_Thumbnail_Embed
	return DL_Thumbnail_Write
	return DL_verbose
	return DL_Add_Metadata
	return DL_Show_Settings
	return window_Position
end read_settings


---------------------------------------------------
--
-- 		Perform various utilities
--
---------------------------------------------------

-- Handler for MacYTDL utility operations called by the Utilities button on Main dialog
on utilities()
	read_settings()
	
	-- Set Service Status flag - will be shown in the Utilities dialog
	set service_installed to "MacYTDL Service installed:    Yes"
	tell application "Finder"
		if not (the file "Library:Services:Send-URL-To-MacYTDL.workflow" of home exists) then
			set service_installed to "MacYTDL Service installed:    No"
		end if
	end tell
	-- Set Atomic Parsley Status flag - will be shown in the Utilities dialog
	set Atomic_installed to "Atomic Parsley installed:         Yes"
	tell application "System Events"
		set macYTDL_Atomic_file to ("usr:local:bin:AtomicParsley" as text)
		if not (exists file macYTDL_Atomic_file) then
			set Atomic_installed to "Atomic Parsley installed:         No"
		end if
	end tell
	
	-- Set youtube-dl and FFmpeg version installed text - to show in Utilities dialog
	set YTDL_version_installed to "Version installed:        " & YTDL_version
	set FFMpeg_version_installed to "Version installed:                   " & ffmpeg_version
	
	-- Set variables for the Utilities dialog	
	set instructions_text to "Choose the utility(ies) you would like to run then click 'Start'"
	set utilities_diag_prompt to "Utilities"
	set accViewWidth to 600
	set accViewInset to 75
	
	-- Set buttons and controls
	set {theButtons, minWidth} to create buttons {"Delete logs", "Uninstall", "About MacYTDL", "Cancel", "Start"} button keys {"d", "U", "a", "c", ""} default button 5
	if minWidth > accViewWidth then set accViewWidth to minWidth
	set {theUtilitiesRule, theTop} to create rule 10 rule width accViewWidth
	if service_installed is "MacYTDL Service installed:    Yes" then
		set {utilities_theCheckbox_Service_Install, theTop} to create checkbox "Remove Service" left inset accViewInset bottom (theTop + 5) max width 250
	else
		set {utilities_theCheckbox_Service_Install, theTop} to create checkbox "Install Service" left inset accViewInset bottom (theTop + 5) max width 250
	end if
	if Atomic_installed is "Atomic Parsley installed:         Yes" then
		set {utilities_theCheckbox_Atomic_Install, theTop} to create checkbox "Remove Atomic Parsley" left inset accViewInset bottom (theTop + 5) max width 250
	else
		set {utilities_theCheckbox_Atomic_Install, theTop} to create checkbox "Install Atomic Parsley" left inset accViewInset bottom (theTop + 5) max width 250
	end if
	set {utilities_theCheckbox_FFmpeg_Check, theTop} to create checkbox "Check for FFmpeg update" left inset accViewInset bottom (theTop + 5) max width 250
	set {utilities_theCheckbox_MacYTDL_Check, theTop} to create checkbox "Check for MacYTDL update" left inset accViewInset bottom (theTop + 5) max width 200
	set {utilities_theCheckbox_YTDL_release, theTop} to create checkbox "Open youtube-dl web page" left inset accViewInset bottom (theTop + 5) max width 200
	set {utilities_theCheckbox_YTDL_Check, theTop} to create checkbox "Check for youtube-dl update" left inset accViewInset bottom (theTop + 5) max width 250
	set {utilities_theCheckbox_DL_Open, theTop} to create checkbox "Open download folder" left inset accViewInset bottom (theTop + 5) max width 250
	set {utilities_theCheckbox_Logs_Open, theTop} to create checkbox "Open log folder" left inset accViewInset bottom (theTop + 5) max width 250
	
	set {utilities_service_status, theTop} to create label service_installed left inset 285 bottom (theTop - 178) max width 225 aligns left
	set {utilities_atomic_status, theTop} to create label Atomic_installed left inset 285 bottom (theTop + 6) max width 225 aligns left
	set {utilities_FFmpeg_version, theTop} to create label FFMpeg_version_installed left inset 285 bottom (theTop + 6) max width 225 aligns left
	set {utilities_YTDL_version, theTop} to create label YTDL_version_installed left inset 285 bottom (theTop + 52) max width 225 aligns left
	
	
	set {utilities_instruct, theTop} to create label instructions_text left inset accViewInset + 5 bottom (theTop + 60) max width minWidth - 100 aligns left with multiline
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 50 view width 64 view height 64 scale image scale proportionally
	set {utilities_prompt, theTop} to create label utilities_diag_prompt left inset 0 bottom (theTop) max width minWidth aligns center aligned with bold type
	set utilities_allControls to {theUtilitiesRule, utilities_theCheckbox_Atomic_Install, utilities_theCheckbox_Service_Install, utilities_theCheckbox_FFmpeg_Check, utilities_theCheckbox_MacYTDL_Check, utilities_theCheckbox_YTDL_release, utilities_theCheckbox_YTDL_Check, utilities_theCheckbox_DL_Open, utilities_theCheckbox_Logs_Open, utilities_FFmpeg_version, utilities_YTDL_version, utilities_service_status, utilities_atomic_status, MacYTDL_icon, utilities_instruct, utilities_prompt}
	
	-- Make sure MacYTDL is in front and show dialog
	tell me to activate
	set {utilities_button_returned, utilities_controls_results} to display enhanced window diag_Title buttons theButtons acc view width minWidth acc view height theTop acc view controls utilities_allControls
	
	if utilities_button_returned is "Start" then
		-- Get control results from utilities dialog - numbered choice variables are not used but help ensure correct utilities are run
		-- set utilities_choice_1 to item 1 of utilities_controls_results -- <= Missing value [the rule]
		set utilities_Atomic_choice to item 2 of utilities_controls_results -- <= Install Atomic Parsley choice
		set utilities_Service_choice to item 3 of utilities_controls_results -- <= Install Service choice
		set utilities_FFmpeg_check_choice to item 4 of utilities_controls_results -- <= Check FFmpeg version choice
		set utilities_MacYTDL_check_choice to item 5 of utilities_controls_results -- <= Check MacYTDL version choice
		set utilities_YTDL_release_choice to item 6 of utilities_controls_results -- <= Show YTDL release info page choice
		set utilities_YTDL_check_choice to item 7 of utilities_controls_results -- <= Check YTDL version choice
		set utilities_DL_folder_choice to item 8 of utilities_controls_results -- <= Open download folder choice
		set utilities_log_folder_choice to item 9 of utilities_controls_results -- <= Open log folder choice
		--set utilities_Atomic_status_choice_10 to item 10 of utilities_controls_results -- <= Atomic status indicator
		--set utilities_service_status_choice_11 to item 11 of utilities_controls_results -- <= Service status indicator
		--set utilities_choice_12 to item 12 of utilities_controls_results -- <= Missing value [the icon]
		--set utilities_choice_13 to item 13 of utilities_controls_results -- <= Contains the "Instructions" text
		
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
				set the position of the front Finder window to {100, 100} -- <= This DOES work but is ugly - it opens the window then moves it to a location which doesn't overlap Main Dialog
			end tell
		end if
		
		-- Open youtube-dl release page (in default web browser)
		if utilities_YTDL_release_choice is true then
			open location "https://github.com/rg3/youtube-dl/releases"
		end if
		
		-- Need to show the version checked dialog before returning to Main dialog
		-- Do selected combination of version checks - Provide for each possible combination of check boxes
		if utilities_YTDL_check_choice is true and utilities_FFmpeg_check_choice is true then
			check_ytdl()
			check_ffmpeg()
			tell me to activate
			display dialog alert_text_ytdl & return & alert_text_ffmpeg with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 600
		else if utilities_FFmpeg_check_choice is true and utilities_YTDL_check_choice is false then
			check_ffmpeg()
			tell me to activate
			display dialog alert_text_ffmpeg & return & return with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 600
		else if utilities_YTDL_check_choice is true and utilities_FFmpeg_check_choice is false then
			check_ytdl()
			tell me to activate
			display dialog alert_text_ytdl & return with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 600
		end if
		
		-- Check for MacYTDL update
		if utilities_MacYTDL_check_choice is true then
			check_MacYTDL()
		end if
		
		-- Install Atomic Parsely
		if utilities_Atomic_choice is true then
			if Atomic_installed contains "No" then
				-- Atomic is not installed - go ahead and install it
				my install_MacYTDLatomic()
				tell me to activate
			end if
		end if
		-- Remove Atomic Parsely
		if utilities_Atomic_choice is true then
			if Atomic_installed contains "Yes" then
				-- Atomic is installed - user wants to remove it
				my remove_MacYTDLatomic()
				tell me to activate
			end if
		end if
		
		-- Install Service
		if utilities_Service_choice is true then
			if service_installed contains "No" then
				-- Service is not installed - user wants to install it
				my install_MacYTDLservice()
				tell me to activate
				display dialog "The MacYTDL Service is installed." with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 100
			end if
		end if
		-- Remove is installed
		if utilities_Service_choice is true then
			if service_installed contains "Yes" then
				-- Service is installed - user wants to remove it
				my remove_MacYTDLservice()
				tell me to activate
				display dialog "The MacYTDL Service has been removed." with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 100
			end if
		end if
		
		-- Move all log files to Trash then display a job done dialog
	else if utilities_button_returned is "Delete logs" then
		do shell script "mv " & POSIX path of MacYTDL_preferences_path & "youtube-dl_response-*" & " ~/.trash/"
		display dialog "All MacYTDL log files are now in the Trash." with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 100
		
		-- Uninstall all MacYTDL files - move files to Trash
	else if utilities_button_returned is "Uninstall" then
		set really_remove_MacYTDL to display dialog "Do you really want to remove MacYTDL ?  Everything will be moved to the Trash." buttons {"Yes", "No"} with title diag_Title default button "No" with icon note giving up after 600
		set remove_answ to button returned of really_remove_MacYTDL
		if remove_answ is "No" then
			main_dialog()
		end if
		-- If it exists, move AtomicParsley to Trash
		if Atomic_is_installed is true then
			do shell script "mv /usr/local/bin/AtomicParsley" & " ~/.trash/AtomicParsley" with administrator privileges
		end if
		-- If it exists, move the MacYTDL Service to Trash
		set services_Folder to (POSIX path of (path to home folder) & "Library/Services/")
		set macYTDL_service_file to services_Folder & "Send-URL-To-MacYTDL.workflow"
		tell application "System Events"
			if (the file macYTDL_service_file exists) then
				tell current application to do shell script "mv " & quoted form of (macYTDL_service_file) & " ~/.trash/Send-URL-To-MacYTDL.workflow"
			end if
		end tell
		-- All other components are certain to exist
		try
			do shell script "mv " & POSIX path of youtubedl_file & " ~/.trash/youtube-dl" with administrator privileges
			do shell script "mv " & POSIX path of ffprobe_file & " ~/.trash/ffprobe" with administrator privileges
			do shell script "mv " & POSIX path of ffmpeg_file & " ~/.trash/ffmpeg" with administrator privileges
			do shell script "mv " & POSIX path of MacYTDL_preferences_path & " ~/.trash/MacYTDL"
			do shell script "mv " & quoted form of (POSIX path of DTP_file) & " ~/.trash/DialogToolkitMacYTDL.scptd" -- Quoted form because of space in "Script Libraries" folder name
			set path_to_macytdl_file to quoted form of (POSIX path of (path to me as text))
			do shell script "mv " & path_to_macytdl_file & " ~/.trash/MacYTDL.app" with administrator privileges
			-- trap case where user cancels credentials dialog
		on error number -128
			main_dialog()
		end try
		display dialog "MacYTDL is uninstalled.  All components are in the Trash which you can empty when you wish.  Cheers." buttons {"Goodbye"} default button "Goodbye" with icon note giving up after 600
		error number -128
		
		-- Show the About MacYTDL dialog
	else if utilities_button_returned is "About MacYTDL" then
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
	set about_text_1 to "MacYTDL is a simple AppleScript program for downloading videos from various web sites.  It uses the youtube-dl Python script as the download engine."
	set about_text_2 to "Please post any questions or suggestions to github.com/section83/MacYTDL/issues" & return & return & "Written by © Vincentius, " & MacYTDL_date & ".  With thanks to Shane Stanley, Adam Albrec, kopurando and Michael Page."
	set about_diag_prompt to "About MacYTDL"
	set accViewWidth to 400
	set accViewInset to 0
	
	-- Set buttons and controls
	set {theButtons, minWidth} to create buttons {"Visit Site", "Send E-Mail", "OK"} button keys {"v", "e", ""} default button 3
	if minWidth > accViewWidth then set accViewWidth to minWidth
	set {about_Rule, theTop} to create rule 10 rule width accViewWidth
	set {about_instruct_2, theTop} to create label about_text_2 left inset 5 bottom (theTop + 10) max width minWidth aligns left with multiline
	set {about_instruct_1, theTop} to create label about_text_1 left inset 75 bottom (theTop + 10) max width minWidth - 75 aligns left with multiline
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 60 view width 64 view height 64 scale image scale proportionally
	set {about_prompt, theTop} to create label about_diag_prompt left inset 0 bottom (theTop) max width minWidth aligns center aligned with bold type
	set about_allControls to {about_Rule, MacYTDL_icon, about_instruct_1, about_instruct_2, about_prompt}
	
	-- Make sure MacYTDL is in front and show dialog
	tell me to activate
	set {about_button_returned, about_controls_results} to display enhanced window diag_Title buttons theButtons acc view width minWidth acc view height theTop acc view controls about_allControls
	if about_button_returned is "OK" then
		main_dialog()
	end if
	
	-- Open MacYTDL release page (in default web browser) to manually check version
	if about_button_returned is "Visit Site" then
		open location "https://github.com/section83/MacYTDL/"
	end if
	
	-- Open email message to author
	if about_button_returned is "Send E-Mail" then
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
	set instructions_text to "Enter your user name and password in the boxes below for the next download, skip credentials and continue to download or return to the Main dialog."
	set credentials_diag_prompt to "Credentials for next download"
	set accViewWidth to 275
	set accViewInset to 0
	
	-- Set buttons and controls
	set {theButtons, minWidth} to create buttons {"Return", "Skip", "OK"} button keys {"r", "s", ""} default button 3
	set {theField_password, theTop} to create field "" placeholder text "Password" left inset accViewInset bottom 5 field width accViewWidth
	set {theField_username, theTop} to create field "" placeholder text "User name" left inset accViewInset bottom (theTop + 20) field width accViewWidth
	set {utilities_instruct, theTop} to create label instructions_text left inset 75 bottom (theTop + 15) max width (accViewWidth - 75) aligns left with multiline
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 60 view width 64 view height 64 scale image scale proportionally
	set {utilities_prompt, theTop} to create label credentials_diag_prompt left inset 0 bottom (theTop + 10) max width accViewWidth aligns center aligned with bold type
	set credentials_allControls to {theField_username, theField_password, MacYTDL_icon, utilities_instruct, utilities_prompt}
	
	-- Make sure MacYTDL is in front and show dialog
	tell me to activate
	set {credentials_button_returned, credentials_results} to display enhanced window diag_Title buttons theButtons acc view width accViewWidth acc view height theTop acc view controls credentials_allControls
	
	if credentials_button_returned is "OK" then
		-- Get control results from credentials dialog
		set theField_username_choice to item 1 of credentials_results -- <= User name
		set theField_password_choice to item 2 of credentials_results -- <= Password
		set YTDL_credentials to "--username " & theField_username_choice & " --password " & theField_password_choice & " "
		return YTDL_credentials
	else if credentials_button_returned is "Skip" then
		-- Continue download without credentials
		set YTDL_credentials to ""
		return YTDL_credentials
	else
		main_dialog()
	end if
end get_YTDL_credentials


----------------------------------------------------------------------------------------------------------
--
-- 	Handlers to update format of Preferences file for v1.2, v1.4, v1.5, v1.10, 1.11 and 1.12.1
--
----------------------------------------------------------------------------------------------------------

-- Handler to add new v1.2 items to preferences file
on add_v1_2_preferences()
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:boolean, name:"SubTitles_Embedded", value:false}
			make new property list item at end with properties {kind:string, name:"FileFormat", value:"Default"}
		end tell
	end tell
end add_v1_2_preferences

-- Handler to add new v1.4 items to preferences file and to delete the "Resolution" item which is not needed
on add_v1_4_preferences()
	-- First, set about reading in the preferences file, deleting the two lines relating to the Resolution settings and writing it out
	set MacYTDL_prefs_file to MacYTDL_prefs_file as string
	set source_text to read POSIX file MacYTDL_prefs_file
	set deletePhrase to "Resolution"
	deleteLinesFromText(source_text, deletePhrase)
	set plist_file to open for access POSIX file MacYTDL_prefs_file with write permission
	set eof of plist_file to 0
	write newText to plist_file starting at eof
	close access plist_file
	-- Second, add the new items
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:boolean, name:"Audio_Only", value:false}
			make new property list item at end with properties {kind:string, name:"Remux_Format", value:"No remux"}
			make new property list item at end with properties {kind:boolean, name:"Auto_Check_YTDL_Update", value:false}
			make new property list item at end with properties {kind:boolean, name:"Keep_Remux_Original", value:false}
		end tell
	end tell
end add_v1_4_preferences

-- Handler to add v1.5 items to preferences file - subtitle format, metadata thumbnail download and embedding
on add_v1_5_preferences()
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:boolean, name:"Thumbnail_Write", value:false}
			make new property list item at end with properties {kind:boolean, name:"Thumbnail_Embed", value:false}
			make new property list item at end with properties {kind:string, name:"Subtitles_Format", value:"best"}
			make new property list item at end with properties {kind:boolean, name:"Add_Metadata", value:false}
		end tell
	end tell
	ask_user_install_Atomic()
end add_v1_5_preferences

on add_v1_10_preference()
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:boolean, name:"Show_Settings_before_Download", value:true}
		end tell
	end tell
end add_v1_10_preference

on add_v1_11_preference()
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:list, name:"final_Position", value:{X_position, Y_position}}
		end tell
	end tell
end add_v1_11_preference

on add_v1_12_1_preference()
	tell application "System Events"
		tell property list file MacYTDL_prefs_file
			make new property list item at end with properties {kind:string, name:"Subtitles_Language", value:"en"}
		end tell
	end tell
end add_v1_12_1_preference


-----------------------------------------------------------------------------------------
--
-- 	 Remove "Resolution" setting from prefs file - called by add_v1_4_preferences
--
-----------------------------------------------------------------------------------------

-- Handler to delete lines from text read in from Preferences file - this seems the only way to remove redundant "Resolution" preference from the file
on deleteLinesFromText(theText, deletePhrase)
	-- Turn the text into a list so you can repeat over each line of text
	set textList to paragraphs of theText
	-- Repeat over the list and replace lines that have the deletePhrase with 'missing values'.
	repeat with i from 1 to (count textList)
		if (item i of textList contains deletePhrase) then
			set item i of textList to missing value
			set item (i + 1) of textList to missing value
		end if
	end repeat
	-- Coerce the paragraphs which are left to a single text using return delimiters.
	set astid to AppleScript's text item delimiters
	set AppleScript's text item delimiters to return
	set newText to textList's text as text
	set AppleScript's text item delimiters to astid
	return newText
end deleteLinesFromText


---------------------------------------------------------
--
-- 	 Create preference settings file with defaults
--
---------------------------------------------------------

-- Handler for creating preferences file and setting default preferences - called by Main if prefs don't exist or are faulty
on set_preferences()
	if old_version_prefs is "Yes" then
		-- Prefs file is old or faulty - warn user it must be replaced for MacYTDL to work
		set Install_MacYTDL_text to "The MacYTDL Preferences file needs to be replaced.  To work, MacYTDL needs the latest version of the Preferences file.  Do you wish to continue ?"
		set Install_diag_buttons to {"No", "Yes"}
		set Install_diag_default_button to "Yes"
		set Install_diag_cancel_button to "No"
		tell me to activate
		set ask_update to display dialog Install_MacYTDL_text buttons Install_diag_buttons default button Install_diag_default_button cancel button Install_diag_cancel_button with title diag_Title with icon note giving up after 600
		set Install_MacYTDL to button returned of ask_update
		if Install_MacYTDL is "No" then
			error number -128
		end if
		set downloadsFolder to "Desktop/"
		set downloadsFolder_Path to (POSIX path of (path to home folder) & downloadsFolder)
		tell application "Finder"
			delete MacYTDL_prefs_file as POSIX file
		end tell
	else
		-- Prefs file doesn't exist - warn user it must be created for MacYTDL to work
		set Install_MacYTDL_text to "The MacYTDL Preferences file is not present.  To work, MacYTDL needs to create a file in your Preferences folder.  Do you wish to continue ?"
		set Install_diag_buttons to {"No", "Yes"}
		set Install_diag_default_button to "Yes"
		set Install_diag_cancel_button to "No"
		set Install_diag_title to "MacYTDL, version " & MacYTDL_version & ", " & MacYTDL_date
		set Install_MacYTDL to display dialog Install_MacYTDL_text buttons Install_diag_buttons default button Install_diag_default_button cancel button Install_diag_cancel_button with title Install_diag_title with icon note giving up after 600
		if Install_MacYTDL is "No" then
			error number -128
		end if
		-- Set path to default downloads folder and create it
		set downloadsFolder to "Desktop/"
		set downloadsFolder_Path to (POSIX path of (path to home folder) & downloadsFolder)
		tell application "System Events"
			if not (exists folder MacYTDL_preferences_path) then
				tell current application to do shell script "mkdir " & MacYTDL_preferences_path
			end if
		end tell
	end if
	-- Create new Preferences file and set the default preferences
	tell application "System Events"
		set thePropertyListFile to make new property list file with properties {name:MacYTDL_prefs_file}
		tell property list items of thePropertyListFile
			make new property list item at end with properties {kind:string, name:"DownloadFolder", value:downloadsFolder_Path} -- <= Path has no trailing slash
			make new property list item at end with properties {kind:string, name:"FileFormat", value:"Default"}
			make new property list item at end with properties {kind:boolean, name:"Audio_Only", value:false}
			make new property list item at end with properties {kind:boolean, name:"Auto_Check_YTDL_Update", value:false}
			make new property list item at end with properties {kind:boolean, name:"SubTitles", value:false}
			make new property list item at end with properties {kind:boolean, name:"SubTitles_Embedded", value:false}
			make new property list item at end with properties {kind:string, name:"Subtitles_Format", value:"best"}
			make new property list item at end with properties {kind:boolean, name:"Description", value:false}
			make new property list item at end with properties {kind:boolean, name:"Over-writes allowed", value:false}
			make new property list item at end with properties {kind:string, name:"Remux_Format", value:"No remux"}
			make new property list item at end with properties {kind:boolean, name:"Keep_Remux_Original", value:false}
			make new property list item at end with properties {kind:boolean, name:"Thumbnail_Write", value:false}
			make new property list item at end with properties {kind:boolean, name:"Thumbnail_Embed", value:false}
			make new property list item at end with properties {kind:boolean, name:"Add_Metadata", value:false}
			make new property list item at end with properties {kind:boolean, name:"Verbose", value:false}
			make new property list item at end with properties {kind:boolean, name:"Show_Settings_before_Download", value:false}
			make new property list item at end with properties {kind:list, name:"final_Position", value:{X_position, Y_position}}
			make new property list item at end with properties {kind:string, name:"Subtitles_Language", value:"en"}
		end tell
	end tell
end set_preferences


---------------------------------------------------
--
-- 		Install Dialog Toolkit
--
---------------------------------------------------

-- Handler to install Shane Stanley's Dialog Toolkit Plus in user's Library - as altered for MacYTDL
-- Needed as Monitor dialog (running from osascript) cannot see locations inside this app
on install_DTP()
	set libraries_folder to quoted form of (POSIX path of (path to home folder) & "Library/Script Libraries/")
	tell application "System Events"
		if not (the folder libraries_folder exists) then
			tell current application to do shell script "mkdir -p " & libraries_folder
		end if
	end tell
	set DTP_library_MacYTDL to quoted form of ((POSIX path of (path to me)) & "Contents/Resources/Script Libraries/DialogToolkitMacYTDL.scptd")
	do shell script "cp -R " & DTP_library_MacYTDL & " " & libraries_folder
	-- If old DTP library is present, delete it
	set libraries_folder_nonposix to text 3 thru -2 of (POSIX path of libraries_folder)
	set DTP_old_file to libraries_folder_nonposix & "DialogToolkitPlus.scptd"
	tell application "System Events"
		if file DTP_old_file exists then
			delete file DTP_old_file
		end if
	end tell
end install_DTP


---------------------------------------------------
--
-- 		Invite user to install Service
--
---------------------------------------------------

-- Ask user if they would like the MacYTDL service installed. If so, copy from Resource folder to user's Services folder - only ask once
on ask_user_install_service()
	tell me to activate
	set services_Folder to (POSIX path of (path to home folder) & "/Library/Services/")
	set macYTDL_service_file to services_Folder & "Send-URL-To-MacYTDL.workflow"
	tell application "System Events"
		if not (exists file macYTDL_service_file) then
			set Install_service_text to "The MacYTDL Service is not installed.  It's not critical but enables calling MacYTDL from within the web browser and you can also assign a keystroke shortcut to copy a video URL and run MacYTDL.  However, after the Service is installed, you will need to grant Assistive Access to another part of MacYTDL.  There are instructions in the Help file." & return & return & "Would you like the Service installed ?  You can install the Service later on if you prefer."
			set Install_service_buttons to {"No thanks", "Yes"}
			set Install_service_default_button to "Yes"
			set Install_MacYTDL_service to button returned of (display dialog Install_service_text buttons Install_service_buttons default button Install_service_default_button with title diag_Title with icon MacYTDL_custom_icon_file giving up after 600)
			if Install_MacYTDL_service is "Yes" then
				my install_MacYTDLservice()
			end if
		end if
	end tell
end ask_user_install_service


---------------------------------------------------
--
-- 			Install Service
--
---------------------------------------------------

-- Handler for installing the Service and updating Service menu - separated out to avoid conflict with System Events - also called by Utilities dialog
on install_MacYTDLservice()
	set services_Folder to (POSIX path of (path to home folder) & "Library/Services")
	tell application "System Events"
		if not (the folder services_Folder exists) then
			tell current application to do shell script "mkdir -p " & services_Folder
		end if
	end tell
	set getURL_service to quoted form of (POSIX path of (path to me)) & "Contents/Resources/Send-URL-To-MacYTDL.workflow"
	--	do shell script "cp -R " & getURL_service & " " & services_Folder & ";sleep 1; /System/Library/CoreServices/pbs -update"  -- The pbs -update didn't work
	do shell script "cp -R " & getURL_service & " " & services_Folder & ";sleep 1;killall pbs;/System/Library/CoreServices/pbs -flush"
end install_MacYTDLservice



------------------------------------------------------------------------------------------------------------------
--
-- 	Check version of MacYTDL Service - update if old version - called when starting MacYTDL
--
------------------------------------------------------------------------------------------------------------------

-- Handler to check whether Serivce is installed and if so, which version - if old version, update to new
on update_MacYTDLservice()
	set Service_exists_flag to "No"
	set services_Folder to (POSIX path of (path to home folder) & "Library/Services/")
	set old_service_file to (services_Folder & "Send-URL-To-MacYTDL.workflow")
	tell application "System Events"
		if exists file old_service_file then
			set Service_exists_flag to "Yes"
		end if
	end tell
	if Service_exists_flag is "Yes" then
		set getURL_service_temp to ((path to me) & "Contents:Resources:Send-URL-To-MacYTDL.workflow") as string
		set getURL_service to getURL_service_temp as alias
		tell application "System Events"
			set old_service_size to the size of getURL_service
			set new_service_size to the size of alias old_service_file
		end tell
		if old_service_size is not equal to new_service_size then
			do shell script "rm -R " & quoted form of (old_service_file)
			do shell script "cp -R " & POSIX path of (getURL_service) & " " & old_service_file & ";sleep 1;killall pbs;/System/Library/CoreServices/pbs -flush"
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
			tell current application to do shell script "rm -R " & quoted form of (macYTDL_service_file)
		end if
	end tell
end remove_MacYTDLservice


---------------------------------------------------
--
-- 	Invite user to install AtomicParsley
--
---------------------------------------------------

-- If AtomicParsley is not installed, ask user if they want it.  If so, go to install_MacYTDLatomic handler Ð this is called if there is no preferences file
on ask_user_install_Atomic()
	tell me to activate
	tell application "System Events"
		set macYTDL_Atomic_file to usr_bin_folder & "AtomicParsley"
		if not (exists file macYTDL_Atomic_file) then
			set Install_Atomic_text to "Atomic Parsley is not installed.  It's not critical but enables thumbnail images provided by web sites to be embedded in downloaded files." & return & return & "Would you like Atomic Parsley installed ?  You can install it later on if you prefer.  Note: You may need to provide administrator credentials."
			set Install_MacYTDL_Atomic to button returned of (display dialog Install_Atomic_text buttons {"No thanks", "Yes"} default button "Yes" with title diag_Title with icon MacYTDL_custom_icon_file giving up after 600)
			if Install_MacYTDL_Atomic is "Yes" then
				my install_MacYTDLatomic()
			end if
		end if
	end tell
end ask_user_install_Atomic

---------------------------------------------------
--
-- 	Install Atomic Parsley
--
---------------------------------------------------

-- Handler for installing Atomic Parsley and updating Service menu - copy from Resource folder to /user/local/bin - separated out to avoid conflict with System Events - also called by Utilities dialog
on install_MacYTDLatomic()
	set getAtomic to quoted form of (POSIX path of (path to me)) & "Contents/Resources/AtomicParsley"
	try
		do shell script "cp -R " & getAtomic & " " & usr_bin_folder with administrator privileges
		set Atomic_is_installed to true
		tell me to activate
		display dialog "Atomic Parsley is installed.  When available, thumbnail images can now be embedded in your downloads.  Go to Settings to turn on that feature." with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 100
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

on remove_MacYTDLatomic()
	set getAtomic to quoted form of (POSIX path of (path to me)) & "Contents/Resources/AtomicParsley"
	try
		do shell script "mv /usr/local/bin/AtomicParsley" & " ~/.trash/AtomicParsley" with administrator privileges
		set Atomic_is_installed to false
		display dialog "Atomic Parsley has been removed." with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 100
		-- trap case where user cancels credentials dialog
	on error number -128
		return
	end try
end remove_MacYTDLatomic


--------------------------------------------------------
--
-- 	Parse ABC iView web page to get episodes
--
--------------------------------------------------------

-- Handler to parse ABC iView "Show" pages to get and show a list of episodes - ask user which episodes to download
on Get_ABC_Episodes(URL_user_entered)
	-- Get the entire web page from user's chosen URL
	set ABC_show_page to do shell script "curl " & URL_user_entered
	if ABC_show_page is "" then
		display dialog "There was a problem with the iView URLs.  It looks like you tried to download from two or more separate show pages at the same time.  MacYTDL can't do that at present.  Try just one show page URL at a time.  There is more info in Help." with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 100
		main_dialog()
	end if
	-- Get name of the show - using web page to ensure what is shown is same as what user sees
	set start_show_name to (offset of "\\\"title\\\":\\\"" in ABC_show_page) + 12
	set end_show_name to (offset of "\\\",\\\"displayTitle\\\":\\\"" in ABC_show_page) - 1
	set show_name to text start_show_name thru end_show_name of ABC_show_page
	-- Get name of the show for use in accessing API web page
	set start_show_name_api to (offset of "canonicalUrl\":\"https://iview.abc.net.au/show/" in ABC_show_page) + 45
	set end_show_name_api to (offset of "\",\"contentType\"" in ABC_show_page) - 1
	set show_name_api to text start_show_name_api thru end_show_name_api of ABC_show_page
	-- Get the list of episodes from iView API and count number of episodes
	set iView_API_URL to "https://iview.abc.net.au/api/series/"
	set ABC_episodes_list to do shell script "curl " & iView_API_URL & show_name_api
	
	-- Are there any "Extras" videos ? If so, get text of extras API page and merge with episodes API page
	-- NB Does not find extras which are stored under a different show name - which happened with "Employable Me" and "Back Roads"
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
		return
	else
		-- Populate the lists of names and URLs - Repeat for each occurrence of an episode found in the API call results
		repeat with i from 1 to myNum
			set item (i) of occurrences to text item (i + 1) of ABC_episodes_list --<= Get text of each occurrence - current delimiter is "\"title\":\""
			set AppleScript's text item delimiters to "\",\"href"
			set item (i) of name_list to text 1 through end of text item 1 of item (i) of occurrences --<= Get each episode name
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
		-- set reverse_name_list to name_list
		set reverse_name_list to reverse of name_list
		
		-- Set variables for the ABC episode choice dialog	
		set instructions_text to "Select which episodes of \"" & show_name & "\" that you wish to download then click on Download or press Return. You can select any combination."
		set diag_prompt to "MacYTDL Ð Choose ABC Shows"
		set accViewWidth to 375
		set accViewInset to 0
		
		-- Set buttons and controls - need to loop through episodes
		set {theButtons, minWidth} to create buttons {"Cancel", "Download"} button keys {"c", "d"} default button 2
		if minWidth > accViewWidth then set accViewWidth to minWidth
		set {theEpisodesRule, theTop} to create rule 10 rule width accViewWidth
		set ABC_Checkboxes to {}
		if minWidth > accViewWidth then set accViewWidth to minWidth
		-- Add space between the rule and the first checkbox
		set theTop to theTop + 15
		set first_box to theTop
		set set_Width to 0
		set number_cols to 1
		
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
			if set_Width is less than theWidth then
				set set_Width to theWidth
			end if
			set end of ABC_Checkboxes to aCheckbox
			-- Increment window width and reset vertical and horizontal position of further checkboxes
			if theTop is greater than screen_height * 0.5 then
				set number_cols to number_cols + 1
				set at_Top to theTop
				set theTop to first_box
				set accViewInset to accViewInset + set_Width
				set accViewWidth to set_Width * number_cols
				set set_Width to 0
			end if
		end repeat
		if number_cols = 1 then
			set at_Top to theTop
		end if
		
		set {ABC_all_episodes_theCheckbox, theTop} to create checkbox "All episodes" left inset 0 bottom (at_Top + 15) max width 270
		set icon_top to theTop
		set {boxes_instruct, theTop} to create label instructions_text left inset 75 bottom (theTop + 20) max width accViewWidth - 75 aligns left with multiline
		set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom icon_top + 20 view width 64 view height 64 scale image scale proportionally
		set {boxes_prompt, theTop} to create label diag_prompt left inset 0 bottom (theTop + 10) max width accViewWidth aligns center aligned with bold type
		set ABC_allControls to {theEpisodesRule, boxes_instruct, boxes_prompt, MacYTDL_icon, ABC_all_episodes_theCheckbox} & ABC_Checkboxes
		-- Make sure MacYTDL is in front and show dialog
		tell me to activate
		set {ABC_button_returned, ABC_controls_results} to display enhanced window diag_Title buttons theButtons acc view width accViewWidth acc view height theTop acc view controls ABC_allControls
		
		if ABC_button_returned is "Download" then
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
			if text 1 of ABC_show_URLs is " " then
				set ABC_show_URLs to text 2 thru end of ABC_show_URLs
			end if
			if ABC_show_URLs is "" then
				set ABC_cancel_DL to button returned of (display dialog "You didn't select any ABC shows. Do you wish to download an ABC show or just return to Main dialog ?" with title diag_Title buttons {"Return", "Download"} default button {"Download"} with icon note giving up after 600)
				if ABC_cancel_DL is "Return" then
					main_dialog()
				else
					Get_ABC_Episodes(URL_user_entered)
				end if
			end if
		else
			main_dialog()
		end if
	end if
end Get_ABC_Episodes


---------------------------------------------------
--
-- 	Write current URL(s) to batch file
--
---------------------------------------------------

-- Handler to write the user's selected URL tp the batch file for later download
-- Creates file if need, adds URL and a return each time
on add_To_Batch(URL_user_entered_lines, number_of_URLs)
	-- Remove quotes from around URL_user_entered
	set URL_user_entered_lines to text 2 thru -2 of URL_user_entered
	-- Change spaces to returns when URL_user_entered has more than one URL
	if myNum is greater than 1 or number_of_URLs is greater than 1 then
		set URL_user_entered_lines to text 2 thru end of (replace_chars(URL_user_entered_lines, " ", return))
	end if
	set batch_filepathname to "BatchFile.txt" as string
	set batch_file to POSIX file (MacYTDL_preferences_path & batch_filepathname) as Çclass furlÈ
	try
		set batch_refNum to missing value
		set batch_refNum to open for access batch_file with write permission
		write URL_user_entered_lines & return to batch_refNum starting at eof
		close access batch_refNum
	on error batch_errMsg
		display dialog "There was an error: " & batch_errMsg
		close access batch_refNum
		main_dialog()
	end try
	display dialog "The URL has been added to batch file." with title diag_Title buttons {"OK"} default button {"OK"} with icon note giving up after 600
	main_dialog()
end add_To_Batch


---------------------------------------------------------
--
-- 	Open batch processing dialog - called by Main
--
---------------------------------------------------------
-- Handler to open batch file processing dialog - called by Main dialog
on open_batch_processing(folder_chosen, remux_format_choice, YTDL_subtitles, YTDL_STEmbed, YTDL_credentials, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
	
	-- Start by calculating tally of URLs currently saved in the batch file
	set batch_tally_number to tally_batch()
	
	-- Set variables for the Batch functions dialog	
	set instructions_text to "Choose to download list of URLs in batch file, clear the batch list, edit the batch list, remove last addition to the batch or return to Main dialog."
	set batch_diag_prompt to "MacYTDL Batch Functions"
	set accViewWidth to 500
	set accViewInset to 0
	
	-- Set buttons and controls
	set {theButtons, minWidth} to create buttons {"Return", "Edit", "Clear", "Remove last item", "Download"} button keys {"r", "e", "c", "U", "d"} default button 5
	if minWidth > accViewWidth then set accViewWidth to minWidth
	set {theBatchRule, theTop} to create rule 10 rule width accViewWidth
	set {batch_tally, theTop} to create label "Number of videos in batch: " & batch_tally_number left inset 25 bottom (theTop + 15) max width 225 aligns left
	set {batch_instruct, theTop} to create label instructions_text left inset 75 bottom (theTop + 30) max width 350 aligns left with multiline
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 60 view width 64 view height 64 scale image scale proportionally
	set {batch_prompt, theTop} to create label batch_diag_prompt left inset 0 bottom (theTop) max width minWidth aligns center aligned with bold type
	set batch_allControls to {theBatchRule, batch_tally, MacYTDL_icon, batch_instruct, batch_prompt}
	
	-- Make sure MacYTDL is in front and show dialog
	tell me to activate
	set {batch_button_returned, batch_controls_results} to display enhanced window diag_Title buttons theButtons acc view width minWidth acc view height theTop acc view controls batch_allControls
	
	if batch_button_returned is "Download" then
		-- Eventually, will have code here which will read the batch file and present user with list to choose from - but, would be best if had show name not just URL
		download_batch(folder_chosen, remux_format_choice, YTDL_subtitles, YTDL_STEmbed, YTDL_credentials, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
	else if batch_button_returned is "Edit" then
		-- Check that there is a batch file
		tell application "System Events"
			set batch_file_test to batch_file as string
			if not (exists file batch_file_test) then
				display dialog "Sorry, there is no batch file." with title diag_Title buttons {"OK"} default button {"OK"} with icon MacYTDL_custom_icon_file giving up after 600
				my main_dialog()
			end if
		end tell
		tell application "Finder"
			activate
			open batch_file
		end tell
		open_batch_processing(folder_chosen, remux_format_choice, YTDL_subtitles, YTDL_STEmbed, YTDL_credentials, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
	else if batch_button_returned is "Clear" then
		clear_batch(folder_chosen, remux_format_choice, YTDL_subtitles, YTDL_STEmbed, YTDL_credentials, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
	else if batch_button_returned is "Remove last item" then
		remove_last_from_batch(folder_chosen, remux_format_choice, YTDL_subtitles, YTDL_STEmbed, YTDL_credentials, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
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
		display dialog "There was an error: " & batch_errMsg & "batch_file: " & batch_file with title "Tally_batch handler" buttons {"OK"} default button {"OK"}
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
-- Handler to download selection of URLs in Batch file - forms and calls youtube-dl separately from the download_video handler
on download_batch(folder_chosen, remux_format_choice, YTDL_subtitles, YTDL_STEmbed, YTDL_credentials, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
	
	-- Check that there is a batch file
	tell application "System Events"
		set batch_file_test to batch_file as string
		if not (exists file batch_file_test) then
			display dialog "Sorry, there is no batch file." with title diag_Title buttons {"OK"} default button {"OK"} with icon MacYTDL_custom_icon_file giving up after 600
			my open_batch_processing(folder_chosen, remux_format_choice, YTDL_subtitles, YTDL_STEmbed, YTDL_credentials, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
		end if
	end tell
	if (get eof file batch_file) is 0 then
		display dialog "Sorry, the batch file is empty." with title diag_Title buttons {"OK"} default button {"OK"} with icon MacYTDL_custom_icon_file giving up after 600
		open_batch_processing(folder_chosen, remux_format_choice, YTDL_subtitles, YTDL_STEmbed, YTDL_credentials, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
	end if
	
	-- Check that downloads folder is available
	check_download_folder(folder_chosen)
	
	-- Get date and time so it can be added to response file name
	set download_date_time to get_Date_Time()
	
	-- Set name to be used for response file and monitor dialog
	set YTDL_response_file to MacYTDL_preferences_path & "youtube-dl_response-Batch_download_on-" & download_date_time & ".txt"
	set download_filename_new to "the saved batch"
	
	-- Put diag title, file and path names into quotes as they are not passed correctly when they contain apostrophes or spaces
	set diag_Title_quoted to quoted form of diag_Title
	set download_filename_new to quoted form of download_filename_new
	set YTDL_response_file to quoted form of YTDL_response_file
	set YTDL_batch_file to quoted form of POSIX path of batch_file
	
	-- Set remaining variables needed by Monitor.scpt
	set YTDL_simulate_response to "Null"
	set URL_user_entered to "Null"
	set YTDL_output_template to " -o '%(title)s.%(ext)s'"
	
	-- Form up parameters to send to monitor.scpt - uses all current values		
	set ytdl_settings to quoted form of (" --restrict-filenames --ignore-errors --prefer-ffmpeg " & YTDL_subtitles & YTDL_STEmbed & YTDL_credentials & YTDL_format & YTDL_remux_format & YTDL_Remux_original & YTDL_description & YTDL_audio_only & YTDL_over_writes & YTDL_Thumbnail_Write & YTDL_Thumbnail_Embed & YTDL_metadata & YTDL_verbose & YTDL_output_template & " --batch-file " & YTDL_batch_file)
	set my_params to quoted form of downloadsFolder_Path & " " & MacYTDL_preferences_path & " " & ytdl_settings & " " & URL_user_entered & " " & YTDL_response_file & " " & download_filename_new & " " & MacYTDL_custom_icon_file_posix & " " & monitor_dialog_position & " " & YTDL_simulate_response & " " & diag_Title_quoted
	
	-- Prepare to call on the download Monitor - first get Monitor script location -- Monitor-bundle.scptd
	set myMonitorScriptAsString to quoted form of ((POSIX path of (path to me)) & "Contents/Resources/Scripts/Monitor.scpt")
	
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
on clear_batch(folder_chosen, remux_format_choice, YTDL_subtitles, YTDL_STEmbed, YTDL_credentials, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
	-- Check that there is a batch file
	tell application "System Events"
		set batch_file_test to batch_file as string
		if not (exists file batch_file_test) then
			display dialog "Sorry, there is no batch file." with title diag_Title buttons {"OK"} default button {"OK"} with icon MacYTDL_custom_icon_file giving up after 600
			return
		end if
	end tell
	if (get eof file batch_file) is 0 then
		display dialog "Sorry, the batch file is empty." with title diag_Title buttons {"OK"} default button {"OK"} with icon MacYTDL_custom_icon_file giving up after 600
		open_batch_processing(folder_chosen, remux_format_choice, YTDL_subtitles, YTDL_STEmbed, YTDL_credentials, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
	end if
	try
		set batch_file_ref to missing value
		set batch_file_ref to open for access file batch_file with write permission
		set eof batch_file_ref to 0
		close access batch_file_ref
	on error batch_errMsg
		display dialog "There was an error: " & batch_errMsg & "batch_file: " & batch_file buttons {"OK"} default button {"OK"}
		try
			close access batch_file_ref
		on error
			main_dialog()
		end try
		main_dialog()
	end try
	open_batch_processing(folder_chosen, remux_format_choice, YTDL_subtitles, YTDL_STEmbed, YTDL_credentials, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
end clear_batch


--------------------------------------------------------------------------
--
-- 	Remove last batch addition - called by open_batch_processing
--
--------------------------------------------------------------------------
-- Handler to remove the most recent addition to batch file
on remove_last_from_batch(folder_chosen, remux_format_choice, YTDL_subtitles, YTDL_STEmbed, YTDL_credentials, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
	-- Check that there is a batch file
	tell application "System Events"
		set batch_file_test to batch_file as string
		if not (exists file batch_file_test) then
			display dialog "Sorry, there is no batch file." with title diag_Title buttons {"OK"} default button {"OK"} with icon MacYTDL_custom_icon_file giving up after 600
			return
		end if
	end tell
	if (get eof file batch_file) is 0 then
		display dialog "Sorry, the batch file is empty." with title diag_Title buttons {"OK"} default button {"OK"} with icon MacYTDL_custom_icon_file giving up after 600
		open_batch_processing(folder_chosen, remux_format_choice, YTDL_subtitles, YTDL_STEmbed, YTDL_credentials, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
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
		display dialog "There was an error: " & batch_errMsg & "batch_file: " & batch_file buttons {"OK"} default button {"OK"}
		close access batch_file_ref
		main_dialog()
	end try
	open_batch_processing(folder_chosen, remux_format_choice, YTDL_subtitles, YTDL_STEmbed, YTDL_credentials, YTDL_format, YTDL_remux_format, YTDL_Remux_original, YTDL_description, YTDL_audio_only, YTDL_over_writes, YTDL_Thumbnail_Write, YTDL_Thumbnail_Embed, YTDL_metadata, YTDL_verbose)
end remove_last_from_batch


---------------------------------------------------
--
-- 	Parse SBS OnDemand web page - NOT IMPLEMENTED YET
--
---------------------------------------------------

--Handler to parse SBS On Demand "Show" pages so as to get a list of episodes - not currently in use
on Get_SBS_Episodes(URL_user_entered)
	display dialog "This is an SBS \"Show\" page from which MacYTDL cannot download videos. Try an individual episode"
	set SBS_show_page to do shell script "curl --data-ascii  " & URL_user_entered
end Get_SBS_Episodes


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
	set this_text to the item_list as string
	set AppleScript's text item delimiters to ""
	return this_text
end replace_chars


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
		set reversed to reverse of characters of the_object_string as string
		set last_occurrence_offset to len - (offset of the_search_string in reversed)
		--		set last_occurrence to len - (offset of char in reversed) + 1
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
	set monitor_dialog_position to ""
	set old_version_prefs to "No"
	set DL_batch_status to false
	error number -128
end quit_MacYTDL
