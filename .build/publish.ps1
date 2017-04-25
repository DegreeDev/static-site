if($PSCommandPath -eq $null) {
	$CommandRootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path);
} else {
	$CommandRootPath = (Split-Path -Parent $PSCommandPath);
}

."$CommandRootPath\utilities.ps1";

function Invoke-Publish {
	param (
		[Parameter(Mandatory)]
		[string] $AppStackName,
		[Parameter(Mandatory)]
		[string] $AwsAccountName,
		[Parameter(Mandatory)]
		[string] $Workspace,
		[Parameter(Mandatory)]
		[string] $ProjectName,
		[Parameter(Mandatory)]
		[string] $Version,
		[Parameter(Mandatory)]
		[string] $ArtifactsSourcePath,
		[Parameter(Mandatory)]
		[string] $ArtifactOutputPath,
		[Parameter(Mandatory)]
		[string] $Branch,
		[Parameter(Mandatory)]
		[string] $IamDeployRoleName,
		[switch] $IsCISnapshot
	)
	begin {
		$projectEnvironment = 'dev'
		# if not tagged as snapshot
		if(!($IsCISnapshot.IsPresent)) {
			# and we are in nonprod
			if($AwsAccountName -eq 'nonprod') {
				# then it is uat
				$projectEnvironment = 'uat';
			} else {
				# or it is the 'account' (ie: prod)
				$projectEnvironment = $AwsAccountName;
			}
		}

		# for topic branches create unique objects
		$baseProjectName = "$AppStackName-$projectEnvironment-$ProjectName";
		$proxyLambdaName = "$AppStackName-$projectEnvironment-$ProjectName";
		$uniqueExecutorRole = "$AppStackName-$projectEnvironment-$ProjectName-executor";
		$trimmedBranch = "";

		if ($IsCISnapshot.IsPresent -and ($Branch -ne "" -and $Branch -ne $null)) {
		  # jenkins-jobs is removed becuase it shows up sometimes from jenkins... not sure why it is not 100% of the time.
			$trimmedBranch = $Branch | Out-CleanBranchForStackName;
			$baseProjectName = "$AppStackName-$projectEnvironment-$ProjectName-$trimmedBranch";
		  $proxyLambdaName = "$AppStackName-$projectEnvironment-$ProjectName-$trimmedBranch";
			$uniqueExecutorRole = "$AppStackName-$projectEnvironment-$ProjectName-$trimmedBranch-executor";
		}

		$distPath = Join-Path -Path $Workspace -ChildPath $ArtifactOutputPath;
		$lambdaPkg = Join-Path -Path $distPath -ChildPath "$ProjectName-$Version.zip";
		#if($IsCISnapshot.IsPresent) {
		# $lambdaPkg = Join-Path -Path $distPath -ChildPath "$ProjectName-$Version-SNAPSHOT.zip";
		#}
		$lambdaPkg = $lambdaPkg -replace '\\', '/';

		$ENV:APP_ARTIFACT_PACKAGE_PATH = "$lambdaPkg";
		$ENV:APP_CLEAN_BRANCH_NAME = "$trimmedBranch";
		$ENV:APP_ENVIRONMENT_NAME = "$projectEnvironment";
		$ENV:APP_GATEWAY_LAMBDA = "$proxyLambdaName";
		$ENV:APP_EXECUTOR_ROLE = "$uniqueExecutorRole";
		$ENV:APP_BASE_STACK_NAME = "$baseProjectName";

		$workspaceArtifacts = "$($Workspace)\\$($ArtifactsSourcePath)";
	}
	process {
		try {
			Grant-AWSDeploymentRole -RoleName "$IamDeployRoleName" -SessionName "$ProjectName-$Version" | Out-Null;

			$templates = Get-TemplatesToTransform -Path (Join-Path -Path $Workspace -ChildPath "cfn-templates");
			$exitCode = 0;

			$exitCode += Invoke-TemplateDeployment -Templates $templates
			if($exitCode -ne 0){
				return $exitCode;
			}

			"Publish code to lamda: $lambdaFunctionName" | Write-Host;
			Invoke-AwsCli -Command lambda -Action "update-function-code" -Arguments @(
				"--function-name `"$lambdaFunctionName`"",
				"--zip-file `"fileb://$lambdaPkg`""
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
		$exitCode = Invoke-Publish -AppStackName $ENV:AWS_APP_STACK -AwsAccountName $ENV:AWS_ACCOUNT -Workspace $ENV:WORKSPACE `
			-ProjectName $ENV:CI_PROJECT -Version $ENV:CI_SEMVERSION -ArtifactsSourcePath $ENV:CI_ARTIFACTS_PATH `
			-ArtifactOutputPath $ENV:CI_ARTIFACT_OUTPUT_PATH -Branch $ENV:GIT_BRANCH -IamDeployRoleName $ENV:AWS_IAM_DEPLOY_ROLE `
			-IsCISnapshot:($ENV:CI_SNAPSHOT -match '^true$');
		exit $exitCode;
	} catch {
		$_ | Write-Warning;
		exit 255;
	}
}
