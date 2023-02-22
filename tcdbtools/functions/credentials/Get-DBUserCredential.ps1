function Get-DBUserCredential {
    [OutputType([pscredential])]
    <#
    .SYNOPSIS
        Gets the credential stored under the application name.

    .DESCRIPTION
        Gets the credential stored under the application name.

    .PARAMETER ApplicationName
        The application name the credentials will be saved under.

    .OUTPUTS
        The credentials for the application name.

    .EXAMPLE
        PS>$credential = Get-DBUserCredential -ApplicationName "myappname"

    .LINK
        https://github.com/tcartwright/tcdbtools

    .LINK
        https://support.microsoft.com/en-us/windows/accessing-credential-manager-1b5c916a-6a16-889f-8581-fc16e8165ac0#:~:text=Credential%20Manager%20lets%20you%20view,select%20Credential%20Manager%20Control%20panel.

    .NOTES
        Author: Tim Cartwright
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ApplicationName
    )

    begin {
    }

    process {
        $credObject = [CredManager.Util]::GetUserCredential($ApplicationName)

        [SecureString]$securePassword = ConvertTo-SecureString ($credObject.password) -AsPlainText -Force
        [pscredential]$credentials = New-Object System.Management.Automation.PSCredential ($credObject.username, $securePassword)
        return $credentials
    }

    end {
    }
}
