if($PSCommandPath -eq $null) {
	$CommandRootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path);
} else {
	$CommandRootPath = (Split-Path -Parent $PSCommandPath);
}

# This stops the initial invoking of Invoke-Setup;
$Execute = $false;

."$(Join-Path -Path $CommandRootPath -ChildPath "../publish.ps1")" -Path .;

Describe "Invoke-Publish" {
	Context "When publishing topic branch successfully" {
		It "Must return success exit code" {
			Mock Test-Path { return $true; };
			Mock Grant-AWSDeploymentRole {
				return;
			};
			Mock Invoke-TemplateDeployment {return 0;};
			Mock Invoke-AwsCli {
				"some output from the command";
				$GLOBAL:LASTEXITCODE = 0;
				return 0;
			}
			Setup -File './mock/cfn-templates/app-cfn.template';
			Setup -File './mock/cfn-templates/dynamo-db.template';
			$result = Invoke-Publish -AppStackName 'mock' -AwsAccountName 'nonprod' `
				-Workspace "$TestDrive/mock" -ProjectName 'project' -Version '1.0.0.0' `
				-ArtifactsSourcePath './dist' -ArtifactOutputPath './dist-pkgs' `
				-Branch 'topic/my-mock-branch' -IamDeployRoleName 'mock-deploy-role' `
				-IsCISnapshot:$true;
			$result | Should Be 0;
			$ENV:APP_GATEWAY_LAMBDA | Should Not Be $null;
			$ENV:APP_GATEWAY_LAMBDA | Should BeExactly "mock-dev-project-my-mock-branch";
			Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 1;
			Assert-MockCalled Invoke-TemplateDeployment -Exactly -Times 1;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
		}
	}

	Context "When assume role fails" {
		It "Must return error code 255" {
			Mock Test-Path { return $true; };
			Mock Grant-AWSDeploymentRole {
				throw "assume-role exited with error code: 44";
			};
			Mock Invoke-TemplateDeployment {return 0;};
			Mock Invoke-AwsCli {
				"some output from the command";
				$GLOBAL:LASTEXITCODE = 0;
				return 0;
			};
			Mock Write-Warning { return; };
			Setup -File './mock/cfn-templates/app-cfn.template';
			Setup -File './mock/cfn-templates/dynamo-db.template';
			$result = Invoke-Publish -AppStackName 'mock' -AwsAccountName 'nonprod' `
				-Workspace "$TestDrive/mock" -ProjectName 'project' -Version '1.0.0.0' `
				-ArtifactsSourcePath './dist' -ArtifactOutputPath './dist-pkgs' `
				-Branch 'topic/my-mock-branch' -IamDeployRoleName 'mock-deploy-role' `
				-IsCISnapshot:$true;
			$result | Should Be 255;
			Setup -File './mock/cfn-templates/app-cfn.template';
			Setup -File './mock/cfn-templates/dynamo-db.template';
			$ENV:APP_GATEWAY_LAMBDA | Should Not Be $null;
			$ENV:APP_GATEWAY_LAMBDA | Should BeExactly "mock-dev-project-my-mock-branch";
			$ENV:APP_EXECUTOR_ROLE | Should Not Be $null;
			$ENV:APP_EXECUTOR_ROLE | Should BeExactly "mock-dev-project-my-mock-branch-executor";
			$ENV:APP_BASE_STACK_NAME | Should Not Be $null;
			$ENV:APP_BASE_STACK_NAME | Should BeExactly "mock-dev-project-my-mock-branch";

			Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 1;
			Assert-MockCalled Invoke-TemplateDeployment -Exactly -Times 0;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 0;
		}
	}

	Context "When Invoke-TemplateDeployment fails" {
		It "Must return error code" {
			Mock Test-Path { return $true; };
			Mock Grant-AWSDeploymentRole {
				return;
			};

			Mock Invoke-TemplateDeployment {return 4;};

			Mock Invoke-AwsCli {
				"some output from the command";
				$GLOBAL:LASTEXITCODE = 0;
				return 0;
			};
			Mock Write-Warning { return; };
			Setup -File './mock/cfn-templates/app-cfn.template';
			Setup -File './mock/cfn-templates/dynamo-db.template';
			$result = Invoke-Publish -AppStackName 'mock' -AwsAccountName 'nonprod' `
				-Workspace "$TestDrive/mock" -ProjectName 'project' -Version '1.0.0.0' `
				-ArtifactsSourcePath './dist' -ArtifactOutputPath './dist-pkgs' `
				-Branch 'topic/my-mock-branch' -IamDeployRoleName 'mock-deploy-role' `
				-IsCISnapshot:$true;
			$result | Should Be 4;
			$ENV:APP_GATEWAY_LAMBDA | Should Not Be $null;
			$ENV:APP_GATEWAY_LAMBDA | Should BeExactly "mock-dev-project-my-mock-branch";
			Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 1;
			Assert-MockCalled Invoke-TemplateDeployment -Exactly -Times 1;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 0;
		}
	}

	Context "When fails on lambda code update" {
		It "Must return error code" {
			Mock Test-Path { return $true; };
			Mock Grant-AWSDeploymentRole {
				return;
			};
			Mock Invoke-TemplateDeployment {return 0;};
			Mock Invoke-AwsCli {
				"some output from the command";
				$GLOBAL:LASTEXITCODE = 421;
				return 421;
			};
			Mock Write-Warning { return; };
			Setup -File './mock/cfn-templates/app-cfn.template';
			Setup -File './mock/cfn-templates/dynamodb-cfn.template';
			$result = Invoke-Publish -AppStackName 'mock' -AwsAccountName 'nonprod' `
				-Workspace "$TestDrive/mock" -ProjectName 'project' -Version '1.0.0.0' `
				-ArtifactsSourcePath './dist' -ArtifactOutputPath './dist-pkgs' `
				-Branch 'topic/my-mock-branch' -IamDeployRoleName 'mock-deploy-role' `
				-IsCISnapshot:$true;
			$result | Should Be 421;
			$ENV:APP_GATEWAY_LAMBDA | Should Not Be $null;
			$ENV:APP_GATEWAY_LAMBDA | Should BeExactly "mock-dev-project-my-mock-branch";
			Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 1;
			Assert-MockCalled Invoke-TemplateDeployment -Exactly -Times 1;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
		}
	}
}
