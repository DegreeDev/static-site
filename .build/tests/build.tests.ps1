if($PSCommandPath -eq $null) {
	$CommandRootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path);
} else {
	$CommandRootPath = (Split-Path -Parent $PSCommandPath);
}

# This stops the initial invoking of Invoke-Setup;
$Execute = $false;

."$(Join-Path -Path $CommandRootPath -ChildPath "../build.ps1")" -Path .;

Describe "Invoke-Build" {
	Context "When executing build" {
		It "Must execute the npm build" {
			$expected = "npm run build";
			$expectedVersion = "npm version 1.0.0-alpha.1 --no-git-tag-version";
			Mock Test-Path { return $false; };
      Mock Remove-Item { return; };
      Mock New-Item { return; };
			Mock Invoke-ExternalCommand {
				"Output from command";
				$GLOBAL:INVOKE_BUILD_EXTERNALCOMMAND_VALUE = "$Command $($Arguments -join " ")";
				$GLOBAL:LASTEXITCODE = 0;
			} -ParameterFilter { $Arguments -contains "build" };
			Mock Invoke-ExternalCommand {
				"Output from command";
				$GLOBAL:INVOKE_VERSION_EXTERNALCOMMAND_VALUE = "$Command $($Arguments -join " ")";
				$GLOBAL:LASTEXITCODE = 0;
			} -ParameterFilter { $Arguments -contains "version" };
			Mock Start-Sleep { };
			Mock Copy-ToDistributionFolder { return; };
			Mock Get-Location { return $TestDrive; };
			Mock Write-Host { return; };

			$result = Invoke-Build -Environment "nonprod" `
				-DistributionPath "$TestDrive\dist" `
				-ArtifactsPath "$TestDrive\dist-pkgs" `
				-Version "1.0.0-alpha.1";
			$GLOBAL:LASTEXITCODE | Should Be 0;
			$GLOBAL:INVOKE_BUILD_EXTERNALCOMMAND_VALUE | Should BeExactly $expected;
			$GLOBAL:INVOKE_VERSION_EXTERNALCOMMAND_VALUE | Should BeExactly $expectedVersion;
			Assert-MockCalled Invoke-ExternalCommand -Exactly -Times 2;
			Assert-MockCalled Test-Path -Exactly -Times 2;
			Assert-MockCalled New-Item -Exactly -Times 2;
			Assert-MockCalled Remove-Item -Exactly -Times 0;
			Assert-MockCalled Get-Location -Exactly -Times 1;
			Assert-MockCalled Copy-ToDistributionFolder -Exactly -Times 1;
			Assert-MockCalled Start-Sleep -Exactly -Times 1;

		}
	}
  Context "When Environment unknown" {
    It "Must set build environment to development" {
      $GLOBAL:MESSAGES = [System.Collections.ArrayList]@();
      Mock Test-Path { return $false; };
      Mock Remove-Item { return; };
      Mock New-Item { return; };
      Mock Invoke-ExternalCommand {
				"Output from command";
        $GLOBAL:LASTEXITCODE = 0;
      };
      Mock Start-Sleep { };
      Mock Copy-ToDistributionFolder { return; };
      Mock Get-Location { return $TestDrive; };
      Mock Write-Host {
				return;
      };

      $result = Invoke-Build -Environment "unknown" `
				-DistributionPath "$TestDrive\dist" `
				-ArtifactsPath "$TestDrive\dist-pkgs" `
				-Version "1.0.0-SNAPSHOT";
      Assert-MockCalled Test-Path -Exactly -Times 2;
      Assert-MockCalled New-Item -Exactly -Times 2;
      Assert-MockCalled Remove-Item -Exactly -Times 0;
      Assert-MockCalled Invoke-ExternalCommand -Exactly -Times 2;
      Assert-MockCalled Get-Location -Exactly -Times 1;
      Assert-MockCalled Copy-ToDistributionFolder -Exactly -Times 1;
      Assert-MockCalled Start-Sleep -Exactly -Times 1;
    }
  }
  Context "When Environment is development" {
    It "Must set build environment to development" {
      $GLOBAL:MESSAGES = [System.Collections.ArrayList]@();
      Mock Test-Path { return $false; };
      Mock Remove-Item { return; };
      Mock New-Item { return; };
      Mock Invoke-ExternalCommand {
				"Output from command";
        $GLOBAL:LASTEXITCODE = 0;
      };
      Mock Start-Sleep { };
      Mock Copy-ToDistributionFolder { return; };
      Mock Get-Location { return $TestDrive; };
      Mock Write-Host {
				return;
      };

      $result = Invoke-Build -Environment "development" `
				-DistributionPath "$TestDrive\dist" `
				-ArtifactsPath "$TestDrive\dist-pkgs" `
				-Version "1.0.0-SNAPSHOT";
      Assert-MockCalled Test-Path -Exactly -Times 2;
      Assert-MockCalled New-Item -Exactly -Times 2;
      Assert-MockCalled Remove-Item -Exactly -Times 0;
      Assert-MockCalled Invoke-ExternalCommand -Exactly -Times 2;
      Assert-MockCalled Get-Location -Exactly -Times 1;
      Assert-MockCalled Copy-ToDistributionFolder -Exactly -Times 1;
      Assert-MockCalled Start-Sleep -Exactly -Times 1;
    }
  }
  Context "When Environment is nonprod and is snapshot" {
    It "Must set build environment to development" {
      $TEMP_CI_SNAPSHOT = $ENV:CI_SNAPSHOT
      $GLOBAL:MESSAGES = [System.Collections.ArrayList]@();
      Mock Test-Path { return $false; };
      Mock Remove-Item { return; };
      Mock New-Item { return; };
      Mock Invoke-ExternalCommand {
				"Output from command";
        $GLOBAL:LASTEXITCODE = 0;
      };
      Mock Start-Sleep { };
      Mock Copy-ToDistributionFolder { return; };
      Mock Get-Location { return $TestDrive; };
      Mock Write-Host {
				return;
      };

      $ENV:CI_SNAPSHOT = 'true';

      $result = Invoke-Build -Environment "nonprod" `
				-DistributionPath "$TestDrive\dist" `
				-ArtifactsPath "$TestDrive\dist-pkgs" `
				-Version "1.0.0-SNAPSHOT";
      Assert-MockCalled Test-Path -Exactly -Times 2;
      Assert-MockCalled New-Item -Exactly -Times 2;
      Assert-MockCalled Remove-Item -Exactly -Times 0;
      Assert-MockCalled Invoke-ExternalCommand -Exactly -Times 2;
      Assert-MockCalled Get-Location -Exactly -Times 1;
      Assert-MockCalled Copy-ToDistributionFolder -Exactly -Times 1;
      Assert-MockCalled Start-Sleep -Exactly -Times 1;
      # Restore values
      $ENV:CI_SNAPSHOT = $TEMP_CI_SNAPSHOT;
    }
  }

  Context "When Environment is nonprod and is not a snapshot" {
    It "Must set build environment to uat" {
      $TEMP_CI_SNAPSHOT = $ENV:CI_SNAPSHOT
      $GLOBAL:MESSAGES = [System.Collections.ArrayList]@();
      Mock Test-Path { return $false; };
      Mock Remove-Item { return; };
      Mock New-Item { return; };
      Mock Invoke-ExternalCommand {
				"Output from command";
        $GLOBAL:LASTEXITCODE = 0;
      };
      Mock Start-Sleep { };
      Mock Copy-ToDistributionFolder { return; };
      Mock Get-Location { return $TestDrive; };
      Mock Write-Host {
				return;
      };

      $ENV:CI_SNAPSHOT = 'false';

      $result = Invoke-Build -Environment "nonprod" `
				-DistributionPath "$TestDrive\dist" `
				-ArtifactsPath "$TestDrive\dist-pkgs" `
				-Version "1.0.0";
      Assert-MockCalled Test-Path -Exactly -Times 2;
      Assert-MockCalled New-Item -Exactly -Times 2;
      Assert-MockCalled Remove-Item -Exactly -Times 0;
      Assert-MockCalled Invoke-ExternalCommand -Exactly -Times 2;
      Assert-MockCalled Get-Location -Exactly -Times 1;
      Assert-MockCalled Copy-ToDistributionFolder -Exactly -Times 1;
      Assert-MockCalled Start-Sleep -Exactly -Times 1;
      # Restore values
      $ENV:CI_SNAPSHOT = $TEMP_CI_SNAPSHOT;
    }
  }
  Context "When Environment is prod" {
    It "Must set build environment to production" {
      $TEMP_CI_SNAPSHOT = $ENV:CI_SNAPSHOT
      $GLOBAL:MESSAGES = [System.Collections.ArrayList]@();
      Mock Test-Path { return $true; };
      Mock Remove-Item { return; };
      Mock New-Item { return; };
      Mock Invoke-ExternalCommand {
				"Output from command";
        $GLOBAL:LASTEXITCODE = 0;
      };
      Mock Start-Sleep { };
      Mock Copy-ToDistributionFolder { return; };
      Mock Get-Location { return $TestDrive; };
      Mock Write-Host {
				return;
      };

      $ENV:CI_SNAPSHOT = $null;

      $result = Invoke-Build -Environment "prod" `
				-DistributionPath "$TestDrive\dist" `
				-ArtifactsPath "$TestDrive\dist-pkgs" `
				-Version "1.0.0";
      Assert-MockCalled Test-Path -Exactly -Times 2;
      Assert-MockCalled New-Item -Exactly -Times 1;
      Assert-MockCalled Remove-Item -Exactly -Times 1;
      Assert-MockCalled Invoke-ExternalCommand -Exactly -Times 2;
      Assert-MockCalled Get-Location -Exactly -Times 1;
      Assert-MockCalled Copy-ToDistributionFolder -Exactly -Times 1;
      Assert-MockCalled Start-Sleep -Exactly -Times 1;
      # Restore values
      $ENV:CI_SNAPSHOT = $TEMP_CI_SNAPSHOT;
    }
  }
}

Describe "Copy-ToDistributionFolder" {
  Context "When SourcePath has files" {
    It "Must copy them to DistributionPath" {
      Setup -File "mock/f1.txt" -Content "A";
      Setup -File "mock/s1/f2.txt" -Content "B";
      Setup -File "mock/s1/f3.txt" -Content "C";

      $result = Copy-ToDistributionFolder -SourcePath "$TestDrive/mock" -DistributionPath "$TestDrive/dist";
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
