$script:ModuleRoot = $PSScriptRoot
$script:site = "sharepoint2016"
$script:mylist = "My Test List"
$script:filename = "C:\temp\$script:mylist.xml"
$script:onlinesite = "https://netnerds.sharepoint.com"
$script:onlinecred = Import-CliXml -Path "$home\Documents\sponline.xml"