if($PSCommandPath -eq $null) {
	$CommandRootPath = (Split-Path -Parent $MyInvocation.MyCommand.Path);
} else {
	$CommandRootPath = (Split-Path -Parent $PSCommandPath);
}

# This stops the initial invoking of Invoke-Setup;
$Execute = $false;
."$(Join-Path -Path $CommandRootPath -ChildPath "../package.ps1")" -Path .;

Describe "Create-ArtifactArchive" {
  Context "When topic branch build" {
    It "Must create zip file for snapshot" {
      Setup -File 'mock\file.txt';
      Setup -File 'mock\dist\file.txt';

      $outFile = "mock-project-1.0.0-snapshot.zip"

			Mock Write-Host { return; };
      Mock Invoke-7zip {
        Setup -File "mock\dist-pkgs\$outFile" -Content "BBBBBBBBBBBBBBBB" | Out-Null;
        $GLOBAL:LASTEXITCODE = 0;
				return "$TestDrive\mock\dist-pkgs\$outFile";
      };

      $result = Create-ArtifactArchive -SourcePath "$TestDrive\mock\dist" `
				-OutputPath "$TestDrive\mock\dist-pkgs" -PackageName $outFile;
      ([array]$result).Count | Should Be 1;
      $result | Should Exist;
      $result | Should Match "mock\\dist-pkgs\\mock-project-1.0.0-snapshot\.zip$";
      (Get-Item -Path $result).Length | Should BeGreaterThan 0;
      Assert-MockCalled Invoke-7zip -Exactly -Times 1;
    }
  }
}

Describe "Invoke-7zip" {
  Context "When destination file exists" {
    It "Must remove the destination before processing" {
      $mockZip = "mock/bin/file.zip";
      $mockFilePath = Join-Path -Path $TestDrive -ChildPath $mockZip;
			Mock Write-Host { return; };
      Mock Test-Path { return $true; };
      Mock Remove-Item { return; };
      Mock Invoke-Expression {
        Setup -File $mockZip -Content "BBBBBBBBB";
        $GLOBAL:LASTEXITCODE = 0;
      }
      $result = Invoke-7zip -OutputFile $mockFilePath -SourcePattern "$TestDrive/mock/dist/*";
      $result | Should Not Be $null;
      $result | Should Be 0;
      $mockFilePath | Should Exist;
      (Get-Item -Path $mockFilePath).Length | Should BeGreaterThan 0;
      $GLOBAL:LASTEXITCODE | Should Be 0;
      Assert-MockCalled Test-Path -Exactly -Times 1;
      Assert-MockCalled Remove-Item -Exactly -Times 1;
      Assert-MockCalled Invoke-Expression -Exactly -Times 1;
    }
  }

  Context "When destination file does not exist" {
    It "Must just process the source pattern" {
      $mockZip = "mock/bin/file.zip";
      $mockFilePath = Join-Path -Path $TestDrive -ChildPath $mockZip;
			Mock Write-Host { return; };
      Mock Test-Path { return $false; };
      Mock Remove-Item { return; };
      Mock Invoke-Expression {
        Setup -File $mockZip -Content "BBBBBBBBB";
        $GLOBAL:LASTEXITCODE = 0;
      }

      $result = Invoke-7zip -OutputFile $mockFilePath -SourcePattern "$TestDrive/mock/dist/*";
      $result | Should Not Be $null;
      $result | Should Be 0;
      $mockFilePath | Should Exist;
      (Get-Item -Path $mockFilePath).Length | Should BeGreaterThan 0;
      $GLOBAL:LASTEXITCODE | Should Be 0;
      Assert-MockCalled Test-Path -Exactly -Times 1;
      Assert-MockCalled Remove-Item -Exactly -Times 0;
      Assert-MockCalled Invoke-Expression -Exactly -Times 1;
    }
  }
}
