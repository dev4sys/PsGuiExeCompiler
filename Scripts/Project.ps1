##############################
# Kevin RAHETILAHY
# DEV4SYS
##############################

#  Comment:
# KRA: Initialize the project location on the loval computer
# Need to Implement a method to be selected from a project file later.
$Script:ProjectLocation = $null

Function Get-ProjectLocation(){
    Param(
        [String]$ProjectSource
    )
    If(Test-Path -Path $ProjectSource)
    {
        Write-Host "Source project found."
    }
    Else
    {
        # Project Folder does not exists. Ask the user if hes wants to start a new project.
        Write-Host "No project found or invalid project."
    }

}


Function New-Project(){
    Param(
        [String]$ProjectName,
        [string]$ProjectLocation
    )

    $iRet = $false

    $tempBeforeCreate = "$ProjectLocation\$ProjectName"
    If(Test-Path -Path $tempBeforeCreate){
        # Project already exists
        Write-Host "Project already exists. Please choose a different name."

    }
    Else{
        # Create the new Porject folder
        New-Item -path "$ProjectLocation" -name "$ProjectName" -type directory -ErrorAction Stop | Out-null
        $iRet = $true    
    }

    return $iRet

}