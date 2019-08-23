Anyone is welcome to suggest improvements, changes, re-designs etc.  If you are an AppleScript coder, please provide suggested code.  It's best to create a new issue or pull request.

Even better, you could download MacYTDL, make changes using *Script Editor* (test it works) and upload to this repo. At this stage MacYTDL will be code signed with my signature.  So, I'll need to monitor contributions, incorporate the new code, test, update the Help and Versions files and upload for each release.

## Some principles

MacYTDL has been developed with some guiding principles:

* Explain as much as possible in the help document(s) – which are accessible from within the app and outside in the dmg file.
* Make all code accessible to the user.
* Provide the user with all components not already in macOS – either installing from within the app bundle or downloading from the source – tell user what is being installed before hand and give option to opt out.
* Don’t reinstall components the user already has.
* Provide a function to check and update all components – with opt out.
* Provide a function to clean up all temporary/log files.
* Provide a function for a complete but reversible uninstaller.
