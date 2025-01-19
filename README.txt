+++ header
@file: ohmypwsh/README.txt
@author: Tianhan Tang (tianhantang.pd@gmail.com)
@date:
- created on 2025-01-18
- updated on 2025-01-19
+++

=== Introduction

[ohmypwsh](https://github.com/tianhantang/ohmypwsh) is a fundamentally a PowerShell profile, much like a `.bashrc` or `.zshrc`.
It is a collection of scripts and functions that I use in my daily work.

It is inspired by [Oh My Zsh](https://ohmyz.sh).

=== Advanced usage

--- To use the device-dependent `Mount-Workspace` function

One needs to create a JSON file to store the necessary parameters for the remote storage mount operation for their system.
The content may look like this (`+++ JSON` and `+++` are part of the content):
```
+++ JSON
{
	WkspID: {
		MountPoint: "~/Workspace",
		HostID: "MyServer",
		VolumeID: "WKSP",
		VolumeType: "smbfs",
		UserID: "foo"
		UserPSW: "hogehoge"
	}
}
+++
```

Then encrypt the JSON file with GPG, e.g.
+++ command
gpg --encrypt --armor --recipient tianhantang.pd@gmail.com ./workspace-info
+++

Put the encrypted file in the dedicated ohmypwsh config directory---for macOS, it is `~/.ohmypwsh.d/workspace-info.asc`.

There you go, the `Mount-Workspace` function will auto load the parameters from the encrypted JSON file, and mount the remote storage for you by calling `Mount-Workspace WkspID`.

=== Guideline for contribution

1. Fork the repository
2. Create your feature or bugfix branch from the `develop` branch
3. Make pull request to the `develop` branch
