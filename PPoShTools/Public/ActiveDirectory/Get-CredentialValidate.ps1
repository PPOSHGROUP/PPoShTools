function Get-CredentialValidate {
	<#
	.SYNOPSIS
    	Get domain credential.
    .DESCRIPTION
    	Get and check domain credential.
	.PARAMETER UserName
		Specify UserName.
	.PARAMETER Credential
		Specify Credential as PSCredential.
    .EXAMPLE
    	Get-CredentialValidate
		Get credential, check them and if correct pass them by.
    .EXAMPLE
    	Get-CredentialValidate -Verbose
		Show login and password on the screen.
		Get credential, check them and pass them by if correct.
   	.EXAMPLE
    	$Credentials = Get-Credential
    	Get-CredentialValidate -Credential $Credentials
		Check credential specify as parameter and if correct pass them by.
  #>

	[CmdletBinding(PositionalBinding = $false)]
	[OutputType([PSCredential])]
	param
	(
		[Parameter()]
		[System.String]$UserName = "$env:USERDOMAIN\$env:USERNAME",
		[Parameter()]
		[System.Management.Automation.PSCredential]$Credential,
		[Parameter()]
		[System.String]$Message = 'Please provide credential:'
	)

	Add-Type -AssemblyName System.DirectoryServices.AccountManagement

	if (-not $Credential) {
		Write-Verbose -Message 'Getting credential...'
		$Credential = Get-Credential -Message $Message -UserName $UserName
		$Password = $Credential.GetNetworkCredential().Password
	}

	#Checking if user exist by taking login from Credential
	if ($Credential) {
		$UserName = $Credential.UserName

		if ($UserName -like '*\*') {
			$DomainNetBIOS = $UserName.Split('\')[0]
			$Server = (Get-ADDomain $DomainNetBIOS).PDCEmulator

			$SamAccountName = $UserName.Split('\')[-1]
		} elseif ($UserName -like '*@*') {
			$DomainNetBIOS = $UserName.Split('@')[1]
			$Server = (Get-ADDomain $DomainNetBIOS).PDCEmulator

			$SamAccountName = $UserName.Split('@')[0]
		} else {
			$DomainNetBIOS = $env:USERDNSDOMAIN
			$Server = (Get-ADDomain $DomainNetBIOS).PDCEmulator

			$SamAccountName = $UserName
		}

		if ($DomainFQDN = (Get-ADDomain $DomainNetBIOS).DNSRoot) {
			Write-Verbose -Message "Fully qualified domain name found: '$DomainFQDN'"
		} else {
			$errMsg = "Fully qualified domain name of '$DomainNetBIOS' was found."
			Throw $errMsg
		}

		Write-Verbose -Message "Checking login: $SamAccountName, in domain: $DomainNetBIOS at server: $Server"

		if (Get-ADUser -Filter {
				SamAccountName -eq $SamAccountName
			} -Server $Server) {
			Write-Verbose -Message "Login $SamAccountName exist in $DomainNetBIOS"
		} else {
			$errMsg = "Login $SamAccountName doesn't exist in $DomainNetBIOS domain."
			Throw $errMsg
		}
	} else {
		$errMsg = 'No valid credential.'
		Throw $errMsg
	}

	#Checking Credential and doing loop if false
	do {
		Write-Verbose -Message 'Checking credential...'

		if ((-not $Check -and $Credential -and -not $Password) -and $DomainADSI) {
			Write-Verbose -Message 'Getting credential (password was empty)...'
			$UserName = $UserName
			$Credential = Get-Credential -Message 'Provide correct credential (password was empty):' -UserName $UserName
		} elseif ((-not $Check -and $Credential) -and $DomainADSI) {
			Write-Verbose -Message 'Getting credential (no valid login or password)...'
			$UserName = $UserName
			$Credential = Get-Credential -Message 'Provide correct credential (no valid login or password):' -UserName $UserName
		} else {
			Write-Verbose -Message 'Credential arguments provided (not empty).'
		}

		Write-Verbose -Message 'Validating...'

		$DomainADSI = "LDAP://" + $DomainFQDN
		$UserName = $Credential.UserName
		$Password = $Credential.GetNetworkCredential().Password
		$Check = (New-Object System.DirectoryServices.DirectoryEntry($DomainADSI, $UserName, $Password)).distinguishedName
	} while ( -not $Check -or -not $Password )

	Write-Verbose -Message "Login: $UserName, Password: $Password"

	$Credential
}
