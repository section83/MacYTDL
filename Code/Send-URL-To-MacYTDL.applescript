-- This script runs from a service inside a web browser.  It gets the name of the browser and with that uses the required technique to get the URL of the current tab/page/window.

set app_name_short to short name of (info for (path to frontmost application))

if app_name_short is "Safari" then
	using terms from application "Safari"
		tell application "Safari"
			set video_URL to URL of current tab of first window
		end tell
	end using terms from
else if app_name_short is "Firefox" then
	tell application app_name_short to activate
	tell application "System Events"
		keystroke "l" using command down
		keystroke "c" using command down
	end tell
	delay 0.5
	set video_URL to the clipboard
else if app_name_short is "Opera" then
	tell application app_name_short
		set video_URL to URL of front document as string
	end tell
else if app_name_short is "Chrome" then
	try
		set video_URL to run script "\ntell application \"Chrome\"\nreturn URL of active tab of front window\nend tell"
	end try
else if app_name_short is "Edge" then
	set app_name_short to "Microsoft Edge"
	try
		set video_URL to run script "\ntell application \"Microsoft Edge\"\nreturn URL of active tab of front window\nend tell"
	end try
else if app_name_short is "Chromium" then
	try
		set video_URL to run script "\ntell application \"Chromium\"\nreturn URL of active tab of front window\nend tell"
	end try
end if

set MacYTDL_appName to "MacYTDL"
set startIt to false

-- Is MacYTDL running
tell application "System Events"
	if not (exists process MacYTDL_appName) then
		set startIt to true
	end if
end tell

-- MacYTDL is not running - launch it and pass the URL to main dialog
if startIt is true then
	tell application MacYTDL_appName
		ignoring application responses
			launch
			called_by_service(video_URL)
		end ignoring
	end tell
end if

-- MacYTDL is running - bring MacYTDL to the front and set the URL - browser must not be in full screen
if startIt is false then
	tell application "System Events"
		tell process app_name_short
			tell front window
				set value of attribute "AXFullScreen" to false
			end tell
		end tell
		delay 1
		tell process MacYTDL_appName
			set visible to true
			set frontmost to true
		end tell
		delay 1
		set value of text field 1 of window of process MacYTDL_appName to video_URL
	end tell
end if
