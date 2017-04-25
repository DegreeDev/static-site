if($PSCommandPath -eq $null) {
	$CommandRootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path);
} else {
	$CommandRootPath = (Split-Path -Parent $PSCommandPath);
}

."$CommandRootPath\utilities.ps1";

function Invoke-ArtifactDownload {
	param (
		[Parameter(Mandatory)]
		[string] $ProjectName,
		[Parameter(Mandatory)]
		[string] $Version,
		[Parameter(Mandatory)]
		[ValidateScript({ Test-Path -Path $_ -PathType 'Container' })]
		[string] $DestinationPath,
		[string] $ArtifactRepository = "savo-builds"
	)
	begin {
		$artifactUrl = "http://artifactory.savo.io/artifactory/$($ArtifactRepository)/$($ProjectName)/$($ProjectName)-$($Version).zip";
		$outFile = (Join-Path -Path $DestinationPath -ChildPath "$($ProjectName)-$($Version).zip");
	}
	process {
		try {
			Invoke-WebRequest -Uri $artifactUrl -OutFile $outFile | Out-Null;
			return Resolve-Path -Path $outFile;
		} catch {
			throw $_;
		}
	}
}

function Initialize-Environment {
	param()
	process {
		$ENV:AWS_SECRET_ACCESS_KEY = Get-Item -Path "ENV:\$($ENV:AWS_SECRET_ACCESS_KEY_ENV_KEY)" -ErrorVariable "tempErrors" -ErrorAction SilentlyContinue;
		$ENV:AWS_ACCESS_KEY_ID = Get-Item -Path "ENV:\$($ENV:AWS_ACCESS_KEY_ID_ENV_KEY)" -ErrorVariable "tempErrors" -ErrorAction SilentlyContinue;
		if($tempErrors) {
			return 255;
		} else {
			return 0;
		}
	}
}

function Invoke-Deploy {
	param (
		[Parameter(Mandatory)]
		[string] $AppStackName,
		[Parameter(Mandatory)]
		[string] $AwsAccountName,
		[Parameter(Mandatory)]
		[ValidateScript({ Test-Path -Path $_ -PathType 'Container' })]
		[string] $Workspace,
		[Parameter(Mandatory)]
		[string] $ProjectName,
		[Parameter(Mandatory)]
		[string] $Version,
		[Parameter(Mandatory)]
		[string] $IamDeployRoleName,
		[switch] $DeployStacks
	)
	begin {
		$projectEnvironment = 'prod';
		if($AwsAccountName -eq 'nonprod') {
			$projectEnvironment = 'uat';
		}

		$baseProjectName = "$AppStackName-$projectEnvironment-$ProjectName";
		$proxyLambdaName = "$AppStackName-$projectEnvironment-$ProjectName";
		$uniqueExecutorRole = "$AppStackName-$projectEnvironment-$ProjectName-executor";

		$dist = Join-Path -Path $Workspace -ChildPath "dist";
		if(!(Test-Path -Path "$dist")) {
			New-Item -ItemType Directory -Path $dist -Force | Out-Null;
		}
		$artifactFile = (Join-Path -Path $dist -ChildPath "$($ProjectName)-$($Version).zip");

		$ENV:APP_ARTIFACT_PACKAGE_PATH = "$artifactFile";
		$ENV:APP_CLEAN_BRANCH_NAME = "$trimmedBranch";
		$ENV:APP_ENVIRONMENT_NAME = "$projectEnvironment";
		$ENV:APP_GATEWAY_LAMBDA = "$proxyLambdaName";
		$ENV:APP_EXECUTOR_ROLE = "$uniqueExecutorRole";
		$ENV:APP_BASE_STACK_NAME = "$baseProjectName";
	}
	process {
		try {
			$exitCode = 0;
			$exitCode += Initialize-Environment;
			if($exitCode -ne 0) {
				return $exitCode;
			}

			$artifact = Invoke-ArtifactDownload -ProjectName $ProjectName -Version $Version -DestinationPath $dist;

			if ($DeployStacks.IsPresent) {
				Grant-AWSDeploymentRole -RoleName "$IamDeployRoleName" -SessionName "$ProjectName-$Version-deploy" | Out-Null;

				$templates = Get-TemplatesToTransform -Path (Join-Path -Path $Workspace -ChildPath "cfn-templates");
				$exitCode += Invoke-TemplateDeployment -Templates $templates
				if($exitCode -ne 0){
					return $exitCode;
				}
			}

			"Publish code to lamda: $lambdaFunctionName" | Write-Host;
			Invoke-AwsCli -Command lambda -Action "update-function-code" -Arguments @(
				"--function-name `"$lambdaFunctionName`"",
				"--zip-file `"fileb://$($artifactFile -replace "\\", "/")`""
			) | Out-Null;
			$exitCode += $LASTEXITCODE;
			return $exitCode;
		} catch {
			$_ | Write-Warning;
			return 255;
		}
	}
}

if( ($Execute -eq $null) -or ($Execute -eq $true) ) {
	try {
		$shouldDeployStacks = $ENV:CI_DEPLOY_STACKS -match "^true$";
		$result = Invoke-Deploy -AppStackName $ENV:AWS_APP_STACK `
			-Workspace "$ENV:WORKSPACE" -AwsAccountName $ENV:AWS_ACCOUNT `
			-ProjectName $ENV:CI_PROJECT -Version $ENV:CI_VERSION `
			-IamDeployRoleName $ENV:AWS_IAM_DEPLOY_ROLE `
			-DeployStacks:$shouldDeployStacks;
		exit $result;
	} catch {
		$_ | Write-Warning;
		exit 255;
	}
}
