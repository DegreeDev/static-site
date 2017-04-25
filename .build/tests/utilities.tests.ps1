if($PSCommandPath -eq $null) {
	$CommandRootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path);
} else {
	$CommandRootPath = (Split-Path -Parent $PSCommandPath);
}

."$(Join-Path -Path $CommandRootPath -ChildPath "../utilities.ps1")" -Path .;

Describe "Get-AWSAccountId" {
  Context "When ENV:AWS_ACCOUNT_ID is not set" {
    It "Must throw an error" {
			Mock Write-Host { return; };
      $TEMP_AWS_ACCOUNT_ID = $ENV:AWS_ACCOUNT_ID;
      $ENV:AWS_ACCOUNT_ID = "";
      { Get-AWSAccountId } | Should Throw "AWS_ACCOUNT_ID not present in environment variables.";

      # Restore value
      $ENV:AWS_ACCOUNT_ID = $TEMP_AWS_ACCOUNT_ID;
    }
  }

  Context "When ENV:AWS_ACCOUNT_ID is set" {
    It "Must return the value" {
			Mock Write-Host { return; };
      $TEMP_AWS_ACCOUNT_ID = $ENV:AWS_ACCOUNT_ID;
      $ENV:AWS_ACCOUNT_ID = "mock-account-id";
      $TEMP_AWS_IAM_DEPLOY_ROLE = $ENV:AWS_IAM_DEPLOY_ROLE;
      $ENV:AWS_IAM_DEPLOY_ROLE = "mock-deploy-role";
      Get-AWSAccountId | Should Be "mock-account-id";

      # Restore value
      $ENV:AWS_ACCOUNT_ID = $TEMP_AWS_ACCOUNT_ID;
      $ENV:AWS_IAM_DEPLOY_ROLE = $TEMP_AWS_IAM_DEPLOY_ROLE;
    }
  }
}

Describe "Grant-AWSDeploymentRole" {
  Mock Get-AWSAccountId {
    return "123456789";
  };
  $SuccessAssumeResult = '{
    "AssumedRoleUser": {
      "AssumedRoleId": "MOCK-ASSUME-ROLE-ID:mock-session-name",
      "Arn": "arn:aws:sts::123456789:assumed-role/mock-deploy-role/mock-session-name"
    },
    "Credentials": {
      "SecretAccessKey": "MOCK-SECRET-ACCESS-KEY",
      "SessionToken": "MOCK-SESSION-TOKEN",
      "Expiration": "2017-02-10T21:29:05Z",
      "AccessKeyId": "MOCK-ACCESS-ID"
    }
  }';
	Context "When access key id is not set" {
		It "Must throw exception" {
			$TEMP_AWS_SESSION_TOKEN = $ENV:AWS_SESSION_TOKEN;
			$TEMP_AWS_SESSION_EXPIRATION = $ENV:AWS_SESSION_EXPIRATION;
			$TEMP_AWS_ACCESS_KEY_ID = $ENV:AWS_ACCESS_KEY_ID;
			$TEMP_AWS_SECRET_ACCESS_KEY = $ENV:AWS_SECRET_ACCESS_KEY;

			$FailureAssumeResult = '{
		    "AssumedRoleUser": {
		      "AssumedRoleId": "MOCK-ASSUME-ROLE-ID:mock-session-name",
		      "Arn": "arn:aws:sts::123456789:assumed-role/mock-deploy-role/mock-session-name"
		    },
		    "Credentials": {
		      "SecretAccessKey": "MOCK-SECRET-ACCESS-KEY",
		      "SessionToken": "MOCK-SESSION-TOKEN",
		      "Expiration": "2017-02-10T21:29:05Z"
		    }
		  }';
			Mock Invoke-AwsCli {
				$Global:LASTEXITCODE = 0;
				return $FailureAssumeResult;
			};
			Mock Test-Path { return $false; };
			Mock Remove-Item { return; };
			Mock Write-Host { return; };
			{
				Grant-AWSDeploymentRole -RoleName "mock-deploy-role" -SessionName "mock-session-name"
			} | Should Throw "There was a problem getting the AWS_ACCESS_KEY_ID and storing it for use";

			Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
      Assert-MockCalled Get-AWSAccountId -Exactly -Times 1;
      Assert-MockCalled Remove-Item -Exactly -Times 0;
      Assert-MockCalled Test-Path -Exactly -Times 2;

			# Restore Values
      $ENV:AWS_ACCESS_KEY_ID = $TEMP_AWS_ACCESS_KEY_ID;
      $ENV:AWS_SECRET_ACCESS_KEY = $TEMP_AWS_SECRET_ACCESS_KEY;
      $ENV:AWS_SESSION_TOKEN = $TEMP_AWS_SESSION_TOKEN;
      $ENV:AWS_SESSION_EXPIRATION = $TEMP_AWS_SESSION_EXPIRATION;
		}
	}
	Context "When access key id is not set" {
		It "Must throw exception" {
			$TEMP_AWS_SESSION_TOKEN = $ENV:AWS_SESSION_TOKEN;
			$TEMP_AWS_SESSION_EXPIRATION = $ENV:AWS_SESSION_EXPIRATION;
			$TEMP_AWS_ACCESS_KEY_ID = $ENV:AWS_ACCESS_KEY_ID;
			$TEMP_AWS_SECRET_ACCESS_KEY = $ENV:AWS_SECRET_ACCESS_KEY;

			$FailureAssumeResult = '{
		    "AssumedRoleUser": {
		      "AssumedRoleId": "MOCK-ASSUME-ROLE-ID:mock-session-name",
		      "Arn": "arn:aws:sts::123456789:assumed-role/mock-deploy-role/mock-session-name"
		    },
		    "Credentials": {
		      "SessionToken": "MOCK-SESSION-TOKEN",
		      "Expiration": "2017-02-10T21:29:05Z",
					"AccessKeyId": "MOCK-ACCESS-ID"
		    }
		  }';
			Mock Invoke-AwsCli {
				$Global:LASTEXITCODE = 0;
				return $FailureAssumeResult;
			};
			Mock Test-Path { return $false; };
			Mock Remove-Item { return; };
			Mock Write-Host { return; };
			{
				Grant-AWSDeploymentRole -RoleName "mock-deploy-role" -SessionName "mock-session-name"
			} | Should Throw "There was a problem getting the AWS_SECRET_ACCESS_KEY and storing it for use";

			Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
      Assert-MockCalled Get-AWSAccountId -Exactly -Times 1;
      Assert-MockCalled Remove-Item -Exactly -Times 0;
      Assert-MockCalled Test-Path -Exactly -Times 2;

			# Restore Values
      $ENV:AWS_ACCESS_KEY_ID = $TEMP_AWS_ACCESS_KEY_ID;
      $ENV:AWS_SECRET_ACCESS_KEY = $TEMP_AWS_SECRET_ACCESS_KEY;
      $ENV:AWS_SESSION_TOKEN = $TEMP_AWS_SESSION_TOKEN;
      $ENV:AWS_SESSION_EXPIRATION = $TEMP_AWS_SESSION_EXPIRATION;
		}
	}
	Context "When access key id is not set" {
		It "Must throw exception" {
			$TEMP_AWS_SESSION_TOKEN = $ENV:AWS_SESSION_TOKEN;
			$TEMP_AWS_SESSION_EXPIRATION = $ENV:AWS_SESSION_EXPIRATION;
			$TEMP_AWS_ACCESS_KEY_ID = $ENV:AWS_ACCESS_KEY_ID;
			$TEMP_AWS_SECRET_ACCESS_KEY = $ENV:AWS_SECRET_ACCESS_KEY;

			$FailureAssumeResult = '{
		    "AssumedRoleUser": {
		      "AssumedRoleId": "MOCK-ASSUME-ROLE-ID:mock-session-name",
		      "Arn": "arn:aws:sts::123456789:assumed-role/mock-deploy-role/mock-session-name"
		    },
		    "Credentials": {
					"SecretAccessKey": "MOCK-SECRET-ACCESS-KEY",
		      "Expiration": "2017-02-10T21:29:05Z",
					"AccessKeyId": "MOCK-ACCESS-ID"
		    }
		  }';
			Mock Invoke-AwsCli {
				$Global:LASTEXITCODE = 0;
				return $FailureAssumeResult;
			};
			Mock Test-Path { return $false; };
			Mock Remove-Item { return; };
			Mock Write-Host { return; };
			{
				Grant-AWSDeploymentRole -RoleName "mock-deploy-role" -SessionName "mock-session-name"
			} | Should Throw "There was a problem getting the AWS_SESSION_TOKEN and storing it for use";

			Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
      Assert-MockCalled Get-AWSAccountId -Exactly -Times 1;
      Assert-MockCalled Remove-Item -Exactly -Times 0;
      Assert-MockCalled Test-Path -Exactly -Times 2;

			# Restore Values
      $ENV:AWS_ACCESS_KEY_ID = $TEMP_AWS_ACCESS_KEY_ID;
      $ENV:AWS_SECRET_ACCESS_KEY = $TEMP_AWS_SECRET_ACCESS_KEY;
      $ENV:AWS_SESSION_TOKEN = $TEMP_AWS_SESSION_TOKEN;
      $ENV:AWS_SESSION_EXPIRATION = $TEMP_AWS_SESSION_EXPIRATION;
		}
	}
	Context "When access key id is not set" {
		It "Must throw exception" {
			$TEMP_AWS_SESSION_TOKEN = $ENV:AWS_SESSION_TOKEN;
			$TEMP_AWS_SESSION_EXPIRATION = $ENV:AWS_SESSION_EXPIRATION;
			$TEMP_AWS_ACCESS_KEY_ID = $ENV:AWS_ACCESS_KEY_ID;
			$TEMP_AWS_SECRET_ACCESS_KEY = $ENV:AWS_SECRET_ACCESS_KEY;

			$FailureAssumeResult = '{
		    "AssumedRoleUser": {
		      "AssumedRoleId": "MOCK-ASSUME-ROLE-ID:mock-session-name",
		      "Arn": "arn:aws:sts::123456789:assumed-role/mock-deploy-role/mock-session-name"
		    },
		    "Credentials": {
					"SecretAccessKey": "MOCK-SECRET-ACCESS-KEY",
					"SessionToken": "MOCK-SESSION-TOKEN",
					"AccessKeyId": "MOCK-ACCESS-ID"
		    }
		  }';
			Mock Invoke-AwsCli {
				$Global:LASTEXITCODE = 0;
				return $FailureAssumeResult;
			};
			Mock Test-Path { return $false; };
			Mock Remove-Item { return; };
			Mock Write-Host { return; };
			{
				Grant-AWSDeploymentRole -RoleName "mock-deploy-role" -SessionName "mock-session-name"
			} | Should Throw "There was a problem getting the AWS_SESSION_EXPIRATION and storing it for use";

			Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
      Assert-MockCalled Get-AWSAccountId -Exactly -Times 1;
      Assert-MockCalled Remove-Item -Exactly -Times 0;
      Assert-MockCalled Test-Path -Exactly -Times 2;

			# Restore Values
      $ENV:AWS_ACCESS_KEY_ID = $TEMP_AWS_ACCESS_KEY_ID;
      $ENV:AWS_SECRET_ACCESS_KEY = $TEMP_AWS_SECRET_ACCESS_KEY;
      $ENV:AWS_SESSION_TOKEN = $TEMP_AWS_SESSION_TOKEN;
      $ENV:AWS_SESSION_EXPIRATION = $TEMP_AWS_SESSION_EXPIRATION;
		}
	}
  Context "When assuming role fails" {
    It "Must throw error" {
      Mock Invoke-AwsCli {
        $Global:LASTEXITCODE = 25;
        return "{}";
      };
      Mock Test-Path { return $false; };
      Mock Remove-Item { return; };
      Mock Write-Host { return; };
      { Grant-AWSDeploymentRole -RoleName "mock-deploy-role" -SessionName "mock-session-name" } | Should Throw "assume-role exited with error code: 25";
      $Global:LASTEXITCODE | Should Be 25;
      Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
      Assert-MockCalled Get-AWSAccountId -Exactly -Times 1;
      Assert-MockCalled Remove-Item -Exactly -Times 0;
      Assert-MockCalled Test-Path -Exactly -Times 2;

    }
  }


  Context "When environment already has values" {
    It "Must remove the items" {

      $TEMP_AWS_SESSION_TOKEN = $ENV:AWS_SESSION_TOKEN;
      $TEMP_AWS_SESSION_EXPIRATION = $ENV:AWS_SESSION_EXPIRATION;
      $TEMP_AWS_ACCESS_KEY_ID = $ENV:AWS_ACCESS_KEY_ID;
      $TEMP_AWS_SECRET_ACCESS_KEY = $ENV:AWS_SECRET_ACCESS_KEY;

      Mock Invoke-AwsCli {
        $Global:LASTEXITCODE = 0;
        $SuccessAssumeResult;
      };
      Mock Test-Path { return $true; };
      Mock Remove-Item { return; };
      Mock Write-Host { return; };

      $expected = $SuccessAssumeResult | ConvertFrom-Json;

      $ENV:AWS_SESSION_TOKEN = "MOCK-SESSION-TOKEN";
      $ENV:AWS_SESSION_EXPIRATION = "MOCK-SESSION-EXPIRATION";

      $result = Grant-AWSDeploymentRole -RoleName "mock-deploy-role" -SessionName "mock-session-name";
      $result | Should Not Be $null;
      $result[0].Credentials.AccessKeyId | Should BeExactly $expected.Credentials.AccessKeyId;
      $ENV:AWS_ACCESS_KEY_ID | Should BeExactly $expected.Credentials.AccessKeyId;
      $result[0].Credentials.SecretAccessKey | Should BeExactly $expected.Credentials.SecretAccessKey;
      $ENV:AWS_SECRET_ACCESS_KEY | Should BeExactly $expected.Credentials.SecretAccessKey;
      $result[0].Credentials.SessionToken | Should BeExactly $expected.Credentials.SessionToken;
      $ENV:AWS_SESSION_TOKEN | Should BeExactly $expected.Credentials.SessionToken;
      $result[0].Credentials.Expiration | Should BeExactly $expected.Credentials.Expiration;
      $ENV:AWS_SESSION_EXPIRATION | Should BeExactly $expected.Credentials.Expiration;

      $Global:LASTEXITCODE | Should Be 0;

      Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
      Assert-MockCalled Get-AWSAccountId -Exactly -Times 1;
      Assert-MockCalled Remove-Item -Exactly -Times 2;
      Assert-MockCalled Test-Path -Exactly -Times 2;

      # Restore Values
      $ENV:AWS_ACCESS_KEY_ID = $TEMP_AWS_ACCESS_KEY_ID;
      $ENV:AWS_SECRET_ACCESS_KEY = $TEMP_AWS_SECRET_ACCESS_KEY;
      $ENV:AWS_SESSION_TOKEN = $TEMP_AWS_SESSION_TOKEN;
      $ENV:AWS_SESSION_EXPIRATION = $TEMP_AWS_SESSION_EXPIRATION;
    }
  }

  Context "When assuming role is success" {
    It "Must set environment variables" {
      Mock Invoke-AwsCli {
        $Global:LASTEXITCODE = 0;
        $SuccessAssumeResult;
      };

      Mock Test-Path { return $false; };
      Mock Remove-Item { return; };
      Mock Write-Host { return; };

      $expected = $SuccessAssumeResult | ConvertFrom-Json;

      $TEMP_AWS_ACCESS_KEY_ID = $ENV:AWS_ACCESS_KEY_ID;
      $TEMP_AWS_SECRET_ACCESS_KEY = $ENV:AWS_SECRET_ACCESS_KEY;
      $TEMP_AWS_SESSION_TOKEN = $ENV:AWS_SESSION_TOKEN;
      $TEMP_AWS_SESSION_EXPIRATION = $ENV:AWS_SESSION_EXPIRATION;

      $ENV:AWS_SESSION_TOKEN = $null;
      $ENV:AWS_SESSION_EXPIRATION = $null;


      $result = Grant-AWSDeploymentRole -RoleName "mock-deploy-role" -SessionName "mock-session-name";
      $result | Should Not Be $null;
      $result[0].Credentials.AccessKeyId | Should BeExactly $expected.Credentials.AccessKeyId;
      $ENV:AWS_ACCESS_KEY_ID | Should BeExactly $expected.Credentials.AccessKeyId;
      $result[0].Credentials.SecretAccessKey | Should BeExactly $expected.Credentials.SecretAccessKey;
      $ENV:AWS_SECRET_ACCESS_KEY | Should BeExactly $expected.Credentials.SecretAccessKey;
      $result[0].Credentials.SessionToken | Should BeExactly $expected.Credentials.SessionToken;
      $ENV:AWS_SESSION_TOKEN | Should BeExactly $expected.Credentials.SessionToken;
      $result[0].Credentials.Expiration | Should BeExactly $expected.Credentials.Expiration;
      $ENV:AWS_SESSION_EXPIRATION | Should BeExactly $expected.Credentials.Expiration;

      $Global:LASTEXITCODE | Should Be 0;

      Assert-MockCalled Invoke-AwsCli -Exactly -Times 1;
      Assert-MockCalled Get-AWSAccountId -Exactly -Times 1;
      Assert-MockCalled Remove-Item -Exactly -Times 0;
      Assert-MockCalled Test-Path -Exactly -Times 2;

      # Reset values
      $ENV:AWS_ACCESS_KEY_ID = $TEMP_AWS_ACCESS_KEY_ID;
      $ENV:AWS_SECRET_ACCESS_KEY = $TEMP_AWS_SECRET_ACCESS_KEY;
      $ENV:AWS_SESSION_TOKEN = $TEMP_AWS_SESSION_TOKEN;
      $ENV:AWS_SESSION_EXPIRATION = $TEMP_AWS_SESSION_EXPIRATION;
    }
  }
}

Describe "Save-TransformedContent" {
  $TemplateFileData = "{
    `"item1`": `"#{MOCK_VARIABLE1}`",
    `"item2`": `"#{MOCK_VARIABLE2}`",
    `"item3`": `"#{MOCK_VARIABLE3}`"
  }";
	Context "When including file content" {
		It "Must include the file in the block" {
			$mockFileTemplate = "{
				`"Event`": `"Load`",
				`"Name`": `"MOCK-ITEM-NAME`"
			}"
			$template = "{
				`"item1`": `"#{MOCK_VARIABLE1}`",
		    `"item2`": #{file://$($TestDrive -replace "\\", '/')/mock/mock.template}
			}";
			$outputFile = "$TestDrive/output.json";
			Setup -File 'mock/mock.template' -Content $mockFileTemplate;
			Setup -File 'mock/cfn.template' -Content $template;
			$result = Save-TransformedContent -InputFile "$TestDrive/mock/cfn.template" -OutputFile "$outputFile";
			$result | Should Be 0;
			$outputFile | Should Exist;
			$outputContent = Get-Content -Path $outputFile | Out-String;
			$outObject = $outputContent | ConvertFrom-Json;
			$outObject.item2 | Should Not Be $null;
			$outObject.item2.Event | Should BeExactly "Load";
			$outObject.item2.Name | Should BeExactly "MOCK-ITEM-NAME";
		}
	}
	Context "When including file content for file that does not exist" {
		It "Must not throw error" {
			$template = "{
				`"item1`": `"#{MOCK_VARIABLE1}`",
		    `"item2`": [ #{file://$($TestDrive -replace "\\", '/')/mock/mock.template} ]
			}";
			$outputFile = "$TestDrive/output.json";
			Setup -File 'mock/cfn.template' -Content $template;
			{ Save-TransformedContent -InputFile "$TestDrive/mock/cfn.template" -OutputFile "$outputFile"; } | Should Not Throw;
		}
	}
	Context "When including file content for file that does not exist" {
		It "Must set the value to null/empty" {
			$template = "{
				`"item1`": `"#{MOCK_VARIABLE1}`",
		    `"item2`": [ #{file://$($TestDrive -replace "\\", '/')/mock/mock.template} ]
			}";
			$outputFile = "$TestDrive/output.json";
			Setup -File 'mock/cfn.template' -Content $template;
			$result = Save-TransformedContent -InputFile "$TestDrive/mock/cfn.template" -OutputFile "$outputFile";
			$result | Should Be 0;
			$outputFile | Should Exist;
			$outputContent = Get-Content -Path $outputFile | Out-String;
			$outObject = $outputContent | ConvertFrom-Json;
			$outObject.item2.Count | Should Be 0;
			$outObject.item2.Name | Should Be $null;
		}
	}
  Context "When input file exists" {
    It "Must transform data and save to output file" {
      $ENV:MOCK_VARIABLE1 = "value1";
      $ENV:MOCK_VARIABLE2 = "value2";
      $GLOBAL:TEMP_TC_CONTENT = "";
      Mock Test-Path { return $true; }
      Mock Out-ToFile {
        $GLOBAL:TEMP_TC_CONTENT = $Content;
      };
			Mock Write-Host { return; };
      Mock Get-Content { return $TemplateFileData; };
      $result = Save-TransformedContent -InputFile "$TestDrive/mock-template.json" -OutputFile "$TestDrive/output.json";
      $resultObject = $GLOBAL:TEMP_TC_CONTENT | ConvertFrom-Json;
      $resultObject.item1 | Should BeExactly $ENV:MOCK_VARIABLE1;
      $resultObject.item2 | Should BeExactly $ENV:MOCK_VARIABLE2;
      $resultObject.item3 | Should BeExactly "";
      Assert-MockCalled Test-Path -Exactly -Times 1;
      Assert-MockCalled Out-ToFile -Exactly -Times 1;
      Assert-MockCalled Get-Content -Exactly -Times 1;
    }
  }
}

Describe "Invoke-AwsCli" {
	Context "When passing debug parameter" {
		It "Must include the debug flag on the command" {
			Mock Invoke-ExternalCommand {
				"Output from command execution";
				$GLOBAL:TEMP_AWSCLI_COMMAND = "$Command $($Arguments -join " ")";
        $GLOBAL:LASTEXITCODE = 0;
      }
      $result = Invoke-AwsCli -Command cloudformation -Action describe-stacks -Arguments @("--stack-name", "aero-mock-stack") -EnableDebug;
			$GLOBAL:TEMP_AWSCLI_COMMAND | Should Not Be $null;
      $GLOBAL:TEMP_AWSCLI_COMMAND | Should BeExactly "aws cloudformation describe-stacks --stack-name aero-mock-stack --debug";
      $GLOBAL:LASTEXITCODE | Should Be 0;
      Assert-MockCalled Invoke-ExternalCommand -Exactly -Times 1;
		}
	}
  Context "When invoking cli successfully" {
    It "Must execute the command and return the exit code"{
			$GLOBAL:TEMP_AWSCLI_COMMAND = "";
      Mock Invoke-ExternalCommand {
				"Output from command execution";
				$GLOBAL:TEMP_AWSCLI_COMMAND = "$Command $($Arguments -join " ")";
        $GLOBAL:LASTEXITCODE = 0;
      }
      $result = Invoke-AwsCli -Command cloudformation -Action describe-stacks -Arguments @("--stack-name", "aero-mock-stack");
      $GLOBAL:TEMP_AWSCLI_COMMAND | Should Not Be $null;
      $GLOBAL:TEMP_AWSCLI_COMMAND | Should BeExactly "aws cloudformation describe-stacks --stack-name aero-mock-stack";
      $GLOBAL:LASTEXITCODE | Should Be 0;
      Assert-MockCalled Invoke-ExternalCommand -Exactly -Times 1;
    }
  }
  Context "When invoking cli and it fails" {
    It "Must execute the command and return the exit code"{
			$GLOBAL:TEMP_AWSCLI_COMMAND = "";
      Mock Invoke-ExternalCommand {
				$GLOBAL:TEMP_AWSCLI_COMMAND = "$Command $($Arguments -join " ")";
        $Global:LASTEXITCODE = 3;
      }
      $result = Invoke-AwsCli -Command cloudformation -Action describe-stacks -Arguments @("--stack-name", "aero-mock-stack");
      # this is an array because we are mocking and forwarding the message to the output
			$GLOBAL:TEMP_AWSCLI_COMMAND | Should Not Be $null;
      $GLOBAL:TEMP_AWSCLI_COMMAND | Should BeExactly "aws cloudformation describe-stacks --stack-name aero-mock-stack";
      $GLOBAL:LASTEXITCODE | Should Be 3;
      Assert-MockCalled Invoke-ExternalCommand -Exactly -Times 1;
    }
  }
}

Describe "Invoke-ExternalCommand" {
  Context "When command exits successfully" {
    It "Must return 0" {
      [System.Collections.ArrayList]$GLOBAL:TEMP_COMMAND = [System.Collections.ArrayList]@();
      Mock Invoke-Expression {
        $GLOBAL:TEMP_COMMAND.Add($Command) | Out-Null;
        $GLOBAL:LASTEXITCODE = 0;
      };
      Mock Write-Host {
        return;
      };
      $result = Invoke-ExternalCommand -Command npm -Arguments install
			$GLOBAL:TEMP_COMMAND.Count | Should Be 1;
      $GLOBAL:TEMP_COMMAND[0] | Should Match "npm install";
      $GLOBAL:LASTEXITCODE | Should Be 0;
      Assert-MockCalled Invoke-Expression -Exactly -Times 1;
    }
  };
  Context "When command has multiple arguments" {
    It "Must execute command with all arguments" {
			[System.Collections.ArrayList]$GLOBAL:TEMP_COMMAND = [System.Collections.ArrayList]@();
      Mock Invoke-Expression {
        $GLOBAL:TEMP_COMMAND.Add($Command) | Out-Null;
        $GLOBAL:LASTEXITCODE = 0;
      }
      $result = Invoke-ExternalCommand -Command npm -Arguments install, --production
			$GLOBAL:TEMP_COMMAND.Count | Should Be 1;
      $GLOBAL:TEMP_COMMAND[0] | Should Match "npm install --production";
      $GLOBAL:LASTEXITCODE | Should Be 0;
      Assert-MockCalled Invoke-Expression -Exactly -Times 1;
    }
  }

  Context "When command exits with failure" {
    It "Must return error code" {
      Mock Invoke-Expression {
				"Some text output"
        $GLOBAL:LASTEXITCODE = 93;
      }
      Mock Write-Host { return; };
      $result = Invoke-ExternalCommand -Command npm -Arguments install, --production

      $GLOBAL:LASTEXITCODE | Should Be 93;
      Assert-MockCalled Invoke-Expression -Exactly -Times 1;
    }
  }

  Context "When command does not exist" {
    It "Must throw error" {
      Mock Write-Host { return; };
      $command = "made-up-command.exe";
      $expectedException = "The term '$command' is not recognized as the name of a cmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is correct and try again."
      { Invoke-ExternalCommand -Command "made-up-command.exe" } | Should Throw $expectedException;
    }
  }

	Context "When command does exist" {
    It "Must output content and set exit code" {
      Mock Write-Host { return; };
      $command = "echo";
      $result = Invoke-ExternalCommand -Command "echo" -Arguments @("This is some text to output");
			$result -join " " | Should Be "This is some text to output";
    }
  }
}

Describe "Out-ToFile" {
  Context "When output path exists" {
    It "Must write the content in the output file" {
			Mock Write-Host { return; };
      $mockJson = "{
	`"item1`": `"value1`",
  `"item2`": `"value2`",
  `"arrayItems`": [ `"a1`", `"a2`", `"a3`" ]
}";
      $outFile = "$TestDrive/mock.json";
      Setup -File "mock.json";
      Out-ToFile -OutputFile $outFile -Content $mockJson | Out-Null;
      $outFile | Should Exist;
			$fileData = Get-Content -Path $outFile | Out-String;
      $data = $fileData | ConvertFrom-Json;
      $data | Should Not Be $null;
      $data.item1 | Should BeExactly "value1";
      $data.item2 | Should BeExactly "value2";
      $data.arrayItems.Count | Should Be 3;
    }
  }
}

Describe "Out-CleanBranchForStackName" {
	Context "When no value passed" {
		It "Must throw exception" {
			{ Out-CleanBranchForStackName -Branch } | Should Throw "Missing an argument for parameter 'Branch'. Specify a parameter of type 'System.String' and try again.";
		}
	}
	Context "When value passed by pipeline" {
		It "Must process the value" {
			$inputBranch = "origin/topic/jenkins-jobs/topic/mock-branch-name";
			$expected = "mock-branch-name";
			$output = $inputBranch | Out-CleanBranchForStackName;
			$output | Should BeExactly $expected;
		}
	}
	Context "When value passed by parameter" {
		It "Must process the value" {
			$inputBranch = "origin/topic/jenkins-jobs/topic/aws/mock-branch-name";
			$expected = "aws-mock-branch-name";
			$output = Out-CleanBranchForStackName -Branch $inputBranch;
			$output | Should BeExactly $expected;
		}
	}
}


Describe "Copy-ToDistributionFolder" {
  Context "When SourcePath has files" {
    It "Must copy them to DistributionPath" {
      Setup -File "mock/f1.txt" -Content "A";
      Setup -File "mock/s1/f2.txt" -Content "B";
      Setup -File "mock/s1/f3.txt" -Content "C";
      $result = Copy-ToDistributionFolder -SourcePath "$TestDrive\mock" -DistributionPath "$TestDrive\dist";
      $result | Should Be $null;
      "$TestDrive\dist\f1.txt" | Should Exist;
      "$TestDrive\dist\s1" | Should Exist;
      "$TestDrive\dist\s1\f2.txt" | Should Exist;
      "$TestDrive\dist\f2.txt" | Should Not Exist;
      "$TestDrive\dist\s1\f3.txt" | Should Exist;
      "$TestDrive\dist\f3.txt" | Should Not Exist;
      (Get-Item "$TestDrive\dist\f1.txt").Length | Should BeGreaterThan 0;
      (Get-Item "$TestDrive\dist\s1\f2.txt").Length | Should BeGreaterThan 0;
      (Get-Item "$TestDrive\dist\s1\f3.txt").Length | Should BeGreaterThan 0;
    }
  }
}

Describe "Get-TemplatesToTransform" {
	Context "When there are no files" {
		It "Must return null" {
			Setup -File 'mock/cfn-templates/.gitkeep';
			$result = Get-TemplatesToTransform -Path (Join-Path $TestDrive -ChildPath "mock/cfn-templates");
			$result | Should Be $null;
		}
	}
	Context "When there 2 template file" {
		It "Must return the files" {
			Setup -File 'mock/cfn-templates/.gitkeep';
			Setup -File 'mock/cfn-templates/app-cfn.template';
			Setup -File 'mock/cfn-templates/another-template.json';
			$result = Get-TemplatesToTransform -Path (Join-Path $TestDrive -ChildPath "mock/cfn-templates");
			$result | Should Not Be $null;
			$result.Count | Should Be 2;

		}
	}
	Context "When the folder to scan does not exist" {
		It "Must throw exception" {
			{ Get-TemplatesToTransform -Path (Join-Path $TestDrive -ChildPath "mock/cfn-templates")} | Should Throw;
		}
	}
}
