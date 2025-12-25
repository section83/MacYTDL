# MacYTDL

MacYTDL is a utility which downloads videos using the [_yt-dlp_](https://github.com/yt-dlp/yt-dlp) and [_youtube-dl_](https://github.com/ytdl-org/youtube-dl) video downloader scripts.  _yt-dlp_ and _youtube-dl_ are able to download videos from a great many web sites. MacYTDL runs on any Apple Mac with macOS 10.10 or later and has been developed mostly in AppleScript. The key external conponents, _yt-dlp_, _FFmpeg_ and _Deno_, are installed by MacYTDL. The code is not accessable from within the applet. However, text exports of the code are in the "Code" folder above and can be opened in _Script Editor_. MacYTDL is code signed and notarized. Code signing ensures that the app has not been altered after it has been signed by the developer. Notarized apps have been scanned by Apple for known malware.

[Download from here](https://github.com/section83/MacYTDL/releases/download/1.30/MacYTDL-v1.30.dmg).

#### Main dailog

<img src="https://github.com/section83/MacYTDL/blob/master/Images/Main.png" width="480" height="374">

### Features

* Download individual videos and playlists.
* Download multiple videos in separate processes, in one process (sequentially) or in one process (parallel).
   * Parallel downloading is available for playlists, multiple downloads, batches and _ABC iView_ and _SBS OnDemand_ (Australia)
* Works with all sites supported by [_yt-dlp_](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md).
* Can cancel individual downloads.
* Can pause/resume downloads.
* By default, will resume interrupted downloads if passed the URL.
* Can pass through any custom settings to _youtube-dl_ and _yt-dlp_.
* Settings for level of _yt-dlp_ feedback, download folder, file format, remuxing format, download speed, proxy URL, Quicktime compatibility, custom file name template etc.
* Batch downloads.
* Provides option for choosing episodes of shows available on _ABC iView_ and _SBS OnDemand_ (Australia).
* PDF help file which describes how to use all MacYDL features.
* Download a text description of the video.
* Option to choose from available download files (called "formats").
* Switch between stable and nightly builds of _yt-dlp_.
* Localisation – currently Spanish, Italian, French and German are available (switching languages is supported in macOS 10.15 and later).
  * Localisation is not yet up-to-date.
* Download and embed subtitles in chosen format and language including auto-generated captions from YouTube.
* Download and optionally embed thumbnail images and metadata.
* Download or extract audio-only files in chosen format (conversion is done if necessary).
* Optional macOS Service which gets the current text selection, clipboard contents or active web browser URL, switches to MacYTDL and pastes URL of video to be downloaded.
* The Service can be set to automatically download from the URL of the current web page using current settings without showing the Main dialog.
* Settings can be saved, restored and reset to default.
* MacYTDL requires _yt-dlp_ and _FFmpeg_ both of which are downloaded and installed and can be updated by the app.
  * Other components are bundled in MacYTDL.
* Issues notification (via [*Alerter*](https://github.com/vjeantet/alerter)) when download finished with option to play the video.
* A separate log file is retained for each download enabling problem solving if a download fails.
* Has a built-in uninstaller which moves all components to Trash.
* Includes a range of simple utilities.
* Uses arm64 or x86_64 code according to user's Mac.

### Requirements

An Apple Mac running macOS 10.10 Yosemite and higher is required to use MacYTDL. MacYTDL works in Parallels virtual machines.

_yt-dlp_ is the default for all Macs. Python 3.13 is supplied with the _yt-dlp_ executable. However, Homebrew and MacPorts installs can be used. Detail is in the [Help](https://github.com/section83/MacYTDL/blob/master/Help.pdf).

_youtube-dl_ can be used with all versions of macOS up to Monterey 12.2.1. However _youtube-dl_ has not been updated since December 2021 and so is out-of-date. Users on Macs running macOS 10.15 to 12.2.1 can switch between _youtube-dl_ and _yt-dlp_.

### How to install for the first time

* Download and open [the DMG file](https://github.com/section83/MacYTDL/releases/download/1.30/MacYTDL-v1.30.dmg).
* Click and drag MacYTDL to any location - it's best to use the Applications folder.
* Open MacYTDL.
* When asked, click on "Yes" to install various components and create a preferences folder.
* Provide administrator credentials when asked.
* Wait – it can take time to download and install _yt-dlp_ and _FFmpeg_.
* MacYTDL main dialog is displayed.

### How to update

* Download and open [the DMG file](https://github.com/section83/MacYTDL/releases/download/1.30/MacYTDL-v1.30.dmg).
* Click and drag MacYTDL to your usual location – make sure to replace the old version.
* Open MacYTDL. Components such as the preferences file are updated as required.
* There is a facility to download an update, if more recent, in "Utilities".

More detail is available in [the Help file](https://github.com/section83/MacYTDL/blob/master/Help.pdf) (4.9MB).

### Bugs, problems, questions
To report bugs, problems etc., get a Github account, click on the "Issues" tab above and open a new issue.  Alternatively, open an item in "Discussions" above or send an email to macytdl@gmail.com.

### Acknowledgements

MacYTDL would be useless without [_yt-dlp_](https://github.com/yt-dlp/yt-dlp). It is a remarkable, feature rich tool maintained by the most dedicated group of volunteers.

Much is owed to Shane Stanley, for his many contributions solving problems with MacYTDL. Shane developed [Dialog Toolkit Plus and Myriad Tables Lib](https://latenightsw.com/support/freeware/) which provide the dialogs in MacYTDL. MacYTDL is developed in [_Script Debugger_](https://latenightsw.com). Many thanks to Mark Alldritt and Shane for their 30 years of dedication to _SD_ and the _SD_ users. _SD_ will be sorely missed.

Ideas for this GUI front-end came from many sources including:

* Adam Albrec, author of PPC Media Centre.
* Michael Page (http://techion.com.au), author of the Video Hoarder automator script.
* “kopurando” (https://github.com/kopurando), author of the Virga downloader.
* “Tombs” (https://forum.videohelp.com/members/235982-Tombs) an active contributor to [Whirlpool](www.whirlpool.net.au) and author of the URLDown Dropper utility for Windows.
* “xplorr” (https://forum.videohelp.com/members/268051-xplorr), author of TVDownloader.
* Anonymous (https://cresstone.com/apps/youtubeDLFrontEnd/), author of youtubeDLFrontEnd.
* Frank, Geoff, John, Santo, Trevor and Walter, fellow members of the [ACT Apple Users Group](https://www.actapple.org.au).
* MacYTDL users 1alessandro1, 11lucasarr11, Adam, adam01212, adenosslept, AirMarty, Alex, Alex Luis, alikaylan, alphabitnz, Andy, andyrb412, Anjum, Antaro, artcore-c, barney1903, Başar, Bohdan, BigJoe309, bovirus, Brandon, CdrSpock, CharlesLai0307, Chris, ComfortableMilk4454, Dantha, darbid, defcon5at, Didier EuronymousDeadOhlin, Dorkington, dragonlord66666, EricTheDerek, Fred B, frissonlabs, froggyking3, Gábor Librecz, GrantGochnauer, gustavosaez, Hamza, heviiguy, hunterbr3193, inb4ohnoes, Infinivibex, ItsMorePaul, lxne, Jack, JAKHIGDON, janvdvelde, JeanT, jeremydouglass, John E, Joshua, L-Kiewa, kuglee, Labhansh-Sharma, Labhansh-Sharma, leon-chen-wen-jia, LordB54, marksinclair1, macmeister1967, LeonardoMaracino, macmeister1967, MalEbenSo, Marius, martinsstuff, mcdiarmid1, meiwechner, michel-GH, Mike, minkses, mmaslar, mmicha, MrJmpl3, Nellio, nottooloud, onaforeignshore, palomnik, pedrocadiz13, Peter, QAQDE, Rick, Raymond-Adams, roest01, Ruben, Stephenzero, SwineBurglar, tabascoman77, Ted, Tenz14, thejasonparker, tht7, tigrr, Tobias, Tom, TomasCarlson, tryitagain, upekshapriya, Vinsamlegast78, vorob1, watto23, williamcorney, Woolfy025, Yehushupat, zxzzz8.

### MacYTDL is free

MacYTDL is a retirement project for me and will always be free. Please consider sponsoring the [_yt-dlp_](https://github.com/yt-dlp/yt-dlp) team. Detail on sponsorships is available here: https://github.com/yt-dlp/yt-dlp/blob/master/Collaborators.md#collaborators.

If you use other shareware or open source software consider making a donation to the developers – let them know they are appreciated.
