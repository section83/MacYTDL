Anyone is welcome to suggest improvements, changes, re-designs etc.  If you are an AppleScript coder, please provide suggested code.  It's best to create a new issue or pull request.

Have a look at the lists of issues that I have raised.  If you feel anything is missing, please add a new issue.

Even better, you could download MacYTDL, make changes using *Script Editor* (test it works) and upload to this repo.  Please add a comment to the issue or pull request that you are working on code for a particular issue.

At this stage MacYTDL will be code signed with my signature.  So, I'll need to monitor contributions, incorporate the new code, test, update the Help and Versions files and upload for each release.

## Some principles for users

MacYTDL has been developed with some guiding principles:

* Explain as much as possible in the help document(s) – which are accessible from within the app and outside in the dmg file.
* Make all code accessible to the user.
* Provide the user with all components not already in macOS – either installing from within the app bundle or downloading from the source – tell user what is being installed before hand and give option to opt out.
* Don’t reinstall components the user already has.
* Provide a function to check and update all components – with opt out.
* Provide a function to clean up all temporary/log files.
* Provide a function for a complete but reversible uninstaller.

## Some principles for coding

You can see from my code that it's not the best. However, it would help if coders can:

* Add comments to code so that others will be able to understand what it does (especially me).
* This is an AppleScript project. So, please stay with AppleScript or AppleScript Objective-C.  If you wish to use another language, take a copy of MacYTDL and start a new repo of your own.
* Feel free to improve existing code – MacYTDL could be more efficient.
* Avoid changing macOS requirements.  MacYTDL currently runs on macOS 10.10 and above.  That enables it to run on many older Macs.
