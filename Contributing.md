Anyone is welcome to suggest improvements, changes, re-designs etc.  If you are an AppleScript coder, please provide suggested code.  It's best to create a new issue or pull request.

Even better, you could download MacYTDL, make changes using *Script Editor* (test it works) and upload to this repo. At this stage MacYTDL will be code signed with my signature.  So, I'll need to monitor contributions, incorporate the new code, test, update the Help and Versions files and upload for each release.

## Some principles

MacYTDL has been developed with some guiding principles:

* explain as much as possible in the help document(s) – which are accessible from within the app and outside in the dmg file;
* make all code accessible to the user;
* provide the user with all components not already in macOS – either installing from within the app bundle or downloading from the source – tell user what is being installed beforehand and give option to opt out;
* don’t reinstall components the user already has;
* enable the user to check and update all components from within the app – with opt out;
* provide a function to clean up all temporary/log files
* provide a function for a complete but reversible uninstaller.
