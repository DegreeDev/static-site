param (
	[string] $Root = ".build",
	[switch] $EnableExit
)

if($PSCommandPath -eq $null) {
	$CommandRootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path);
} else {
	$CommandRootPath = (Split-Path -Parent $PSCommandPath);
}

$Execute = $false;
.(Join-Path -Path $CommandRootPath -ChildPath "..\test.ps1" -Resolve);
$result = Invoke-PesterTests -TestsPath "./$Root/tests" -ScriptsPath "$root" -ResultsPath "$root";
if($EnableExit.IsPresent) {
	exit $result;
}
