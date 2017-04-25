
if($PSCommandPath -eq $null) {
	$CommandRootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path);
} else {
	$CommandRootPath = (Split-Path -Parent $PSCommandPath);
}

."$CommandRootPath\utilities.ps1";

function Invoke-Destroy {
  param (
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=0)]
    [string] $AppStackName,
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=0)]
    [string] $ProjectName,
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=0)]
    [string] $Branch,
    [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=0)]
    [string] $DeployRole
  )
  begin {
    $stackName = $AppStackName;
    # This is always dev, becase you shouldnt be destroying any other environment
    $projectEnvironment = 'dev';

    $baseProjectName = "$AppStackName-$projectEnvironment-$ProjectName";
    "CI_GIT_DESTROY_BRANCH : $Branch" | Write-Host;
    if ($Branch -ne "" -and $Branch -ne $null) {
    	$trimmedBranch = $Branch | Out-CleanBranchForStackName;
    	$baseProjectName = "$AppStackName-$projectEnvironment-$ProjectName-$trimmedBranch";
    }
    $stackName = "$baseProjectName-stack";
  }
  process {
    try {
      Grant-AWSDeploymentRole -RoleName "$DeployRole" -SessionName "$ProjectName-destroy" | Out-Null;
      $stackExists = Test-StackExists -StackName $stackName;
      $exitCode = 0;
      if($stackExists) {
        $exitCode = Remove-Stack -StackName $stackName;
				return $exitCode;
      } else {
				"Stack '$stackName' does not exist. No action taken." | Write-Host;
				return 0;
			}
    } catch {
      $_ | Write-Warning;
      return 255;
    }
  }
}

if( ($Execute -eq $null) -or ($Execute -eq $true) ) {
	try {
  	$exitCode = Invoke-Destroy -AppStackName $ENV:AWS_APP_STACK -ProjectName $ENV:CI_PROJECT -Branch $ENV:CI_GIT_DESTROY_BRANCH -DeployRole $ENV:AWS_IAM_DEPLOY_ROLE;
		exit $exitCode;
	} catch {
		$_ | Write-Warning;
		exit 255;
	}
}
