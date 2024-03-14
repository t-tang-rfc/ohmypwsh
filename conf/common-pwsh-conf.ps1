<#
	@brief: Common PowerShell configuration for all platforms

	@detaisl:
	- Locale configuration
	- Environment configuration
	- Alias configuration
	- Prompt configuration
	- PSReadline configuration

	@author:
	- Tianhan Tang (tianhantang.pd@gmail.com)

	@date:
	- created on 2021-08-05
	- updated on 2024-03-14
#>

# /// Locale settings
[cultureinfo]::CurrentCulture = 'ja-JP'

# /// Environment setup
# ////////////////////////////////////////////////////////////

# // Unload PSReadline (@note, ince PSReadline is automatically loaded, we unload it first to do some configuration)
Remove-Module -Name PSReadline

# // Set environment variables
# configure GPG_TTY such that gpg-agent can find the tty for passphrase input
Set-Item -Path "env:GPG_TTY" -Value "$(tty)" # @note, use `Get-Command -Name tty` to check whether the command is available

# /// Alias configuration

# /// Prompt configuration
# ////////////////////////////////////////////////////////////

# Prompt function
Function prompt {
	$stat = $Global:custom_error_status -and $? # @todo
	# Line 2 (time and status)
	$line_2 = @(
		'|-',
		'[',
		(Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"), # ISO 8601 format
		']',
		'[',
		($stat ? 'o' : 'x'),
		']'
	) -join ''
	# Line 3 (empty)
	$line_3 = ''
	# Line 0 ([env][name@machine:path][git])
	$line_0 = @(
		'|-',
		'[',
		'env:',
		$Global:custom_conda_prompt,
		']',
		'[',
		(
			$Global:custom_usr_id +
			'@' + $Global:custom_machine_id + ':' + 
			$Global:custom_path_prompt
		),
		']',
		'[',
		'git:',
		$Global:custom_git_info.git_prompt,
		']'
	) -join ''
	# Line 1 (command)
	$line_1 = @(
		':',
		' '
	) -join ''

	$Global:custom_error_status = $true

	return @(
		$line_2,
		$line_3,
		$line_0,
		$line_1
	) -join [System.Environment]::newline
}

# /// PSReadline configuration
# ////////////////////////////////////////////////////////////

# Re-load PSReadline
Import-Module -Name PSReadline

# Set PSReadline options
$PSReadLineOptions = @{
	EditMode = "Emacs";
	HistoryNoDuplicates = $true;
	HistorySearchCursorMovesToEnd = $true
}
Set-PSReadLineOption @PSReadLineOptions
