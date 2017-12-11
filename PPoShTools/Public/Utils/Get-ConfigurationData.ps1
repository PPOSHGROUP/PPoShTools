function Get-ConfigurationData {
  <#
      .SYNOPSIS
      Get-ConfigurationData will retrieve configuratin depending on the input

      .DESCRIPTION
      Currently JSON (.json) and PowerShell Data (.psd1) are supported.
      For JSON files possible output is hashtable (default) and PSObject.
      For PSD1 files only PSObject is currently supported.
      Using helpers function will return an object data from given configuration file

      .PARAMETER ConfigurationPath
      Path to JSON or psd1 file

      .EXAMPLE
      Get-ConfigurationData -ConfigurationPath C:\SomePath\Config.json -OutputType HashTable
      Will read content of Config.json file and convert it to a HashTable.

      .EXAMPLE
      Get-ConfigurationData -ConfigurationPath C:\SomePath\Config.json -OutputType PSObject
      Will read content of Config.json file and convert it to a PS Object.

      .EXAMPLE
      Get-ConfigurationData -ConfigurationPath C:\SomePath\Config.psd1
      Will read content of Config.psd1 file and return it as a PS Object.

      .INPUTS
      Accepts string as paths to JSON or PSD1 files

      .OUTPUTS
      Outputs a hashtable of key/value pair or PSObject.
  #>

  [CmdletBinding()]
  [OutputType([Hashtable])]
  param (
    [Parameter(Mandatory = $true, HelpMessage = 'Provide path for configuration file to read', Position = 0 )]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf })]

    [string[]]
    $ConfigurationPath,

    [Parameter(Mandatory = $false, HelpMessage = 'Select output type',Position = 0)]
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
        if($configPath -match '.psd1') {
          Import-LocalizedData -BaseDirectory (Split-Path $ConfigurationPath -Parent) -FileName (Split-Path $ConfigurationPath -Leaf)
        }
    }
  }
}