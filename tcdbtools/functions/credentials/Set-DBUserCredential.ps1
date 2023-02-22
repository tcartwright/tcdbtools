function Set-DBUserCredential {
    <#
    .SYNOPSIS
        Saves a user credential to the Windows Credential Manager that can be retried later, and passed in to functions that require credentials.

    .DESCRIPTION
        Saves a user credential to the Windows Credential Manager that can be retried later, and passed in to functions that require credentials.
        Should be run to store the credentials, but not saved into a script. That way you can keep from storing passwords into your scripts.

        Removal of credentials can be done by accessing the Credential Manager UI from windows.

    .NOTES
        Credentials can also be created directly using the Credential Manager under: Windows Credentials --> Generic Credentials

    .PARAMETER ApplicationName
        The application name the credentials will be saved under.

    .PARAMETER UserName
        The user name for the credential.

    .PARAMETER Credentials
        The password for the credential.

    .OUTPUTS

    .EXAMPLE
        PS>Set-DBUserCredential -ApplicationName "myappname" -UserName "user" -Password "password"

    .EXAMPLE
        Use the alias of the function:

        PS>New-DBUserCredential -ApplicationName "myappname" -UserName "user" -Password "password"

    .LINK
        https://github.com/tcartwright/tcdbtools

    .LINK
        https://support.microsoft.com/en-us/windows/accessing-credential-manager-1b5c916a-6a16-889f-8581-fc16e8165ac0#:~:text=Credential%20Manager%20lets%20you%20view,select%20Credential%20Manager%20Control%20panel.

    .NOTES
        Author: Tim Cartwright
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification='Must be a string')]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ApplicationName,
        [Parameter(Mandatory=$true)]
        [string]$UserName,
        [Parameter(Mandatory=$true)]
        [string]$Password
    )

    begin {

    }

    process {
        [CredManager.Util]::SetUserCredential($ApplicationName, $UserName, $Password)
    }

    end {

    }
}

