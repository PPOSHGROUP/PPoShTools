function ConvertTo-PSObjectFromJSON {
  #requires -Version 3.0
  <#
      .SYNOPSIS
      Retrievies json file from disk and converts to hashtable.

      .DESCRIPTION
      Reads file given as Path parameter and using ConvertTo-HashtableFromPsCustomObject converts it to a hashtable.

      .PARAMETER Path
      Path to a json file.

      .EXAMPLE
      ConvertTo-PSObjectFromJSON -Path c:\somefile.json
      Will read somefile.json and convert it to custom psobject.

      .INPUTS
      Path to a json file (string).

      .OUTPUTS
      Custom PS Object.
  #>



    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
         [Parameter(Mandatory = $true,
             Position = 0,HelpMessage='Path to json file',
             ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
         [ValidateScript({Test-Path -Path $_ -PathType 'Leaf' -Include '*.json' })]
         [string]
         $Path
     )

  Process{
    Write-Log -Info -Message "Reading configuration file from {$Path}"
    $content = Get-Content -LiteralPath $path -ReadCount 0 -Raw | Out-String
    $pscustomObject = ConvertFrom-Json -InputObject $content
    Write-Log -Info -Message "Returning parsed configuration object"
    $pscustomObject
  }
}


