##############################
# Kevin RAHETILAHY
# DEV4SYS
##############################


# Include all other function
."Scripts\Core.ps1"

# Initialize the location of the executing script
$CurrentFolder  = (Get-Location).Path



Main -exeName "test" -mainScript "form.ps1" -projectDirectory $CurrentFolder

