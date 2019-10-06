#Requires -Modules Pester
[CmdletBinding()]
param (
    [PSCredential]$Credential = $NextcloudCredential,
    [string]$Server = $NextcloudServer
)
if ($env:AGENT_NAME) {
    $Credential = [Management.Automation.PSCredential]::new('$(NextcloudUser)', (ConvertTo-SecureString '$(NextcloudPassword)' -AsPlainText -Force))
    $Server = '$(NextcloudServer)'
}
else {
    if (!$Credential) {
        $Credential = $Global:NextcloudCredential = Get-Credential
    }
    if (!$Server) {
        $Server = $Global:NextcloudServer = Read-Host -Prompt 'Nextcloud Server'
    }
}

Describe 'Users' {
    $UserIdAdmin = $Credential.UserName
    $UserIdTest1 = "{0}-{1}-Test1" -f $UserIdAdmin, $(if ($env:System_JobDisplayName) { $env:System_JobDisplayName } else { 'Local' })
    It 'Connect-NextcloudServer' {
        Connect-NextcloudServer -Server $Server -Credential $Credential | Should -BeNullOrEmpty
    }
    It 'Get-NextcloudUser' {
        $User = Get-NextcloudUser -UserID $UserIdAdmin
        $User.id | Should -Be $UserIdAdmin
    }
    It 'Add-NextcloudUser' {
        try {
            Remove-NextcloudUser -UserID $UserIdTest1
        }
        catch {
            Write-Verbose $_
        }
        Add-NextcloudUser -UserID $UserIdTest1 -Password New-Guid | Should -BeNullOrEmpty
        (Get-NextcloudUser -UserID $UserIdTest1).id | Should -Be $UserIdTest1

        { Add-NextcloudUser -UserID $UserIdTest1 -Password New-Guid } | Should -Throw -ExpectedMessage 'User already exists'
    }
    It 'Get-NextcloudUsers' {
        $Users = Get-NextcloudUser
        $Users.id | Should -Contain $UserIdAdmin
        $Users.id | Should -Contain $UserIdTest1
    }
    It 'Set-NextcloudUser' {
        Set-NextcloudUser -UserID $UserIdTest1 -Email 'me@example.com' | Should -BeNullOrEmpty
        (Get-NextcloudUser -UserID $UserIdTest1).email | Should -Be 'me@example.com'
    }
    It 'Remove-NextcloudUser' {
        Remove-NextcloudUser -UserID $UserIdTest1 | Should -BeNullOrEmpty
        { Remove-NextcloudUser -UserID $UserIdTest1 } | Should -Throw -ExpectedMessage '101'
        Get-NextcloudUser -UserID $UserIdTest1 | Should -BeNullOrEmpty
    }
}