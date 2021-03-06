
#########################################################################
# Author:  Kevin RAHETILAHY                                             #   
# Blog: dev4sys.com                                             #
#########################################################################

#########################################################################
#                        Add shared_assemblies                          #
#########################################################################


[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null


[System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\assembly\MahApps.Metro.dll")      | out-null  
[System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\assembly\ControlzEx.dll") | out-null
[System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\assembly\Microsoft.Xaml.Behaviors.dll") | out-null
[System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\assembly\MahApps.Metro.IconPacks.dll") | out-null
[System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\assembly\MahApps.Metro.IconPacks.MaterialDesign.dll") | out-null
[System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\assembly\MahApps.Metro.IconPacks.Core.dll") | out-null
[System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\assembly\dev4sys.Tree.dll")      | out-null 


#########################################################################
#                        Load Main Panel                                #
#########################################################################

#$Global:pathPanel= split-path -parent $MyInvocation.MyCommand.Definition
$Global:pathPanel= $PSScriptRoot


function LoadXaml ($filename){
    $XamlLoader=(New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}

$XamlMainWindow=LoadXaml($pathPanel+"\form.xaml")
$reader = (New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Form = [Windows.Markup.XamlReader]::Load($reader)

#########################################################################
#                        HAMBURGER VIEWS                                #
#########################################################################

#******************* Target View  *****************

$HamburgerMenuControl = $Form.FindName("HamburgerMenuControl")

$ConfigurationView  = $Form.FindName("ConfigurationView") 
$AdvancedView       = $Form.FindName("AdvancedView")
$VersioningView     = $Form.FindName("VersioningView") 

# $ProjectSettings ="" ; 
# {Define a XML where all the files and compilation will be done}


#******************************************************* 
# Include all other function
#*******************************************************
."Scripts\Core.ps1"
."Scripts\Project.ps1"


#******************* Load Other Views  *****************
$viewFolder = $pathPanel +"\views"

$XamlChildWindow    = LoadXaml($viewFolder+"\Configuration.xaml")
$Childreader        = (New-Object System.Xml.XmlNodeReader $XamlChildWindow)
$ConfigurationXaml  = [Windows.Markup.XamlReader]::Load($Childreader)

$XamlChildWindow    = LoadXaml($viewFolder+"\Advanced.xaml")
$Childreader        = (New-Object System.Xml.XmlNodeReader $XamlChildWindow)
$AdvancedXaml       = [Windows.Markup.XamlReader]::Load($Childreader)

$XamlChildWindow    = LoadXaml($viewFolder+"\Versioning.xaml")
$Childreader        = (New-Object System.Xml.XmlNodeReader $XamlChildWindow)
$VersioningXaml     = [Windows.Markup.XamlReader]::Load($Childreader)
    
$ConfigurationView.Children.Add($ConfigurationXaml) | Out-Null
$AdvancedView.Children.Add($AdvancedXaml)           | Out-Null    
$VersioningView.Children.Add($VersioningXaml)       | Out-Null      

# Initialize with the first childwindow the pane
$HamburgerMenuControl.SelectedItem = $HamburgerMenuControl.ItemsSource[0]



$BuildActionBtn  = $Form.FindName("TargetBuild")
$CleanActionBtn  = $Form.FindName("TargetClean")
$CreateProject  = $Form.FindName("CreateProject")



$BuildActionBtn.IsEnabled = $false
$CleanActionBtn.IsEnabled = $false


$ConsoleOutput  = $Form.FindName("ConsoleOutput")



#########################################################################
#                       FOLDER BROWSER                                  #
#########################################################################

Function Get-FolderDialog($text)
{

    $foldername = [System.Windows.Forms.FolderBrowserDialog]::New()
    $foldername.Description = "$text"
    $foldername.rootfolder = "MyComputer"

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }
    return $folder
}

#########################################################################
#                       CONFIGURATIONS PANE                             #
#########################################################################

$ConfTxtBoxPath     =  $ConfigurationXaml.FindName("ConfTxtBoxPath")
$ConfBtnPath        =  $ConfigurationXaml.FindName("ConfBtnPath")
$ConfExeName        =  $ConfigurationXaml.FindName("ConfExeName")
$ConfSingleInstance =  $ConfigurationXaml.FindName("ConfSingleInstance")
$ConfPs1Name        =  $ConfigurationXaml.FindName("ConfPs1Name")
$ConfUserProjectPath =  $ConfigurationXaml.FindName("ConfUserProjectPath")
$ConfBtnUserPsPath =  $ConfigurationXaml.FindName("ConfBtnUserPsPath")

$outputProjetFolder = "$env:ALLUSERSPROFILE\Temp"


$ConfBtnUserPsPath.Add_Click({

    $inputUserFolder = Get-FolderDialog("Select output folder")
    $script:UserPowershellProjectFolder = $inputUserFolder
    $ConfUserProjectPath.Text = $inputUserFolder
    PopulateTreeView -SourcePath $inputUserFolder
    
})

$ConfBtnPath.Add_Click({
    $outputProjetFolder = Get-FolderDialog("Select output folder")
    $script:UserOutputProjectFolder = $outputProjetFolder
    $ConfTxtBoxPath.Text = $outputProjetFolder
})


#########################################################################
#                       ADVANCED PANE                                   #
#########################################################################





$CreateProject.Add_Click({

    
    $canProceed = $false

    $source      = $Script:UserPowershellProjectFolder
    $destination = $Script:UserOutputProjectFolder

    try{
    if((Test-Path $source) -and (Test-Path $destination) ){
    
        [string]$sourceDirectory  = "$source\*"
        [string]$destinationDirectory = "$destination\Resources"

        $ConsoleOutput.Text += "Creating resources folder in project ... `n"

        New-Item -ItemType directory -Path $destinationDirectory
        Copy-item -Force -Recurse $sourceDirectory -Destination $destinationDirectory 
    
        $ConsoleOutput.Text += "Resources folder created successfully ... `n"

        $canProceed = $true


    }
    }catch
    {
        $ConsoleOutput.Text += "An error occured. Error:  $($_.Exception.Message) `n "
    }


    $exeName = $ConfExeName.Text
    $mainScript = $ConfPs1Name.Text
    $singleInstance = $ConfSingleInstance.IsChecked

    $version = $VerTxtExeVersion.Text
    $companyName = $VerTxtBoxCompany.Text

    if($canProceed)
    {
        $ConsoleOutput.Text += "Starting process for $exeName  ...  `n"
        $ConsoleOutput.Text += "Using as main script: $mainScript `n" 
        $ConsoleOutput.Text += "Tool version: $version `n" 
    

        # Initialize the location of the executing script
        #$CurrentFolder  = "E:\TEST\TOTO"
        #Main -exeName "TOTO" -mainScript "Main.ps1" -$singleInstance $false -projectDirectory $CurrentFolder -companyName "ACME" -version "2.1.3.0"

        BuildFlatSources -exeName $exeName -mainScript $mainScript -singleInstance $singleInstance `            -projectDirectory $destination -companyName $companyName -version $version             
        $ConsoleOutput.Text += "Flat sources created ... `n"

        $BuildActionBtn.IsEnabled = $true
        $CleanActionBtn.IsEnabled = $true

    }


})




$BuildActionBtn.Add_Click({

    $ConsoleOutput.Text += "Building Project ... `n "
    Run -action "Build" -projectPath $Script:UserOutputProjectFolder

    $ConsoleOutput.Text += "Finished `n"


})

$CleanActionBtn.Add_Click({

    $ConsoleOutput.Text += "Cleaning Project ... `n "
    $Script:result = Run -action "Clean" -projectPath $Script:UserOutputProjectFolder

    $ConsoleOutput.Text += "$Script:result.stdout `n"
    $ConsoleOutput.Text += "$Script:result.ExitCode `n"

})


Function BuildFlatSources(){
    
    Param(
        [String]$exeName,
        [String]$mainScript,
        [bool]$singleInstance,
        [String]$projectDirectory,
        [String]$companyName,
        [String]$version
    )

    Write-Host "Starting process for $exeName  ... "
    Write-Host "Using as main script: $mainScript" 
    Write-Host "Tool version: $version" 

    GenerateProjectStructure -CurrentProjectFolder $projectDirectory
    $retVal = GenerateDirectoryInf -CurrentProjectFolder $projectDirectory
    If(!$retVal){
        Write-Host "An error ocurred while processing your application files."
    }

    GenerateProgramCs -toolName $exeName -mainScript $mainScript -mutex $singleInstance -CurrentProjectFolder $projectDirectory
    GenerateAssemblyInfoCs -toolName $exeName -companyName $companyName -version $version -CurrentProjectFolder $projectDirectory 
    GenerateCSprojectFile -CurrentProjectFolder $projectDirectory



}



#########################################################################
#                       VERSION PANE                                   #
#########################################################################

$VerTxtExeVersion = $VersioningXaml.FindName("VerTxtExeVersion")
$VerTxtBoxCompany = $VersioningXaml.FindName("VerTxtBoxCompany")


#########################################################################
#                        HAMBURGER EVENTS                               #
#########################################################################

# /************  equals to OnItemInvoked of MAhapps lib in C# *********/

$HamburgerMenuControl.add_ItemInvoked({
    
   $HamburgerMenuControl.Content = $_.InvokedItem
   $HamburgerMenuControl.IsPaneOpen = $false

})


#########################################################################
#                       HANDLING TREEVIEW PROJECT                       #
#########################################################################

$Script:FolderTree  = $Form.FindName("TreeView")
$script:dummyNode   = $null

function PopulateTreeView () {
    param (
        [String]$SourcePath
    )
    # Source path corrsponds to the folde rpath of project source files
    # they will be copied inside the "Project folder when selected by the user."

    Try {
        $AllFiles  = [IO.Directory]::GetFiles($SourcePath)
        $AllDirectory = [IO.Directory]::GetDirectories($SourcePath)
    }
    catch {
        Write-Host "No such file or folder found. Exception: $($_.Exception.Message)"
    }
    
    # ================== Handle Folders ===========================
    foreach ($folder in $AllDirectory){

        $treeViewItem = [Windows.Controls.TreeViewItem]::new()
        $treeViewItem.Header = $folder.Substring($folder.LastIndexOf("\") + 1)
        $treeViewItem.Tag = @("folder",$folder)
        $treeViewItem.Items.Add($dummyNode) | Out-Null
        $treeViewItem.Add_Expanded({
            Write-Host $_.OriginalSource.Header  " is expanded"
            TreeExpanded($_.OriginalSource)
        })
        $FolderTree.Items.Add($treeViewItem)| Out-Null

    }

    # ================== Handle Files ===========================
    foreach ($file in $AllFiles){

        $treeViewItem = [Windows.Controls.TreeViewItem]::new()
        $treeViewItem.Header = $file.Substring($file.LastIndexOf("\") + 1)
        $treeViewItem.Tag = @("file",$file) 
        $FolderTree.Items.Add($treeViewItem)| Out-Null

        $treeViewItem.Add_PreviewMouseLeftButtonDown({
            [System.Windows.Controls.TreeViewItem]$sender = $args[0]
            #[System.Windows.RoutedEventArgs]$e = $args[1]
            Write-Host "Left Click: $($sender.Tag)"
        })

        $treeViewItem.Add_PreviewMouseRightButtonDown({
            [System.Windows.Controls.TreeViewItem]$sender = $args[0]
            #[System.Windows.RoutedEventArgs]$e = $args[1]
            Write-Host "Right Click: $($sender.Tag)"
        })

    }

}

Function TreeExpanded($sender){
    
    $item = [Windows.Controls.TreeViewItem]$sender
    If ($item.Items.Count -eq 1 -and $item.Items[0] -eq $dummyNode)
    {
        $item.Items.Clear();
        Try
        {
            
            foreach ($string in [IO.Directory]::GetDirectories($item.Tag[1].ToString()))
            {
                $subitem = [Windows.Controls.TreeViewItem]::new();
                $subitem.Header = $string.Substring($string.LastIndexOf("\") + 1)
                $subitem.Tag = @("folder",$string)
                $subitem.Items.Add($dummyNode)
                $subitem.Add_Expanded({
                    TreeExpanded($_.OriginalSource)
                })
                $item.Items.Add($subitem) | Out-Null
            }

            foreach ($file in [IO.Directory]::GetFiles($item.Tag[1].ToString())){
                $subitem = [Windows.Controls.TreeViewItem]::new()
                $subitem.Header = $file.Substring($file.LastIndexOf("\") + 1)
                $subitem.Tag = @("file",$file) 
                $item.Items.Add($subitem)| Out-Null

                $subitem.Add_PreviewMouseLeftButtonDown({
		            [System.Windows.Controls.TreeViewItem]$sender = $args[0]
		            #[System.Windows.RoutedEventArgs]$e = $args[1]
		            Write-Host "Left Click: $($sender.Tag)"
	            })

	            $subitem.Add_PreviewMouseRightButtonDown({
		            [System.Windows.Controls.TreeViewItem]$sender = $args[0]
		            #[System.Windows.RoutedEventArgs]$e = $args[1]
		            Write-Host "Right Click: $($sender.Tag)"
	            })

            }

        }   
        Catch [Exception] { }
    }
     
}

#########################################################################
#                    PROJECT SOURCES DRAG & DROP                        #
#########################################################################

$ProjectSources = $Form.FindName("ProjectSources")
$ProjectSources.AllowDrop = $True

$ProjectSources.Add_PreviewDragOver({
    [System.Object]$script:sender = $args[0]
    [System.Windows.DragEventArgs]$e = $args[1]

    $e.Effects = [System.Windows.DragDropEffects]::Move
    $e.Handled = $true
})

$ProjectSources.Add_Drop({

    [System.Object]$script:sender = $args[0]
    [System.Windows.DragEventArgs]$e = $args[1]

    If($e.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)){

        $Folder =  $e.Data.GetData([System.Windows.DataFormats]::FileDrop)
        #Write-Host "Folder Count is: " + $Folder.Length

        $Script:UserPowershellProjectFolder = $Folder

        If($Folder.Length -eq 1){

            $FolderTree.Items.Clear()
            # Fill the treeview with the content of the folder
            PopulateTreeView -SourcePath $Folder 

        }Else{
            # show user error message
            $okOnly = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative 
            [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Form,"EXE Compiler","Please select/drop a valid folder. ",$okOnly)
    
        }

    }

})

#########################################################################
#                        Show Dialog                                    #
#########################################################################

$Form.ShowDialog() | Out-Null
  
