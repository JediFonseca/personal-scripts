#Requires -RunAsAdministrator

<###
.SYNOPSIS
    Audita o estado da instalação customizada do Windows 11.

.DESCRIPTION
    Este script e ESTRITAMENTE SOMENTE LEITURA.

    Ele foi construido a partir de:
      - autounattend.xml fornecido pelo usuario;
      - windows_debloat2.ps1 fornecido pelo usuario.

    O objetivo e comparar o sistema atual com o estado-base esperado da
    instalacao customizada, sem considerar o script de pos-instalacao.

    O script NAO:
      - escreve no Registro;
      - instala, remove ou provisiona aplicativos;
      - habilita/desabilita recursos;
      - inicia/para/reconfigura servicos;
      - altera politicas;
      - cria/exclui arquivos;
      - cria/exclui tarefas agendadas;
      - altera contas;
      - exporta logs para disco.

    Saida:
      [ OK ]         estado conforme o baseline
      [ DIFERENTE ]  estado diferente do baseline
      [ AVISO ]      checagem heuristica/nao deterministica
      [ INFO ]       informacao complementar

    Codigo de saida:
      0 = nenhum estado obrigatorio divergente
      1 = pelo menos uma divergencia obrigatoria
      2 = divergencia + avisos/checagens incompletas

.NOTES
    Recomendado executar em PowerShell 5.1 ou superior, de preferencia 64-bit.

    Importante: parametros que aparecem apenas no comentario gerado pelo
    unattend-generator (por exemplo, selecao regional "Portugal", CapsLock
    e ScrollLock) nao sao tratados como baseline persistente neste auditor,
    porque os arquivos fornecidos nao gravam um estado pos-instalacao
    verificavel para esses itens.

    A hive HKU\DefaultUser nao e carregada para auditoria. Carrega-la exigiria
    uma operacao de estado. O auditor verifica o perfil atual (HKCU) e a hive
    .DEFAULT, que sao os estados persistentes relevantes sem carregar outra hive.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

# -----------------------------------------------------------------------------
# Contadores / formatacao
# -----------------------------------------------------------------------------

$script:DifferentCount = 0
$script:WarningCount   = 0
$script:OkCount        = 0
$script:InfoCount      = 0

function Write-Status {
    param(
        [Parameter(Mandatory)] [string] $Section,
        [Parameter(Mandatory)] [string] $Item,
        [Parameter(Mandatory)] [ValidateSet('OK','DIFERENTE','AVISO','INFO')] [string] $Status,
        [string] $Expected = '',
        [string] $Actual = '',
        [string] $Detail = ''
    )

    switch ($Status) {
        'OK'         { $script:OkCount++;       $color = 'Green';  $tag = '[ OK ]' }
        'DIFERENTE'  { $script:DifferentCount++; $color = 'Red';    $tag = '[ DIFERENTE ]' }
        'AVISO'      { $script:WarningCount++; $color = 'Yellow'; $tag = '[ AVISO ]' }
        'INFO'       { $script:InfoCount++;    $color = 'Cyan';   $tag = '[ INFO ]' }
    }

    Write-Host ("{0} {1} :: {2}" -f $tag, $Section, $Item) -ForegroundColor $color

    if ($Expected) {
        Write-Host ("    Esperado: {0}" -f $Expected)
    }
    if ($Actual) {
        Write-Host ("    Atual:    {0}" -f $Actual)
    }
    if ($Detail) {
        Write-Host ("    Detalhe:  {0}" -f $Detail)
    }
}

function Format-Value {
    param([AllowNull()] $Value)

    if ($null -eq $Value) {
        return '<ausente>'
    }

    if ($Value -is [byte[]]) {
        return ('0x' + (($Value | ForEach-Object { $_.ToString('X2') }) -join ''))
    }

    if ($Value -is [array]) {
        return (($Value | ForEach-Object { [string]$_ }) -join ', ')
    }

    return [string]$Value
}

# -----------------------------------------------------------------------------
# Baseline extraido do autounattend.xml + windows_debloat2.ps1
# -----------------------------------------------------------------------------

$AppsToRemove = @(
    'MicrosoftCorporationII.QuickAssist'
    'Microsoft.WindowsCamera'
    'Microsoft.BingWeather'
    'Microsoft.WindowsSoundRecorder'
    'Microsoft.WindowsFeedbackHub'
    'Microsoft.BingSearch'
    'Clipchamp.Clipchamp'
    'Microsoft.BingNews'
    'MSTeams'
    'Microsoft.Todos'
    'Microsoft.MicrosoftStickyNotes'
    'Microsoft.OutlookForWindows'
    'Microsoft.Paint'
    'Microsoft.MSPaint'
    'Microsoft.PowerAutomateDesktop'
    'Microsoft.WindowsAlarms'
    'Microsoft.ZuneMusic'
    'Microsoft.MicrosoftSolitaireCollection'
    'Microsoft.GamingApp'
    'Microsoft.XboxGamingOverlay'
    'Microsoft.GetHelp'
    'Microsoft.Windows.DevHome'
    'Microsoft.YourPhone'
    'Microsoft.Copilot'
    'Microsoft.Windows.Ai.Copilot.Provider'
    'Microsoft.549981C3F5F10'
    'MicrosoftCorporationII.MicrosoftFamily'
    'Microsoft.Edge.GameAssist'
    'Microsoft.Getstarted'
    'microsoft.windowscommunicationsapps'
    'Microsoft.WindowsMaps'
    'Microsoft.MixedReality.Portal'
    'Microsoft.MicrosoftOfficeHub'
    'Microsoft.Office.OneNote'
    'Microsoft.Microsoft3DViewer'
    'Microsoft.WindowsStore'
    'Microsoft.StorePurchaseApp'
    'Microsoft.People'
    'Microsoft.SkypeApp'
    'Microsoft.Wallet'
    'Microsoft.ZuneVideo'
    'MicrosoftTeams'
    'Microsoft.Xbox.TCUI'
    'Microsoft.XboxApp'
    'Microsoft.XboxGameOverlay'
    'Microsoft.XboxIdentityProvider'
    'Microsoft.XboxSpeechToTextOverlay'
    # Em alguns builds o nome usado pelo debloat inclui tambem este pacote.
    'Microsoft.XboxGamingOverlay'
)
$AppsToRemove = $AppsToRemove | Sort-Object -Unique

$CapabilitiesToRemove = @(
    'Language.Handwriting'
    'MathRecognizer'
    'OneCoreUAP.OneSync'
    'App.StepsRecorder'
    'App.Support.QuickAssist'
    'Language.Speech'
    'Language.TextToSpeech'
    'Hello.Face.18967'
    'Hello.Face.Migration.18967'
    'Hello.Face.20134'
    'Microsoft.Windows.MSPaint'
    'Microsoft.Windows.WordPad'
)

$FeaturesToRemove = @(
    'Microsoft-RemoteDesktopConnection'
    'Recall'
)

$RegistryKeysToDelete = @(
    'SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate'
    'SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate'
)

$ContentDeliveryManagerKeys = @(
    'ContentDeliveryAllowed'
    'FeatureManagementEnabled'
    'OEMPreInstalledAppsEnabled'
    'PreInstalledAppsEnabled'
    'PreInstalledAppsEverEnabled'
    'SilentInstalledAppsEnabled'
    'SoftLandingEnabled'
    'SubscribedContentEnabled'
    'SubscribedContent-310093Enabled'
    'SubscribedContent-338387Enabled'
    'SubscribedContent-338388Enabled'
    'SubscribedContent-338389Enabled'
    'SubscribedContent-338393Enabled'
    'SubscribedContent-353694Enabled'
    'SubscribedContent-353696Enabled'
    'SubscribedContent-353698Enabled'
    'SystemPaneSuggestionsEnabled'
)

$DesktopIconsHidden = @(
    '{5399e694-6ce5-4d6c-8fce-1d8870fdcba0}'
    '{b4bfcc3a-db2c-424c-b029-7fe99a87c641}'
    '{a8cdff1c-4878-43be-b5fd-f8091c1c60d0}'
    '{374de290-123f-4565-9164-39c4925e467b}'
    '{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}'
    '{f874310e-b6b7-47dc-bc84-b9e6b38f5903}'
    '{1cf1260c-4dd0-4ebb-811f-33c572699fde}'
    '{f02c1a0d-be21-4350-88b0-7367fc96ef3c}'
    '{3add1653-eb32-4cb0-bbd7-dfa0abb5acca}'
    '{20d04fe0-3aea-1069-a2d8-08002b30309d}'
    '{59031a47-3f72-44a7-89c5-5595fe6b30ee}'
    '{a0953c92-50dc-43bf-be83-3742fed03c9c}'
)

$RecycleBinClsid = '{645ff040-5081-101b-9f08-00aa002f954e}'

# Registro HKCU
$RegistryTweaksHKCU = @(
    @{ Path='Software\Policies\Microsoft\Windows\WindowsCopilot'; Name='TurnOffWindowsCopilot'; Type='REG_DWORD'; Value=1 }
    @{ Path='Software\Microsoft\Windows\CurrentVersion\GameDVR'; Name='AppCaptureEnabled'; Type='REG_DWORD'; Value=0 }
    @{ Path='Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='HideFileExt'; Type='REG_DWORD'; Value=0 }
    @{ Path='Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='LaunchTo'; Type='REG_DWORD'; Value=1 }
    @{ Path='Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='TaskbarAl'; Type='REG_DWORD'; Value=0 }
    @{ Path='Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='ShowTaskViewButton'; Type='REG_DWORD'; Value=0 }
    @{ Path='Software\Microsoft\Windows\CurrentVersion\Search'; Name='SearchboxTaskbarMode'; Type='REG_DWORD'; Value=0 }
    @{ Path='Software\Microsoft\Edge\SmartScreenEnabled'; Name=''; Type='REG_DWORD'; Value=0 }
    @{ Path='Software\Microsoft\Edge\SmartScreenPuaEnabled'; Name=''; Type='REG_DWORD'; Value=0 }
    @{ Path='Software\Microsoft\Windows\CurrentVersion\AppHost'; Name='EnableWebContentEvaluation'; Type='REG_DWORD'; Value=0 }
    @{ Path='Software\Microsoft\Windows\CurrentVersion\AppHost'; Name='PreventOverride'; Type='REG_DWORD'; Value=0 }
    @{ Path='Software\Policies\Microsoft\Windows\Explorer'; Name='DisableSearchBoxSuggestions'; Type='REG_DWORD'; Value=1 }
    @{ Path='Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'; Name='TaskbarEndTask'; Type='REG_DWORD'; Value=1 }
    @{ Path='Control Panel\Accessibility\StickyKeys'; Name='Flags'; Type='REG_SZ'; Value='10' }
    @{ Path='Control Panel\Keyboard'; Name='InitialKeyboardIndicators'; Type='REG_SZ'; Value='2' }
)

# Registro HKLM
$RegistryTweaksHKLM = @(
    @{ Path='SOFTWARE\Microsoft\Windows\CurrentVersion\Communications'; Name='ConfigureChatAutoInstall'; Type='REG_DWORD'; Value=0 }
    @{ Path='SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name='SmartScreenEnabled'; Type='REG_SZ'; Value='Off' }
    @{ Path='SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components'; Name='ServiceEnabled'; Type='REG_DWORD'; Value=0 }
    @{ Path='SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components'; Name='NotifyMalicious'; Type='REG_DWORD'; Value=0 }
    @{ Path='SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components'; Name='NotifyPasswordReuse'; Type='REG_DWORD'; Value=0 }
    @{ Path='SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components'; Name='NotifyUnsafeApp'; Type='REG_DWORD'; Value=0 }
    @{ Path='SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Systray'; Name='HideSystray'; Type='REG_DWORD'; Value=1 }
    @{ Path='SYSTEM\CurrentControlSet\Control\CI\Policy'; Name='VerifiedAndReputablePolicyState'; Type='REG_DWORD'; Value=0 }
    @{ Path='System\CurrentControlSet\Control\DeviceGuard'; Name='EnableVirtualizationBasedSecurity'; Type='REG_DWORD'; Value=0 }
    @{ Path='System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'; Name='Enabled'; Type='REG_DWORD'; Value=0 }
    @{ Path='System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'; Name='EnabledBootId'; Type='REG_DWORD'; Value=0 }
    @{ Path='System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'; Name='WasEnabledBy'; Type='REG_DWORD'; Value=0 }
    @{ Path='SYSTEM\CurrentControlSet\Control\FileSystem'; Name='LongPathsEnabled'; Type='REG_DWORD'; Value=1 }
    @{ Path='SYSTEM\CurrentControlSet\Control\Session Manager\Power'; Name='HiberbootEnabled'; Type='REG_DWORD'; Value=0 }
    @{ Path='SOFTWARE\Policies\Microsoft\Dsh'; Name='AllowNewsAndInterests'; Type='REG_DWORD'; Value=0 }
    @{ Path='Software\Policies\Microsoft\Windows\CloudContent'; Name='DisableWindowsConsumerFeatures'; Type='REG_DWORD'; Value=1 }
    @{ Path='Software\Policies\Microsoft\Windows\CloudContent'; Name='DisableCloudOptimizedContent'; Type='REG_DWORD'; Value=1 }
    @{ Path='SOFTWARE\Microsoft\Windows\CurrentVersion\Communications'; Name='ConfigureChatAutoInstall'; Type='REG_DWORD'; Value=0 }
    @{ Path='SYSTEM\CurrentControlSet\Control\BitLocker'; Name='PreventDeviceEncryption'; Type='REG_DWORD'; Value=1 }
    @{ Path='Software\Policies\Microsoft\Edge'; Name='HideFirstRunExperience'; Type='REG_DWORD'; Value=1 }
    @{ Path='Software\Policies\Microsoft\Edge\Recommended'; Name='BackgroundModeEnabled'; Type='REG_DWORD'; Value=0 }
    @{ Path='Software\Policies\Microsoft\Edge\Recommended'; Name='StartupBoostEnabled'; Type='REG_DWORD'; Value=0 }
    @{ Path='SOFTWARE\Microsoft\PolicyManager\current\device\Start'; Name='ConfigureStartPins'; Type='REG_SZ'; Value='{"pinnedList":[]}' }
)

# A entrada ConfigureStartPins aparece como HKLM no autounattend e no debloat.
# Mantemos uma unica entrada no baseline mesmo que a origem a escreva em momentos diferentes.
$RegistryTweaksHKLM = $RegistryTweaksHKLM | Sort-Object Path, Name -Unique

# HKU\.DEFAULT
$RegistryTweaksDefault = @(
    @{ Path='Control Panel\Accessibility\StickyKeys'; Name='Flags'; Type='REG_SZ'; Value='10' }
    @{ Path='Control Panel\Keyboard'; Name='InitialKeyboardIndicators'; Type='REG_SZ'; Value='2' }
)

# HKCU Start / Explorer (valores que merecem comparacao byte-a-byte / arquivo)
$ExpectedVisiblePlaces = [byte[]](0x86,0x08,0x73,0x52,0xAA,0x51,0x43,0x42,0x9F,0x7B,0x27,0x76,0x58,0x46,0x59,0xD4)

# -----------------------------------------------------------------------------
# Helpers de Registro (somente leitura)
# -----------------------------------------------------------------------------

function Get-RegistryHiveAndSubPath {
    param(
        [Parameter(Mandatory)] [ValidateSet('HKLM','HKCU','HKU_DEFAULT')] [string] $Root,
        [Parameter(Mandatory)] [string] $Path
    )

    switch ($Root) {
        'HKLM' {
            return @{ Hive=[Microsoft.Win32.RegistryHive]::LocalMachine; SubPath=$Path }
        }
        'HKCU' {
            return @{ Hive=[Microsoft.Win32.RegistryHive]::CurrentUser; SubPath=$Path }
        }
        'HKU_DEFAULT' {
            return @{ Hive=[Microsoft.Win32.RegistryHive]::Users; SubPath=('.DEFAULT\' + $Path) }
        }
    }
}

function Get-RegistryValueInfo {
    param(
        [Parameter(Mandatory)] [ValidateSet('HKLM','HKCU','HKU_DEFAULT')] [string] $Root,
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Name
    )

    $spec = Get-RegistryHiveAndSubPath -Root $Root -Path $Path
    $view = if ([Environment]::Is64BitOperatingSystem) {
        [Microsoft.Win32.RegistryView]::Registry64
    } else {
        [Microsoft.Win32.RegistryView]::Default
    }

    $base = $null
    $key = $null

    try {
        $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey($spec.Hive, $view)
        $key = $base.OpenSubKey($spec.SubPath, $false)

        if ($null -eq $key) {
            return [pscustomobject]@{ Exists=$false; Value=$null; Kind=$null }
        }

        $names = @($key.GetValueNames())
        if (-not ($names -contains $Name)) {
            return [pscustomobject]@{ Exists=$false; Value=$null; Kind=$null }
        }

        $value = $key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $kind = $key.GetValueKind($Name)

        return [pscustomobject]@{ Exists=$true; Value=$value; Kind=$kind }
    }
    catch {
        return [pscustomobject]@{ Exists=$false; Value=$null; Kind=$null; Error=$_.Exception.Message }
    }
    finally {
        if ($key) { $key.Dispose() }
        if ($base) { $base.Dispose() }
    }
}

function Test-RegistryValue {
    param(
        [Parameter(Mandatory)] [ValidateSet('HKLM','HKCU','HKU_DEFAULT')] [string] $Root,
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [ValidateSet('REG_DWORD','REG_SZ','REG_BINARY')] [string] $Type,
        [Parameter(Mandatory)] $Expected,
        [string] $Label = ''
    )

    $info = Get-RegistryValueInfo -Root $Root -Path $Path -Name $Name
    $full = "${Root}:\$Path" + ($(if ($Name -eq '') { '\(Padrão)' } else { "\$Name" }))
    $title = if ($Label) { $Label } else { $full }

    $expectedKind = switch ($Type) {
        'REG_DWORD' { [Microsoft.Win32.RegistryValueKind]::DWord }
        'REG_SZ'    { [Microsoft.Win32.RegistryValueKind]::String }
        'REG_BINARY'{ [Microsoft.Win32.RegistryValueKind]::Binary }
    }

    if (-not $info.Exists) {
        Write-Status -Section 'Registro' -Item $title -Status 'DIFERENTE' -Expected ("$Type = " + (Format-Value $Expected)) -Actual '<ausente>'
        return
    }

    $valueOk = $false
    if ($Type -eq 'REG_BINARY') {
        $actualBytes = [byte[]]$info.Value
        $expectedBytes = [byte[]]$Expected
        $valueOk = [System.Linq.Enumerable]::SequenceEqual($actualBytes, $expectedBytes)
    } else {
        $valueOk = ([string]$info.Value -eq [string]$Expected)
    }

    $kindOk = ($info.Kind -eq $expectedKind)

    if ($valueOk -and $kindOk) {
        Write-Status -Section 'Registro' -Item $title -Status 'OK' -Expected ("$Type = " + (Format-Value $Expected)) -Actual ("$($info.Kind) = " + (Format-Value $info.Value))
    } elseif (-not $kindOk -and $valueOk) {
        Write-Status -Section 'Registro' -Item $title -Status 'DIFERENTE' -Expected ("tipo $Type; valor " + (Format-Value $Expected)) -Actual ("tipo $($info.Kind); valor " + (Format-Value $info.Value))
    } else {
        Write-Status -Section 'Registro' -Item $title -Status 'DIFERENTE' -Expected ("$Type = " + (Format-Value $Expected)) -Actual ("$($info.Kind) = " + (Format-Value $info.Value))
    }
}

function Test-RegistryKeyAbsent {
    param(
        [Parameter(Mandatory)] [ValidateSet('HKLM','HKCU','HKU_DEFAULT')] [string] $Root,
        [Parameter(Mandatory)] [string] $Path,
        [string] $Label = ''
    )

    $spec = Get-RegistryHiveAndSubPath -Root $Root -Path $Path
    $view = if ([Environment]::Is64BitOperatingSystem) {
        [Microsoft.Win32.RegistryView]::Registry64
    } else {
        [Microsoft.Win32.RegistryView]::Default
    }
    $base = $null
    $key = $null

    try {
        $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey($spec.Hive, $view)
        $key = $base.OpenSubKey($spec.SubPath, $false)
        $exists = ($null -ne $key)
    }
    catch {
        $exists = $false
    }
    finally {
        if ($key) { $key.Dispose() }
        if ($base) { $base.Dispose() }
    }

    $title = if ($Label) { $Label } else { "${Root}:\$Path" }
    if (-not $exists) {
        Write-Status -Section 'Registro' -Item $title -Status 'OK' -Expected '<chave ausente>' -Actual '<ausente>'
    } else {
        Write-Status -Section 'Registro' -Item $title -Status 'DIFERENTE' -Expected '<chave ausente>' -Actual '<presente>'
    }
}

# -----------------------------------------------------------------------------
# Cache de consultas somente-leitura
# -----------------------------------------------------------------------------

Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ' AUDITORIA DO BASELINE - WINDOWS 11 CUSTOMIZADO' -ForegroundColor Cyan
Write-Host ' SOMENTE LEITURA - NENHUMA MODIFICACAO SERA FEITA' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ''

if (-not [Environment]::Is64BitProcess) {
    Write-Status -Section 'Ambiente' -Item 'PowerShell 64-bit' -Status 'AVISO' -Expected 'Processo 64-bit' -Actual 'Processo 32-bit' -Detail 'O auditor tenta ler HKLM usando Registry64, mas recomenda-se PowerShell 64-bit.'
} else {
    Write-Status -Section 'Ambiente' -Item 'PowerShell 64-bit' -Status 'OK' -Expected 'Processo 64-bit' -Actual 'Processo 64-bit'
}

$AllAppx = @()
$ProvisionedAppx = @()
$AllCapabilities = @()
$AllOptionalFeatures = @()

try { $AllAppx = @(Get-AppxPackage -AllUsers | Select-Object Name, PackageFullName) } catch { Write-Status -Section 'Preparacao' -Item 'Get-AppxPackage -AllUsers' -Status 'AVISO' -Detail $_.Exception.Message }
try { $ProvisionedAppx = @(Get-AppxProvisionedPackage -Online | Select-Object DisplayName, PackageName) } catch { Write-Status -Section 'Preparacao' -Item 'Get-AppxProvisionedPackage -Online' -Status 'AVISO' -Detail $_.Exception.Message }
try { $AllCapabilities = @(Get-WindowsCapability -Online) } catch { Write-Status -Section 'Preparacao' -Item 'Get-WindowsCapability -Online' -Status 'AVISO' -Detail $_.Exception.Message }
try { $AllOptionalFeatures = @(Get-WindowsOptionalFeature -Online) } catch { Write-Status -Section 'Preparacao' -Item 'Get-WindowsOptionalFeature -Online' -Status 'AVISO' -Detail $_.Exception.Message }

# -----------------------------------------------------------------------------
# 1. Identidade / estado definido no autounattend
# -----------------------------------------------------------------------------

$ExpectedComputerName = 'windowsn7'
$ExpectedTimeZoneId = 'E. South America Standard Time'
$ExpectedLocalUser = 'jedifonseca'

$computerName = $env:COMPUTERNAME
if ($computerName -eq $ExpectedComputerName) {
    Write-Status -Section 'Sistema' -Item 'Nome do computador' -Status 'OK' -Expected $ExpectedComputerName -Actual $computerName
} else {
    Write-Status -Section 'Sistema' -Item 'Nome do computador' -Status 'DIFERENTE' -Expected $ExpectedComputerName -Actual $computerName
}

try {
    $tz = Get-TimeZone
    if ($tz.Id -eq $ExpectedTimeZoneId) {
        Write-Status -Section 'Sistema' -Item 'Fuso horario' -Status 'OK' -Expected $ExpectedTimeZoneId -Actual ("{0} ({1})" -f $tz.Id, $tz.DisplayName)
    } else {
        Write-Status -Section 'Sistema' -Item 'Fuso horario' -Status 'DIFERENTE' -Expected $ExpectedTimeZoneId -Actual ("{0} ({1})" -f $tz.Id, $tz.DisplayName)
    }
} catch {
    Write-Status -Section 'Sistema' -Item 'Fuso horario' -Status 'AVISO' -Detail $_.Exception.Message
}

try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $productName = [string]$os.Caption
    if ($productName -match 'Windows 11 Pro') {
        Write-Status -Section 'Sistema' -Item 'Edicao do Windows' -Status 'OK' -Expected 'Windows 11 Pro' -Actual $productName
    } else {
        Write-Status -Section 'Sistema' -Item 'Edicao do Windows' -Status 'DIFERENTE' -Expected 'Windows 11 Pro' -Actual $productName
    }
} catch {
    Write-Status -Section 'Sistema' -Item 'Edicao do Windows' -Status 'AVISO' -Detail $_.Exception.Message
}

try {
    $user = Get-LocalUser -Name $ExpectedLocalUser -ErrorAction SilentlyContinue
    if ($user) {
        Write-Status -Section 'Conta' -Item 'Conta local criada pelo unattend' -Status 'OK' -Expected $ExpectedLocalUser -Actual ("$($user.Name) | Ativa=$($user.Enabled)")
    } else {
        Write-Status -Section 'Conta' -Item 'Conta local criada pelo unattend' -Status 'DIFERENTE' -Expected $ExpectedLocalUser -Actual '<ausente>'
    }

    $adminGroup = Get-LocalGroup -SID ([System.Security.Principal.SecurityIdentifier]'S-1-5-32-544') -ErrorAction SilentlyContinue
    if ($adminGroup) {
        $members = @(Get-LocalGroupMember -Group $adminGroup.Name -ErrorAction SilentlyContinue)
        $member = $members | Where-Object { $_.Name -match "(^|\\)$([regex]::Escape($ExpectedLocalUser))$" } | Select-Object -First 1
        if ($member) {
            Write-Status -Section 'Conta' -Item 'Conta membro de Administrators' -Status 'OK' -Expected "Membro de $($adminGroup.Name)" -Actual $member.Name
        } else {
            Write-Status -Section 'Conta' -Item 'Conta membro de Administrators' -Status 'DIFERENTE' -Expected "Membro de $($adminGroup.Name)" -Actual '<nao encontrado>'
        }
    } else {
        Write-Status -Section 'Conta' -Item 'Grupo Administrators' -Status 'AVISO' -Detail 'Nao foi possivel localizar o grupo pelo SID S-1-5-32-544.'
    }
} catch {
    Write-Status -Section 'Conta' -Item 'Conta local / grupo Administrators' -Status 'AVISO' -Detail $_.Exception.Message
}

Test-RegistryValue -Root 'HKLM' -Path 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'AutoLogonCount' -Type 'REG_DWORD' -Expected 0 -Label 'Winlogon: AutoLogonCount = 0 (apos o primeiro logon)'

# RunOnce UnattendedSetup e esperado ter sido consumido pelo primeiro logon.
$runOnceInfo = Get-RegistryValueInfo -Root 'HKCU' -Path 'Software\Microsoft\Windows\CurrentVersion\RunOnce' -Name 'UnattendedSetup'
if (-not $runOnceInfo.Exists) {
    Write-Status -Section 'Autologon/OOBE' -Item 'RunOnce: UnattendedSetup' -Status 'OK' -Expected '<ausente apos o primeiro logon>' -Actual '<ausente>'
} else {
    Write-Status -Section 'Autologon/OOBE' -Item 'RunOnce: UnattendedSetup' -Status 'DIFERENTE' -Expected '<ausente apos o primeiro logon>' -Actual (Format-Value $runOnceInfo.Value)
}

# -----------------------------------------------------------------------------
# 2. AppX removidos (instalados + provisionados)
# -----------------------------------------------------------------------------

foreach ($app in $AppsToRemove) {
    $installed = @($AllAppx | Where-Object { $_.Name -eq $app })
    $provisioned = @($ProvisionedAppx | Where-Object { $_.DisplayName -eq $app })

    if (($installed.Count -eq 0) -and ($provisioned.Count -eq 0)) {
        Write-Status -Section 'AppX' -Item $app -Status 'OK' -Expected '<nao instalado e nao provisionado>' -Actual '<ausente>'
    } else {
        $details = @()
        if ($installed.Count -gt 0) { $details += 'instalado: ' + (($installed.PackageFullName) -join ', ') }
        if ($provisioned.Count -gt 0) { $details += 'provisionado: ' + (($provisioned.PackageName) -join ', ') }
        Write-Status -Section 'AppX' -Item $app -Status 'DIFERENTE' -Expected '<nao instalado e nao provisionado>' -Actual ($details -join ' | ')
    }
}

# -----------------------------------------------------------------------------
# 3. Capabilities removidas
# -----------------------------------------------------------------------------

foreach ($capability in $CapabilitiesToRemove) {
    $found = @($AllCapabilities | Where-Object { $_.Name -like "$capability*" })

    if ($found.Count -eq 0) {
        Write-Status -Section 'Capability' -Item $capability -Status 'OK' -Expected 'nao instalado / removido' -Actual '<nao presente na imagem>'
        continue
    }

    $bad = @($found | Where-Object { $_.State -notin @('NotPresent','Removed') })
    if ($bad.Count -eq 0) {
        $states = (($found | ForEach-Object { "{0}={1}" -f $_.Name, $_.State }) -join ', ')
        Write-Status -Section 'Capability' -Item $capability -Status 'OK' -Expected 'NotPresent ou Removed' -Actual $states
    } else {
        $states = (($found | ForEach-Object { "{0}={1}" -f $_.Name, $_.State }) -join ', ')
        Write-Status -Section 'Capability' -Item $capability -Status 'DIFERENTE' -Expected 'NotPresent ou Removed' -Actual $states
    }
}

# -----------------------------------------------------------------------------
# 4. Optional Features removidas
# -----------------------------------------------------------------------------

foreach ($feature in $FeaturesToRemove) {
    $found = @($AllOptionalFeatures | Where-Object { $_.FeatureName -eq $feature })

    if ($found.Count -eq 0) {
        Write-Status -Section 'Optional Feature' -Item $feature -Status 'OK' -Expected 'nao habilitado / removido' -Actual '<feature nao presente neste build>'
        continue
    }

    $bad = @($found | Where-Object { $_.State -notin @('Disabled','DisabledWithPayloadRemoved') })
    if ($bad.Count -eq 0) {
        Write-Status -Section 'Optional Feature' -Item $feature -Status 'OK' -Expected 'Disabled ou DisabledWithPayloadRemoved' -Actual $found.State
    } else {
        Write-Status -Section 'Optional Feature' -Item $feature -Status 'DIFERENTE' -Expected 'Disabled ou DisabledWithPayloadRemoved' -Actual $found.State
    }
}

# -----------------------------------------------------------------------------
# 5. Registro HKCU
# -----------------------------------------------------------------------------

foreach ($tweak in $RegistryTweaksHKCU) {
    Test-RegistryValue -Root 'HKCU' -Path $tweak.Path -Name $tweak.Name -Type $tweak.Type -Expected $tweak.Value
}

# ContentDeliveryManager
foreach ($name in $ContentDeliveryManagerKeys) {
    Test-RegistryValue -Root 'HKCU' -Path 'Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name $name -Type 'REG_DWORD' -Expected 0
}

# VisiblePlaces
Test-RegistryValue -Root 'HKCU' -Path 'Software\Microsoft\Windows\CurrentVersion\Start' -Name 'VisiblePlaces' -Type 'REG_BINARY' -Expected $ExpectedVisiblePlaces

# Menu de contexto classico (valor padrao vazio)
Test-RegistryValue -Root 'HKCU' -Path 'Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' -Name '' -Type 'REG_SZ' -Expected '' -Label 'Menu de contexto classico'

# Start menu / desktop icons, para ambos os modos gravados pelo script.
foreach ($panel in @('ClassicStartMenu','NewStartPanel')) {
    foreach ($icon in $DesktopIconsHidden) {
        Test-RegistryValue -Root 'HKCU' -Path "Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\$panel" -Name $icon -Type 'REG_DWORD' -Expected 1
    }
    Test-RegistryValue -Root 'HKCU' -Path "Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\$panel" -Name $RecycleBinClsid -Type 'REG_DWORD' -Expected 0 -Label "Icones da area de trabalho [$panel]: Lixeira"
}

# -----------------------------------------------------------------------------
# 6. Registro HKLM
# -----------------------------------------------------------------------------

foreach ($tweak in $RegistryTweaksHKLM) {
    Test-RegistryValue -Root 'HKLM' -Path $tweak.Path -Name $tweak.Name -Type $tweak.Type -Expected $tweak.Value
}

foreach ($key in $RegistryKeysToDelete) {
    Test-RegistryKeyAbsent -Root 'HKLM' -Path $key
}

# -----------------------------------------------------------------------------
# 7. Registro HKU\.DEFAULT
# -----------------------------------------------------------------------------

foreach ($tweak in $RegistryTweaksDefault) {
    Test-RegistryValue -Root 'HKU_DEFAULT' -Path $tweak.Path -Name $tweak.Name -Type $tweak.Type -Expected $tweak.Value
}

# -----------------------------------------------------------------------------
# 8. Windows Search
# -----------------------------------------------------------------------------

try {
    $wsearch = Get-CimInstance -ClassName Win32_Service -Filter "Name='WSearch'"
    if (-not $wsearch) {
        Write-Status -Section 'Servico' -Item 'Windows Search (WSearch)' -Status 'DIFERENTE' -Expected 'servico presente, StartMode=Disabled, State=Stopped' -Actual '<servico nao encontrado>'
    } else {
        $startModeOk = ($wsearch.StartMode -eq 'Disabled')
        $stateOk = ($wsearch.State -eq 'Stopped')
        if ($startModeOk -and $stateOk) {
            Write-Status -Section 'Servico' -Item 'Windows Search (WSearch)' -Status 'OK' -Expected 'StartMode=Disabled; State=Stopped' -Actual "StartMode=$($wsearch.StartMode); State=$($wsearch.State)"
        } else {
            Write-Status -Section 'Servico' -Item 'Windows Search (WSearch)' -Status 'DIFERENTE' -Expected 'StartMode=Disabled; State=Stopped' -Actual "StartMode=$($wsearch.StartMode); State=$($wsearch.State)"
        }
    }
} catch {
    Write-Status -Section 'Servico' -Item 'Windows Search (WSearch)' -Status 'AVISO' -Detail $_.Exception.Message
}

# -----------------------------------------------------------------------------
# 9. fsutil: DisableLastAccess
# -----------------------------------------------------------------------------

try {
    $fsutilOutput = (& fsutil.exe behavior query disablelastaccess 2>&1 | Out-String).Trim()
    $m = [regex]::Match($fsutilOutput, '(?im)DisableLastAccess\s*=\s*(\d+)')
    if ($m.Success) {
        $actual = [int]$m.Groups[1].Value
        if ($actual -eq 1) {
            Write-Status -Section 'Sistema de arquivos' -Item 'DisableLastAccess' -Status 'OK' -Expected '1' -Actual $actual
        } else {
            Write-Status -Section 'Sistema de arquivos' -Item 'DisableLastAccess' -Status 'DIFERENTE' -Expected '1' -Actual $actual
        }
    } else {
        Write-Status -Section 'Sistema de arquivos' -Item 'DisableLastAccess' -Status 'AVISO' -Expected '1' -Actual '<nao foi possivel interpretar a saida>' -Detail $fsutilOutput
    }
} catch {
    Write-Status -Section 'Sistema de arquivos' -Item 'DisableLastAccess' -Status 'AVISO' -Expected '1' -Detail $_.Exception.Message
}

# -----------------------------------------------------------------------------
# 10. Politica de senha: /maxpwage:UNLIMITED
# -----------------------------------------------------------------------------

try {
    $netAccounts = (& net.exe accounts 2>&1 | Out-String).Trim()

    $passwordAgeLine = $netAccounts -split "`r?`n" | Where-Object {
        $_ -match '(?i)(máximo|maximum).*(senha|password)|(senha|password).*(máximo|maximum)'
    } | Select-Object -First 1

    if (-not $passwordAgeLine) {
        $passwordAgeLine = $netAccounts -split "`r?`n" | Where-Object {
            $_ -match '(?i)(password|senha).*(age|idade|val|vál)' -or $_ -match '(?i)(age|idade).*(password|senha)'
        } | Select-Object -First 1
    }

    if ($passwordAgeLine) {
        $valueText = (($passwordAgeLine -split ':',2)[-1]).Trim()
        if ($valueText -match '(?i)^(unlimited|ilimitado|nunca|never|0)$') {
            Write-Status -Section 'Politica' -Item 'Tempo maximo de senha' -Status 'OK' -Expected 'Unlimited / Ilimitado / Nunca' -Actual $valueText
        } else {
            Write-Status -Section 'Politica' -Item 'Tempo maximo de senha' -Status 'DIFERENTE' -Expected 'Unlimited / Ilimitado / Nunca' -Actual $valueText
        }
    } else {
        Write-Status -Section 'Politica' -Item 'Tempo maximo de senha' -Status 'AVISO' -Expected 'Unlimited / Ilimitado / Nunca' -Actual '<linha nao identificada>' -Detail $netAccounts
    }
} catch {
    Write-Status -Section 'Politica' -Item 'Tempo maximo de senha' -Status 'AVISO' -Detail $_.Exception.Message
}

# -----------------------------------------------------------------------------
# 11. OneDrive: estados explicitamente removidos pelos dois scripts
# -----------------------------------------------------------------------------

$OneDriveRemovedPaths = @(
    'C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk'
    'C:\Windows\System32\OneDriveSetup.exe'
    'C:\Windows\SysWOW64\OneDriveSetup.exe'
)

foreach ($path in $OneDriveRemovedPaths) {
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Status -Section 'OneDrive' -Item $path -Status 'OK' -Expected '<ausente>' -Actual '<ausente>'
    } else {
        Write-Status -Section 'OneDrive' -Item $path -Status 'DIFERENTE' -Expected '<ausente>' -Actual '<presente>'
    }
}

$oneDriveRun = Get-RegistryValueInfo -Root 'HKCU' -Path 'Software\Microsoft\Windows\CurrentVersion\Run' -Name 'OneDriveSetup'
if (-not $oneDriveRun.Exists) {
    Write-Status -Section 'OneDrive' -Item 'HKCU Run: OneDriveSetup' -Status 'OK' -Expected '<ausente>' -Actual '<ausente>'
} else {
    Write-Status -Section 'OneDrive' -Item 'HKCU Run: OneDriveSetup' -Status 'DIFERENTE' -Expected '<ausente>' -Actual (Format-Value $oneDriveRun.Value)
}

# -----------------------------------------------------------------------------
# 12. Artefatos que o autounattend explicitamente remove apos o primeiro logon
# -----------------------------------------------------------------------------

$ExpectedAbsentSetupFiles = @(
    'C:\Windows\Panther\unattend.xml'
    'C:\Windows\Panther\unattend-original.xml'
    'C:\Windows\Setup\Scripts\Wifi.xml'
)

foreach ($path in $ExpectedAbsentSetupFiles) {
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Status -Section 'Setup' -Item $path -Status 'OK' -Expected '<ausente apos o primeiro logon>' -Actual '<ausente>'
    } else {
        Write-Status -Section 'Setup' -Item $path -Status 'DIFERENTE' -Expected '<ausente apos o primeiro logon>' -Actual '<presente>'
    }
}

# -----------------------------------------------------------------------------
# 13. Artefatos persistentes criados pelo autounattend
# -----------------------------------------------------------------------------

$ExpectedPersistentSetupFiles = @(
    'C:\Windows\Setup\Scripts\RemovePackage.ps1'
    'C:\Windows\Setup\Scripts\RemoveCapability.ps1'
    'C:\Windows\Setup\Scripts\RemoveFeature.ps1'
    'C:\Windows\Setup\Scripts\TaskbarLayoutModification.xml'
    'C:\Windows\Setup\Scripts\UnlockStartLayout.vbs'
    'C:\Windows\Setup\Scripts\UnlockStartLayout.xml'
    'C:\Windows\Setup\Scripts\SetStartPins.ps1'
    'C:\Windows\Setup\Scripts\Specialize.ps1'
    'C:\Windows\Setup\Scripts\UserOnce.ps1'
    'C:\Windows\Setup\Scripts\DefaultUser.ps1'
    'C:\Windows\Setup\Scripts\FirstLogon.ps1'
)

foreach ($path in $ExpectedPersistentSetupFiles) {
    if (Test-Path -LiteralPath $path) {
        Write-Status -Section 'Artefatos do baseline' -Item $path -Status 'OK' -Expected '<presente>' -Actual '<presente>'
    } else {
        Write-Status -Section 'Artefatos do baseline' -Item $path -Status 'DIFERENTE' -Expected '<presente>' -Actual '<ausente>'
    }
}

# Conteudo estrutural do TaskbarLayoutModification.xml conforme o unattend.
$layoutPath = 'C:\Windows\Setup\Scripts\TaskbarLayoutModification.xml'
if (Test-Path -LiteralPath $layoutPath) {
    try {
        $actualLayout = (Get-Content -LiteralPath $layoutPath -Raw)
        $normalizedLayout = ($actualLayout -replace '\s+', '')
        $expectedLayout = '<LayoutModificationTemplatexmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"Version="1"><CustomTaskbarLayoutCollectionPinListPlacement="Replace"><defaultlayout:TaskbarLayout><taskbar:TaskbarPinList><taskbar:DesktopAppDesktopApplicationLinkPath="#leaveempty"/></taskbar:TaskbarPinList></defaultlayout:TaskbarLayout></CustomTaskbarLayoutCollection>'
        if ($normalizedLayout -eq $expectedLayout) {
            Write-Status -Section 'Artefatos do baseline' -Item 'Conteudo de TaskbarLayoutModification.xml' -Status 'OK' -Expected 'Layout vazio com PinListPlacement=Replace' -Actual 'Conteudo conforme o autounattend'
        } else {
            Write-Status -Section 'Artefatos do baseline' -Item 'Conteudo de TaskbarLayoutModification.xml' -Status 'DIFERENTE' -Expected 'Layout vazio com PinListPlacement=Replace' -Actual 'Conteudo diferente'
        }
    } catch {
        Write-Status -Section 'Artefatos do baseline' -Item 'Conteudo de TaskbarLayoutModification.xml' -Status 'AVISO' -Detail $_.Exception.Message
    }
}

# -----------------------------------------------------------------------------
# 14. Tarefa UnlockStartLayout / Event Source
# -----------------------------------------------------------------------------

try {
    $task = Get-ScheduledTask -TaskName 'UnlockStartLayout' -ErrorAction SilentlyContinue
    if (-not $task) {
        Write-Status -Section 'Tarefa agendada' -Item 'UnlockStartLayout' -Status 'DIFERENTE' -Expected 'tarefa presente e habilitada' -Actual '<ausente>'
    } else {
        $actionOk = @($task.Actions | Where-Object {
            $_.Execute -ieq 'C:\Windows\System32\wscript.exe' -and $_.Arguments -match 'UnlockStartLayout\.vbs'
        }).Count -gt 0

        $taskEnabled = $task.Settings.Enabled

        if ($taskEnabled -and $actionOk) {
            Write-Status -Section 'Tarefa agendada' -Item 'UnlockStartLayout' -Status 'OK' -Expected 'presente, habilitada, executando UnlockStartLayout.vbs' -Actual "Enabled=$taskEnabled; ActionOK=$actionOk"
        } else {
            Write-Status -Section 'Tarefa agendada' -Item 'UnlockStartLayout' -Status 'DIFERENTE' -Expected 'presente, habilitada, executando UnlockStartLayout.vbs' -Actual "Enabled=$taskEnabled; ActionOK=$actionOk"
        }
    }
} catch {
    Write-Status -Section 'Tarefa agendada' -Item 'UnlockStartLayout' -Status 'AVISO' -Detail $_.Exception.Message
}

try {
    if ([System.Diagnostics.EventLog]::SourceExists('UnattendGenerator')) {
        Write-Status -Section 'Event Log' -Item 'Source UnattendGenerator' -Status 'OK' -Expected '<fonte presente>' -Actual '<presente>'
    } else {
        Write-Status -Section 'Event Log' -Item 'Source UnattendGenerator' -Status 'DIFERENTE' -Expected '<fonte presente>' -Actual '<ausente>'
    }
} catch {
    Write-Status -Section 'Event Log' -Item 'Source UnattendGenerator' -Status 'AVISO' -Detail $_.Exception.Message
}

# -----------------------------------------------------------------------------
# 15. Estado final do Start: layout desbloqueado
# -----------------------------------------------------------------------------

# O autounattend cria LockedStartLayout=1 no perfil padrao e registra uma tarefa
# que o muda para 0 nos SIDs existentes. Portanto, no usuario atual, o estado
# pos-instalacao esperado e 0.
Test-RegistryValue -Root 'HKCU' -Path 'Software\Policies\Microsoft\Windows\Explorer' -Name 'StartLayoutFile' -Type 'REG_SZ' -Expected 'C:\Windows\Setup\Scripts\TaskbarLayoutModification.xml'
Test-RegistryValue -Root 'HKCU' -Path 'Software\Policies\Microsoft\Windows\Explorer' -Name 'LockedStartLayout' -Type 'REG_DWORD' -Expected 0

# -----------------------------------------------------------------------------
# 16. Checagens manuais (heuristicas)
# -----------------------------------------------------------------------------

# O windows_debloat2.ps1 lista estes itens como remocao manual. Eles nao tem,
# nos arquivos fornecidos, um identificador tecnico unico equivalente a um
# selector AppX. Por isso, estas verificacoes sao AVISOS/heuristicas e nao
# entram como equivalencia perfeita do baseline.

# Microsoft Edge: procura executavel em locais padrao e comando resolvivel.
$edgeFound = $false
$edgeEvidence = @()
$edgePaths = @(
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
)
foreach ($p in $edgePaths) {
    if ($p -and (Test-Path -LiteralPath $p)) {
        $edgeFound = $true
        $edgeEvidence += $p
    }
}
try {
    $edgeCommand = Get-Command msedge.exe -ErrorAction SilentlyContinue
    if ($edgeCommand) {
        $edgeFound = $true
        $edgeEvidence += $edgeCommand.Source
    }
} catch { }

if ($edgeFound) {
    Write-Status -Section 'Remocao manual' -Item 'Microsoft Edge' -Status 'AVISO' -Expected '<nao instalado>' -Actual ('possivel presenca: ' + (($edgeEvidence | Sort-Object -Unique) -join ', ')) -Detail 'O debloat lista Edge como remocao manual; esta checagem usa caminhos/executavel comuns e nao pretende provar ausencia absoluta.'
} else {
    Write-Status -Section 'Remocao manual' -Item 'Microsoft Edge' -Status 'OK' -Expected '<nao instalado>' -Actual '<nenhum executavel encontrado nos locais comuns>' -Detail 'Checagem heuristica; nao e uma prova criptografica/abrangente de ausencia.'
}

# Start Experiences / Xbox Live: usa apenas o nome visivel do Start Apps quando
# disponivel. Os nomes podem variar com idioma/build, portanto sao apenas avisos.
try {
    $startApps = @(Get-StartApps)
    foreach ($manualName in @('Aplicativo Start Experiences','Microsoft Edge','Xbox Live')) {
        $hit = @($startApps | Where-Object { $_.Name -ieq $manualName })
        if ($hit.Count -gt 0) {
            Write-Status -Section 'Remocao manual' -Item $manualName -Status 'AVISO' -Expected '<nao listado no Start Apps>' -Actual '<presente>' -Detail 'Checagem heuristica baseada no nome exibido.'
        } else {
            Write-Status -Section 'Remocao manual' -Item $manualName -Status 'INFO' -Expected '<nao listado no Start Apps>' -Actual '<nao encontrado>' -Detail 'Ausencia neste relatorio nao garante ausencia do componente; nomes e exposicao podem variar por build/idioma.'
        }
    }
} catch {
    Write-Status -Section 'Remocao manual' -Item 'Start Apps' -Status 'AVISO' -Detail $_.Exception.Message
}

# -----------------------------------------------------------------------------
# 17. Relatorio de escopo: itens intencionalmente NAO auditados como baseline
# -----------------------------------------------------------------------------

Write-Host ''
Write-Host '---------------- ITENS FORA DO ESCOPO DO AUDITOR ----------------' -ForegroundColor DarkCyan
Write-Status -Section 'Escopo' -Item 'O&O ShutUp10++' -Status 'INFO' -Detail 'Ignorado por instrucao: o usuario pediu para considerar somente autounattend + windows_debloat2.ps1.'
Write-Status -Section 'Escopo' -Item 'Drivers' -Status 'INFO' -Detail 'Ignorado por instrucao: pertence ao pos-instalacao.'
Write-Status -Section 'Escopo' -Item 'Aplicativos instalados via winget' -Status 'INFO' -Detail 'Ignorado por instrucao: pertence ao pos-instalacao.'
Write-Status -Section 'Escopo' -Item 'Plano AMD Ryzen Balanced' -Status 'INFO' -Detail 'Ignorado por instrucao: pertence ao pos-instalacao.'
Write-Status -Section 'Escopo' -Item 'Regiao Portugal / parametros apenas no comentario do gerador' -Status 'INFO' -Detail 'Nao existe no arquivo fornecido um estado persistente inequivo verificavel para todos esses parametros; o auditor nao os inventa.'

# -----------------------------------------------------------------------------
# Resumo
# -----------------------------------------------------------------------------

Write-Host ''
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ' RESUMO DA AUDITORIA' -ForegroundColor Cyan
Write-Host '============================================================' -ForegroundColor Cyan
Write-Host ("OK:         {0}" -f $script:OkCount) -ForegroundColor Green
Write-Host ("DIFERENTE:  {0}" -f $script:DifferentCount) -ForegroundColor Red
Write-Host ("AVISO:      {0}" -f $script:WarningCount) -ForegroundColor Yellow
Write-Host ("INFO:       {0}" -f $script:InfoCount) -ForegroundColor Cyan
Write-Host ''

if ($script:DifferentCount -eq 0 -and $script:WarningCount -eq 0) {
    Write-Host 'RESULTADO: o sistema esta conforme ao baseline auditavel.' -ForegroundColor Green
    exit 0
}

if ($script:DifferentCount -gt 0) {
    Write-Host 'RESULTADO: existem diferencas no estado do baseline.' -ForegroundColor Red
} else {
    Write-Host 'RESULTADO: nenhuma divergencia obrigatoria foi encontrada, mas existem avisos/checagens heuristicas.' -ForegroundColor Yellow
}

if ($script:DifferentCount -gt 0 -and $script:WarningCount -gt 0) {
    exit 2
}

if ($script:DifferentCount -gt 0) {
    exit 1
}

exit 2
