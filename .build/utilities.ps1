
function Get-AWSAccountId {
	param(

  )
	begin {
		if($ENV:AWS_ACCOUNT_ID -eq "" -or $ENV:AWS_ACCOUNT_ID -eq $null) {
			throw "AWS_ACCOUNT_ID not present in environment variables.";
		}
	}
	process {
		# This is set in the *-pipeline jobs
		return $ENV:AWS_ACCOUNT_ID;
	}
}

function Out-CleanBranchForStackName {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[string] $Branch
	)
	begin {

	}
	process {
		return (((($Branch -replace 'origin/', '') -replace 'topic/', '') -replace 'jenkins-jobs/', '') -replace '/', '-');
	}
}

function Test-StackExists {
	param (
		# Param1 help description
		[Parameter(Mandatory)]
		$StackName
	)
	process {
    Invoke-AwsCli -Command cloudformation -Action describe-stacks -Arguments @("--stack-name", $StackName ) | Out-Null;
		$stackCheck = $LASTEXITCODE;
		if( $stackCheck -eq 0 ) {
			"Stack: $StackName exists" | Write-Host;
			return $true;
		} else {
			"Stack: $StackName does not exist" | Write-Host;
			return $false;
		}
	}
}

function Remove-Stack {
	param (
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=0)]
		$StackName
	)
	begin {
		$accountId = Get-AWSAccountId;
	}
	process {
		"attempting to destroy stack $StackName" | Write-Host;
    Invoke-AwsCli -Command cloudformation -Action delete-stack -Arguments @("--stack-name", $StackName) | Write-Host;
    $stackEC = $LASTEXITCODE;
		if ( $stackEC -eq 0 ) {
			# only run this if we successfully ran the previous task
			"waiting for stack destroy to complete" | Write-Host;
      Invoke-AwsCli -Command cloudformation -Action wait -Arguments @("stack-delete-complete", "--stack-name", "$StackName") | Write-Host;
      return $LASTEXITCODE;
		}
		return $stackEC;
	}
}

function Update-Stack {
	param (
		[Parameter(Mandatory)]
		[string] $StackName,
		[Parameter(Mandatory)]
		[string] $CloudFormationTemplate,
		[Array] $StackParameters = $null
	)
	begin {
		$paramsString = "";
		if ($StackParameters -ne $null) {
			$convertedParams = (((ConvertTo-JSON -InputObject $StackParameters -Compress | Out-String) -replace "`n", '') -replace "`r", '');
			# create a file with the data
			$paramsFile = Join-Path -Path (Get-Location) -ChildPath "./$StackName-parameters.json";
			Out-ToFile -OutputFile $paramsFile -Content $convertedParams | Out-Null;
			$paramsString = "--parameters `"file://$($paramsFile -replace "\\", "/")`"";
		}
	}
	process {
		try {
			# $updateInfo = (& aws cloudformation update-stack --stack-name $StackName --template-body $CloudFormationTemplate --parameters "[{\`"ParameterKey\`":\`"LambdaFunctionName\`", \`"ParameterValue\`": \`"$lambdaFunctionName\`"},{\`"ParameterKey\`": \`"ProxyApiStageName\`", \`"ParameterValue\`": \`"latest\`"},{\`"ParameterKey\`": \`"IAMLambdaRole\`", \`"ParameterValue\`": \`"$exeRole\`"},{\`"ParameterKey\`": \`"LambdaCodePackage\`", \`"ParameterValue\`": \`"fileb://$lambdaPkg\`"}]" --debug *>&1);
			$updateInfo = Invoke-AwsCli -Command cloudformation -Action "update-stack" -Arguments @(
				"--stack-name $StackName",
				"--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM",
				"--template-body `"$CloudFormationTemplate`"",
				$paramsString );
			$updateInfo | Write-Host;
	    $noUpdates = $updateInfo -match "(?si)No\s?updates are to be performed\.";
	    if($noUpdates) {
	      "Setting exit to 0 because 'No updates are to be performed'." | Write-Host;
	      return 0;
	    } else {
			  $stackEC = $LASTEXITCODE;
	    }
			if($stackEC -eq 0) {
				# only run this if we successfully ran the previous task
				"waiting for stack update to complete" | Write-Host;
				# $resultData = (& aws cloudformation wait stack-update-complete --stack-name $StackName --debug *>&1) -join "`n";
				$resultData = Invoke-AwsCli -Command cloudformation -Action wait -Arguments @(
					"stack-update-complete",
					"--stack-name $StackName"
					);
				$resultData | Write-Host;
	      $noUpdates = $resultData -match "(?si)No\s?updates are to be performed\.";
	      if($noUpdates) {
					"Setting exit to 0 because 'No updates are to be performed'." | Write-Host;
	        return 0;
	      } else {
					return $LASTEXITCODE;
	      }
			}
			return $stackEC;
		} catch {
			$_ | Write-Warning;
			return 255;
		}
	}
}

function Create-Stack {
	param (
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=0)]
		$StackName,
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=1)]
		$CloudFormationTemplate,
		[Array] $StackParameters = $null
	)
	begin {
		$paramsString = ""
		if ($StackParameters -ne $null) {
			$convertedParams = (((ConvertTo-JSON -InputObject $StackParameters -Compress | Out-String) -replace "`n", '') -replace "`r", '');
			# create a file with the data
			$paramsFile = Join-Path -Path (Get-Location) -ChildPath "./$StackName-parameters.json";
			Out-ToFile -OutputFile $paramsFile -Content $convertedParams | Out-Null;
			$paramsString = "--parameters `"file://$($paramsFile -replace "\\", "/")`"";
		}
	}
	process {
		# stack does not exist, need to create it
		Invoke-AwsCli -Command cloudformation -Action "create-stack" -Arguments @(
			"--stack-name $StackName",
			"--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM",
			"--template-body `"$CloudFormationTemplate`"",
			$paramsString
		) | Write-Host;
		#(& aws cloudformation create-stack --stack-name $StackName --template-body $CloudFormationTemplate --parameters "[{\`"ParameterKey\`":\`"LambdaFunctionName\`", \`"ParameterValue\`": \`"$lambdaFunctionName\`"},{\`"ParameterKey\`": \`"ProxyApiStageName\`", \`"ParameterValue\`": \`"latest\`"},{\`"ParameterKey\`": \`"IAMLambdaRole\`", \`"ParameterValue\`": \`"$exeRole\`"},{\`"ParameterKey\`": \`"LambdaCodePackage\`", \`"ParameterValue\`": \`"fileb://$lambdaPkg\`"}]" --debug *>&1);
		$stackEC = $LASTEXITCODE;
		if ( $stackEC -eq 0 ) {
			# only run this if we successfully ran the previous task
			"waiting for stack creation to complete" | Write-Host;
			Invoke-AwsCli -Command cloudformation -Action wait -Arguments @(
				"stack-create-complete",
				"--stack-name $StackName"
			) | Write-Host;
			return $LASTEXITCODE;
		} else {
			return $stackEC;
		}
	}
}

function Invoke-StackCreateOrUpdate {
	param(
		[Parameter(Mandatory)]
		[string] $StackName,
		[Parameter(Mandatory)]
		[string] $TemplateUri,
		[PsObject] $StackParameters
	)
	begin {
		$stackExists = Test-StackExists -StackName $StackName;
	}
	process {
		$exitCode = 0;
		if ( $stackExists -eq $true ) {
			"Running Update-Stack" | Write-Host;
			$exitCode = Update-Stack -StackName $StackName -CloudFormationTemplate $TemplateUri -StackParameters $StackParameters;
		} else {
			"Running Create-Stack" | Write-Host;
			$exitCode = Create-Stack -StackName $StackName -CloudFormationTemplate $TemplateUri -StackParameters $StackParameters;
		}
		return $exitCode;
	}
}

function Grant-AWSDeploymentRole {
	param(
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=0)]
		$RoleName,
		[Parameter(Mandatory, ValueFromPipelineByPropertyName, Position=1)]
		$SessionName
	)
	begin {
		$accountId = Get-AWSAccountId;
	}
	process {
		# Remove these, if they exist
		if ( Test-Path -Path ENV:\AWS_SESSION_TOKEN ) {
			Remove-Item -Path Env:\AWS_SESSION_TOKEN | Out-Null;
		}
		if ( Test-Path -Path ENV:\AWS_SESSION_EXPIRATION ) {
			Remove-Item -Path Env:\AWS_SESSION_EXPIRATION | Out-Null;
		}

    $accessResultData = Invoke-AwsCli -Command sts -Action assume-role -Arguments @("--role-arn", "arn:aws:iam::$($accountId):role/$($RoleName)", "--role-session-name", $SessionName);
		$executionResult = $LASTEXITCODE;
		if ($executionResult -ne 0) {
			throw "assume-role exited with error code: $executionResult";
		}

		#"result: $accessResultData" | Write-Host;
		$accessResultData | Write-Host;
		$accessResult = $accessResultData | Out-String | ConvertFrom-Json;

		# I think we ONLY want to set this at the process level
		# setting them beyond that, seems to override the values that jenkins sets
		$ENV:AWS_ACCESS_KEY_ID = $accessResult.Credentials.AccessKeyId;
		$ENV:AWS_SECRET_ACCESS_KEY = $accessResult.Credentials.SecretAccessKey;
		$ENV:AWS_SESSION_TOKEN = $accessResult.Credentials.SessionToken;
		$ENV:AWS_SESSION_EXPIRATION = $accessResult.Credentials.Expiration;

		"AWS_ACCESS_KEY_ID: $ENV:AWS_ACCESS_KEY_ID"| Write-Host;

		"Token will expire @ $($accessResult.Credentials.Expiration)" | Write-Host;

		if ( $ENV:AWS_ACCESS_KEY_ID -eq "" -or
					$ENV:AWS_ACCESS_KEY_ID -eq $null -or
					$accessResult.Credentials.AccessKeyId -eq "" -or
					$accessResult.Credentials.AccessKeyId -eq $null ) {
			throw "There was a problem getting the AWS_ACCESS_KEY_ID and storing it for use";
		}

		if ( $ENV:AWS_SECRET_ACCESS_KEY -eq "" -or
					$ENV:AWS_SECRET_ACCESS_KEY -eq $null -or
					$accessResult.Credentials.SecretAccessKey -eq "" -or
					$accessResult.Credentials.SecretAccessKey -eq $null ) {
			throw "There was a problem getting the AWS_SECRET_ACCESS_KEY and storing it for use";
		}

		if ( $ENV:AWS_SESSION_TOKEN -eq "" -or
					$ENV:AWS_SESSION_TOKEN -eq $null -or
					$accessResult.Credentials.SessionToken -eq "" -or
					$accessResult.Credentials.SessionToken -eq $null ) {
			throw "There was a problem getting the AWS_SESSION_TOKEN and storing it for use";
		}

		if ( $ENV:AWS_SESSION_EXPIRATION -eq "" -or
					$ENV:AWS_SESSION_EXPIRATION -eq $null -or
					$accessResult.Credentials.Expiration -eq "" -or
					$accessResult.Credentials.Expiration -eq $null ) {
			throw "There was a problem getting the AWS_SESSION_EXPIRATION and storing it for use";
		}

    return $accessResult;
	}
}

function Save-TransformedContent {
	param (
		[Parameter(Mandatory)]
		[ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' })]
		[String] $InputFile,
		[Parameter(Mandatory)]
		[String] $OutputFile
	)
	begin {
	}
	process {
		try {
			$content = (Get-Content -Path $InputFile | `
			# This replaces all #{ENV_VAR_NAME} with the env var value
			foreach { [RegEx]::Replace($_ ,'(\#\{([^\}]+)\})', {
				param($match)
				if($match.Groups[2].Value -match "^file:\/\/") {
					# inject file content
					$file = $match.Groups[2].Value.Substring(7);
					$fileContent = Get-Content -Path $file -ErrorAction SilentlyContinue | Out-String;
					$fileContent;
				} else {
					((Get-Item -Path "ENV:$($match.Groups[2].Value)" -ErrorAction SilentlyContinue).Value);
				}
			}) } `
			| Out-String); #-replace "`r`n", "`n"; #| Out-File -FilePath $OutputFile;
			Out-ToFile -OutputFile $OutputFile -Content $content | Out-Null;
			return 0;
		} catch {
			$_ | Write-Warning;
			return 255;
		}
	}
}

function Invoke-AwsCli {
  param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string] $Command,
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [string] $Action,
    [string[]] $Arguments,
		[switch] $EnableDebug
  )
	begin {
		[System.Collections.ArrayList]$xargs = [System.Collections.ArrayList]@($Command, $Action);
		$Arguments | where { $_ -ne $null -and $_ -ne "" } | foreach { $xargs.Add($_) | Out-Null; };
		if($EnableDebug.IsPresent) {
			$xargs.Add("--debug") | Out-Null;
		}
	}
	process {
		$result = Invoke-ExternalCommand -Command aws -Arguments ([array]$xargs);
		return $result;
	}
}

function Invoke-ExternalCommand {
  param (
    [Parameter(Mandatory)]
    [string] $Command,
    [string[]] $Arguments = @()
  )
  begin {
    $mergedCommand = "$Command $($Arguments -join " ")";
		$mergedCommand | Write-Host;
  }
  process {
    $result = Invoke-Expression "(& $mergedCommand *>&1)";
		return $result;
  }
}

function Out-ToFile {
  param (
    [Parameter(Mandatory)]
    [string] $OutputFile,
    [Parameter(Mandatory)]
    [string] $Content
  )
  process {
    try {
      [IO.File]::WriteAllText("$OutputFile","$Content") | Out-Null;
    } catch {
      $_ | Write-Warning;
			throw;
    }
  }
}

function Copy-ToDistributionFolder {
  param (
    [Parameter(Mandatory)]
    [string] $SourcePath,
    [Parameter(Mandatory)]
    [string] $DistributionPath
  )
  begin {
		$cwd = Get-Item -Path $SourcePath;
		if(!(Test-Path -Path $DistributionPath)) {
			New-Item -ItemType Directory -Path $DistributionPath | Out-Null;
		}
		$dist = (Get-Item -Path $DistributionPath).Name;
		if($dist -eq $null -or $dist -eq "") {
			$dist = "dist";
		}
		$parent = $cwd.Name
  }
  process {
    Get-ChildItem -Path $cwd -Recurse | where {
     $_.FullName -notmatch "$parent\\$dist" -and `
		 	$_.FullName -notmatch "$parent\\.build";
    } | foreach {
        $targetFile = "$DistributionPath\" + $_.FullName.SubString(($cwd).FullName.Trim('\').Length + 1);
        if ($_.PSIsContainer) {
          New-Item -ItemType Directory -Path $targetFile -Force | Out-Null;
        } else {
          Copy-Item -Path $_.FullName -Destination $targetFile -Force | Out-Null;
        }
    }
  }
}

function Get-TemplatesToTransform {
	param (
		[Parameter(Mandatory)]
		[ValidateScript({ Test-Path -Path $_ -PathType 'Container' })]
		[string] $Path
	)
	begin {

	}
	process {
		$items = Get-ChildItem -Path "$Path\*" -Include "*.template", "*.json", "*.yml", "*.yaml" -Exclude "*transformed-*" -Recurse;
		return $items;
	}
}


function Invoke-TemplateDeployment {
	param (
		[Array] $Templates = @()
	)
	process {
		for( $x = 0; $x -lt $Templates.Count; ++$x ) {
			$template = $Templates[$x];
			$filename = Split-Path -Path $template -Leaf;
			$name = $filename.Substring(0, $filename.LastIndexOf('.'));
			$directory = Split-Path -Path $template -Parent;
			$transformed = (Join-Path -Path $directory -ChildPath "transformed-$filename");

			# load the config file for the template
			$configFile = (Join-Path -Path $directory -ChildPath "$name.ps1");
			$config = @{ StackName = $name; Parameters = @() };
			if(Test-Path -Path $configFile) {
				$config = ."$configFile";
				if($config.StackName -eq $null -or $config.StackName -eq "") {
					$config.StackName = $name;
				}
				if($config.Parameters -eq $null -or $config.Parameters -eq "") {
					$config.Parameters = @();
				}
			}

			$exitCode += Save-TransformedContent -InputFile $template -OutputFile $transformed;
			if($exitCode -ne 0) {
				return $exitCode;
			}

			$transformedUri = "file://$($transformed -replace "\\", "/")";
			[Array]$transformedParameters = ConvertTo-CliArrayParameters -Parameters $config.Parameters;
			$exitCode += Invoke-StackCreateOrUpdate -StackName $config.StackName `
				-TemplateUri "$transformedUri" `
				-StackParameters $transformedParameters;
			if($exitCode -ne 0){
				return $exitCode;
			}
		}
		return 0;
	}
}

function Test-TemplateDeployment {
	param (
		[Array] $Templates = @()
	)
	process {
		for( $x = 0; $x -lt $Templates.Count; ++$x ) {
			$template = $Templates[$x];
			$filename = Split-Path -Path $template -Leaf;
			$directory = Split-Path -Path $template -Parent;
			$transformed = (Join-Path -Path $directory -ChildPath "transformed-$filename");
			$exitCode += Save-TransformedContent -InputFile $template -OutputFile $transformed;
			if($exitCode -ne 0) {
				return $exitCode;
			}

			$transformedUri = "file://$($transformed -replace "\\", "/")";
			$exitCode += Invoke-CfnValidation -Template "$transformedUri";
			if($exitCode -ne 0){
				return $exitCode;
			}
		}

		return 0;
	}
}

function ConvertTo-CliArrayParameters {
	param(
		[PSObject] $Parameters = $null
	)
	process {
		if ($Parameters -is [Array]) {
			return $Parameters;
		} else {
			$output = [System.Collections.ArrayList]@();
			$Parameters.Keys | foreach {
				$obj = @{};
				$obj.ParameterKey = $_;
				$obj.ParameterValue = $Parameters."$_";
				$output.Add($obj) | Out-Null;
			};
			return [Array]$output;
		}
	}
}
