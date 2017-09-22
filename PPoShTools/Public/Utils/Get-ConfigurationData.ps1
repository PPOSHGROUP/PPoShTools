function Get-ConfigurationData {
  <#
      .SYNOPSIS
      Get-ConfigurationData will retrieve configuratin depending on the input

      .DESCRIPTION
      Currently JSON files are integrated.
      Using ConvertTo-HashtableFromJSON will return configuration data from json file

      .PARAMETER ConfigurationPath
      Path to JSON file

      .EXAMPLE
      Get-ConfigurationData -ConfigurationPath C:\SomePath\Config.json -OutputType HashTable
      Will read content of Config.json file and convert it to a HashTable.

      .EXAMPLE
      Get-ConfigurationData -ConfigurationPath C:\SomePath\Config.json -OutputType PSObject
      Will read content of Config.json file and convert it to a PS Object.

      .INPUTS
      Accepts string as paths to JSON files

      .OUTPUTS
      Outputs a hashtable of key/value pair or PSObject based on JSON file
  #>

  [CmdletBinding()]
  [OutputType([Hashtable])]
  param (
    [Parameter(Mandatory = $true,
        Position = 0, HelpMessage = 'Provide path for configuration file to read')]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf })]

    [string[]]
    $ConfigurationPath,

    [Parameter(Mandatory = $true,
        Position = 0, HelpMessage = 'Select output type')]
        [ValidateSet('PSObject','HashTable')]
    [string]
    $OutputType='HashTable'


  )
  process {
    foreach ($configPath in $ConfigurationPath) {
        if($configPath -match '.json') {
            if($PSBoundParameters.ContainsValue('HashTable')){
              (ConvertTo-HashtableFromJSON -Path $configPath)
            }
            elseif($PSBoundParameters.ContainsValue('PSObject')){
              (ConvertTo-PSObjectFromJSON -Path $configPath)
            }
        }
    }
  }
}