
#########################################################################
# Author:  Kevin RAHETILAHY                                             #   
# Blog: dev4sys.blogspot.fr                                             #
#########################################################################

#########################################################################
#                        Add shared_assemblies                          #
#########################################################################

[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
[System.Reflection.Assembly]::LoadFrom('assembly\System.Windows.Interactivity.dll') | out-null
[System.Reflection.Assembly]::LoadFrom('assembly\MahApps.Metro.dll')      | out-null  
[System.Reflection.Assembly]::LoadFrom('assembly\dev4sys.Tree.dll')      | out-null 

#########################################################################
#                        Load Main Panel                                #
#########################################################################

$Global:pathPanel= split-path -parent $MyInvocation.MyCommand.Definition

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

# Initialize the location of the executing script
$CurrentFolder  = "E:\TEST\TOTO"

#Main -exeName "TOTO" -mainScript "Main.ps1" -$singleInstance $false -projectDirectory $CurrentFolder -companyName "ACME" -version "2.1.3.0"



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

#########################################################################
#                       CONFIGURATIONS PANE                             #
#########################################################################

$ConfTxtBoxPath     =  $ConfigurationXaml.FindName("ConfTxtBoxPath")
$ConfBtnPath        =  $ConfigurationXaml.FindName("ConfBtnPath")
$ConfExeName        =  $ConfigurationXaml.FindName("ConfExeName")
$ConfSingleInstance =  $ConfigurationXaml.FindName("ConfSingleInstance")

#########################################################################
#                       ADVANCED PANE                                   #
#########################################################################
$ConfBtnPath.Add_Click({

    Write-Host $ConfExeName.Text
    Write-Host $ConfSingleInstance.IsChecked
    $ConfTxtBoxPath.Text = "PATH"
    Write-Host $VerTxtExeVersion.Text
    Write-Host $VerTxtBoxCompany.Text
    
})

#########################################################################
#                       VERSION PANE                                   #
#########################################################################

$VerTxtExeVersion = $VersioningXaml.FindName("VerTxtExeVersion")
$VerTxtBoxCompany = $VersioningXaml.FindName("VerTxtBoxCompany")


#########################################################################
#                        HAMBURGER EVENTS                               #
#########################################################################

$HamburgerMenuControl.add_ItemClick({
    
   $HamburgerMenuControl.Content = $HamburgerMenuControl.SelectedItem
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

        $Script:Files =  $e.Data.GetData([System.Windows.DataFormats]::FileDrop)
        Write-Host "File length is: " + $Files.Length

        If($Files.Length -eq 1){

            $FolderTree.Items.Clear()
            # Fill the treeview with the content of the folder
            PopulateTreeView -SourcePath $Files 

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
  
