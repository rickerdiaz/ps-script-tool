###
### DEPLOY WEB AND DB, UPDATE, PACK, REMOVE, CHANGE URL FOR CALCMENU WEB
###
### This script can be used to deploy a new CALCMENU Web, or Update a new one
###
### #2025-08-05
###
Function fctToolLatest {
param(
[Parameter(Mandatory=$True,Position=1)]$ProjectNameToDeploy,
[Parameter(Mandatory=$True,Position=2)]$DoApp,
[Parameter(Mandatory=$True,Position=3)]$DoApp2,
[Parameter(Mandatory=$True,Position=4)]$DOSql1,
[Parameter(Mandatory=$True,Position=5)]$DOSql2,
[Parameter(Mandatory=$True,Position=6)]$DOSql3,
[Parameter(Mandatory=$True,Position=7)]$DOSql4,
[Parameter(Mandatory=$True,Position=8)]$DOSql9,
[Parameter(Mandatory=$True,Position=9)]$DOPack,
[Parameter(Mandatory=$True,Position=10)]$DoUpdate,
[Parameter(Mandatory=$True,Position=11)]$DoRemoveWeb,
[Parameter(Mandatory=$True,Position=12)]$DoRemoveDb,
[Parameter(Mandatory=$True,Position=13)]$DoChangeUrl,
[Parameter(Mandatory=$True,Position=14)]$DOVersion,
[Parameter(Mandatory=$True,Position=15)]$DOVersionMain,
[Parameter(Mandatory=$True,Position=16)]$ConversionVersionToForcedStr,
[Parameter(Mandatory=$True,Position=17)]$UrlOrigin,
[Parameter(Mandatory=$True,Position=18)]$UrlReplacement,
[Parameter(Mandatory=$True,Position=19)]$DoUpdateClientLogo,
[Parameter(Mandatory=$True,Position=20)]$DoUpdateCmWebLogo,
[Parameter(Mandatory=$True,Position=21)]$DoUpdateKey,
[Parameter(Mandatory=$True,Position=22)]$DoCopyWeb,
[Parameter(Mandatory=$True,Position=23)]$DoCopyWebProjectNameSource,
[Parameter(Mandatory=$True,Position=24)]$DoHttpToHttps,
[Parameter(Mandatory=$True,Position=25)]$Silent,
[Parameter(Mandatory=$True,Position=26)]$AutoCreateDomain,
[Parameter(Mandatory=$True,Position=27)]$AutoDeployKey, 
[Parameter(Mandatory=$False)]$AutoQA,
[Parameter(Mandatory=$False)]$UpdateFolderKiosk,
[Parameter(Mandatory=$False)]$UpdateFolderKioskDb,
[Parameter(Mandatory=$False)]$DoRestoreWeb,
[Parameter(Mandatory=$False)]$DoRestoreWebFolder,
[Parameter(Mandatory=$False)]$DoRestoreWebPathcmwebCurrentSource,
[Parameter(Mandatory=$False)]$DoRestoreWebDataSourceIPSource,
[Parameter(Mandatory=$False)]$DoRestoreWebDataSourceIPTarget
) 
$VersionTool="33.28.00"
$DoIIS="0"
$CertificateThumbprint="496dcbe323eda7d7ee2738acbd6579944ac3e902" #"009b23c709775a01770a1c519e80703789758228" #"a5723ede652a70306d739ba6eca6ae02e51e8b7e" #"369f7eae88655f77f7b78526454311694683ac46" #"bac5d29d7dd1041c1cf26eb8404b4dede93947d2"
#

#
#$PSVersionTable
#Write-host "###########" -foregroundcolor Cyan
#Write-host "### EGS ###" -foregroundcolor Yellow
#Write-host "###########" -foregroundcolor Magenta
#If ($Silent -eq "1") {} else { cls }
#
#WHAT TO INSTALL? APPLICATION OR/AND DATABASE
<#
$DoApp = "0"          #Set to "1" if application should be installed
$DoApp2 = "0"         #Set to "1" if application should be backup and move to S3
$DOSql1 = "0"         #Set to "1" for download of latest DBs
$DOSql2 = "0"         #Set to "1" for unzipping and restoring of the database + login
$DOSql3 = "0"         #Set to "1" for database conversion
$DOSql4 = "0"         #Set to "1" for adjustments of database (language, users, etc.)
$DOSql9 = "0"         #Set to "1" for setting of backup for the database
$DOPack = "0"         #Set to "1" to create a pack with Application and Database (if available)
$DOUpdate = "0"       #Set to "1" to update an Application only  
$DoRemoveWeb = "0"    #Set to "1" to delete a website
$DoRemoveDb = "0"
$DoChangeUrl = "0"    #Set to "1 or 2" to make changes in the Url of a solution. 1=Normal to server, 2=Server to normal

#PARAMETERS
$DOVersion = "v1"     #Set to the folder version to install "v1", "v2", "v3", etc
$DOVersionMain = "2014"     #Set to the folder version to install "2014" or "2015"
#>
$DoChangePwd = "0"    #Set to "1 changes password of all users (with Code>0) with PasswordAdmin
#
If ($DoRestoreWeb -eq $null) { $DoRestoreWeb=0 }
#
If ($Silent -eq "") {$Silent="0"}
If ($AutoCreateDomain -eq "") {$AutoCreateDomain="1"}
If ($AutoDeployKey -eq "") {$AutoDeployKey="1"}
#
If ($DoCopyWeb -eq "") { $DoCopyWeb="0" }
If ($DoHttpToHttps -eq "") { $DoHttpToHttps="0" }
#
If (($DOVersion -eq "v1") -or ($DOVersion -eq "v2"))
{$VersionOfConfig=1 }
else
{$VersionOfConfig=2 } #Increase this whenever changes are made in web.config or other js files
#
#
$AwsExeFile="C:\Program Files\Amazon\AWSCLIV2\aws.exe"
"step2"
#
#-#$ProjectNameToDeploy="SHL"
#############################################################################################################
#############################################################################################################
#############################################################################################################
#############################################################################################################
#############################################################################################################
### FUNCTIONS
#############################################################################################################
#############################################################################################################
#############################################################################################################
#############################################################################################################
#############################################################################################################
#
# SCOPE: SEARCH A DIRECTORY FOR FILES (W/WILDCARDS IF NECESSARY)
# Usage:
# $directory = "\\SERVER\SHARE"
# $searchterms = "filname[*].ext"
# PS> $Results = Search $directory $searchterms

[reflection.assembly]::loadwithpartialname("Microsoft.VisualBasic") | Out-Null
#
Function pause ($message)
{
    # Check if running Powershell ISE
    if ($psISE)
    {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$message")
    }
    else
    {
        Write-Host "$message" -ForegroundColor Yellow
        $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}
#
Function Search {
  # Parameters $Path and $SearchString
  param ([Parameter(Mandatory=$true, ValueFromPipeline = $true)][string]$Path,
  [Parameter(Mandatory=$true)][string]$SearchString
  )
  try {
    #.NET FindInFiles Method to Look for file
    # BENEFITS : Possibly running as background job (haven't looked into it yet)

    [Microsoft.VisualBasic.FileIO.FileSystem]::GetFiles(
    $Path,
    [Microsoft.VisualBasic.FileIO.SearchOption]::SearchAllSubDirectories,
    $SearchString
    )
  } catch { $_ }

}
#
Function ExecuteScript {
    Param (
        [string] $ScriptFileName,
        [string] $ScriptPath,
        [string] $NameOfClient,
        [string] $SrvInstance,
        [string] $ReplaceSource,
        [string] $ReplaceBy
    )
    $OutCompleteF="$ScriptPath\$ScriptFileName"
    $OutF="$PathForTempFolder\$ScriptFileName"
    Write-Host "Executing... ($ScriptFileName)" -ForegroundColor Yellow
    If ($ReplaceSource.length -eq 0)
    {
        (Get-Content $OutCompleteF) | Out-File -Encoding utf8 $OutF
    }
    else
    {
        (Get-Content $OutCompleteF) | 
        Foreach-Object {$_ -replace $ReplaceSource,$ReplaceBy}  | 
        Out-File -Encoding utf8 $OutF
    }
    Invoke-Sqlcmd -InputFile $OutF -Database "CalcmenuWeb_$NameOfClient" -ServerInstance $SrvInstance -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
}
#
function Get-Tree($Path,$Include='*') { 
    @(Get-Item $Path -Include $Include) + 
        (Get-ChildItem $Path -Recurse -Include $Include) | 
        sort pspath -Descending -unique
} 

function Remove-Tree($Path,$Include='*') { 
    Get-Tree $Path $Include | Remove-Item -force -recurse
} 
#
function fctDownloadCmWebAndUnZip 
# $args[0] $ProfileNameAWS 
# $args[1] $PathcmwebRoot 
# $args[2] $DOVersion 
# $args[3] $DOVersionMain  
{
    param( [string]$paramProfileName, [string]$paramPathcmwebRoot, [string]$paramVersion, [string]$paramYear )
    <#
        $paramProfileName="egs.s31"
    $paramPathcmwebRoot="C:\EgsExchange"
    $paramVersion="v8.2"
    $paramYear="2015"
    #>
    $RarFileName="CmWeb_"+$paramYear+"_"+$paramVersion+".rar"
    $RarPath="$paramPathcmwebRoot\CalcmenuWeb\$paramYear\$paramVersion"
    $RarPathShort="$paramPathcmwebRoot\CalcmenuWeb\$paramYear\"
    $RarFile="$paramPathcmwebRoot\CalcmenuWeb\$RarFileName"
    Write-host "Downloading $RarFile" -ForegroundColor Yellow
    #$RarFileName 
    #$RarFile
    & $AwsExeFile --profile=$paramProfileName s3 cp "s3://cmweb/CalcmenuWeb/$RarFileName" $RarFile
    If (Test-Path $RarPath) 
    {  
        Remove-Tree $RarPath
    }
    If (Test-Path $RarFile) 
    {  
        Write-host "Unzipping $RarPath" -ForegroundColor Yellow
        & $PathWinUnRar x -idc -idq $RarFile $RarPathShort
    }
    else
    {
        Write-host "Error downloading the rar files with CM WEB source files" -ForegroundColor red
        break
    }
}
#
function Add-SQLPSSnapin
{
	#
	# Add the SQL Server Provider.
	#

	$ErrorActionPreference = "Stop";

    $shellIds = Get-ChildItem HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds;

    if(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps") {
        $sqlpsreg = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps"
    }
    elseif(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps110") { 
        try{
			if((Get-PSSnapin -Registered |? { $_.Name -ieq "SqlServerCmdletSnapin110"}).Count -eq 0) {

				Write-Host "Registering the SQL Server 2012 Powershell Snapin";

				if(Test-Path -Path $env:windir\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe) {
					Set-Alias installutil $env:windir\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe;
				} 
				elseif (Test-Path -Path $env:windir\Microsoft.NET\Framework\v2.0.50727\InstallUtil.exe) {
					Set-Alias installutil $env:windir\Microsoft.NET\Framework\v2.0.50727\InstallUtil.exe;
				}
				else {
					throw "InstallUtil wasn't found!";
				}

				if(Test-Path -Path "$env:ProgramFiles\Microsoft SQL Server\110\Tools\PowerShell\Modules\SQLPS\") {
					installutil "$env:ProgramFiles\Microsoft SQL Server\110\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSProvider.dll";
					installutil "$env:ProgramFiles\Microsoft SQL Server\110\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSSnapins.dll";
				}
				elseif(Test-Path -Path "${env:ProgramFiles(x86)}\Microsoft SQL Server\110\Tools\PowerShell\Modules\SQLPS\") {
					installutil "${env:ProgramFiles(x86)}\Microsoft SQL Server\110\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSProvider.dll";
					installutil "${env:ProgramFiles(x86)}\Microsoft SQL Server\110\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSSnapins.dll"; 
				}
                    
				Add-PSSnapin SQLServer*110;
				Write-Host "Sql Server 2012 Powershell Snapin registered successfully.";
			} 
		}catch{}

        $sqlpsreg = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps110";
    }
    elseif(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps120") { 
        try{
			if((Get-PSSnapin -Registered |? { $_.Name -ieq "SqlServerCmdletSnapin120"}).Count -eq 0) {

				Write-Host "Registering the SQL Server 2014 Powershell Snapin";

				if(Test-Path -Path $env:windir\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe) {
					Set-Alias installutil $env:windir\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe;
				} 
				elseif (Test-Path -Path $env:windir\Microsoft.NET\Framework\v2.0.50727\InstallUtil.exe) {
					Set-Alias installutil $env:windir\Microsoft.NET\Framework\v2.0.50727\InstallUtil.exe;
				}
				else {
					throw "InstallUtil wasn't found!";
				}

				if(Test-Path -Path "$env:ProgramFiles\Microsoft SQL Server\120\Tools\PowerShell\Modules\SQLPS\") {
					installutil "$env:ProgramFiles\Microsoft SQL Server\120\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSProvider.dll";
					installutil "$env:ProgramFiles\Microsoft SQL Server\120\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSSnapins.dll";
				}
				elseif(Test-Path -Path "${env:ProgramFiles(x86)}\Microsoft SQL Server\120\Tools\PowerShell\Modules\SQLPS\") {
					installutil "${env:ProgramFiles(x86)}\Microsoft SQL Server\120\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSProvider.dll";
					installutil "${env:ProgramFiles(x86)}\Microsoft SQL Server\120\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSSnapins.dll"; 
				}
                    
				Add-PSSnapin SQLServer*120;
				Write-Host "Sql Server 2014 Powershell Snapin registered successfully.";
			} 
		}catch{}

        $sqlpsreg = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps120";
    }
	elseif(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps130") { 
        try{
			if((Get-PSSnapin -Registered |? { $_.Name -ieq "SqlServerCmdletSnapin130"}).Count -eq 0) {

				Write-Host "Registering the SQL Server 2016 Powershell Snapin";

				if(Test-Path -Path $env:windir\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe) {
					Set-Alias installutil $env:windir\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe;
				} 
				elseif (Test-Path -Path $env:windir\Microsoft.NET\Framework\v2.0.50727\InstallUtil.exe) {
					Set-Alias installutil $env:windir\Microsoft.NET\Framework\v2.0.50727\InstallUtil.exe;
				}
				else {
					throw "InstallUtil wasn't found!";
				}

				if(Test-Path -Path "$env:ProgramFiles\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\") {
					installutil "$env:ProgramFiles\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSProvider.dll";
					installutil "$env:ProgramFiles\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSSnapins.dll";
				}
				elseif(Test-Path -Path "${env:ProgramFiles(x86)}\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\") {
					installutil "${env:ProgramFiles(x86)}\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSProvider.dll";
					installutil "${env:ProgramFiles(x86)}\Microsoft SQL Server\130\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSSnapins.dll"; 
				}
                    
				Add-PSSnapin SQLServer*130;
				Write-Host "Sql Server 2016 Powershell Snapin registered successfully.";
			} 
		}catch{}

        $sqlpsreg = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps130";
    }
    elseif(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps140") { 
        try{
			if((Get-PSSnapin -Registered |? { $_.Name -ieq "SqlServerCmdletSnapin140"}).Count -eq 0) {

				Write-Host "Registering the SQL Server 2017 Powershell Snapin";

				if(Test-Path -Path $env:windir\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe) {
					Set-Alias installutil $env:windir\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe;
				} 
				elseif (Test-Path -Path $env:windir\Microsoft.NET\Framework\v2.0.50727\InstallUtil.exe) {
					Set-Alias installutil $env:windir\Microsoft.NET\Framework\v2.0.50727\InstallUtil.exe;
				}
				else {
					throw "InstallUtil wasn't found!";
				}

				if(Test-Path -Path "$env:ProgramFiles\Microsoft SQL Server\140\Tools\PowerShell\Modules\SQLPS\") {
					installutil "$env:ProgramFiles\Microsoft SQL Server\140\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSProvider.dll";
					installutil "$env:ProgramFiles\Microsoft SQL Server\140\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSSnapins.dll";
				}
				elseif(Test-Path -Path "${env:ProgramFiles(x86)}\Microsoft SQL Server\140\Tools\PowerShell\Modules\SQLPS\") {
					installutil "${env:ProgramFiles(x86)}\Microsoft SQL Server\140\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSProvider.dll";
					installutil "${env:ProgramFiles(x86)}\Microsoft SQL Server\140\Tools\PowerShell\Modules\SQLPS\Microsoft.SqlServer.Management.PSSnapins.dll"; 
				}
                    
				Add-PSSnapin SQLServer*140;
				Write-Host "Sql Server 2017 Powershell Snapin registered successfully.";
			} 
		}catch{}

        $sqlpsreg = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps140";
    }
        elseif(Test-Path -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps150") {
        try {
            if ((Get-PSSnapin -Registered | Where-Object { $_.Name -ieq "SqlServerCmdletSnapin150" }).Count -eq 0) {

                Write-Host "Registering the SQL Server 2019 Powershell Snapin";

                # find InstallUtil
                if (Test-Path "$env:windir\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe") {
                    Set-Alias installutil "$env:windir\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe"
                }
                elseif (Test-Path "$env:windir\Microsoft.NET\Framework\v2.0.50727\InstallUtil.exe") {
                    Set-Alias installutil "$env:windir\Microsoft.NET\Framework\v2.0.50727\InstallUtil.exe"
                }
                else {
                    throw "InstallUtil wasn't found!"
                }

                # register the snap-in DLLs
                $base = "$env:ProgramFiles\Microsoft SQL Server\150\Tools\PowerShell\Modules\SQLPS\"
                if (Test-Path $base) {
                    installutil "$base\Microsoft.SqlServer.Management.PSProvider.dll"
                    installutil "$base\Microsoft.SqlServer.Management.PSSnapins.dll"
                }
                else {
                    $base = "${env:ProgramFiles(x86)}\Microsoft SQL Server\150\Tools\PowerShell\Modules\SQLPS\"
                    installutil "$base\Microsoft.SqlServer.Management.PSProvider.dll"
                    installutil "$base\Microsoft.SqlServer.Management.PSSnapins.dll"
                }

                Add-PSSnapin SQLServer*150
                Write-Host "Sql Server 2019 Powershell Snapin registered successfully."
            }
        }
        catch {
            # ignore registration errors
        }

        $sqlpsreg = "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps150"
    }

    else {
        throw "SQL Server Provider for Windows PowerShell is not installed."
    }

    $item = Get-ItemProperty $sqlpsreg
	$sqlpsPath = [System.IO.Path]::GetDirectoryName($item.Path)

	#
	# Set mandatory variables for the SQL Server provider
	#
	Set-Variable -scope Global -name SqlServerMaximumChildItems -Value 0
	Set-Variable -scope Global -name SqlServerConnectionTimeout -Value 30
	Set-Variable -scope Global -name SqlServerIncludeSystemObjects -Value $false
	Set-Variable -scope Global -name SqlServerMaximumTabCompletion -Value 1000

	#
	# Load the snapins, type data, format data
	#
	Push-Location
	
    cd $sqlpsPath 
    	
    if (Get-PSSnapin -Registered | where {$_.name -eq 'SqlServerProviderSnapin100'}) 
    { 
        if( !(Get-PSSnapin | where {$_.name -eq 'SqlServerProviderSnapin100'})) 
        {
            Add-PSSnapin SqlServerProviderSnapin100; 
        }  
        
        if( !(Get-PSSnapin | where {$_.name -eq 'SqlServerCmdletSnapin100'})) 
        {
            Add-PSSnapin SqlServerCmdletSnapin100;
        }
        
        Write-Host "Using the SQL Server 2008 Powershell Snapin.";
          
       Update-TypeData -PrependPath SQLProvider.Types.ps1xml -ErrorAction SilentlyContinue
       Update-FormatData -prependpath SQLProvider.Format.ps1xml -ErrorAction SilentlyContinue
    } 
    else #Sql Server 2012 or 2014 module should be registered now.  Note, we'll only use it if the earlier version isn't installed.
    {
        if (!(Get-Module -ListAvailable -Name SqlServer))
        {
            Write-Host "Using the SQL Server 2012 or 2014 Powershell Module.";

            if( !(Get-Module | where {$_.name -eq 'sqlps'})) 
            {  
                Import-Module 'sqlps' -DisableNameChecking; 
            }	
            cd $sqlpsPath;
            cd ..\PowerShell\Modules\SQLPS;
        }

        Update-TypeData -PrependPath SQLProvider.Types.ps1xml -ErrorAction SilentlyContinue
        Update-FormatData -prependpath SQLProvider.Format.ps1xml -ErrorAction SilentlyContinue
	}
    
    Pop-Location
}



<#if ( (Get-PSSnapin -Name SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue) -eq $null )
{
#
    if ( (Get-PSSnapin -Name SqlServerCmdletSnapin100 -ErrorAction SilentlyContinue) -eq $null )
    {
        If (([System.Environment]::OSVersion.Version.Major -eq "6") -and ([System.Environment]::OSVersion.Version.Minor -eq "1"))
        {
            #2008 R2
            Add-PsSnapin SqlServerCmdletSnapin100
        }
        else
        {
            #Other
            Add-SQLPSSnapin

            ## #2012 
            ## Add-PSSnapin SqlServerCmdletSnapin110
        }
    }
    #
    if ( (Get-PSSnapin -Name SqlServerProviderSnapin100 -ErrorAction SilentlyContinue) -eq $null )
    {
        If (([System.Environment]::OSVersion.Version.Major -eq "6") -and ([System.Environment]::OSVersion.Version.Minor -eq "1"))
        {
            #2008 R2
            Add-PSSnapin SqlServerProviderSnapin100
        }
        else
        {
            ## #2012 
            ## Add-PSSnapin SqlServerProviderSnapin110
        }
    }
    #
}#>
#
function fctDownloadCmWebUpdateAndUnZip 
# $args[0] $ProfileNameAWS 
# $args[1] $PathcmwebRoot 
# $args[2] $DOVersion 
# $args[3] $DOVersionMain  
{
    param( [string]$paramProfileName, [string]$paramPathcmwebRoot )
    $RarFileName="CmWeb_Updates.rar"
    $RarPathUpdate="$paramPathcmwebRoot\CalcmenuWeb\2015\Version Updates"
    $RarPathShort="$paramPathcmwebRoot\CalcmenuWeb\2015\"
    $RarFile="$paramPathcmwebRoot\CalcmenuWeb\2015\$RarFileName"
    Write-host "Downloading $RarFile" -ForegroundColor Yellow
    #$RarFileName 
    #$RarFile
    & $AwsExeFile --profile=$paramProfileName s3 cp "s3://cmweb/CalcmenuWeb/$RarFileName" $RarFile
    If (Test-Path $RarPathUpdate) 
    {  
        Remove-Tree $RarPathUpdate
    }
    If (Test-Path $RarFile) 
    {  
        Write-host "Unzipping $RarPathUpdate" -ForegroundColor Yellow
        & $PathWinUnRar x -idc -idq $RarFile $RarPathShort
    }
    else
    {
        Write-host "Error downloading the rar files with CM WEB source files" -ForegroundColor red
        break
    }
}
#
Function ChangeConfig {
# Parameters $Path and $SearchString
  param ([Parameter(Mandatory=$true)]$Path,
  [Parameter(Mandatory=$true)]$StringSearch,
  [Parameter(Mandatory=$true)][AllowEmptyString()][AllowNull()]$StringReplace
  )
    If (Test-Path $Path)
    {
        $PathCopy=$Path+".Copy"
        Copy-Item $Path $PathCopy
        (Get-Content $Path) | 
        Foreach-Object {$_ -replace $StringSearch,$StringReplace}  | 
        Out-File -Encoding utf8 $Path
        #
        if((Get-FileHash $Path).hash  -ne (Get-FileHash $PathCopy).hash)
         { Write-host "File $Path was changed with $StringReplace" -ForegroundColor Green}
        Else {Write-host "File $Path was NOT changed ($StringSearch not replaced)" -ForegroundColor Yellow}
        #
        Remove-Item $PathCopy
    }
    else
    {
        Write-Host "File cannot be found: $Path" -ForegroundColor Magenta
    }
  }

function fctSetParametersInConfigsNew 
{
    param( [string]$fctPathcmwebCurrent, [string]$fctDataSourceIP, [string]$fctClientName, [string]$fctUsernameForLogin, [string]$fctPasswordDb, [string]$fctUrlNameServer, [string]$fctIsMigros, [string]$fctDOVersion, [string]$fctDOVersionMain, [string]$fctCultureKiosk, [string]$fctHTTPS, [string]$fctUseDeclarationTool, [string]$fctLanguageCode, [string]$fctCultureFormatDate, [string]$fctCultureFormatDateNum, [string]$fctCultureFormatNumber, [string]$fctCMLogoFileName)

    #
    if (Test-Path "c:\Website\$fctClientName")
    {
        $functionPathcmweb="c:"
    }
    else
    {
        if (Test-Path "d:\Website\$fctClientName")
        {
            $functionPathcmweb="d:"
        }
        else
        {
            if (Test-Path "e:\Website\$fctClientName")
            {
                $functionPathcmweb="e:"
            }
            else
            {
                write-host "Drive was not found (fctSetParametersInConfigsNew)" -ForegroundColor Red
                exit
            }
            
        }
    }
    #
    $WebConfigFolderDest=$fctPathcmwebCurrent+"\CalcmenuWeb"
    #
    $WebConfigFolder=$fctPathcmwebCurrent+"\CalcmenuWeb"
         
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config" "\[ClientUrl\]" "$fctUrlNameServer.calcmenuweb.com" 
    ChangeConfig "$WebConfigFolder\web.config" "\[ClientLocalReportFolder\]" "$fctPathcmwebCurrent\CalcmenuWeb\pdf\" 
    ChangeConfig "$WebConfigFolder\web.config" "\[DeclarationUrl\]" "http://$fctUrlNameServer.calcmenuweb.com/Declaration" 
    ChangeConfig "$WebConfigFolder\web.config" "\[IsMigros\]" $fctIsMigros 
    ChangeConfig "$WebConfigFolder\web.config" "\[ApplicationLogoFileName\]" $fctCMLogoFileName

    $WebConfigFolder=$WebConfigFolderDest+"\calcmenuapi"
    $WebConfigFolderB=$WebConfigFolderDest
    $KeyTempURL="https"+"://$fctUrlNameServer.calcmenuweb.com" #http://eoc.calcmenuweb.com
    $KeyTempURL=$KeyTempURL.ToLower()
         
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config" "\[keyDAM\]" "$WebConfigFolderB\DigitalAssets\" 
    ChangeConfig "$WebConfigFolder\web.config" "\[keyTEMP\]" "$WebConfigFolderB\temp\" 
    ChangeConfig "$WebConfigFolder\web.config" "\[keyURL\]" "$KeyTempURL" 
    ChangeConfig "$WebConfigFolder\web.config" "\[keyFILES\]" "$WebConfigFolderB\Files\" 
    ChangeConfig "$WebConfigFolder\web.config" "\[keyPICNORMAL\]" "$WebConfigFolderB\picnormal\" 
    ChangeConfig "$WebConfigFolder\web.config" "\[keyPICTHUMBNAIL\]" "$WebConfigFolderB\picthumbnail\" 
    ChangeConfig "$WebConfigFolder\web.config" "\[keyPICORIGINAL\]" "$WebConfigFolderB\picOriginal\" 
    
    $WebConfigFolder=$WebConfigFolderDest+'\kiosk'
    $WebConfigFolderB=$WebConfigFolderDest

    $tempKeyNormal="https"+"://$fctUrlNameServer.calcmenuweb.com/picnormal/"
    $tempKeyThumbnail="https"+"://$fctUrlNameServer.calcmenuweb.com/picthumbnail/"
    $tempKeyOriginal="https"+"://$fctUrlNameServer.calcmenuweb.com/picOriginal/"
         
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config" "\[keyPICNORMAL\]" $tempKeyNormal 
    ChangeConfig "$WebConfigFolder\web.config" "\[keyPICTHUMBNAIL\]" $tempKeyThumbnail 
    ChangeConfig "$WebConfigFolder\web.config" "\[keyPICORIGINAL\]" $tempKeyOriginal 
    ChangeConfig "$WebConfigFolder\web.config" "\[ClientCMWebFolder\]" $WebConfigFolderB 
    ChangeConfig "$WebConfigFolder\web.config" '\[ClientUrl\]' "$fctUrlNameServer.calcmenuweb.com" 
    ChangeConfig "$WebConfigFolder\web.config" "\[ClientLocalReportFolder\]" "$WebConfigFolder\pdf\" 
    #
    $WebConfigFolder=$WebConfigFolderDest+'\ws'
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    #
    $WebConfigFolder=$WebConfigFolderDest+'\eMenu'
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config" "\[keyURL\]" "$KeyTempURL" 
    ChangeConfig "$WebConfigFolder\web.config" '\[ClientUrl\]' "$fctUrlNameServer.calcmenuweb.com" 
    #
    $WebConfigFolder=$WebConfigFolderDest+'\eMenuPlan'
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config" "\[keyURL\]" "$KeyTempURL" 
    #
    $WebConfigFolder=$WebConfigFolderDest+'\eRecipe'
    ChangeConfig "$WebConfigFolder\appSettings.json" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\appSettings.json" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\appSettings.json" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\appSettings.json" "\[Password\]" $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\appSettings.json" "\[keyURL\]" "$KeyTempURL" 
    ChangeConfig "$WebConfigFolder\appSettings.json" "\[ClientUrl\].calcmenuweb.com" "$fctUrlNameServer.calcmenuweb.com" 
    #
    $WebConfigFolder=$WebConfigFolderDest+'\eRecipe\ClientApp\dist\assets'
    ChangeConfig "$WebConfigFolder\appSettings.json" "\[ClientUrl\].calcmenuweb.com" "$fctUrlNameServer.calcmenuweb.com" 
    #
    $WebConfigFolder=$WebConfigFolderDest+'\eRecipe\ClientApp\dist'
    ChangeConfig "$WebConfigFolder\index.html" "\[keyURL\].calcmenuweb.com" "$fctUrlNameServer.calcmenuweb.com" 
    ChangeConfig "$WebConfigFolder\index.html" "\[ClientUrl\].calcmenuweb.com" "$fctUrlNameServer.calcmenuweb.com" 
    #
    $WebConfigFolder=$WebConfigFolderDest+'\ws'
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    #
    $WebConfigFolder=$WebConfigFolderDest+'\inventory'
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config" "\[ApplicationLogoFileName\]" $fctCMLogoFileName
    #
    $WebConfigFolder=$WebConfigFolderDest+'\RecipeExport'
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config" "\[ApplicationLogoFileName\]" $fctCMLogoFileName
    #
    $WebConfigFolder=$WebConfigFolderDest+'\DataExport'
    $WebConfigFolderB=$WebConfigFolderDest
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config" "\[ApplicationLogoFileName\]" $fctCMLogoFileName
    ChangeConfig "$WebConfigFolder\web.config" "\[ClientCMWebFolder\]" $WebConfigFolderB 
    #
    $WebConfigFolder=$WebConfigFolderDest+'\DataAnalytics'
    $WebConfigFolderB=$WebConfigFolderDest
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config" "\[ApplicationLogoFileName\]" $fctCMLogoFileName
    ChangeConfig "$WebConfigFolder\web.config" "\[keyURL\]" "$KeyTempURL" 
    ChangeConfig "$WebConfigFolder\web.config" "\[ClientCMWebFolder\]" $WebConfigFolderB 
    # 
    $WebConfigFolder=$WebConfigFolderDest+'\RecipeImport'
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config" "\[ApplicationLogoFileName\]" $fctCMLogoFileName
   #
    $WebConfigFolder=$WebConfigFolderDest+'\MenuPlanView'
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config" "\[ApplicationLogoFileName\]" $fctCMLogoFileName
    #
    $ExcelPath=$WebConfigFolderDest+'\AdvancedShoppingList\Report\'
    $WebConfigFolder=$WebConfigFolderDest+'\AdvancedShoppingList'
    $WebConfigFolderB=$WebConfigFolderDest
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config" "\[ExcelPath\]" $ExcelPath 
    ChangeConfig "$WebConfigFolder\web.config" '\[KeyUrl\]' "$fctUrlNameServer.calcmenuweb.com" 
    ChangeConfig "$WebConfigFolder\App\app.js" '\[KeyUrl\]' "$fctUrlNameServer.calcmenuweb.com" 
    ChangeConfig "$WebConfigFolder\index.html" '\[KeyUrl\]' $fctUrlNameServer 
    ChangeConfig "$WebConfigFolder\App\app.js" "advanceshoppinglist" "advancedshoppinglist" 
    ChangeConfig "$WebConfigFolder\web.config" "\[ClientCMWebFolder\]" $WebConfigFolderB 
    #
    $WebConfigFolder=$WebConfigFolderDest+'\shoppinglistWS'
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    #
    $WebConfigFolder=$WebConfigFolderDest+'\wsapi'
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    #
    $WebConfigFolder="$WebConfigFolderDest\kiosk\assets\js"
    ChangeConfig "$WebConfigFolder\kiosk.baseURL.min.js" '\[ClientUrl\]' "$fctUrlNameServer.calcmenuweb.com" 
    ChangeConfig "$WebConfigFolder\kiosk.baseURL.min.js" '\[LanguageCode\]' $fctLanguageCode 
    #
    $WebConfigFolder="$WebConfigFolderDest\eMenu\js"
    ChangeConfig "$WebConfigFolder\kiosk.core.js" '\[ClientUrl\]' "$fctUrlNameServer.calcmenuweb.com" 
    #
    $WebConfigFolder="$WebConfigFolderDest\ReportXML"
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    #
    Write-Host "CHANGES IN WEB.CONFIG AND OTHER JS FILES HAVE BEEN COMPLETED" -foregroundcolor "green"
    #
}

#
function fctSetParametersInConfigsForKioskFolderNew 
{
    param( [string]$fctPathcmwebCurrent, [string]$fctDataSourceIP, [string]$fctClientName, [string]$fctUsernameForLogin, [string]$fctPasswordDb, [string]$fctUrlNameServer, [string]$fctIsMigros, [string]$fctDOVersion, [string]$fctDOVersionMain, [string]$fctCultureKiosk, [string]$fctHTTPS, [string]$fctUseDeclarationTool, [string]$fctLanguageCode, [string]$fctCultureFormatDate, [string]$fctCultureFormatDateNum, [string]$fctCultureFormatNumber)

    #
    if (Test-Path "c:\Website\$fctClientName")
    {
        $functionPathcmweb="c:"
    }
    else
    {
        if (Test-Path "d:\Website\$fctClientName")
        {
            $functionPathcmweb="d:"
        }
        else
        {
            #if (Test-Path "e:\Website\$fctClientName")
            #{
            #    $functionPathcmweb="e:"
            #}
            #else
            #{
            #}
            write-host "Drive was not found (fctSetParametersInConfigsForKioskFolderNew)" -ForegroundColor Red

        }
    }
    $WebConfigFolder=$fctPathcmwebCurrent+"\kiosk"
    $WebConfigFolderRoot=$fctPathcmwebCurrent
    #
    $WebConfigFolder=$WebConfigFolder
    $tempKeyNormal="https"+"://$fctUrlNameServer.calcmenuweb.com/picnormal/"
    $tempKeyThumbnail="https"+"://$fctUrlNameServer.calcmenuweb.com/picthumbnail/"
    $tempKeyOriginal="https"+"://$fctUrlNameServer.calcmenuweb.com/picOriginal/"
         
    ChangeConfig "$WebConfigFolder\web.config" "\[DataSource\]" $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "\[InitialCatalog\]" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" "\[UserID\]" $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config" "\[Password\]" $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config" "\[keyPICNORMAL\]" $tempKeyNormal 
    ChangeConfig "$WebConfigFolder\web.config" "\[keyPICTHUMBNAIL\]" $tempKeyThumbnail 
    ChangeConfig "$WebConfigFolder\web.config" "\[keyPICORIGINAL\]" $tempKeyOriginal 
    ChangeConfig "$WebConfigFolder\web.config" "\[ClientCMWebFolder\]" $WebConfigFolderRoot 
    ChangeConfig "$WebConfigFolder\web.config" '\[ClientUrl\]' "$fctUrlNameServer.calcmenuweb.com" 
    ChangeConfig "$WebConfigFolder\web.config" "\[ClientLocalReportFolder\]" "$WebConfigFolderRoot\pdf\" 
            
    #
    $WebConfigFolder="$WebConfigFolder\assets\js"
    ChangeConfig "$WebConfigFolder\kiosk.baseURL.min.js" '\[ClientUrl\]' "$fctUrlNameServer.calcmenuweb.com" 
    ChangeConfig "$WebConfigFolder\kiosk.baseURL.min.js" '\[LanguageCode\]' $fctLanguageCode 
    #
    Write-Host "CHANGES IN WEB.CONFIG AND OTHER JS FILES FOR THE KIOSK FOLDER ONLY HAVE BEEN COMPLETED" -foregroundcolor "green"
    #
}
#


function fctReplaceParametersInConfigsNew 
{
    param( [string]$fctPathcmwebCurrent, [string]$fctDataSourceIP, [string]$fctClientName, [string]$fctUsernameForLogin, [string]$fctPasswordDb, [string]$fctUrlNameServer, [string]$fctIsMigros, [string]$fctDOVersion, [string]$fctDOVersionMain, [string]$fctCultureKiosk, [string]$fctHTTPS, [string]$fctUseDeclarationTool, [string]$fctLanguageCode, [string]$fctCultureFormatDate, [string]$fctCultureFormatDateNum, [string]$fctCultureFormatNumber, [string]$fctClientNameSource, [string]$fctDataSourceIPSource, [string]$fctHTTPSSource, [string]$fctIsMigrosSource, [string]$fctLanguageCodeSource, [string]$fctPasswordDbSource, [string]$fctPathcmwebCurrentSource, [string]$fctUrlNameServerSource, [string]$fctUsernameForLoginSource)

    #
    "----------fctReplaceParametersInConfigsNew"
    $fctPathcmwebCurrent 
    $fctDataSourceIP
    $fctClientName
    $fctUsernameForLogin
    $fctPasswordDb
    $fctUrlNameServer
    $fctIsMigros
    $fctDOVersion
    $fctDOVersionMain
    $fctCultureKiosk
    $fctHTTPS
    $fctUseDeclarationTool 
    $fctLanguageCode 
    $fctCultureFormatDate
    $fctCultureFormatDateNum
    $fctCultureFormatNumber
    $fctClientNameSource
    $fctDataSourceIPSource
    $fctHTTPSSource
    $fctIsMigrosSource
    $fctLanguageCodeSource
    $fctPasswordDbSource
    $fctPathcmwebCurrentSource
    $fctUrlNameServerSource, 
    $fctUsernameForLoginSource
    "-----------------------------------"
    #
    if (Test-Path "c:\Website\$fctClientName")
    {
        $functionPathcmweb="c:"
    }
    else
    {
        if (Test-Path "d:\Website\$fctClientName")
        {
            $functionPathcmweb="d:"
        }
        else
        {
            #if (Test-Path "e:\Website\$fctClientName")
            #{
            #    $functionPathcmweb="e:"
            #}
            #else
            #{
            #}
            write-host "Drive was not found (fctReplaceParametersInConfigsNew)" -ForegroundColor Red
        }
    }
    #
    #
    [string]$WebConfigFolderSource=$fctPathcmwebCurrentSource+"\CalcmenuWeb"
    [string]$WebConfigFolderDest=$fctPathcmwebCurrent+"\CalcmenuWeb"
    #
    $TmpX=[Regex]::Escape($fctPathcmwebCurrentSource)
    [string]$WebConfigFolder=$fctPathcmwebCurrent+"\CalcmenuWeb"
    ChangeConfig "$WebConfigFolder\web.config" $fctDataSourceIPSource $fctDataSourceIP
    ChangeConfig "$WebConfigFolder\web.config"  "CalcmenuWeb_$fctClientNameSource" "CalcmenuWeb_$fctClientName"
    ChangeConfig "$WebConfigFolder\web.config"  $fctUsernameForLoginSource $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config"  $fctPasswordDbSource $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config"  "$fctUrlNameServerSource.calcmenuweb.com" "$fctUrlNameServer.calcmenuweb.com" 
    ChangeConfig "$WebConfigFolder\web.config"  $TmpX $fctPathcmwebCurrent 
    ChangeConfig "$WebConfigFolder\web.config"  "http://$fctUrlNameServerSource.calcmenuweb.com/Declaration" "http://$fctUrlNameServer.calcmenuweb.com/Declaration" 

    [string]$WebConfigFolder=$WebConfigFolderDest+"\calcmenuapi"
    $WebConfigFolderSim=$WebConfigFolderDest
    $KeyTempURL="https"+"://$fctUrlNameServer.calcmenuweb.com" #https://eoc.calcmenuweb.com
    $KeyTempURL=$KeyTempURL.ToLower()
    $KeyTempURLSource="https"+"://$fctUrlNameServerSource.calcmenuweb.com" #https://eoc.calcmenuweb.com
    $KeyTempURLSource=$KeyTempURLSource.ToLower()
    $TmpX=[Regex]::Escape($WebConfigFolderSource)
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config"   "CalcmenuWeb_$fctClientNameSource" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config"   $fctUsernameForLoginSource $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config"   $fctPasswordDbSource $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config"   $TmpX  $WebConfigFolderSim #2021-07-13  
    ChangeConfig "$WebConfigFolder\web.config"   "$KeyTempURLSource" "$KeyTempURL" 

    [string]$WebConfigFolder=$WebConfigFolderDest+'\kiosk'
    $tempKeyNormal="https"+"://$fctUrlNameServer.calcmenuweb.com/picnormal/"
    $tempKeyThumbnail="https"+"://$fctUrlNameServer.calcmenuweb.com/picthumbnail/"
    $tempKeyOriginal="https"+"://$fctUrlNameServer.calcmenuweb.com/picOriginal/"
    $tempKeyWebBaseUrl="https"+"://$fctUrlNameServer.calcmenuweb.com"
    $tempKeyReportFolder=$functionPathcmweb+"\Website\"+$fctClientName+"\CalcmenuWeb"
    $tempKeyNormalSource="https"+"://$fctUrlNameServerSource.calcmenuweb.com/picnormal/"
    $tempKeyThumbnailSource="https"+"://$fctUrlNameServerSource.calcmenuweb.com/picthumbnail/"
    $tempKeyOriginalSource="https"+"://$fctUrlNameServerSource.calcmenuweb.com/picOriginal/"
    $tempKeyWebBaseUrlSource="https"+"://$fctUrlNameServerSource.calcmenuweb.com"
    $tempKeyReportFolderSource=$fctPathcmwebCurrentSource+"\CalcmenuWeb" 
    $TmpX=[Regex]::Escape($tempKeyReportFolderSource)
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "CalcmenuWeb_$fctClientNameSource" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" $fctUsernameForLoginSource $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config"  $fctPasswordDbSource $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config"  $tempKeyNormalSource $tempKeyNormal 
    ChangeConfig "$WebConfigFolder\web.config"  $tempKeyThumbnailSource $tempKeyThumbnail 
    ChangeConfig "$WebConfigFolder\web.config"  $tempKeyOriginalSource $tempKeyOriginal 
    ChangeConfig "$WebConfigFolder\web.config"  $tempKeyWebBaseUrlSource $tempKeyWebBaseUrl 
    ChangeConfig "$WebConfigFolder\web.config"  $TmpX  $tempKeyReportFolder 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\ws'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config"  "CalcmenuWeb_$fctClientNameSource" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" $fctUsernameForLoginSource $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config"  $fctPasswordDbSource $fctPasswordDb 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\wsapi'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config"  "CalcmenuWeb_$fctClientNameSource" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config" $fctUsernameForLoginSource $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config"  $fctPasswordDbSource $fctPasswordDb 
    #
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\inventory'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "CalcmenuWeb_$fctClientNameSource" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config"  $fctUsernameForLoginSource $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config"  $fctPasswordDbSource $fctPasswordDb 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\RecipeExport'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config"  "CalcmenuWeb_$fctClientNameSource" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config"  $fctUsernameForLoginSource $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config"  $fctPasswordDbSource $fctPasswordDb 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\DataExport'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config"  "CalcmenuWeb_$fctClientNameSource" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config"  $fctUsernameForLoginSource $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config"  $fctPasswordDbSource $fctPasswordDb 
    $tempKeyReportFolder=$functionPathcmweb+"\Website\"+$fctClientName+"\CalcmenuWeb"
    $tempKeyReportFolderSource=$fctPathcmwebCurrentSource+"\CalcmenuWeb" 
    $TmpX=[Regex]::Escape($tempKeyReportFolderSource)
    ChangeConfig "$WebConfigFolder\web.config"  $TmpX  $tempKeyReportFolder 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\DataAnalytics'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config"  "CalcmenuWeb_$fctClientNameSource" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config"  $fctUsernameForLoginSource $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config"  $fctPasswordDbSource $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config"  $tempKeyWebBaseUrlSource $tempKeyWebBaseUrl 
    $tempKeyReportFolder=$functionPathcmweb+"\Website\"+$fctClientName+"\CalcmenuWeb"
    $tempKeyReportFolderSource=$fctPathcmwebCurrentSource+"\CalcmenuWeb" 
    $TmpX=[Regex]::Escape($tempKeyReportFolderSource)
    ChangeConfig "$WebConfigFolder\web.config"  $TmpX  $tempKeyReportFolder 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\RecipeImport'
    ChangeConfig "$WebConfigFolder\web.config" $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config"  "CalcmenuWeb_$fctClientNameSource" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config"  $fctUsernameForLoginSource $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config"  $fctPasswordDbSource $fctPasswordDb 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\MenuPlanView'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config" "CalcmenuWeb_$fctClientNameSource" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config"  $fctUsernameForLoginSource $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config"  $fctPasswordDbSource $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config"  "$fctUrlNameServerSource.calcmenuweb" "$fctUrlNameServer.calcmenuweb" 
    ChangeConfig "$WebConfigFolder\WeatherAPI\web.config"   $fctUrlNameServerSource $fctUrlNameServer 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\shoppinglistWS'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config"  "CalcmenuWeb_$fctClientNameSource" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config"  $fctUsernameForLoginSource $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config"  $fctPasswordDbSource $fctPasswordDb 
    #
    [string]$WebConfigFolder="$WebConfigFolderDest\kiosk\assets\js"
    ChangeConfig "$WebConfigFolder\kiosk.baseURL.min.js" $fctUrlNameServerSource $fctUrlNameServer 
    #
    $fctLanguageCodeSource=""""+$fctLanguageCodeSource+""""
    $fctLanguageCode=""""+$fctLanguageCode+""""
    ChangeConfig "$WebConfigFolder\kiosk.baseURL.min.js"  $fctLanguageCodeSource $fctLanguageCode 
    #
    [string]$WebConfigFolder="$WebConfigFolderDest\ReportXML"
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config"  "CalcmenuWeb_$fctClientNameSource" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\web.config"  $fctUsernameForLoginSource $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\web.config"  $fctPasswordDbSource $fctPasswordDb 
    #
    [string]$WebConfigFolder="$WebConfigFolderDest\emenu"
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config"   "CalcmenuWeb_$fctClientNameSource;" "CalcmenuWeb_$fctClientName;" 
    ChangeConfig "$WebConfigFolder\web.config"  "$fctUsernameForLoginSource;" "$fctUsernameForLogin;" 
    ChangeConfig "$WebConfigFolder\web.config"   $fctPasswordDbSource $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config"   "$fctUrlNameServerSource.calcmenuweb" "$fctUrlNameServer.calcmenuweb" 
    ChangeConfig "$WebConfigFolder\js\kiosk.core.js"   "$fctUrlNameServerSource.calcmenuweb" "$fctUrlNameServer.calcmenuweb" 
    #
    [string]$WebConfigFolder="$WebConfigFolderDest\emenuplan"
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config"  "CalcmenuWeb_$fctClientNameSource;" "CalcmenuWeb_$fctClientName;" 
    ChangeConfig "$WebConfigFolder\web.config"  "$fctUsernameForLoginSource;" "$fctUsernameForLogin;" 
    ChangeConfig "$WebConfigFolder\web.config"  $fctPasswordDbSource $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config" "$fctUrlNameServerSource.calcmenuweb" "$fctUrlNameServer.calcmenuweb"
    #
    [string]$WebConfigFolder="$WebConfigFolderDest\erecipe\ClientApp\dist\assets"
    ChangeConfig "$WebConfigFolder\appSettings.json"  "$fctUrlNameServerSource.calcmenuweb.com" "$fctUrlNameServer.calcmenuweb.com" 
    #
    [string]$WebConfigFolder="$WebConfigFolderDest\erecipe"
    ChangeConfig "$WebConfigFolder\appSettings.json"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\appSettings.json"  "CalcmenuWeb_$fctClientNameSource" "CalcmenuWeb_$fctClientName" 
    ChangeConfig "$WebConfigFolder\appSettings.json"  $fctUsernameForLoginSource $fctUsernameForLogin 
    ChangeConfig "$WebConfigFolder\appSettings.json"  $fctPasswordDbSource $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\appSettings.json"  "$fctUrlNameServerSource.calcmenuweb.com" "$fctUrlNameServer.calcmenuweb.com" 
    #
    [string]$WebConfigFolder="$WebConfigFolderDest\erecipe\ClientApp\dist"
    ChangeConfig "$WebConfigFolder\index.html"  "$fctUrlNameServerSource.calcmenuweb.com" "$fctUrlNameServer.calcmenuweb.com" 
    #
    $TmpX=[Regex]::Escape($WebConfigFolderSource)
    $WebConfigFolder=$WebConfigFolderDest+'\AdvancedShoppingList'
    ChangeConfig "$WebConfigFolder\web.config" $fctDataSourceIPSource $fctDataSourceIP  
    ChangeConfig "$WebConfigFolder\web.config" "CalcmenuWeb_$fctClientNameSource;" "CalcmenuWeb_$fctClientName;"  
    ChangeConfig "$WebConfigFolder\web.config" "$fctUsernameForLoginSource;" "$fctUsernameForLogin;" 
    ChangeConfig "$WebConfigFolder\web.config" $fctPasswordDbSource $fctPasswordDb 
    ChangeConfig "$WebConfigFolder\web.config" $TmpX $WebConfigFolderDest 
    ChangeConfig "$WebConfigFolder\web.config" "$fctUrlNameServerSource.calcmenuweb" "$fctUrlNameServer.calcmenuweb" 
    ChangeConfig "$WebConfigFolder\index.html" $fctUrlNameServerSource $fctUrlNameServer 
    ChangeConfig "$WebConfigFolder\App\app.js" $fctUrlNameServerSource $fctUrlNameServer 
    $tempKeyReportFolder=$functionPathcmweb+"\Website\"+$fctClientName+"\CalcmenuWeb"
    $tempKeyReportFolderSource=$fctPathcmwebCurrentSource+"\CalcmenuWeb" 
    $TmpX=[Regex]::Escape($tempKeyReportFolderSource)
    ChangeConfig "$WebConfigFolder\web.config"  $TmpX  $tempKeyReportFolder 
    #
    Write-Host "CHANGES IN WEB.CONFIG AND OTHER JS FILES HAVE BEEN COMPLETED" -foregroundcolor "green"
    #
}
#
function fctReplaceParametersInConfigsNewForRestoreWeb 
{
    param( [string]$fctPathcmwebCurrent, [string]$fctDataSourceIP, [string]$fctDataSourceIPSource, [string]$fctPathcmwebCurrentSource)

    #
    "----------fctReplaceParametersInConfigsNew"
    $fctPathcmwebCurrent 
    $fctDataSourceIP
    $fctDataSourceIPSource
    $fctPathcmwebCurrentSource
    "-----------------------------------"
    #
    if (Test-Path "c:\Website\$fctClientName")
    {
        $functionPathcmweb="c:"
    }
    else
    {
        if (Test-Path "d:\Website\$fctClientName")
        {
            $functionPathcmweb="d:"
        }
        else
        {
            if (Test-Path "e:\Website\$fctClientName")
            {
                $functionPathcmweb="e:"
            }
            else
            {
                write-host "Drive was not found (fctReplaceParametersInConfigsNewForRestoreWeb)" -ForegroundColor Red
            }
            
        }
    }
    #
    #
    [string]$WebConfigFolderSource=$fctPathcmwebCurrentSource+"\CalcmenuWeb"
    [string]$WebConfigFolderDest=$fctPathcmwebCurrent+"\CalcmenuWeb"
    #
    $TmpX=[Regex]::Escape($fctPathcmwebCurrentSource)
    [string]$WebConfigFolder=$fctPathcmwebCurrent+"\CalcmenuWeb"
    ChangeConfig "$WebConfigFolder\web.config" $fctDataSourceIPSource $fctDataSourceIP
    ChangeConfig "$WebConfigFolder\web.config"  $TmpX $fctPathcmwebCurrent 

    [string]$WebConfigFolder=$WebConfigFolderDest+"\calcmenuapi"
    $WebConfigFolderSim=$WebConfigFolderDest
    $KeyTempURL="https"+"://$fctUrlNameServer.calcmenuweb.com" #https://eoc.calcmenuweb.com
    $KeyTempURL=$KeyTempURL.ToLower()
    $KeyTempURLSource="https"+"://$fctUrlNameServerSource.calcmenuweb.com" #https://eoc.calcmenuweb.com
    $KeyTempURLSource=$KeyTempURLSource.ToLower()
    $TmpX=[Regex]::Escape($WebConfigFolderSource)
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config"   $TmpX  $WebConfigFolderSim #2021-07-13  

    [string]$WebConfigFolder=$WebConfigFolderDest+'\kiosk'
    $tempKeyReportFolderSource=$fctPathcmwebCurrentSource+"\CalcmenuWeb" 
    $TmpX=[Regex]::Escape($tempKeyReportFolderSource)
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    ChangeConfig "$WebConfigFolder\web.config"  $TmpX  $tempKeyReportFolder 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\ws'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\wsapi'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    #
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\inventory'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\RecipeExport'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\DataExport'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\DataAnalytics'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\RecipeImport'
    ChangeConfig "$WebConfigFolder\web.config" $fctDataSourceIPSource $fctDataSourceIP 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\MenuPlanView'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    #
    [string]$WebConfigFolder=$WebConfigFolderDest+'\shoppinglistWS'
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    #
    #
    $fctLanguageCodeSource=""""+$fctLanguageCodeSource+""""
    $fctLanguageCode=""""+$fctLanguageCode+""""
    #
    [string]$WebConfigFolder="$WebConfigFolderDest\ReportXML"
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    #
    [string]$WebConfigFolder="$WebConfigFolderDest\emenu"
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    #
    [string]$WebConfigFolder="$WebConfigFolderDest\emenuplan"
    ChangeConfig "$WebConfigFolder\web.config"  $fctDataSourceIPSource $fctDataSourceIP 
    #
    [string]$WebConfigFolder="$WebConfigFolderDest\erecipe\ClientApp\dist\assets"
    #
    [string]$WebConfigFolder="$WebConfigFolderDest\erecipe"
    ChangeConfig "$WebConfigFolder\appSettings.json"  $fctDataSourceIPSource $fctDataSourceIP 
    #
    [string]$WebConfigFolder="$WebConfigFolderDest\erecipe\ClientApp\dist"
    #
    $TmpX=[Regex]::Escape($WebConfigFolderSource)
    $WebConfigFolder=$WebConfigFolderDest+'\AdvancedShoppingList'
    ChangeConfig "$WebConfigFolder\web.config" $fctDataSourceIPSource $fctDataSourceIP  
    ChangeConfig "$WebConfigFolder\web.config" $TmpX $WebConfigFolderDest 
    #
    Write-Host "CHANGES IN WEB.CONFIG AND OTHER JS FILES HAVE BEEN COMPLETED" -foregroundcolor "green"
    #
}
#

#
function fctChangeHttpToHttpsInConfigsNew
{
    param( [string]$fctPathcmwebCurrent, [string]$fctClientName, [string]$fctUrlNameServer)

    #
    if (Test-Path "c:\Website\$fctClientName")
    {
        $functionPathcmweb="c:"
    }
    else
    {
        if (Test-Path "d:\Website\$fctClientName")
        {
            $functionPathcmweb="d:"
        }
        else
        {
            #if (Test-Path "e:\Website\$fctClientName")
            #{
            #    $functionPathcmweb="e:"
            #}
            #else
            #{
            #}
            write-host "Drive was not found (fctChangeHttpToHttpsInConfigsNew)" -ForegroundColor Red

        }
    }
    #
    $WebConfigFolder=$fctPathcmwebCurrent+"\CalcmenuWeb"
    write-host "Current Folder:"$WebConfigFolder
    ChangeConfig "$WebConfigFolder\web.config" "http://$fctUrlNameServer.calcmenuweb.com" "https://$fctUrlNameServer.calcmenuweb.com" 
        
    $WebConfigFolder=$WebConfigFolder+"\calcmenuapi"
    ChangeConfig "$WebConfigFolder\web.config" "http://$fctUrlNameServer.calcmenuweb.com" "https://$fctUrlNameServer.calcmenuweb.com" 
        
    $WebConfigFolder=$WebConfigFolder+'\kiosk'
    ChangeConfig "$WebConfigFolder\web.config" "http://$fctUrlNameServer.calcmenuweb.com" "https://$fctUrlNameServer.calcmenuweb.com" 
        
    $WebConfigFolder="$functionPathcmweb\Website\"+$fctClientName+'\CalcmenuWeb\kiosk\assets\js'
    ChangeConfig "$WebConfigFolder\kiosk.baseURL.min.js" "http://$fctUrlNameServer.calcmenuweb.com" "https://$fctUrlNameServer.calcmenuweb.com" 

    $WebConfigFolder="$functionPathcmweb\Website\"+$fctClientName+'\CalcmenuWeb\ReportXML'
    ChangeConfig "$WebConfigFolder\web.config" "http://$fctUrlNameServer.calcmenuweb.com" "https://$fctUrlNameServer.calcmenuweb.com" 
        
    $WebConfigFolderEmenu=$WebConfigFolder+'\eMenu\js'
    ChangeConfig "$WebConfigFolder\kiosk.core.js" "http://$fctUrlNameServer.calcmenuweb.com" "https://$fctUrlNameServer.calcmenuweb.com" 
        
    #
    Write-Host "CHANGES IN WEB.CONFIG AND OTHER JS FILES HAVE BEEN COMPLETED" -foregroundcolor "green"
    #
}
#
#############################################################################################################
Function New-R53ResourceRecordSet
{
	param(
	[Parameter(Mandatory=$True,Position=1)]
        [String]$ProfileName,
        [Parameter(Mandatory=$True)]
        [String]$Value,
	[Parameter(Mandatory=$True)]
        $Type,
	[Parameter(Mandatory=$True)]
        $RecordName,
	[Parameter(Mandatory=$True)]
        $TTL,
	[Parameter(Mandatory=$True)]
        $ZoneName,
        [Parameter(Mandatory=$False)]
        $Comment
	)
 
	$ZoneEntry = (Get-R53HostedZones -ProfileName $ProfileName) | ? {$_.Name -eq "$($ZoneName)."}
	
	If($ZoneEntry){
	    $CreateRecord = New-Object Amazon.Route53.Model.Change
        $CreateRecord.Action = "CREATE"
        $CreateRecord.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
        $CreateRecord.ResourceRecordSet.Name = "$RecordName.$ZoneName"
        $CreateRecord.ResourceRecordSet.Type = $Type
        $CreateRecord.ResourceRecordSet.TTL = $TTL
        $CreateRecord.ResourceRecordSet.ResourceRecords.Add(@{Value="$Value"})
	    Edit-R53ResourceRecordSet -ProfileName $ProfileName -HostedZoneId $ZoneEntry.Id -ChangeBatch_Change $CreateRecord -ChangeBatch_Comment $Comment
	}
    Else 
    {
        Write-Host "Zone name '$ZoneName' not found using AWS Profile $ProfileName"
    }
}
#New-R53ResourceRecordSet -ProfileName "cmweb" -Value "54.77.170.7" -Type "A" -RecordName "sandro" -TTL 3600 -ZoneName "recipecenter.com"   


Function Update-R53ResourceRecordSet
{
    param(
    [Parameter(Mandatory=$False,Position=1)][String]$ProfileName,
    [Parameter(Mandatory=$True)][String]$Value,
    [Parameter(Mandatory=$True)][ValidateSet("CNAME","A","AAAA","MX","TXT","PTR","SRV","SPF","NS","SOA")]$Type,
    [Parameter(Mandatory=$True)]$RecordName,
    [Parameter(Mandatory=$True)]$TTL,
    [Parameter(Mandatory=$True)]$ZoneName,
    [Parameter(Mandatory=$False)]$Comment
    )
         
    #$ZoneEntry = (Get-R53HostedZones -ProfileName $ProfileName) | ? {$_.Name -eq "$($ZoneName)."}
    $ZoneEntry = (Get-R53HostedZones) | ? {$_.Name -eq "$($ZoneName)."}
                        
    If($ZoneEntry)
    {
        $CreateRecord = New-Object Amazon.Route53.Model.Change
        $CreateRecord.Action = "UPSERT"
        $CreateRecord.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
        $CreateRecord.ResourceRecordSet.Name = "$RecordName.$ZoneName"
        $CreateRecord.ResourceRecordSet.Type = $Type
        $CreateRecord.ResourceRecordSet.TTL = $TTL
        $CreateRecord.ResourceRecordSet.ResourceRecords.Add(@{Value="$Value"})
        Edit-R53ResourceRecordSet -ProfileName $ProfileName -HostedZoneId $ZoneEntry.Id -ChangeBatch_Change $CreateRecord -ChangeBatch_Comment $Comment
    } 
    Else 
    {
        Write-Host "Zone name '$ZoneName' not found using AWS Profile"
    }
}


Function BindWebsite {
    param( [string]$ip, [string]$drivePath, [string]$client, [string]$AppNameBinding)
    Import-Module WebAdministration

    $websitePath = $drivePath+"\Website"
    #$clientAll = Get-ChildItem -Path $websitePath
    $iisAppPoolDotNetVersion = "v4.0"
    
    $certificate = "*.calcmenuweb.com*"
    $thumbprint = $CertificateThumbprint #"92ABF9A806ECC6A7B744AF96060E7D2848F23E91" #(Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "*$certificate*"}).Thumbprint
    
    #foreach($client in $clientAll) {

    $iisAppName = "CalcmenuWeb_"+$client
    $iisAppNameAfter = "CalcmenuWeb_"+$client
    $iisAppPoolName = "CalcmenuWeb_"+$client
    $clientUpperCase = "$client".ToUpper();
    $clientLowerCase = "$client".ToLower();
    $iisAppNameBinding =$AppNameBinding+".calcmenuweb.com"
    $directoryPath = $drivePath+"\Website\"+$client+"\CalcmenuWeb"

    Set-Location IIS:\AppPools\ # Added 2025-06-29
    CD IIS:\AppPools\

    $iisAppPoolDotNetVersion = "v4.0"
    #Check if the app pool exists
    if (!(Test-Path $iisAppPoolName -PathType Container)) {
        $appPool =  New-Item $iisAppPoolName
        $appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $iisAppPoolDotNetVersion
        $appPool | Set-ItemProperty -Name "enable32BitAppOnWin64" -Value "True"
        Write-Host "`nAPPLICATION POOL HAS BEEN SETUP FOR $clientUpperCase" -ForegroundColor Green
    }  
    $iisAppPoolDotNetVersionERecipe = "No Managed Code"
    $iisAppNameERecipe = $iisAppName+"_eRecipe"
    #Check if the app pool exists
    if (!(Test-Path $iisAppNameERecipe -PathType Container)) {
        $appPool =  New-Item $iisAppNameERecipe
        $appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $iisAppPoolDotNetVersionERecipe
        $appPool | Set-ItemProperty -Name "enable32BitAppOnWin64" -Value "True"
        Write-Host "`nAPPLICATION POOL HAS BEEN SETUP FOR $clientUpperCase" -ForegroundColor Green
    }  
        
    CD IIS:\Sites\
        
    $clientWebsites = Get-ChildItem IIS:\Sites\

   
     if (!(Test-Path $iisAppName -PathType Container)) 
     {
        #Check if the website exists.
        #If website do not, website will be made.
        $AllUnassigned = "*"
    
        if (!(Test-Path $iisAppName -PathType Container)) {
            $binding =(
                @{protocol="http";bindingInformation="$($AllUnassigned):80:"+$iisAppNameBinding},
                @{protocol="https";bindingInformation="$($AllUnassigned):443:"+$iisAppNameBinding;certificateThumbprint=$thumbprint;SslFlags=1})  #$cert.Thumbprint;certificateStoreName='My'
            New-Item $iisAppName -Type Site –PhysicalPath $directoryPath -Bindings $binding -Force
            Set-ItemProperty -Path $iisAppName -Name "applicationPool" -Value $iisAppPoolName
            Write-Host "`nWEBSITE HAS BEEN SET UP FOR $clientUpperCase" -ForegroundColor Green
        }
         
        #Convert to web applications.
            
        $calcmenuapiAppPath = "$iisAppName\calcmenuapi"
        ConvertTo-WebApplication $calcmenuapiAppPath -Force | Out-Null
        Set-ItemProperty -Path $calcmenuapiAppPath -Name "applicationPool" -Value $iisAppPoolName

        #$declarationAppPath = "$iisAppName\Declaration"
        #ConvertTo-WebApplication $declarationAppPath -Force | Out-Null
        #Set-ItemProperty -Path $declarationAppPath -Name "applicationPool" -Value $iisAppPoolName

        $kioskAppPath = "$iisAppName\kiosk"
        ConvertTo-WebApplication $kioskAppPath -Force | Out-Null
        Set-ItemProperty -Path $kioskAppPath -Name "applicationPool" -Value $iisAppPoolName
        #
        $checkAppPathToConvert="$websitePath\$client\CalcmenuWeb\ws"
        write-host $checkAppPathToConvert -ForegroundColor Yellow
        If (Test-Path $checkAppPathToConvert)
        {
            $wsAppPath = "$iisAppName\ws"
            ConvertTo-WebApplication $wsAppPath -Force | Out-Null
            Set-ItemProperty -Path $wsAppPath -Name "applicationPool" -Value $iisAppPoolName
        }
        else
        {
            Write-host "Could not find path ($checkAppPathToConvert). App not converted." -ForegroundColor Red
        }
        #
        $reportXMLAppPath = "$iisAppName\ReportXML"
        ConvertTo-WebApplication $reportXMLAppPath -Force | Out-Null
        Set-ItemProperty -Path $reportXMLAppPath -Name "applicationPool" -Value $iisAppPoolName
        #
        $checkAppPathToConvert="$websitePath\$client\CalcmenuWeb\emenu"
        write-host $checkAppPathToConvert -ForegroundColor Yellow
        If (Test-Path $checkAppPathToConvert)
        {
            $emenuAppPath = "$iisAppName\emenu"
            ConvertTo-WebApplication $emenuAppPath -Force | Out-Null
            Set-ItemProperty -Path $emenuAppPath -Name "applicationPool" -Value $iisAppPoolName
        }
        else
        {
            Write-host "Could not find path ($checkAppPathToConvert). App not converted." -ForegroundColor Red
        }
        #
        $checkAppPathToConvert="$websitePath\$client\CalcmenuWeb\emenuplan"
        write-host $checkAppPathToConvert -ForegroundColor Yellow
        If (Test-Path $checkAppPathToConvert)
        {
            $emenuplanAppPath = "$iisAppName\emenuplan"
            ConvertTo-WebApplication $emenuplanAppPath -Force | Out-Null
            Set-ItemProperty -Path $emenuplanAppPath -Name "applicationPool" -Value $iisAppPoolName
        }
        else
        {
            Write-host "Could not find path ($checkAppPathToConvert). App not converted." -ForegroundColor Red
        }
        #
        #4/8/2022
        $checkAppPathToConvert="$websitePath\$client\CalcmenuWeb\erecipe"
        write-host $checkAppPathToConvert -ForegroundColor Yellow
        If (Test-Path $checkAppPathToConvert)
        {
            $iisAppPoolNameERecipe=$iisAppPoolName+"_eRecipe" #2022-11-24
            $emenuplanAppPath = "$iisAppName\erecipe"
            ConvertTo-WebApplication $emenuplanAppPath -Force | Out-Null
            Set-ItemProperty -Path $emenuplanAppPath -Name "applicationPool" -Value $iisAppPoolNameERecipe
        }
        else
        {
            Write-host "Could not find path ($checkAppPathToConvert). App not converted." -ForegroundColor Red
        }
        #4/8/2022
        #
        $checkAppPathToConvert="$websitePath\$client\CalcmenuWeb\wsapi"
        write-host $checkAppPathToConvert -ForegroundColor Yellow
        If (Test-Path $checkAppPathToConvert)
        {
            $wsapiAppPath = "$iisAppName\wsapi"
            ConvertTo-WebApplication $wsapiAppPath -Force | Out-Null
            Set-ItemProperty -Path $wsapiAppPath -Name "applicationPool" -Value $iisAppPoolName
        }
        else
        {
            Write-host "Could not find path ($checkAppPathToConvert). App not converted." -ForegroundColor Red
        }
        #
        #
        $checkAppPathToConvert="$websitePath\$client\CalcmenuWeb\RecipeExport"
        write-host $checkAppPathToConvert -ForegroundColor Yellow
        If (Test-Path $checkAppPathToConvert)
        {
            $wsapiAppPath = "$iisAppName\RecipeExport"
            ConvertTo-WebApplication $wsapiAppPath -Force | Out-Null
            Set-ItemProperty -Path $wsapiAppPath -Name "applicationPool" -Value $iisAppPoolName
        }
        else
        {
            Write-host "Could not find path ($checkAppPathToConvert). App not converted." -ForegroundColor Red
        }
        #
        #
        $checkAppPathToConvert="$websitePath\$client\CalcmenuWeb\DataExport"
        write-host $checkAppPathToConvert -ForegroundColor Yellow
        If (Test-Path $checkAppPathToConvert)
        {
            $wsapiAppPath = "$iisAppName\DataExport"
            ConvertTo-WebApplication $wsapiAppPath -Force | Out-Null
            Set-ItemProperty -Path $wsapiAppPath -Name "applicationPool" -Value $iisAppPoolName
        }
        else
        {
            Write-host "Could not find path ($checkAppPathToConvert). App not converted." -ForegroundColor Red
        }
        #
        #
        $checkAppPathToConvert="$websitePath\$client\CalcmenuWeb\DataAnalytics"
        write-host $checkAppPathToConvert -ForegroundColor Yellow
        If (Test-Path $checkAppPathToConvert)
        {
            $wsapiAppPath = "$iisAppName\DataAnalytics"
            ConvertTo-WebApplication $wsapiAppPath -Force | Out-Null
            Set-ItemProperty -Path $wsapiAppPath -Name "applicationPool" -Value $iisAppPoolName
        }
        else
        {
            Write-host "Could not find path ($checkAppPathToConvert). App not converted." -ForegroundColor Red
        }
        #
        #
        $checkAppPathToConvert="$websitePath\$client\CalcmenuWeb\RecipeImport"
        write-host $checkAppPathToConvert -ForegroundColor Yellow
        If (Test-Path $checkAppPathToConvert)
        {
            $wsapiAppPath = "$iisAppName\RecipeImport"
            ConvertTo-WebApplication $wsapiAppPath -Force | Out-Null
            Set-ItemProperty -Path $wsapiAppPath -Name "applicationPool" -Value $iisAppPoolName
        }
        else
        {
            Write-host "Could not find path ($checkAppPathToConvert). App not converted." -ForegroundColor Red
        }
        #
        #
        $checkAppPathToConvert="$websitePath\$client\CalcmenuWeb\shoppinglistWS"
        write-host $checkAppPathToConvert -ForegroundColor Yellow
        If (Test-Path $checkAppPathToConvert)
        {
            $wsapiAppPath = "$iisAppName\shoppinglistWS"
            ConvertTo-WebApplication $wsapiAppPath -Force | Out-Null
            Set-ItemProperty -Path $wsapiAppPath -Name "applicationPool" -Value $iisAppPoolName
        }
        else
        {
            Write-host "Could not find path ($checkAppPathToConvert). App not converted." -ForegroundColor Red
        }
        #
        #
        $checkAppPathToConvert="$websitePath\$client\CalcmenuWeb\MenuPlanView"
        write-host $checkAppPathToConvert -ForegroundColor Yellow
        If (Test-Path $checkAppPathToConvert)
        {
            $wsapiAppPath = "$iisAppName\MenuPlanView"
            ConvertTo-WebApplication $wsapiAppPath -Force | Out-Null
            Set-ItemProperty -Path $wsapiAppPath -Name "applicationPool" -Value $iisAppPoolName
        }
        else
        {
            Write-host "Could not find path ($checkAppPathToConvert). App not converted." -ForegroundColor Red
        }
        #
        #
        $checkAppPathToConvert="$websitePath\$client\CalcmenuWeb\inventory"
        write-host $checkAppPathToConvert -ForegroundColor Yellow
        If (Test-Path $checkAppPathToConvert)
        {
            $wsapiAppPath = "$iisAppName\inventory"
            ConvertTo-WebApplication $wsapiAppPath -Force | Out-Null
            Set-ItemProperty -Path $wsapiAppPath -Name "applicationPool" -Value $iisAppPoolName
        }
        else
        {
            Write-host "Could not find path ($checkAppPathToConvert). App not converted." -ForegroundColor Red
        }
        #
        #
        $checkAppPathToConvert="$websitePath\$client\CalcmenuWeb\AdvancedShoppingList"
        write-host $checkAppPathToConvert -ForegroundColor Yellow
        If (Test-Path $checkAppPathToConvert)
        {
            $wsapiAppPath = "$iisAppName\AdvancedShoppingList"
            ConvertTo-WebApplication $wsapiAppPath -Force | Out-Null
            Set-ItemProperty -Path $wsapiAppPath -Name "applicationPool" -Value $iisAppPoolName
        }
        else
        {
            Write-host "Could not find path ($checkAppPathToConvert). App not converted." -ForegroundColor Red
        }
        #
        Write-Host "APPLICATION FOLDERS HAVE BEEN CONVERTED" -foregroundcolor "green"

    }
    


    #If website exist, it will check if it has the http and https binding.
    else {
        $iisAppNamePath = "IIS:\Sites\"+$iisAppName
        $clientWebsite = Get-Item $iisAppNamePath

        [bool]$hasHTTP = $false
        [bool]$hasHTTPS = $false
            
        #Gets the protocol of binding if http or http exist. 
        $binding = $clientWebsite.bindings
        [string]$bindingInfo = $binding.Collection
        [string[]]$bindings = $bindingInfo.Split(" ")

        $i = 0
        Do {
            if("http" -eq $bindings[($i)]) {
                $hasHTTP = $true
            }
                
            if("https" -eq $bindings[($i)]) {
                $hasHTTPS = $true
            }
            $i=$i+2
        }
        While ($i -lt ($bindings.count))

        #If http and/or https binding do not exist, the binding will be override to have http and https bindings.
        #If one of http or https binding do not exist, it is better to override the existing binding to make sure
        #that the website is binded with the ip address.
        $AllUnassigned = "*"
        if(($hasHTTP -eq $false) -or ($hasHTTPS -eq $false)){
            $binding =(
                @{protocol="http";bindingInformation="$($AllUnassigned):80:"+$iisAppNameBinding},
                @{protocol="https";bindingInformation="$($AllUnassigned):443:"+$iisAppNameBinding;SslFlags=1})
            New-Item $iisAppName -Type Site –PhysicalPath $directoryPath -bindings $binding -Force
            Set-ItemProperty -Path $iisAppName -Name "applicationPool" -Value $iisAppPoolName
            Write-Host "WEBSITE HAS BEEN SET UP FOR $clientUpperCase" -ForegroundColor Green
        }
        else {
            Write-Host "`nNO NEW SET UP HAS BEEN MADE FOR $clientUpperCase" -ForegroundColor Yellow
        }
    }
    

    #Check if certificate is already assigned for ip and port number.
    try {
        $cert = "cert:\LocalMachine\MY\"+$thumbprint
        $assignCert = "IIS:\SslBindings\"+$ip+"!443"
        $error= Get-Item $cert | New-Item $assignCert -ErrorAction SilentlyContinue
        Write-Host "`nCERTIFICATE HAS BEEN ASSIGNED FOR IP ADDRESS $ip WITH PORT 443" -ForegroundColor Green
    }
    catch {
        if($error -like "*Cannot create a file when that file already exists*") {
            Write-Host "`nCERTIFICATE ALREADY ASSIGNED FOR IP ADDRESS $ip WITH PORT 443" -ForegroundColor Yellow
        }
        else {
            Write-Host "FAILED TO ASSIGN SSL CERTIFICATE. ERROR: $error" -ForegroundColor Red
        }
    }
}

Function WebConfigRewrite {
    param( [string]$drivePath, [string]$client)
    
    $websitePath = $drivePath+"\Website"
    #$clientAll = Get-ChildItem -Path $websitePath

    #foreach($client in $clientAll) {
        $webConfig = $drivePath+"\Website\"+$client+"\CalcmenuWeb\web.config"
        
        if(-not(Test-Path $webConfig.trim())) {
            Write-Host "`nWeb.config file do not exist on $client" -ForegroundColor RED
        }
        else {
            $xmlData = (Get-Content $webConfig) -as [Xml]

            $systemWebServer = $xmlData.SelectSingleNode("//configuration/system.webServer")
            $rewriteNode = $xmlData.SelectSingleNode("//configuration/system.webServer/rewrite")

            if(-not $rewriteNode) {
                $rewrite = $xmlData.CreateElement("rewrite")
                $newRewrite = $systemWebServer.AppendChild($rewrite)
    
                $rules = $xmlData.CreateElement("rules")
                $newRules = $newRewrite.AppendChild($rules)
    
                $clear = $xmlData.CreateElement("clear")
                $newClear = $newRules.AppendChild($clear)
    
                $rule = $xmlData.CreateElement('rule')
                $newRule = $newRules.AppendChild($rule)
                $newRule.SetAttribute("name", "HTTP to HTTPS redirect")
                $newRule.SetAttribute("enabled", "true")
                $newRule.SetAttribute("stopProcessing", "true")
    
                $match = $xmlData.CreateElement('match')
                $newMatch = $newRule.AppendChild($match)
                $newMatch.SetAttribute("url", "(.*)")

                $conditions = $xmlData.CreateElement("conditions")
                $newConditions = $newRule.AppendChild($conditions)
                $newConditions.SetAttribute("logicalGrouping", "MatchAll")
                $newConditions.SetAttribute("trackAllCaptures", "false")

                $add = $xmlData.CreateElement("add")
                $newAdd = $newConditions.AppendChild($add)
                $newAdd.SetAttribute("input", "{HTTPS}")
                $newAdd.SetAttribute("pattern", "off")
                $newAdd.SetAttribute("ignoreCase", "true")

                $action = $xmlData.CreateElement("action")
                $newAction = $newRule.AppendChild($action)
                $newAction.SetAttribute("type", "Redirect")
                $newAction.SetAttribute("url", "https://{HTTP_HOST}/{R:1}")
                $newAction.SetAttribute("redirectType", "Found")

                try {
                    $xmlData.Save($webConfig)      
                }
                catch {
                    $errorMessage = $_.Exception.Message
                }
                finally {
                    if($errorMessage.length -eq 0) {
                        Write-Host "`nWeb.config changes has been made for $client " -ForegroundColor GREEN
                    }
                    else {
                        Write-Host "`nError in updating web.config for $client : $errorMessage" -ForegroundColor RED
                    }
                }
            }
            else {
                 Write-Host "`nNo web.config changes has been made for $client " -ForegroundColor YELLOW
            }
        }
    #}
}

Function ReadUrlFromConfigFile {
    param( [string]$fctProjectNameToDeploy)

    #Read the file that contain the deployment information
    $DFCompletePath="C:\EgsExchange\ToDeploy\WebDeployList$fctProjectNameToDeploy.txt"
    if (!(Test-Path $DFCompletePath)) 
    {
        $DFCompletePath="D:\EgsExchange\ToDeploy\WebDeployList$fctProjectNameToDeploy.txt"
        if (!(Test-Path $DFCompletePath)) 
        {
            Write-host "The file with deployment information does not exist." -ForegroundColor Red
            Write-host "SCRIPT INTERRUPTED" -ForegroundColor Red
            Break
        }
    }
    $filedata=Get-Content $DFCompletePath
    foreach ($line in $filedata)
    {
        if ($line -like '*URL=*') { $sURL=($line).Replace("URL=","") }
    }
    return $sURL
}

Function ReadFromConfigFileForCopyWeb {
    param( [string]$fctProjectNameToDeploy)

    #Read the file that contain the deployment information
    $DFCompletePath="C:\EgsExchange\ToDeploy\WebDeployList$fctProjectNameToDeploy.txt"
    if (!(Test-Path $DFCompletePath)) 
    {
        $DFCompletePath="D:\EgsExchange\ToDeploy\WebDeployList$fctProjectNameToDeploy.txt"
        if (!(Test-Path $DFCompletePath)) 
        {
            Write-host "The file with deployment information does not exist." -ForegroundColor Red
            Write-host "SCRIPT INTERRUPTED" -ForegroundColor Red
            Break
        }
    }
    $filedata=Get-Content $DFCompletePath
    foreach ($line in $filedata)
    {
        if ($line -like '*Name=*') { $fctClientNameSource=($line).Replace("Name=","") }
        if ($line -like '*URL=*') { $fctUrlNameServerSource=($line).Replace("URL=","") }
        if ($line -like '*HTTPS=*') { $fctHTTPSSource=($line).Replace("HTTPs=","") }
        if ($line -like '*PasswordDb=*') { $fctPasswordDbSource=($line).Replace("PasswordDB=","") }
        if ($line -like '*LanguageCode=*') { $fctLanguageCodeSource=($line).Replace("LanguageCode=","") }
        if ($line -like '*IsMigros=*') { $fctIsMigrosSource=($line).Replace("IsMigros=","") }
    }
    return $fctClientNameSource,$fctHTTPSSource,$fctIsMigrosSource,$fctLanguageCodeSource,$fctPasswordDbSource,$fctUrlNameServerSource
}


#
#############################################################################################################
#############################################################################################################
#############################################################################################################
#############################################################################################################
#############################################################################################################
### END FUNCTIONS
#############################################################################################################
#############################################################################################################
#############################################################################################################
#############################################################################################################
#############################################################################################################
#    
If ($ConversionVersionToForcedStr -eq "")
{ $ConversionVersionToForced=0 }
else
{ $ConversionVersionToForced=[int]$ConversionVersionToForcedStr }
#-#$ConversionVersionToForced=41999 #Set to 0 if should be taken from EgsData.Dll
#
#
Write-host "########### EGS TOOL ###########" -foregroundcolor cyan
Write-host "### Project: $ProjectNameToDeploy " -foregroundcolor cyan
Write-host "### Version to install: $DOVersion\$DOVersionMain" -foregroundcolor cyan
Write-host "### Version of tool: $VersionTool" -ForegroundColor cyan
#
#
#####################################################################################################
#
##
#GET DEPLOY FILES BY TRYING
if (($DoApp -eq "1") -or ($DoIIS -eq "1") -or ($DOSql1 -eq "1") -or ($DOUpdate -eq "1") -or ($UpdateFolderKiosk -eq "1") -or ($DoCopyWeb -eq "1") -or ($DoRestoreWeb -eq "1") -or ($DoHttpToHttps -eq "1")) {
    #Find the path of EgsExchange by testing
    $PathcmwebRoot=""
    If (Test-Path "C:\EgsExchange") 
    { 
        $PathcmwebRoot="C:\EgsExchange" 
    }
    else
    {
        If (Test-Path "D:\EgsExchange") 
        { 
            $PathcmwebRoot="D:\EgsExchange" 
        }
        else
        {
            If (Test-Path "\\egs\Websites") { $PathcmwebRoot="\\egs\Websites" }
        }
    }
    #Find the profile by testing
    $ProfileNameAWS=""
    $ProfileNameAWS="egs.s31" 
    #
    If ($PathcmwebRoot -eq "") 
    {
        Write-Host "Cannot find the location of Exchange folder - script interrupted" -ForegroundColor Red
        Break
    }
    else { Write-Host "Location of Exchange folder: $PathcmwebRoot" -ForegroundColor Cyan }
    If ($ProfileNameAWS -eq "") 
    {
        Write-Host "Cannot find the AWS credentials" -ForegroundColor DarkYellow
        $ProfileNameAWS="egs.sandro"
        Write-Host "Trying with following AWS credentials: $ProfileNameAWS" -ForegroundColor yellow 
        #Break
    }
    else { Write-Host "Name of AWS Credentials: $ProfileNameAWS" -ForegroundColor Cyan }
    If (($PathcmwebRoot -ne "") -and ($ProfileNameAWS -ne ""))
    {
        Write-host "Retrieving Deployment Data from CLoud" -ForegroundColor Yellow
        & $AwsExeFile --profile=$ProfileNameAWS s3 sync 's3://cmweb/ToDeploy' "$PathcmwebRoot\ToDeploy"  --delete --exact-timestamps
    }
}
#
#CHECK WHICH SERVER WE ARE
#
#GetComputerName
$ComputerNameOfCurrentServer=$env:computername
#Get-WMIObject Win32_ComputerSystem | Select-Object -ExpandProperty name
#[system.environment]::MachineName
#
If ($ComputerNameOfCurrentServer -eq "SANDRO") { $servercurrent="Local" }

If ($ComputerNameOfCurrentServer -eq "PONTUS")  { $servercurrent="Pontus"}
If ($ComputerNameOfCurrentServer -eq "PALLAS")  { $servercurrent="Pallas"}
If ($ComputerNameOfCurrentServer -eq "TYPHON")  { $servercurrent="Typhon"}
If ($ComputerNameOfCurrentServer -eq "TALOS")  { $servercurrent="Talos"}
Write-host "Current Server is: $servercurrent" -ForegroundColor Yellow
#
#
#READ DEPLOY FILE
#
If (($DoApp -eq "1") -or ($DoIIS -eq "1") -or ($DOSql1 -eq "1") -or ($DOSql2 -eq "1") -or ($DOSql3 -eq "1") -or ($UpdateFolderKioskDb -eq "1") -or ($DOSql9 -eq "1") -or ($DoRemoveWeb -eq "1") -or ($DoRemoveDb -eq "1") -or ($DoUpdate -eq "1") -or ($UpdateFolderKiosk -eq "1") -or ($DoUpdateClientLogo -eq "1") -or ($DoUpdateCmWebLogo -eq "1") -or ($DoUpdateKey -eq "1") -or ($DoChangeUrl -gt "0") -or ($DoCopyWeb -eq "1") -or ($DoRestoreWeb -eq "1") -or ($DoHttpToHttps -eq "1"))
{
    #
    #Read the file that contain the deployment information
    $DeploymentFileCompletePath="C:\EgsExchange\ToDeploy\WebDeployList$ProjectNameToDeploy.txt"
    if (!(Test-Path $DeploymentFileCompletePath)) 
    {
        $DeploymentFileCompletePath="D:\EgsExchange\ToDeploy\WebDeployList$ProjectNameToDeploy.txt"
        if (!(Test-Path $DeploymentFileCompletePath)) 
        {
            Write-host "The file with deployment information does not exist." -ForegroundColor Red
            Write-host "SCRIPT INTERRUPTED" -ForegroundColor Red
            Break
        }
    }
    $filedata=Get-Content $DeploymentFileCompletePath
    #$filedata[0]
    foreach ($line in $filedata)
                                                                                                                                                                                                                                                            {
        #write-host $line
        if ($line -like '*Name=*') { $ClientName=($line).Replace("Name=","") }
        if ($line -like '*Enum=*') { $Enum=($line).Replace("Enum=","") }
        if ($line -like '*TotalUserPerSite=*') { $TotalUserPerSite=($line).Replace("TotalUserPerSite=","") }
        if ($line -like '*TotalProperty=*') { $TotalProperty=($line).Replace("TotalProperty=","") }
        if ($line -like '*TotalSites=*') { $TotalSites=($line).Replace("TotalSites=","") }
        if ($line -like '*TotalKioskUserPerSite=*') { $TotalKioskUserPerSite=($line).Replace("TotalKioskUserPerSite=","") }
        if ($line -like '*Edition=*') { $Edition=($line).Replace("Edition=","") }
        if ($line -like '*Version=*') { $VersionCm=($line).Replace("Version=","") }
        if ($line -like '*Auditing=*') { $Auditing=($line).Replace("Auditing=","") }
        if ($line -like '*PrepAutoSpacing=*') { $PrepAutoSpacing=($line).Replace("PrepAutoSpacing=","") }
        if ($line -like '*DateValidity=*') { $DateValidity=($line).Replace("dateValidity=","") }
        if ($line -like '*Nut_USDA=*') { $Nut_USDA=($line).Replace("Nut_USDA=","") }
        if ($line -like '*Nut_AUSNUT=*') { $Nut_AUSNUT=($line).Replace("Nut_AUSNUT=","") }
        if ($line -like '*Nut_BLS=*') { $Nut_BLS=($line).Replace("Nut_BLS=","") }
        if ($line -like '*Nut_SWISSFOOD=*') { $Nut_SWISSFOOD=($line).Replace("Nut_SWISSFOOD=","") }
        if ($line -like '*Nut_CIQUAL=*') { $Nut_CIQUAL=($line).Replace("Nut_CIQUAL=","") }
        if ($line -like '*Nut_NUBEL=*') { $Nut_NUBEL=($line).Replace("Nut_NUBEL=","") }
        if ($line -like '*Nut_BEDCA=*') { $Nut_BEDCA=($line).Replace("Nut_BEDCA=","") }
        if ($line -like '*Nut_UK=*') { $Nut_UK=($line).Replace("Nut_UK=","") }
        if ($line -like '*Nut_INRAN=*') { $Nut_INRAN=($line).Replace("Nut_INRAN=","") }
        if ($line -like '*Nut_COFID=*') { $Nut_COFID=($line).Replace("Nut_COFID=","") }
        if ($line -like '*Nut_CFS_NIIS=*') { $Nut_CFS_NIIS=($line).Replace("Nut_CFS_NIIS=","") }
        if ($line -like '*Nut_CNF=*') { $Nut_CNF=($line).Replace("Nut_CNF=","") }
        if ($line -like '*Nut_HPB=*') { $Nut_HPB=($line).Replace("Nut_HPB=","") }
        if ($line -like '*Nut_SWISSFOODS=*') { $Nut_SWISSFOODS=($line).Replace("Nut_SWISSFOODS=","") }
        if ($line -like '*Nut_SWISSFOODS5_D=*') { $Nut_SWISSFOODS5_D=($line).Replace("Nut_SWISSFOODS5_D=","") }
        if ($line -like '*Nut_ASA=*') { $Nut_ASA=($line).Replace("Nut_ASA=","") }
        if ($line -like '*Nut_SGE04_G=*') { $Nut_SGE04_G=($line).Replace("Nut_SGE04_G=","") }
        if ($line -like '*Nut_SGE04_F=*') { $Nut_SGE04_F=($line).Replace("Nut_SGE04_F=","") }
        if ($line -like '*Nut_SGE04_I=*') { $Nut_SGE04_I=($line).Replace("Nut_SGE04_I=","") }
        if ($line -like '*Nut_INN=*') { $Nut_INN=($line).Replace("Nut_INN=","") }
        if ($line -like '*URL=*') { $URL=($line).Replace("URL=","") }
        if ($line -like '*URLtest=*') { $URLtest=($line).Replace("URLtest=","") }
        if ($line -like '*HTTPS=*') { $HTTPS=($line).Replace("HTTPs=","") }
        if ($line -like '*ServerApp=*') { $ServerApp=($line).Replace("ServerApp=","") }
        if ($line -like '*ServerSql=*') { $ServerSql=($line).Replace("ServerSql=","") }
        if ($line -like '*DatabaseReference=*') { $DatabaseReference=($line).Replace("DatabaseReference=","") }
        if ($line -like '*PasswordDb=*') { $PasswordDb=($line).Replace("PasswordDB=","") }
        if ($line -like '*PasswordAdmin=*') { $PasswordAdmin=($line).Replace("PasswordAdmin=","") }
        if ($line -like '*PasswordAdminEncrypt=*') { $PasswordAdminEncrypt=($line).Replace("PasswordAdminEncrypt=","") }
        if ($line -like '*Demo=*') { $DemoAccount=($line).Replace("Demo=","") }
        if ($line -like '*QA=*') { $QAAccount=($line).Replace("QA=","") }
        if ($line -like '*Upgrade=*') { $Upgrade=($line).Replace("Upgrade=","") }
        if ($line -like '*Beta=*') { $BetaAccount=($line).Replace("Beta=","") }
        if ($line -like '*UseDeclarationTool=*') { $UseDeclarationTool=($line).Replace("UseDeclarationTool=","") }
        if ($line -like '*LanguageCode=*') { $LanguageCode=($line).Replace("LanguageCode=","") }
        if ($line -like '*Culture=*') { $CultureKiosk=($line).Replace("Culture=","") }
        if ($line -like '*CultureNumber=*') { $CultureFormatNumber=($line).Replace("CultureNumber=","") }
        if ($line -like '*CultureDate=*') { $CultureFormatDate=($line).Replace("CultureDate=","") }
        if ($line -like '*IsMigros=*') { $IsMigros=($line).Replace("IsMigros=","") }
        if ($line -like '*CurrencyCm=*') { $CurrencyCm=($line).Replace("CurrencyCm=","") }
        if ($line -like '*LanguageCm=*') { $LanguageCm=($line).Replace("LanguageCm=","") }
        if ($line -like '*LanguageCmDefault=*') { $LanguageCmDefault=($line).Replace("LanguageCmDefault=","") }
        if ($line -like '*LanguagDb=*') { $LanguagDb=($line).Replace("LanguagDb=","") }
        if ($line -like '*LanguageDbMain=*') { $LanguageDbMain=($line).Replace("LanguageDbMain=","") }
        if ($line -like '*DataEmptyMerchRecipe=*') { $DataEmptyMerchRecipe=($line).Replace("DataEmptyMerchRecipe=","") }
        if ($line -like '*IsMasterEgs=*') { $IsMasterEgs=($line).Replace("IsMasterEgs=","") }
        if ($line -like '*SupplierPistor=*') { $SupplierPistor=($line).Replace("SupplierPistor=","") }
        if ($line -like '*SupplierScana=*') { $SupplierScana=($line).Replace("SupplierScana=","") }
        if ($line -like '*SupplierTransgourmet=*') { $SupplierTransgourmet=($line).Replace("SupplierTransgourmet=","") }
    }
    #
    $CultureFormatDateNum=($CultureFormatDate).replace("dd","01")
    $CultureFormatDateNum=($CultureFormatDateNum).replace("mm","01")
    $CultureFormatDateNum=($CultureFormatDateNum).replace("yyyy","1900")
    #
    Write-Host $ClientName
    Write-Host $Enum
    Write-Host $TotalUserPerSite
    Write-Host $TotalProperty
    Write-Host $TotalSites
    Write-Host $TotalKioskUserPerSite
    Write-Host $Edition
    #Write-Host $VersionCm
    Write-Host $Auditing
    Write-Host $PrepAutoSpacing
    Write-Host $DateValidity
    Write-Host $CultureKiosk
    Write-Host $CultureFormatNumber
    Write-Host $CultureFormatDate
    Write-Host $CultureFormatDateNum
    Write-Host $URL
    #Write-Host $URLtest
    Write-Host $HTTPS
    Write-Host $ServerApp
    Write-Host $ServerSql
    Write-Host $DatabaseReference
    Write-Host $PasswordDb
    Write-Host $DemoAccount
    Write-Host $QAAccount
    Write-Host $BetaAccount
    Write-Host $UseDeclarationTool
    Write-Host $LanguageCode
    #
    #
    #If (($DoApp -eq "1") -and ($VersionCm -ne $DOVersionMain))
    #{
    #    write-host "Thw wrong version is being deployed" -ForegroundColor Red
    #    break
    #}
    #
    #
    if ($ProjectNameToDeploy.ToLower() -eq $ClientName.ToLower())
    {
        write-host "The file with deployment information has been read and is correct" -ForegroundColor Green
    }
    else
    {
        #"The file with deployment information has been read, but it's not a valid file."
        write-host "SCRIPT INTERRUPTED - INVALID DEPLOYMENT FILE" -ForegroundColor Red
        Break
    }
    #
    If ((($DoApp -eq "1") -or ($DoUpdate -eq "1") -or ($UpdateFolderKiosk -eq "1") -or ($DoCopyWeb -eq "1") -or ($DoRestoreWeb -eq "1") -or ($DoHttpToHttps -eq "1")) -and ($servercurrent.ToLower() -ne $ServerApp.ToLower()) -and ($servercurrent -ne "Test")) 
    { 
        write-host "SCRIPT INTERRUPTED - WRONG APP SERVER" -ForegroundColor Red
        Break
    }
    #
    If (($servercurrent -eq "Test") -or ($servercurrent -eq "Local") -or ($servercurrent -eq "Local"))
    {
    }
    Else
    {
        If (($DoSql2 -eq "1") -and ($servercurrent.ToLower() -ne $ServerSql.ToLower())) 
        { 
            write-host "SCRIPT INTERRUPTED - WRONG SQL SERVER" -ForegroundColor Red
            Break
        }
    }
    #
    If (($HTTPS -eq "0") -and ($DOVersion -ne "v1") -and ($DOVersion -ne "v2"))
    {
        write-host "SCRIPT INTERRUPTED - MUST BE HTTPS WITH THIS Version" -ForegroundColor Red
        Break
    }
    ###
    ### 
    ###
    $UrlName=$URL    
    $UrlNameServer=$URL #No more server name in URL #+"."+$ServerToDeployToApp.ToLower()    
    "Url: $UrlName"
    "Url for this server: $UrlNameServer"
    #
    #If it is on "Test" server then we change the Servers from config file to "Test"
    $ComputerNameOfCurrentServer=$env:computername
    If (($ComputerNameOfCurrentServer -eq "WEB-J7AKNRFFF8G") -or ($ComputerNameOfCurrentServer -eq "SQL-J7AKNRFFF8G")) 
    { 
        #We are on a Test server!
        
    }
    #
}
#
$ServerToDeployToApp=$ServerApp #"Local" #Local or Test or Argus 
$ServerToDeployToSql=$ServerSql #"Local" #Local or Test or Attus or Myris or TFS
#
Write-host "CURRENT SERVER: $servercurrent" 
Write-host "APPLICATION SERVER: $ServerToDeployToApp" 
Write-host "SQL SERVER: $ServerToDeployToSql" 
#
#break
#"-----> $ServerToDeployToApp"
#break
#
#Check Server
#
$PathForDBScriptsForced="" #Set it below, depending on server
#
$PathPS="C:\Powershell\"        #Location of the Powershell scripts 
$PathWinRar="C:\Program Files\WinRAR\rar.exe"      #Location and filename of the Winrar application
$PathWinUnRar="C:\Program Files\WinRAR\unrar.exe"
#
#PARAMETERS ABOUT THE SERVERS 
if ($ServerToDeployToApp -eq "Pontus") #-and ($DoIIS -eq "1"))
{
    $ComputerNameServerAppInternal="10.0.0.2" #floating IP: 78.47.45.29
    $ComputerNameServerAppInternalHttps="10.0.0.2" 
    $ComputerNameServerAppExternal="78.47.45.29" 
    $ComputerNameServerAppExternalHttps="78.47.45.29" 
    $ProfileNameAWS="egs.s31"
    $PathcmwebRoot="C:\EgsExchange" #Folder where file exchanged with servers is located
    $Pathcmweb="E:" #\Website\"     #Location of Websites, etc. WHere the \Website is located
    $PathcmwebNoSemicolon=$Pathcmweb.Substring(0,1)
    $PathDBs ="E:\Database"         #Location of where the Databases files are installed
    $PathBackupApp="E:\Backup\"        #Location of the backup files (temporary)
    $CertificateThumbprint="496dcbe323eda7d7ee2738acbd6579944ac3e902" #"009b23c709775a01770a1c519e80703789758228"
}
elseif ($ServerToDeployToApp -eq "Pallas") #-and ($DoIIS -eq "1"))
{
    $ComputerNameServerAppInternal="10.1.0.2" #floating IP: 78.47.45.29
    $ComputerNameServerAppInternalHttps="10.1.0.2" 
    $ComputerNameServerAppExternal="5.161.23.90" 
    $ComputerNameServerAppExternalHttps="5.161.23.90" 
    $ProfileNameAWS="egs.s31"
    $PathcmwebRoot="C:\EgsExchange" #Folder where file exchanged with servers is located
    $Pathcmweb="E:" #\Website\"     #Location of Websites, etc. WHere the \Website is located
    $PathcmwebNoSemicolon=$Pathcmweb.Substring(0,1)
    $PathDBs ="E:\Database"         #Location of where the Databases files are installed
    $PathBackupApp="E:\Backup\"        #Location of the backup files (temporary)
    $CertificateThumbprint="496dcbe323eda7d7ee2738acbd6579944ac3e902" #"009b23c709775a01770a1c519e80703789758228"
}
else
{
    write-host "SCRIPT INTERRUPTED" -ForegroundColor Red
    Break
}
#
if ($ServerToDeployToSql -eq "Talos")
{
    $ComputerNameServerSql="TALOS"  # 116.202.185.46
    $DataSourceIP="10.1.0.3" #$ComputerNameServerSql floating IP: 116.202.185.46
    $ProfileNameAWS="egs.s31"
    $PathcmwebRoot="C:\EgsExchange" #Folder where file exchanged with servers is located
    #$Pathcmweb="C:" #\Website\"     #Location of Websites, etc. WHere the \Website is located
    #$PathcmwebNoSemicolon=$Pathcmweb.Substring(0,1)
    $PathDBs ="E:\Database"         #Location of where the Databases files are installed
    $PathBackupSql="E:\Backup\"        #Location of the backup files (temporary)
}
elseif ($ServerToDeployToSql -eq "Typhon")
{
    $ComputerNameServerSql="TYPHON"  # 116.202.185.46
    $DataSourceIP="10.0.0.3" #$ComputerNameServerSql floating IP: 116.202.185.46
    $ProfileNameAWS="egs.s31"
    $PathcmwebRoot="C:\EgsExchange" #Folder where file exchanged with servers is located
    #$Pathcmweb="C:" #\Website\"     #Location of Websites, etc. WHere the \Website is located
    #$PathcmwebNoSemicolon=$Pathcmweb.Substring(0,1)
    $PathDBs ="E:\Database"         #Location of where the Databases files are installed
    $PathBackupSql="E:\Backup\"        #Location of the backup files (temporary)
}
else
{
    "SCRIPT INTERRUPTED"
    Break
}
#
#SNAPIN
#
#To Test: Invoke-Sqlcmd -Query "SELECT GETDATE() AS TimeOfQuery;" -ServerInstance $ComputerNameServerSql
#
If (($DOSql2 -eq "1") -or ($DOSql3 -eq "1") -or ($UpdateFolderKioskDb -eq "1") -or ($DOPack -eq "1") -or ($DoRemoveDb -eq "1") -or ($DoUpdateClientLogo -eq "1"))
{
#
    function Add-SQLServer2019PowerShell {
        [CmdletBinding()]
        param()

        $ErrorActionPreference = 'Stop'

        # 1) Preferred: Import the SqlServer module (PowerShell Gallery) for SQL 2019+
        if (Get-Module -ListAvailable -Name SqlServer) {
            Write-Host 'Importing SqlServer PowerShell module for SQL Server 2019…'
            Import-Module SqlServer -DisableNameChecking -ErrorAction Stop
        }
        else {
            # 2) Fallback: register & load the legacy SQLPS150 snap-in
            $sqlpsRoot = Join-Path $env:ProgramFiles 'Microsoft SQL Server\150\Tools\PowerShell\Modules\SQLPS'
            if (-not (Test-Path $sqlpsRoot)) {
                Throw 'Neither SqlServer module nor SQLPS150 snap-in was found. Please install the SqlServer module or SQL Server 2019 PowerShell components.'
            }

            # find InstallUtil.exe
            $installUtil = Get-ChildItem "$env:windir\Microsoft.NET\Framework\v4.0.30319\InstallUtil.exe" -ErrorAction SilentlyContinue |
                           Select-Object -First 1 -ExpandProperty FullName
            if (-not $installUtil) {
                Throw 'InstallUtil.exe not found under .NET Framework folders.'
            }

            # register provider & snap-in DLLs
            foreach ($dll in 'Microsoft.SqlServer.Management.PSProvider.dll','Microsoft.SqlServer.Management.PSSnapins.dll') {
                $path = Join-Path $sqlpsRoot $dll
                if (Test-Path $path) {
                    & $installUtil $path
                }
            }

            # add the snap-ins
            Add-PSSnapin SqlServerProviderSnapin100,SqlServerCmdletSnapin100,SqlServerCmdletSnapin150 -ErrorAction Stop
            Write-Host 'Registered SQLPS150 snap-in for SQL Server 2019.'
        }

        # 3) Common settings & loading of type/format data
        Set-Variable -Scope Global -Name SqlServerMaximumChildItems     -Value 0
        Set-Variable -Scope Global -Name SqlServerConnectionTimeout     -Value 30
        Set-Variable -Scope Global -Name SqlServerIncludeSystemObjects  -Value $false
        Set-Variable -Scope Global -Name SqlServerMaximumTabCompletion  -Value 1000

        Update-TypeData   -PrependPath SQLProvider.Types.ps1xml   -ErrorAction SilentlyContinue
        Update-FormatData -PrependPath SQLProvider.Format.ps1xml  -ErrorAction SilentlyContinue

        Write-Host 'SQL Server 2019 PowerShell environment ready.'
    }
    Add-SQLServer2019PowerShell

    # Try to import the SqlServer module first (preferred for 2019+)
    if (-not (Get-Module -ListAvailable -Name SqlServer)) {
        # Fallback: register & load the SQLPS150 snap-ins
        Write-Host 'SqlServer module not found—falling back to SQLPS150 snap-in'

        # (Assumes you’ve already registered the DLLs via InstallUtil as shown previously)
        if (-not (Get-PSSnapin -Name SqlServerCmdletSnapin150 -ErrorAction SilentlyContinue)) {
            Add-PSSnapin SqlServerCmdletSnapin150 -ErrorAction Stop
            Write-Host 'Loaded SqlServerCmdletSnapin150'
        }
        if (-not (Get-PSSnapin -Name SqlServerProviderSnapin150 -ErrorAction SilentlyContinue)) {
            Add-PSSnapin SqlServerProviderSnapin150 -ErrorAction Stop
            Write-Host 'Loaded SqlServerProviderSnapin150'
        }
    }
    else {
        Write-Host 'Importing SqlServer PowerShell module for SQL 2019…'
        Import-Module SqlServer -DisableNameChecking -ErrorAction Stop
    }

    # (Then set your global SQL-provider variables and update type/format data)
    Set-Variable -Scope Global  -Name SqlServerMaximumChildItems    -Value 0
    Set-Variable -Scope Global  -Name SqlServerConnectionTimeout    -Value 30
    Set-Variable -Scope Global  -Name SqlServerIncludeSystemObjects -Value $false
    Set-Variable -Scope Global  -Name SqlServerMaximumTabCompletion -Value 1000

    Update-TypeData   -PrependPath SQLProvider.Types.ps1xml   -ErrorAction SilentlyContinue
    Update-FormatData -PrependPath SQLProvider.Format.ps1xml  -ErrorAction SilentlyContinue

    Write-Host 'SQL Server 2019 PowerShell environment ready.'

}
#
#Other dependant folders
$PathcmwebMaster="$PathcmwebRoot\CalcmenuWeb"
$PathcmwebMaster="$PathcmwebMaster\$DOVersionMain\$DOVersion"
$PathcmwebFromSql="\\$ComputerNameServerAppInternal\Website$PathcmwebNoSemicolon\"
#If (($ServerToDeployToApp -eq "RB") -and ($ServerToDeployToSql -eq "Chronos"))
#{
#    $PathcmwebFromSql="\\$ComputerNameServerAppExternal\Website$PathcmwebNoSemicolon\"
#}
#SQL Server Name
$SqlServerInstance=$ComputerNameServerSql
#
#INITIALISATION VARIABLES
$ErrorCount=0
$ClientName=$ProjectNameToDeploy
#
#SYNCRONIZING CLOUD
#
#Get latest Keys
if ((($DoApp -eq "1") -and ($ServerToDeployToApp -ne "Test")) -or ($UpdateFolderKiosk -eq "1")) {
    Write-host "Retrieving CalcmenuWeb, Keys and Logos folders from Cloud" -ForegroundColor Yellow
    fctDownloadCmWebAndUnZip $ProfileNameAWS $PathcmwebRoot $DOVersion $DOVersionMain
    & $AwsExeFile --profile=$ProfileNameAWS s3 sync 's3://cmweb/Keys' "$PathcmwebRoot\Keys"  --delete --exact-timestamps
    & $AwsExeFile --profile=$ProfileNameAWS s3 sync 's3://cmweb/Logos' "$PathcmwebRoot\Logos"  --delete --exact-timestamps
}
if (($DoUpdate -eq "1")  ) {
    Write-host "Retrieving CalcmenuWeb Update, Keys and Logos folders from Cloud" -ForegroundColor Yellow
    fctDownloadCmWebUpdateAndUnZip $ProfileNameAWS $PathcmwebRoot 
    & $AwsExeFile --profile=$ProfileNameAWS s3 sync 's3://cmweb/Keys' "$PathcmwebRoot\Keys"  --delete --exact-timestamps
    & $AwsExeFile --profile=$ProfileNameAWS s3 sync 's3://cmweb/Logos' "$PathcmwebRoot\Logos"  --delete --exact-timestamps
}
if ($DOSql1 -eq "1") {
    Write-host "Retrieving Databases folders from CLoud" -ForegroundColor Yellow
    & $AwsExeFile --profile=$ProfileNameAWS s3 sync 's3://cmweb/Databases' "$PathcmwebRoot\Databases"  --delete --exact-timestamps
}
if (($DoUpdateClientLogo -eq "1") -or ($DoUpdateCmWebLogo -eq "1")) {
    & $AwsExeFile --profile=$ProfileNameAWS s3 sync 's3://cmweb/Logos' "$PathcmwebRoot\Logos"  --delete --exact-timestamps
}
if (($DoUpdateKey -eq "1") -or ($DoCopyWeb -eq "1")) {
    & $AwsExeFile --profile=$ProfileNameAWS s3 sync 's3://cmweb/Keys' "$PathcmwebRoot\Keys"  --delete --exact-timestamps
}
##
$NewDbName='CalcmenuWeb_'+$ClientName
#
$UsernameForLogin="cmweb_$ClientName"
$UsernameForLogin=$UsernameForLogin.ToLower()
#
###
###
### SETUP APPLICATION
###
###
If ($DoApp -eq "1") 
{
    #
    #CHECKING FIRST
    #
    #
    $TempPath="$PathcmwebRoot\Keys\EgswKey$ClientName.dll"
    if (!(Test-Path $TempPath)) 
    {
        Write-Host "PRODUCT KEY IS MISSING" -foregroundcolor "red"
        Write-Host "SCRIPT INTERRUPTED" -foregroundcolor "red"
        Break
    }
    #
    #
    #BACKUP
    #
    #Backup Website if exists
    $PathcmwebCurrent="$Pathcmweb\Website\"+$ClientName
    Write-Host "Check folder: $PathcmwebCurrent" -ForegroundColor Yellow
    if (Test-Path $PathcmwebCurrent) 
    {
        "Folder exists. Start Backup"
        $Time=Get-Date
        $FileBackup=$PathBackupApp+$ClientName+'\'+$ClientName+'Web_'+$Time.ToString("yyyy-MM-dd")+'.rar'
        $PathToBackup="$Pathcmweb\Website\"+$ClientName
        Try
        {
            set-location $PathToBackup
            $dir = [string](get-location)
            if ($dir -eq $PathToBackup)
            {
                Write-Host "Path being backup: "$PathToBackup 
                Write-Host "Backup placed here: "$FileBackup 
                #################Start-Process -FilePath $PathWinRar -ArgumentList ("a -r " + $FileBackup) -NoNewWindow -Wait
            }
        }
        Catch
        {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            $ErrorCount = $ErrorCount+1
            Write-Host $ErrorMessage
            Write-Host $FailedItem
            "script interupted"
            Break
        }
        Finally
        {
            If ($ErrorCount -gt 0)
            {
                "An Error Occured." #| out-file D:\Data\Dropbox\EgsProjects\Amazon\Powershell\Updatecmweb.log -append
                Write-Host "Error Count:",$ErrorCount
                Exit
            }
            else
            {
                "Backup done successfully"
            }
        }
    }
    else
    {
        "New setup (no backup needed)"
    }
    #
    $ErrorCount=0
    #Copy Files
    Write-Host "Starts Copying files" -ForegroundColor Yellow
    if (Test-Path "$Pathcmweb\Website\") 
    {
        Try
        {
            Copy-Item $PathcmwebMaster "$PathcmwebCurrent\CalcmenuWeb" -recurse -Force
        }
        Catch
        {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            $ErrorCount = $ErrorCount+1
            Write-Host $ErrorMessage
            Write-Host $FailedItem
            Write-host "ERROR COPYING FILES - SCRIPT INTERRUPTED" -ForegroundColor Red
            Break
        }
        Finally
        {
            $Time=Get-Date
            Write-Host "WEBSITE FILES HAVE BEEN COPIED" -foregroundcolor "green"
            #"This script to upload cmweb versions was executed on $Time" | out-file D:\Data\Dropbox\EgsProjects\Amazon\Powershell\Updatecmweb.log -append
            If ($ErrorCount -gt 0)
            {
                "An Error Occured." #| out-file D:\Data\Dropbox\EgsProjects\Amazon\Powershell\Updatecmweb.log -append
                Write-Host "Error Count:",$ErrorCount
            }
            else
            {
                "Update done successfully"
            }
        }
    }
    else
    {
        write-host "SCRIPT INTERRUPTED - Path does not exist: $Pathcmweb\Website\" -ForegroundColor Red
        break
    }
    if (!(Test-Path "$PathcmwebCurrent\CalcmenuWeb\"))
    {
        write-host "SCRIPT INTERRUPTED - Path does not exist: $PathcmwebCurrent\CalcmenuWeb\" -ForegroundColor Red
        break
    }
    #Clear Pictures and Digitalasset folders
    Remove-Item -Path $PathcmwebCurrent\CalcmenuWeb\picnormal\*.* -Force -Recurse #-WhatIf
    Remove-Item -Path $PathcmwebCurrent\CalcmenuWeb\picOriginal\*.* -Force -Recurse #-WhatIf
    Remove-Item -Path $PathcmwebCurrent\CalcmenuWeb\picthumbnail\*.* -Force -Recurse #-WhatIf
    Remove-Item -Path $PathcmwebCurrent\CalcmenuWeb\DigitalAssets\*.* -Force -Recurse #-WhatIf
    Remove-Item -Path $PathcmwebCurrent\CalcmenuWeb\Temp\* -Force -Recurse #-WhatIf
    #
    #sg#Copy-Item -Path $PathcmwebCurrent\CalcmenuWeb\Files\Manual\ -Destination $PathcmwebCurrent\CalcmenuWeb\!Manual\ -Force -Recurse
    Remove-Item -Path $PathcmwebCurrent\CalcmenuWeb\Files\* -Force -Recurse 
    #sg#New-Item $PathcmwebCurrent\CalcmenuWeb\Files\Manual -type directory
    #sg#Move-Item -Path $PathcmwebCurrent\CalcmenuWeb\!Manual\*.* -Destination $PathcmwebCurrent\CalcmenuWeb\Files\Manual\ -Force  
    #sg#Remove-Item -Path $PathcmwebCurrent\CalcmenuWeb\!Manual -Force  
    #
    #Clear other files
    Remove-Item -Path $PathcmwebCurrent\CalcmenuWeb\*.bak -Force -Recurse #-WhatIf
    Remove-Item -Path $PathcmwebCurrent\CalcmenuWeb\*.log -Force -Recurse #-WhatIf  # OK?????????????????????????????????
    if (Test-Path $PathcmwebCurrent\CalcmenuWeb\Thumbs.db) {
        Remove-Item -Path $PathcmwebCurrent\CalcmenuWeb\Thumbs.db -Force -Recurse #-WhatIf  # OK?????????????????????????????????
    }
    Write-Host "CLEAN UP OF PICTURE, FILES, .BAK, .LOG, THUMBS.DB HAS BEEN COMPLETED" -foregroundcolor "green"
    #
    #
    #REMOVE DECLARATION TOOL FOLDER IF NOT NEEDED
    If ($UseDeclarationTool -eq "0")
    {
        $PathDeclaration="$PathcmwebCurrent\CalcmenuWeb\Declaration"
        If (Test-Path $PathDeclaration)
        {
            Remove-Tree $PathDeclaration
            Write-Host "DECLARATION TOOL FOLDER DELETE AS IT IS NOT NEEDED - $PathDeclaration" -foregroundcolor "green"
        }
    }
    #
    #SET THE RIGHT CALCMENU WEB LOGO
    #
    $CMLogoFileName=""
    #[LogoPngName]
    if ($DemoAccount -eq "1") {
        $CMLogoFileName="cmweb-demo.png"
        Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
    }
    elseif (($QAAccount -eq "1") -or ($Upgrade -eq "1")) {
        $CMLogoFileName="cmweb-qa.png"
        Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
    }
    elseif ($BetaAccount -eq "1") {
        $CMLogoFileName="cmweb-beta.png"
        Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
    }
    else
    {
        $EditionLower=$Edition.ToLower()
        if ($EditionLower -eq "") {
            $CMLogoFileName="cmweb.png"
            #Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
        }
        else
        {
            $CMLogoFileName="cmweb-$EditionLower.png"
            #Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
        }
    }
    if ($CMLogoFileName -ne "") #-and (Test-Path ))
    {
        #RENAME AND REPLACE LOGO OF CALCMENU WEB
        #Delete logo
        #2014
        $PathLogo2014="$PathcmwebCurrent\CalcmenuWeb\Images\Logo\CM-Web-150x70.png"
        If (Test-Path $PathLogo2014) { Remove-Item -Path $PathLogo2014 -Force -Recurse }
        #2015
        $PathLogo2015="$PathcmwebCurrent\CalcmenuWeb\Images\Logo\cmweb_header-left.png"
        If (Test-Path $PathLogo2015) { Remove-Item -Path $PathLogo2015 -Force -Recurse }

        #Copy right logo to that name
        $CopyLogoOK="0"
        #2014
        Copy-Item "$PathcmwebCurrent\CalcmenuWeb\Images\Logo\$CMLogoFileName" $PathLogo2014 -recurse -Force
        If (Test-Path $PathLogo2014)
        {
            Write-Host "LOGO (2014) HAS BEEN CHANGED TO: $PathcmwebCurrent\CalcmenuWeb\Images\Logo\$CMLogoFileName" -foregroundcolor "green"
            $CopyLogoOK="1"
        }
        #2015
        Copy-Item "$PathcmwebCurrent\CalcmenuWeb\Images\Logo\$CMLogoFileName" $PathLogo2015 -recurse -Force
        If (Test-Path $PathLogo2015)
        {
            Write-Host "LOGO (2015) HAS BEEN CHANGED TO: $PathcmwebCurrent\CalcmenuWeb\Images\Logo\$CMLogoFileName" -foregroundcolor "green"
            $CopyLogoOK="1"
        }
        If ($CopyLogoOK -eq "0")
        {
            Write-Host "PROBLEM WITH CHANGE OF LOGO: $PathcmwebCurrent\CalcmenuWeb\Images\Logo\$CMLogoFileName" -foregroundcolor "red"
        }
        #From 7.0.47
        #Go to the folder where web.config is located
        $WebConfigFolder=$PathcmwebCurrent+"\CalcmenuWeb"
        write-host "Current Folder:"$WebConfigFolder
        set-location $WebConfigFolder
        $dir = [string](get-location)
        #Make sure we are really where we are supposed to be
        if ($dir -eq $WebConfigFolder)
        {
            (Get-Content web.config) | 
            Foreach-Object {$_ -replace "\[ApplicationLogoFileName\]",$CMLogoFileName}  | 
            Out-File -Encoding utf8 web.config
        }
        pop-location
        #
    }
    #
    #COPY THE CLIENT'S LOGO (MULTIPLE?)
    #    *TODO
    #UPDATE EgswConfig SET String = 'logo/[SiteLogoName.jpg]' WHERE Numero = 20026 AND CodeGroup = -3
    #UPDATE EgswConfig SET String = '' WHERE Numero = 20026 AND CodeGroup = -3
    #UPDATE EgswConfig SET String = 'logo/default.jpg' WHERE Numero = 20026 AND CodeGroup = -3
    #
    #Get Web.config Info
    #
    #nextz
    #
    #
    fctSetParametersInConfigsNew $PathcmwebCurrent $DataSourceIP $ClientName $UsernameForLogin $PasswordDb $UrlNameServer $IsMigros $DOVersion $DOVersionMain $CultureKiosk $HTTPS $UseDeclarationTool $LanguageCode $CultureFormatDate $CultureFormatDateNum $CultureFormatNumber $CMLogoFileName
    #
    #
    #SET FOLDER PERMISSIONS
    #
    $FolderPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb'
    $acl = Get-Acl $FolderPath 
    $colRights = [System.Security.AccessControl.FileSystemRights]"Read,Modify,ExecuteFile,ListDirectory" 
    $permission = "IIS_IUSRS",$colRights,"ContainerInherit,ObjectInherit”,”None”,”Allow” 
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission  
    $acl.AddAccessRule($accessRule) 
    Set-Acl $FolderPath $Acl
    Write-Host "FOLDER PERMISSION HAS BEEN SET" -foregroundcolor "green"
    #
    #CONFIGURE IIS
    #
    if ($HTTPS -eq "1") 
    {
        "##########################"
        $ComputerNameServerAppInternalHttps 
        $Pathcmweb 
        $ClientName 
        $UrlNameServer
        "##########################"
        push-location
        BindWebsite  $ComputerNameServerAppInternalHttps $Pathcmweb $ClientName $UrlNameServer
        WebConfigRewrite $Pathcmweb $ClientName
        $iisAppName = "CalcmenuWeb_$ClientName"
        pop-location
    }
    else
    {
        push-location
        Import-Module WebAdministration
        #$iisAppPoolName = $UrlName+".calcmenuweb.com"
        $iisAppPoolName = "CalcmenuWeb_$ClientName"
        $iisAppPoolDotNetVersion = "v4.0"
        #$iisAppName = $UrlName+".calcmenuweb.com"
        $iisAppName = "CalcmenuWeb_$ClientName"
        $iisAppNameBinding = $UrlNameServer+".calcmenuweb.com"
        $directoryPath = "$Pathcmweb\Website\$ClientName\CalcmenuWeb"
        #navigate to the app pools root
        cd IIS:\AppPools\
        #check if the app pool exists
        if (!(Test-Path $iisAppPoolName -pathType container))
        {
            #create the app pool
            $appPool = New-Item $iisAppPoolName
            $appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $iisAppPoolDotNetVersion
        }
        #navigate to the sites root
        cd IIS:\Sites\
        #check if the site exists
        if (Test-Path $iisAppName -pathType container)
        {
            #do nothing
        }
        else
        {
            #If site is Pontus
            $AllUnassigned = ""
            write-host "ServerApp: $ServerAppToDeployToApp" -foregroundcolor "yellow"
            #if ($ServerAppToDeployToApp -eq "Pontus") 
            #{
                $AllUnassigned = "*"
                write-host "All Unassigned is set to *" -foregroundcolor "yellow"
            #}
            #create the site 
            $iisApp = New-Item $iisAppName -bindings @{protocol="http";bindingInformation="$($AllUnassigned):80:" + $iisAppNameBinding} -physicalPath $directoryPath
            $iisApp | Set-ItemProperty -Name "applicationPool" -Value $iisAppPoolName
            Write-Host "WEBSITE AND APPLICATION POOL HAS BEEN SETUP" -foregroundcolor "green"
            #if ($HTTPS -eq "1") 
            #{
            #    $iisApp = New-Item $iisAppName -bindings @{protocol="https";bindingInformation=$ComputerNameServerAppInternalHttps+":443:" + $iisAppNameBinding} -physicalPath $directoryPath #-Force
            #}
        }
    }
    pop-location
    #
    <#
    #Convert folder to application
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\calcmenuapi"
    #Retired 27.01.2017 ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\Declaration"
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\Kiosk"
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\ws"
    #new 30.19
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\ReportXML"
    #new 30.19
    Write-Host "APPLICATION FOLDERS HAVE BEEN CONVERTED" -foregroundcolor "green"
    #>
    #
    #SETUP LICENSE KEY
    #
    $PathClientLicenseKey="$PathcmwebRoot\Keys\EgswKey$ClientName.dll"
    if (Test-Path $PathClientLicenseKey) 
    {
        $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\bin\EgswKey.dll'
        Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
        Write-Host "Copy EgswKey.dll to $LicenseKeyPath" -foregroundcolor "yellow"
        #
        $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\kiosk\bin\EgswKey.dll'
        Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
        Write-Host "Copy EgswKey.dll to $LicenseKeyPath" -foregroundcolor "yellow"
        #
        $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\MenuPlanView\bin\EgswKey.dll'
        Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
        Write-Host "Copy EgswKey.dll to $LicenseKeyPath" -foregroundcolor "yellow"
        #
        $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\RecipeExport\bin\EgswKey.dll'
        Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
        Write-Host "Copy EgswKey.dll to $LicenseKeyPath" -foregroundcolor "yellow"
        #
        $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\DataExport\bin\EgswKey.dll'
        Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
        Write-Host "Copy EgswKey.dll to $LicenseKeyPath" -foregroundcolor "yellow"
        #
        $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\DataAnalytics\bin\EgswKey.dll'
        Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
        Write-Host "Copy EgswKey.dll to $LicenseKeyPath" -foregroundcolor "yellow"
        #
        $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\RecipeImport\bin\EgswKey.dll'
        Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
        Write-Host "Copy EgswKey.dll to $LicenseKeyPath" -foregroundcolor "yellow"
        #
        $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\inventory\bin\EgswKey.dll'
        Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
        Write-Host "Copy EgswKey.dll to $LicenseKeyPath" -foregroundcolor "yellow"
        #
        Write-Host "PRODUCT KEYS HAS BEEN SETUP" -foregroundcolor "green"
    }
    else
    {
        Write-Host "LICENSE KEY IS MISSING!!!" -foregroundcolor "red"
        Write-Host "SCRIPT INTERRUPTED" -foregroundcolor "red"
        Break
    }
    #
    #BACKUP WEBSITE AND SETUP PICTURES/FILES BACKUP
    #
    #
    #CONFIGURE THE DOMAIN NAME #SG
    if ($HTTPS -eq "1") 
    {
        $IpForDomainName=$ComputerNameServerAppExternalHttps
        $httpType="https:"
    }
    else
    {
        $IpForDomainName=$ComputerNameServerAppExternal
        $httpType="http:"
    }
    if ($Silent -eq "0")
    {
        $choice = ""
        while ($choice -notmatch "[y|n]")
        {
            $choice = read-host "Do you wish to setup the domain name $httpType//$UrlName.calcmenuweb.com with IP address: $IpForDomainName ? (Y/N)"
        }
        if ($choice -eq "y")
        {
            New-R53ResourceRecordSet -ProfileName "egs.sandro" -Value $IpForDomainName -Type "A" -RecordName $UrlName -TTL 3600 -ZoneName "calcmenuweb.com"   
            Write-host "Domain Name $UrlName.calcmenuweb.com has been setup on $IpForDomainName" -foregroundcolor Green
        }
    }
    else
    {
        if ($AutoCreateDomain -eq "1")
        {
            New-R53ResourceRecordSet -ProfileName "egs.sandro" -Value $IpForDomainName -Type "A" -RecordName $UrlName -TTL 3600 -ZoneName "calcmenuweb.com"   
            Write-host "Domain Name $UrlName.calcmenuweb.com has been setup on $IpForDomainName" -foregroundcolor Green
        }
    }
    #
    #
    #
    Write-host "########### EGS TOOL - WEB DEPLOYMENT COMPLETED ###########" -foregroundcolor Yellow
    Write-host "### Look for errors and report them to SG. " -foregroundcolor Yellow
    Write-host "### Thank you." -foregroundcolor Yellow
}
###
###
### SETUP DATABASE
###
###
If ($DoSql2 -eq "1") 
{

    #
    #RESTORE DATABASE 
    #
    "Restoring Database..."
    $databaseToMap = "CalcmenuWeb_$ClientName"
    #
    #Remove any .bak in the database folder
    Remove-Item -Path "$PathcmwebRoot\Databases\*.bak" -Force 
    #
    #For testing
    #$DatabaseReference="9002"
    #
    #Find Filename that match the DatabaseReference
    $DatabaseBackupName=""
    If($DatabaseReference.length -eq 4) 
    {
            #$DatabaseReference="1002"
            Get-ChildItem -path "$PathcmwebRoot\Databases\" | ForEach-Object {
                #$_.Name
                #$_.Name.substring(0,4)
                $DatabaseBackupNameRar=$_.Name  #This is the .rar
                #
                $tmpToExclude =$DatabaseBackupNameRar -match '\b\.part[0-9]+[2-9]+\.rar\b'    #look for .part02.rar, .part03.rar, etc.
                if ($tmpToExclude) 
                {
                    if ($_.Name.substring(0,4) -eq $DatabaseReference) 
                    {
                        "Exclude: $PathcmwebRoot\Databases\$DatabaseBackupNameRar"
                    }
                }
                else
                {
                    if ($_.Name.substring(0,4) -eq $DatabaseReference) 
                    {
                        #Get .Bak Name
                        $extBak = [System.IO.Path]::GetExtension($DatabaseBackupNameRar);
                        $DatabaseBackupName=$DatabaseBackupNameRar.replace($extBak,'')
                        $DatabaseBackupName=$DatabaseBackupName+".bak"
                        #
                        If  ($ServerToDeployToSql -eq "Tfs")
                        {
                            #Move the file before unzipping
                            $backupPathLocal=$PathBackupSql+$ClientName
                            $backupPathFileLocal=$PathBackupSql+$ClientName+"\"+$DatabaseBackupNameRar
                            Remove-Item -Path "$backupPathLocal\$DatabaseBackupName" -Force 
                            write-host $backupPathLocal -ForegroundColor Yellow
                            Copy-Item "$PathcmwebRoot\Databases\$DatabaseBackupNameRar" $backupPathFileLocal -recurse -Force
                            Write-Host "Copy Backup Locally to $backupPathFileLocal" -ForegroundColor Yellow
                            #Unzip
                            & $PathWinUnRar e -idc $backupPathFileLocal "$backupPathLocal\"
                            #Get the database name of the backup file
                            $backupPath="$backupPathLocal\$DatabaseBackupName" 
                            $backupPath
                            
                        }
                        else
                        {
                            #Unzip
                            & $PathWinUnRar e -idc "$PathcmwebRoot\Databases\$DatabaseBackupNameRar" "$PathcmwebRoot\Databases\"
                            #Get the database name of the backup file
                            $backupPath= "$PathcmwebRoot\Databases\$DatabaseBackupName" 
                        }
                    }
                }

            }
            #   
            #
            #
            if ($DatabaseBackupName -ne "") 
            {
                #

                #Load the required assemlies SMO and SmoExtended.
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
                # Connect SQL Server.
                $sqlServer = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $SqlServerInstance
                # Create SMo Restore object instance
                $dbRestore = new-object ("Microsoft.SqlServer.Management.Smo.Restore")
                # Set database and backup file path
                #$dbRestore.Database = $dbname
                $dbRestore.Devices.AddDevice($backupPath, "File")
                # Get the file list from backup file
                $dbFileList = $dbRestore.ReadFileList($sqlServer)
                $PhysicalNameWithPath=$dbFileList.Select("Type = 'D'")[0].PhysicalName
                $PhysicalNameOnly = [System.IO.Path]::GetFileName($PhysicalNameWithPath);
                $ext = [System.IO.Path]::GetExtension($PhysicalNameWithPath);
                $PhysicalNameOnly=$PhysicalNameOnly.replace($ext,'')
                $PhysicalNameOnly             
                #
                #New!
                $headerSqlDb = $dbRestore.ReadBackupHeader($sqlServer)
                if($headerSqlDb.Rows.Count -eq 1)
                {
                  $PhysicalNameOnly=$headerSqlDb.Rows[0]["DatabaseName"]
                }
                $PhysicalNameOnly
            
                $PowershellRestoreDB= $PathPS+'Restore-SqlDb.ps1'
                Write-host $PowershellRestoreDB
                $PathToRestore=$backupPath #$PathcmwebRoot+'\Databases\'+$DatabaseBackupName
                write-host $PathToRestore
                & $PowershellRestoreDB -dbName $PhysicalNameOnly -from $SqlServerInstance -paths $PathToRestore -moveLogsTo $PathDBs -moveDataTo $PathDBs -newDbName $NewDbName -recover -execute
                #
                Write-Host "DATABASE HAS BEEN RESTORED" -foregroundcolor "green"
                #
                #33.03.00
                Invoke-SQLcmd -ServerInstance $SqlServerInstance -query "ALTER DATABASE $NewDbName SET RECOVERY SIMPLE"  -Database $NewDbName -Encrypt Mandatory -TrustServerCertificate
                Write-Host "DATABASE RECOVERY MODEL CHANGED TO SIMPLE" -foregroundcolor "green"
                #
                #
                #CREATE LOGIN
                #
                "Creating login..."
                $roleName = "db_owner"
 
                $server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $SqlServerInstance

                # drop login if it exists
                if ($server.Logins.Contains($UsernameForLogin))  
                {   
                    Write-Host("Deleting the existing login $UsernameForLogin.")
                       $server.Logins[$UsernameForLogin].Drop() 
                }

                $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList $server, $UsernameForLogin
                $login.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::SqlLogin
                $login.PasswordExpirationEnabled = $false
                $login.PasswordPolicyEnforced = $false
                $login.DefaultDatabase=$databaseToMap
                $login.Create($PasswordDb)

                $database = $server.Databases[$databaseToMap]
                if ($database.Users[$UsernameForLogin])
                {
                    #Dropping user $UsernameForLogin on $database.
                    $database.Users[$UsernameForLogin].Drop()
                }

                $dbUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.User -ArgumentList $database, $UsernameForLogin
                $dbUser.Login = $UsernameForLogin
                $dbUser.Create()

                #assign database role for a new user
                $dbrole = $database.Roles[$roleName]
                $dbrole.AddMember($UsernameForLogin)
                $dbrole.Alter()
                Write-Host("USER LOGIN $dbUser HAS BEEN ADDED TO $roleName ROLE") -foregroundcolor "green"

                #
                #
                #
            }
            else
            {
                "Invalid Filename/database reference or Filename not found"
                Write-Host "SCRIPT INTERRUPTED" -foregroundcolor "red"
                Break
            }
 
        }
        else
        {
            "Invalid Database Reference. The Reference Code has no match in the Databases folder."
             Write-Host "SCRIPT INTERRUPTED" -foregroundcolor "red"
            Break
        }
        write-host 'Database Name:'$DatabaseBackupName
}
#
If ($UpdateFolderKioskDb -eq "1") 
{
    #
    #
    #
    #CONVERSION OF THE DATABASE FOR UPDATE OF KIOSK ONLY
    #
    #
    "Converting database $NewDbName (Login: $UsernameForLogin)..."
    #
    #
    #Wait for the folder with the dbscript to be reachable (in case app has not yet been deployed)
    #Path for EgsData.dll
    $WebsiteDrive="C"
    #$PathForEgsDataDll="\\$ComputerNameServerAppInternal\Website$PathcmwebNoSemicolon\$ClientName\CalcmenuWeb\bin\EgsData.dll"
    $PathForEgsDataDll="\\$ComputerNameServerAppInternal\WebsiteC\$ClientName\CalcmenuWeb\bin\EgsData.dll"
    If (!(Test-Path $PathForEgsDataDll))
    {
        $WebsiteDrive="D"
        $PathForEgsDataDll="\\$ComputerNameServerAppInternal\WebsiteD\$ClientName\CalcmenuWeb\bin\EgsData.dll"
        If (!(Test-Path $PathForEgsDataDll))
        {
            $WebsiteDrive="E"
            $PathForEgsDataDll="\\$ComputerNameServerAppInternal\WebsiteE\$ClientName\CalcmenuWeb\bin\EgsData.dll"
            If (!(Test-Path $PathForEgsDataDll))
            {
                Write-Host "The file EgsData.dll is inacessible on C, D, E using this path:" -ForegroundColor Red
                Write-Host $PathForEgsDataDll -ForegroundColor Red
                Break
            }
        }
    }
    <#
    If (($ServerToDeployToApp -eq "RB") -and ($ServerToDeployToSql -eq "Chronos"))
    {
        $WebsiteDrive="C"
        #$PathForEgsDataDll="\\$ComputerNameServerAppExternal\Website$PathcmwebNoSemicolon\$ClientName\CalcmenuWeb\bin\EgsData.dll"
        $PathForEgsDataDll="\\$ComputerNameServerAppExternal\WebsiteC\$ClientName\CalcmenuWeb\bin\EgsData.dll"
        If (!(Test-Path $PathForEgsDataDll))
        {
            $WebsiteDrive="D"
            $PathForEgsDataDll="\\$ComputerNameServerAppExternal\WebsiteD\$ClientName\CalcmenuWeb\bin\EgsData.dll"
            If (!(Test-Path $PathForEgsDataDll))
            {
                $WebsiteDrive="E"
                $PathForEgsDataDll="\\$ComputerNameServerAppExternal\WebsiteE\$ClientName\CalcmenuWeb\bin\EgsData.dll"
                If (!(Test-Path $PathForEgsDataDll))
                {
                    Write-Host "The file EgsData.dll is inacessible on C, D, E using this path:" -ForegroundColor Red
                    Write-Host $PathForEgsDataDll -ForegroundColor Red
                    Break
                }
            }
        }

    }
    #>
    While (!(Test-Path $PathForEgsDataDll))
    {
        Start-Sleep -s 5
        Write-host "Waiting for folder $PathForEgsDataDll to exist"
    }
    Write-host "Folder $PathForEgsDataDll exists" -ForegroundColor Yellow
    #
    #Path for DbScript
    If ($PathForDBScriptsForced.Length -eq 0)
    {
        $PathForDBScripts="\\$ComputerNameServerAppInternal\Website$WebsiteDrive\$ClientName\CalcmenuWeb\kiosk\DBScripts\"
        #If (($ServerToDeployToApp -eq "RB") -and ($ServerToDeployToSql -eq "Chronos"))
        #{
        #    $PathForDBScripts="\\$ComputerNameServerAppExternal\Website$WebsiteDrive\$ClientName\CalcmenuWeb\kiosk\DBScripts\"
        #}
    }
    else
    {
        $PathForDBScripts=$PathForDBScriptsForced
    }
    #
    $ScriptForKioskUpdate='43767.sql'
    $PathForDBScripts=$PathForDBScripts+$ScriptForKioskUpdate
    #
    If (!(Test-Path $PathForDBScripts -PathType Leaf))
    {
        Write-host "Script $PathForDBScripts does not exist"
        Break
    }
    Write-host "Script $PathForDBScripts exists" -ForegroundColor Yellow
    #
    #
    #Get the start version from the version of the database
    $ConversionVersionFrom=0
    $connectionString = “Server=$SqlServerInstance;uid=$UsernameForLogin; pwd=$PasswordDb;Database=$NewDbName;Integrated Security=False;”
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $query = “SELECT Version FROM EgswSystem”
    $Command.CommandText = $query
    $result = $Command.ExecuteReader()
    while ($result.Read()) {
        $ConversionVersionFrom=$result.GetValue($1)
    }
    $connection.Close()
    if ($ConversionVersionFrom -eq 0)
    {
        "Cannot Find the Current Version of the Database. Impossible to Convert."
    }
    Else
    {
        #
        #BREAK  # !!!!!!!!!!!!!!!!!! FOR NOW !!!!!!!!!!!!!!
        #
        push-location
        "Scripts $PathForDBScripts"
        #Create temp folder
        $PathForDBScriptsTemp=$PathBackupSql+"temp"
        If (!(Test-Path -Path $PathForDBScriptsTemp))
        {
            New-Item -Path $PathForDBScriptsTemp -type directory -Force
        }
        #
        $OutF="$PathForDBScriptsTemp\$ScriptForKioskUpdate"
        (Get-Content $PathForDBScripts)  | Out-File -Encoding utf8 "$PathForDBScriptsTemp\$ScriptForKioskUpdate"
        $ErrorCount=0
        Try {
            Invoke-Sqlcmd -InputFile $OutF -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
        }
        Catch {
            $ErrorCount=$ErrorCount+1
        }
        Finally {
            "Error Count: $ErrorCount"
        }
        Write-Host "DATABASE HAS BEEN CONVERTED" -ForegroundColor "green"
        #
        #
        pop-location
        #
        #
    }
}
#
If ($DoSql3 -eq "1") 
{
    #
    #
    #
    #CONVERSION OF THE DATABASE
    #
    #
    "Converting database $NewDbName (Login: $UsernameForLogin)..."
    #
    #
    #Wait for the folder with the dbscript to be reachable (in case app has not yet been deployed)
    #Path for EgsData.dll
    $WebsiteDrive="C"
    #$PathForEgsDataDll="\\$ComputerNameServerAppInternal\Website$PathcmwebNoSemicolon\$ClientName\CalcmenuWeb\bin\EgsData.dll"
    $PathForEgsDataDll="\\$ComputerNameServerAppInternal\WebsiteC\$ClientName\CalcmenuWeb\bin\EgsData.dll"
    If (!(Test-Path $PathForEgsDataDll))
    {
        $WebsiteDrive="D"
        $PathForEgsDataDll="\\$ComputerNameServerAppInternal\WebsiteD\$ClientName\CalcmenuWeb\bin\EgsData.dll"
        If (!(Test-Path $PathForEgsDataDll))
        {
            $WebsiteDrive="E"
            $PathForEgsDataDll="\\$ComputerNameServerAppInternal\WebsiteE\$ClientName\CalcmenuWeb\bin\EgsData.dll"
            If (!(Test-Path $PathForEgsDataDll))
            {
                Write-Host "The file EgsData.dll is inacessible on C, D, E using this path:" -ForegroundColor Red
                Write-Host $PathForEgsDataDll -ForegroundColor Red
                Break
            }
        }
    }
    <#
    If (($ServerToDeployToApp -eq "RB") -and ($ServerToDeployToSql -eq "Chronos"))
    {
        $WebsiteDrive="C"
        #$PathForEgsDataDll="\\$ComputerNameServerAppExternal\Website$PathcmwebNoSemicolon\$ClientName\CalcmenuWeb\bin\EgsData.dll"
        $PathForEgsDataDll="\\$ComputerNameServerAppExternal\WebsiteC\$ClientName\CalcmenuWeb\bin\EgsData.dll"
        If (!(Test-Path $PathForEgsDataDll))
        {
            $WebsiteDrive="D"
            $PathForEgsDataDll="\\$ComputerNameServerAppExternal\WebsiteD\$ClientName\CalcmenuWeb\bin\EgsData.dll"
            If (!(Test-Path $PathForEgsDataDll))
            {
                $WebsiteDrive="E"
                $PathForEgsDataDll="\\$ComputerNameServerAppExternal\WebsiteE\$ClientName\CalcmenuWeb\bin\EgsData.dll"
                If (!(Test-Path $PathForEgsDataDll))
                {
                    Write-Host "The file EgsData.dll is inacessible on C, D, E using this path:" -ForegroundColor Red
                    Write-Host $PathForEgsDataDll -ForegroundColor Red
                    Break
                }
            }
        }
    }
    #>
    While (!(Test-Path $PathForEgsDataDll))
    {
        Start-Sleep -s 5
        Write-host "Waiting for folder $PathForEgsDataDll to exist"
    }
    Write-host "Folder $PathForEgsDataDll exists" -ForegroundColor Yellow
    #
    #Path for DbScript
    If ($PathForDBScriptsForced.Length -eq 0)
    {
        $PathForDBScripts="\\$ComputerNameServerAppInternal\Website$WebsiteDrive\$ClientName\CalcmenuWeb\DBScripts\"
        #If (($ServerToDeployToApp -eq "RB") -and ($ServerToDeployToSql -eq "Chronos"))
        #{
        #    $PathForDBScripts="\\$ComputerNameServerAppExternal\Website$WebsiteDrive\$ClientName\CalcmenuWeb\DBScripts\"
        #}
    }
    else
    {
        $PathForDBScripts=$PathForDBScriptsForced
    }
    While (!(Test-Path $PathForDBScripts))
    {
        Start-Sleep -s 5
        Write-host "Waiting for folder $PathForDBScripts to exist"
    }
    Write-host "Folder $PathForDBScripts exists" -ForegroundColor Yellow
    #
    #
    #Get the start version from the version of the database
    $ConversionVersionFrom=0
    #$dataSource = “81.18.31.180”
    #$UsernameForLogin = “sa”
    #$PasswordDb = “...”
    #$database = “CalcmenuWeb_Bluche”
    #$PasswordDb
    $connectionString = “Server=$SqlServerInstance;uid=$UsernameForLogin; pwd=$PasswordDb;Database=$NewDbName;Integrated Security=False;”
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $Connection
    $query = “SELECT Version FROM EgswSystem”
    $Command.CommandText = $query
    $result = $Command.ExecuteReader()
    while ($result.Read()) {
        $ConversionVersionFrom=$result.GetValue($1)
    }
    $connection.Close()
    if ($ConversionVersionFrom -eq 0)
    {
        "Cannot Find the Current Version of the Database. Impossible to Convert."
    }
    Else
    {
        #
        If ($ConversionVersionFrom -eq 43767) { $ConversionVersionFrom="43767.000"} #33.06.00
        If ($ConversionVersionToForced -gt 0)
        {
            $ConversionVersionTo=$ConversionVersionToForced
            "Conversion forced to version: $ConversionVersionToForced"
        }
        else
        {
            #Get the version to convert to from the Minor Version field in EgsData.dll
            $VersionDataDll=[System.Diagnostics.FileVersionInfo]::GetVersionInfo($PathForEgsDataDll).FileVersion
            $VersionDataDllParts=$VersionDataDll.split(".")
            $VersionDataDllPartsCount=$VersionDataDllParts.Count 
            #$VersionDataDllParts[0] 
            #$VersionDataDllParts[1] 
            $ConversionVersionTo=$VersionDataDllParts[2] 
            #$VersionDataDllParts[3] 
            If ($VersionDataDllParts[3] -ne 0) #33.06.00
            {
                $ConversionVersionTo=$VersionDataDllParts[2]+"."+$VersionDataDllParts[3] 
            }
            #
        }
        #
        #Convert Database from version: $ConversionVersionFrom to version: $ConversionVersionTo
        "Conversion from version $ConversionVersionFrom to version $ConversionVersionTo"
        #
        #
        if ($ConversionVersionTo -eq 0)
        {
            "Cannot Find the Version for the database to convert to (in EgsData.dll). Impossible to convert."
            Write-HOST "SCRIPT INTERUPTED" -ForegroundColor "red"
            Break
        }
        Else
        {
            push-location
            #$ConversionVersionFrom =41761 
            #$ConversionVersionTo=41929
            #$ClientName="Eclipse"
            #$ComputerNameServerAppInternal="WIN-QNU4NG3-APP"
            "Scripts are from $PathForDBScripts"
            #Create temp folder
            $PathForDBScriptsTemp=$PathBackupSql+"temp"
            If (!(Test-Path -Path $PathForDBScriptsTemp))
            {
                New-Item -Path $PathForDBScriptsTemp -type directory -Force
            }
            #
            if ($PSVersionTable.PSVersion.Major -eq "3") 
            {
                #2008
                foreach ($f in Get-ChildItem -path $PathForDBScripts -Filter *.sql | sort-object ) 
                { 
                    $FilenameOnlyDBScripts=[System.IO.Path]::GetFileName($f.fullname)
                    #"File:$FilenameOnlyDBScripts"
                    if (($FilenameOnlyDBScripts -ge "$ConversionVersionFrom.sql") -and ($FilenameOnlyDBScripts -le "$ConversionVersionTo.sql")) 
                    {
                        if (($FilenameOnlyDBScripts.Length -eq 9) -or ($FilenameOnlyDBScripts.Length -eq 13)) #33.06.00
                        {
                            if ($FilenameOnlyDBScripts.Replace("_$ClientName","") -ne $FilenameOnlyDBScripts) #33.15.00
                            { 
                                "Converting with:$FilenameOnlyDBScripts"
                                $OutF="$PathForDBScriptsTemp\$f"
                                (Get-Content $f.fullname)  | Out-File -Encoding utf8 "$PathForDBScriptsTemp\$f"
                                Invoke-Sqlcmd -InputFile $OutF -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                            }
                        }
                        else
                        {
                            $aStart=$FilenameOnlyDBScripts.IndexOf("_")
                            $bStart=$FilenameOnlyDBScripts.IndexOf(".sql")
                            if (($aStart -gt 4) -and ($bStart -gt $aStart))
                            {
                                If ($FilenameOnlyDBScripts.Substring($aStart+1,$bStart-$aStart-1) -eq $ClientName)
                                {
                                    "SPECIAL Converting with:$FilenameOnlyDBScripts"
                                    $OutF="$PathForDBScriptsTemp\$f"
                                    (Get-Content $f.fullname)  | Out-File -Encoding utf8 "$PathForDBScriptsTemp\$f"
                                    $ErrorCount=0
                                    Try {
                                        Invoke-Sqlcmd -InputFile $OutF -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                                    }
                                    Catch {
                                        $ErrorCount=$ErrorCount+1
                                    }
                                    Finally {
                                        "Error Count: $ErrorCount"
                                    }
                                }
                            }
                        }
                    }
                }
            }
            else
            {
                #2012
                $ResultsListOfSql = Search $PathForDBScripts "*.sql"
                foreach ($ft in $ResultsListOfSql | sort-object ) 
                { 
                    #$f
                    [System.IO.DirectoryInfo]$f= $ft
                    $ffull=$f
                    $FilenameOnlyDBScripts=[System.IO.Path]::GetFileName($f.fullname)
                    $f=$FilenameOnlyDBScripts
                    #"File:$FilenameOnlyDBScripts"
                    if (($FilenameOnlyDBScripts -ge "$ConversionVersionFrom.sql") -and ($FilenameOnlyDBScripts -le "$ConversionVersionTo.sql")) 
                    {
                        if (($FilenameOnlyDBScripts.Length -eq 9) -or ($FilenameOnlyDBScripts.Length -eq 13)) #33.06.00
                        {
                            "Converting with:$FilenameOnlyDBScripts"
                            $OutF="$PathForDBScriptsTemp\$f"
                            (Get-Content $ffull)  | Out-File -Encoding utf8 "$PathForDBScriptsTemp\$f"
                            Invoke-Sqlcmd -InputFile $OutF -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                        }
                        else
                        {
                            $aStart=$FilenameOnlyDBScripts.IndexOf("_")
                            $bStart=$FilenameOnlyDBScripts.IndexOf(".sql")
                            if (($aStart -gt 4) -and ($bStart -gt $aStart))
                            {
                                If ($FilenameOnlyDBScripts.Substring($aStart+1,$bStart-$aStart-1) -eq $ClientName)
                                {
                                    "SPECIAL Converting with:$FilenameOnlyDBScripts"
                                    $OutF="$PathForDBScriptsTemp\$f"
                                    (Get-Content $ffull)  | Out-File -Encoding utf8 "$PathForDBScriptsTemp\$f"
                                    $ErrorCount=0
                                    Try {
                                        Invoke-Sqlcmd -InputFile $OutF -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                                    }
                                    Catch {
                                        $ErrorCount=$ErrorCount+1
                                    }
                                    Finally {
                                        "Error Count: $ErrorCount"
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Write-Host "DATABASE HAS BEEN CONVERTED" -ForegroundColor "green"
            #
            $choicelogo = ""
            $choiceedition = ""
            if ($Silent -eq "0")
            {
                while ($choicelogo -notmatch "[y|n]"){
                    $choicelogo = read-host "Should we reset the client's LOGOS to default? (Y/N)"
                    }
                while ($choiceedition -notmatch "[y|n]"){
                    $choiceedition = read-host "Should we reset the client's MODULES to standard? (Y/N)"
                    }
            }
            else
            {
                $choicelogo = "n" #changed 10/31/2020
                $choiceedition = "n" #changed 10/31/2020
            }
            if ($choicelogo -eq "y")
            {
                $MySQLQuery = "UPDATE EgswConfig SET String = 'logo/default.jpg' WHERE Numero = 20026 AND CodeGroup = -3"
                Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                Write-Host "CLIENTS LOGOS HAVE BEEN RESET TO EGS LOGO" -ForegroundColor "green"
                #
            }
            else 
            {
                write-host "The client's LOGOS has NOT been modified!" -ForegroundColor Yellow
            }
            if ($choiceedition -eq "y")
            {
                #Disable/Enable Modules based on Edition or other information
                #
                If ($Edition -eq "Professional")
                {
                    #/*DISABLE MENU MODULE*/
                    $MySQLQuery = "UPDATE EgswRolesRightsTemplate SET Active = 0 WHERE Modules IN (16, 627, 704, 1077)" 
                    Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                    $MySQLQuery = "DELETE EgswRolesRights WHERE Modules IN (16, 627, 704, 1077)" 
                    Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                    Write-Host "MENU MODULE HAS BEEN DISABLED (Edition=$Edition)" -ForegroundColor "green"

                    #/*DISABLE MENUPLAN MODULE*/
                    $MySQLQuery = "UPDATE EgswRolesRightsTemplate SET Active = 0 WHERE Modules IN (24, 2063)" 
                    Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                    $MySQLQuery = "DELETE EgswRolesRights WHERE Modules IN (24, 2063)" 
                    Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                    $MySQLQuery = "DELETE EgswUserRoles WHERE [Role] IN (SELECT Code FROM EgswRoles WHERE Name = 'Menu Plan')"
                    Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                    $MySQLQuery = "DELETE EgswRolesRights WHERE [Role] IN (SELECT Code FROM EgswRoles WHERE Name = 'Menu Plan')"
                    Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                    $MySQLQuery = "DELETE EgswRoles WHERE Name = 'Menu Plan'"
                    Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                    Write-Host "MENU PLAN MODULE HAS BEEN DISABLED (Edition=$Edition)" -ForegroundColor "green"

                    #/*DISABLE LABELS TAB (RECIPE)*/
                    $MySQLQuery = "UPDATE EgswRolesRightsTemplate SET Active = 0 WHERE Modules = 8 AND Rights = 208"
                    Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                    $MySQLQuery = "DELETE EgswRolesRights WHERE Modules = 8 AND Rights = 208"
                    Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                    $MySQLQuery = "UPDATE EgswRolesRightsTemplate SET Active = 1 WHERE Modules IN (2105,2104,2103)"
                    Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                    Write-Host "DECLARATION MODULE HAS BEEN DISABLED (Edition=$Edition)" -ForegroundColor "green"
                }
                If (($Edition -eq "Business") -or ($Edition -eq "Health") -or ($Edition -eq "Airline") -or ($Edition -eq "Chain") -or ($Edition -eq "Brand") -or ($Edition -eq "Academic") -or ($Edition -eq "Care") -or ($Edition -eq "Migros") -or ($Edition -eq "FIC"))
                {
                    #/*ENABLE MENU MODULE*/
                    $MySQLQuery = "UPDATE EgswRolesRightsTemplate SET Active = 1 WHERE Modules IN (16, 627, 704, 1077)" 
                    Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                    Write-Host "MENU MODULE HAS BEEN ENABLED (Edition=$Edition)" -ForegroundColor "green"

                    #/*ENABLE MENUPLAN MODULE*/
                    $MySQLQuery = "UPDATE EgswRolesRightsTemplate SET Active = 1 WHERE Modules IN (24, 2063)" 
                    Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                    Write-Host "MENU MODULE HAS BEEN ENABLED (Edition=$Edition)" -ForegroundColor "green"

                    #/*ENABLE LABELS TAB (RECIPE)*/
                    $MySQLQuery = "UPDATE EgswRolesRightsTemplate SET Active = 1 WHERE Modules = 8 AND Rights = 208"
                    Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                    Write-Host "DECLARATION MODULE HAS BEEN ENABLED (Edition=$Edition)" -ForegroundColor "green"
                }
                #
                #Update Title of application
                $MySQLQuery = "UPDATE EgswConfig SET String = 'Calcmenu Web' WHERE Numero = 20024"
                Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                Write-Host "CLIENTS TITLE HAS BEEN UPDATED TO: 'Calcmenu Web'" -ForegroundColor "green"

            }
            else 
            {
                write-host "The client's MODULES visiblilty has NOT been modified!" -ForegroundColor Yellow
            }
            #
            #Disabled for now
            #Final Script
            #"Final script"
            #$FinalIn=$PathForDBScripts+"final.sql"
            #$FinalOut="$PathForDBScriptsTemp\final.sql"
            #(Get-Content $FinalIn)  | Out-File -Encoding utf8 $FinalOut
            #Invoke-Sqlcmd -InputFile $FinalOut -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
            #Write-Host "FINAL SCRIPT HAS BEEN EXECUTED" -ForegroundColor "green"
            #
            #Clean up temp folder
            If (Test-Path -Path $PathForDBScriptsTemp)
            {
                Remove-Item -Path "$PathForDBScriptsTemp\*.sql" -Force 
                Remove-Item -Path $PathForDBScriptsTemp -Force
            }
            #
            If ($DoSql2 -eq "1") 
            { 
                #It was new deployement
                #UPdate the Admin Password
                $MySQLQuery = "UPDATE EgswUser SET Password='$PasswordAdminEncrypt' WHERE Username='admin'"
                Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
                Write-Host "THE PASSWORD OF THE Admin USER HAS BEEN RESET TO: $PasswordAdmin" -ForegroundColor "green"
            }
            else
            {
                #It was an update of a deployment
                Write-Host "THE PASSWORD OF THE Admin USER HAS NOT BEEN RESET" -ForegroundColor "green"
            }
            #
            #Write-Host "CHANGING PASSWORD OF USER 'admin'" -ForegroundColor "yellow"
            #Write-Host "PASSWORD OF 'admin' IS $PasswordAdmin" -ForegroundColor "cyan"
            #
            pop-location
            #
            $DbNameX="CalcmenuWeb_$ClientName"
            ExecuteScript -ScriptFileName "FIXEGSDECRYPT.sql" -ScriptPath "c:\PowerShell" -NameOfClient $ClientName -SrvInstance $ComputerNameServerSql -ReplaceSource "DATABASE_NAME" -ReplaceBy $DbNameX
            #
            #This return 4000 because of a bug
            #invoke-sqlcmd "select REPLICATE('x', 4001)" -Database master -ServerInstance $ComputerNameServerSql | foreach {($_.Column1).length}
            #This should be used to fix bug
            #invoke-sqlcmd "select REPLICATE('x', 4001)" -Database master -ServerInstance $ComputerNameServerSql -maxcharlength (65000) -Encrypt Mandatory -TrustServerCertificate | foreach {($_.Column1).length}
            #
        }
    }
}
If ($DOSql4 -eq "1") 
{
}
If ($DOSql9 -eq "1") 
{
}
If ($DoApp2 -eq "1") 
{
    ###
    ### BACKUP CALCMENU WEB FOLDER WITH PICTURES INTO ZIP AND MOVE TO S3 with mention "FIRST" so it won't be deleted from Backup
    ###
    $bckPathcmweb="$Pathcmweb\Website\" 
    #
    $PathBackupApp=$PathBackupApp+$ClientName
    if(!(Test-Path -Path $PathBackupApp )){
        New-Item -ItemType directory -Path $PathBackupApp
    }
    #BACKUP
    $Time=Get-Date
    $FileBackup=$PathBackupApp+'\Website_'+$ClientName+'_First_'+$Time.ToString("yyyy-MM-dd")
    set-location $bckPathcmweb
    $dir = [string](get-location)
    Write-Host $FileBackup
    Write-Host $PathBackupApp
    Write-Host $bckPathcmweb
    Write-Host $dir
    if ($dir -eq $bckPathcmweb)
    {
       & $PathWinRar a -r -x*\Calcmenuapi\logs\* -x*\Logs\* $FileBackup $ClientName  #-x"*Bin/EgswKey.dll"  -x"web.config.bak" 
    }
    $FileBackup=$FileBackup+".rar"
    & $AwsExeFile s3 mv   "$FileBackup" s3://egss3/Backup/$ClientName/  #| Out-Null 
    Write-Host "CALCMENU WEB SOLUTION WITH PICTURES HAS BEEN ZIPED AND MOVE TO S3" -ForegroundColor "green"
}
#
#
#CREATE PACK
#
#
If ($DoPack -gt "0") 
{
    If ($DoPack -eq "1") 
    {
        #
        #Packing Website if exists
        #
        $PathcmwebCurrent="$Pathcmweb\Website\"+$ClientName
        $Time=Get-Date
        $FilePack=$PathBackupApp+$ClientName+'\Pack_CalcmenuWeb_'+$ClientName+'_'+$Time.ToString("yyyy-MM-dd")+'.rar'
        $PathToPack="$Pathcmweb\Website\$ClientName"
        Write-Host "Check folder: "$PathcmwebCurrent
        if (Test-Path $PathcmwebCurrent) 
        {
            Try
            {
                set-location $PathToPack
                $dir = [string](get-location)
                if ($dir -eq $PathToPack)
                {
                    "Folder exists. Starts Packing."
                    Write-Host "Path being packed: "$PathToPack 
                    & $PathWinRar a -r -ep1 -idq -idc -x*\Calcmenuapi\logs\* -x*\Logs\* $FilePack $PathToPack 
                    # 
                }
            }
            Catch
            {
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                $ErrorCount = $ErrorCount+1
                Write-Host $ErrorMessage
                Write-Host $FailedItem
                "script interupted"
                Break
            }
            Finally
            {
                If ($ErrorCount -gt 0)
                {
                    "An Error Occured." 
                    Write-Host "Error Count:",$ErrorCount
                    if (Test-Path $FilePack) { 
                        Remove-Item -Path $FilePack -Force 
                        "RAR FILE DELETED"
                    }
                    Exit
                }
                else
                {
                    "Packing done successfully"
                    Write-Host "Pack placed here: "$FilePack 
                }
            }
    }
    If ($DoPack -eq "2") 
    {
        #
        #Packing database if exists
        #
        #Backup database
        #
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null
 
        $server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $ComputerNameServerSql

        $dbName = $NewDbName
 
        $timestamp = Get-Date -format yyyy-MM-dd-HHmmss
        $targetPath = $PathBackupSql+$ClientName+"\" + $dbName + "_" + $timestamp + ".bak"
 
        $smoBackup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup")
        $smoBackup.Action = "Database"
        $smoBackup.BackupSetDescription = "Full Backup of " + $dbName
        $smoBackup.BackupSetName = $dbName + " Backup"
        $smoBackup.Database = $dbName
        $smoBackup.MediaDescription = "Disk"
        $smoBackup.CompressionOption = 1
        $smoBackup.Devices.AddDevice($targetPath, "File")
        $smoBackup.SqlBackup($server)
        "Backup completed for $dbName ($ComputerNameServerSql) to $targetPath"
        
        "Verifying Backup"
        $smoRestore = new-object ("Microsoft.SqlServer.Management.Smo.Restore")
        $smoRestore.Devices.AddDevice($dbName, [Microsoft.SqlServer.Management.Smo.DeviceType]::File)
        if (!($smoRestore.SqlVerify($server)))
        {
            "Backup has been verified. Health status OK"
        }
        else
        {
            "Backup verification completed with error."
            Write-Host "SCRIPT INTERRUPTED" -foregroundcolor "red"
            if (Test-Path $FilePack) { 
                Remove-Item -Path $FilePack -Force 
                "RAR FILE DELETED"
            }
            Break
        }
        #
        #Adding Backup file to RAR
        #
        ######################this should be done through network path
        #
        "Adding Database Backup to Pack"
        & $PathWinRar a -r -ep1 -idq -idc $FilePack $targetPath
        #
        "Removing Database Backup"
        if (Test-Path $targetPath) { 
            Remove-Item -Path $targetPath -Force 
            "Backup file deleted"
        }    
        #
        "Pack completed"
 
 
        #...
        }
    }
}
#
#
# REMOVE WEBSITE
# 
#
If ($DoRemoveWeb -eq "1") 
{
    $iisAppPoolName = $UrlName+".calcmenuweb.com"
    $iisAppName = $UrlName+".calcmenuweb.com"
    #
    #STOP WEBSITE
    Stop-WebSite -Name "$iisAppName"
    Write-host "WEBSITE [$iisAppName] HAS BEEN STOPPED" -foregroundcolor "green"
    #
    set-location "$Pathcmweb\Website"
    #
    #REMOVE FILES
    $targetPath="$Pathcmweb\Website\"+$ClientName
    if (Test-Path -Path $targetPath) { 
       "***" 
       $ConfirmDelete = Read-Host "Type 'delete' to confirm deletion of [$targetPath] ?" 
       if ($ConfirmDelete -eq "delete")
       {
           "DELETING FILES..."
           Remove-Item $targetPath\* -recurse  -Force 
           if (Test-Path -Path $targetPath)
           {
                Remove-Item -path $targetPath -Force 
           }
           if (Test-Path -Path $targetPath)
           {
                Write-host "WEBSITE FILES [$targetPath] ARE STILL THERE. PLEASE CHECK" -foregroundcolor "red"
           }
           else
           {
                Write-host "WEBSITE FILES [$targetPath] HAVE BEEN DELETED" -foregroundcolor "green"
           }
       }
    }
    #
    set-location
    #
    #REMOVE IIS SETUP
    if (Get-WebSite -Name "$iisAppName")
    {
        Write-Verbose "Removing '$iisAppName'..."
        Remove-WebSite -Name "$iisAppName" 
        Write-host "WEBSITE [$iisAppName] HAS BEEN DELETED" -foregroundcolor "green"
    }
    #REMOVE APP POOL
    Remove-Item IIS:\AppPools\$iisAppPoolName -Recurse
    Write-host "APP POOL [$iisAppPoolName] HAS BEEN DELETED" -foregroundcolor "green"
}
#
#
# REMOVE DATABASE
#
#
If ($DoRemoveDb -eq "1") 
{
    $DBNameToDrop=$NewDbName
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($ComputerNameServerSql)
    if ($server.Databases[$DBNameToDrop] -ne $null)  
    {  
        #drop database users
        if($server.databases[$DBNameToDrop].Users.Contains($UsernameForLogin))
        {
            $server.databases[$DBNameToDrop].Users[$UsernameForLogin].Drop();
            Write-Host "DATABASE USER DELETED: $UsernameForLogin" -foregroundcolor "green"
        }
        else
        {
            Write-Host "DATABASE USER DOES NOT EXIST: $UsernameForLogin" -foregroundcolor "Yellow"
        }
        #$server.killallprocess($DBNameToDrop)
        $server.databases[$DBNameToDrop].Drop()
        Write-Host "DATABASE DELETED: $DBNameToDrop" -foregroundcolor "green"
    }
    else
    {
        Write-Host "DATABASE DOES NOT EXIST: $NewDbName" -foregroundcolor "Yellow"
    }
    #drop server logins
    if ($server.Logins.Contains($UsernameForLogin)) 
    { 
        $server.Logins[$UsernameForLogin].Drop(); 
        Write-Host "SERVER LOGIN DELETED: $UsernameForLogin" -foregroundcolor "green"
    }
    else
    {
        Write-Host "SERVER LOGIN DOES NOT EXIST: $UsernameForLogin" -foregroundcolor "Yellow"
    }
}
#
#
###
###
### COPY WEB
###
###
If ($DoCopyWeb -eq "1") 
{
    If ($DoCopyWebProjectNameSource -eq $ProjectNameToDeploy)
    {
        Write-Host "Both source and destination cannot be the same" -foregroundcolor Red   
        break
    }
    #In progress
    #$PathcmwebCurrent="$Pathcmweb\Website\"+$ClientName
    #$PathcmwebCurrentSource="$Pathcmweb\Website\"+$DoCopyWebProjectNameSource
    #Source
    $SrcX="C:\Website\"+$DoCopyWebProjectNameSource
    if (Test-Path $SrcX)
    {
        $PathcmwebCurrentSource="C:\Website\"+$DoCopyWebProjectNameSource
    }
    Else
    {
        $SrcX="E:\Website\"+$DoCopyWebProjectNameSource
        if (Test-Path $SrcX)
        {
            $PathcmwebCurrentSource="E:\Website\"+$DoCopyWebProjectNameSource
        }
        Else
        {
            Write-host "WEBSITE [$DoCopyWebProjectNameSource] CANNOT BE FOUND" -foregroundcolor Red
            BREAK
        }
    }
    $PathcmwebCurrent="$Pathcmweb\Website\"+$ClientName
    $iisAppNameSource = "CalcmenuWeb_"+$DoCopyWebProjectNameSource
    #Destination
    $PathcmwebCurrentDest="$Pathcmweb\Website\"+$ClientName
    $iisAppNameDest = "CalcmenuWeb_"+$ClientName
    #
    # STOP IIS
    #
    $sites = Get-Website | where {$_.Name -eq $iisAppNameSource}
    If ($sites.State -eq "Stopped")
    {  
        #Is Stopped
        Write-host "WEBSITE [$iisAppNameSource] IS ALREADY STOPPED" -foregroundcolor "green"
    }
    elseif ($sites.State -eq "Started")
    {
        #Is Started
        #STOP WEBSITE
        "Stop: $iisAppNameSource"
        Stop-WebSite -Name "$iisAppNameSource"
        Write-host "WEBSITE [$iisAppNameSource] HAS BEEN STOPPED" -foregroundcolor "green"
    }
    #
    #
    # COPY ALL FILES
    #
    #Copy Files
    $DoCopyWebProjectNameDest
    Write-Host "Starts Copying files" -ForegroundColor Yellow
    if (Test-Path "$PathcmwebCurrentSource\CalcmenuWeb\") 
    {
        "Copy from: $PathcmwebCurrentSource\CalcmenuWeb\"
        "Copy to: $PathcmwebCurrentDest\CalcmenuWeb\"
        #20190815 Copy-Item "$PathcmwebCurrentSource\CalcmenuWeb\" "$PathcmwebCurrentDest\CalcmenuWeb\" -Filter *picnormal\Pistor*,*picOriginal\Pistor*,*picthumbnail\Pistor*,*picnormal\Scana*,*picOriginal\Scana*,*picthumbnail\Scana* -recurse -Force
        #20190815:
        $source = "$PathcmwebCurrentSource\CalcmenuWeb\"
        $dest = "$PathcmwebCurrentDest\CalcmenuWeb\"
        $exclude=""
        if (($SupplierPistor -eq "0") -and ($SupplierScana -eq "0")) {$exclude = @('Pistor_*.jpg','Scana_*.jpg')}
        if (($SupplierPistor -eq "1") -and ($SupplierScana -eq "0")) {$exclude = @('Scana_*.jpg')}
        if (($SupplierPistor -eq "0") -and ($SupplierScana -eq "1")) {$exclude = @('Pistor_*.jpg')}
        if (($exclude -eq "") -or ($IsMasterEgs -eq "0"))
        {
            Copy-Item $source $dest -recurse -Force
        }
        else
        {
            Get-ChildItem $source -Recurse -Exclude $exclude | Copy-Item -Destination {Join-Path $dest $_.FullName.Substring($source.length)}
        }
    }
    #
    # RESTART IIS
    #
    $sites = Get-Website | where {$_.Name -eq $iisAppNameSource}
    If ($sites.State -eq "Stopped")
    {  
        #Is Stopped
        Start-WebSite -Name "$iisAppNameSource"
        Write-host "WEBSITE [$iisAppNameSource] HAS BEEN RESTARTED" -foregroundcolor "green"
    }
    elseif ($sites.State -eq "Started")
    {
        Write-host "WEBSITE [$iisAppNameSource] IS ALREADY STARTED" -foregroundcolor "green"
    }
    #
    # SET FOLDER AND FILES PERMISSIONS ON COPY
    #
    $FolderPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb'
    "Set permissions to folder: $FolderPath"
    #
    $acl = Get-Acl $FolderPath 
    $colRights = [System.Security.AccessControl.FileSystemRights]"Read,Modify,ExecuteFile,ListDirectory" 
    $permission = "IIS_IUSRS",$colRights,"ContainerInherit,ObjectInherit”,”None”,”Allow” 
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission  
    $acl.AddAccessRule($accessRule) 
    Set-Acl $FolderPath $Acl
    Write-Host "FOLDER PERMISSION HAS BEEN SET" -foregroundcolor "green"
    #
    #
    #
    # SET IIS FOR COPY
    #
    if ($HTTPS -eq "1") 
    {
        "##########################"
        $ComputerNameServerAppInternalHttps 
        $Pathcmweb 
        $ClientName 
        $UrlNameServer
        "##########################"
        BindWebsite  $ComputerNameServerAppInternalHttps $Pathcmweb $ClientName $UrlNameServer
        #not needed since we copy the web config #WebConfigRewrite $Pathcmweb $ClientName
        $iisAppName = "CalcmenuWeb_$ClientName"
    }
    else
    {
        push-location
        Import-Module WebAdministration
        #$iisAppPoolName = $UrlName+".calcmenuweb.com"
        $iisAppPoolName = "CalcmenuWeb_$ClientName"
        $iisAppPoolDotNetVersion = "v4.0"
        #$iisAppName = $UrlName+".calcmenuweb.com"
        $iisAppName = "CalcmenuWeb_$ClientName"
        $iisAppNameBinding = $UrlNameServer+".calcmenuweb.com"
        $directoryPath = "$Pathcmweb\Website\$ClientName\CalcmenuWeb"
        #
        $iisAppPoolName 
        $iisAppName 
        $iisAppNameBinding 
        $directoryPath 
        #
        #navigate to the app pools root
        cd IIS:\AppPools\
        #check if the app pool exists
        if (!(Test-Path $iisAppPoolName -pathType container))
        {
            #create the app pool
            $appPool = New-Item $iisAppPoolName
            $appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $iisAppPoolDotNetVersion
        }
        #navigate to the sites root
        cd IIS:\Sites\
        #check if the site exists
        if (Test-Path $iisAppName -pathType container)
        {
            #do nothing
        }
        else
        {
            #create the site 
            $AllUnassigned="*"
            $iisApp = New-Item $iisAppName -bindings @{protocol="http";bindingInformation="$($AllUnassigned):80:" + $iisAppNameBinding} -physicalPath $directoryPath
            $iisApp | Set-ItemProperty -Name "applicationPool" -Value $iisAppPoolName
            Write-Host "WEBSITE AND APPLICATION POOL HAS BEEN SETUP" -foregroundcolor "green"
        }
        pop-location
    }
    #
    #Convert folder to application
    #7.3.2018 - ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\calcmenuapi"
    #Retired 27.01.2017 ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\Declaration"
    #7.3.2018 - ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\Kiosk"
    #new 30.19
    #7.3.2018 - ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\ReportXML"
    #new 30.19
    #7.3.2018 - Write-Host "APPLICATION FOLDERS HAVE BEEN CONVERTED" -foregroundcolor "green"
    #
    #SETUP LICENSE KEY
    #
    $choice = ""
    if ($Silent -eq "0")
    {
        while ($choice -notmatch "[y|n]")
        {
            $choice = read-host "Do you wish to deploy a new key ? (Y/N)"
        }
    }
    else
    {
        if ($AutoDeployKey -eq "1")
        {
            $choice = "y"
        }
    }
    if ($choice -eq "y")
    {
        $PathClientLicenseKey="$PathcmwebRoot\Keys\EgswKey$ClientName.dll"
        "Copy this key $PathClientLicenseKey" 
        if (Test-Path $PathClientLicenseKey) 
        {
            $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\bin\EgswKey.dll'
            "To: $LicenseKeyPath" 
            Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
            #
            $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\Kiosk\bin\EgswKey.dll'
            "To: $LicenseKeyPath" 
            Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
            #
            $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\MenuPlanView\bin\EgswKey.dll'
            "To: $LicenseKeyPath" 
            Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
            #
            $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\RecipeExport\bin\EgswKey.dll'
            "To: $LicenseKeyPath" 
            Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
            #
            $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\DataExport\bin\EgswKey.dll'
            "To: $LicenseKeyPath" 
            Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
            #
            $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\DataAnalytics\bin\EgswKey.dll'
            "To: $LicenseKeyPath" 
            Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
            #
            $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\RecipeImport\bin\EgswKey.dll'
            "To: $LicenseKeyPath" 
            Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
            #
            $LicenseKeyPath="$Pathcmweb\Website\"+$ClientName+'\CalcmenuWeb\inventory\bin\EgswKey.dll'
            "To: $LicenseKeyPath" 
            Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
            #
            Write-Host "PRODUCT KEY HAS BEEN SETUP" -foregroundcolor "green"
        }
        else
        {
            Write-Host "LICENSE KEY IS MISSING!!!" -foregroundcolor "red"
            Write-Host "SCRIPT INTERRUPTED" -foregroundcolor "red"
            Break
        }
    }
    #
    # CHANGES IN WEB.CONFIG AND OTHER FILES
    #
    "--"
    $return = ReadFromConfigFileForCopyWeb $DoCopyWebProjectNameSource
    
    $ClientNameSource=$return[0]
    $HTTPSSource=$return[1]
    $IsMigrosSource=$return[2]
    $LanguageCodeSource=$return[3]
    $PasswordDbSource=$return[4]
    $UrlNameServerSource=$return[5]

    $DataSourceIPSource = $DataSourceIP
    $UsernameForLoginSource="cmweb_$ClientNameSource"
    $UsernameForLoginSource=$UsernameForLoginSource.ToLower()

    $ClientNameSource 
    $DataSourceIPSource 
    $HTTPSSource 
    $IsMigrosSource 
    $LanguageCodeSource 
    $PasswordDbSource 
    $PathcmwebCurrentSource 
    $UrlNameServerSource 
    $UsernameForLoginSource 
    "--"
    #
    fctReplaceParametersInConfigsNew $PathcmwebCurrent $DataSourceIP $ClientName $UsernameForLogin $PasswordDb $UrlNameServer $IsMigros $DOVersion $DOVersionMain $CultureKiosk $HTTPS $UseDeclarationTool $LanguageCode $CultureFormatDate $CultureFormatDateNum $CultureFormatNumber $ClientNameSource $DataSourceIPSource $HTTPSSource $IsMigrosSource $LanguageCodeSource $PasswordDbSource $PathcmwebCurrentSource $UrlNameServerSource $UsernameForLoginSource
    #
    # CONFIGURE THE DOMAIN NAME 
    #
    if ($HTTPS -eq "1") 
    {
        $IpForDomainName=$ComputerNameServerAppExternalHttps
        $httpType="https:"
    }
    else
    {
        $IpForDomainName=$ComputerNameServerAppExternal
        $httpType="http:"
    }
    #
    $choice = ""
    if ($Silent -eq "0")
    {
        while ($choice -notmatch "[y|n]")
        {
            $choice = read-host "Do you wish to setup the domain name $httpType//$UrlName.calcmenuweb.com with IP address: $IpForDomainName ? (Y/N)"
        }
    }
    else
    {
        if ($AutoCreateDomain -eq "1")
        {
            $choice = "y"
        }
    }
    if ($choice -eq "y")
    {
        New-R53ResourceRecordSet -ProfileName "egs.sandro" -Value $IpForDomainName -Type "A" -RecordName $UrlName -TTL 3600 -ZoneName "calcmenuweb.com"   
        Write-host "Domain Name $UrlName.calcmenuweb.com has been setup on $IpForDomainName" -foregroundcolor Green
    }
    #
    #$DoChangeUrl="4"
    #$UrlOrigin=ReadUrlFromConfigFile $DoCopyWebProjectNameSource
    #$UrlReplacement=$UrlNameServer
    #
    #
    Write-host "########### EGS TOOL - COPY OF WEB COMPLETED ###########" -foregroundcolor Yellow
    Write-host "### Look for errors and report them to SG. " -foregroundcolor Yellow
    Write-host "### Thank you." -foregroundcolor Yellow
}
#
#
###
###
### RESTORE WEB
###
###
If ($DoRestoreWeb -eq "1") 
{
    $ProjectNameList=$ProjectNameToDeploy #"SandroArg"
    $FolderWebsite=$DoRestoreWebFolder #"C"
    #
    If ($FolderWebsite -eq $null)
    {
        $FolderWebsite=$FolderWebsite+":\"
        If (Test-Path $FolderWebsite)
        {
            #ok
        }
        else
        {
            If (Test-Path "D:\website")
            {    $FolderWebsite="D:\website" }
            elseif (Test-Path "E:\website")
            {    $FolderWebsite="E:\website" }
            elseif (Test-Path "C:\website")
            {    $FolderWebsite="C:\website" }
            If ($FolderWebsite -eq "")
            {
                Write-Host "No \Backup folder found. PROCEDURE STOPPED." -ForegroundColor Red
                Break
            }
        }
    }
    else 
    {
        $FolderWebsiteTest=$FolderWebsite+":\website\"#+$ProjectNameList
        If (!(Test-Path $FolderWebsiteTest))
        {
            Write-host "Invalid drive letter" -ForegroundColor Red
            Break
        }
        $FolderWebsite=$FolderWebsite+":\website"
    }
    $FolderWebsite
    #

    #
    If ($ProjectNameList -eq "")
    {
        Write-Host "Invalid Project Name" -ForegroundColor Red    
        Break
    }
    $ClientName=$ProjectNameList

    #$VersionCmWeb="v8.2"
    #$PatchCmWeb="v8.2-Patch"
    #$VersionTool="1.0.00"
    #$DoIIS="0"
    #$DOVersion="v8.2"
    #$DOVersionMain="2015" 
    #
    $TimeStampPatch=Get-Date -format yyyy-MM-dd-HHmmss
    #
    ########################################
    #
    #
    ########################################
    #
    $PathcmwebRoot="C:\EgsExchange" #Folder where file exchanged with servers is located
    $PathBackupApp="C:\Backup\"        #Location of the backup files (temporary)
    #
    $PathPS="C:\Powershell\"  
    $PathWinUnRar="C:\Program Files\WinRAR\unrar.exe"
    #
    If (Test-Path "D:\Backup")
    {    $LocalPathForBackup="D:\Backup" }
    elseif (Test-Path "E:\Backup")
    {    $LocalPathForBackup="E:\Backup" }
    elseif (Test-Path "C:\Backup")
    {    $LocalPathForBackup="C:\Backup" }
    If ($LocalPathForBackup -eq "")
    {
        Write-Host "No \Backup folder found. PROCEDURE STOPPED." -ForegroundColor Red
        Break
    }
    
    $AwsExeFile="C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    
    #$PSVersionTable
    #cls
    #
    #
    Write-host "########### EGS RESTORE TOOL ###########" -foregroundcolor cyan
    Write-host "### Project(s): $ProjectName " -foregroundcolor cyan
    Write-host "### Version of tool: $VersionTool" -ForegroundColor cyan
    #
    Write-Host "Looking for Web Backup of $ClientName on $NowString" -ForegroundColor Magenta
    #
    $PathTempFile="C:\EgsExchange"
    $NowStringShort=Get-Date -format yyyyMMdd
    #$NowStringShort="20210706"
    $NowString=[string]$NowStringShort.Substring(0,4)+"-"+$NowStringShort.Substring(4,2)+"-"+$NowStringShort.Substring(6,2)
    $NowString="2025-07-13"    
    #
    & $AwsExeFile s3 ls "s3://egss3/Backup/$ClientName" --recursive --profile egs.s31 | out-file "$PathTempFile\awsfiles.txt"
    #Read the file that contain the deployment information
    #$strWhere="*$ClientName"+"_Web_B4update*$NowString*.rar"
    
    $strWhere="*Website_$ClientName"+"_FULL_*$NowString*.rar"
    $filedata=Get-Content "$PathTempFile\awsfiles.txt"  | where { $_ -like $strWhere } 
    foreach ($line in $filedata)
    {
    
        $i=$line.Indexof("Backup/$ClientName")
        if ($i -gt 0) 
        {
            Write-Host "Found it!" -ForegroundColor Green
            #write-host $line -ForegroundColor Magenta
            $j=$line.IndexOf("Backup")
            $BackupPath=$line.Substring($j,$line.Length-$j)
            Write-Host "Path of the backup on S3: $BackupPath" -ForegroundColor Yellow
            $BackupFilenameRar=$BackupPath.replace("Backup/",$LocalPathForBackup+"/")
            Write-Host "Filename of the backup on S3: $BackupFilenameRar" -ForegroundColor Yellow
            #
            $choice = ""
            while ($choice -notmatch "[y|n]")
            {
                $choice = read-host "Is it OK to restore this web backup: $BackupFilenameRar ? (Y/N)"
            }
            if ($choice -eq "y")
            {
                If (Test-Path "$LocalPathForBackup\$BackupFilenameRar")
                {
                    Write-Host "File $LocalPathForBackup\$BackupFilenameRar already exists. It is not redownloaded." -ForegroundColor Yellow
                }
                else
                {
                    Write-Host "Downloading Backup to $LocalPathForBackup..." -ForegroundColor Magenta
                    & $AwsExeFile s3 cp  "s3://egss3/$BackupPath" "$BackupFilenameRar" --profile egs.s31
                }
                If (!(Test-Path "$BackupFilenameRar"))
                {
                    Write-Host "File $BackupFilenameRar is missing. PROCEDURE STOPPED." -ForegroundColor Red
                    Break
                }
                #
                $FullBackupFilenameBak=$BackupFilenameRar
                $FullBackupExtracted=$FullBackupFilenameBak.Replace(".rar","")
                #
                If (Test-Path $FullBackupExtracted)
                {
                    Write-Host "File $FullBackupExtracted already exists. It is not reextracted." -ForegroundColor Yellow
                }
                else
                {
                    $choice = ""
                    $FolderWebsiteTest=$FolderWebsite+"\"+$ClientName
                    If (Test-Path $FolderWebsiteTest)
                    {
                        while ($choice -notmatch "[y|n]")
                        {
                            $choice = read-host "This folder already exist: $FolderWebsiteTest. Do you wish to continue ? (You may delete it manually first) (Y/N)"
                        }
                    }
                    else {$choice="y"} 
                    if ($choice -eq "y")
                    {
                        Write-Host "Extracting Backup to $FullBackupExtracted..." -ForegroundColor Magenta
                        $FolderToExtract=$FolderWebsite+"\"+$ClientName+"\CalcmenuWeb\" # Added 2025-06-28 
                        # Removed 2025-06-28 & $PathWinUnRar x -idc -idq $BackupFilenameRar "$FolderWebsite\"
                        & $PathWinUnRar x -idc -idq $BackupFilenameRar "$FolderToExtract\"  # Added 2025-06-28 
                    }
                }
                If (Test-Path $BackupFilenameRar)
                {
                    Write-Host "Deleting File $BackupFilenameRar " -ForegroundColor yellow
                    Remove-Item -Path $BackupFilenameRar -Force
                }
            }
        }
    }
    #
    #
    # SET FOLDER AND FILES PERMISSIONS ON COPY
    #
    $FolderPath=$FolderWebsite+"\"+$ClientName+"\CalcmenuWeb"
    "Set permissions to folder: $FolderPath"
    #
    $acl = Get-Acl $FolderPath 
    $colRights = [System.Security.AccessControl.FileSystemRights]"Read,Modify,ExecuteFile,ListDirectory" 
    $permission = "IIS_IUSRS",$colRights,"ContainerInherit,ObjectInherit”,”None”,”Allow” 
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission  
    $acl.AddAccessRule($accessRule) 
    Set-Acl $FolderPath $Acl
    Write-Host "FOLDER PERMISSION HAS BEEN SET" -foregroundcolor "green"
    #
    #
    #
    # SET IIS FOR COPY
    #
    "##########################"
    $ComputerNameServerAppInternalHttps 
    $Pathcmweb 
    $ClientName 
    $UrlNameServer
    "##########################"
    BindWebsite  $ComputerNameServerAppInternalHttps $Pathcmweb $ClientName $UrlNameServer
    #not needed since we copy the web config #WebConfigRewrite $Pathcmweb $ClientName
    $iisAppName = "CalcmenuWeb_$ClientName"
    #
    #
    # CHANGES IN WEB.CONFIG AND OTHER FILES
    #

    #fctReplaceParametersInConfigsNew $PathcmwebCurrent $DataSourceIP $ClientName $UsernameForLogin $PasswordDb $UrlNameServer $IsMigros $DOVersion $DOVersionMain $CultureKiosk $HTTPS $UseDeclarationTool $LanguageCode $CultureFormatDate $CultureFormatDateNum $CultureFormatNumber $ClientNameSource $DataSourceIPSource $HTTPSSource $IsMigrosSource $LanguageCodeSource $PasswordDbSource $PathcmwebCurrentSource $UrlNameServerSource $UsernameForLoginSource

    $PathcmwebCurrent=$FolderWebsite+"\"+$ClientName
    $DoRestoreWebPathcmwebCurrentSource=$DoRestoreWebPathcmwebCurrentSource+":\Website\"+$ClientName
    #Need to change only 
    fctReplaceParametersInConfigsNewForRestoreWeb $PathcmwebCurrent $DoRestoreWebDataSourceIPTarget  $DoRestoreWebDataSourceIPSource $DoRestoreWebPathcmwebCurrentSource 
    #
    # CONFIGURE THE DOMAIN NAME 
    #
    #$IpForDomainName=$ComputerNameServerAppExternalHttps
    #$httpType="https:"
    #
    Write-host "You must change the IP address for the Domain Name $UrlName.calcmenuweb.com " -foregroundcolor Cyan
    #
    #
    Write-host "########### EGS TOOL - RESTORE OF WEB COMPLETED ###########" -foregroundcolor Yellow
    Write-host "### Look for errors and report them to SG. " -foregroundcolor Yellow
    Write-host "### Thank you." -foregroundcolor Yellow
}
#
#

#CHANGE URL
#
#
If ($DoChangeUrl -gt "0") 
{
    # =1 Replace the regular domain name (ex: client.calcmenuweb.com) with an URL for that server (ex: client.argus.calcmenuweb.com)
    # =2 Replace the URL for that server (ex: client.argus.calcmenuweb.com) with the rgular domain name (ex: client.calcmenuweb.com)
    # =4 Replace the URLA by URLB for that server (ex: clienta.calcmenuweb.com with clientb.calcmenuweb.com)
    # =8 Change from http to https 
    #
    if ($DoChangeUrl -eq "8")
    {
        #Change http URL with https URL
        #URL is read from deploy file, so we ignore the parameter passed
        #
        #Force parameters
        $UrlOrigin=$UrlName
        $UrlReplacement=$UrlName
        #
        $PathcmwebCurrent=$Pathcmweb+"\Website\"+$ClientName
        $DomainServerName=$ServerToDeployToApp.ToLower() #Ex: argus
        #
        #Go to the folder where web.config is located
        $WebConfigFolder=$PathcmwebCurrent+"\CalcmenuWeb"
        write-host "Current Folder:"$WebConfigFolder
        set-location $WebConfigFolder
        #Check current location
        $UrlName1=$UrlName 

        $dir = [string](get-location)
        #Make sure we are really where we are supposed to be
        if ($dir -eq $WebConfigFolder)
        {
            (Get-Content web.config) | 
            Foreach-Object {$_ -replace "http://$UrlOrigin.calcmenuweb.com","https://$UrlReplacement.calcmenuweb.com"}  | 
            Out-File -Encoding utf8 web.config
        }
        #Go to the folder where \calcmenuapi\web.config is located
        $WebConfigFolderApi=$WebConfigFolder+"\calcmenuapi"
        set-location $WebConfigFolderApi
        #Check current location
        $dir = [string](get-location)
        #Make sure we are really where we are supposed to be
        if ($dir -eq $WebConfigFolderApi)
        {
            (Get-Content web.config) | 
            Foreach-Object {$_ -replace "http://$UrlOrigin.calcmenuweb.com","https://$UrlReplacement.calcmenuweb.com"}  | 
            Out-File -Encoding utf8 web.config
        }
  
        #Go to the folder where \kiosk\web.config is located
        $WebConfigFolderKiosk=$WebConfigFolder+'\kiosk'
        set-location $WebConfigFolderKiosk
        #Check current location
        $dir = [string](get-location)
        #Make sure we are really where we are supposed to be
        if ($dir -eq $WebConfigFolderKiosk)
        {
            (Get-Content web.config) | 
            Foreach-Object {$_ -replace "http://$UrlOrigin.calcmenuweb.com","https://$UrlReplacement.calcmenuweb.com"}  | 
            Out-File -Encoding utf8 web.config
       }
         #Go to the folder where \Declaration\web.config is located
        $WebConfigFolderDeclaration=$WebConfigFolder+'\Declaration'
        set-location $WebConfigFolderDeclaration
        #Check current location
        $dir = [string](get-location)
        if ($dir -eq $WebConfigFolderDeclaration)
        {
            (Get-Content web.config) | 
            Foreach-Object {$_ -replace "http://$UrlOrigin.calcmenuweb.com","https://$UrlReplacement.calcmenuweb.com"}  | 
            Out-File -Encoding utf8 web.config
        }
         #Go to the folder where \Declaration\web.config is located
        $WebConfigFolderDeclaration=$WebConfigFolder+'\kiosk\assets\js'
        set-location $WebConfigFolderDeclaration
        #Check current location
        $dir = [string](get-location)
        if ($dir -eq $WebConfigFolderDeclaration)
        {
            (Get-Content kiosk.baseURL.min.js) | 
            Foreach-Object {$_ -replace "http://$UrlOrigin.calcmenuweb.com","https://$UrlReplacement.calcmenuweb.com"}  | 
            Out-File -Encoding utf8 kiosk.baseURL.min.js
        }
        #Change Binding
        #
        #THIS IS TO CHANGE THE IIS CONFIGURATION AND APP POOLS NAMES (INCLUDING THE BINDINGS, BUT NOT THE PATH)
        #THE PROCESS IS TO RECREATE EVERYTHING
        #
        $iisAppNameBeforeA = "$UrlOrigin.calcmenuweb.com"
        $iisAppNameBindingAfter ="$UrlReplacement.calcmenuweb.com"
        $iisAppPoolNameBeforeA = $iisAppNameBeforeA  
        $iisAppNameBeforeB = "CalcmenuWeb_$ClientName"
        $iisAppPoolNameBeforeB = "CalcmenuWeb_$ClientName"
        #Before
        #$iisAppNameBefore = $UrlName+".calcmenuweb.com"
        #$iisAppPoolNameBefore = $UrlName+".calcmenuweb.com"
        #$iisAppNameBefore = "CalcmenuWeb_$ClientName"
        #$iisAppPoolNameBefore = "CalcmenuWeb_$ClientName"

        #After
        $iisAppNameAfter = "CalcmenuWeb_$ClientName" 
        $iisAppPoolNameAfter = "CalcmenuWeb_$ClientName" 
        #$iisAppNameBindingAfter = $UrlNameServer+".calcmenuweb.com"

        #
        $iisAppPoolDotNetVersion = "v4.0"
        $directoryPath = "$Pathcmweb\Website\$ClientName\CalcmenuWeb"
        #
        #
        "iisAppNameBeforeA $iisAppNameBeforeA"
        "iisAppNameBeforeB $iisAppNameBeforeB"
        "iisAppPoolNameBeforeA $iisAppPoolNameBeforeA"
        "iisAppPoolNameBeforeB $iisAppPoolNameBeforeB"
        #
        #
        #DELETE FIRST ALL
        #
        #REMOVE IIS SETUP
        push-location
        Import-Module WebAdministration
        cd IIS:\Sites\
        if (Test-Path  $iisAppNameBeforeA -pathType container)
        {
            Stop-WebSite -Name "$iisAppNameBeforeA"
            Write-host "WEBSITE [$iisAppNameBeforeA] HAS BEEN STOPPED" -foregroundcolor "green"
            Write-Verbose "Removing '$iisAppNameBeforeA'..."
            Remove-WebSite -Name "$iisAppNameBeforeA" 
            Write-host "WEBSITE [$iisAppNameBeforeA] HAS BEEN DELETED" -foregroundcolor "green"
        }
        else
        {
            if (Test-Path  $iisAppNameBeforeB -pathType container)
            {
                Stop-WebSite -Name "$iisAppNameBeforeB"
                Write-host "WEBSITE [$iisAppNameBeforeB] HAS BEEN STOPPED" -foregroundcolor "green"
                Write-Verbose "Removing '$iisAppNameBeforeB'..."
                Remove-WebSite -Name "$iisAppNameBeforeB" 
                Write-host "WEBSITE [$iisAppNameBeforeB] HAS BEEN DELETED" -foregroundcolor "green"
            }
        }
        #REMOVE APP POOL
        cd IIS:\AppPools\
        if (Test-Path $iisAppPoolNameBeforeA -pathType container)
        {
            Remove-Item IIS:\AppPools\$iisAppPoolNameBeforeA -Recurse
            Write-host "APP POOL [$iisAppPoolNameBeforeA] HAS BEEN DELETED" -foregroundcolor "green"
        }
        else
        {
            if (Test-Path $iisAppPoolNameBeforeB -pathType container)
            {
                Remove-Item IIS:\AppPools\$iisAppPoolNameBeforeB -Recurse
                Write-host "APP POOL [$iisAppPoolNameBeforeB] HAS BEEN DELETED" -foregroundcolor "green"
            }
        }
        #
        #RECREATE
        #navigate to the app pools root
        cd IIS:\AppPools\
        #check if the app pool exists
        if (!(Test-Path $iisAppPoolNameAfter -pathType container))
        {
            #create the app pool
            $appPool = New-Item $iisAppPoolNameAfter
            $appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $iisAppPoolDotNetVersion
        }
        #navigate to the sites root
        cd IIS:\Sites\
        #check if the site exists
        if (Test-Path $iisAppNameAfter -pathType container)
        {
            #do nothing
        }
        else
        {
            #create the site
            #Get-ChildItem -path cert:\LocalMachine\My
            $thumbprint="844B4F4D5D8980690250FCEF865CC9F64AC94705"
            $AllUnassigned="*"
            $Certificat = Get-ChildItem cert:\LocalMachine\My | ?{$_.Thumbprint -eq $thumbprint}
            $iisApp = New-Item $iisAppNameAfter -bindings @{protocol="https";bindingInformation="$($AllUnassigned):443:" + $iisAppNameBindingAfter;SslFlags=1} -physicalPath $directoryPath #-Force  #$ComputerNameServerAppInternalHttps+

            #-value @{protocol="https";bindingInformation="*:$($port):$($hostheader)";certificateStoreName="My";certificateHash=$thumbprint}

            #$iisApp = New-Item $iisAppNameAfter -bindings @{protocol="http";bindingInformation=":80:" + $iisAppNameBindingAfter} -physicalPath $directoryPath
            $iisApp | Set-ItemProperty -Name "applicationPool" -Value $iisAppPoolNameAfter
            Write-Host "WEBSITE AND APPLICATION POOL HAS BEEN SETUP" -foregroundcolor "green"
            #Rod
        }
        #Convert folder to applicatio
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\calcmenuapi"
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\Kiosk"
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\ws"
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\ReportXML"
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\emenu"
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\emenuplan"
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\wsapi"
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\AdvancedShoppingList"
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\MenuPlanView"
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\RecipeImport"
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\RecipeExport"
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\DataExport"
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\DataAnalytics"
        
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\shoppinglistWS"
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\inventory"
        #new 23.4.2021
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\erecipe"
        #new 30.19
        pop-location
        Write-Host "APPLICATION FOLDERS HAVE BEEN CONVERTED" -foregroundcolor "green"
        #
        
        #Go to the folder where web.config is located
        $WebConfigFolder=$PathcmwebCurrent+"\CalcmenuWeb"
        write-host "Current Folder:"$WebConfigFolder
        set-location $WebConfigFolder
        #Check current location
        $UrlName1=$UrlName 

        $dir = [string](get-location)
        #Make sure we are really where we are supposed to be
        if ($dir -eq $WebConfigFolder)
        {
            $RedirectingToHttps="<rewrite>
                    <rules>               
                        <rule name=""HTTP to HTTPS redirect"" enabled=""true"" stopProcessing=""true"">
                            <match url=""(.*)"" />
                            <conditions logicalGrouping=""MatchAll"" trackAllCaptures=""false"">
                                <add input=""{HTTPS}"" pattern=""off"" ignoreCase=""true"" />
                            </conditions>
                            <action type=""Redirect"" url=""https://{HTTP_HOST}/{R:1}"" redirectType=""Found"" />
                        </rule>                                                                                                               
                    </rules>
                </rewrite>
            </system.webServer>"
            #
            (Get-Content web.config) | 
            Foreach-Object {$_ -replace "</system.webServer>",$RedirectingToHttps}  | 
            Out-File -Encoding utf8 web.config
        }

    }
    else
    {
        if ($DoChangeUrl -eq "4")
        {
            if (($UrlOrigin -eq "") -or ($UrlReplacement -eq ""))
            {
                Write-host "SCRIPT INTERRUPTED - Missing URL for Origin and/or Replacement" -foregroundcolor "red"
                BREAK
            }
        }
        #
        If ($DoChangeUrl -eq "1") 
        {
            $UrlA=$UrlName1
            $UrlB="$UrlName.$DomainServerName" 
        }
        elseif ($DoChangeUrl -eq "2")
        {
            $UrlA="$UrlName1.$DomainServerName"
            $UrlB=$UrlName 
        }
        elseif ($DoChangeUrl -eq "4")
        {
            $UrlA=$UrlOrigin
            $UrlB=$UrlReplacement
        }
        "Replace URL $UrlA"
        "With URL $UrlB"
        #
        $PathcmwebCurrent=$Pathcmweb+"\Website\"+$ClientName
        $PathcmwebCurrent
        #$DomainServerName=$ServerToDeployToApp.ToLower() #Ex: argus
        #
        #Go to the folder where web.config is located
        $WebConfigFolder=$PathcmwebCurrent+"\CalcmenuWeb"
        write-host "Current Folder:"$WebConfigFolder
        set-location $WebConfigFolder
        #Check current location
        $UrlName1=$UrlName 

        $dir = [string](get-location)
        #Make sure we are really where we are supposed to be
        if ($dir -eq $WebConfigFolder)
        {
            (Get-Content web.config) | 
            Foreach-Object {$_ -replace "$UrlA.calcmenuweb.com","$UrlB.calcmenuweb.com"}  | 
            Out-File -Encoding utf8 web.config
        }
        #Go to the folder where \calcmenuapi\web.config is located
        $WebConfigFolderApi=$WebConfigFolder+"\calcmenuapi"
        set-location $WebConfigFolderApi
        #Check current location
        $dir = [string](get-location)
        #Make sure we are really where we are supposed to be
        if ($dir -eq $WebConfigFolderApi)
        {
            (Get-Content web.config) | 
            Foreach-Object {$_ -replace "$UrlA.calcmenuweb.com","$UrlB.calcmenuweb.com"}  | 
            Out-File -Encoding utf8 web.config
        }
        #Go to the folder where \kiosk\web.config is located
        $WebConfigFolderKiosk=$WebConfigFolder+'\kiosk'
        set-location $WebConfigFolderKiosk
        #Check current location
        $dir = [string](get-location)
        #Make sure we are really where we are supposed to be
        if ($dir -eq $WebConfigFolderKiosk)
        {
            (Get-Content web.config) | 
            Foreach-Object {$_ -replace "$UrlA.calcmenuweb.com","$UrlB.calcmenuweb.com"}  | 
            Out-File -Encoding utf8 web.config
        }
        <#
        #Go to the folder where \Declaration\web.config is located
        $WebConfigFolderDeclaration=$WebConfigFolder+'\Declaration'
        set-location $WebConfigFolderDeclaration
        #Check current location
        $dir = [string](get-location)
        if ($dir -eq $WebConfigFolderDeclaration)
        {
            (Get-Content web.config) | 
            Foreach-Object {$_ -replace "$UrlA.calcmenuweb.com","$UrlB.calcmenuweb.com"}  | 
            Out-File -Encoding utf8 web.config
        }
        #>
        #Go to the folder where \Declaration\web.config is located
        $WebConfigFolderDeclaration=$WebConfigFolder+'\kiosk\assets\js'
        set-location $WebConfigFolderDeclaration
        #Check current location
        $dir = [string](get-location)
        if ($dir -eq $WebConfigFolderDeclaration)
        {
            (Get-Content kiosk.baseURL.min.js) | 
            Foreach-Object {$_ -replace "$UrlA.calcmenuweb.com","$UrlB.calcmenuweb.com"}  | 
            Out-File -Encoding utf8 kiosk.baseURL.min.js
        }
        #Change Binding
        #
        #THIS IS TO CHANGE THE IIS CONFIGURATION AND APP POOLS NAMES (INCLUDING THE BINDINGS, BUT NOT THE PATH)
        #THE PROCESS IS TO RECREATE EVERYTHING
        #
        $iisAppNameBeforeA = "$UrlA.calcmenuweb.com"
        $iisAppNameBindingAfter ="$UrlB.calcmenuweb.com"
        $iisAppPoolNameBeforeA = $iisAppNameBeforeA
        $iisAppNameBeforeB = "CalcmenuWeb_$ClientName"
        $iisAppPoolNameBeforeB = "CalcmenuWeb_$ClientName"
        #Before
        #$iisAppNameBefore = $UrlName+".calcmenuweb.com"
        #$iisAppPoolNameBefore = $UrlName+".calcmenuweb.com"
        #$iisAppNameBefore = "CalcmenuWeb_$ClientName"
        #$iisAppPoolNameBefore = "CalcmenuWeb_$ClientName"

        #After
        $iisAppNameAfter = "CalcmenuWeb_$ClientName" 
        $iisAppPoolNameAfter = "CalcmenuWeb_$ClientName" 
        #$iisAppNameBindingAfter = $UrlNameServer+".calcmenuweb.com"

        #
        $iisAppPoolDotNetVersion = "v4.0"
        $directoryPath = "$Pathcmweb\Website\$ClientName\CalcmenuWeb"
        #
        #
        "iisAppNameBeforeA $iisAppNameBeforeA"
        "iisAppNameBeforeB $iisAppNameBeforeB"
        "iisAppPoolNameBeforeA $iisAppPoolNameBeforeA"
        "iisAppPoolNameBeforeB $iisAppPoolNameBeforeB"
        #
        #DELETE FIRST ALL
        #
        #REMOVE IIS SETUP
        cd IIS:\Sites\
        if (Test-Path  $iisAppNameBeforeA -pathType container)
        {
            Write-Verbose "Removing '$iisAppNameBeforeA'..."
            Remove-WebSite -Name "$iisAppNameBeforeA" 
            Write-host "WEBSITE [$iisAppNameBeforeA] HAS BEEN DELETED" -foregroundcolor "green"
        }
        else
        {
            if (Test-Path  $iisAppNameBeforeB -pathType container)
            {
                Write-Verbose "Removing '$iisAppNameBeforeB'..."
                Remove-WebSite -Name "$iisAppNameBeforeB" 
                Write-host "WEBSITE [$iisAppNameBeforeB] HAS BEEN DELETED" -foregroundcolor "green"
            }
        }
        #REMOVE APP POOL
        cd IIS:\AppPools\
        if (Test-Path $iisAppPoolNameBeforeA -pathType container)
        {
            Remove-Item IIS:\AppPools\$iisAppPoolNameBeforeA -Recurse
            Write-host "APP POOL [$iisAppPoolNameBeforeA] HAS BEEN DELETED" -foregroundcolor "green"
        }
        else
        {
            if (Test-Path $iisAppPoolNameBeforeB -pathType container)
            {
                Remove-Item IIS:\AppPools\$iisAppPoolNameBeforeB -Recurse
                Write-host "APP POOL [$iisAppPoolNameBeforeB] HAS BEEN DELETED" -foregroundcolor "green"
            }
        }
        #
        #RECREATE
        #navigate to the app pools root
        cd IIS:\AppPools\
        #check if the app pool exists
        if (!(Test-Path $iisAppPoolNameAfter -pathType container))
        {
            #create the app pool
            $appPool = New-Item $iisAppPoolNameAfter
            $appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $iisAppPoolDotNetVersion
        }
        #navigate to the sites root
        cd IIS:\Sites\
        #check if the site exists
        if (Test-Path $iisAppNameAfter -pathType container)
        {
            #do nothing
        }
        else
        {
            #create the site
            $AllUnassigned="*"

            $iisApp = New-Item $iisAppNameAfter -bindings @{protocol="http";bindingInformation="$($AllUnassigned):80:" + $iisAppNameBindingAfter} -physicalPath $directoryPath
            $iisApp | Set-ItemProperty -Name "applicationPool" -Value $iisAppPoolNameAfter
            Write-Host "WEBSITE AND APPLICATION POOL HAS BEEN SETUP" -foregroundcolor "green"
        }
        #Convert folder to application
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\calcmenuapi"
        #ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\Declaration"
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\Kiosk"
        ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppNameAfter\ws"
        pop-location
        Write-Host "APPLICATION FOLDERS HAVE BEEN CONVERTED" -foregroundcolor "green"
        #
   

    }

}
#
# Change Password of all Users
#
If ($DoChangePwd -eq "1")
{
    #UPDATE [EgswUser] SET Password=..encrypted $PasswordAdmin...... WHERE Code>0 

    $emailRecipient1="sandro@eg-software.com" #"support.noticket@eg-software.com"
    $emailRecipient2="sandro.grandjean@eg-software.com" #"sandro@eg-software.com"
    $emailRecipient3="" 
    $emailSubject = "This is a test"
    $emailBody = "Body"
    $emailAttachment = ""

   Write-Host "CHANGE OF PASSWORD FOR ALL USERS COMPLETED" -foregroundcolor "green"
   #Show Password
   Write-Host "Please take note of the password for all users: $PasswordAdmin" -ForegroundColor Cyan
}
#
# SENDS N EMAIL
#
If ($emailSubjet -ne "")
{
    $EmailPath=$PathPS+"Email.ps1"
    If ($emailAttachment.Length -eq 0)
    {
        If ($emailRecipient1.Length -gt 0)
        { & $EmailPath -eRecipient $emailRecipient1 -eSubject $emailSubject -eBody $emailBody  }
        If ($emailRecipient2.Length -gt 0)
        { & $EmailPath -eRecipient $emailRecipient2 -eSubject $emailSubject -eBody $emailBody  }
        If ($emailRecipient3.Length -gt 0)
        { & $EmailPath -eRecipient $emailRecipient3 -eSubject $emailSubject -eBody $emailBody  }
    }
    else
    {
        If ($emailRecipient1.Length -gt 0)
        { & $EmailPath -eRecipient $emailRecipient1 -eSubject $emailSubject -eBody $emailBody -eAttachment $emailAttachment }
        If ($emailRecipient2.Length -gt 0)
        { & $EmailPath -eRecipient $emailRecipient2 -eSubject $emailSubject -eBody $emailBody -eAttachment $emailAttachment }
        If ($emailRecipient3.Length -gt 0)
        { & $EmailPath -eRecipient $emailRecipient3 -eSubject $emailSubject -eBody $emailBody -eAttachment $emailAttachment }
    }
}
#
#
#
If ($UpdateWeb -gt "0") 
{
   #
    #
    #UPDATE
    #
    $PathcmwebCurrent="$Pathcmweb\Website\"+$ClientName
    Write-Host "*********************" -ForegroundColor Cyan
    Write-Host "UPDATING CALCMENU WEB" -ForegroundColor Cyan
    Write-Host "*********************" -ForegroundColor Cyan
    Write-Host "Path: $PathcmwebCurrent" -ForegroundColor Cyan
    
    #
    if (Test-Path $PathcmwebCurrent) 
    {
        Write-Host "Folder exists. Starting Backup." -ForegroundColor Yellow
        $Time=Get-Date
        $FileBackup=$PathBackupApp+$ClientName+'\'+$ClientName+'Web_'+$Time.ToString("yyyy-MM-dd")+'.rar'
        $PathToBackup="$Pathcmweb\Website\"+$ClientName
        #
        Try
        {
            set-location $PathToBackup
            $dir = [string](get-location)
            if ($dir -eq $PathToBackup)
            {
                Write-Host "Path being backup: "$PathToBackup 
                Write-Host "Backup placed here: "$FileBackup 
                #
                #& $PathWinRar a -r -x*\Calcmenuapi\logs\* -x*\Logs\* $PathToBackup $FileBackup  #-x"*Bin/EgswKey.dll"  -x"web.config.bak" 
                #
            }
        }
        Catch
        {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            $ErrorCount = $ErrorCount+1
            Write-Host $ErrorMessage -ForegroundColor Red
            Write-Host $FailedItem -ForegroundColor Red
            Write-Host "script interupted" -ForegroundColor Red
            Break
        }
        Finally
        {
            If ($ErrorCount -gt 0)
            {
                "An Error Occured." #| out-file D:\Data\Dropbox\EgsProjects\Amazon\Powershell\Updatecmweb.log -append
                Write-Host "Error Count:",$ErrorCount  -ForegroundColor Red
                Exit
            }
            else
            {
                Write-host "Backup done successfully" -ForegroundColor Green
                #
                Write-host "Updating CALCMENU Web by copying files" -ForegroundColor Yellow
                Write-host "Copy files from: "
                Write-host "to: $PathToBackup"
                #Copy-Item $PathcmwebMaster "$PathcmwebCurrent\CalcmenuWeb" -recurse -Force -Exclude web.config -Exclude web.config -Exclude web.config
                $excludefromcopy = @('web.config','kiosk.baseURL.min.js', 'cm.core.js'. 'Recipe.html')
                #source and dest without slash at the end
                Get-ChildItem $PathcmwebMaster -Recurse -Exclude $excludefromcopy | Copy-Item -Destination {Join-Path "$PathcmwebCurrent\CalcmenuWeb" $_.FullName.Substring($PathcmwebMaster.length)}
            }
        }
    }
    else
    {
        Write-Host "The folder does not exist. Application cannot be updated. Script interrupted." -ForegroundColor Red
    }
    #
}
###
###
### UPDATE KIOSK FOLDER ONLY OF APPLICATION
###
###
If ($UpdateFolderKiosk -eq "1") 
{
    #
    #
    #BREAK # !!!!!!!!!!!!! For Now !!!!!!!!!!!!!!!!!!!! 
    #
    #
    #CHECKING FIRST
    #
    $TempPath="$PathcmwebRoot\Keys\EgswKey$ClientName.dll"
    if (!(Test-Path $TempPath)) 
    {
        Write-Host "PRODUCT KEY IS MISSING" -foregroundcolor "red"
        Write-Host "SCRIPT INTERRUPTED" -foregroundcolor "red"
        Break
    }

    #
    #Is it on drive C, D, E?
    $CheckPath="C:\Website\"+$ClientName
    if (Test-Path $CheckPath)
    {
        $PathcmwebCurrent=$CheckPath
    }
    else
    {
        $CheckPath="D:\Website\"+$ClientName
        if (Test-Path $CheckPath)
        {
            $PathcmwebCurrent=$CheckPath
        }
        else
        {
            $CheckPath="E:\Website\"+$ClientName
            if (Test-Path $CheckPath)
            {
                $PathcmwebCurrent=$CheckPath
            }
            else
            {
                Write-host "The Folder does not exist. Nothing to update." -ForegroundColor Red
                break
            }        
        }
    }
    #
    #
    #BACKUP
    #
    #Backup Website if exists
    #$PathcmwebCurrent="$Pathcmweb\Website\"+$ClientName
    #$PathcmwebCurrent="C:\Website\BergamoLavoratoriQA"
    $PathcmwebCurrentRoot="$PathcmwebCurrent\CalcmenuWeb"
    $PathcmwebCurrent="$PathcmwebCurrent\CalcmenuWeb\Kiosk"
    Write-Host "Check folder: $PathcmwebCurrent" -ForegroundColor Yellow
    if (Test-Path $PathcmwebCurrent) 
    {
        "Folder exists. Start Backup"
        $Time=Get-Date
        $FileBackup=$PathBackupApp+$ClientName+'\'+$ClientName+'_Web_B4update_'+$Time.ToString("yyyy-MM-dd_HH-mm-ss")+'.rar'
        $PathToBackup=$PathcmwebCurrent
        #Backup Folder exist?
        $tmpPathX=$PathBackupApp+$ClientName
        If (!(Test-Path -Path $tmpPathX))
        {
            New-Item -Path $tmpPathX -type directory -Force
        }
        Try
        {
            #set-location $PathToBackup
            #$dir = [string](get-location)
            if (Test-Path $PathToBackup)
            {
                Write-Host "Path being backup: "$PathToBackup 
                Write-Host "Backup placed here: "$FileBackup 
                & $PathWinRar a -r -ep1 -idq -idc $FileBackup $PathToBackup #-x*\Calcmenuapi\logs\* -x*\Logs\*   #-x"*Bin/EgswKey.dll"  -x"web.config.bak" 
            }
            $FileBackup=$FileBackup+".rar"
            #& $AwsExeFile s3 cp   "$FileBackup" s3://egss3/Backup/$ClientName/  #| Out-Null 
            #break
            Write-Host "CALCMENU WEB SOLUTION WITH PICTURES HAS BEEN ZIPED AND MOVE TO S3" -ForegroundColor "green"
        }
        Catch
        {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            $ErrorCount = $ErrorCount+1
            Write-Host $ErrorMessage
            Write-Host $FailedItem
            "script interupted"
            Break
        }
        Finally
        {
            If ($ErrorCount -gt 0)
            {
                "An Error Occured." #| out-file D:\Data\Dropbox\EgsProjects\Amazon\Powershell\Updatecmweb.log -append
                Write-Host "Error Count:",$ErrorCount
                Exit
            }
            else
            {
                Write-host "Backup done successfully" -ForegroundColor Yellow
                
            }
        }
    }
    else
    {
        Write-host "The Folder does not exist. Nothing to update." -ForegroundColor Red
        break
    }
    #break
    #NEXTZ 
    #
    #Get the current version in EgsData.dll
    $PathForEgsDataDll="$PathcmwebCurrent\bin\EgsData.dll"
    $VersionDataDll=[System.Diagnostics.FileVersionInfo]::GetVersionInfo($PathForEgsDataDll).FileVersion
    #
    #$VersionDataDllParts=$VersionDataDll.split(".")
    #$VersionDataDllPartsCount=$VersionDataDllParts.Count 
    #$VersionDataDllParts[0] 
    #$VersionDataDllParts[1] 
    #$ConversionVersionTo=$VersionDataDllParts[2] 
    #$VersionDataDllParts[3] 
    $VersionDataDll
    $CurrentVersion=$VersionDataDll #"7.0.42496.33"
    #
    $Directory="$PathcmwebRoot\CalcmenuWeb\$DOVersionMain\$DOVersion\kiosk"  #"C:\EgsExchange\CalcmenuWeb\2015\Version Updates"
    if (Test-Path $Directory)
    {
        $VersFullName= "$Directory\*"
        Write-Host "Copy from: $VersFullName" -ForegroundColor Cyan
        Write-Host "Copy to: $PathcmwebCurrent" -ForegroundColor Cyan
        Copy-Item $VersFullName $PathcmwebCurrent -recurse -Force
        #
        <#
        Get-ChildItem $Directory |  Sort-Object Name | % {
            if ($_.Attributes -eq "Directory") {
                $VersName=$_.Name
                $VersFullName=$_.FullName
                if ($VersName -gt $CurrentVersion)
                {
                    Write-Host $VersName -ForegroundColor Red
                    $VersFullName= "$VersFullName" #\*"
                    Write-Host "Copy from: $VersFullName" -ForegroundColor Cyan
                    Write-Host "Copy to: $PathcmwebCurrent\" -ForegroundColor Cyan
                    #Copy-Item $VersFullName "$PathcmwebCurrent\CalcmenuWeb\" -recurse -Force
                    #
                    $ErrorCount=0
                    #Copy Files
                    Write-Host "Starts Copying files" -ForegroundColor Yellow
                    Try
                    {
                        Write-Host "Copying files" -ForegroundColor White  #(excluding files: web.config, kiosk.baseURL.min.js, cm.core.js, Recipe.html)" -ForegroundColor White
                        #$exclude = @('EgswKey.dll')
                        $source=$VersFullName
                        $dest="$PathcmwebCurrent"
                        #Get-ChildItem $source -Recurse -Exclude $exclude | Copy-Item -Destination {Join-Path $dest $_.FullName.Substring($source.length)} -Force #-WhatIf
                        Get-ChildItem $source -Recurse | Copy-Item -Destination {Join-Path $dest $_.FullName.Substring($source.length)} -Force #-WhatIf
                    }
                    Catch
                    {
                        $ErrorMessage = $_.Exception.Message
                        $FailedItem = $_.Exception.ItemName
                        $ErrorCount = $ErrorCount+1
                        Write-Host $ErrorMessage
                        Write-Host $FailedItem
                        Write-host "ERROR COPYING FILES - SCRIPT INTERRUPTED" -ForegroundColor Red
                        Break
                    }
                    Finally
                    {
                        $Time=Get-Date
                        Write-Host "WEBSITE FILES HAVE BEEN COPIED" -foregroundcolor "green"
                        #"This script to upload cmweb versions was executed on $Time" | out-file D:\Data\Dropbox\EgsProjects\Amazon\Powershell\Updatecmweb.log -append
                        If ($ErrorCount -gt 0)
                        {
                            "An Error Occured." #| out-file D:\Data\Dropbox\EgsProjects\Amazon\Powershell\Updatecmweb.log -append
                            Write-Host "Error Count:",$ErrorCount
                        }
                        else
                        {
                            write-host "UPDATE DONE SUCCESSFULLY" -ForegroundColor Green
                        }
                    }
                }
                else
                {
                    Write-Host "Skipped: $VersName" -ForegroundColor Yellow 
                }
        
            }
        }

        #>
        fctSetParametersInConfigsForKioskFolderNew $PathcmwebCurrentRoot $DataSourceIP $ClientName $UsernameForLogin $PasswordDb $UrlNameServer $IsMigros $DOVersion $DOVersionMain $CultureKiosk $HTTPS $UseDeclarationTool $LanguageCode $CultureFormatDate $CultureFormatDateNum $CultureFormatNumber
        #
        #SETUP LICENSE KEY
        #
        $PathClientLicenseKey="$PathcmwebRoot\Keys\EgswKey$ClientName.dll"
        if (Test-Path $PathClientLicenseKey) 
        {
            $LicenseKeyPath="$PathcmwebCurrent\bin\EgswKey.dll"
            Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
            Write-Host "PRODUCT KEY HAS BEEN SETUP" -foregroundcolor "green"
        }
        else
        {
            Write-Host "LICENSE KEY IS MISSING!!!" -foregroundcolor "red"
            Write-Host "SCRIPT INTERRUPTED" -foregroundcolor "red"
            Break
        }
            #
        Write-Host "CALCMENU WEB SOLUTION WITH PICTURES HAS BEEN ZIPED AND MOVE TO S3" -ForegroundColor "green"
    }
    else
    {
        Write-Host "Invalid path $Directory" -ForegroundColor Red
        break
    }
    #
    $Directory="$PathcmwebRoot\CalcmenuWeb\$DOVersionMain\$DOVersion\kiosk\DBScripts"  
    if (Test-Path $Directory)
    {
        $VersFullName= "$Directory\*"
        $PathcmwebCurrent="$PathcmwebCurrent\DBScripts"
        Write-Host "Copy scripts from: $VersFullName" -ForegroundColor Cyan
        Write-Host "Copy scripts to: $PathcmwebCurrent" -ForegroundColor Cyan
        Copy-Item $VersFullName $PathcmwebCurrent -recurse -Force
    }
    #
    #
    Write-host "########### EGS TOOL - UPDATE OF KIOSK COMPLETED ###########" -foregroundcolor Yellow
    Write-host "### Look for errors and report them to SG. " -foregroundcolor Yellow
    Write-host "### Thank you." -foregroundcolor Yellow
}
#
###
###
### UPDATE APPLICATION
###
###
If ($DoUpdate -eq "1") 
{
    #
    #CHECKING FIRST
    #
    $TempPath="$PathcmwebRoot\Keys\EgswKey$ClientName.dll"
    if (!(Test-Path $TempPath)) 
    {
        Write-Host "PRODUCT KEY IS MISSING" -foregroundcolor "red"
        Write-Host "SCRIPT INTERRUPTED" -foregroundcolor "red"
        Break
    }

    #
    #Is it on drive C, D, E?
    $CheckPath="C:\Website\"+$ClientName
    if (Test-Path $CheckPath)
    {
        $PathcmwebCurrent=$CheckPath
    }
    else
    {
        $CheckPath="D:\Website\"+$ClientName
        if (Test-Path $CheckPath)
        {
            $PathcmwebCurrent=$CheckPath
        }
        else
        {
            $CheckPath="E:\Website\"+$ClientName
            if (Test-Path $CheckPath)
            {
                $PathcmwebCurrent=$CheckPath
            }
            else
            {
                Write-host "The Folder does not exist. Nothing to update." -ForegroundColor Red
                break
            }        
        }
    }
    #
    #
    #BACKUP
    #
    #Backup Website if exists
    #$PathcmwebCurrent="$Pathcmweb\Website\"+$ClientName
    Write-Host "Check folder: $PathcmwebCurrent" -ForegroundColor Yellow
    if (Test-Path $PathcmwebCurrent) 
    {
        "Folder exists. Start Backup"
        $Time=Get-Date
        $FileBackup=$PathBackupApp+$ClientName+'\'+$ClientName+'_Web_B4update_'+$Time.ToString("yyyy-MM-dd_HH-mm-ss")+'.rar'
        $PathToBackup=$PathcmwebCurrent
        #Backup Folder exist?
        $tmpPathX=$PathBackupApp+$ClientName
        If (!(Test-Path -Path $tmpPathX))
        {
            New-Item -Path $tmpPathX -type directory -Force
        }
        Try
        {
            #set-location $PathToBackup
            #$dir = [string](get-location)
            if (Test-Path $PathToBackup)
            {
                Write-Host "Path being backup: "$PathToBackup 
                Write-Host "Backup placed here: "$FileBackup 
                & $PathWinRar a -r -ep1 -idq -idc $FileBackup $PathToBackup #-x*\Calcmenuapi\logs\* -x*\Logs\*   #-x"*Bin/EgswKey.dll"  -x"web.config.bak" 
            }
            $FileBackup=$FileBackup+".rar"
            #& $AwsExeFile s3 cp   "$FileBackup" s3://egss3/Backup/$ClientName/  #| Out-Null 
            #break
            Write-Host "CALCMENU WEB SOLUTION WITH PICTURES HAS BEEN ZIPED AND MOVE TO S3" -ForegroundColor "green"
        }
        Catch
        {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            $ErrorCount = $ErrorCount+1
            Write-Host $ErrorMessage
            Write-Host $FailedItem
            "script interupted"
            Break
        }
        Finally
        {
            If ($ErrorCount -gt 0)
            {
                "An Error Occured." #| out-file D:\Data\Dropbox\EgsProjects\Amazon\Powershell\Updatecmweb.log -append
                Write-Host "Error Count:",$ErrorCount
                Exit
            }
            else
            {
                Write-host "Backup done successfully" -ForegroundColor Yellow
                
            }
        }
    }
    else
    {
        Write-host "The Folder does not exist. Nothing to update." -ForegroundColor Red
        break
    }
    #break
    #NEXTZ 
    #
    #Get the current version in EgsData.dll
    $PathForEgsDataDll="$PathcmwebCurrent\CalcmenuWeb\bin\EgsData.dll"
    $VersionDataDll=[System.Diagnostics.FileVersionInfo]::GetVersionInfo($PathForEgsDataDll).FileVersion
    #
    #$VersionDataDllParts=$VersionDataDll.split(".")
    #$VersionDataDllPartsCount=$VersionDataDllParts.Count 
    #$VersionDataDllParts[0] 
    #$VersionDataDllParts[1] 
    #$ConversionVersionTo=$VersionDataDllParts[2] 
    #$VersionDataDllParts[3] 
    $VersionDataDll
    $CurrentVersion=$VersionDataDll #"7.0.42496.33"
    #
    $Directory="$PathcmwebRoot\CalcmenuWeb\2015\Version Updates"  #"C:\EgsExchange\CalcmenuWeb\2015\Version Updates"
    if (Test-Path $Directory)
    {
        Get-ChildItem $Directory |  Sort-Object Name | % {
            if ($_.Attributes -eq "Directory") {
                $VersName=$_.Name
                $VersFullName=$_.FullName
                if ($VersName -gt $CurrentVersion)
                {
                    Write-Host $VersName -ForegroundColor Red
                    $VersFullName= "$VersFullName" #\*"
                    Write-Host "Copy from: $VersFullName" -ForegroundColor Cyan
                    Write-Host "Copy to: $PathcmwebCurrent\CalcmenuWeb\" -ForegroundColor Cyan
                    #Copy-Item $VersFullName "$PathcmwebCurrent\CalcmenuWeb\" -recurse -Force
                    #
                    $ErrorCount=0
                    #Copy Files
                    Write-Host "Starts Copying files" -ForegroundColor Yellow
                    Try
                    {
                        Write-Host "Copying files -ForegroundColor White " #(excluding files: web.config, kiosk.baseURL.min.js, cm.core.js, Recipe.html)" -ForegroundColor White
                        #$exclude = @('EgswKey.dll')
                        $source=$VersFullName
                        $dest="$PathcmwebCurrent\CalcmenuWeb"
                        #Get-ChildItem $source -Recurse -Exclude $exclude | Copy-Item -Destination {Join-Path $dest $_.FullName.Substring($source.length)} -Force #-WhatIf
                        Get-ChildItem $source -Recurse | Copy-Item -Destination {Join-Path $dest $_.FullName.Substring($source.length)} -Force #-WhatIf
                    }
                    Catch
                    {
                        $ErrorMessage = $_.Exception.Message
                        $FailedItem = $_.Exception.ItemName
                        $ErrorCount = $ErrorCount+1
                        Write-Host $ErrorMessage
                        Write-Host $FailedItem
                        Write-host "ERROR COPYING FILES - SCRIPT INTERRUPTED" -ForegroundColor Red
                        Break
                    }
                    Finally
                    {
                        $Time=Get-Date
                        Write-Host "WEBSITE FILES HAVE BEEN COPIED" -foregroundcolor "green"
                        #"This script to upload cmweb versions was executed on $Time" | out-file D:\Data\Dropbox\EgsProjects\Amazon\Powershell\Updatecmweb.log -append
                        If ($ErrorCount -gt 0)
                        {
                            "An Error Occured." #| out-file D:\Data\Dropbox\EgsProjects\Amazon\Powershell\Updatecmweb.log -append
                            Write-Host "Error Count:",$ErrorCount
                        }
                        else
                        {
                            write-host "UPDATE DONE SUCCESSFULLY" -ForegroundColor Green
                        }
                    }
                }
                else
                {
                    Write-Host "Skipped: $VersName" -ForegroundColor Yellow 
                }
        
            }
        }
        #
        #SET THE RIGHT CALCMENU WEB LOGO
        #2022-11-14
        $CMLogoFileName=""
        #[LogoPngName]
        if ($DemoAccount -eq "1") {
            $CMLogoFileName="cmweb-demo.png"
            Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
        }
        elseif (($QAAccount -eq "1") -or ($Upgrade -eq "1")) {
            $CMLogoFileName="cmweb-qa.png"
            Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
        }
        elseif ($BetaAccount -eq "1") {
            $CMLogoFileName="cmweb-beta.png"
            Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
        }
        else
        {
            $EditionLower=$Edition.ToLower()
            if ($EditionLower -eq "") {
                $CMLogoFileName="cmweb.png"
                #Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
            }
            else
            {
                $CMLogoFileName="cmweb-$EditionLower.png"
                #Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
            }
        }
        #2022-11-14
        #
        fctSetParametersInConfigsNew $PathcmwebCurrent $DataSourceIP $ClientName $UsernameForLogin $PasswordDb $UrlNameServer $IsMigros $DOVersion $DOVersionMain $CultureKiosk $HTTPS $UseDeclarationTool $LanguageCode $CultureFormatDate $CultureFormatDateNum $CultureFormatNumber $CMLogoFileName #2022-11-14
        #
        #SETUP LICENSE KEY
        #
        $PathClientLicenseKey="$PathcmwebRoot\Keys\EgswKey$ClientName.dll"
        if (Test-Path $PathClientLicenseKey) 
        {
            $LicenseKeyPath="$PathcmwebCurrent\CalcmenuWeb\bin\EgswKey.dll"
            Copy-Item $PathClientLicenseKey $LicenseKeyPath -Force
            Write-Host "PRODUCT KEY HAS BEEN SETUP" -foregroundcolor "green"
        }
        else
        {
            Write-Host "LICENSE KEY IS MISSING!!!" -foregroundcolor "red"
            Write-Host "SCRIPT INTERRUPTED" -foregroundcolor "red"
            Break
        }
            #
        Write-Host "CALCMENU WEB SOLUTION WITH PICTURES HAS BEEN ZIPED AND MOVE TO S3" -ForegroundColor "green"
    }
    else
    {
        Write-Host "Invalid path $Directory" -ForegroundColor Red
        break
    }
    break

    #
    break
    #
    #
    #SET THE RIGHT CALCMENU WEB LOGO
    #
    $CMLogoFileName=""
    #[LogoPngName]
    if ($DemoAccount -eq "1") {
        $CMLogoFileName="cmweb-demo.png"
        Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
    }
    elseif (($QAAccount -eq "1") -or ($Upgrade -eq "1")) {
        $CMLogoFileName="cmweb-qa.png"
        Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
    }
    elseif ($BetaAccount -eq "1") {
        $CMLogoFileName="cmweb-beta.png"
        Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
    }
    else
    {
        $EditionLower=$Edition.ToLower()
        if ($EditionLower -eq "") {
            $CMLogoFileName="cmweb.png"
            #Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
        }
        else
        {
            $CMLogoFileName="cmweb-$EditionLower.png"
            #Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
        }
    }
    if ($CMLogoFileName -ne "") #-and (Test-Path ))
    {
        #RENAME AND REPLACE LOGO OF CALCMENU WEB
        #Delete logo
        Remove-Item -Path "$PathcmwebCurrent\CalcmenuWeb\Images\Logo\CM-Web-150x70.png" -Force -Recurse #-WhatIf
        
        #Copy right logo to that name
        Copy-Item "$PathcmwebCurrent\CalcmenuWeb\Images\Logo\$CMLogoFileName" "$PathcmwebCurrent\CalcmenuWeb\Images\Logo\CM-Web-150x70.png" -recurse -Force
        If (Test-Path "$PathcmwebCurrent\CalcmenuWeb\Images\Logo\$CMLogoFileName")
        {
            Write-Host "LOGO HAS BEEN CHANGED TO: $PathcmwebCurrent\CalcmenuWeb\Images\Logo\$CMLogoFileName" -foregroundcolor "green"
        }
        else
        {
            Write-Host "PROBLEM WITH CHANGE OF LOGO: $PathcmwebCurrent\CalcmenuWeb\Images\Logo\$CMLogoFileName" -foregroundcolor "red"
        }
    }
    #
    #
    #
    Write-host "########### EGS TOOL - UPDATE COMPLETED ###########" -foregroundcolor Yellow
    Write-host "### Look for errors and report them to SG. " -foregroundcolor Yellow
    Write-host "### Thank you." -foregroundcolor Yellow
}
#
#
#
#
#UPDATE OF THE CLIENT'S LOGO 
#(Ex: Logo_ClientName.jpg -> for all sites)
#(Ex: Logo_ClientName_1.jpg -> for site 1)
#
if ($DoUpdateClientLogo -eq "1") 
{
    $logook="0"
    #$PathcmwebCurrent="\\$ComputerNameServerAppInternal\EgsExchange\Logos"
    $PathcmwebCurrent="$PathcmwebRoot\Logos"
    if (!(Test-Path $PathcmwebCurrent)) 
    {
        Write-Host "The Path of the application is wrong." -ForegroundColor Red
        break
    }
    $LogoFileNamePng="Logo_$ClientName.png"
    $LogoFileNameJpg="Logo_$ClientName.jpg"
    $ProductLogoPathSource="$PathcmwebRoot\Logos\$LogoFileNamePng"
    if (!(Test-Path $ProductLogoPathSource)) 
    {
        Write-Host "The logo does not exist as PNG: $ProductKeyPathSource" -ForegroundColor Cyan
        $ProductLogoPathSource="$PathcmwebRoot\Logos\$LogoFileNameJpg"
        if (!(Test-Path $ProductLogoPathSource)) 
        {
            Write-Host "The logo does not exist as JPG: $ProductKeyPathSource" -ForegroundColor Cyan
            Write-Host "No Valid Logo Found - No Logo copied/updated" -ForegroundColor Red
        }
        else 
        { 
            $LogoFileName=$LogoFileNameJpg 
            $logook="1"
        }
    }
    else 
    { 
        $LogoFileName=$LogoFileNamePng 
        $logook="1"
    }
    #
    If ($logook -eq "1")
    {
        $LogoPathDestination="\\$ComputerNameServerAppInternal\Website$PathcmwebNoSemicolon\$ClientName\CalcmenuWeb\Logo\$LogoFileName"
        #If (($ServerToDeployToApp -eq "RB") -and ($ServerToDeployToSql -eq "Chronos"))
        #{
        #    $LogoPathDestination="\\$ComputerNameServerAppExternal\Website$PathcmwebNoSemicolon\$ClientName\CalcmenuWeb\Logo\$LogoFileName"
        #}
        if (!(Test-Path $LogoPathDestination)) 
        {
            Write-Host "The logo does not exist at the destination: $LogoPathDestination" -ForegroundColor Cyan
            #ok to continue
        }
        #
        Copy-Item -Path $ProductLogoPathSource -Destination $LogoPathDestination -Force 
        Write-Host "THE LOGO HAS BEEN COPIED: $LogoPathDestination" -ForegroundColor DarkYellow
        #
        $MySQLQuery = "UPDATE EgswConfig SET String = 'logo/$LogoFileName' WHERE Numero = 20026 AND CodeGroup = -3"
        Invoke-Sqlcmd -Query $MySQLQuery -Database "CalcmenuWeb_$ClientName" -ServerInstance $ComputerNameServerSql -querytimeout (65000) -Encrypt Mandatory -TrustServerCertificate
        Write-Host "CLIENTS LOGOS HAVE BEEN CHANGED TO $LogoFileName" -ForegroundColor "green"
        #
    }
}
#
#
#
#
#
#
#UPDATE OF THE CALCMENU WEB LOGO
#
if ($DoUpdateCmWebLogo -eq "1") 
{
    #SET THE RIGHT CALCMENU WEB LOGO
    #
    $CMLogoFileName=""
    #[LogoPngName]
    if ($DemoAccount -eq "1") {
        $CMLogoFileName="cmweb-demo.png"
        Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
    }
    elseif (($QAAccount -eq "1") -or ($Upgrade -eq "1")) {
        $CMLogoFileName="cmweb-qa.png"
        Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
    }
    elseif ($BetaAccount -eq "1") {
        $CMLogoFileName="cmweb-beta.png"
        Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
    }
    else
    {
        $EditionLower=$Edition.ToLower()
        if ($EditionLower -eq "") {
            $CMLogoFileName="cmweb.png"
            #Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
        }
        else
        {
            $CMLogoFileName="cmweb-$EditionLower.png"
            #Write-Host "LOGO HAS BEEN CHANGED TO: $CMLogoFileName" -foregroundcolor "green"
        }
    }
    #
    $PathCmWebLogo="$Pathcmweb\Website\"+$ClientName
    #
    if ($CMLogoFileName -ne "") #-and (Test-Path ))
    {
        #RENAME AND REPLACE LOGO OF CALCMENU WEB
        #Delete logo
        #2014
        $PathLogo2014="$PathCmWebLogo\CalcmenuWeb\Images\Logo\CM-Web-150x70.png"
        If (Test-Path $PathLogo2014) { Remove-Item -Path $PathLogo2014 -Force -Recurse }
        #2015
        $PathLogo2015="$PathCmWebLogo\CalcmenuWeb\Images\Logo\cmweb_header-left.png"
        If (Test-Path $PathLogo2015) { Remove-Item -Path $PathLogo2015 -Force -Recurse }

        #Copy right logo to that name
        $CopyLogoOK="0"
        #2014
        Copy-Item "$PathCmWebLogo\CalcmenuWeb\Images\Logo\$CMLogoFileName" $PathLogo2014 -recurse -Force
        If (Test-Path $PathLogo2014)
        {
            Write-Host "LOGO (2014) HAS BEEN CHANGED TO: $PathCmWebLogo\CalcmenuWeb\Images\Logo\$CMLogoFileName" -foregroundcolor "green"
            $CopyLogoOK="1"
        }
        #2015
        Copy-Item "$PathCmWebLogo\CalcmenuWeb\Images\Logo\$CMLogoFileName" $PathLogo2015 -recurse -Force
        If (Test-Path $PathLogo2015)
        {
            Write-Host "LOGO (2015) HAS BEEN CHANGED TO: $PathCmWebLogo\CalcmenuWeb\Images\Logo\$CMLogoFileName" -foregroundcolor "green"
            $CopyLogoOK="1"
        }
        If ($CopyLogoOK -eq "0")
        {
            Write-Host "PROBLEM WITH CHANGE OF LOGO: $PathCmWebLogo\CalcmenuWeb\Images\Logo\$CMLogoFileName" -foregroundcolor "red"
        }
    }
    #
}
#
#
#
#
#
#
#UPDATE THE PRODUCT KEY 
#
if ($DoUpdateKey -eq "1") 
{
    $Pathcmweb="C:"
    $PathCmWebForKey="$Pathcmweb\Website\$ClientName\CalcmenuWeb"
    if (!(Test-Path $PathCmWebForKey)) 
    {
        $Pathcmweb="D:"
        $PathCmWebForKey="$Pathcmweb\Website\$ClientName\CalcmenuWeb"
        if (!(Test-Path $PathCmWebForKey)) 
        {
            $Pathcmweb="E:"
            $PathCmWebForKey="$Pathcmweb\Website\$ClientName\CalcmenuWeb"
            if (!(Test-Path $PathCmWebForKey)) 
            {
                Write-Host "The Path of the application cannot be found." -ForegroundColor Red
                break
            }
        }
    }
    $ProductKeyPathSource="$PathcmwebRoot\Keys\EgswKey$ClientName.dll"
    if (!(Test-Path $ProductKeyPathSource)) 
    {
        Write-Host "The key does not exist in $ProductKeyPathSource folder." -ForegroundColor Red
        break
    }
    #33.11.00
    #33.10.00 $BakTS=$((Get-Date).ToString("_yyyyMMdd_HHmmss")) #33.08.00
    $KeyPathDestination="$Pathcmweb\Website\$ClientName\CalcmenuWeb\Bin\EgswKey.dll"
    $KeyPathKioskDestination="$Pathcmweb\Website\$ClientName\CalcmenuWeb\Kiosk\Bin\EgswKey.dll"
    $KeyPathMenuPlanviewDestination="$Pathcmweb\Website\$ClientName\CalcmenuWeb\menuplanview\Bin\EgswKey.dll"
    $KeyPathRecipeExportDestination="$Pathcmweb\Website\$ClientName\CalcmenuWeb\RecipeExport\Bin\EgswKey.dll"
    $KeyPathDataExportDestination="$Pathcmweb\Website\$ClientName\CalcmenuWeb\DataExport\Bin\EgswKey.dll"
    $KeyPathDataAnalyticsDestination="$Pathcmweb\Website\$ClientName\CalcmenuWeb\DataAnalytics\Bin\EgswKey.dll"
    
    $KeyPathRecipeImportDestination="$Pathcmweb\Website\$ClientName\CalcmenuWeb\Recipeimport\Bin\EgswKey.dll"
    $KeyPathInventorykDestination="$Pathcmweb\Website\$ClientName\CalcmenuWeb\inventory\Bin\EgswKey.dll"
    #33.10.00 $KeyPathDestinationBak="$Pathcmweb\Website\$ClientName\CalcmenuWeb\Bin\EgswKey.dll$BakTS" #33.08.00
    #33.10.00 $KeyPathKioskDestinationBak="$Pathcmweb\Website\$ClientName\CalcmenuWeb\Kiosk\Bin\EgswKey.dll$BakTS" #33.08.00
    if (!(Test-Path $KeyPathDestination)) 
    {
        Write-Host "The key does not exist at the destination: $KeyPathDestination" -ForegroundColor Cyan
        #ok to continue
    }
    if (!(Test-Path $KeyPathKioskDestination)) 
    {
        Write-Host "The key does not exist at the KIOSK destination: $KeyPathKioskDestination" -ForegroundColor Cyan
        #ok to continue
    }
    if (!(Test-Path $KeyPathMenuPlanviewDestination)) 
    {
        Write-Host "The key does not exist at the MenuPlanView destination: $KeyPathMenuPlanviewDestination" -ForegroundColor Cyan
        #ok to continue
    }
    if (!(Test-Path $KeyPathRecipeExportDestination)) 
    {
        Write-Host "The key does not exist at the RecipeExport destination: $KeyPathRecipeExportDestination" -ForegroundColor Cyan
        #ok to continue
    }
    if (!(Test-Path $KeyPathDataExportDestination)) 
    {
        Write-Host "The key does not exist at the DataExport destination: $KeyPathDataExportDestination" -ForegroundColor Cyan
        #ok to continue
    }
    if (!(Test-Path $KeyPathDataAnalyticsDestination)) 
    {
        Write-Host "The key does not exist at the DataAnalytics destination: $KeyPathDataAnalyticsDestination" -ForegroundColor Cyan
        #ok to continue
    }
    if (!(Test-Path $KeyPathRecipeImportDestination)) 
    {
        Write-Host "The key does not exist at the RecipeImport destination: $KeyPathRecipeImportDestination" -ForegroundColor Cyan
        #ok to continue
    }
    if (!(Test-Path $KeyPathInventorykDestination)) 
    {
        Write-Host "The key does not exist at the Inventory destination: $KeyPathInventorykDestination" -ForegroundColor Cyan
        #ok to continue
    }
    #
    $iisAppPoolName = "CalcmenuWeb_$ClientName"
    $iisAppName = "CalcmenuWeb_$ClientName"
    #
    #STOP WEBSITE
    Stop-WebSite -Name "$iisAppName"
    Write-host "WEBSITE [$iisAppName] HAS BEEN STOPPED" -foregroundcolor "green"
    #
    Copy-Item -Path $ProductKeyPathSource -Destination $KeyPathDestination -Force 
    Write-Host "THE KEY HAS BEEN COPIED: $KeyPathDestination" -ForegroundColor DarkYellow
    #
    Copy-Item -Path $ProductKeyPathSource -Destination $KeyPathKioskDestination -Force 
    Write-Host "THE KEY HAS BEEN COPIED: $KeyPathKioskDestination" -ForegroundColor DarkYellow
    #
    Copy-Item -Path $ProductKeyPathSource -Destination $KeyPathMenuPlanviewDestination -Force 
    Write-Host "THE KEY HAS BEEN COPIED: $KeyPathMenuPlanviewDestination" -ForegroundColor DarkYellow
    #
    Copy-Item -Path $ProductKeyPathSource -Destination $KeyPathRecipeExportDestination -Force 
    Write-Host "THE KEY HAS BEEN COPIED: $KeyPathRecipeExportDestination" -ForegroundColor DarkYellow
    #
    Copy-Item -Path $ProductKeyPathSource -Destination $KeyPathDataExportDestination -Force 
    Write-Host "THE KEY HAS BEEN COPIED: $KeyPathDataExportDestination" -ForegroundColor DarkYellow
    #
    Copy-Item -Path $ProductKeyPathSource -Destination $KeyPathDataAnalyticsDestination -Force 
    Write-Host "THE KEY HAS BEEN COPIED: $KeyPathDataAnalyticsDestination" -ForegroundColor DarkYellow
    #
    Copy-Item -Path $ProductKeyPathSource -Destination $KeyPathRecipeImportDestination -Force 
    Write-Host "THE KEY HAS BEEN COPIED: $KeyPathRecipeImportDestination" -ForegroundColor DarkYellow
    #
    Copy-Item -Path $ProductKeyPathSource -Destination $KeyPathInventorykDestination -Force 
    Write-Host "THE KEY HAS BEEN COPIED: $KeyPathInventorykDestination" -ForegroundColor DarkYellow
    #
    Start-WebSite -Name "$iisAppName"
    Write-host "WEBSITE [$iisAppName] HAS BEEN RESTARTED" -foregroundcolor "green"
 }
#
#
#
#
# CHANGE FROM HTTP TO HTTPS 
#
if ($DoHttpToHttps -eq "1") 
{
    "##########################"
    $ComputerNameServerAppInternalHttps 
    $Pathcmweb 
    $ClientName 
    $UrlNameServer
    "##########################"
    BindWebsite  $ComputerNameServerAppInternalHttps $Pathcmweb $ClientName $UrlNameServer
    WebConfigRewrite $Pathcmweb $ClientName
    $PathcmwebCurrent="$Pathcmweb\Website\"+$ClientName
    fctChangeHttpToHttpsInConfigsNew $PathcmwebCurrent $ClientName $UrlNameServer 
    Write-host "WEBSITE for [$ClientName] HAS BEEN UPGRADED FROM HTTP TO HTTPS" -foregroundcolor "green"
    #
    $iisAppName = "CalcmenuWeb_$ClientName"
    #Convert folder to application
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\calcmenuapi"
    #Retired 27.01.2017 ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\Declaration"
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\Kiosk"
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\ws"
    #new 30.19
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\ReportXML"
    #new 07.02.2019
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\emenu"
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\emenuplan"
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\wsapi"
    #new 6.5.2020
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\AdvancedShoppingList"
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\MenuPlanView"
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\RecipeImport"
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\RecipeExport"
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\DataExport"
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\DataAnalytics"
    
    #new 7.5.2020
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\shoppinglistWS"
    #new 19.2.2021
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\inventory"
    #new 23.4.2021
    ConvertTo-WebApplication -PSPath "IIS:\Sites\$iisAppName\erecipe"
    #new 30.19
    Write-Host "APPLICATION FOLDERS HAVE BEEN CONVERTED" -foregroundcolor "green"
    #

 }
#
#
#
#
#Script to remove/hide menu
#DELETE EgswRolesRights WHERE Modules = 16
#DELETE EgswRolesRightsTemplate WHERE Modules = 16
#
#
#
#
#Configure IIS for files that already exists on the disk (transfered from another server or disk)
#
If ($DoIIS -eq "1")
{
    #
    if (Test-Path "C:\Website\$ClientName\CalcmenuWeb") {$Pathcmweb="C:"}
    else
    {
        if (Test-Path "D:\Website\$ClientName\CalcmenuWeb") {$Pathcmweb="D:"}
        else
        {
            if (Test-Path "E:\Website\$ClientName\CalcmenuWeb") {$Pathcmweb="E:"}
            else
            { 
                Write-Host "FOLDER ?:\Website\$ClientName\CalcmenuWeb CANNOT BE FOUND" -foregroundcolor red
                BREAK 
            }
        }
    }
    #
    $FolderPath="$Pathcmweb\Website\$ClientName\CalcmenuWeb"
    #
    #SET FOLDER PERMISSIONS
    #
    $acl = Get-Acl $FolderPath 
    $colRights = [System.Security.AccessControl.FileSystemRights]"Read,Modify,ExecuteFile,ListDirectory" 
    $permission = "IIS_IUSRS",$colRights,"ContainerInherit,ObjectInherit”,”None”,”Allow” 
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission  
    $acl.AddAccessRule($accessRule) 
    Set-Acl $FolderPath $Acl
    Write-Host "FOLDER PERMISSION HAS BEEN SET" -foregroundcolor "green"
    #
    #CONFIGURE IIS
    #
    if ($HTTPS -eq "1") 
    {
        "##########################"
        $ComputerNameServerAppInternalHttps 
        $Pathcmweb 
        $ClientName 
        $UrlNameServer
        "##########################"
        push-location
        BindWebsite  $ComputerNameServerAppInternalHttps $Pathcmweb $ClientName $UrlNameServer
        WebConfigRewrite $Pathcmweb $ClientName
        $iisAppName = "CalcmenuWeb_$ClientName"
        pop-location
    }
    else
    {
        push-location
        Import-Module WebAdministration
        #$iisAppPoolName = $UrlName+".calcmenuweb.com"
        $iisAppPoolName = "CalcmenuWeb_$ClientName"
        $iisAppPoolDotNetVersion = "v4.0"
        #$iisAppName = $UrlName+".calcmenuweb.com"
        $iisAppName = "CalcmenuWeb_$ClientName"
        $iisAppNameBinding = $UrlNameServer+".calcmenuweb.com"
        $directoryPath = "$Pathcmweb\Website\$ClientName\CalcmenuWeb"
        #navigate to the app pools root
        cd IIS:\AppPools\
        #check if the app pool exists
        if (!(Test-Path $iisAppPoolName -pathType container))
        {
            #create the app pool
            $appPool = New-Item $iisAppPoolName
            $appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value $iisAppPoolDotNetVersion
        }
        #navigate to the sites root
        cd IIS:\Sites\
        #check if the site exists
        if (Test-Path $iisAppName -pathType container)
        {
            #do nothing
        }
        else
        {
            #create the site 
            $AllUnassigned="*"
            $iisApp = New-Item $iisAppName -bindings @{protocol="http";bindingInformation="$($AllUnassigned):80:" + $iisAppNameBinding} -physicalPath $directoryPath
            $iisApp | Set-ItemProperty -Name "applicationPool" -Value $iisAppPoolName
            Write-Host "WEBSITE AND APPLICATION POOL HAS BEEN SETUP" -foregroundcolor "green"
        }
    }
    pop-location
    #
    #FOR MIGROS ONLY
    <#
         <remove fileExtension=".tpl" />
      <mimeMap fileExtension=".tpl" mimeType="text/html" />
      <remove fileExtension=".woff" />
      <mimeMap fileExtension=".woff" mimeType="text/woff" />
      <remove fileExtension=".woff2" />
      <mimeMap fileExtension=".woff2" mimeType="text/woff2" />
     <remove fileExtension=".otf" />
     <mimeMap fileExtension=".otf" mimeType="font/otf" />
    #>
    #
    #CONFIGURE THE DOMAIN NAME #SG
    if ($HTTPS -eq "1") 
    {
        $IpForDomainName=$ComputerNameServerAppExternalHttps
        $httpType="https:"
    }
    else
    {
        $IpForDomainName=$ComputerNameServerAppExternal
        $httpType="http:"
    }
    if ($Silent -eq "0")
    {
        $choice = ""
        while ($choice -notmatch "[y|n]")
        {
            $choice = read-host "Do you wish to setup the domain name $httpType//$UrlName.calcmenuweb.com with IP address: $IpForDomainName ? (Y/N)"
        }
        if ($choice -eq "y")
        {
            New-R53ResourceRecordSet -ProfileName "egs.sandro" -Value $IpForDomainName -Type "A" -RecordName $UrlName -TTL 3600 -ZoneName "calcmenuweb.com"   
            Write-host "Domain Name $UrlName.calcmenuweb.com has been setup on $IpForDomainName" -foregroundcolor Green
        }
    }
    else
    {
        if ($AutoCreateDomain -eq "1")
        {
            New-R53ResourceRecordSet -ProfileName "egs.sandro" -Value $IpForDomainName -Type "A" -RecordName $UrlName -TTL 3600 -ZoneName "calcmenuweb.com"   
            Write-host "Domain Name $UrlName.calcmenuweb.com has been setup on $IpForDomainName" -foregroundcolor Green
        }
    }
    #
    #
    #
    Write-host "########### EGS TOOL - WEB IIS SETUP COMPLETED ###########" -foregroundcolor Yellow
    Write-host "### Look for errors and report them to SG. " -foregroundcolor Yellow
    Write-host "### Thank you." -foregroundcolor Yellow
}
}
<#
$ProjectName="Cretelongue"
 fctToolLatest -ProjectNameToDeploy $ProjectName `
 -DoApp "0"  -DoApp2 "0" `
 -DOSql1 "0"  -DOSql2 "0" -DOSql3 "0" -DOSql4 "0" -DOSql9 "0" `
 -DOPack "0" `
 -DoUpdate "0" `
 -DoRemoveWeb "0" `
 -DoRemoveDb "0" `
 -DoChangeUrl "0" `
 -DOVersion "v1" `
 -DOVersionMain "2015" `
 -ConversionVersionToForcedStr "0" `
 -UrlOrigin "" `
 -UrlReplacement "" `
 -DoUpdateClientLogo "0" `
 -DoUpdateCmWebLogo "0" `
 -DoUpdateKey "1" `
 -DoCopyWeb "0" `
 -DoCopyWebProjectNameSource "" `
 -DoHttpToHttps "0" `
 -Silent "0" `
 -AutoCreateDomain "0" `
 -AutoDeployKey "0"

#>

<#
$ProjectName="MSFIDemo"
fctToolLatest -ProjectNameToDeploy $ProjectName `
 -DoApp "0"  -DoApp2 "0" `
 -DOSql1 "0"  -DOSql2 "0" -DOSql3 "0" -DOSql4 "0" -DOSql9 "0" `
 -DOPack "0" `
 -DoUpdate "0" `
 -DoRemoveWeb "0" `
 -DoRemoveDb "0" `
 -DoChangeUrl "0" `
 -DOVersion "v1" `
 -DOVersionMain "2015" `
 -ConversionVersionToForcedStr "0" `
 -UrlOrigin "" `
 -UrlReplacement "" `
 -DoUpdateClientLogo "1" `
 -DoUpdateCmWebLogo "0" `
 -DoUpdateKey "0" `
 -DoCopyWeb "0" `
 -DoCopyWebProjectNameSource "" `
 -DoHttpToHttps "0" `
 -Silent "0" `
 -AutoCreateDomain "0" `
 -AutoDeployKey "0"

 #>