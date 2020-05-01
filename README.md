# MacYTDL

MacYTDL is a macOS GUI front end for [youtube-dl, the cross-platform video downloader](https://github.com/ytdl-org/youtube-dl). It runs on any Apple Mac with macOS 10.10 or later. It has been developed in AppleScript. The code is not protected and can be opened in Script Editor. MacYTDL is code signed and notarized.

[Download from here](https://github.com/section83/MacYTDL/releases/download/1.14.1/MacYTDL-v1.14.1.dmg).


![Main dailog](https://github.com/section83/MacYTDL/blob/master/images/Main%20-%20v1.14.png)

### Features

* Download individual videos and playlists.
* Download multiple videos separately (in parallel) or in one process (sequentially).
* Works with all sites supported by youtube-dl.
* Can cancel individual downloads.
* Settings for level of youtube-dl feedback, download folder, file format and remuxing format.
* Batch downloads.
* Download a text description of the video.
* Download and embed subtitles in chosen format and language.
* Download and optionally embed thumbnail images and metadata.
* Download or extract audio-only files in chosen format.
* Download selected episodes from ABC iView (Australia) show pages.
* Optional macOS Service for use in web browsers which copies the current URL, switches to MacYTDL and pastes URL of video to be downloaded.
* All components downloaded and/or installed by MacYTDL, which can be controlled by the user. Component updates available in the app.
* A separate log file is retained for each download enabling problem solving if a download fails.
* Has a built-in uninstaller which moves all components to Trash.
* Includes a range of simple utilities.
* Is 64-bit and so runs in macOS 10.15 Catalina.

### How to install

* Download and open [the DMG file](https://github.com/section83/MacYTDL/releases/download/1.14.1/MacYTDL-v1.14.1.dmg).
* Read the Help file.
* Click and drag MacYTDL to any location - it's best to use the Applications folder.
* Run MacYTDL.
* Click on "Yes" to install various components and create a preferences folder when asked.
* Provide administrator credentials when asked.
* Wait.
* MacYTDL dialog is displayed.

More detail is available in [the Help file](https://github.com/section83/MacYTDL/blob/master/images/Help-v1.14-small.pdf).

### Bugs, problems, questions
To report bugs, problems etc., get a Github account, click on the "Issues" tab above and open a new issue.

### Acknowledgements

MacYTDL would be useless without [youtube-dl](https://github.com/ytdl-org/youtube-dl). It is a remarkable, feature rich utility maintained by the most dedicated group of volunteers.

Much is owed to Shane Stanley, for his many contributions solving problems with MacYTDL. Shane developed [Dialog Toolkit Plus](https://www.macosxautomation.com/applescript/apps/Script_Libs.html#DialogToolkit) which provides the dialogs in MacYTDL. Ideas for this GUI front-end came from many sources including:

* Adam Albrec, author of PPC Media Centre.
* Michael Page (http://techion.com.au), author of the Video Hoarder automator script.
* “kopurando” (https://github.com/kopurando), author of the Virga downloader.
* “Tombs” (https://forum.videohelp.com/members/235982-Tombs) an active contributor to [Whirlpool](www.whirlpool.net.au) and author of the URLDown Dropper utility for Windows.
* “xplorr” (https://forum.videohelp.com/members/268051-xplorr), author of TVDownloader. Anonymous (https://cresstone.com/apps/youtubeDLFrontEnd/), author of youtubeDLFrontEnd.
* Frank, Trevor and John, fellow members of the ACT Apple Users Group.
* MacYTDL users bovirus, 11lucasarr11, Ted, Peter, Mike, Dantha and upekshapriya.

### MacYTDL is free but...

MacYTDL is a retirement project for me and will always be free. But if you use MacYTDL to download files please consider making a donation to the youtube-dl project. Their donation page is here:

https://ytdl-org.github.io/youtube-dl/donations.html
