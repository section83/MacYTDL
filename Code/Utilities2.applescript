---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  MacYTDL
--  This is contains handlers for installing Deno, getting Deno version and asking user for video password.
-- Also has handler for getting video password
--  Handlers in this script are called by main.scpt and Utilities.scpt
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Include libraries
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use script "DialogToolkitMacYTDL"
property parent : AppleScript


--------------------------------------------------------------------------
-- for testing
--set deno_version to "2.5.4"
--set user_system_arch to "arm64"
--set path_to_MacYTDL to path to me as text
--set resourcesPath to POSIX path of (path_to_MacYTDL & "Contents:Resources:")
--set theButtonOKLabel to "OK"
--set MacYTDL_custom_icon_file to "Bennett:Users:macytdl:MacYTDL:MacYTDL:MacYTDL.app:Contents:Resources:macytdl.icns" as string
--set diag_Title to "MacYTDL, v1.30 - testing"
--install_update_Deno(deno_version, user_system_arch, resourcesPath, path_to_MacYTDL, theButtonOKLabel, MacYTDL_custom_icon_file, diag_Title)
--------------------------------------------------------------------------

--------------------------------------------------------------------------
--
-- 		Does user wish to install/update Deno ?
--
--------------------------------------------------------------------------

-- Handler for installing/updating Deno - called by Preliminaries and Utilities dialog - Added in v1.30, 1/11/25
-- This is not called if Deno_version contains "Refused"
-- Assuming for now that Deno version number is sourced from Preliminaries, before main_dialog()
-- deno_version contains current version installed, "Refused" or "Not installed"
-- Currently sourcing Deno from deno.land. If there are problems will change to GitHub.
on install_update_Deno(deno_version, user_system_arch, resourcesPath, path_to_MacYTDL, theButtonOKLabel, MacYTDL_custom_icon_file, diag_Title, MacYTDL_prefs_file)
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
		set installAlertTitle to quoted form of (localized string "MacYTDL installation:" in bundle file path_to_MacYTDL from table "MacYTDL")
		set installAlertMessage to quoted form of (localized string "started.  Please wait." in bundle file path_to_MacYTDL from table "MacYTDL")
		set installAlertSubtitle to quoted form of (localized string "Installing Deno" in bundle file path_to_MacYTDL from table "MacYTDL")
		do shell script resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
		try
			do shell script "curl -L " & deno_download_site & " -o /usr/local/bin/deno.zip" with administrator privileges
			do shell script "unzip -o /usr/local/bin/deno.zip -d /usr/local/bin/" with administrator privileges
			do shell script "rm /usr/local/bin/deno.zip" with administrator privileges
			set deno_version to text 2 thru end of deno_current_version
			tell application "System Events"
				tell property list file MacYTDL_prefs_file
					set value of property list item "Deno_version" to deno_version
				end tell
			end tell
			display dialog ((localized string "Deno is installed and up-to-date. You have version") & " " & deno_version) buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		on error number -128
			-- User cancels credentials dialog - just return to Main dialog
			set theYTDLInstallCancelLabel to localized string "You've cancelled installing Deno. You can install/update Deno in the Utilities dialog." in bundle file path_to_MacYTDL from table "MacYTDL"
			display dialog theYTDLInstallCancelLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		end try
	else
		display dialog ((localized string "Deno is up-to-date. You have version" in bundle file path_to_MacYTDL from table "MacYTDL") & " " & deno_version) buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		return deno_version
	end if
	return deno_version
end install_update_Deno


---------------------------------------------------
--
--			Get Deno version
--
---------------------------------------------------

-- Handler to get version of currently installed Deno - called during startup if prefs file is missing or out-of-date, by update_settings() and by set_preferences()
on get_Deno_version()
	set deno_file to ("/usr/local/bin/deno" as text)
	tell application "System Events"
		if exists file deno_file then
			set deno_version to word 2 of (do shell script "/usr/local/bin/deno -v")
		else
			set deno_version to "Not installed"
		end if
	end tell
	return deno_version
end get_Deno_version


---------------------------------------------------
--
-- 		Get video password
--
---------------------------------------------------

-- v1.31, 16/4/26 - User ticked the runtime setting to include password for next video download - Called by main_dialog()
on get_Video_password(theButtonReturnLabel, theButtonOKLabel, MacYTDL_custom_icon_file_posix, diag_Title, MacYTDL_custom_icon_file, path_to_MacYTDL)
	-- Set variables for the get credentials dialog	
	set theCredentialsInstructionsLabel to localized string "Enter the password for the next video download in the box below, skip and continue to download or return to the Main dialog." in bundle file path_to_MacYTDL from table "MacYTDL"
	set theCredentialsDiagPromptLabel to localized string "Password for next download" in bundle file path_to_MacYTDL from table "MacYTDL"
	set instructions_text to theCredentialsInstructionsLabel
	set credentials_diag_prompt to theCredentialsDiagPromptLabel
	set accViewWidth to 275
	set accViewInset to 0
	
	-- Set buttons and controls
	set theButtonsCredSkipLabel to localized string "Skip" in bundle file path_to_MacYTDL from table "MacYTDL"
	set theButtonsCredBackLabel to localized string "Back" in bundle file path_to_MacYTDL from table "MacYTDL"
	set {theButtons, minWidth} to create buttons {theButtonReturnLabel, theButtonsCredSkipLabel, theButtonOKLabel} button keys {"r", "s", ""} default button 3
	set theButtonsCredPasswordLabel to localized string "Password" in bundle file path_to_MacYTDL from table "MacYTDL"
	set {theField_password, theTop} to create field "" placeholder text theButtonsCredPasswordLabel left inset accViewInset bottom 5 field width accViewWidth
	--	set theButtonsCredNameLabel to localized string "User name" from table "MacYTDL"
	--	set {theField_username, theTop} to create field "" placeholder text theButtonsCredNameLabel left inset accViewInset bottom (theTop + 20) field width accViewWidth
	set {utilities_instruct, theTop} to create label instructions_text left inset 75 bottom (theTop + 15) max width (accViewWidth - 75) aligns left aligned with multiline
	set {MacYTDL_icon, theTop} to create image view MacYTDL_custom_icon_file_posix left inset 0 bottom theTop - 60 view width 64 view height 64 scale image scale proportionally
	set {utilities_prompt, theTop} to create label credentials_diag_prompt left inset 0 bottom (theTop + 10) max width accViewWidth aligns center aligned with bold type
	set credentials_allControls to {theField_password, MacYTDL_icon, utilities_instruct, utilities_prompt}
	
	-- Make sure MacYTDL is in front and show dialog - Repeat loop ensures blank credentials are not returned
	tell me to activate
	repeat
		set {password_button_returned, passwordButtonNumberReturned, credentials_results} to display enhanced window diag_Title buttons theButtons acc view width accViewWidth acc view height theTop acc view controls credentials_allControls
		
		if passwordButtonNumberReturned is 3 then
			-- Get control results from password dialog
			--	set theField_username_choice to item 1 of credentials_results -- <= User name
			set theField_password_choice to item 1 of credentials_results -- <= Password
			set YTDL_videoPW to "--video-password " & theField_password_choice & " "
			if theField_password_choice is "" then
				set theBlankPasswordLabel to localized string "You didn't enter your video password. Do you wish to go back, return to Main dialog or skip credentials and download ?" in bundle file path_to_MacYTDL from table "MacYTDL"
				set vidPW_skip_back_or_giveup to button returned of (display dialog theBlankPasswordLabel with title diag_Title buttons {theButtonReturnLabel, theButtonsCredSkipLabel, theButtonsCredBackLabel} default button 3 with icon file MacYTDL_custom_icon_file giving up after 600)
				if vidPW_skip_back_or_giveup is theButtonReturnLabel then
					return "Main"
					exit repeat
				end if
				if vidPW_skip_back_or_giveup is theButtonsCredSkipLabel then
					return "Download"
					exit repeat
				end if
				if vidPW_skip_back_or_giveup is theButtonsCredBackLabel then
					-- Do nothing - just repeat the credentials dialog
				end if
			else
				return YTDL_videoPW
				exit repeat
			end if
		else if passwordButtonNumberReturned is 2 then
			-- Continue download without credentials
			return "Download"
			exit repeat
		else
			
			-- ************************************************************************************************************************************************************
			-- v1.29.2 - 11/5/25 - First version of repeat loop to control flow
			-- User clicked on "Return"
			return "Main"
			exit repeat
			--	main_dialog()
			-- ************************************************************************************************************************************************************		
			
		end if
	end repeat
end get_Video_password


---------------------------------------------------
--
-- 		Check for yt-dlp nightly update
--
---------------------------------------------------

-- Handler to check and update nightly edition of yt-dlp if user wishes - called by Utilities dialog and the auto check on startup
-- v1.31.2, 25/8/26 - First implementation on recommendation of users including Michel
-- Legacy and Homebrew users cannot get to here and so no need to test those cases

on check_ytdl_nightly(MacYTDL_custom_icon_file, diag_Title, theButtonOKLabel, theButtonNoLabel, theButtonYesLabel, MacYTDL_prefs_file, YTDL_version, ytdlp_file, alert_text_ytdl, resourcesPath)
	
	-- Get version of latest yt-dlp nightly release
	set YTDL_site_URL to "https://github.com/yt-dlp/yt-dlp-nightly-builds/releases"
	set name_of_executable to "yt-dlp_macos"
	try
		set YTDL_releases_page to do shell script "curl " & YTDL_site_URL & " | textutil -stdin -stdout -format html -convert txt -encoding UTF-8 "
	on error errMSG
		set theYTDLCurlErrorLabel1 to localized string "There was an error with looking for the " from table "MacYTDL"
		set theYTDLCurlErrorLabel2 to localized string " web page. The error was: " from table "MacYTDL"
		set theYTDLCurlErrorLabel3 to localized string ", and the URL that produced the error was: " from table "MacYTDL"
		set theYTDLCurlErrorLabel4 to localized string "Try again later and/or send a message to macytdl@gmail.com with the details." from table "MacYTDL"
		set theYTDLCurlErrorLabel to theYTDLCurlErrorLabel1 & "yt-dlp" & theYTDLCurlErrorLabel2 & errMSG & theYTDLCurlErrorLabel3 & YTDL_site_URL & ". " & theYTDLCurlErrorLabel4
		display dialog theYTDLCurlErrorLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return "Main"
		--	main_dialog()
		-- ************************************************************************************************************************************************************
		
	end try
	
	-- The plist file normally has the correct version number of the installed YTDL_version - but, because settings are on a user basis, on multi-user Macs this can be out-of-date
	-- Note, that getting the ytdl version via do shell script can be slow for reasons I've never understood
	
	set installedYTDL_version to do shell script ytdlp_file & " --version"
	-- If installed version is different to user's settings file, update the settings file
	if installedYTDL_version is not YTDL_version then
		tell application "System Events"
			tell property list file MacYTDL_prefs_file
				set value of property list item "YTDL_YTDLP_version" to installedYTDL_version
			end tell
		end tell
		set YTDL_version to installedYTDL_version -- Added on 9/6/23 - seems like a good idea
	end if
	
	set theYTDLUpToDateLabela to localized string " is up to date. Your installed version is " from table "MacYTDL"
	set theYTDLUpToDateLabel to "yt-dlp" & theYTDLUpToDateLabela
	set switch_flag to false
	if alert_text_ytdl is "Switching" then set switch_flag to true
	set alert_text_ytdl to theYTDLUpToDateLabel & installedYTDL_version
	-- Trap case in which user is offline or some other problem in reaching yt-dlp
	if YTDL_releases_page is "" then
		set theYTDLPageErrorLabel1 to localized string "There was a problem with looking for " from table "MacYTDL"
		set theYTDLPageErrorLabel2 to localized string "Perhaps you are not connected to the internet or GitHub is currently not available." from table "MacYTDL"
		set theYTDLPageErrorLabel to theYTDLPageErrorLabel1 & "yt-dlp" & ". " & theYTDLPageErrorLabel2
		display dialog theYTDLPageErrorLabel buttons {theButtonOKLabel} default button 1 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600
		
		-- ************************************************************************************************************************************************************
		-- v1.29.2 - 26/4/25 - First version of repeat loop to control flow
		return "Main"
		--	main_dialog()
		-- ************************************************************************************************************************************************************
		
	else
		-- v1.31.2, 20/8/26 - Now getting latest version from second last para - Not an issue on Tahoe but fixes crashes on Monterey
		set AppleScript's text item delimiters to "Latest"
		set YTDL_releases_text to text item 1 of YTDL_releases_page
		set numParas to count paragraphs in YTDL_releases_text
		--	set version_para to paragraph (numParas) of YTDL_releases_text
		set version_para to paragraph (numParas - 1) of YTDL_releases_text
		set AppleScript's text item delimiters to " "
		--	set YTDL_version_check to text item 2 of version_para
		set YTDL_version_check to text item 3 of version_para
		set AppleScript's text item delimiters to ""
		
		if YTDL_version_check is not equal to installedYTDL_version then
			if switch_flag is true then
				set YTDL_update_text to "To switch to yt-dlp it will need to be installed. Would you like to install it now ?"
			else
				set YTDL_update_text to "A new nightly version of yt-dlp is available. You have version" & " " & installedYTDL_version & ". " & "The latest version is" & " " & YTDL_version_check & return & return & "Would you like to install it now ?"
			end if
			tell me to activate
			set YTDL_install_answ to button returned of (display dialog YTDL_update_text buttons {theButtonNoLabel, theButtonYesLabel} default button 2 with title diag_Title with icon file MacYTDL_custom_icon_file giving up after 600)
			if YTDL_install_answ is theButtonYesLabel then
				try
					do shell script "curl -L https://github.com/yt-dlp/yt-dlp-nightly-builds/releases/latest/download/yt-dlp_macos.zip -o  /usr/local/bin/yt-dlp_macos.zip" with administrator privileges
					set installAlertActionLabel to quoted form of "_"
					set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
					set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
					set installAlertSubtitle to quoted form of ((localized string "Download and update of " from table "MacYTDL") & "yt-dlp")
					do shell script resourcesPath & "alerter -message " & installAlertMessage & " -title " & installAlertTitle & " -subtitle " & installAlertSubtitle & " -timeout 10 -sender com.apple.script.id.MacYTDL -actions " & installAlertActionLabel & " > /dev/null 2> /dev/null & "
					do shell script "unzip -o /usr/local/bin/yt-dlp_macos.zip -d /usr/local/bin/" with administrator privileges
					do shell script "mv /usr/local/bin/yt-dlp_macos /usr/local/bin/yt-dlp" with administrator privileges
					do shell script "rm /usr/local/bin/yt-dlp_macos.zip" with administrator privileges
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
				set YTDL_version to YTDL_version_check
				tell application "System Events"
					tell property list file MacYTDL_prefs_file
						set value of property list item "YTDL_YTDLP_version" to YTDL_version
					end tell
				end tell
				set theYTDLUpDatedLabel to localized string " has been updated. Your new version is " from table "MacYTDL"
				set alert_text_ytdl to "yt-dlp" & theYTDLUpDatedLabel & YTDL_version
			else
				set theYTDLOutOfDateLabel to localized string " installed has not been changed. Your installed version is " from table "MacYTDL"
				set alert_text_ytdl to "yt-dlp" & theYTDLOutOfDateLabel & YTDL_version
			end if
		else
			-- In this case, the installed version is up to date
			return alert_text_ytdl
		end if
	end if
end check_ytdl_nightly