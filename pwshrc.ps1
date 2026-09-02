<# 
	@file: pwshrc.ps1

	@brief: Entry point for a PowerShell profile script that is loaded at start time.

	@details:
	To use this script,
	- copy it to the default profile location for the OS,
	- or create a symlink to this file from the default profile location.

	@note:
	This script will load external modules.

	@author: madpang

	@date: [created: 2021-06-08, updated: 2026-09-02]
#>

# === Get the execution path

$_entry_point = Get-ItemProperty $MyInvocation.MyCommand.Path
if ($null -ne $_entry_point.Target)
{
	# If it is called via a symbolic link
	$_script_dir = Split-Path $_entry_point.Target -Parent
} else {
	# If it is called directly
	$_script_dir = $_entry_point.Directory.FullName
}

# === Load external modules

# --- Common setup for all platforms
. ([System.IO.Path]::Combine(
	$_script_dir,
	'conf',
	'common-pwsh-conf.ps1'
))

# === Clean up

# Remove temporary variables that starts with '_'
Remove-Variable -Name "_*"
