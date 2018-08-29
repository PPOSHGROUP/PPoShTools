function New-PSSessionCustom {
  <#
      .SYNOPSIS
      Creates PS Session object depends on parameters passed

      .DESCRIPTION
      Accepts ComputerName, Credentials and ConfigurationName as parameters to create PS Session. If no credentials are given, current credentials are used.

      .PARAMETER ComputerName
      Computer name of the nodes where the PS Session will be established.

      .PARAMETER Credential
      A PSCredential object that will be used when opening a remoting session to any of the $Nodes specified.

      .PARAMETER ConfigurationName
      PowerShell Configuration name to use (JEA).

      .PARAMETER SessionName
      Custom Name for PSSession

      .EXAMPLE
      New-PSSessionCustom -ComputerName 'SomeServer' -Credential (Get-Credential) -SessionName
      Will use {SomeDomain\SomeUser} to create PSSession to computer {SomeServer}
      Created PSSession to computer {SomeServer}
      ```
      Id Name            ComputerName    ComputerType    State         ConfigurationName     Availability
      -- ----            ------------    ------------    -----         -----------------     ------------
      5 WinRM5          SomeServer      RemoteMachine   Opened        Microsoft.PowerShell     Available
      ```

      .OUTPUTS
      Will output PSSession object
  #>

  [CmdletBinding()]
  [OutputType([System.Management.Automation.Runspaces.PSSession])]
  param(
    [Parameter(Mandatory=$true)]
    [string]
    $ComputerName,

    [Parameter(Mandatory=$false)]
    [System.Management.Automation.PSCredential]
    $Credential,

    [Parameter(Mandatory=$false)]
    [string]
    $ConfigurationName,

    [Parameter(Mandatory=$false)]
    [string]
    $SessionName

  )
  process {
    $sessionParams = @{
      ComputerName = $ComputerName
    }
    if($PSBoundParameters.ContainsKey('ConfigurationName')){
      $sessionParams.ConfigurationName = $ConfigurationName
    }
    if($PSBoundParameters.ContainsKey('SessionName')){
      $sessionParams.Name = $SessionName
    }
    if($PSBoundParameters.ContainsKey('Credential')){
      $sessionParams.Credential = $Credential
      Write-Log -Info -Message "Will use {$($Credential.UserName)} to create PSSession to computer {$($sessionParams.ComputerName)}"
    }
    else{
      Write-Log -Info -Message "Will use current user Credential {$($ENV:USERNAME)} to create PSSession to computer {$($sessionParams.ComputerName)}"
    }
    $Session = New-PSSession @sessionParams -ErrorAction SilentlyContinue
    if ($Session) {
      Write-Log -Info -Message "Created PSSession to computer {$($Session.ComputerName)}"
    }
    else {
      Write-Log -Error -Message "Unable to create PSSession to computer {$($Session.ComputerName)}. Aborting!"
      break
    }
    $Session
  }
}