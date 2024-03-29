############################################################################################
# SCRIPT  : LockScreenInfo.ps1 - BGINFO REPLACEMENT IN POWERSHELL FOR WINDOWS 7/10 enterprise
# PURPOSE : GET THE BEST OF BACKINFO (Microsoft) AND BGINFO (Sysinternals)
# Version : 08/11/2011 - RIVIERRE Frédéric (VortiFred)
# Version : 01/03/2012 - RIVIERRE Frédéric (VortiFred)
# Version : 07/11/2014 - RIVIERRE Frédéric (VortiFred)
# Version : 11/07/2019 - David Search (WSUTC)
############################################################################################

[CmdletBinding()]

    Param (
        [Parameter(ValueFromPipeline=$False,Mandatory=$False,HelpMessage="Path to target image")]
        [string]$TargetImage = "$env:SYSTEMROOT\System32\oobe\info\backgrounds\backgroundDefault.jpg",
        [Parameter(ValueFromPipeline=$False,Mandatory=$False,HelpMessage="Path to HTML configuration file")]
        [string]$HTMLPath = "format.html"
    )

#set-psdebug -strict
set-strictmode -version 1.0
$error.clear()
$DebugPreference = "SilentlyContinue"


#===============================================================================
# FUNCTION SECTION 
#-------------------------------------------------------------------------------
# LogWrite - format log messages
Function LogWrite {
   Param ([string]$logstring)
   "[$((Get-Date).ToString())] [$($MyScript)] $logstring" | out-file -filepath $LogFile -append 
}
#-------------------------------------------------------------------------------
# oGetScreenInfo - Using .NET classes (working with RDP and VM)
#-------------------------------------------------------------------------------
function oGetScreenInfo {
  	#[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	return [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
}
#-------------------------------------------------------------------------------
# oGetVideoMode - Using WMI (not working with RDP and VM)
#-------------------------------------------------------------------------------
function oGetVideoMode {
    #get current screen resolution
    [int]$VideoWidth, [int]$VideoHeight, [int]$VideoFormat = 0, 0, 0
    $computer = "LocalHost" 
    $namespace = "root\CIMV2" 
    $colItems = Get-WmiObject -class Win32_VideoController -computername $computer -namespace $namespace -filter "CurrentHorizontalResolution > 0"
    foreach ($objItem in $colItems) {
        $VideoWidth = $objItem.CurrentHorizontalResolution
        $VideoHeight = $objItem.CurrentVerticalResolution
        write-verbose -Message "CurrentHorizontalResolution=$VideoWidth" # .gettype.name()
        write-verbose -Message "CurrentVerticalResolution=$VideoHeight" #.gettype.name()
    }
     LogWrite "[info] WMI Video Mode Description:$($objItem.VideoModeDescription)"
    if ($VideoHeight -gt 0) { $VideoFormat = [math]::round(($VideoWidth/$VideoHeight), 2) }
    #else { $VideoFormat = 0 }
    return $Obj = New-Object -TypeName PSObject -Property @{"CurrentHorizontalResolution"= $VideoWidth; "CurrentVerticalResolution" = $VideoHeight ; "VideoFormat" = $VideoFormat }
 }

#
#Generate_QR - create an image of a qr code
#
function Generate_QR {
    Param (
        [Parameter(Mandatory=$True)][string]$Data,
        [Parameter(Mandatory=$True)][string]$ImageFile,
        [Parameter(Mandatory=$False)][int]$PixelSize = 1,
        [Parameter(Mandatory=$False)][byte[]]$LightColor = (255,255,255,255),
        [Parameter(Mandatory=$False)][byte[]]$DarkColor = (0,0,0,255)
    )
    add-type -Path QRCoder.dll
    $qrgen = New-Object QRCoder.QRCodeGenerator
    $pngdata = New-Object QRCoder.PngByteQRCode -ArgumentList ($qrgen.CreateQrCode($Data,"L"))
    [System.IO.File]::WriteAllBytes($ImageFile,$pngdata.GetGraphic($PixelSize,$DarkColor,$LightColor))
}

#-------------------------------------------------------------------------------
# InitDefinedItem 
# create global variable about the Computer
#-------------------------------------------------------------------------------
function vInitDefinedItem {

    $Script:MyScript = $(Split-Path -Leaf $MyInvocation.ScriptName)
    $Script:LogFile = "$($env:Temp)\$((Get-ChildItem -Path $MyInvocation.ScriptName).Basename).log"

    $Script:OPERATINGSYSTEM = get-wmiobject -class "win32_operatingsystem" -namespace "root\CIMV2" -computername "."
    $Script:WMIBootTime = $OPERATINGSYSTEM.LastBootUpTime
    $Script:LastBootTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($WMIBootTime)
    $Script:BootTime = "$($LastBootTime.toshortdatestring()) $($LastBootTime.toshorttimestring())"
    $Script:COMPUTERSYSTEM = get-wmiobject -class "win32_computersystem" -namespace "root\CIMV2" -computername "."
    $Script:SYSTEMENCLOSURE = get-wmiobject -class "win32_systemenclosure" -namespace "root\CIMV2" -computername "."
    $Script:PRODUCT = get-wmiobject -class "Win32_ComputerSystemProduct" -namespace "root\CIMV2" -computername "."
    $Script:HostName = $COMPUTERSYSTEM.Name
    $Script:Manufacturer = $COMPUTERSYSTEM.Manufacturer
    $Script:Model = $COMPUTERSYSTEM.Model
    $Script:OverrideSerialNum = Get-Content "$($OPERATINGSYSTEM.SystemDirectory)\oobe\info\$($PRODUCT.UUID)-SerialNum.txt" -ErrorAction SilentlyContinue
    $Script:OverrideAssetTag = Get-Content "$($OPERATINGSYSTEM.SystemDirectory)\oobe\info\$($PRODUCT.UUID)-AssetTag.txt" -ErrorAction SilentlyContinue
    $Script:Contact = Get-Content "$($OPERATINGSYSTEM.SystemDirectory)\oobe\info\ContactInfo.txt" -ErrorAction SilentlyContinue
    $Script:SerialNum = $SYSTEMENCLOSURE.SerialNumber
    $Script:AssetTag = $SYSTEMENCLOSURE.SMBIOSAssetTag
    if($OverrideSerialNum) {
        $Script:SerialNum = $OverrideSerialNum
    }
    if($OverrideAssetTag) {
        $Script:AssetTag = $OverrideAssetTag
    }
    if ($COMPUTERSYSTEM.PartOfDomain) { 
        $Script:ComputerDomain = $($COMPUTERSYSTEM.Domain) 
    } else { 
        $Script:ComputerDomain = $($COMPUTERSYSTEM.WorkGroup)
    }
    [array]$Script:PROCESSORS = get-wmiobject -class "Win32_Processor" -namespace "root\CIMV2" -computername "."
    [array]$Script:NetworkAdapterConfiguration = get-wmiobject -Class "Win32_NetworkAdapterConfiguration" -Name "root\cimv2" -Filter "IpEnabled=True"
    #$Script:OEMInformation = get-itemproperty -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation"
	$Script:OEMInformation = get-itemproperty -path "HKLM:\SYSTEM\ControlSet001\Control\SystemInformation"
    #$Script:ComputerInfos = get-itemproperty -path "HKLM:\SOFTWARE\Vortisoft\ComputerInfos"
	$Script:ComputerInfos = 
    $Script:TcpIpParameters = get-itemproperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\TcpIp\Parameters"
    $Script:TotalPhysicalMemory = $COMPUTERSYSTEM.TotalPhysicalMemory
    
    $Script:hFormat = @{1.25="5/4";1.33="4/3";1.5="3/2";1.6="16/10";1.67="5/3";1.78="16/9";1.89="17/9"}
  	$Script:hExtension = @{".bmp"="Bmp";".emf"="Emf";".gif"="Gif";".jpg"="Jpeg";".png"="Png";".tif"="Tiff";".wmf"="Wmf"}
}

Function vExit([int]$ExitCode) {
     LogWrite "[info] === exit process. ==="
    Exit $ExitCode
}

#-------------------------------------------------------------------------------
# MAIN 
#-------------------------------------------------------------------------------

    #Initialize Predefined Computer Informations
    vInitDefinedItem
    $LogFile
     "[$((Get-Date).ToString())] [$($MyScript)] [info] === begin process. ===" | out-file -filepath $LogFile
    #Trace context infos
     LogWrite "[info] MyInvocationName:$($MyInvocation.InvocationName)"
     LogWrite "[info] MyInvocationLine:$($MyInvocation.Line)"
     LogWrite "[info] PsHome:$PsHome"
     LogWrite "[info] BuildVersion:$($PsVersionTable.BuildVersion.ToString())"
     LogWrite "[info] PowerShell Version:$($PsVersionTable.PSVersion.ToString())"
     LogWrite "[info] Working Directory:$($Pwd.Path)"
     LogWrite "[info] About Environment:"
    Get-ChildItem Env: | ForEach-Object { LogWrite "[info] $($_.Key)=$($_.Value)" }

    #Get WMI Win32_VideoController
    $oScreenResolution = oGetVideoMode 
    $ScreenWidth = [int]($oScreenResolution.CurrentHorizontalResolution)
    $ScreenHeight = [int]($oScreenResolution.CurrentVerticalResolution)

    if ($ScreenHeight -gt 0) {
        LogWrite "[info] Get Screen Size from WMI."
        $ScreenFormat = [math]::round(($ScreenWidth/$ScreenHeight), 2) }
    else { 
        $oScreenInfo = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        if ($oScreenInfo.Height -gt 0) {
            LogWrite "[info] Get Screen Size from Win32 Screen API."
            $ScreenWidth = [int]$oScreenInfo.Width
            $ScreenHeight = [int]$oScreenInfo.Height
        } else {
            LogWrite "[info] Set Arbitrary Screen Size."
            $ScreenWidth = 1024
            $ScreenHeight = 768
        }
    }
    $ScreenFormat = [math]::round(($ScreenWidth/$ScreenHeight), 2)
     LogWrite "[info] Current Screen Size:$ScreenWidth x $ScreenHeight"
     LogWrite "[info] Screen Format:$ScreenFormat ($($hFormat.$ScreenFormat))"

$html = Get-Content -raw $HTMLPath
$htmlExpanded = $ExecutionContext.InvokeCommand.ExpandString($html)
Write-Output $htmlExpanded > generated.html
.\wkhtmltoimage.exe --disable-smart-width --log-level error --width $ScreenWidth --height $ScreenHeight generated.html $TargetImage
LogWrite ".\wkhtmltoimage.exe --disable-smart-width --log-level none --width $($ScreenWidth) --height $($ScreenHeight) generated.html $TargetImage"

### END OF SCRIPT ###