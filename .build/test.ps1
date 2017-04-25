
if($PSCommandPath -eq $null) {
	$CommandRootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path);
} else {
	$CommandRootPath = (Split-Path -Parent $PSCommandPath);
}

."$CommandRootPath\utilities.ps1";

function Invoke-CfnValidation {
	param (
		[Parameter(Mandatory)]
		$Template
	)
	process {
		Invoke-AwsCli -Command cloudformation -Action "validate-template" -Arguments @("--template-body `"$Template`"") | Write-Host;
		return $LASTEXITCODE;
	}
}

function Invoke-PesterTests {
	param (
		[Parameter(Mandatory)]
		[ValidateScript({Test-Path $_ -PathType Container})]
		[string] $TestsPath,
		[Parameter(Mandatory)]
		[ValidateScript({Test-Path $_ -PathType Container})]
		[string] $ScriptsPath,
		[Parameter(Mandatory)]
		[ValidateScript({Test-Path $_ -PathType Container})]
		[string] $ResultsPath
	)
	begin {
		if(-not (Get-Module -ListAvailable -Name "pester")) {
			Invoke-ExternalCommand -Command choco -Arguments @("install", "pester", "-y") | Out-Null;
		}
		Import-Module "pester" -Force | Out-Null;
		$psModuleFiles = "$ScriptsPath\*.ps*1";

		$tests = (Get-ChildItem -Path "$TestsPath\*.tests.ps1" | % { $_.FullName });
		$coverageFiles = (Get-ChildItem -Path "$psModuleFiles") | where { $_.Name -inotmatch "\.tests\.ps1$" -and $_.Name -inotmatch "\.psd1$" } | % { $_.FullName };
		$resultsOutput = (Join-Path -Path $ResultsPath -ChildPath "pester.results.xml");
	}
	process {
		try {
			$result = Invoke-Pester -Script $tests -OutputFormat NUnitXml -CodeCoverage $coverageFiles -OutputFile $resultsOutput -Strict -PassThru;
			return $result.FailedCount;
		} catch {
			$_ | Write-Warning;
			return 255;
		}
	}
}

function Invoke-NpmTest {
  #(& istanbul cover node_modules/mocha/bin/_mocha -- -R spec) | Write-Host;
	Invoke-ExternalCommand -Command npm -Arguments @('run', 'test') | Write-Host;
  return $LASTEXITCODE;
}

function Invoke-Tests {
	param (
		[Parameter(Mandatory)]
		[ValidateScript({Test-Path $_ -PathType Container})]
		[string] $Workspace,
		[Parameter(Mandatory)]
		[string] $ProjectName,
		[Parameter(Mandatory)]
		[string] $IamDeployRoleName
	)
	begin {
	}
	process {
		try {
			$exitCode = Invoke-PesterTests -TestsPath (Join-Path -Path $Workspace -ChildPath "./tests") `
				-ScriptsPath (Join-Path -Path $Workspace -ChildPath "./") `
				-ResultsPath (Join-Path -Path $Workspace -ChildPath "./");
			if($exitCode -ne 0){
				return $exitCode;
			}

			Grant-AWSDeploymentRole -RoleName "$IamDeployRoleName" -SessionName "$ProjectName-TESTS" | Out-Null;

			$templates = Get-TemplatesToTransform -Path (Join-Path -Path $Workspace -ChildPath "cfn-templates");
			$exitCode += Test-TemplateDeployment -Templates $templates;
			if($exitCode -ne 0){
				return $exitCode;
			}
			$exitCode += Invoke-NpmTest;
			return $exitCode;
		} catch {
			$_ | Write-Warning;
			return 255;
		}
	}
}

if( ($Execute -eq $null) -or ($Execute -eq $true) ) {
	try {
		if(!(Test-Path ENV:\SAND_PATH)) {
      $workspacePath = $ENV:WORKSPACE
    } else {
      $workspacePath = Join-Path -Path $ENV:WORKSPACE -ChildPath $ENV:SAND_PATH;
    }
		$result = Invoke-Tests -Workspace "$workspacePath" -ProjectName $ENV:CI_PROJECT -IamDeployRoleName $ENV:AWS_IAM_DEPLOY_ROLE;
		exit $result;
	} catch {
		$_ | Write-Warning;
		exit 255;
	}
}
