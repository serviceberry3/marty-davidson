# An auto-reply bot for iMessage (Mac) and Android Messages #

This is Marty, an iMessage auto-reply robot which can store and retrieve users’ information in an SQL databse, call users and deliver automated robotic messages, schedule appointments, and remotely control an LED display.

There are three versions of Marty currently available:
* For older versions (pre-High Sierra) of MacOS. Probably won't work further back than OS X Mountain Lion. This version is implemented in AppleScript or JavaScript for Automation (JXA). Located in **Marty_AppleScript** and **Marty_JavaScript** folders. 
    * To use it, change any AppleScript files to .scpt and then select them as the "AppleScript Handler" in Messages > Preferences > General on a Mac Laptop. 
* For newer verisons (High Sierra or more recent) of MacOS. This version is implemented in Swift and interacts with chat.db via SQL.
* For Android. This version is an Android app that uses Android's BroadCastReceiver and android.provider.Telephony.SMS_RECEIVED.

# Updates #
## Newer MacOS versions ##
***12/16/20:*** I'm working on a new release which fixes bugs and adds support for messages "reactions."   
***11/30/20:*** Grab the latest release up there on the right-hand side. Download that .app file. You'll know what to do after that...
