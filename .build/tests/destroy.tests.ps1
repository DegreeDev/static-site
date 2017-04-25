if($PSCommandPath -eq $null) {
	$CommandRootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path);
} else {
	$CommandRootPath = (Split-Path -Parent $PSCommandPath);
}

# This stops the initial invoking of Invoke-Setup;
$Execute = $false;

."$(Join-Path -Path $CommandRootPath -ChildPath "../destroy.ps1")" -Path .;

Describe "Invoke-Destroy" {
  Context "When AppStackName not set" {
    It "Must throw exception" {
      Mock Grant-AWSDeploymentRole { return; };
      Mock Test-StackExists { return $true; };
      Mock Remove-Stack { return 0; };
			Mock Write-Host { return; };
      { Invoke-Destroy -AppStackName "" -ProjectName "mock-project" -Branch "topic/mock-branch-name" -DeployRole "mock-iam-deploy-role" } |
        Should Throw "Cannot bind argument to parameter 'AppStackName' because it is an empty string.";
      { Invoke-Destroy -AppStackName -ProjectName "mock-project" -Branch "topic/mock-branch-name" -DeployRole "mock-iam-deploy-role"} |
        Should Throw "Missing an argument for parameter 'AppStackName'. Specify a parameter of type 'System.String' and try again.";
      Assert-MockCalled Remove-Stack -Exactly -Times 0;
      Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 0;
      Assert-MockCalled Test-StackExists -Exactly -Times 0;
    }
  }
  Context "When ProjectName not set" {
    It "Must throw exception" {
      Mock Grant-AWSDeploymentRole { return; };
      Mock Test-StackExists { return $true; };
      Mock Remove-Stack { return 0; };
			Mock Write-Host { return; };
      { Invoke-Destroy -AppStackName "aero" -ProjectName "" -Branch "topic/mock-branch-name" -DeployRole "mock-iam-deploy-role" } |
        Should Throw "Cannot bind argument to parameter 'ProjectName' because it is an empty string.";
      { Invoke-Destroy -AppStackName "aero" -ProjectName -Branch "topic/mock-branch-name" -DeployRole "mock-iam-deploy-role"} |
        Should Throw "Missing an argument for parameter 'ProjectName'. Specify a parameter of type 'System.String' and try again.";
      Assert-MockCalled Remove-Stack -Exactly -Times 0;
      Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 0;
      Assert-MockCalled Test-StackExists -Exactly -Times 0;
    }
  }
  Context "When Branch not set" {
    It "Must throw exception" {
      Mock Grant-AWSDeploymentRole { return; };
      Mock Test-StackExists { return $true; };
      Mock Remove-Stack { return 0; };
			Mock Write-Host { return; };
      { Invoke-Destroy -AppStackName "aero" -ProjectName "mock-project" -Branch "" -DeployRole "mock-iam-deploy-role" } |
        Should Throw "Cannot bind argument to parameter 'Branch' because it is an empty string.";
      { Invoke-Destroy -AppStackName "aero" -ProjectName "mock-project" -Branch -DeployRole "mock-iam-deploy-role"} |
        Should Throw "Missing an argument for parameter 'Branch'. Specify a parameter of type 'System.String' and try again.";
      Assert-MockCalled Remove-Stack -Exactly -Times 0;
      Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 0;
      Assert-MockCalled Test-StackExists -Exactly -Times 0;
    }
  }
  Context "When DeployRole not set" {
    It "Must throw exception" {
      Mock Grant-AWSDeploymentRole { return; };
      Mock Test-StackExists { return $true; };
      Mock Remove-Stack { return 0; };
			Mock Write-Host { return; };
      { Invoke-Destroy -AppStackName "aero" -ProjectName "mock-project" -Branch "topic/mock-branch-name" -DeployRole "" } |
        Should Throw "Cannot bind argument to parameter 'DeployRole' because it is an empty string.";
      { Invoke-Destroy -AppStackName "aero" -ProjectName "mock-project" -Branch "topic/mock-branch-name" -DeployRole } |
        Should Throw "Missing an argument for parameter 'DeployRole'. Specify a parameter of type 'System.String' and try again.";

      Assert-MockCalled Remove-Stack -Exactly -Times 0;
      Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 0;
      Assert-MockCalled Test-StackExists -Exactly -Times 0;
    }
  }
  Context "When unable to grant deployment role" {
    It "Must exit with error code" {
      Mock Write-Warning { return $Message };
      Mock Grant-AWSDeploymentRole { throw "There was a problem getting the AWS_ACCESS_KEY_ID and storing it for use" };
      Mock Test-StackExists { return $true; };
      Mock Remove-Stack { return 0; };
			Mock Write-Host { return; };
    	$result = Invoke-Destroy -AppStackName "aero" -ProjectName "mock-project" -Branch "topic/mock-branch-name" -DeployRole "mock-iam-deploy-role";
      $result[0] | Should Be "There was a problem getting the AWS_ACCESS_KEY_ID and storing it for use";
      $result[1] | Should Be 255;
      Assert-MockCalled Remove-Stack -Exactly -Times 0;
      Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 1;
      Assert-MockCalled Test-StackExists -Exactly -Times 0;
    }

  }
  Context "When Stack does not exist" {
    It "Must exit without error" {
      Mock Write-Warning { return $Message };
      Mock Grant-AWSDeploymentRole { return };
      Mock Test-StackExists { return $false; };
      Mock Remove-Stack { return 0; };
			Mock Write-Host { return; };
      $result = Invoke-Destroy -AppStackName "aero" -ProjectName "mock-project" -Branch "topic/mock-branch-name" -DeployRole "mock-iam-deploy-role";
      $result | Should Be 0;
      Assert-MockCalled Remove-Stack -Exactly -Times 0;
      Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 1;
      Assert-MockCalled Test-StackExists -Exactly -Times 1;
    }
  }
  Context "When delete stack fails" {
    It "Must exit with error code" {
      Mock Grant-AWSDeploymentRole { return };
      Mock Test-StackExists { return $true; };
      Mock Remove-Stack { return 23; };
			Mock Write-Host { return; };
      $result = Invoke-Destroy -AppStackName "aero" -ProjectName "mock-project" -Branch "topic/mock-branch-name" -DeployRole "mock-iam-deploy-role";
      $result | Should Be 23;
      Assert-MockCalled Remove-Stack -Exactly -Times 1;
      Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 1;
      Assert-MockCalled Test-StackExists -Exactly -Times 1;
    }
  }
  Context "When delete stack is success" {
    It "Must exit without error" {
      Mock Grant-AWSDeploymentRole { return };
      Mock Test-StackExists { return $true; };
      Mock Remove-Stack { return 0; };
			Mock Write-Host { return; };
      $result = Invoke-Destroy -AppStackName "aero" -ProjectName "mock-project" -Branch "topic/mock-branch-name" -DeployRole "mock-iam-deploy-role";
      $result | Should Be 0;
      Assert-MockCalled Remove-Stack -Exactly -Times 1;
      Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 1;
      Assert-MockCalled Test-StackExists -Exactly -Times 1;
    }
  }
}
