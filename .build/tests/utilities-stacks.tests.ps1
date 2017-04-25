if($PSCommandPath -eq $null) {
	$CommandRootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path);
} else {
	$CommandRootPath = (Split-Path -Parent $PSCommandPath);
}

."$(Join-Path -Path $CommandRootPath -ChildPath "../utilities.ps1")" -Path .;

Describe "Test-StackExists" {
  Context "When stack does exist" {
    It "Must return true" {
      Mock Invoke-AwsCli {
				$GLOBAL:LASTEXITCODE = 0;
				"Output from command";
			} -ParameterFilter { $Command -eq "cloudformation" -and $Action -eq "describe-stacks"};
			Mock Write-Host { return; };
      Test-StackExists -StackName "aero-mock-stack" | Should Be $true;
      Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
    }
  }
  Context "When stack does not exist" {
    It "Must return false" {
      Mock Invoke-AwsCli {
				$GLOBAL:LASTEXITCODE = 10;
				"Output from command";
			} -ParameterFilter { $Command -eq "cloudformation" -and $Action -eq "describe-stacks"};
			Mock Write-Host { return; };
      Test-StackExists -StackName "aero-mock-stack" | Should Be $false;
      Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
    }
  }
}

Describe "Remove-Stack" {
  Context "When stack exists and is deleted successfully" {
    It "Must return 0" {
      Mock Get-AWSAccountId { return "123456789" };
      Mock Invoke-AwsCli {
				$GLOBAL:LASTEXITCODE = 0;
				"Output from command";
			} -ParameterFilter { $Command -eq "cloudformation" -and $Action -eq "delete-stack"};
      Mock Invoke-AwsCli {
				$GLOBAL:LASTEXITCODE = 0;
				"Output from command";
			} -ParameterFilter { $Command -eq "cloudformation" -and $Action -eq "wait"};
			Mock Write-Host { return; };
      Remove-Stack -StackName "aero-mock-stack" | Should Be 0;
    }
  }
  Context "When stack validation fails" {
    It "Must return failure exit code" {
      Mock Get-AWSAccountId { return "123456789" };
      Mock Invoke-AwsCli {
				$GLOBAL:LASTEXITCODE = 34;
				"Output from command";
			} -ParameterFilter { $Command -eq "cloudformation" -and $Action -eq "delete-stack"};
      Mock Invoke-AwsCli {
				$GLOBAL:LASTEXITCODE = 0;
				"Output from command";
			} -ParameterFilter { $Command -eq "cloudformation" -and $Action -eq "wait"};
			Mock Write-Host { return; };
      Remove-Stack -StackName "aero-mock-stack" | Should Be 34;
      Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
      Assert-MockCalled Get-AWSAccountId -Exactly -Times 1;
    }
  }
  Context "When stack exists and fails to delete" {
    It "Must return failure exit code" {
      Mock Get-AWSAccountId { return "123456789" };
      Mock Invoke-AwsCli {
				$GLOBAL:LASTEXITCODE = 0;
				"Output from command";
			} -ParameterFilter { $Command -eq "cloudformation" -and $Action -eq "delete-stack"};
      Mock Invoke-AwsCli {
				$GLOBAL:LASTEXITCODE = 124;
				"Output from command";
			} -ParameterFilter { $Command -eq "cloudformation" -and $Action -eq "wait"};
			Mock Write-Host { return; };
      Remove-Stack -StackName "aero-mock-stack" | Should Be 124;
      Assert-MockCalled Invoke-AwsCli -Exactly -Times 2;
      Assert-MockCalled Get-AWSAccountId -Exactly -Times 1;
    }
  }
}

Describe "Update-Stack" {
	Context "When has parameters" {
		It "Must convert them to valid JSON" {
			$expectedJson = "[{`"ParameterKey`":`"MockKeyName1`",`"ParameterValue`":`"mock-key-value-1`"},{`"ParameterKey`":`"MockKeyName2`",`"ParameterValue`":`"mock-key-value-2`"}]";
			$expectedObject = $expectedJson | ConvertFrom-Json;
			$xparams = @(@{
					ParameterKey = "MockKeyName1";
					ParameterValue = "mock-key-value-1";
				}, @{
					ParameterKey = "MockKeyName2";
					ParameterValue = "mock-key-value-2";
				}
			);
			$stackName = "mock-stack";
			Setup -File "mock/cfn.template" -Content "---";
			Mock Invoke-AwsCli {
				"Some output of the cli";
				$GLOBAL:LASTEXITCODE = 0;
			};
			Mock Get-Location {
				return $TestDrive;
			}

			Mock Write-Host { return; };

			$result = Update-Stack -StackName $stackName -CloudFormationTemplate "file://$TestDrive/mock/cfn.template" -StackParameters $xparams;
			$xparamsJson = $xparams | ConvertTo-JSON -Compress;
			$xparamsJson | Should BeExactly $expectedJson;
			$xparams.Count | Should Be $expectedObject.Count;
			$GLOBAL:LASTEXITCODE | Should Be 0;
			$xparams[0].ParameterKey | Should Be $expectedObject[0].ParameterKey
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 2;
			Assert-MockCalled Get-Location -Exactly -Times 1;

		}
	}
	Context "When command fails" {
		It "Must return the error" {
			$expectedJson = "[{`"ParameterKey`":`"MockKeyName1`",`"ParameterValue`":`"mock-key-value-1`"},{`"ParameterKey`":`"MockKeyName2`",`"ParameterValue`":`"mock-key-value-2`"}]";
			$expectedObject = $expectedJson | ConvertFrom-Json;
			$xparams = @(@{
					ParameterKey = "MockKeyName1";
					ParameterValue = "mock-key-value-1";
				}, @{
					ParameterKey = "MockKeyName2";
					ParameterValue = "mock-key-value-2";
				}
			);
			$stackName = "mock-stack";
			Setup -File "mock/cfn.template" -Content "---";
			Mock Invoke-AwsCli {
				"Error: Doing something wrong";
				$GLOBAL:LASTEXITCODE = 3;
			} -ParameterFilter { $Action -eq "update-stack"; };
			Mock Get-Location {
				return $TestDrive;
			}

			Mock Invoke-AwsCli {
				"Some output of the cli";
				$GLOBAL:LASTEXITCODE = 0;
			};
			Mock Write-Host { return; };

			$result = Update-Stack -StackName $stackName -CloudFormationTemplate "file://$TestDrive/mock/cfn.template" -StackParameters $xparams;
			$GLOBAL:LASTEXITCODE | Should Be 3;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
			Assert-MockCalled Get-Location -Exactly -Times 1;

		}
	}

	Context "When wait command fails" {
		It "Must return the error" {
			$expectedJson = "[{`"ParameterKey`":`"MockKeyName1`",`"ParameterValue`":`"mock-key-value-1`"},{`"ParameterKey`":`"MockKeyName2`",`"ParameterValue`":`"mock-key-value-2`"}]";
			$expectedObject = $expectedJson | ConvertFrom-Json;
			$xparams = @(@{
					ParameterKey = "MockKeyName1";
					ParameterValue = "mock-key-value-1";
				}, @{
					ParameterKey = "MockKeyName2";
					ParameterValue = "mock-key-value-2";
				}
			);
			$stackName = "mock-stack";
			Setup -File "mock/cfn.template" -Content "---";
			Mock Invoke-AwsCli {
				"Error: Doing something wrong";
				$GLOBAL:LASTEXITCODE = 3;
			} -ParameterFilter { $Action -eq "wait"; };
			Mock Get-Location {
				return $TestDrive;
			}

			Mock Invoke-AwsCli {
				"Some output of the cli";
				$GLOBAL:LASTEXITCODE = 0;
			};
			Mock Write-Host { return; };

			$result = Update-Stack -StackName $stackName -CloudFormationTemplate "file://$TestDrive/mock/cfn.template" -StackParameters $xparams;
			$GLOBAL:LASTEXITCODE | Should Be 3;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 2;
			Assert-MockCalled Get-Location -Exactly -Times 1;

		}
	}

	Context "When no update performed in update" {
		It "Must return success" {
			$expectedJson = "[{`"ParameterKey`":`"MockKeyName1`",`"ParameterValue`":`"mock-key-value-1`"},{`"ParameterKey`":`"MockKeyName2`",`"ParameterValue`":`"mock-key-value-2`"}]";
			$expectedObject = $expectedJson | ConvertFrom-Json;
			$xparams = @(@{
					ParameterKey = "MockKeyName1";
					ParameterValue = "mock-key-value-1";
				}, @{
					ParameterKey = "MockKeyName2";
					ParameterValue = "mock-key-value-2";
				}
			);
			$stackName = "mock-stack";
			Setup -File "mock/cfn.template" -Content "---";
			Mock Invoke-AwsCli {
				"An error occurred (ValidationError) when calling the UpdateStack operation: No updates are to be performed.";
				$GLOBAL:LASTEXITCODE = 3;
			} -ParameterFilter { $Action -eq 'update-stack' };
			Mock Invoke-AwsCli {
				"An error occurred (ValidationError) when calling the UpdateStack operation: No updates are to be performed.";
				$GLOBAL:LASTEXITCODE = 3;
			} -ParameterFilter { $Action -eq 'wait' };
			Mock Get-Location {
				return $TestDrive;
			}

			Mock Write-Host { return; };

			$result = Update-Stack -StackName $stackName -CloudFormationTemplate "file://$TestDrive/mock/cfn.template" -StackParameters $xparams;
			$result | Should Be 0;
			$GLOBAL:LASTEXITCODE | Should Be 3;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
			Assert-MockCalled Get-Location -Exactly -Times 1;

		}
	}

	Context "When no update performed in update when text has line breaks" {
		It "Must return success" {
			$expectedJson = "[{`"ParameterKey`":`"MockKeyName1`",`"ParameterValue`":`"mock-key-value-1`"},{`"ParameterKey`":`"MockKeyName2`",`"ParameterValue`":`"mock-key-value-2`"}]";
			$expectedObject = $expectedJson | ConvertFrom-Json;
			$xparams = @(@{
					ParameterKey = "MockKeyName1";
					ParameterValue = "mock-key-value-1";
				}, @{
					ParameterKey = "MockKeyName2";
					ParameterValue = "mock-key-value-2";
				}
			);
			$stackName = "mock-stack";
			Setup -File "mock/cfn.template" -Content "---";
			Mock Invoke-AwsCli {
				"An error occurred (ValidationError) when calling the UpdateStack operation: No`nupdates are to be performed.";
				$GLOBAL:LASTEXITCODE = 3;
			};
			Mock Get-Location {
				return $TestDrive;
			}

			Mock Write-Host { return; };

			$result = Update-Stack -StackName $stackName -CloudFormationTemplate "file://$TestDrive/mock/cfn.template" -StackParameters $xparams;
			$GLOBAL:LASTEXITCODE | Should Be 3;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
			Assert-MockCalled Get-Location -Exactly -Times 1;

		}
	}

	Context "When has no parameters" {
		It "Must not create the parameters file" {
			$stackName = "mock-project-stack";
			Setup -File "mock/cfn.template" -Content "---";
			Mock Invoke-AwsCli {
				"waiting for complete.";
				$GLOBAL:LASTEXITCODE = 0;
			} -ParameterFilter { $Action -eq "wait"; };
			Mock Invoke-AwsCli {
				"Some output of the cli";
				$GLOBAL:LASTEXITCODE = 0;
			};
			Mock Get-Location {
				return $TestDrive;
			}
			Mock Write-Host { return; };
			Mock Out-ToFile { throw "Should not be called when no parameters"; };
			$result = Update-Stack -StackName $stackName -CloudFormationTemplate "file://$TestDrive/mock/cfn.template";
			$GLOBAL:LASTEXITCODE | Should Be 0;
			$result | Should Be 0;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 2;
			Assert-MockCalled Get-Location -Exactly -Times 0;
			Assert-MockCalled Out-ToFile -Exactly -Times 0;
		}
	}
}

Describe "Create-Stack" {
	Context "When parameters have line breaks" {
		It "Must remove them to pass valid json" {
			$appParamsObject = @(@{
					ParameterKey = "LambdaFunctionName";
					ParameterValue = "mock-dev-project-branch";
				}, @{
					ParameterKey = "ProxyApiStageName";
					ParameterValue = "latest"
				}, @{
					ParameterKey = "IAMLambdaRole";
					ParameterValue = "mock-project-executor"
				}, @{
					ParameterKey = "LambdaCodePackage";
					ParameterValue = "fileb://$($TestDrive -replace "\\", "/")/mock/project/dist-pkgs/project-1.0.0-snapshot.zip"
				});
			$expectedJson = "[{`"ParameterKey`":`"LambdaFunctionName`",`"ParameterValue`":`"" `
				+ "mock-dev-project-branch`"},{`"ParameterKey`":`"ProxyApiStageName`",`"ParameterValue`":`"latest`"}," `
				+ "{`"ParameterKey`":`"IAMLambdaRole`",`"ParameterValue`":`"mock-project-executor`"}," `
				+ "{`"ParameterKey`":`"LambdaCodePackage`",`"ParameterValue`":`"fileb://$($TestDrive -replace "\\", "/")/mock/project/dist-pkgs/project-1.0.0-snapshot.zip`"}]";

			$stackName = "mock-stack";
			Setup -File "mock/project/cfn.template" -Content "---";
			Mock Invoke-AwsCli {
				"Some output of the cli";
				$GLOBAL:LASTEXITCODE = 0;
			};
			Mock Get-Location {
				return $TestDrive;
			}
			Mock Write-Host { return; };
			$result = Create-Stack -StackName $stackName -CloudFormationTemplate "file://$TestDrive/mock/project/cfn.template" -StackParameters $appParamsObject;
			$appParamsObject | ConvertTo-JSON -Compress | Should Be $expectedJson;
			$result | Should Be 0;

			Assert-MockCalled Invoke-AwsCli -Exactly -Times 2;
			Assert-MockCalled Get-Location -Exactly -Times 1;
		}
	}
	Context "When has parameters" {
		It "Must convert them to valid JSON" {
			$expectedJson = "[{`"ParameterKey`":`"MockKeyName1`",`"ParameterValue`":`"mock-key-value-1`"},{`"ParameterKey`":`"MockKeyName2`",`"ParameterValue`":`"mock-key-value-2`"}]";
			$expectedObject = $expectedJson | ConvertFrom-Json;
			$xparams = @(@{
					ParameterKey = "MockKeyName1";
					ParameterValue = "mock-key-value-1";
				}, @{
					ParameterKey = "MockKeyName2";
					ParameterValue = "mock-key-value-2";
				}
			);
			$stackName = "mock-stack";
			Setup -File "mock/cfn.template" -Content "---";
			Mock Invoke-AwsCli {
				"Some output of the cli";
				$GLOBAL:LASTEXITCODE = 0;
			};
			Mock Get-Location {
				return $TestDrive;
			}
			Mock Write-Host { return; };

			$result = Create-Stack -StackName $stackName -CloudFormationTemplate "file://$TestDrive/mock/cfn.template" -StackParameters $xparams;
			$result | Should Be 0;
			$xparamsJson = $xparams | ConvertTo-JSON -Compress;
			$xparamsJson | Should BeExactly $expectedJson;
			$xparams.Count | Should Be $expectedObject.Count;
			$xparams[0].ParameterKey | Should Be $expectedObject[0].ParameterKey
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 2;
			Assert-MockCalled Get-Location -Exactly -Times 1;
		}
	}
	Context "When command fails" {
		It "Must return the error" {
			$expectedJson = "[{`"ParameterKey`":`"MockKeyName1`",`"ParameterValue`":`"mock-key-value-1`"},{`"ParameterKey`":`"MockKeyName2`",`"ParameterValue`":`"mock-key-value-2`"}]";
			$expectedObject = $expectedJson | ConvertFrom-Json;
			$xparams = @(@{
					ParameterKey = "MockKeyName1";
					ParameterValue = "mock-key-value-1";
				}, @{
					ParameterKey = "MockKeyName2";
					ParameterValue = "mock-key-value-2";
				}
			);
			$stackName = "mock-stack";
			Setup -File "mock/cfn.template" -Content "---";
			Mock Invoke-AwsCli {
				"Error: Doing something wrong";
				$GLOBAL:LASTEXITCODE = 3;
			} -ParameterFilter { $Action -eq "create-stack"; };
			Mock Invoke-AwsCli {
				"Some output of the cli";
				$GLOBAL:LASTEXITCODE = 0;
			};
			Mock Get-Location {
				return $TestDrive;
			}
			Mock Write-Host { return; };

			$result = Create-Stack -StackName $stackName -CloudFormationTemplate "file://$TestDrive/mock/cfn.template" -StackParameters $xparams;
			$result | Should Be 3;
			$GLOBAL:LASTEXITCODE | Should Be 3;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
			Assert-MockCalled Get-Location -Exactly -Times 1;
		}
	}

	Context "When has no parameters" {
		It "Must not create the parameters file" {
			$stackName = "mock-project-stack";
			Setup -File "mock/cfn.template" -Content "---";
			Mock Invoke-AwsCli {
				"waiting for complete.";
				$GLOBAL:LASTEXITCODE = 0;
			} -ParameterFilter { $Action -eq "wait"; };
			Mock Invoke-AwsCli {
				"Some output of the cli";
				$GLOBAL:LASTEXITCODE = 0;
			};
			Mock Get-Location {
				return $TestDrive;
			}
			Mock Write-Host { return; };
			Mock Out-ToFile { throw "Should not be called when no parameters"; };
			$result = Create-Stack -StackName $stackName -CloudFormationTemplate "file://$TestDrive/mock/cfn.template";
			$GLOBAL:LASTEXITCODE | Should Be 0;
			$result | Should Be 0;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 2;
			Assert-MockCalled Get-Location -Exactly -Times 0;
			Assert-MockCalled Out-ToFile -Exactly -Times 0;
		}
	}

	Context "When wait command fails" {
		It "Must return the error" {
			$expectedJson = "[{`"ParameterKey`":`"MockKeyName1`",`"ParameterValue`":`"mock-key-value-1`"},{`"ParameterKey`":`"MockKeyName2`",`"ParameterValue`":`"mock-key-value-2`"}]";
			$expectedObject = $expectedJson | ConvertFrom-Json;
			$xparams = @(@{
					ParameterKey = "MockKeyName1";
					ParameterValue = "mock-key-value-1";
				}, @{
					ParameterKey = "MockKeyName2";
					ParameterValue = "mock-key-value-2";
				}
			);
			$stackName = "mock-stack";
			Setup -File "mock/cfn.template" -Content "---";
			Mock Invoke-AwsCli {
				"Error: Doing something wrong";
				$GLOBAL:LASTEXITCODE = 3;
			} -ParameterFilter { $Action -eq "wait"; };
			Mock Invoke-AwsCli {
				"Some output of the cli";
				$GLOBAL:LASTEXITCODE = 0;
			};
			Mock Get-Location {
				return $TestDrive;
			}
			Mock Write-Host { return; };

			$result = Create-Stack -StackName $stackName -CloudFormationTemplate "file://$TestDrive/mock/cfn.template" -StackParameters $xparams;
			$GLOBAL:LASTEXITCODE | Should Be 3;
			$result | Should Be 3;
			Assert-MockCalled Invoke-AwsCli -Exactly -Times 2;
			Assert-MockCalled Get-Location -Exactly -Times 1;
		}
	}
}

Describe "Invoke-StackCreateOrUpdate" {
	Context "When Stack does exist" {
		It "Must run update stack" {
			Mock Test-StackExists { return $true; };
			Mock Update-Stack { return 0; };
			Mock Create-Stack { return 300; };
			$xparams = @(@{
				ParameterKey = "mock-key-1";
				ParameterValue = "mock-value-1"
			});
			$result = Invoke-StackCreateOrUpdate -StackName 'mock-stack' -TemplateUri "file://$TestDrive/mock/cloudformation.json" -StackParameters $xparams;
			$result | Should Be 0;
			Assert-MockCalled Update-Stack -Exactly -Times 1;
			Assert-MockCalled Create-Stack -Exactly -Times 0;
			Assert-MockCalled Test-StackExists -Exactly -Times 1;
		}
	}
	Context "When Stack Exists and fails to update" {
		It "Must return error code" {
			Mock Test-StackExists { return $true; };
			Mock Update-Stack { return 96; };
			Mock Create-Stack { return 300; };
			$xparams = @(@{
				ParameterKey = "mock-key-1";
				ParameterValue = "mock-value-1"
			});
			$result = Invoke-StackCreateOrUpdate -StackName 'mock-stack' -TemplateUri "file://$TestDrive/mock/cloudformation.json" -StackParameters $xparams;
			$result | Should Be 96;
			Assert-MockCalled Update-Stack -Exactly -Times 1;
			Assert-MockCalled Create-Stack -Exactly -Times 0;
			Assert-MockCalled Test-StackExists -Exactly -Times 1;
		}
	}
	Context "When Stack does not exist" {
		It "Must run create stack" {
			Mock Test-StackExists { return $false; };
			Mock Update-Stack { return 300; };
			Mock Create-Stack { return 0; };
			$xparams = @(@{
				ParameterKey = "mock-key-1";
				ParameterValue = "mock-value-1"
			});
			$result = Invoke-StackCreateOrUpdate -StackName 'mock-stack' -TemplateUri "file://$TestDrive/mock/cloudformation.json" -StackParameters $xparams;
			$result | Should Be 0;
			Assert-MockCalled Update-Stack -Exactly -Times 0;
			Assert-MockCalled Create-Stack -Exactly -Times 1;
			Assert-MockCalled Test-StackExists -Exactly -Times 1;
		}
	}
	Context "When Stack does not exist and fails to create" {
		It "Must return error code" {
			Mock Test-StackExists { return $false; };
			Mock Update-Stack { return 0; };
			Mock Create-Stack { return 124; };
			$xparams = @(@{
				ParameterKey = "mock-key-1";
				ParameterValue = "mock-value-1"
			});
			$result = Invoke-StackCreateOrUpdate -StackName 'mock-stack' -TemplateUri "file://$TestDrive/mock/cloudformation.json" -StackParameters $xparams;
			$result | Should Be 124;
			Assert-MockCalled Update-Stack -Exactly -Times 0;
			Assert-MockCalled Create-Stack -Exactly -Times 1;
			Assert-MockCalled Test-StackExists -Exactly -Times 1;
		}
	}
}


Describe "Invoke-TemplateDeployment" {
	Context "When there are no templates" {
		It "Must exit successfully" {
			Mock Save-TransformedContent { return 0; };
			Mock Invoke-StackCreateOrUpdate { return 0; };
			Mock ConvertTo-CliArrayParameters { return @(); };
			$templates = @();
			$result = Invoke-TemplateDeployment -Templates $templates;
			$result | Should Be 0;

			Assert-MockCalled Save-TransformedContent -Exactly -Times 0;
			Assert-MockCalled Invoke-StackCreateOrUpdate -Exactly -Times 0;
			Assert-MockCalled ConvertTo-CliArrayParameters -Exactly -Times 0;
		}
	}


	Context "When there are 3 templates and one fails on Save-TransformedContent" {
		It "Must exit with error" {
			Mock Save-TransformedContent { return 125; } -ParameterFilter { $InputFile -match "app-cfn\.template"};
			Mock Save-TransformedContent { return 0; };
			Mock Invoke-StackCreateOrUpdate { return 0; };
			Mock ConvertTo-CliArrayParameters { return @(); };
			Setup -File 'mock/cfn-templates/app-cfn.template';
			Setup -File 'mock/cfn-templates/db-cfn.yml';
			Setup -File 'mock/cfn-templates/s3-cfn.json';
			$templates = Get-TemplatesToTransform -Path (Join-Path -Path $TestDrive -ChildPath "mock/cfn-templates");
			$result = Invoke-TemplateDeployment -Templates $templates;
			$result | Should Be 125;
			Assert-MockCalled Save-TransformedContent -Exactly -Times 1;
			Assert-MockCalled ConvertTo-CliArrayParameters -Exactly -Times 0;
			Assert-MockCalled Invoke-StackCreateOrUpdate -Exactly -Times 0;
		}
	}

	Context "When there are 3 templates and one fails on Invoke-StackCreateOrUpdate" {
		It "Must exit with error" {
			Mock Save-TransformedContent { return 0; };
			Mock Invoke-StackCreateOrUpdate { return 124; } -ParameterFilter { $TemplateUri -match "[/\\]transformed-app-cfn\.template$"};
			Mock Invoke-StackCreateOrUpdate { return 0; }
			Mock ConvertTo-CliArrayParameters { return @(); };
			Setup -File 'mock/cfn-templates/app-cfn.template';
			Setup -File 'mock/cfn-templates/db-cfn.yml';
			Setup -File 'mock/cfn-templates/s3-cfn.json';
			$templates = Get-TemplatesToTransform -Path (Join-Path -Path $TestDrive -ChildPath "mock/cfn-templates");
			$result = Invoke-TemplateDeployment -Templates $templates;
			$result | Should Be 124;
			Assert-MockCalled Save-TransformedContent -Exactly -Times 1;
			Assert-MockCalled Invoke-StackCreateOrUpdate -Exactly -Times 1;
			Assert-MockCalled ConvertTo-CliArrayParameters -Exactly -Times 1;
		}
	}

	Context "When template has config file" {
		It "Must use the data in the config" {
			Mock Save-TransformedContent { return 0; };
			Mock Invoke-StackCreateOrUpdate { return 0; } -ParameterFilter { $StackName -eq "mock-project-stack"; };
			Mock Invoke-StackCreateOrUpdate {
				Write-Warning "THIS SHOULD NOT BE INVOKED: $StackName";
				return 255;
			}
			Mock ConvertTo-CliArrayParameters { return @(); };
			Setup -File 'mock/cfn-templates/app-cfn.template';
			Setup -File 'mock/cfn-templates/app-cfn.ps1' -Content "@{ StackName = 'mock-project-stack'; }";
			$templates = Get-TemplatesToTransform -Path (Join-Path -Path $TestDrive -ChildPath "mock/cfn-templates");
			$result = Invoke-TemplateDeployment -Templates $templates;
			$result | Should Be 0;
			Assert-MockCalled Save-TransformedContent -Exactly -Times 1;
			Assert-MockCalled Invoke-StackCreateOrUpdate -Exactly -Times 1;
			Assert-MockCalled ConvertTo-CliArrayParameters -Exactly -Times 1;
		}
	}
}

Describe "Test-TemplateDeployment" {
	Context "When there are no templates" {
		It "Must exit successfully" {
			Mock Save-TransformedContent { return 0; };
			Mock Invoke-CfnValidation { return 0; };
			$templates = @();
			$result = Test-TemplateDeployment -Templates $templates;
			$result | Should Be 0;

			Assert-MockCalled Save-TransformedContent -Exactly -Times 0;
			Assert-MockCalled Invoke-CfnValidation -Exactly -Times 0;
		}
	}

	Context "When there are 3 templates and fails on Save-TransformedContent" {
		It "Must exit with error code" {
			Mock Save-TransformedContent { return 124; } -ParameterFilter { $InputFile -match "[/\\]app-cfn\.template$"};
			Mock Save-TransformedContent {
				Setup -File 'mock/cfn-templates/transformed-app-cfn.template';
				Setup -File 'mock/cfn-templates/transformed-db-cfn.yml';
				Setup -File 'mock/cfn-templates/transformed-s3-cfn.json';

				return 0;
			};
			Mock Invoke-StackCreateOrUpdate { return 0; }
			Setup -File 'mock/cfn-templates/app-cfn.template';
			Setup -File 'mock/cfn-templates/db-cfn.yml';
			Setup -File 'mock/cfn-templates/s3-cfn.json';

			$templates = Get-TemplatesToTransform -Path (Join-Path -Path $TestDrive -ChildPath "mock/cfn-templates");
			$result = Test-TemplateDeployment -Templates $templates;
			$result | Should Be 124;
			Assert-MockCalled Save-TransformedContent -Exactly -Times 1;
			Assert-MockCalled Invoke-CfnValidation -Exactly -Times 0;
		}
	}

	Context "When there are 3 templates and fails on Invoke-CfnValidation" {
		It "Must exit with error code" {
			Mock Save-TransformedContent {
				Setup -File 'mock/cfn-templates/transformed-app-cfn.template';
				Setup -File 'mock/cfn-templates/transformed-db-cfn.yml';
				Setup -File 'mock/cfn-templates/transformed-s3-cfn.json';

				return 0;
			};
			Mock Invoke-CfnValidation { return 124; } -ParameterFilter { $Template -match "[/\\]transformed-app-cfn\.template$"}
			Mock Invoke-CfnValidation { return 0; }
			Setup -File 'mock/cfn-templates/app-cfn.template';
			Setup -File 'mock/cfn-templates/db-cfn.yml';
			Setup -File 'mock/cfn-templates/s3-cfn.json';

			$templates = Get-TemplatesToTransform -Path (Join-Path -Path $TestDrive -ChildPath "mock/cfn-templates");
			$result = Test-TemplateDeployment -Templates $templates;
			$result | Should Be 124;
			Assert-MockCalled Save-TransformedContent -Exactly -Times 1;
			Assert-MockCalled Invoke-CfnValidation -Exactly -Times 1;
		}
	}

	Context "When there are 3 templates and all process successfully" {
		It "Must exit with 0" {
			Mock Save-TransformedContent {
				Setup -File 'mock/cfn-templates/transformed-app-cfn.template';
				Setup -File 'mock/cfn-templates/transformed-db-cfn.yml';
				Setup -File 'mock/cfn-templates/transformed-s3-cfn.json';

				return 0;
			};
			Mock Invoke-CfnValidation { return 0; }
			Setup -File 'mock/cfn-templates/app-cfn.template';
			Setup -File 'mock/cfn-templates/db-cfn.yml';
			Setup -File 'mock/cfn-templates/s3-cfn.json';

			$templates = Get-TemplatesToTransform -Path (Join-Path -Path $TestDrive -ChildPath "mock/cfn-templates");
			$result = Test-TemplateDeployment -Templates $templates;
			$result | Should Be 0;
			Assert-MockCalled Save-TransformedContent -Exactly -Times 3;
			Assert-MockCalled Invoke-CfnValidation -Exactly -Times 3;
		}
	}
}

Describe "ConvertTo-CliArrayParameters" {

	[PSObject]$sample1 = @{
		StackName = "mock-project-stack";
		Parameters = @(
			@{
				ParameterKey = "MockParameterName";
				ParameterValue = "mock-parameter-value";
			}
		);
	};

	[PSObject]$sample2 = @{
		StackName = "mock-project-stack";
		Parameters = @{
				MockParameterName = "mock-parameter-value";
			};
	};

	[PSObject]$sample3 = @{
		StackName = "mock-project-stack";
		Parameters = @(
			@{
				ParameterKey = "MockParameterName1";
				ParameterValue = "mock-parameter-value1";
			},
			@{
				ParameterKey = "MockParameterName2";
				ParameterValue = "mock-parameter-value2";
			}

		);
	};

	[PSObject]$sample4 = @{
		StackName = "mock-project-stack";
		Parameters = @{
			MockParameterName1 = "mock-parameter-value1";
			MockParameterName2 = "mock-parameter-value2";
		};
	};

	Context "When has single value and parameters is already a formatted array" {
		It "Must return the formatted array" {
			[Array]$result = ConvertTo-CliArrayParameters -Parameters $sample1.Parameters;
			$result | Should Not Be $null;
			$result -is [Array] | Should Be $true;
			$result | Should Be $sample1.Parameters;
		}
	}
	Context "When has single value and parameters is a PSCustomObject" {
		It "Must convert the object to the expected parameters array" {
			[Array]$result = ConvertTo-CliArrayParameters -Parameters $sample2.Parameters;
			$result | Should Not Be $null;
			$result -is [Array] | Should Be $true;
			$result.Count | Should Be $sample1.Parameters.Count;
			for($x = 0; $x -lt $sample1.Parameters.Count; $x++) {
				$result[$x].ParameterKey | Should Not Be $null;
				$result[$x].ParameterValue | Should Not Be $null;
			}
		}
	}

	Context "When has multiple values and parameters is already a formatted array" {
		It "Must return the formatted array" {
			[Array]$result = ConvertTo-CliArrayParameters -Parameters $sample3.Parameters;
			$result | Should Not Be $null;
			$result -is [Array] | Should Be $true;
			$result | Should Be $sample3.Parameters;
		}
	}
	Context "When has multiple values and parameters is a PSCustomObject" {
		It "Must convert the object to the expected parameters array" {
			[Array]$result = ConvertTo-CliArrayParameters -Parameters $sample4.Parameters;
			$result | Should Not Be $null;
			$result -is [Array] | Should Be $true;
			$result.Count | Should Be $sample3.Parameters.Count;
			for($x = 0; $x -lt $sample3.Parameters.Count; $x++) {
				$result[$x].ParameterKey | Should Not Be $null;
				$result[$x].ParameterValue | Should Not Be $null;
			}
		}
	}
}
