Register-PSFTeppScriptblock -Name SPReplicator-Template -ScriptBlock {
	$class = [Microsoft.SharePoint.Client.ListTemplateType]
	[System.Enum]::GetNames($class)
}
Register-PSFTeppScriptblock -Name SPReplicator-FieldType -ScriptBlock {
	[System.Enum]::GetNames([Microsoft.SharePoint.Client.FieldType]) | Where-Object { $PSItem -ne 'Invalid' } | Sort-Object
}
Register-PSFTeppScriptblock -Name SPReplicator-Location -ScriptBlock { "OnPrem", "Online" }