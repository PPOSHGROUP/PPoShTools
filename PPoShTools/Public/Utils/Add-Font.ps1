function Add-Font {
  <#
      #requires -Version 2.0
      .SYNOPSIS
      This will install Windows fonts.

      .DESCRIPTION
      Requries Administrative privileges. Will copy fonts to Windows Fonts folder and register them.

      .PARAMETER Path
      May be either the path to a font file to install or the path to a folder containing font files to install.
      Valid file types are .fon, .fnt, .ttf,.ttc, .otf, .mmm, .pbf, and .pfm

      .EXAMPLE
      Add-Font -Path Value
      Will get all font files from provided folder and install them in Windows.

      .EXAMPLE
      Add-Font -Path Value
      Will install provided font in Windows.


  #>



  [CmdletBinding(DefaultParameterSetName='Directory')]
  Param(
    [Parameter(Mandatory=$false,
      ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
    [Parameter(ParameterSetName='Directory')]
    [ValidateScript({Test-Path $_ -PathType Container })]
    [System.String[]]
    $Path,

    [Parameter(Mandatory=$false,
      ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
      [Parameter(ParameterSetName='File')]
    [ValidateScript({Test-Path $_ -PathType Leaf })]
    [System.String]
    $FontFile
  )

  begin {
    Set-Variable Fonts -Value 0x14 -Option ReadOnly
    $fontRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

    $shell = New-Object -ComObject Shell.Application
    $folder = $shell.NameSpace($Fonts)
    $objfontFolder = $folder.self.Path
    $copyOptions = 4+16
    $copyFlag = [string]::Format("{0:x}",$copyOptions)
  }

  process {
    switch ($PsCmdlet.ParameterSetName) {
      "Directory" {
        ForEach ($fontsFolder in $Path){
        Write-Log -Info -Message "Processing folder {$fontsFolder}"
        $fontFiles = Get-ChildItem -Path $fontsFolder -File -Recurse -Include @("*.fon", "*.fnt", "*.ttf","*.ttc", "*.otf", "*.mmm", "*.pbf", "*.pfm")
       }
      }
      "File" {
        $fontFiles = Get-ChildItem -Path $FontFile -Include @("*.fon", "*.fnt", "*.ttf","*.ttc", "*.otf", "*.mmm", "*.pbf", "*.pfm")
      }
    }
    if ($fontFiles) {
      foreach ($item in $fontFiles) {
        Write-Log -Info -Message "Processing font file {$item}"
        if(Test-Path (Join-Path -Path $objfontFolder -ChildPath $item.Name)) {
          Write-Log -Info -Message "Font {$($item.Name)} already exists in {$objfontFolder}"
        }
        else {
          Write-Log -Info -Message "Font {$($item.Name)} does not exists in {$objfontFolder}"
          Write-Log -Info -Message "Reading font Full Name  {$($item.Name)}"

          $objFontCollection =  new-object System.Drawing.Text.PrivateFontCollection
          $objFontCollection.AddFontFile($item.FullName)
          $FontName = $objFontCollection.Families.Name

          Write-Log -Info -Message "Font Full Name is {$FontName}"
          Write-Log -Info -Message "Copying Font {$($item.Name)} to system Folder {$objfontFolder}"
          $folder.CopyHere($item.FullName, $copyFlag)

          if (-not ( Get-ItemProperty -Path $fontRegistryPath -name *$FontName*)) {
            New-ItemProperty -Name $FontName -Path $fontRegistryPath -PropertyType string -Value $item.Name
            Write-Log -Info -Message "Registering Font {$item} in Registry"
          }
        }
      }
    }
  end {
  }
}
