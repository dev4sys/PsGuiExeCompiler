##############################
# Kevin RAHETILAHY
# DEV4SYS
##############################


Function Main(){
    
    Param(
        [String]$exeName,
        [String]$mainScript,
        [String]$outPutPath,
        [String]$projectDirectory
    )

    $iRet = $False

    Write-Host "Starting process for $exeName  ... "
    Write-Host "Using as main script: $mainScript" 

    GenerateProjectStructure
    $retVal = GenerateDirectoryInf -resourcesDirectory "$projectDirectory\Project\Resources"
    GenerateProgramCs -toolName $exeName -mainScript $mainScript
    GenerateCSprojectFile

    If(!$retVal){
        Write-Host "An error ocurred while processing your application files."
    }

    Write-Host "Ending process"

    # return the status of the exexcution
    return $iRet
}

Function Run(){
     
     Param(
     [String]$action
     )


    Switch ($action)
    {
        "Build" { 
       
            $cmdLine =  ".\MSBuild\15.0\Bin\MSBuild.exe .\Socle\starter.csproj /target:Build /tv:4.0"
       
        }
        "Clean" { 

            $cmdLine =  ".\MSBuild\15.0\Bin\MSBuild.exe .\Socle\starter.csproj /target:Clean"
       
        }
    }   

}

Function GenerateDirectoryInf(){

    # ====================== Description ======================================
    # This function get the list of file and directory to be stored
    # It will be used to recreate the souce structure form emmbeded resources. 
    # =========================================================================
    Param(
        [String]$resourcesDirectory
    )
    
    $iRet = $true
    # extension to be exclude in the project for later ...
    $filter = ""

    Try{
        $FileLIst = Get-ChildItem -Path $resourcesDirectory -file -recurse -ErrorAction SilentlyContinue | % { if ($_.PsIsContainer) { $_.FullName + "\" } else { $_.FullName } }
        $RelativePathList = $FileLIst.Replace("$resourcesDirectory","")
        $RelativePathList | Out-File "$resourcesDirectory\directory.inf"
    }
    Catch{
        $iRet = $False
        Write-Host "An error occured. Error:  $($_.Exception.Message)"
    }

    return $iRet

}

Function GenerateProgramCs(){
    # ====================== Description =====================================
    # This function update the content of program.cs before build
    # ========================================================================

    Param(
        [String]$toolName,
        [String]$mainScript
    )

    # %mainScript.ps1%
    # %toolName%
    $canProceed = (IsValidToolName($toolName) -and IsvalidScriptName($toolName))

    if($canProceed)
    {
        # Open and replace elements in the code from template
        $ProgramCSharp      = Get-content ".\Tools\Template\Program.cs"
        $TempProgramCSharp  = $ProgramCSharp.Replace("%toolName%",$toolName)
        $ProgramCSharp      = $TempProgramCSharp.Replace("%mainScript.ps1%",$mainScript)

        # Export result to the current project folder
        $ProgramCSharp  | Set-Content ".\Project\Program.cs"
        $TempProgramCSharp = $null
        
    }
    else
    {
        Write-Host "Incorrect parameter *ToolName or *Main script. please check it."
    }

}

Function GenerateCSprojectFile(){
    Param(
        [String]$iconPath
    )

    If([string]::IsNullOrEmpty($iconPath)){
        # set default icon for the application

    }
    Else
    {
        # we use the con provided by the user
    }

    $directoryInfProject = ".\Project\Resources\directory.inf"
    If(Test-path($directoryInfProject)){
        Write-Host "Found the project structure. Contructing C# project file ..."
        $ResourceFiles = Get-Content $directoryInfProject
        $arrayElement = ($ResourceFiles | Measure-Object).Count
    }
    Else
    {
        Write-Host "No directory information found. Aborting process."
    }


    If ($arrayElement -gt 0)
    {

        $XmlDoc = [System.Xml.XmlDocument]::new()
        $XmlDoc.load(".\Tools\Template\starter.csproj")

        # === Icon for the application ================================================================
        $XmlDoc.Project.PropertyGroup[2].ApplicationIcon = "Tool.icon"
        $XmlDoc.Project.ItemGroup[6].Content.Include = "Tool.ico"

        # === Embbeded resources ======================================================================
        $EmbbededResourceTag = $XmlDoc.Project.ItemGroup[4]
        # Remove current node in the template
        $EmbbededResourceTag.EmbeddedResource | ForEach-Object{ $_.ParentNode.Removechild($_) } | Out-Null
        # Append new elements 

        ForEach($file in $ResourceFiles)
        {
            if ($file -ne "\directory.inf") 
            {
                $resourceFile = "Resources" + $file
                $xmlchild = $XmlDoc.CreateElement("EmbeddedResource", "http://schemas.microsoft.com/developer/msbuild/2003")
                $xmlchild.SetAttribute("Include",$resourceFile)
                $EmbbededResourceTag.AppendChild($xmlchild) | Out-Null
            }
        }

        $XmlDoc.Save(".\Project\starter.csproj")

    }

}

Function GenerateProjectStructure(){
    Try{
        New-Item -path ".\Project" -name "bin" -type directory -ErrorAction Stop | Out-null
        New-Item -path ".\Project" -name "obj" -type directory -ErrorAction Stop | Out-null
        Copy-Item -Path ".\Tools\Template\App.config" -Destination ".\Project\App.config"
    }
    Catch {
        Write-Host "An error occured while genrating project structure."
    }
}

Function IsValidToolName(){
    Param(
        $toolName
    )
    $iRet = $true
    # TO DO

    return $iRet
}

Function IsvalidScriptName(){
    Param(
        $scriptName
    )
    $iRet = $true
    # TO DO
    return $iRet
}
     






