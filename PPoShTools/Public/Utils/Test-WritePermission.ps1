function Test-WritePermission {
  <#
    .SYNOPSIS
    Tests if it's possible to create file in given location (path)

    .DESCRIPTION
    Creates a random file in given location. Deletes if it was created. Returns Boolean True or False

    .PARAMETER Path
    Location where test write should occur

    .EXAMPLE
    Test-WritePermission -Path c:\SomePath
    Will create random file in given location. Will return True or False

    .INPUTS
    Path to test

    .OUTPUTS
    Boolean True or False
  #>

  [cmdletbinding()]
  [OutputType([Boolean])]

  Param(
  [Parameter(Mandatory,HelpMessage='Provide path where to test write possibility')]
  [ValidateScript({Test-Path -Path $_ -IsValid -PathType Container})]
  [string[]]
  $Path
  )

  foreach ($testPath in $Path)
  {
    $testFileName = "TestFile_{0}" -f (Get-Date -Format 'yyyyMMddHHss')
    $testfile = New-Item -Path $testPath -Name $testFileName -ItemType File -ErrorAction SilentlyContinue
    if (-not $testfile) {
      Write-Log -Error -Message "Unable to write in Path {$testPath}. Verify your permissions."
      $false
      break
    }
    else {
      Remove-Item -Path $testfile -Force
      $true
    }
  }
}