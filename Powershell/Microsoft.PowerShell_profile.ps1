
# Admin Check and Prompt Customization
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
function prompt {
    if ($isAdmin) { "[" + (Get-Location) + "] # " } else { "[" + (Get-Location) + "] $ " }
}
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()

# Utility Functions
function Test-CommandExists {
    param($command)
    $exists = $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
    return $exists
}

#### Recomend to Install oh-my-posh first #######################
Import-Module -Name Terminal-Icons
oh-my-posh init pwsh --config 'C:\Users\mfach\AppData\Local\Programs\oh-my-posh\themes\kushal.omp.json' | Invoke-Expression

# Editor Configuration
$EDITOR = if (Test-CommandExists nvim) { 'nvim' }
          elseif (Test-CommandExists pvim) { 'pvim' }
          elseif (Test-CommandExists vim) { 'vim' }
          elseif (Test-CommandExists vi) { 'vi' }
          elseif (Test-CommandExists code) { 'code' }
          elseif (Test-CommandExists notepad++) { 'notepad++' }
          elseif (Test-CommandExists sublime_text) { 'sublime_text' }
          else { 'notepad' }
Set-Alias -Name vim -Value $EDITOR

function Edit-Profile {
    vim $PROFILE
}
function touch($file) { "" | Out-File $file -Encoding ASCII }
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

# Network Utilities
function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }


# System Utilities
function admin {
    if ($args.Count -gt 0) {
        $argList = "& '$args'"
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    } else {
        Start-Process wt -Verb runAs
    }
}

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command with elevated rights.
Set-Alias -Name su -Value admin

function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem | Select-Object @{Name='LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}} | Format-Table -HideTableHeaders
    } else {
        net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
    }
}

function reload-profile {
    & $profile
}
function unzip ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}


function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

function ssh-copy-id
{
<#
.SYNOPSIS
    Appends a public key to a machines ~/.ssh/authorized_keys file.
    CAUTION: This script is not declarative, it will append key(s) into authorized_keys that already exist.
 
.DESCRIPTION
    ssh-copy-id is a PowerShell script that uses ssh to log into a remote machine and append the
    indicated identity file to that machine's ~/.ssh/authorized_keys file. By default, it installs the key(s) stored in "$env:USERPROFILE\.ssh\id_rsa.pub".
    CAUTION: This script is not declarative, it will append key(s) into authorized_keys that already exist.
 
.PARAMETER RemoteHost
    Specifies the IP or DNS name of the machine to install the public key on.
 
.PARAMETER RemoteUser
    Specifies which user's authorized_keys file that the key will be installed under.
     
.PARAMETER KeyFile
    A path of the keyfile to be installed.
 
.INPUTS
 
    None at the moment.
 
.OUTPUTS
 
    None at the moment.
 
.EXAMPLE
 
    PS> ssh-copy-id root@172.16.1.10
 
.EXAMPLE
 
    PS> ssh-copy-id 172.16.1.10 -l root
 
.EXAMPLE
 
    PS> ssh-copy-id root@172.16.1.10 -i C:\users\n8tg\SpecialKeyDir\key.pub
 
.EXAMPLE
 
    PS> ssh-copy-id -RemoteHost 172.16.1.10 -RemoteUser root
 
.EXAMPLE
 
    PS> ssh-copy-id -RemoteHost 172.16.1.10 -RemoteUser root -KeyFile C:\users\n8tg\SpecialKeyDir\key.pub
 
.NOTES
 
    If no username is supplied using -RemoteUser or the User@RemoteHost syntax, the user running the command's username will be used.
 
.LINK
 
https://github.com/n8tg/ssh-copy-id
#>


    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$false)]
        [string]
        $RemoteHost,

        [Alias('l')]
        [string]
        $RemoteUser,

        [Alias('i')]
        [string]
        $KeyFile = "$env:USERPROFILE\.ssh\mfachmie.pub"
    )  

    PROCESS {

        if($RemoteHost -contains "@"){
            $RemoteUser = $RemoteHost.Split("@")[0]
            $RemoteHost = $RemoteHost.Split("@")[1]
        }

        # Check key file is there
        if(!(Test-Path $KeyFile)) { Write-Warning "Specified key file not found"; return }
        
        try{
            if($RemoteUser){
                Get-Content $KeyFile | ssh $RemoteHost -l $RemoteUser "cd; umask 077; mkdir -p `".ssh/`" && { [ -z \`tail -1c .ssh/authorized_keys 2>/dev/null\` ] || echo >> .ssh/authorized_keys; } && cat >> .ssh/authorized_keys || exit 1; "
            }else{
                Get-Content $KeyFile | ssh $RemoteHost "cd; umask 077; mkdir -p `".ssh/`" && { [ -z \`tail -1c .ssh/authorized_keys 2>/dev/null\` ] || echo >> .ssh/authorized_keys; } && cat >> .ssh/authorized_keys || exit 1; "
            }
        } catch {
            Write-Warning "An error occurred when installing the key"
            Write-Host $_
        }
    }
}

#function ssh-copy-id($server) {
#   type $env:USERPROFILE\.ssh\id_rsa.pub | ssh $server "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
#}
function df {
    get-volume
}

function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
    Get-Process $name
}

function head {
  param($Path, $n = 10)
  Get-Content $Path -Head $n
}

function tail {
  param($Path, $n = 10, [switch]$f = $false)
  Get-Content $Path -Tail $n -Wait:$f
}

# Quick File Creation
function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }

# Directory Management
function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }

### Quality of Life Aliases

# Navigation Shortcuts
function docs { Set-Location -Path $HOME\Documents }

function dtop { Set-Location -Path $HOME\Desktop }

# Quick Access to Editing the Profile
function ep { vim $PROFILE }

# Simplified Process Management
function k9 { Stop-Process -Name $args[0] }

# Enhanced Listing
function la { Get-ChildItem -Path . -Force | Format-Table -AutoSize }
function ll { Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize }


# Quick Access to System Information
function sysinfo { Get-ComputerInfo }

# Networking Utilities
function flushdns {
	Clear-DnsClientCache
	Write-Host "DNS has been flushed"
}

# Clipboard Utilities
function cpy { Set-Clipboard $args[0] }

function pst { Get-Clipboard }

# Enhanced PowerShell Experience
#Set-PSReadLineOption -Colors @{
#   Command = 'Yellow'
#    Parameter = 'Blue'
#    String = 'DarkCyan'
#}

#$PSROptions = @{
#   ContinuationPrompt = '  '
#    Colors             = @{
#    Parameter          = $PSStyle.Foreground.Magenta
#    Selection          = $PSStyle.Background.Black
#    InLinePrediction   = $PSStyle.Foreground.BrightYellow + $PSStyle.Background.BrightBlack
#    }
#}
#Set-PSReadLineOption @PSROptions
#Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function ForwardWord
#Set-PSReadLineKeyHandler -Chord 'Enter' -Function ValidateAndAcceptLine

#$scriptblock = {
#    param($wordToComplete, $commandAst, $cursorPosition)
#    dotnet complete --position $cursorPosition $commandAst.ToString() |
#        ForEach-Object {
#            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
#        }
#}
# Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock


Set-Alias -Name ifconfig -Value ipconfig
Set-Alias -Name z -Value __zoxide_z -Option AllScope -Scope Global -Force
Set-Alias -Name zi -Value __zoxide_zi -Option AllScope -Scope Global -Force

# Help Function
function Show-Help {
    @"
PowerShell Profile Help
=======================
cpy 		- Copies the specified text to the clipboard.
SYNTAX : cpy <text> 

ssh-copy-id 	
EXAMPLE
	PS> ssh-copy-id 172.16.1.10 -l root
	PS> ssh-copy-id root@172.16.1.10 -i C:\users\n8tg\SpecialKeyDir\key.pub
	PS> ssh-copy-id -RemoteHost 172.16.1.10 -RemoteUser root
	PS> ssh-copy-id -RemoteHost 172.16.1.10 -RemoteUser root -KeyFile C:\users\n8tg\SpecialKeyDir\key.pub
	
df		- Displays information about volumes.
docs		- Changes the current directory to the user's Documents folder. "Path $HOME\Documents"
dtop		- Changes the current directory to the user's Desktop folder.	"Path $HOME\Desktop"
Edit-Profile	- Opens the current user's profile for editing using the configured editor.
ep		- Opens the profile for editing.
export		- Sets an environment variable.
SYNTAX : export <name> <value>

ff		- Finds files recursively with the specified name.
SYNTAX : ff <name> 	

flushdns	- Clears the DNS cache.
Get-PubIP	- Retrieves the public IP address of the machine.
grep		- Searches for a regex pattern in files within the specified directory or from the pipeline input.
SYNTAX : grep <regex> [dir] 	 			

head		- Displays the first n lines of a file (default 10).
SYNTAX : head <path> [n] 	

k9		- Kills a process by name.
SYNTAX : K9 <name> 				

la		- Lists all files in the current directory with detailed formatting.
lazyg		- Adds all changes, commits with the specified message, and pushes to the remote repository.
SYNTAX :lazyg <message>

ll		- Lists all files, including hidden, in the current directory with detailed formatting.
mkcd		- Creates and changes to a new directory.
SYNTAX : mkcd <dir>

nf		- Creates a new file with the specified name.
SYNTAX : nf <name> 			

pgrep		- Lists processes by name.
SYNTAX : pgrep <name> 		

pkill		- Kills processes by name.
SYNTAX : pkill <name> 		

pst		- Retrieves text from the clipboard.
reload-profile	- Reloads the current user's PowerShell profile.
sed		- Replaces text in a file.
SYNTAX : sed <file> <find> <replace> 

sysinfo		- Displays detailed system information.
tail		- Displays the last n lines of a file (default 10).
SYNTAX : tail <path> [n]

touch		- Creates a new empty file.
SYNTAX : touch	<file>

unzip		- Extracts a zip file to the current directory.
SYNTAX : unzip <file> 

Update-PowerShell- Checks for the latest PowerShell release and updates if a new version is available.
Update-Profile	- Checks for profile updates from a remote repository and updates if necessary.
uptime		- Displays the system uptime.
which		- Shows the path of the command.
SYNTAX : which <name>

Use 'Show-Help' to display this help message.

"@
}
Write-Host "Use 'Show-Help' to display help"
