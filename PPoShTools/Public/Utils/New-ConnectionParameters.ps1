function New-ConnectionParameters {
    <#
    .SYNOPSIS
    Creates an universal connection parameters object that can be conveniently used for opening connections.

    .DESCRIPTION
    It returns following hashtable:
    ```
    @{
        Nodes = <array of nodes>
        NodesAsString = <nodes in string format>
        RemotingMode = <RemotingMode>
        Credential = <Credential>
        Authentication = <Authentication>
        Port = <Port>
        Protocol = <Protocol>
        PSSessionParams = <hashtable that can be used for splatting in Invoke-Command>
        CimSessionParams = <hashtable that can be used for splatting in New-CimSession>
        MsDeployDestinationString = <string that can be used for opening msdeploy connections>
        OptionsAsString = <string describing all options for logging purposes>
    }
    ```

    .PARAMETER Nodes
    Names of remote nodes where the connection will be established.

    .PARAMETER RemotingMode
    Defines type of remoting protocol to be used for remote connection. Available values:
    - **PSRemoting** (default)
    - **WebDeployHandler** - https://<server>:<8172>/msdeploy.axd
    - **WebDeployAgentService** - http://<server>/MsDeployAgentService

    .PARAMETER Credential
    A PSCredential object that will be used when opening a remoting session to any of the $Nodes specified.

    .PARAMETER Authentication
    Defines type of authentication that will be used to establish remote connection. Available values:
    - **Basic**
    - **NTLM**
    - **CredSSP**
    - **Default** (default)
    - **Digest**
    - **Kerberos**
    - **Negotiate**
    - **NegotiateWithImplicitCredential**

    .PARAMETER Port
    Defines the port used for establishing remote connection.

    .PARAMETER Protocol
    Defines the transport protocol used for establishing remote connection (HTTP or HTTPS). Available values:
    - **HTTP** (default)
    - **HTTPS**

    .PARAMETER CrossDomain
    Should be on when destination nodes are outside current domain.

    .EXAMPLE
    New-ConnectionParameters -Nodes server1
    #>
    
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory=$false)]
        [string[]]
        $Nodes,

        [Parameter(Mandatory=$false)]
        [ValidateSet('PSRemoting', 'WebDeployHandler', 'WebDeployAgentService')]
        [string]
        $RemotingMode = 'PSRemoting',

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential] 
        $Credential,

        [Parameter(Mandatory=$false)]
        [ValidateSet($null, 'Basic', 'NTLM', 'Credssp', 'Default', 'Digest', 'Kerberos', 'Negotiate', 'NegotiateWithImplicitCredential')]
        [string]
        $Authentication,

        [Parameter(Mandatory=$false)]
        [string]
        $Port,

        [Parameter(Mandatory=$false)]
        [string]
        [ValidateSet($null, 'HTTP', 'HTTPS')]
        $Protocol,

        [Parameter(Mandatory=$false)]
        [switch]
        $CrossDomain
    )

    if ($RemotingMode -eq 'PSRemoting') {
        $psRemotingParams = @{}
        if ($Nodes) {
            $psRemotingParams['ComputerName'] = $Nodes
        }
        if ($Authentication -and $Nodes) {
            $psRemotingParams['Authentication'] = $Authentication
        }

        if ($Credential) {
            $psRemotingParams['Credential'] = $Credential
            # if we have Credentials, we need to have ComputerName (to properly select parameter set in Invoke-Command)
            if (!$Nodes) {
                $psRemotingParams['ComputerName'] = 'localhost'
            }
        }

        if ($Port) {
            $psRemotingParams['Port'] = $Port
        }

        if ($Protocol -eq 'HTTPS') {
            $psRemotingParams['UseSSL'] = $true
            $psRemotingParams['SessionOption'] = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
        }

        $cimSessionParams = @{}
        if ($Nodes) {
            $cimSessionParams['ComputerName'] = $Nodes
        }
        if ($Authentication) {
            $cimSessionParams['Authentication'] = $Authentication
        }
        #$params['SkipTestConnection'] = $true

        if ($Credential) {
            $cimSessionParams['Credential'] = $Credential
        }

        if ($Port) {
            $cimSessionParams['Port'] = $Port
        }

        if ($Protocol -eq 'HTTPS') {
            $cimSessionParams['SessionOption'] = New-CimSessionOption -UseSsl -SkipCACheck -SkipCNCheck -SkipRevocationCheck
        }
    } 
    else {
         if ($Nodes.Count -ne 1) {
            throw "Only one node can be specified for RemotingMode = $RemotingMode."
         }
         if ($RemotingMode -eq "WebDeployHandler") {
            if (!$Port) {
                # default port
                $Port = '8172'
            }
            if ($Protocol -eq 'HTTP') {
                $urlProtocol = 'http'
            } 
            else {
                $urlProtocol = 'https'
            }
            $url = "{0}://{1}:{2}/msdeploy.axd" -f $urlProtocol, $Nodes[0], $Port
        } 
        else {
            if (!$Port) {
                # default port
                $Port = '80'
            }
            if ($Protocol -eq 'HTTPS') {
                $urlProtocol = 'https'
            } 
            else {
                $urlProtocol = 'http'
            }
            $url = "{0}://{1}:{2}/MsDeployAgentService" -f $urlProtocol, $Nodes[0], $Port
        }
        $msDeployDestinationStringParams = @{ Url = $url; Offline = $false }

        if ($Credential) {
            $msDeployDestinationStringParams.Add("UserName", $Credential.UserName)
            $msDeployDestinationStringParams.Add("Password", $Credential.GetNetworkCredential().Password)
        }

        if ($Authentication) {
            $msDeployDestinationStringParams.Add("AuthType", $Authentication)
        }
        $msDeployDestinationString = New-MsDeployDestinationString @msDeployDestinationStringParams
    }

    return @{
        Nodes = @($Nodes)
        NodesAsString = @($Nodes) -join ','
        RemotingMode = $RemotingMode
        Credential = $Credential
        Authentication = $Authentication
        Port = $Port
        Protocol = $Protocol
        CrossDomain = $CrossDomain
        PSSessionParams = $psRemotingParams
        CimSessionParams = $cimSessionParams
        MsDeployDestinationString = $msDeployDestinationString
        OptionsAsString = "Credential: '$($Credential.UserName)', RemotingMode: '$RemotingMode', Auth: '$Authentication', Protocol: '$Protocol', Port: '$Port'"
    }
}