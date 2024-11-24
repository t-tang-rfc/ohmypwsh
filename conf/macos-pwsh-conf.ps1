<#
	@brief: macOS-specific PowerShell configuration

	@detaisl:
	- Environment configuration
	- Alias configuration

	@author:
	- Tianhan Tang (tianhantang.pd@gmail.com)

	@date:
	- created on 2021-08-09
	- updated on 2024-11-24
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
# 3. console coloring
# @param[in]: $Theme - the theme name
# @param[out]: None
# @note: This utility function is not a real function in the rigorous functional programming sense, since it has side effects.
function Switch-Theme {
    param (
        [Parameter(Mandatory)]
        [ValidateSet("Dark", "Light")]
        [string]$Theme
    )
    if ($Theme -eq "Dark") {

		$Global:PD_PROMPT_COLOR = @{
			'BG_USER'    = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Ocean']);
			'FG_USER'    = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Snow']);
			'BG_MACHINE' = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Snow']);
			'FG_MACHINE' = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Licorice']);
			'BG_PATH'    = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Cayenne']);
			'FG_PATH'    = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Snow']);
			'BG_AUX'     = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Licorice']);
			'FG_AUX'     = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Snow']);
		}

		Set-PSReadLineOption -Color @{
			'Default'                = "`e[38;2;$((Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Snow']))m";
			'Command'                = "`e[38;2;$((Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Lemon']))m";
			'Operator'               = "`e[38;2;$((Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Lemon']))m";
			'Parameter'              = "`e[38;2;$((Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Snow']))m";
			ContinuationPrompt       = $PSStyle.Foreground.FromRGB(0x0000FF)
			Emphasis                 = $PSStyle.Foreground.FromRGB(0x287BF0)
			Error                    = $PSStyle.Foreground.FromRGB(0xE50000)
			InlinePrediction         = $PSStyle.Foreground.FromRGB(0x93A1A1)
			Keyword                  = $PSStyle.Foreground.FromRGB(0x00008b)
			ListPrediction           = $PSStyle.Foreground.FromRGB(0x06DE00)
			Member                   = $PSStyle.Foreground.FromRGB(0x000000)
			Number                   = $PSStyle.Foreground.FromRGB(0x800080)			
			String                   = $PSStyle.Foreground.FromRGB(0x8b0000)
			Type                     = $PSStyle.Foreground.FromRGB(0x008080)
			Variable                 = $PSStyle.Foreground.FromRGB(0xff4500)
			ListPredictionSelected   = $PSStyle.Background.FromRGB(0x93A1A1)
			Selection                = $PSStyle.Background.FromRGB(0x00BFFF)
			'Comment'                = "`e[38;2;$((Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Tin']))m";
		}

		$PSStyle.Formatting.TableHeader = "`e[38;2;$((Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Snow']))m";
		$PSStyle.FileInfo.Directory = "`e[38;2;$((Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Turquoise']))m";
		$PSStyle.FileInfo.SymbolicLink = "`e[38;2;$((Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Silver']))m";

    } elseif ($Theme -eq "Light") {

		$Global:PD_PROMPT_COLOR = @{
			'BG_USER'    = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Ocean']);
			'FG_USER'    = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Snow']);
			'BG_MACHINE' = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Licorice']);
			'FG_MACHINE' = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Snow']);
			'BG_PATH'    = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Cayenne']);
			'FG_PATH'    = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Snow']);
			'BG_AUX'     = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Silver']);
			'FG_AUX'     = (Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Licorice']);
		}

		Set-PSReadLineOption -Color @{
			'Default'                = "`e[38;2;$((Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Licorice']))m";
			'Command'                = "`e[38;2;$((Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Midnight']))m";
			'Operator'               = "`e[38;2;$((Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Midnight']))m";
			ContinuationPrompt       = $PSStyle.Foreground.FromRGB(0x0000FF)
			Emphasis                 = $PSStyle.Foreground.FromRGB(0x287BF0)
			Error                    = $PSStyle.Foreground.FromRGB(0xE50000)
			InlinePrediction         = $PSStyle.Foreground.FromRGB(0x93A1A1)
			Keyword                  = $PSStyle.Foreground.FromRGB(0x00008b)
			ListPrediction           = $PSStyle.Foreground.FromRGB(0x06DE00)
			Member                   = $PSStyle.Foreground.FromRGB(0x000000)
			Number                   = $PSStyle.Foreground.FromRGB(0x800080)
			Parameter                = $PSStyle.Foreground.FromRGB(0x000080)
			String                   = $PSStyle.Foreground.FromRGB(0x8b0000)
			Type                     = $PSStyle.Foreground.FromRGB(0x008080)
			Variable                 = $PSStyle.Foreground.FromRGB(0xff4500)
			ListPredictionSelected   = $PSStyle.Background.FromRGB(0x93A1A1)
			Selection                = $PSStyle.Background.FromRGB(0x00BFFF)
			'Comment'                = "`e[38;2;$((Convert-HexColorToANSI $Global:PD_COLOR_PALLETE['Tin']))m";
		}

	}
	Write-Host "Switched to $Theme theme."
}
