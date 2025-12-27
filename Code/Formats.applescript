use AppleScript version "2.4" -- Yosemite (10.10) or later
use scripting additions
use script "Myriad Tables Lib" version "1.0.13"
property parent : AppleScript


----------------------------------------------------------------------------------
--
-- 		Show format chooser - user to select files for download
--
----------------------------------------------------------------------------------

-- Handler to show format chooser - user can choose which available formats are to be downloaded - separate audio and video formats can be merged
on formats_Chooser(URL_user_entered, diag_Title, theButtonCancelLabel, theButtonDownloadLabel, X_position, screen_height, MacYTDL_custom_icon_file, MacYTDL_custom_icon_file_posix, theButtonReturnLabel, skip_Main_dialog, path_to_MacYTDL, DL_Use_YTDLP, shellPath, download_filename_formats, YTDL_credentials, window_Position, formats_reported, is_Livestream_Flag, YTDL_Use_netrc)
	
	
	--	try
	
	-- v1.26 – Added "--no-playlist" to yt-dlp call as playlists are a nonsense for the formats chooser - doesn't seem to affect other kinds of downloads
	set formats_reported to (do shell script shellPath & DL_Use_YTDLP & " " & YTDL_credentials & YTDL_Use_netrc & " --list-formats --no-playlist " & URL_user_entered)
	
	-- Need to remove extraneous spaces so that getting text items works - can't do a simple search and replace as number of consecutive spaces varies greatly
	set character_count to count of characters of formats_reported
	set formats_available to ""
	repeat with x from 1 to character_count
		set text_char to character x of formats_reported
		if text_char is " " then
			set text_next_char to character (x + 1) of formats_reported
			if text_next_char is not " " then
				set formats_available to formats_available & text_char
			end if
		else
			set formats_available to formats_available & text_char
		end if
	end repeat
	
	
	--		set testing_filename to "ContentOfListFormats.txt" as string
	--		set save_path to path to desktop folder as string
	--		set save_text_file_to to (save_path & testing_filename)
	--		set testing_file to save_text_file_to as «class furl»
	--		set testFile_refNum to missing value
	--		set testFile_refNum to open for access testing_file with write permission
	--		write (formats_available & return) to testFile_refNum starting at eof as «class utf8»
	--		close access testFile_refNum
	
	set download_filename_fixed to replace_chars(download_filename_formats, "\\", "##")
	set download_filename_fixed to replace_chars(download_filename_fixed, {"'", linefeed}, "")
	set download_filename_fixed to replace_chars(download_filename_fixed, "_", " ")
	set download_filename_fixed to replace_chars(download_filename_fixed, "##", "´")
	
	-- Need to drop first 6-7 paras which do not have file details - number of intro paras varies but one always starts with "ID"
	-- Also need to find those sites which do not report file size e.g. ABC iView in Australia - there might be other cases of data not being present in which case this will probably show a mess
	set file_size_present to false
	repeat with x from 1 to count paragraphs of formats_available
		set test_paragraph to paragraph x of formats_available
		if test_paragraph starts with "ID" then
			set z to (x + 1)
			if test_paragraph contains "FILESIZE" then set file_size_present to true
		end if
	end repeat
	
	-- Initialise lists and get count of paragraphs
	set numParas to count paragraphs of formats_available
	set full_ID_list to {}
	set all_table_rows to {}
	repeat (numParas - z) times
		set end of full_ID_list to ""
	end repeat
	
	-- Parse each paragraph for desired data - work up from bottom of the list
	set AppleScript's text item delimiters to " "
	repeat with x from -1 to (-(numParas - z)) by -1
		
		set full_file_format to paragraph (x) of formats_available
		
		-- Get file id - abbreviate if longer than 12 characters for the display
		set file_id_test to text item 1 of full_file_format
		set item x of full_ID_list to file_id_test
		if length of file_id_test is greater than 12 then
			set file_id to text 1 thru 12 of file_id_test as string
		else
			set file_id to file_id_test
		end if
		
		-- Get file extension
		set file_ext to text item 2 of full_file_format
		
		-- Get video resolution
		if text item 4 of full_file_format is "only" then
			set file_res to "Audio only"
		else
			set file_res to (text item 3 of full_file_format & "  ")
		end if
		
		-- Get file size if present then total bitrate, video and audio codecs
		set file_size to ""
		set test1_for_size to text item 6 of full_file_format
		set test2_for_size to text item 7 of full_file_format
		set file_vcodec to ""
		set file_acodec to ""
		-- Note: there is no file size for live streams
		if file_size_present is true then
			if test2_for_size is "~" or test2_for_size is "≈" then -- Some layouts have a space between "~" or "≈" and file size - 29/8/23 added "≈" v1.25 here and below
				set file_size to text item 8 of full_file_format
				set total_bitrate to text item 9 of full_file_format
			else if test1_for_size is "|" then -- audio only + files with both v and a codecs
				set file_size to (text item 7 of full_file_format)
				set total_bitrate to (text item 8 of full_file_format)
			else if character -1 of test1_for_size is "B" then -- YouTube video only files & small 7Plus files
				if text item 5 of full_file_format is "~" or text item 5 of full_file_format is "≈" then
					set file_size to ("~" & test1_for_size)
					set total_bitrate to (text item 7 of full_file_format)
				else
					set file_size to test1_for_size
					set total_bitrate to (text item 7 of full_file_format)
				end if
			else if text item 4 of full_file_format is "|" then
				set file_size to (text item 5 of full_file_format)
				set total_bitrate to (text item 6 of full_file_format)
			else if text item 5 of full_file_format is "~" or text item 5 of full_file_format is "≈" then
				set file_size to ("~" & text item 6 of full_file_format)
				set total_bitrate to (text item 7 of full_file_format)
			else if text item 6 of full_file_format is "~" or text item 6 of full_file_format is "≈" then -- 7Plus layout
				set file_size to ("~" & text item 7 of full_file_format)
				set total_bitrate to (text item 8 of full_file_format)
			end if
			
			-- Get video codec
			if text item 9 of full_file_format is "|" then -- YouTube & some 7Plus
				set file_vcodec to text item 10 of full_file_format
			else if text item 9 of full_file_format is not "storyboard" and text item 10 of full_file_format is "|" and file_res is not "Audio only" then -- YT both codecs
				set file_vcodec to (text item 11 of full_file_format)
				-- Exclude Daily Motion and 9Now videos which don't return 11 items
			else if URL_user_entered does not contain "dailymotion" and URL_user_entered does not contain "9Now" then
				if text item 9 of full_file_format is not "storyboard" and text item 11 of full_file_format is "|" and file_res is not "Audio only" then -- YT both codecs with "~"
					set file_vcodec to (text item 12 of full_file_format)
				end if
			else if text item 9 of full_file_format is "storyboard" then
				set file_vcodec to (tab & "Storyboard")
			end if
			if text item 8 of full_file_format is "|" then
				set file_vcodec to (text item 9 of full_file_format)
			end if
			
			-- Get audio codec - 6/6/24 - Added try block to help find Swedish TV audio codecs
			if file_res is "audio only" and full_file_format does not contain "Default" then -- For YouTube and 7Plus - 30/8/23 v1.25 - added check for default
				try
					set file_acodec to text item 13 of full_file_format
				on error
					set file_acodec to text item 12 of full_file_format
				end try
			end if
			if test1_for_size is "|" then -- audio only + files with both v and a codecs
				set file_acodec to text item 13 of full_file_format
				if text item 7 of full_file_format is "~" or text item 7 of full_file_format is "≈" then
					set file_acodec to text item 14 of full_file_format
				end if
			end if
			if test1_for_size is not "|" and URL_user_entered contains "sbs.com.au/ondemand" then -- 29/8/23 v1.25 - SBS format has changed
				set file_acodec to text item 11 of full_file_format
			end if
			if file_vcodec is not (tab & "Storyboard") and full_file_format does not contain "Default" and full_file_format contains "Video" then -- For YouTube and 7Plus - 30/8/23 v1.25 - added check for default + for SBS added test for Video
				if text item 11 of full_file_format is "video" or text item 12 of full_file_format is "video" or text item 13 of full_file_format is "video" then
					set file_acodec to "Video only"
				end if
			end if
			-- To reduce complexity of parsing, decided to put this If block into a Try block
			try
				if text item 10 of full_file_format contains "mp4a" then -- For 9Now in Oz and maybe others
					set file_acodec to text item 10 of full_file_format
				else if text item 11 of full_file_format contains "mp4a" then -- For 10Play in Oz and maybe others
					set file_acodec to text item 11 of full_file_format
				else if text item 12 of full_file_format contains "mp4a" then -- For some YouTube videos
					set file_acodec to text item 12 of full_file_format
				else if text item 13 of full_file_format contains "mp4a" then -- For some YouTube videos
					set file_acodec to text item 13 of full_file_format
				end if
			end try
		else
			-- Get bitrate, audio and video codec details for cases which have no file size e.g. iView & live streams - making some guesses for live streams from other providers
			if file_res is "Audio only" then -- YouTube & 9Now livestreams
				set file_acodec to text item 10 of full_file_format
			else
				if text item 7 of full_file_format is "|" then -- For iView
					set total_bitrate to text item 5 of full_file_format
					set file_vcodec to text item 8 of full_file_format
					if formats_available contains "VBR" then -- 29/8/23 - v1.25 - added VBR test as some iView URLs do not have VBR or ABR
						set file_acodec to text item 10 of full_file_format
					else
						set file_acodec to text item 9 of full_file_format
					end if
				else if text item 5 of full_file_format is "|" then -- For iView, SBS, 9Now and YouTube livestreams
					set total_bitrate to text item 6 of full_file_format
					set file_vcodec to text item 9 of full_file_format
					try
						if text item 10 of full_file_format contains "mp4a" then -- For YouTube livestreams
							set file_acodec to text item 10 of full_file_format
						else if text item 10 of full_file_format contains "video" then -- For YouTube livestreams - audio only formats
							set file_acodec to "Video only"
						end if
					end try
				else if text item 4 of full_file_format is "|" then
					set total_bitrate to text item 5 of full_file_format
					set file_vcodec to text item 8 of full_file_format
					set file_acodec to text item 9 of full_file_format
				end if
			end if
		end if
		
		-- This is all the text for a single row
		set fileformat_item to {false, file_id, file_ext, file_res, file_size, total_bitrate, file_vcodec, file_acodec}
		-- This adds each row to the list of rows - add to beginning so that no need to design a new iteration method
		set beginning of all_table_rows to fileformat_item
		
	end repeat
	set AppleScript's text item delimiters to ""
	
	-- v1.27 – Turned off live stream message as some live streams have separate formats - i.e. user can choose two formats
	--		if is_Livestream_Flag is "True" then
	--			set instructions_text to localized string "Select one format live stream you wish to download then click on Download. You can skip choosing or cancel the download and return to the Main Dialog." in bundle file path_to_MacYTDL from table "MacYTDL"
	--		else
	set instructions_text to localized string "Select which formats you wish to download then click on Download. You can skip choosing formats or cancel the download and return to the Main Dialog." in bundle file path_to_MacYTDL from table "MacYTDL"
	--		end if
	set theFormatsDiagPromptLabelPart1 to localized string "Choose Formats" in bundle file path_to_MacYTDL from table "MacYTDL"
	set theFormatsDiagPromptLabelPart2 to localized string "Downloading file" in bundle file path_to_MacYTDL from table "MacYTDL"
	--	set theButtonDownloadLabel to localized string "Download" from table "MacYTDL"
	--	set theButtonReturnLabel to localized string "Return" from table "MacYTDL"
	set theButtonSkipLabel to localized string "Skip" in bundle file path_to_MacYTDL from table "MacYTDL"
	--		set theMergeCheckboxLabel to localized string "Merge formats ? [Recommended]" in bundle file path_to_MacYTDL from table "MacYTDL"
	set theMergeCheckboxLabel to localized string "Merge ?" in bundle file path_to_MacYTDL from table "MacYTDL"
	set theHeadingExtensionLabel to localized string "Extension" in bundle file path_to_MacYTDL from table "MacYTDL"
	set theHeadingResolutionLabel to localized string "Resolution" in bundle file path_to_MacYTDL from table "MacYTDL"
	set theHeadingFilesizeLabel to localized string "File size" in bundle file path_to_MacYTDL from table "MacYTDL"
	set theHeadingTotalBitrateLabel to localized string "Bitrate" in bundle file path_to_MacYTDL from table "MacYTDL"
	set theHeadingTotalVCodecLabel to localized string "Video Codec" in bundle file path_to_MacYTDL from table "MacYTDL"
	set theHeadingTotalACodecLabel to localized string "Audio Codec" in bundle file path_to_MacYTDL from table "MacYTDL"
	
	-- Can't find a way to insert a return before the checkbox - Myriad Tables expects just one data class in each cell of each column	
	set end of all_table_rows to {true, (theMergeCheckboxLabel & return & return)}
	
	set theFormatsDiagPromptLabel to (tab & tab & tab & tab & tab & tab & theFormatsDiagPromptLabelPart1 & return & return & theFormatsDiagPromptLabelPart2 & ": " & "\"" & download_filename_fixed & "\"" & return & return & instructions_text)
	
	set format_chooser_headings to {"", "ID", theHeadingExtensionLabel, theHeadingResolutionLabel, theHeadingFilesizeLabel, theHeadingTotalBitrateLabel, theHeadingTotalVCodecLabel, theHeadingTotalACodecLabel}
	
	set repeat_loop_flag to ""
	
	
	--		set AppleScript's text item delimiters to ", "
	--		set table_data to items of all_table_rows as text
	--		set testFile_refNum to open for access testing_file with write permission
	--		write (table_data & return) to testFile_refNum starting at eof as «class utf8»
	--		close access testFile_refNum
	--		set AppleScript's text item delimiters to ""
	
	
	repeat until repeat_loop_flag is "Finished"
		try
			set my_table to make new table with data all_table_rows editable columns {1} column headings format_chooser_headings with prompt theFormatsDiagPromptLabel with title diag_Title with empty selection allowed and multiple lines allowed
			modify table my_table initial position window_Position OK button name theButtonDownloadLabel cancel button name theButtonReturnLabel extra button name theButtonSkipLabel
			modify columns in table my_table columns list {2, 3, 4, 5, 6, 7, 8} head alignment align center sort method sort none
			modify columns in table my_table columns list {1} column width 35
			set theResult to display table my_table giving up after 600
			set button_returned to button number of theResult -- Shows no need to iterate through results just to get button number pressed
			set rows_returned to values returned of theResult -- A list of lists which can be parsed to get IDs of formats the user ticked
		on error number -128
			-- Go back to Main
			if skip_Main_dialog is true then error number -128 -- This is relevant when user has come from Auto-download - need to just quit the applet
			set branch_execution to "Main"
			return branch_execution
		end try
		
		set file_formats_selected to ""
		set user_wants_choose to false
		
		-- User chose formats and wants to download - form up list of selected formats – add merge indicatory between format IDs – "+" indicates merge and "," indicates keep separate		
		if button_returned is 1 then
			-- Iterate through the values returned to find those chosen by user plus the response to the merger question
			set count_choices to 0
			set number_of_formats_requested to (number of items in rows_returned)
			if item 1 of item number_of_formats_requested of rows_returned is true then
				set merger_choice to "+"
				set add_to_output_template to ""
			else
				set merger_choice to ","
				set add_to_output_template to "%(format_id)s" -- Always add format id to file names because file names are the same for all formats
			end if
			repeat with x from 1 to (number_of_formats_requested - 1) -- Last item is the merger choice
				if item 1 of item x of rows_returned is true then
					set count_choices to count_choices + 1
					if count_choices is 1 then
						set file_formats_selected to item x of full_ID_list
					else
						set file_formats_selected to file_formats_selected & merger_choice & item x of full_ID_list
					end if
				end if
			end repeat
			set branch_execution to "Download" & " " & file_formats_selected & " " & add_to_output_template
			
			-- v1.27 - Turned off live stream message as some live streams have separate formats - i.e. user can choose two formats
			--				if is_Livestream_Flag is "True" and count_choices is greater than 1 then
			--					set theFormatsChoiceLabel to localized string "You have chosen to download multiple formats" in bundle file path_to_MacYTDL from table "MacYTDL"
			--					set theManyFormatsLabel to localized string "Sorry but, only one format can be downloaded for live streams. Do you wish to download the first format, choose again or cancel and return to the Main dialog ?" in bundle file path_to_MacYTDL from table "MacYTDL"
			--					set theFirstLabel to localized string "First" in bundle file path_to_MacYTDL from table "MacYTDL"
			--					set theChooseLabel to localized string "Choose" in bundle file path_to_MacYTDL from table "MacYTDL"
			--					set manyFormatsButton to button returned of (display dialog (theFormatsDiagPromptLabelPart1 & return & return & theFormatsChoiceLabel & ": " & file_formats_selected & return & return & theManyFormatsLabel) with title diag_Title buttons {theFirstLabel, theChooseLabel, theButtonReturnLabel} default button 1 with icon file MacYTDL_custom_icon_file giving up after 600)
			--					if manyFormatsButton is theButtonReturnLabel then
			--						if skip_Main_dialog is true then error number -128
			--						set branch_execution to "Main"
			--						set repeat_loop_flag to "Finished"
			--						return branch_execution
			--					else if manyFormatsButton is theFirstLabel then
			--						-- Keep first two format choices and download them - YT-DLP will download the first two formats and ignore the others
			--						set branch_execution to "Download" & " " & file_formats_selected & " " & add_to_output_template
			--						set repeat_loop_flag to "Finished"
			--						return branch_execution
			--					end if
			-- User must have clicked on theChooseLabel - try to get back to beginning of the repeat loop without doing anything
			--					set user_wants_choose to true
			--				end if
			if count_choices is greater than 2 and merger_choice is "+" then
				set theFormatsChoiceLabel to localized string "You have chosen to merge these formats" in bundle file path_to_MacYTDL from table "MacYTDL"
				set theManyFormatsLabel to localized string "Sorry but, three or more formats cannot be merged. Do you wish to merge the first two and ignore the other(s), choose again or cancel and return to the Main dialog ?" in bundle file path_to_MacYTDL from table "MacYTDL"
				set theIgnoreLabel to localized string "Ignore" in bundle file path_to_MacYTDL from table "MacYTDL"
				set theChooseLabel to localized string "Choose" in bundle file path_to_MacYTDL from table "MacYTDL"
				set manyFormatsButton to button returned of (display dialog (theFormatsDiagPromptLabelPart1 & return & return & theFormatsChoiceLabel & ": " & file_formats_selected & return & return & theManyFormatsLabel) with title diag_Title buttons {theButtonReturnLabel, theChooseLabel, theIgnoreLabel} default button 3 with icon file MacYTDL_custom_icon_file giving up after 600)
				if manyFormatsButton is theButtonReturnLabel then
					if skip_Main_dialog is true then error number -128
					set branch_execution to "Main"
					set repeat_loop_flag to "Finished"
					return branch_execution
				else if manyFormatsButton is theIgnoreLabel then
					-- Keep first two format choices and download them - YT-DLP will download the first two formats and ignore the others
					set branch_execution to "Download" & " " & file_formats_selected & " " & add_to_output_template
					set repeat_loop_flag to "Finished"
					return branch_execution
				end if
				-- User must have clicked on theChooseLabel - try to get back to beginning of the repeat loop without doing anything
				set user_wants_choose to true
			end if
			if file_formats_selected is "" then
				set theChooseLabel to localized string "Choose" in bundle file path_to_MacYTDL from table "MacYTDL"
				set theNoFormatsLabel to localized string "You didn't select any formats. Do you wish to choose formats, skip and continue to download or cancel and return to Main ?" in bundle file path_to_MacYTDL from table "MacYTDL"
				set noFormatsButton to button returned of (display dialog theNoFormatsLabel with title diag_Title buttons {theButtonReturnLabel, theButtonSkipLabel, theChooseLabel} default button 3 with icon file MacYTDL_custom_icon_file giving up after 600)
				if noFormatsButton is theButtonReturnLabel then
					if skip_Main_dialog is true then error number -128
					set branch_execution to "Main"
					set repeat_loop_flag to "Finished"
					return branch_execution
				else if noFormatsButton is theButtonSkipLabel then
					-- Skip the chooser and go back to calling point in download_video - download with existing settings
					set branch_execution to "Skip"
					set repeat_loop_flag to "Finished"
					return branch_execution
				end if
				-- User must have clicked on theChooseLabel - try to get back to beginning of the repeat loop without doing anything
				set user_wants_choose to true
			end if
			
			-- This is the end of the "button_returned is 1" block - User gets here if they clicked on "Download" and made no mistakes with their choice - branch_execution contains the choice
			if user_wants_choose is false then
				return branch_execution
			end if
			
			-- Skip the chooser and go back to calling point in download_video to download with existing settings
		else if button_returned is 2 then
			set branch_execution to "Skip"
			set repeat_loop_flag to "Finished"
		end if
	end repeat
	
	return branch_execution
	-- Finished with chooser - head off to download with or without formats or to just return to Main
	
	
	
	
	--	on error errMsg
	--		display dialog errMsg
	--	end try
	
	
	
	
end formats_Chooser

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
