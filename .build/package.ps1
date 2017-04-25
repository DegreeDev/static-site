
function Create-ArtifactArchive {
	param (
		[string] $SourcePath,
		[string] $OutputPath,
		[string] $PackageName
	)
  begin {
    if ( !(Test-Path -Path $OutputPath) ) {
     New-Item -Path "$OutputPath" -Force -ItemType Directory | Out-Null;
    }

    $destination = Join-Path -Path $OutputPath -ChildPath "$PackageName";
  }
	process {
    $result = Invoke-7zip -OutputFile $destination -SourcePattern "$SourcePath\*";
		return $destination;
	}
}

function Invoke-7zip {
  param(
    [Parameter(Mandatory)]
    [string] $OutputFile,
    [Parameter(Mandatory)]
    [string] $SourcePattern
  )
  begin {
    if ( Test-Path -Path $OutputFile ) {
      Remove-Item -Path $OutputFile;
    }
  }
  process {
    Invoke-Expression "7za a -tzip `"$OutputFile`" `"$SourcePattern`" *>&1" | Write-Host;
    return $LASTEXITCODE;
  }
}


if( ($Execute -eq $null) -or ($Execute -eq $true) ) {
	try {
		#$artifactPackage = "$ENV:CI_PROJECT-$ENV:CI_VERSION.zip";
    #if($ENV:CI_SNAPSHOT -eq "true") {
    # $artifactPackage = "$ENV:CI_PROJECT-$ENV:CI_VERSION-SNAPSHOT.zip";
    #}

		$artifactPackage = "$ENV:CI_PROJECT-$ENV:CI_SEMVERSION.zip";
		$exitCode = Create-ArtifactArchive `
			-OutputPath (Join-Path -Path $ENV:WORKSPACE -ChildPath $ENV:CI_ARTIFACT_OUTPUT_PATH) `
			-SourcePath (Join-Path -Path $ENV:WORKSPACE -ChildPath $ENV:CI_ARTIFACTS_PATH) `
			-PackageName $artifactPackage;
		exit $exitCode;
	} catch {
		$_ | Write-Warning;
		exit 255;
	}
}
