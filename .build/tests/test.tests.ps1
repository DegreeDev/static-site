if($PSCommandPath -eq $null) {
	$CommandRootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path);
} else {
	$CommandRootPath = (Split-Path -Parent $PSCommandPath);
}

# This stops the initial invoking of Invoke-Setup;
$Execute = $false;

."$(Join-Path -Path $CommandRootPath -ChildPath "../test.ps1")" -Path .;

Describe "Invoke-CfnValidation" {
	Context "When template does not exist" {
		It "Must return error exit code" {
			Mock Invoke-AwsCli {
				"Error: Output from command";
				$GLOBAL:LASTEXITCODE = 43;
			};
			Mock Test-Path {return $false} -ParameterFilter { $Path -match "mock\\cloudformation\.json" };

			# Setup -File 'mock/cloudformation.json' -Content "AAAAAAAA";
			$result = Invoke-CfnValidation -Template "$TestDrive\mock\cloudformation.json";
			$GLOBAL:LASTEXITCODE | Should Be 43;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
		}
	}
	Context "When template validates successfully" {
		It "Must return exit code 0" {
			Mock Test-Path {return $true} -ParameterFilter { $Path -match "mock\\cloudformation\.json" };
			Mock Invoke-AwsCli {
				"Output from command";
				$GLOBAL:LASTEXITCODE = 0;
			};
			#Setup -File 'mock/cloudformation.json' -Content "AAAAAAAA";
			$result = Invoke-CfnValidation -Template "$TestDrive\mock\cloudformation.json";
			$GLOBAL:LASTEXITCODE | Should Be 0;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
		}
	}
	Context "When template validation fails" {
		It "Must return error code" {
			Mock Test-Path {return $true} -ParameterFilter { $Path -match "mock\\cloudformation\.json" };
			Mock Invoke-AwsCli {
				"Output from command";
				$GLOBAL:LASTEXITCODE = 21;
			};
			#Setup -File 'mock/cloudformation.json' -Content "AAAAAAAA";
			$result = Invoke-CfnValidation -Template "$TestDrive\mock\cloudformation.json";
			$GLOBAL:LASTEXITCODE | Should Be 21;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
		}
	}
}

Describe "Invoke-PesterTests" {
	#$TestFunction = Get-Command -CommandType "Function" -Name "Invoke-PesterTests";
	#Context "When Pester tests pass" {
	#	It "Must return exit code 0" {
	#		Mock Invoke-Pester { return @{ FailedCount = 0 }; }
	#		Setup -File 'mock/tests/ps.tests.ps1';
	#		Setup -File 'mock/scripts/ps.ps1';
	#
	#		$results = Invoke-Command -ScriptBlock $TestFunction.ScriptBlock `
	#			-ArgumentList @("$TestDrive/mock/tests", "$TestDrive/mock/scripts",
	#				"$TestDrive/mock/scripts");
	#	}
	#}
	# Can't test 'Invoke-PesterTests' because it is running these tests
	"Can't test 'Invoke-PesterTests' because it is running these tests" | Write-Warning;
}

Describe "Invoke-NpmTest" {
	Context "When tests exits successfully" {
		It "Must return exit code 0" {
			Mock Invoke-ExternalCommand {
				"Output from command";
				$GLOBAL:LASTEXITCODE = 0;
			};
			$result = Invoke-NpmTest;
			$GLOBAL:LASTEXITCODE | Should Be 0;
			Assert-MockCalled Invoke-ExternalCommand -Exactly -Times 1;
		}
	}
	Context "When tests fail" {
		It "Must return error code" {
			Mock Invoke-ExternalCommand {
				"Output from command";
				$GLOBAL:LASTEXITCODE = 3;
			};
			$result = Invoke-NpmTest;
			$GLOBAL:LASTEXITCODE | Should Be 3;
			Assert-MockCalled Invoke-ExternalCommand -Exactly -Times 1;
		}
	}
	Context "When executing tests" {
		It "Must execute the tests" {
			$expected = "npm run test";
			Mock Invoke-ExternalCommand {
				"Output from command";
				$GLOBAL:INVOKE_EXTERNALCOMMAND_VALUE = "$Command $($Arguments -join " ")";
				$GLOBAL:LASTEXITCODE = 0;
			};
			$result = Invoke-NpmTest;
			$GLOBAL:LASTEXITCODE | Should Be 0;
			$GLOBAL:INVOKE_EXTERNALCOMMAND_VALUE | Should BeExactly $expected;
			Assert-MockCalled Invoke-ExternalCommand -Exactly -Times 1;
		}
	}
}

Describe "Invoke-Tests" {
	Context "When all tests pass" {
		It "Must return exit code 0" {
			Setup -File 'mock/tests/foo.tests.ps1' -Content "A";
			Setup -File 'mock/foo.ps1' -Content "A";
			Setup -File 'mock/cfn-templates/app-cfn.template' -Content "A";
			Setup -File 'mock/cfn-templates/dynamodb-cfn.template' -Content "A";
			Mock Test-Path { return $true; };
			Mock Invoke-PesterTests { return 0; };
			Mock Grant-AWSDeploymentRole { return; };
			Mock Test-TemplateDeployment { return 0; };
			Mock Invoke-NpmTest {return 0;}

			$result = Invoke-Tests -Workspace "$TestDrive\mock" -ProjectName 'project' -IamDeployRoleName "mock-deploy-role";
			$result | Should Be 0;
			Assert-MockCalled Test-Path -Exactly -Times 5;
			Assert-MockCalled Invoke-PesterTests -Exactly -Times 1;
			Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 1;
			Assert-MockCalled Invoke-NpmTest -Exactly -Times 1;
			Assert-MockCalled Test-TemplateDeployment -Exactly -Times 1;
		}
	}

	Context "When pester tests fail" {
		It "Must return error code" {
			Setup -File 'mock/tests/foo.tests.ps1' -Content "A";
			Setup -File 'mock/foo.ps1' -Content "A";
			Setup -File 'mock/cfn-templates/app-cfn.template' -Content "A";
			Setup -File 'mock/cfn-templates/dynamodb-cfn.template' -Content "A";
			Mock Test-Path { return $true; };
			Mock Invoke-PesterTests { return 96; };
			Mock Test-TemplateDeployment { return 0; };
			Mock Grant-AWSDeploymentRole { return; };
			Mock Invoke-NpmTest {return 0;}

			$result = Invoke-Tests -Workspace "$TestDrive\mock" -ProjectName 'project' -IamDeployRoleName "mock-deploy-role";
			$result | Should Be 96;
			Assert-MockCalled Test-Path -Exactly -Times 4;
			Assert-MockCalled Invoke-PesterTests -Exactly -Times 1;
			Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 0;
			Assert-MockCalled Invoke-NpmTest -Exactly -Times 0;
			Assert-MockCalled Test-TemplateDeployment -Exactly -Times 0;
		}
	}

	Context "When CfnValidation tests fail" {
		It "Must return error code" {
			Setup -File 'mock/tests/foo.tests.ps1' -Content "A";
			Setup -File 'mock/foo.ps1' -Content "A";
			Setup -File 'mock/cfn-templates/app-cfn.template' -Content "A";
			Mock Test-Path { return $true; };
			Mock Invoke-PesterTests { return 0; };
			Mock Grant-AWSDeploymentRole { return; };
			Mock Test-TemplateDeployment { return 2; };
			Mock Invoke-NpmTest {return 0;}

			$result = Invoke-Tests -Workspace "$TestDrive\mock" -ProjectName 'project' -IamDeployRoleName "mock-deploy-role";
			$result | Should Be 2;
			Assert-MockCalled Test-Path -Exactly -Times 5;
			Assert-MockCalled Invoke-PesterTests -Exactly -Times 1;
			Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 1;
			Assert-MockCalled Test-TemplateDeployment -Exactly -Times 1;
			Assert-MockCalled Invoke-NpmTest -Exactly -Times 0;
		}
	}

	Context "When mocha tests fail" {
		It "Must return error code" {
			Setup -File 'mock/tests/foo.tests.ps1' -Content "A";
			Setup -File 'mock/foo.ps1' -Content "A";
			Setup -File 'mock/cfn-templates/app-cfn.template' -Content "A";
			Setup -File 'mock/cfn-templates/dynamodb-cfn.template' -Content "A";
			Mock Test-Path { return $true; };
			Mock Invoke-PesterTests { return 0; };
			Mock Test-TemplateDeployment { return 0; };
			Mock Grant-AWSDeploymentRole { return; };
			Mock Invoke-NpmTest {return 9;}

			$result = Invoke-Tests -Workspace "$TestDrive\mock" -ProjectName 'project' -IamDeployRoleName "mock-deploy-role";
			$result | Should Be 9;
			Assert-MockCalled Test-Path -Exactly -Times 5;
			Assert-MockCalled Invoke-PesterTests -Exactly -Times 1;
			Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 1;
			Assert-MockCalled Test-TemplateDeployment -Exactly -Times 1;
			Assert-MockCalled Invoke-NpmTest -Exactly -Times 1;
		}
	}

	Context "When assume role fails" {
		It "Must log exception and return 255" {
			Setup -File 'mock/tests/foo.tests.ps1' -Content "A";
			Setup -File 'mock/foo.ps1' -Content "A";
			Setup -File 'mock/cfn-templates/app-cfn.template' -Content "A";
			Setup -File 'mock/cfn-templates/dynamodb-cfn.template' -Content "A";
			Mock Test-Path { return $true; };
			Mock Invoke-PesterTests { return 0; };
			Mock Grant-AWSDeploymentRole { throw "assume-role exited with error code: 42"; };
			Mock Test-TemplateDeployment { return 0; };
			Mock Invoke-NpmTest {return 0;}
			Mock Write-Warning {
				$GLOBAL:START_TESTS_WRITE_ERROR = $Message;
			}
			$result = Invoke-Tests -Workspace "$TestDrive\mock" -ProjectName 'project' -IamDeployRoleName "mock-deploy-role";
			$result | Should Be 255;
			$GLOBAL:START_TESTS_WRITE_ERROR | Should BeExactly "assume-role exited with error code: 42";
			Assert-MockCalled Test-Path -Exactly -Times 4;
			Assert-MockCalled Invoke-PesterTests -Exactly -Times 1;
			Assert-MockCalled Grant-AWSDeploymentRole -Exactly -Times 1;
			Assert-MockCalled Test-TemplateDeployment -Exactly -Times 0;
			Assert-MockCalled Invoke-NpmTest -Exactly -Times 0;
		}
	}
}
