# Import the Active Directory module for AD operations
Import-Module ActiveDirectory

# Define the security group parameters such as name, category, scope, SAM account name, email, OU, and SamAccountName
$groupName = "MyGroup"
$groupCategory = "Security"
$groupScope = "Global"
$groupSAMAccountName = $groupName
$groupEmail = $groupName+"@domain.com"
$OU = "OU=YourGroupFolder,DC=YOURDOMAIN,DC=com"
$userSAMAccountNames = @("user1", "user2", "user3") # Replace this with the actual users' SAM Account Names

# Check if the group exists in the Active Directory
$group = Get-ADGroup -Filter { Name -eq $groupName } -Properties mail

if ($group) {
    # If the group exists, check if it's mail enabled
    if ($group.mail -eq $null) {
        # If the group is not mail enabled, enable it
        Set-ADGroup -Identity $group.DistinguishedName -Add @{mail=$groupEmail}
        Write-Host "ENABLING: Group '$groupName' is now mail enabled." -ForegroundColor Green
    } else {
        # If the group is already mail enabled, skip this step
        Write-Host "SKIPPING: Group '$groupName' is already mail enabled." -ForegroundColor Yellow
    }
} else {
    # If the group doesn't exist, create it
    New-ADGroup -Name $groupName -GroupCategory $groupCategory -GroupScope $groupScope -SamAccountName $groupSAMAccountName -Path $OU -OtherAttributes @{'mail'=$groupEmail}
    Write-Host "ENABLING: Group '$groupName' created and mail enabled." -ForegroundColor Green
    # Refresh the $group variable after creating the group
    $group = Get-ADGroup -Filter { Name -eq $groupName } -Properties mail
}

# The users to be added to the group

foreach ($userSAMAccountName in $userSAMAccountNames) {
    try {
        # Check if the user exists in the Active Directory
        $user = Get-ADUser -Filter { SamAccountName -eq $userSAMAccountName }
        if ($user) {
            # If the user exists, check if they are already a member of the group
            $groupMembers = Get-ADGroupMember -Identity $group.DistinguishedName | Select-Object -ExpandProperty SamAccountName
            if ($user.SamAccountName -in $groupMembers) {
                # If the user is already a member of the group, skip this step
                Write-Host "  ADDING: User  '$userSAMAccountName' already exists in the group '$groupName'." -ForegroundColor Yellow
            } else {
                # If the user is not a member of the group, add them
                Add-ADGroupMember -Identity $group.DistinguishedName -Members $user.SamAccountName
                Write-Host "ADDING: User  '$userSAMAccountName' added to group '$groupName'." -ForegroundColor Green
            }
        } else {
            # If the user doesn't exist, skip this step
            Write-Host "SKIPPING: User  '$userSAMAccountName' does not exist in AD." -ForegroundColor Yellow
        }
    } catch {
        # If there's an error, write the error message
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}