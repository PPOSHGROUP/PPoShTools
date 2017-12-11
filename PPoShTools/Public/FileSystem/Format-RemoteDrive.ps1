function Format-RemoteDrive {
  <#
      .SYNOPSIS
      Formats all RAW drives on a remote system.

      .DESCRIPTION
      Using Invoke-Command will connect to remote system (ComputerName) and will format all RAW drives with given properties

      .PARAMETER ComputerName
      Name of a remote system to connect to using Invoke-Command.

      .PARAMETER NewFileSystemLabel
      Drive label (i.e. "MyData") for all drives to be formatted.

      .PARAMETER FileSystem
      FileSystem to be choosen for drives (ReFS and NTFS available)

      .PARAMETER Credential
      Alternate credentials to use to connect to ComputerName

      .EXAMPLE
      Format-RemoteDrive -ComputerName SomeServer -NewFileSystemLabel DATA -FileSystem ReFS -Credential (Get-Credential)
      Will connect to SomeServer using given credentials and will format all RAW drives to ReFS with DATA label

  #>


  [CmdletBinding()]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
  [OutputType([void])]

  Param(
    [Parameter(Mandatory=$True,
      ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]
    $ComputerName,

    [Parameter(Mandatory=$false,
      ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [string]
    $NewFileSystemLabel,

    [Parameter(Mandatory=$false,
      ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
    [ValidateSet('NTFS','ReFS')]
    [string]
    $FileSystem,

    [Parameter(Mandatory=$false,
      ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [System.Management.Automation.CredentialAttribute()]
    $Credential
  )

  Begin{
  }

  Process{

    Write-Log -Info -Message "Processing computer {$ComputerName}"
    $ConnectProps = @{
      ComputerName = $ComputerName
    }
    if($PSBoundParameters.ContainsKey('Credential')) {
      Write-Log -Info -Message "Credential {$($Credential.UserName)} will be used to connect to computer {$ComputerName}"
      $ConnectProps.Credential = $Credential
    }

    Write-Log -Info -Message "Creating PSSession to computer {$ComputerName}"
    $pssession = New-PSSession @ConnectProps

    Write-Log -Info -Message "Checking if there are any not initialized disks on {$ComputerName}"
    $rawDisks = Invoke-Command -Session $pssession -ScriptBlock {
      get-disk | Where-Object {$_.PartitionStyle -eq 'RAW'}
    }
    if($rawDisks) {
      if($rawDisks.count){
        Write-Log -Info -Message "Found #{$($rawDisks.Count)} raw disks on {$ComputerName}"
      }
      else {
        Write-Log -Info -Message "Found #{1} raw disk on {$ComputerName}"
      }
      Write-Log -Info -Message "Processing disks on {$ComputerName}"
      Invoke-Command -Session $pssession -ScriptBlock {
          $driveLetter = (get-disk | Where-Object {$_.PartitionStyle -eq 'RAW'} | Initialize-Disk  -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize ).DriveLetter
          $result = Format-Volume -NewFileSystemLabel $USING:NewFileSystemLabel -FileSystem $USING:FileSystem -DriveLetter $driveLetter -Force -confirm:$false
          $result
        }
      }

    Write-Log -Info -Message "Removing PSSession to Computer {$($pssession.ComputerName)}"
    $pssession | Remove-PSSession
  }


  End {
  }
}