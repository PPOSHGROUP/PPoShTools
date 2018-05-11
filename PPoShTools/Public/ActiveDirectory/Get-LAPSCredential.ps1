function Get-LAPSCredential {
    <#
    .SYNOPSIS
    Retrieves LAPS password from AD and creates Credential Object
    .DESCRIPTION
    Using Local Administrator Password Solution cmdlet Get-AdmPwdPassword will query AD for ms-Mcs-AdmPwd attribute. Will use retrieved password to create Credential Object
    .PARAMETER ComputerName
    ComputerName to search for LAPS password
    .EXAMPLE
    Get-LAPSCredential -ComputerName 'SomeComputer'
    UserName                                  Password
    --------                                  --------
    SomeComputer\Administrator System.Security.SecureString
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True,
            ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [string]
        $ComputerName
    )
    Process {
        Write-Log -Info -Message "Retrieving LAPS Password for Computer {$ComputerName}"
        $LAPSPassword = Get-AdmPwdPassword -ComputerName $ComputerName -ErrorAction SilentlyContinue
        If ($LAPSPassword) {
            Write-Log -Info -Message "Found LAPS Password for Computer {$ComputerName}"
            $LocalAdminPassword = ConvertTo-SecureString -String $LAPSPassword -AsPlainText -Force
            $LocalAdminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "$ComputerName\Administrator", $LocalAdminPassword
            Write-Log -Info -Message "Returning created Credential Object {$($LocalAdminCredential.UserName)}"
            $LocalAdminCredential
        }
        Else {
            Write-Log -Error  -Message "No LAPS password found for computer {$ComputerName}"
            $Null
        }
    }
}