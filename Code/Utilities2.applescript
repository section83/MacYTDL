---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  MacYTDL
--  This is contains handlers for installing Deno, getting Deno version and asking user for video password.
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
		set installAlertTitle to quoted form of (localized string "MacYTDL installation:" from table "MacYTDL")
		set installAlertMessage to quoted form of (localized string "started.  Please wait." from table "MacYTDL")
		set installAlertSubtitle to quoted form of (localized string "Installing Deno" from table "MacYTDL")
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
on get_Video_password(theButtonReturnLabel, theButtonOKLabel, MacYTDL_custom_icon_file_posix, diag_Title, MacYTDL_custom_icon_file)
	-- Set variables for the get credentials dialog	
	set theCredentialsInstructionsLabel to localized string "Enter the password for the next video download in the box below, skip and continue to download or return to the Main dialog." from table "MacYTDL"
	set theCredentialsDiagPromptLabel to localized string "Password for next download" from table "MacYTDL"
	set instructions_text to theCredentialsInstructionsLabel
	set credentials_diag_prompt to theCredentialsDiagPromptLabel
	set accViewWidth to 275
	set accViewInset to 0
	
	-- Set buttons and controls
	set theButtonsCredSkipLabel to localized string "Skip" from table "MacYTDL"
	set theButtonsCredBackLabel to localized string "Back" from table "MacYTDL"
	set {theButtons, minWidth} to create buttons {theButtonReturnLabel, theButtonsCredSkipLabel, theButtonOKLabel} button keys {"r", "s", ""} default button 3
	set theButtonsCredPasswordLabel to localized string "Password" from table "MacYTDL"
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
				set theBlankPasswordLabel to localized string "You didn't enter your video password. Do you wish to go back, return to Main dialog or skip credentials and download ?" from table "MacYTDL"
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