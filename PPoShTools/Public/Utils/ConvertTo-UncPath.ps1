function ConvertTo-UncPath {
	<#
		.SYNOPSIS
			A simple function to convert a local file path and a computer name to a network UNC path.
		.PARAMETER LocalFilePath
			A file path ie. C:\Windows\somefile.txt
		.PARAMETER Computername
            One or more computers in which the file path exists on
        .EXAMPLE
        ConvertTo-UncPath -LocalFilePath 'c:\adminTools\SomeFolder' -ComputerName 'SomeRemoteComputer'
        \\SomeRemoteComputer\c$\adminTools\SomeFolder
        .EXAMPLE
        ConvertTo-UncPath -LocalFilePath 'c:\adminTools\SomeFolder' -ComputerName 'SomeRemoteComputer','SomeAnotherComputer'
        \\SomeRemoteComputer\c$\adminTools\SomeFolder
        \\SomeAnotherComputer\c$\adminTools\SomeFolder
        .OUTPUTS
        Will create a string for remote computer path
	#>
    [CmdletBinding()]
    [OutputType([String])]
	param (
        [Parameter(Mandatory=$true,
            ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
		[string]$LocalFilePath,

        [Parameter(Mandatory=$true,
            ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
		[string[]]$ComputerName
	)
	process {
		try {
			foreach ($Computer in $ComputerName) {
				$RemoteFilePathDrive = ($LocalFilePath | Split-Path -Qualifier).TrimEnd(':')
				"\\$Computer\$RemoteFilePathDrive`$$($LocalFilePath | Split-Path -NoQualifier)"
			}
		}
		catch {
			Write-Log -Error -Message $_.Exception.Message
		}
	}
}