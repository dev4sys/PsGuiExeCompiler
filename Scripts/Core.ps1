##############################
# Kevin RAHETILAHY
# DEV4SYS
##############################


# Initialize the location of the executing script
$CurrentFolder  = (Get-Location).Path


Function GenerateDirectoryInf(){
    # ====================== Description ======================================
    # This function get the list of file and directory to be stored
    # It will be used to recreate the souce structure form emmbeded resources. 
    # =========================================================================

    
    $FileLIst = Get-ChildItem -Path $CurrentFolder -file -recurse | % { if ($_.PsIsContainer) { $_.FullName + "\" } else { $_.FullName } }
    $RelativePathList = $FileLIst.Replace("$CurrentFolder","")
 
    $RelativePathList | Out-File ".\directory.inf"


}


Function Main(){
    
    Param(
        [String]$exeName,
        [String]$mainScript,
        [String]$outPutPath,
        [String]$workingDirectory
    )

    $iRet = $False


    
   
    Start-Process


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


Function EditProgramCs(){
    # ====================== Description =====================================
    # This function update the content of program.cs before build
    # ========================================================================

    Param(
        [String]$toolName,
        [String]$MainScript
    )

    # replace the toolName 
    if(IsValidToolName($toolName)){

    }

    # indicate the main script to execute 
    if(IsvalidScriptName($toolName)){
    
    }

}

Function IsValidToolName(){
    Param(
        $toolName
    )
    $iRet = $False
    # TO DO
    return $iRet
}


Function IsvalidScriptName(){
    Param(
        $scriptName
    )
    $iRet = $False
    # TO DO
    return $iRet
}
     






