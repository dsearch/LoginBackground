Creates a background image file that can be used either for the desktop background or the lockscreen background.

format.html is the source template of the image. By default it is setup to display a background and some informational text along with QR codes that aid in inventory of devices. It should also render in a web-browser for quickly checking if the content is layed out properly. Format.html is processed by powershell and results are generated into a new html document that is rendered by wkhtmltoimage.exe. During the processing powershell executes it as an expanded string so additonal powershell commands may be embedded into the document. The example format.html document contains an example of generating and displaying QR codes.

By default the background image is selected based on aspect ratio of the screen. "background<aspect>.jpg" is slected if available otherwise it falls back to "backgroundDefault.jpg" or a solid color if no images are available.


Defaults and files:
format.html - example/default content
LockScreenInfo.ps1 - main script file
LockScreenInfo.cmd - Example launcher
  Both of these are adapted from https://gallery.technet.microsoft.com/scriptcenter/LockScreenInfo-Display-2adfc20b licensed under the MIT license.
system-inventory-utility.ps1 - Utility file to display/set asset tag information needs additional utilities to store asset tags in system firmware. MIT license.


Optional input files:
backgroundDefault.jpg - default background image
background<aspect raito>.jpg - background image for displays of specifc aspect ratio
%windir%\System32\oobe\info\<SYSTEM-UUID>-AssetTag.txt - Override asset tag (for systems that have incorrect or non-embeddable asset tags)
%windir%\System32\oobe\info\<SYSTEM-UUID>-SerialNum.txt - Override serial number (for systems that have incorrect serial numbers)
%windir%\System32\oobe\info\ContactInfo.txt - System contact info for $Contact variable.


Generated files:
generated.html - processed html (ExpandString)
AssetTag.png - (example format.html) QR code for device Asset Tag
SerialNum.png - (example format.html) QR code for Serial Number
%windir%\System32\oobe\info\backgrounds\backgroundDefault.jpg - default output image


Additional Requirements:
QRCoder.dll - https://github.com/codebude/QRCoder compiled version available at https://www.nuget.org/packages/QRCoder/ (QRCoder dll may be extracted from the .nupkg file under /lib/netcore/)
QRCoder is licensed under the MIT license.

wkhtmltoimage.exe - https://wkhtmltopdf.org/
wkhtmltoimage is licensed under GNU GPL version 3.
