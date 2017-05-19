# Properties passed from command line
Properties {   
}

# Common variables
$ProjectRoot = $ENV:BHProjectPath
if (-not $ProjectRoot) {
    $ProjectRoot = $PSScriptRoot
}

$Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
$TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"
$lines = '----------------------------------------------------------------------'

# Tasks

Task Default -Depends Build

Task Init {
    $lines
    Set-Location $ProjectRoot
    "Build System Details:"
    Get-Item ENV:BH*
    "`n"
}

Task Test -Depends Init  {
    $lines
    $PSVersion = $PSVersionTable.PSVersion.Major
    "`n`tSTATUS: Testing with PowerShell $PSVersion"

    $TestResults = Invoke-Pester -Path $ProjectRoot\Tests -PassThru -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$TestFile"

    if ($ENV:BHBuildSystem -eq 'AppVeyor') {
        (New-Object 'System.Net.WebClient').UploadFile(
            "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
            "$ProjectRoot\$TestFile" )
    }

    Remove-Item "$ProjectRoot\$TestFile" -Force -ErrorAction SilentlyContinue

    if ($TestResults.FailedCount -gt 0) {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }
    "`n"
}

Task Build -Depends StaticCodeAnalysis, Test {
    $lines
    
    # Load the module, read the exported functions, update the psd1 FunctionsToExport
    Set-ModuleFunctions

    # Bump the module version
    Update-Metadata -Path $env:BHPSModuleManifest
}

Task StaticCodeAnalysis {
    if ($ENV:BHBuildSystem -eq 'AppVeyor') {
        Add-AppveyorTest -Name "PsScriptAnalyzer" -Outcome Running
    }
    $Results = Invoke-ScriptAnalyzer -Path $ProjectRoot -Recurse -Settings "$ProjectRoot\PPoShScriptingStyle.psd1"
    if ($Results) {
        $ResultString = $Results | Out-String
        Write-Warning $ResultString
        If($ENV:BHBuildSystem -eq 'AppVeyor') {
            Add-AppveyorMessage -Message "PSScriptAnalyzer output contained one or more result(s) with 'Error' severity.`
            Check the 'Tests' tab of this build for more details." -Category Error
            Update-AppveyorTest -Name "PsScriptAnalyzer" -Outcome Failed -ErrorMessage $ResultString
        }
         
        throw "Build failed"
    } 
    else {
        If ($ENV:BHBuildSystem -eq 'AppVeyor') {
            Update-AppveyorTest -Name "PsScriptAnalyzer" -Outcome Passed
        }
    }
}