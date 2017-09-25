function Test-Online {
  <#
      .Synopsis
      Checks if given names/IP addresses are available.

      .DESCRIPTION
      It uses WMI to test connectivity to given names/IP addresses.

      .EXAMPLE
      Test-Online 8.8.8.8

      Address                 : 8.8.8.8
      ProtocolAddress         : 8.8.8.8
      ProtocolAddressResolved : google-public-dns-a.google.com
      ResponseTime            : 27
      Timeout                 : 2000

      .EXAMPLE
      Test-Online someHost1,someHost2

      Address                 : someHost1
      ProtocolAddress         : 10.2.6.49
      ProtocolAddressResolved : someHost1.contoso.com
      ResponseTime            : 1
      Timeout                 : 2000

      Address                 : someHost2
      ProtocolAddress         : 10.2.6.50
      ProtocolAddressResolved : someHost2.contoso.com
      ResponseTime            : 0
      Timeout                 : 2000

      .EXAMPLE
      Test-Online someHost3,someHost4 -ResolveAddressNames:$false -Timeout 1000
      Address                 : someHost4
      ProtocolAddress         : 10.2.6.91
      ProtocolAddressResolved :
      ResponseTime            : 1
      Timeout                 : 1000

      Address                 : someHost3
      ProtocolAddress         :
      ProtocolAddressResolved :
      ResponseTime            :
      Timeout                 : 1000

      .EXAMPLE
      $comps = (get-adcomputer -filter *).where({$_.name -match 'someHost'}).name
      Test-Online $comps | format-table

      Address                      ProtocolAddress              ProtocolAddressResolved                     ResponseTime                     Timeout
      -------                      ---------------              -----------------------                     ------------                     -------
      someHost4                   10.2.6.91                    someHost4.contoso.com                           1                        2000
      someHost2                                                                                                                                2000
      someHost3                   10.2.4.1                     someHost3.contoso.com                           3                        2000
      someHostTEST0                                                                                                                            2000
      someHost3
      2000
  #>

  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWMICmdlet', '')]
  [cmdletbinding()]
  [OutputType([PSObject])]
  Param(
    #Name/IP to check
    [Parameter(Mandatory=$true,Position=0)]
    [String[]]
    $Address,

    #Timeout
    [Parameter(Mandatory=$false)]
    [Int32]
    $Timeout = 2000,

    #Resolve IP to DNS names
    [Parameter(Mandatory=$false,HelpMessage="Resolve IP to DNS names")]
    [Boolean]
    $ResolveAddressNames = $true
  )
  begin{
    if($Address.Count -eq 1) {
      $filter = "Address=""$Address"" and Timeout=$Timeout and ResolveAddressNames=$ResolveAddressNames"
    }
    elseif ($Address.Count -gt 1) {
      $filter = 'Address="' + ($Address -join """ and Timeout=$Timeout and ResolveAddressNames=$ResolveAddressNames or Address=""") + """ and Timeout=$Timeout and ResolveAddressNames=$ResolveAddressNames"
    }
    if($filter) {
      Write-Log -Info -Message "Filter used is {$filter}"
    }
    else {
      Write-Log -Error  -Message 'Filter is empty. Names parsed incorrectly'
      break
    }
  }
  process{
    Get-WmiObject -Class Win32_PingStatus -Filter $filter |  Select-Object  -Property Address, ProtocolAddress,ProtocolAddressResolved, ResponseTime, Timeout
  }
  end{
  }
}