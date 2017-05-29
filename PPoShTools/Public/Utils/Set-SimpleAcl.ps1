function Set-SimpleAcl {
    <#
    .SYNOPSIS
    Sets a simple ACL rule for given Path.
            
    .DESCRIPTION
    Returns true if an access rule has been added. False if it was already present.

    .EXAMPLE
    Set-SimpleAcl -Path 'c:\test' -User 'Everyone' -Permission 'FullControl' -Type 'Allow'
    #>
    
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidDefaultValueSwitchParameter', '')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        $User,

        [Parameter(Mandatory=$true)]
        [string]
        [ValidateSet('FullControl', 'Modify', 'ReadAndExecute', 'ListDirectory', 'Read', 'Write')]
        $Permission,

        [Parameter(Mandatory=$true)]
        [string]
        [ValidateSet('Allow', 'Deny')]
        $Type,

        [Parameter(Mandatory=$false)]
        [switch]
        $Inherit = $true

    ) 

    # see http://stackoverflow.com/questions/7984876/powershell-how-to-get-whatif-to-propagate-to-cmdlets-in-another-module :(
    $whatIf = Test-WhatIf

    if (!(Test-Path -Path $Path)) {
        if ($PSCmdlet.ShouldProcess('Directory', "Add permission '$Permission' to item '$Path' (if it exists) for user '$User'") -and !$whatIf) {
            throw "Item '$Path' does not exist."
        }
        return $true
    }

    $acl = (Get-Item -Path $path).GetAccessControl('Access')

    if ($Inherit) {
        $inheritArg = @([System.Security.AccessControl.InheritanceFlags]::ContainerInherit,[System.Security.AccessControl.InheritanceFlags]::ObjectInherit)
    } 
    else {
        $inheritArg = @([System.Security.AccessControl.InheritanceFlags]::None)
    }

    $userRegex = $User -replace '\\', '\\'
    $existingEntry = $acl.Access.Where({ $_.IdentityReference.Value -imatch $userRegex -and $_.FileSystemRights -imatch $Permission -and $_.AccessControlType -ieq $Type })
    if ($existingEntry -and $existingEntry.InheritanceFlags -eq $inheritArg) {
        Write-Log -_Debug "ACL on '$Path' already matches desired value ('$Type' user '$User', permission '$Permission', inherit $Inherit)"
        return $false
    }

    $propagation = [System.Security.AccessControl.PropagationFlags]::None

    if ($PSCmdlet.ShouldProcess('Directory', "Add permission '$Permission' to item '$Path' for user '$User'") -and !$whatIf) {
        Write-Log -Info "Setting ACL on '$Path' - '$Type' user '$User', permission '$Permission', inherit $Inherit"
        $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $User, $Permission, $inheritArg, $propagation, $Type

        $acl.AddAccessRule($accessRule)
        Set-Acl -Path $Path -AclObject $acl
    }
    return $true
}