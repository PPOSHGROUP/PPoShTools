function Add-ToLocalGroup {
    <#
    .SYNOPSIS
    Adds a user or a group to local administrators of a remote computer

    .PARAMETER ComputerName
    Destination computer name where to add user or group (Identity parameter).

    .PARAMETER Group
    Destination local group the Identity should be added to.

    .PARAMETER DomainName
    Domain name - required for user/group string creation. Can be a workgroup or local computer name instead of domain name.

    .PARAMETER Type
    Type of identity to add - user or group.

    .PARAMETER Identity
    Identity of a user/group to add. Provide samaccountname

    .EXAMPLE
    This will add 'someuser' to 'somecomputer' as local administrator for default domain Objectivity
    Add-ToLocalGroup -ComputerName 'somecomputer' -Group Administrators -Type User -Identity 'someuser'
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidDefaultValueForMandatoryParameter', '')]
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true,HelpMessage='Destination Computer name')]
        [string[]]
        $ComputerName='localhost',

        [Parameter(Mandatory=$true,HelpMessage='Local Group to add Identity to')]
        [string]
        $Group,

        [Parameter(Mandatory=$false,HelpMessage='Domain or workgroup name')]
        [string]
        $DomainName,

        [Parameter(Mandatory=$true,HelpMessage='Type of Identity to add')]
        [ValidateSet('User', 'Group')]
        [string]
        $Type,

        [Parameter(Mandatory=$true,HelpMessage='Identity to add')]
        [string]
        $Identity
   )

    $LocalGroup = [ADSI]"WinNT://$ComputerName/$Group,group"
    if ($Type -eq 'Group') {
        $addgroup = [ADSI]"WinNT://$DomainName/$Identity,group"
        $LocalGroup.Add($addgroup.Path)
    } elseif ($Type -eq 'User') {
        $addUser = [ADSI]"WinNT://$DomainName/$Identity,user"
        $LocalGroup.Add($addUser.Path)
    }

    Write-Log -Info "Added {$Identity} Type {$Type} to local group {$Group} on {$Computername}"

}
