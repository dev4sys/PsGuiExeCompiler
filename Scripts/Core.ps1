##############################
# Kevin RAHETILAHY
# DEV4SYS
##############################



Function Main(){
    
    Param(
        [String]$exeName,
        [String]$mainScript,
        [String]$outPutPath,
        [bool]$singleInstance,
        [String]$projectDirectory,
        [String]$companyName,
        [String]$version
    )

    $iRet = $False

    Write-Host "Starting process for $exeName  ... "
    Write-Host "Using as main script: $mainScript" 
    Write-Host "Tool version: $version" 

    GenerateProjectStructure -CurrentProjectFolder $projectDirectory
    $retVal = GenerateDirectoryInf -CurrentProjectFolder $projectDirectory

    GenerateProgramCs -toolName $exeName -mainScript $mainScript -mutex $singleInstance -CurrentProjectFolder $projectDirectory
    GenerateAssemblyInfoCs -toolName $exeName -companyName $companyName -version $version -CurrentProjectFolder $projectDirectory 
    
    GenerateCSprojectFile -CurrentProjectFolder $projectDirectory

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
       
           # $cmdLine =  ".\MSBuild\15.0\Bin\MSBuild.exe .\Socle\starter.csproj /target:Build /tv:4.0"
       
        }
        "Clean" { 

           # $cmdLine =  ".\MSBuild\15.0\Bin\MSBuild.exe .\Socle\starter.csproj /target:Clean"
       
        }
    }   

}

Function GenerateDirectoryInf(){

    # ====================== Description ======================================
    # This function get the list of file and directory to be stored
    # It will be used to recreate the souce structure form emmbeded resources. 
    # =========================================================================
    Param(
        [String]$CurrentProjectFolder        
    )
    
    $iRet = $true
    $resourcesDirectory = "$CurrentProjectFolder\Resources"
    # extension to be exclude in the project for later ...
    # $filter = ""

    Try{
        Write-Host "Project directory info out: $CurrentProjectFolder\directory.inf"
        $FileLIst = Get-ChildItem -Path $resourcesDirectory -file -recurse -ErrorAction SilentlyContinue | ForEach-Object { if ($_.PsIsContainer) { $_.FullName + "\" } else { $_.FullName } }
        $RelativePathList = $FileLIst.Replace("$resourcesDirectory","")
        $RelativePathList | Out-File "$CurrentProjectFolder\directory.inf"
    }
    Catch{
        $iRet = $False
        Write-Host "An error occured. Error:  $($_.Exception.Message)"
    }

    return $iRet

}


Function GenerateAssemblyInfoCs(){
    # ====================== Description =====================================
    # This function update the content of AssemblyInfo.cs before build
    # ========================================================================

    Param(
        [String]$companyName,
        [String]$toolName,
        [String]$version,
        [string]$CurrentProjectFolder
    )

    Write-Host "Found the project structure. Constructing C# AssemblyInfo ... "
    # Open and replace elements in the code from template
    $AssemblyInfoCs     = Get-content ".\Tools\Template\Properties\AssemblyInfo.cs"
    $TempFile           = $AssemblyInfoCs.Replace("%dev4sys%",$CompanyName)
    $TempFile           = $TempFile.Replace("1.0.0.0",$version)
    $AssemblyInfoCs     = $TempFile.Replace("%starter%",$toolName)

    # Export result to the current project folder
    $AssemblyInfoCs  | Set-Content "$CurrentProjectFolder\Properties\AssemblyInfo.cs"
    $TempFile    = $null

}

Function GenerateProgramCs(){
    # ====================== Description =====================================
    # This function update the content of program.cs before build
    # ========================================================================

    Param(
        [String]$toolName,
        [String]$mainScript,
        [bool]$mutex,
        [string]$CurrentProjectFolder
    )

    # %mainScript.ps1%
    # %toolName%
    $canProceed = (IsValidToolName($toolName) -and IsvalidScriptName($toolName))

    if($canProceed)
    {
        # Open and replace elements in the code from template
        $ProgramCSharp      = Get-content ".\Tools\Template\Program.cs"
        $TempCSharpName     = $ProgramCSharp.Replace("%toolName%",$toolName)
        $TempCSharpMutex    = $TempCSharpName.Replace("%mutex%",("$mutex").ToLower())
        $ProgramCSharp      = $TempCSharpMutex.Replace("%mainScript.ps1%",$mainScript)


        # Export result to the current project folder
        $ProgramCSharp  | Set-Content "$CurrentProjectFolder\Program.cs"
        $TempCSharpMutex    = $null
        $TempCSharpName     = $null
        
    }
    else
    {
        Write-Host "Incorrect parameter *ToolName or *Main script. please check it."
    }

}

Function GenerateCSprojectFile(){
    Param(
        [String]$iconPath,
        [string]$CurrentProjectFolder
    )

    If([string]::IsNullOrEmpty($iconPath)){
        # set default icon for the application

    }
    Else
    {
        # we use the con provided by the user
    }

    $directoryInfProject = "$CurrentProjectFolder\directory.inf"
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
        $XmlDoc.Project.PropertyGroup[2].ApplicationIcon = "Tool.ico"
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

        $XmlDoc.Save("$CurrentProjectFolder\starter.csproj")

    }

}

Function GenerateProjectStructure(){

    Param(
        [string]$CurrentProjectFolder
    )

    Try{
        If (!(Test-Path -Path "$CurrentProjectFolder\bin")){
            # suppose that if bin already exists do not create teh folder
            New-Item -path "$CurrentProjectFolder" -name "bin" -type directory -ErrorAction Stop | Out-null
            New-Item -path "$CurrentProjectFolder" -name "obj" -type directory -ErrorAction Stop | Out-null
            New-Item -path "$CurrentProjectFolder" -name "Properties" -type directory -ErrorAction Stop | Out-null
        }
        Copy-Item -Path ".\Tools\Template\App.config" -Destination "$CurrentProjectFolder\App.config"
        Copy-Item -Path ".\Tools\Template\Tool.ico" -Destination "$CurrentProjectFolder\Tool.ico"

        Write-Host "Successfully generated project structure."
    }
    Catch {
        Write-Host "An error occured while generating project structure. $($_.Exception.Message)"
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
     






