if($PSCommandPath -eq $null) {
	$CommandRootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path);
} else {
	$CommandRootPath = (Split-Path -Parent $PSCommandPath);
}

# This stops the initial invoking of Invoke-Setup;
$Execute = $false;

."$(Join-Path -Path $CommandRootPath -ChildPath "../deploy.ps1")" -Path .;

Describe "Invoke-ArtifactDownload" {
	Context "When download is successful" {
		It "Must return the downloaded file" {
			Mock Invoke-WebRequest {
				Setup -File 'mock/dist/mock-project-1.0.0.0.zip' -Content "AAAAAA";
			};
			# This creates a fake file because its the only way to create the directory with setup
			Setup -File 'mock/dist/mock-file.ext';
			$result = Invoke-ArtifactDownload -ProjectName 'mock-project' -Version '1.0.0.0' `
				-DestinationPath (Join-Path -Path $TestDrive -ChildPath 'mock/dist');
			$result | Should Exist;
			$result | Should Match "mock\\dist\\mock-project-1\.0\.0\.0\.zip";
		}
	}
}

Describe "Initialize-Environment" {
	Context "When values lookup environment variable exists" {
		It "Must set the environment variables" {
			$TEMP_AWS_SECRET_ACCESS_KEY = $ENV:AWS_SECRET_ACCESS_KEY;
			$TEMP_AWS_ACCESS_KEY_ID = $ENV:AWS_ACCESS_KEY_ID;
			$TEMP_AWS_SECRET_ACCESS_KEY_ENV_KEY = $ENV:AWS_SECRET_ACCESS_KEY_ENV_KEY;
			$TEMP_AWS_ACCESS_KEY_ID_ENV_KEY = $ENV:AWS_ACCESS_KEY_ID_ENV_KEY;

			$ENV:AWS_SECRET_ACCESS_KEY_ENV_KEY = "MOCK_AWS_SECRET_ACCESS_KEY";
			$ENV:AWS_ACCESS_KEY_ID_ENV_KEY = "MOCK_AWS_ACCESS_KEY_ID";

			Mock Get-Item {
				$r = @{
					Name = "MOCK_AWS_SECRET_ACCESS_KEY";
					Value = "MOCK-AWS-SECRET-ACCESS-KEY";
				}
				$r | Add-Member -MemberType ScriptMethod -Name ToString -Value { return $this.Value; } -Force | Out-Null;
				return $r;
			} -ParameterFilter { $Path -eq 'ENV:\MOCK_AWS_SECRET_ACCESS_KEY' };
			Mock Get-Item {
				$r = @{
					Name = "MOCK_AWS_ACCESS_KEY_ID";
					Value = "MOCK-AWS-ACCESS-KEY-ID";
				};
				$r | Add-Member -MemberType ScriptMethod -Name ToString -Value { return $this.Value; } -Force | Out-Null;
				return $r;
			} -ParameterFilter { $Path -eq 'ENV:\MOCK_AWS_ACCESS_KEY_ID' };

			$result = Initialize-Environment;
			$result | Should Be 0;
			$ENV:AWS_SECRET_ACCESS_KEY | Should Be "MOCK-AWS-SECRET-ACCESS-KEY";
			$ENV:AWS_ACCESS_KEY_ID | Should Be "MOCK-AWS-ACCESS-KEY-ID";

			Assert-MockCalled Get-Item -ParameterFilter { $Path -eq 'ENV:\MOCK_AWS_SECRET_ACCESS_KEY' } -Exactly -Times 1;
			Assert-MockCalled Get-Item -ParameterFilter { $Path -eq 'ENV:\MOCK_AWS_ACCESS_KEY_ID' } -Exactly -Times 1;

			# Restore values
			$ENV:AWS_SECRET_ACCESS_KEY = $TEMP_AWS_SECRET_ACCESS_KEY;
			$ENV:AWS_ACCESS_KEY_ID = $TEMP_AWS_ACCESS_KEY_ID;
			$ENV:AWS_ACCESS_KEY_ID_ENV_KEY = $TEMP_AWS_ACCESS_KEY_ID_ENV_KEY;
			$ENV:AWS_SECRET_ACCESS_KEY_ENV_KEY = $TEMP_AWS_SECRET_ACCESS_KEY_ENV_KEY;
		}
	}
	Context "When values lookup environment variable does not exist" {
		It "Must return error exit code 255" {
			Mock Write-Error { return; }
			$TEMP_AWS_SECRET_ACCESS_KEY = $ENV:AWS_SECRET_ACCESS_KEY;
			$TEMP_AWS_ACCESS_KEY_ID = $ENV:AWS_ACCESS_KEY_ID;
			$TEMP_AWS_SECRET_ACCESS_KEY_ENV_KEY = $ENV:AWS_SECRET_ACCESS_KEY_ENV_KEY;
			$TEMP_AWS_ACCESS_KEY_ID_ENV_KEY = $ENV:AWS_ACCESS_KEY_ID_ENV_KEY;

			$ENV:AWS_SECRET_ACCESS_KEY_ENV_KEY = "MOCK_AWS_SECRET_ACCESS_KEY";
			$ENV:AWS_ACCESS_KEY_ID_ENV_KEY = "MOCK_AWS_ACCESS_KEY_ID";

			$result = Initialize-Environment;
			$result | Should Be 255;

			# Restore values
			$ENV:AWS_SECRET_ACCESS_KEY = $TEMP_AWS_SECRET_ACCESS_KEY;
			$ENV:AWS_ACCESS_KEY_ID = $TEMP_AWS_ACCESS_KEY_ID;
			$ENV:AWS_ACCESS_KEY_ID_ENV_KEY = $TEMP_AWS_ACCESS_KEY_ID_ENV_KEY;
			$ENV:AWS_SECRET_ACCESS_KEY_ENV_KEY = $TEMP_AWS_SECRET_ACCESS_KEY_ENV_KEY;
		}
	}
}

Describe "Invoke-Deploy" {
	Context "When Initialize-Environment fails" {
		It "Must fail and stop" {
			Mock Invoke-ArtifactDownload { };
			Mock Initialize-Environment { return 255; };
			Mock Invoke-TemplateDeployment {return 0;};
			Setup -File 'mock/.file';
			Setup -File 'mock/cfn-templates/cfn.template';
			$result = Invoke-Deploy -AppStackName 'mock' -AwsAccountName 'nonprod' `
				-Workspace "$TestDrive/mock" -ProjectName 'project' -Version '1.0.0.0' `
				-IamDeployRoleName 'deploy-project-nonprod-mock';
			$result | Should Be 255;
			Assert-MockCalled Initialize-Environment -Exactly -Times 1;
			Assert-MockCalled Invoke-ArtifactDownload -Exactly -Times 0;
			Assert-MockCalled Invoke-TemplateDeployment -Exactly -Times 0;
		}
	}
	Context "When completes successfully but not deploying stack" {
		It "Must not call the stack deployment steps" {
			Mock Grant-AWSDeploymentRole { };
			Mock Invoke-ArtifactDownload { };
			Mock Initialize-Environment { return 0; };
			Mock Invoke-TemplateDeployment {return 0;};
			Mock Invoke-AwsCli {
				"Output from command";
				$GLOBAL:LASTEXITCODE = 0;
			};
			Setup -File 'mock/.file';
			Setup -File 'mock/cfn-templates/cfn.template';
			$result = Invoke-Deploy -AppStackName 'mock' -AwsAccountName 'nonprod' `
				-Workspace "$TestDrive/mock" -ProjectName 'project' -Version '1.0.0.0' `
				-IamDeployRoleName 'deploy-project-nonprod-mock';
			$result | Should Be 0;

			$ENV:APP_GATEWAY_LAMBDA | Should BeExactly 'mock-uat-project';
			$ENV:APP_BASE_STACK_NAME | Should BeExactly 'mock-uat-project';
			$ENV:APP_EXECUTOR_ROLE | Should BeExactly 'mock-uat-project-executor';

			Assert-MockCalled Invoke-ArtifactDownload -Exactly -Times 1;
			Assert-MockCalled Initialize-Environment -Exactly -Times 1;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
			Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 0;
			Assert-MockCalled Invoke-TemplateDeployment -Exactly -Times 0;
		}
	}
	Context "When deploying stacks and Grant-AWSDeploymentRole fails" {
		It "Must return error exit code 255" {
			Mock Grant-AWSDeploymentRole { throw "There was a problem getting the AWS_ACCESS_KEY_ID and storing it for use" };
			Mock Invoke-TemplateDeployment {return 0;};
			Mock Invoke-ArtifactDownload { return; }; # normally returns the file path
			Mock Initialize-Environment { return 0; };
			Mock Invoke-AwsCli { };
			Mock Write-Warning { return; }
			Setup -File 'mock/.file';
			Setup -File 'mock/cfn-templates/cfn.template';
			$result = Invoke-Deploy -AppStackName 'mock' -AwsAccountName 'nonprod' `
				-Workspace "$TestDrive/mock" -ProjectName 'project' -Version '1.0.0.0' `
				-IamDeployRoleName 'deploy-project-nonprod-mock' -DeployStacks;
			$result | Should Be 255;
			$ENV:APP_GATEWAY_LAMBDA | Should BeExactly 'mock-uat-project';
			$ENV:APP_BASE_STACK_NAME | Should BeExactly 'mock-uat-project';
			$ENV:APP_EXECUTOR_ROLE | Should BeExactly 'mock-uat-project-executor';
			Assert-MockCalled Write-Warning -Exactly -Times 1;
			Assert-MockCalled Invoke-ArtifactDownload -Exactly -Times 1;
			Assert-MockCalled Initialize-Environment -Exactly -Times 1;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 0;
			Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 1;
			Assert-MockCalled Invoke-TemplateDeployment -Exactly -Times 0;
		}
	}
	Context "When deploying stacks and Invoke-TemplateDeployment call fails" {
		It "Must return error exit code" {
			Mock Grant-AWSDeploymentRole { };
			Mock Invoke-TemplateDeployment {return 96;};
			Mock Invoke-ArtifactDownload { return; }; # normally returns the file path
			Mock Initialize-Environment { return 0; };
			Mock Invoke-AwsCli { };
			Setup -File 'mock/.file';
			Setup -File 'mock/cfn-templates/app-cfn.template' -Content "AAAAAAA";
			Setup -File 'mock/cfn-templates/dynamodb-cfn.template';
			$result = Invoke-Deploy -AppStackName 'mock' -AwsAccountName 'nonprod' `
				-Workspace "$TestDrive/mock" -ProjectName 'project' -Version '1.0.0.0' `
				-IamDeployRoleName 'deploy-project-nonprod-mock' -DeployStacks;
			$result | Should Be 96;
			$ENV:APP_GATEWAY_LAMBDA | Should BeExactly 'mock-uat-project';
			$ENV:APP_BASE_STACK_NAME | Should BeExactly 'mock-uat-project';
			$ENV:APP_EXECUTOR_ROLE | Should BeExactly 'mock-uat-project-executor';

			Assert-MockCalled Invoke-ArtifactDownload -Exactly -Times 1;
			Assert-MockCalled Initialize-Environment -Exactly -Times 1;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 0;
			Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 1;
			Assert-MockCalled Invoke-TemplateDeployment -Exactly -Times 1;
		}
	}

	Context "When deploying stacks and all calls successful" {
		It "Must return 0" {
			Mock Grant-AWSDeploymentRole { };
			Mock Invoke-ArtifactDownload { return; }; # normally returns the file path
			Mock Initialize-Environment { return 0; };
			Mock Invoke-AwsCli { };
			Mock Invoke-TemplateDeployment {return 0;};
			Setup -File 'mock/.file';
			Setup -File 'mock/cfn-templates/app-cfn.template';
			Setup -File 'mock/cfn-templates/dynamodb-cfn.template';

			$result = Invoke-Deploy -AppStackName 'mock' -AwsAccountName 'nonprod' `
				-Workspace "$TestDrive/mock" -ProjectName 'project' -Version '1.0.0.0' `
				-IamDeployRoleName 'deploy-project-nonprod-mock' -DeployStacks;
			$result | Should Be 0;

			$ENV:APP_GATEWAY_LAMBDA | Should BeExactly 'mock-uat-project';
			$ENV:APP_BASE_STACK_NAME | Should BeExactly 'mock-uat-project';
			$ENV:APP_EXECUTOR_ROLE | Should BeExactly 'mock-uat-project-executor';

			Assert-MockCalled Write-Warning -Exactly -Times 0;
			Assert-MockCalled Invoke-ArtifactDownload -Exactly -Times 1;
			Assert-MockCalled Initialize-Environment -Exactly -Times 1;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
			Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 1;
			Assert-MockCalled Invoke-TemplateDeployment -Exactly -Times 1;
		}
	}
}
