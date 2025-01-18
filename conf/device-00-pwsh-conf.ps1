# @brief: Mount remote shared storage as a workspace
# @note:
# - `UrlEncode` is used to encode the volume name to handle no-ASCII characters (e.g. Japanese)
# - This function utilizes the macOS built-in (BSD) `mount`, make sure the path is properly set
# @todo:
# - [ ] SMB specific
# - [ ] Supress the output of New-Item
# - [ ] Use named parameters
# @see: `man mount`
Function Mount-Workspace {
	param(
		[Parameter(Mandatory = $true, Position = 0)][string]$wksp_id,   # workspace identifier
		[Parameter(Mandatory = $true, Position = 1)][string]$mnt_pt,    # mount point
		[Parameter(Mandatory = $true, Position = 2)][string]$host_id,   # host identifier, IP or hostname
		[Parameter(Mandatory = $true, Position = 3)][string]$vol_id,    # shared volume identifier
		[Parameter(Mandatory = $true, Position = 4)][string]$usr_id,    # user identifier
		[Parameter(Mandatory = $true, Position = 5)][string]$passphrase # passphrase
	)
	if ("W4:" -eq $wksp_id) { # Currently only support W4:
		if (-not (Test-Path $mnt_pt -PathType Container)) { # Abort if the mount point already exists, since it may be local workspace
			$mount_target = "//${usr_id}:${passphrase}@${host_id}/$([System.Web.HttpUtility]::UrlEncode($vol_id))"
			try {
				New-Item -ItemType Directory -Path $mnt_pt -ErrorAction Stop
				# Call system comamnd `mount`
				mount -t smbfs $mount_target $mnt_pt
				if ($?) {
					Write-Output "Successfully created mount point '$mnt_pt' for '$wksp_id'."
				} else {
					throw "Failed to mount '$wksp_id' at '$mnt_pt'."
				}
			} catch {
				Write-Error $_.Exception.Message
				# Clean up
				if (Test-Path $mnt_pt -PathType Container) {
					Remove-Item -Path $mnt_pt -Recurse -Force -ErrorAction SilentlyContinue
				}
			}
		} else {
			Write-Error "Mount point '$wksp_id' already exists! Please take care!"
		}
	} else {
		Write-Error "Workspace '$wksp_id' is not supported in this version."
	}
}

# @brief: Remove mounted workspace served by the remote shared storage
# @note:
# - This function utilizes the macOS built-in (BSD) `umount`, make sure the path is properly set
# @see:
# - `man umount`
Function Remove-Workspace {
	param(
		[Parameter(Mandatory = $true, Position = 0)][string]$wksp_id, # workspace identifier
		[Parameter(Mandatory = $true, Position = 1)][string]$mnt_pt   # mount point
	)
	if ("W4:" -eq $wksp_id) { # Currently only support W4:
		if (-not (Test-Path $mnt_pt -PathType Container)) { # Abort if the mount point does not exist
			Write-Error "The specified mount point '$mnt_pt' does not exist or is not mounted."
			return
		}
		try {
			# Call system command `umount`
			umount $mnt_pt 2>$null
			if (-not $?) {
				# Fallback mechanism for force un-mounting
				diskutil unmount force $mnt_pt
				if (-not $?) {
					throw "Failed to unmount '$wksp_id' from '$mnt_pt'."
				}
			}
			# Clean up
			Remove-Item -Path $mnt_pt -ErrorAction Stop
			Write-Output "Successfully unmounted '$wksp_id' from '$mnt_pt' and cleaned up the directory."
		} catch {
			Write-Error $_.Exception.Message
		}
	} else {
		Write-Error "Workspace '$wksp_id' is not supported in this version."
	}
}
