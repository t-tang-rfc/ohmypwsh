<#
	@brief: macOS-specific PowerShell configuration

	@detaisl:
	- Environment configuration
	- Alias configuration

	@author:
	- Tianhan Tang (tianhantang.pd@gmail.com)

	@date:
	- created on 2021-08-09
	- updated on 2024-11-18
#>

# /// Environment setup
# ////////////////////////////////////////////////////////////

# Set environment variables

Set-Item -Path "env:GPG_TTY" -Value "$(tty)" # configure GPG_TTY such that gpg-agent can find the tty for passphrase input. @note, use `Get-Command -Name tty` to check whether the command is available

# Define functions

# Mount shared workspace
Function Mount-WKSP {
	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $true, Position = 0)][string]$Name,
		[Parameter()][string]$IP = '',
		[Parameter()][string]$Vol = '',
		[Parameter()][string]$MPt = ''
	)
	process {
		$wk_name = $Name.Replace(':', '')
		if ($Global:custom_workspace_info.Contains($wk_name)) {
			if (
				([Environment]::MachineName -in $Global:custom_workspace_info.$wk_name.Allow) -or 
				('All' -eq $Global:custom_workspace_info.$wk_name.Allow)
			) {
				if (
					($Global:custom_workspace_info.Wi.AccPt -eq $Global:custom_workspace_info.$wk_name.AccPt) -or 
					($Global:custom_workspace_info.$wk_name.Host -eq 'iCloud')
				) {
					$Global:custom_error_status = $true
					$msg = "No need to mount the specified workpace $($wk_name)!"
					# report status
					Report-Status $null $msg
				} else {
					$mount_point =  [IO.Path]::Combine(
						$HOME,
						(('' -eq $MPt) ? $Global:custom_workspace_info.$wk_name.AccPt : $MPt)
					)
					if (-not (Test-Path $mount_point)) {
						New-Item $mount_point -ItemType Directory 1>$null
					} else {
						$Global:custom_error_status = $false
						$err = "Mount point already exist! please take care!"
						# report status
						Report-Status $err $null
						return
					}
					$mount_target = 'smb://' + $Global:custom_workspace_info.$wk_name.User + ':' +
						$Global:custom_workspace_info.$wk_name.Pswd + '@' +
						(('' -eq $IP) ? $Global:custom_workspace_info.$wk_name.IP : $IP) + '/' +
						[System.Web.HttpUtility]::UrlEncode(
							('' -eq $Vol) ? $Global:custom_workspace_info.$wk_name.Volume : $Vol
						)
					mount_smbfs $mount_target $mount_point

					$Global:custom_error_status = $?
					# If not successful, delete the dir
					if (-not $Global:custom_error_status) {
						Remove-Item $mount_point
					}
				}
			} else {
				$Global:custom_error_status = $false
				$err = "No authentification for the specified workpace $($wk_name)!"
				# report status
				Report-Status $err $null				
			}
		} else {
			$Global:custom_error_status = $false
			$err = "The specified workpace $($wk_name) is NOT available!"
			# report status
			Report-Status $err $null
		}
	}
}

# Unmount shared workspace
Function Remove-WKSP {
	param(
		[Parameter(Mandatory = $True, ValueFromPipeline = $true, Position = 0)][string]$Name,
		[Parameter()][string]$MPt = ''
	)
	process {
		$wk_name = $Name.Replace(':', '')
		if (
			($null -eq $Global:custom_workspace_info.$wk_name) -or 
			($Global:custom_workspace_info.Wi.AccPt -eq $Global:custom_workspace_info.$wk_name.AccPt)
		) {
			$Global:custom_error_status = $false
			$err = "The specified workpace $($wk_name) is NOT valid!"
			# report status
			Report-Status $err $null
		} else {
			$mount_point = [IO.Path]::Combine(
				$HOME,
				(('' -eq $MPt) ? $Global:custom_workspace_info.$wk_name.AccPt : $MPt)
			)
			if (-not (Test-Path $mount_point)) {
				$Global:custom_error_status = $false
				$err = "The specified workpace $($wk_name) is NOT mounted!"
				# report status
				Report-Status $err $null			
			} else {
				umount $mount_point 2>$null
				if (-not $?) {
					# Fall-back
					diskutil unmount force $mount_point	
				}
				$Global:custom_error_status = $?
				if (-not (Test-Path ([IO.Path]::Combine($mount_point, '*')))) {
					Remove-Item $mount_point
				}
			}
		}
	}
}

# @brief: Switch the light/dark theme for the prompt
# @details:
# There are two major parts for the thme
# 1. The PSReadLine coloring
# 2. The custom prompt coloring
# @param[in]: $Theme - the theme name
# @param[out]: None
# @note: This utility function is not a real function in the functional programming sense, since it has side effects.
function Switch-Theme {
    param (
        [Parameter(Mandatory)]
        [ValidateSet("Dark", "Light")]
        [string]$Theme
    )
    if ($Theme -eq "Dark") {
        # Set-PSReadLineOption -Colors @{ Command = "DarkYellow"; Prompt = "Gray" }
        # $Global:TerminalTheme = "Dark"
    } elseif ($Theme -eq "Light") {
        # Set-PSReadLineOption -Colors @{ Command = "Blue"; Prompt = "Black" }
        # $Global:TerminalTheme = "Light"
    }
    Write-Host "Switched to $Theme theme."
}
