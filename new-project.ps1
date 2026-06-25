[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Name of the new project/app (e.g., my-service)")]
    [string]$Name,

    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Target directory path where the new project will be created")]
    [string]$TargetDir
)

# Set up paths
$RepoRoot = $null
if ($PSScriptRoot) {
    $RepoRoot = Resolve-Path "$PSScriptRoot"
} else {
    $RepoRoot = Resolve-Path "."
}

$LocalTemplateDir = $null
if (Test-Path (Join-Path $RepoRoot "template")) {
    $LocalTemplateDir = Join-Path $RepoRoot "template"
} elseif (Test-Path ".\template") {
    $LocalTemplateDir = Resolve-Path ".\template"
}

# If TargetDir is not specified, default to creating a folder in the current directory
if ([string]::IsNullOrWhiteSpace($TargetDir)) {
    $TargetDir = Join-Path $RepoRoot $Name
} else {
    $TargetDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TargetDir)
}

if (Test-Path $TargetDir) {
    Write-Error "Target directory '$TargetDir' already exists. Choose a different name or path."
    exit 1
}

Write-Host "Creating project '$Name' in: $TargetDir" -ForegroundColor Cyan

if ($LocalTemplateDir -and (Test-Path $LocalTemplateDir)) {
    Write-Host "Using local template directory..." -ForegroundColor Gray
    # Copy template directory recursively
    Copy-Item -Path $LocalTemplateDir -Destination $TargetDir -Recurse -Force
} else {
    Write-Host "Local template directory not found. Downloading template from GitHub (akikungz/homelab)..." -ForegroundColor Cyan
    $ZipUrl = "https://github.com/akikungz/homelab/archive/refs/heads/main.zip"
    $TempZip = [System.IO.Path]::GetTempFileName() + ".zip"
    $TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
    
    try {
        Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing
        Expand-Archive -Path $TempZip -DestinationPath $TempDir -Force
        $ExtractedTemplate = Join-Path $TempDir "homelab-main/template"
        if (-not (Test-Path $ExtractedTemplate)) {
            $ExtractedTemplate = (Get-ChildItem -Path $TempDir -Directory | Join-Path -ChildPath "template")
        }
        
        if (Test-Path $ExtractedTemplate) {
            Copy-Item -Path $ExtractedTemplate -Destination $TargetDir -Recurse -Force
        } else {
            throw "Could not find template folder in the downloaded archive."
        }
    }
    catch {
        Write-Error "Failed to download and extract template: $_"
        exit 1
    }
    finally {
        if (Test-Path $TempZip) { Remove-Item -Path $TempZip -Force }
        if (Test-Path $TempDir) { Remove-Item -Path $TempDir -Recurse -Force }
    }
}

# Find all files to replace occurrences of 'template-app' and references to the template folder
$FilesToProcess = Get-ChildItem -Path $TargetDir -Recurse -File | Where-Object {
    $_.Extension -in @(".yaml", ".yml", ".md", ".txt", ".json", ".example", ".config", ".secret")
}

foreach ($File in $FilesToProcess) {
    $Content = Get-Content -Path $File.FullName -Raw
    $Modified = $false
    
    if ($Content -match "template-app") {
        $Content = $Content -replace "template-app", $Name
        $Modified = $true
    }
    
    if ($Content -match "template/") {
        $Content = $Content -replace "template/", "$Name/"
        $Modified = $true
    }

    if ($Content -match "Kubernetes Kustomize Application Template") {
        $Content = $Content -replace "Kubernetes Kustomize Application Template", "Kubernetes Kustomize - $Name"
        $Modified = $true
    }

    if ($Modified) {
        Set-Content -Path $File.FullName -Value $Content -NoNewline
    }
}

# Auto-initialize .env files from templates in the overlays
$OverlaysDir = Join-Path $TargetDir "overlays"
if (Test-Path $OverlaysDir) {
    $OverlayEnvs = Get-ChildItem -Path $OverlaysDir -Directory
    foreach ($EnvDir in $OverlayEnvs) {
        # Config Map Env
        $ConfigExample = Join-Path $EnvDir.FullName ".env.config.example"
        $ConfigDest = Join-Path $EnvDir.FullName ".env.config"
        if (Test-Path $ConfigExample) {
            Copy-Item -Path $ConfigExample -Destination $ConfigDest -Force
            $Content = Get-Content -Path $ConfigDest -Raw
            if ($Content -match "template-app") {
                $Content = $Content -replace "template-app", $Name
                Set-Content -Path $ConfigDest -Value $Content -NoNewline
            }
        }

        # Secret Env
        $SecretExample = Join-Path $EnvDir.FullName ".env.secret.example"
        $SecretDest = Join-Path $EnvDir.FullName ".env.secret"
        if (Test-Path $SecretExample) {
            Copy-Item -Path $SecretExample -Destination $SecretDest -Force
            $Content = Get-Content -Path $SecretDest -Raw
            if ($Content -match "template-app") {
                $Content = $Content -replace "template-app", $Name
                Set-Content -Path $SecretDest -Value $Content -NoNewline
            }
        }
    }
}

Write-Host "`nSuccessfully created project '$Name'!" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Review the configuration files in: $TargetDir"
Write-Host "2. Edit the generated .env.config and .env.secret files in overlays."
Write-Host "3. Deploy using: kubectl apply -k $Name/overlays/development (from the repo root)"
