# @brief: Mount remote shared storage as a workspace
# @note:
# - `UrlEncode` is used to encode the volume name to handle no-ASCII characters (e.g. Japanese)
# - This function utilizes the macOS built-in (BSD) `mount`, make sure the path is properly set
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
			$mount_target = "smb://${usr_id}:${passphrase}@${host_id}/$([System.Web.HttpUtility]::UrlEncode($vol_id))"
			try {
				New-Item -ItemType Directory -Path $mnt_pt -ErrorAction Stop
				# Call system mount comamnd
				mount -t smbfs $mount_target $mnt_pt
				if ($?) {
					Write-Host "Mount point '$wksp_id' is successfully created at '$mnt_pt'."
				} else {
					Write-Error "Failed to mount '$wksp_id' at '$mnt_pt'."
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
