if($PSCommandPath -eq $null) {
	$CommandRootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path);
} else {
	$CommandRootPath = (Split-Path -Parent $PSCommandPath);
}

."$CommandRootPath\utilities.ps1";

function Invoke-Build {
	param (
		[Parameter(Mandatory)]
		[string] $Environment = 'development',
    [Parameter(Mandatory)]
    [string] $DistributionPath,
    [Parameter(Mandatory)]
    [string] $ArtifactsPath,
		[Parameter(Mandatory)]
		[string] $Version
	)
	begin {
		$buildEnvironment = "development";
		switch ($Environment) {
			nonprod {
				# set to UAT if CI_SNAPSHOT = false
				if ( $ENV:CI_SNAPSHOT -ne 'true' ) {
					$buildEnvironment = "uat";
				} else {
					# otherwise it is development
					$buildEnvironment = "development";
				}
				break;
			}
			prod {
				$buildEnvironment = "production";
				break;
			}
			default {
				$buildEnvironment = "development";
				break;
			}
		}
    $buildEnvironment | Write-Host;
    $outputPath = $DistributionPath;
		if($outputPath -eq $null -or $outputPath -eq '') {
			$outputPath = './dist';
		}

    if (Test-Path -Path $outputPath) {
      Remove-Item -Path $outputPath -Force -Recurse | Out-Null;
    }
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null;

		# Create the folder that will hold the packaged files
		$pkgPath = $ArtifactsPath;
		if($pkgPath -ne $null -and $pkgPath -ne '') {
			if (!(Test-Path -Path $pkgPath)) {
				New-Item -Path $pkgPath -ItemType Directory | Out-Null;
			}
		}

	}
	process {
		$result = 0;
		Invoke-ExternalCommand -Command npm -Arguments @("version", "$Version", "--no-git-tag-version") | Write-Host;
		$result += $LASTEXITCODE;
		"Running 'npm build'" | Write-Host;
		Invoke-ExternalCommand -Command npm -Arguments @("run", "build") | Write-Host;
		$result += $LASTEXITCODE;
    Start-Sleep -s 5 | Out-Null;
    Copy-ToDistributionFolder -SourcePath (Get-Location) -DistributionPath $outputPath | Out-Null;
    return $result;
	}
}


if( ($Execute -eq $null) -or ($Execute -eq $true) ) {
	try {
	  $exitCode = Invoke-Build -Environment $ENV:AWS_ACCOUNT `
			-DistributionPath $ENV:CI_ARTIFACTS_PATH `
			-ArtifactsPath $ENV:CI_ARTIFACT_OUTPUT_PATH `
			-Version $ENV:CI_SEMVERSION;
	  exit $exitCode;
	} catch {
		$_ | Write-Warning;
		exit 255;
	}
}
