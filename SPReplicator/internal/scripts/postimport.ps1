# Add all things you want to run after importing the main code

# Load Configurations
foreach ($file in (Get-ChildItem "$ModuleRoot\internal\configurations\*.ps1" -ErrorAction Ignore)) {
    . Import-ModuleFile -Path $file.FullName
}

# Load Logging Provider
foreach ($file in (Get-ChildItem "$ModuleRoot\internal\provider\*.provider.ps1" -ErrorAction Ignore)) {
    . Import-ModuleFile -Path $file.FullName
}

# Load Tab Expansion
foreach ($file in (Get-ChildItem "$ModuleRoot\internal\tepp\*.tepp.ps1" -ErrorAction Ignore)) {
    . Import-ModuleFile -Path $file.FullName
}

# Load Tab Expansion Assignment
. Import-ModuleFile -Path (Join-SprPath $ModuleRoot internal tepp assignment.ps1)

# Load License
. Import-ModuleFile -Path (Join-SprPath $ModuleRoot internal scripts license.ps1)