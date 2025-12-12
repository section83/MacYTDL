---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  MacYTDL
--  A GUI for the Python Script yt-dlp.  Many thanks to Shane Stanley.
--  This is contains utilities for installing components etc.
--  Handlers in this script are called by main.scpt
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Include libraries
use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
-- use script "DialogToolkitMacYTDL" -- probably don't need DTP
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
-- Assuming for now that Deno version number is sourced from Preliminaries, before main_dialog()
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