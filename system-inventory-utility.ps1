#########################################################################
# system-inventory-utility.ps1: configure inventory settings interactivly
# Optional:
# AssetTag.exe - Microsoft surface asset tag utility.
# cctk.exe - Dell command-control toolkit utility.
#########################################################################

cd (Split-Path $MyInvocation.MyCommand.Path)
$Script:OPERATINGSYSTEM = get-wmiobject -class "win32_operatingsystem" -namespace "root\CIMV2" -computername "."
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
write-output "System Information:"
write-output "Host: $HostName"
write-output "Manufacturer: $Manufacturer"
write-output "Model: $Model"
write-output "Contact: $Contact"
write-output "UUID: $($PRODUCT.UUID)"
write-output "BIOS Serial Number: $SerialNum (Override:$OverrideSerialNum)"
write-output "BIOS Asset Tag: $AssetTag (Override:$OverrideAssetTag)"
if($AssetTag -eq 0 -and  $Manufacturer -eq "Microsoft Corporation" -and (Get-ChildItem -filter "AssetTag.exe") ) {
  $AssetTag = read-host -Prompt "Set Surface asset tag (blank to skip)"
  if($AssetTag) {
    ./AssetTag.exe -s $AssetTag
  }
}
if($AssetTag -eq "" -and $Manufacturer -eq "Dell Inc." -and (Get-ChildItem -filter "cctk.exe")) {
  $AssetTag = read-host -Prompt "Set Dell asset tag (blank to skip)"
  if($AssetTag) {
    ./cctk.exe --asset=$AssetTag
  }
}
$answer = read-host -Prompt "Set Overrides [y/n]?"
if($answer -eq "y") {
  $OverrideSerialNum = read-host -Prompt "Override Serial Number"
  $OverrideAssetTag = read-host -Prompt "Override Asset Tag"
  if($OverrideSerialNum) {
    $OverrideSerialNum | out-file "$($COMPUTERINFO.OsSystemDirectory)\oobe\info\$($PRODUCT.UUID)-SerialNum.txt"
  }
  if($OverrideAssetTag) {
    $OverrideAssetTag | out-file "$($COMPUTERINFO.OsSystemDirectory)\oobe\info\$($PRODUCT.UUID)-AssetTag.txt"
  }
}