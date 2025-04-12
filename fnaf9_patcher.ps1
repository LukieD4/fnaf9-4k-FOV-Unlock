[CmdletBinding()]
param()

$script:4kSettings = @"
[ScalabilityGroups]
sg.ResolutionQuality=100.000000
sg.ViewDistanceQuality=4
sg.AntiAliasingQuality=4
sg.ShadowQuality=2
sg.PostProcessQuality=3
sg.TextureQuality=4
sg.EffectsQuality=4
sg.FoliageQuality=4
sg.ShadingQuality=4

[/Script/fnaf9.FNAFGameUserSettings]
VisualQualityLevel=0
RayTraceQualityLevel=0
bUseVSync=False
bUseDynamicResolution=True
ResolutionSizeX=2560
ResolutionSizeY=1440
LastUserConfirmedResolutionSizeX=3840
LastUserConfirmedResolutionSizeY=2160
FullscreenMode=1
LastConfirmedFullscreenMode=1
PreferredFullscreenMode=1
DesiredScreenWidth=3840
DesiredScreenHeight=2160
LastUserConfirmedDesiredScreenWidth=3840
LastUserConfirmedDesiredScreenHeight=2160
bUseHDRDisplayOutput=False
HDRDisplayOutputNits=1000

[/Script/Engine.GameUserSettings]
bUseDesiredScreenHeight=True
"@

function Show-Menu {
    Clear-Host
    Write-Host @"
=======================================
 FNAF 9 Configuration Toolkit
=======================================
1. Apply/Restore FOV Patch
2. Toggle 4K Ultra HD Settings
3. Restore All Backups
4. Exit
=======================================
"@
}

function Show-FOVMenu {
    Clear-Host
    Write-Host @"
=======================================
 FOV Configuration Options
=======================================
1. Apply Y-Axis FOV (Maintain YFOV)
2. Apply X-Axis FOV (Maintain XFOV)
3. Apply Major Axis FOV
4. Restore Original FOV Settings
5. Return to Main Menu
=======================================
"@
}

function Backup-File {
    param($Path, $Suffix)
    $backupPath = $Path -replace '\.ini$', $Suffix
    if (-not (Test-Path $backupPath)) {
        Copy-Item $Path $backupPath -Force
        Write-Host "Backup created: $backupPath" -ForegroundColor Green
    }
    return $backupPath
}

function Set-4KResolution {
    $settingsPath = "$env:LOCALAPPDATA\fnaf9\Saved\Config\WindowsNoEditor\GameUserSettings.ini"
    $backupPath = $settingsPath -replace '\.ini$', '_pre4kBackup.ini'

    if (-not (Test-Path $settingsPath)) {
        Write-Host "GameUserSettings.ini not found at $settingsPath" -ForegroundColor Red
        return
    }

    # Check and remove read-only attribute from original file if needed
    if ((Get-Item $settingsPath).IsReadOnly) {
        Set-ItemProperty $settingsPath -Name IsReadOnly -Value $false
        Write-Host "Removed read-only attribute from current settings file" -ForegroundColor Yellow
    }

    if (Test-Path $backupPath) {
        # Restore from backup
        Move-Item $backupPath $settingsPath -Force
        Write-Host "4K settings disabled (restored from backup)" -ForegroundColor Green
    }
    else {
        try {
            # Create backup and apply new settings
            Backup-File $settingsPath "_pre4kBackup.ini" | Out-Null
            $script:4kSettings | Out-File $settingsPath -Encoding utf8 -Force
            Write-Host "4K Ultra HD settings applied!" -ForegroundColor Green
            
            # Read-only prompt with improved handling
            $choice = Read-Host "`nSet file to READ-ONLY to prevent game overwrite? (Y/N)`n**YOU CAN'T CHANGE GRAPHICS OPTIONS WHILST IN GAME<-"
            if ($choice -in 'Y','y') {
                Set-ItemProperty $settingsPath -Name IsReadOnly -Value $true
                Write-Host "File set to read-only successfully!" -ForegroundColor Cyan
            }
            else {
                Write-Host "File remains writable. Game might reset your changes!" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Error applying settings: $_" -ForegroundColor Red
        }
    }
}

function Set-FOVSettings {
    param($fovOption)
    $enginePath = "$env:LOCALAPPDATA\fnaf9\Saved\Config\WindowsNoEditor\Engine.ini"
    
    if (-not (Test-Path $enginePath)) {
        Write-Host "Error: Engine.ini not found!" -ForegroundColor Red
        return
    }

    # Check and remove read-only attribute if needed
    if ((Get-Item $enginePath).IsReadOnly) {
        Set-ItemProperty $enginePath -Name IsReadOnly -Value $false
        Write-Host "Removed read-only attribute from Engine.ini" -ForegroundColor Yellow
    }

    $constraintMap = @{
        "YFOV" = "AspectRatio_MaintainYFOV"
        "XFOV" = "AspectRatio_MaintainXFOV"
        "MajorAxis" = "AspectRatio_MajorAxisFOV"
    }

    try {
        Backup-File $enginePath "_preFOVBackup.ini" | Out-Null
        
        $fovContent = @"
[Core.System]
Paths=../../../Engine/Content
Paths=%GAMEDIR%Content
Paths=../../../Engine/Plugins/Marketplace/MORT/Content
Paths=../../../Engine/Plugins/Runtime/Nvidia/RTXGI/Content
Paths=../../../Engine/Plugins/SWGMaterialTools/Content
Paths=../../../fnaf9/Plugins/SWGAIUtils/Content
Paths=../../../fnaf9/Plugins/SWGPlatformUtil/Content
Paths=../../../fnaf9/Plugins/Wwise/Content
Paths=../../../Engine/Plugins/Editor/GeometryMode/Content
Paths=../../../Engine/Plugins/2D/Paper2D/Content
Paths=../../../Engine/Plugins/Developer/AnimationSharing/Content
Paths=../../../Engine/Plugins/Enterprise/DatasmithContent/Content
Paths=../../../Engine/Plugins/Experimental/ChaosClothEditor/Content
Paths=../../../Engine/Plugins/Experimental/GeometryProcessing/Content
Paths=../../../Engine/Plugins/Experimental/GeometryCollectionPlugin/Content
Paths=../../../Engine/Plugins/Experimental/ChaosSolverPlugin/Content
Paths=../../../Engine/Plugins/Experimental/ChaosNiagara/Content
Paths=../../../Engine/Plugins/FX/Niagara/Content
Paths=../../../Engine/Plugins/MagicLeap/MagicLeapPassableWorld/Content
Paths=../../../Engine/Plugins/MagicLeap/MagicLeap/Content
Paths=../../../Engine/Plugins/Media/MediaCompositing/Content
Paths=../../../Engine/Plugins/MegascansPlugin/Content
Paths=../../../Engine/Plugins/Experimental/PythonScriptPlugin/Content
Paths=../../../Engine/Plugins/MovieScene/MovieRenderPipeline/Content

[/script/engine.localplayer]
AspectRatioAxisConstraint=$($constraintMap[$fovOption])
"@

        $fovContent | Out-File $enginePath -Encoding utf8 -Force
        Write-Host "FOV settings applied with $fovOption constraint!" -ForegroundColor Green
        
        # Read-only prompt for FOV settings
        $choice = Read-Host "`nSet file to READ-ONLY to prevent game overwrite? (Y/N)`n**Note: Game may reset FOV if not read-only**"
        if ($choice -in 'Y','y') {
            Set-ItemProperty $enginePath -Name IsReadOnly -Value $true
            Write-Host "Engine.ini set to read-only successfully!" -ForegroundColor Cyan
        }
        else {
            Write-Host "File remains writable. Game might reset your FOV changes!" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error applying FOV settings: $_" -ForegroundColor Red
    }
}

function Restore-Backups {
    $paths = @(
        "$env:LOCALAPPDATA\fnaf9\Saved\Config\WindowsNoEditor\GameUserSettings.ini",
        "$env:LOCALAPPDATA\fnaf9\Saved\Config\WindowsNoEditor\Engine.ini"
    )

    foreach ($path in $paths) {
        # Remove read-only attribute before restoring
        if ((Test-Path $path) -and (Get-Item $path).IsReadOnly) {
            Set-ItemProperty $path -Name IsReadOnly -Value $false
            Write-Host "Removed read-only attribute from $path" -ForegroundColor Yellow
        }

        $backup = $path -replace '\.ini$', '_pre4kBackup.ini'
        if (Test-Path $backup) {
            Move-Item $backup $path -Force
            Write-Host "Restored backup for $path" -ForegroundColor Green
        }
        
        $backup = $path -replace '\.ini$', '_preFOVBackup.ini'
        if (Test-Path $backup) {
            Move-Item $backup $path -Force
            Write-Host "Restored backup for $path" -ForegroundColor Green
        }
    }
}

# Main program loop
while ($true) {
    Show-Menu
    $choice = Read-Host "Please choose an option (1-4)"
    
    switch ($choice) {
        '1' {
            while ($true) {
                Show-FOVMenu
                $fovChoice = Read-Host "Choose FOV option (1-5)"
                switch ($fovChoice) {
                    '1' { Set-FOVSettings -fovOption "YFOV"; break }
                    '2' { Set-FOVSettings -fovOption "XFOV"; break }
                    '3' { Set-FOVSettings -fovOption "MajorAxis"; break }
                    '4' { Restore-Backups; break }
                    '5' { break }
                    default { Write-Host "Invalid option!" -ForegroundColor Red }
                }
                if ($fovChoice -eq '5') { break }
                Pause
            }
        }
        '2' { Set-4KResolution; Pause }
        '3' { Restore-Backups; Pause }
        '4' { exit }
        default { Write-Host "Invalid selection!" -ForegroundColor Red; Pause }
    }
}