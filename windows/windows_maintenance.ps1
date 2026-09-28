#Requires -RunAsAdministrator

# Para rodar, execute:
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# 1. Listas --------------------------------------------------------------------------------#

$AppsToRemove = @(
    "MicrosoftCorporationII.QuickAssist",         # Assistencia Rapida
    "Microsoft.WindowsCamera",                    # Camera
    "Microsoft.BingWeather",                      # Clima
    "Microsoft.WindowsSoundRecorder",             # Gravador de Som
    "Microsoft.WindowsFeedbackHub",               # Hub de Comentarios
    "Microsoft.BingSearch",                       # Microsoft Bing
    "Clipchamp.Clipchamp",                        # Microsoft Clipchamp
    "Microsoft.BingNews",                         # Microsoft Noticias
    "MSTeams",                                    # Microsoft Teams
    "Microsoft.Todos",                            # Microsoft To Do
    "Microsoft.MicrosoftStickyNotes",             # Notas Autoadesivas
    "Microsoft.OutlookForWindows",                # Outlook
    "Microsoft.Paint",                            # Paint
    "Microsoft.MSPaint",                          # Paint (legado)
    "Microsoft.PowerAutomateDesktop",             # Power Automate
    "Microsoft.WindowsAlarms",                    # Relogio
    "Microsoft.ZuneMusic",                        # Reprodutor Multimidia
    "Microsoft.MicrosoftSolitaireCollection",     # Solitaire & Casual Games
    "Microsoft.GamingApp",                        # Xbox
    "Microsoft.XboxGamingOverlay",                # Xbox Game Bar
    "Microsoft.GetHelp",                          # Obter Ajuda
    "Microsoft.Windows.DevHome",                  # Pagina inicial de desenvolvimento
    "Microsoft.YourPhone",                        # Vincular ao Celular
    "Microsoft.Copilot",                          # Copilot
    "Microsoft.Windows.Ai.Copilot.Provider",      # Copilot (provider)
    "Microsoft.549981C3F5F10",                    # Cortana
    "MicrosoftCorporationII.MicrosoftFamily",     # Family Safety
    "Microsoft.Edge.GameAssist",                  # Game Assist (overlay do Edge p/ Xbox)
    "Microsoft.Getstarted",                       # Dicas/Introducao
    "microsoft.windowscommunicationsapps",        # Email e Calendario (legado)
    "Microsoft.WindowsMaps",                      # Mapas
    "Microsoft.MixedReality.Portal",              # Portal de Realidade Mista
    "Microsoft.MicrosoftOfficeHub",               # "Instalar Office" (tile promocional, nao e o Office em si)
    "Microsoft.Office.OneNote",                   # OneNote
    "Microsoft.Microsoft3DViewer",                # Visualizador 3D
    "Microsoft.WindowsStore",                     # Microsoft Store
    "Microsoft.StorePurchaseApp",                 # Compras da Microsoft Store
    "Microsoft.People",                           # Pessoas
    "Microsoft.SkypeApp",                         # Skype
    "Microsoft.Wallet",                           # Carteira
    "Microsoft.ZuneVideo",                        # Filmes e TV
    "MicrosoftTeams",                             # Microsoft Teams (Legacy Name)

    # Xbox Apps Legacy Names:

    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay"
)

$CapabilitiesToRemove = @(
    "Language.Handwriting",                       # Reconhecimento de escrita
    "MathRecognizer",                             # Reconhecimento matematico
    "OneCoreUAP.OneSync",                         # Sincronizacao de Email/Calendario/Contatos
    "App.StepsRecorder",                          # Gravador de Etapas
    "App.Support.QuickAssist",                    # Assistencia Rapida (capability)
    "Language.Speech",                            # Reconhecimento de voz
    "Language.TextToSpeech",                      # Texto para voz
    "Hello.Face.18967",                           # Windows Hello (reconhecimento facial)
    "Hello.Face.Migration.18967",                 # Windows Hello (migracao)
    "Hello.Face.20134",                           # Windows Hello (reconhecimento facial)
    "Microsoft.Windows.MSPaint",                  # Paint (legado, capability)
    "Microsoft.Windows.WordPad"                   # WordPad
)

$FeaturesToRemove = @(
    "Microsoft-RemoteDesktopConnection",          # Conexao de Area de Trabalho Remota (mstsc)
    "Recall"                                      # Recall
)

$RegistryTweaks = @(
    @{ Path = "Software\Policies\Microsoft\Windows\WindowsCopilot";                                    Name = "TurnOffWindowsCopilot";       Type = "REG_DWORD"; Value = "1" }   # Desativa o Copilot
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\GameDVR";                                     Name = "AppCaptureEnabled";            Type = "REG_DWORD"; Value = "0" }  # Desativa gravacao em segundo plano (Game DVR)
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced";                           Name = "HideFileExt";                  Type = "REG_DWORD"; Value = "0" }  # Mostra as extensoes de arquivo
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced";                           Name = "LaunchTo";                     Type = "REG_DWORD"; Value = "1" }  # Explorer abre em "Este Computador"
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced";                           Name = "TaskbarAl";                    Type = "REG_DWORD"; Value = "0" }  # Alinha os icones da barra de tarefas a esquerda
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced";                           Name = "ShowTaskViewButton";           Type = "REG_DWORD"; Value = "0" }  # Oculta o botao de Visao de Tarefas
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\Search";                                      Name = "SearchboxTaskbarMode";         Type = "REG_DWORD"; Value = "0" }  # Oculta a caixa de busca na barra de tarefas
    @{ Path = "Software\Microsoft\Edge\SmartScreenEnabled";                                            Name = "";                             Type = "REG_DWORD"; Value = "0" }  # Desativa o SmartScreen (Edge)
    @{ Path = "Software\Microsoft\Edge\SmartScreenPuaEnabled";                                         Name = "";                             Type = "REG_DWORD"; Value = "0" }  # Desativa deteccao de PUA (Edge)
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\AppHost";                                     Name = "EnableWebContentEvaluation";   Type = "REG_DWORD"; Value = "0" }  # Desativa avaliacao de conteudo (SmartScreen p/ apps)
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\AppHost";                                     Name = "PreventOverride";              Type = "REG_DWORD"; Value = "0" }  # Permite contornar avisos do SmartScreen
    @{ Path = "Software\Policies\Microsoft\Windows\Explorer";                                          Name = "DisableSearchBoxSuggestions";  Type = "REG_DWORD"; Value = "1" }  # Desativa sugestoes na busca do Windows
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings";  Name = "TaskbarEndTask";               Type = "REG_DWORD"; Value = "1" }  # Habilita "Finalizar Tarefa" no menu da barra de tarefas
    @{ Path = "Software\Microsoft\Windows\CurrentVersion\Start";                                       Name = "VisiblePlaces";                Type = "REG_BINARY"; Value = "86087352aa5143429f7b2776584659d4" }  # Pastas exibidas no menu Iniciar (Configuracoes)
    @{ Path = "Control Panel\Accessibility\StickyKeys";                                                Name = "Flags";                        Type = "REG_SZ";    Value = "10" } # Desativa ativacao das Teclas de Aderencia
    @{ Path = "Control Panel\Keyboard";                                                                Name = "InitialKeyboardIndicators";    Type = "REG_SZ";    Value = "2" }  # Mantem o Num Lock ativo ao iniciar
)

$RegistryTweaksHKLM = @(
    @{ Path = "SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer";                                    Name = "SmartScreenEnabled";              Type = "REG_SZ";    Value = "Off" }  # Desativa o SmartScreen (Explorer/Sistema)
    @{ Path = "SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components";                             Name = "ServiceEnabled";                  Type = "REG_DWORD"; Value = "0" }    # Desativa o servico do SmartScreen
    @{ Path = "SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components";                             Name = "NotifyMalicious";                 Type = "REG_DWORD"; Value = "0" }    # Desativa notificacao de app malicioso
    @{ Path = "SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components";                             Name = "NotifyPasswordReuse";             Type = "REG_DWORD"; Value = "0" }    # Desativa notificacao de reutilizacao de senha
    @{ Path = "SOFTWARE\Microsoft\Windows\CurrentVersion\WTDS\Components";                             Name = "NotifyUnsafeApp";                 Type = "REG_DWORD"; Value = "0" }    # Desativa notificacao de app inseguro
    @{ Path = "SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Systray";                  Name = "HideSystray";                     Type = "REG_DWORD"; Value = "1" }    # Oculta o icone do Seguranca do Windows na bandeja
    @{ Path = "SYSTEM\CurrentControlSet\Control\CI\Policy";                                            Name = "VerifiedAndReputablePolicyState"; Type = "REG_DWORD"; Value = "0" }    # Desativa o Smart App Control
    @{ Path = "System\CurrentControlSet\Control\DeviceGuard";                                          Name = "EnableVirtualizationBasedSecurity"; Type = "REG_DWORD"; Value = "0" }  # Desativa a Seguranca Baseada em Virtualizacao (VBS)
    @{ Path = "System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"; Name = "Enabled";                        Type = "REG_DWORD"; Value = "0" }  # Desativa o HVCI (Memory Integrity)
    @{ Path = "System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"; Name = "EnabledBootId";                 Type = "REG_DWORD"; Value = "0" }  # HVCI: limpa o estado do ultimo boot
    @{ Path = "System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"; Name = "WasEnabledBy";                  Type = "REG_DWORD"; Value = "0" }  # HVCI: limpa quem o habilitou
    @{ Path = "SYSTEM\CurrentControlSet\Control\FileSystem";                                           Name = "LongPathsEnabled";                Type = "REG_DWORD"; Value = "1" }    # Habilita caminhos de arquivo longos
    @{ Path = "SYSTEM\CurrentControlSet\Control\Session Manager\Power";                                Name = "HiberbootEnabled";                Type = "REG_DWORD"; Value = "0" }    # Desativa a Inicializacao Rapida (Fast Startup)
    @{ Path = "SOFTWARE\Policies\Microsoft\Dsh";                                                       Name = "AllowNewsAndInterests";           Type = "REG_DWORD"; Value = "0" }    # Desativa os Widgets
    @{ Path = "Software\Policies\Microsoft\Windows\CloudContent";                                      Name = "DisableWindowsConsumerFeatures";  Type = "REG_DWORD"; Value = "1" }    # Desativa recursos de consumidor (sugestoes, promocoes)
    @{ Path = "Software\Policies\Microsoft\Windows\CloudContent";                                      Name = "DisableCloudOptimizedContent";    Type = "REG_DWORD"; Value = "1" }    # Desativa conteudo otimizado na nuvem
    @{ Path = "SOFTWARE\Microsoft\Windows\CurrentVersion\Communications";                              Name = "ConfigureChatAutoInstall";        Type = "REG_DWORD"; Value = "0" }    # Impede a instalacao automatica do Teams/Chat
    @{ Path = "SYSTEM\CurrentControlSet\Control\BitLocker";                                            Name = "PreventDeviceEncryption";         Type = "REG_DWORD"; Value = "1" }    # Impede a criptografia automatica de dispositivo
    @{ Path = "Software\Policies\Microsoft\Edge";                                                      Name = "HideFirstRunExperience";          Type = "REG_DWORD"; Value = "1" }    # Edge: oculta a tela de boas-vindas
    @{ Path = "Software\Policies\Microsoft\Edge\Recommended";                                          Name = "BackgroundModeEnabled";           Type = "REG_DWORD"; Value = "0" }    # Edge: nao roda em segundo plano
    @{ Path = "Software\Policies\Microsoft\Edge\Recommended";                                          Name = "StartupBoostEnabled";             Type = "REG_DWORD"; Value = "0" }    # Edge: desativa o Startup Boost
)

$RegistryKeysToDelete = @(
    "SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate",   # Impede a reinstalacao do Dev Home
    "SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate"    # Impede a reinstalacao do Outlook
)

$ContentDeliveryManagerKeys = @(
    "ContentDeliveryAllowed",
    "FeatureManagementEnabled",
    "OEMPreInstalledAppsEnabled",
    "PreInstalledAppsEnabled",
    "PreInstalledAppsEverEnabled",
    "SilentInstalledAppsEnabled",
    "SoftLandingEnabled",
    "SubscribedContentEnabled",
    "SubscribedContent-310093Enabled",
    "SubscribedContent-338387Enabled",
    "SubscribedContent-338388Enabled",
    "SubscribedContent-338389Enabled",
    "SubscribedContent-338393Enabled",
    "SubscribedContent-353694Enabled",
    "SubscribedContent-353696Enabled",
    "SubscribedContent-353698Enabled",
    "SystemPaneSuggestionsEnabled"
)

# Icones da area de trabalho ocultos (somente a Lixeira, {645ff040-...}, fica visivel)
$DesktopIconsHidden = @(
    "{5399e694-6ce5-4d6c-8fce-1d8870fdcba0}",
    "{b4bfcc3a-db2c-424c-b029-7fe99a87c641}",
    "{a8cdff1c-4878-43be-b5fd-f8091c1c60d0}",
    "{374de290-123f-4565-9164-39c4925e467b}",
    "{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}",
    "{f874310e-b6b7-47dc-bc84-b9e6b38f5903}",
    "{1cf1260c-4dd0-4ebb-811f-33c572699fde}",
    "{f02c1a0d-be21-4350-88b0-7367fc96ef3c}",
    "{3add1653-eb32-4cb0-bbd7-dfa0abb5acca}",
    "{20d04fe0-3aea-1069-a2d8-08002b30309d}",
    "{59031a47-3f72-44a7-89c5-5595fe6b30ee}",
    "{a0953c92-50dc-43bf-be83-3742fed03c9c}"
)

$AppsParaRemocaoManual = @(
    "Aplicativo Start Experiences",
    "Microsoft Edge",
    "Xbox Live"
)

# 2. Funcao: remove pacote AppX (todos os usuarios + provisionado) --------------------------#

function Remove-AppXCompletely {

		$Provisioned = Get-AppxProvisionedPackage -Online

		foreach ($App in $AppsToRemove) {

			foreach ($Package in Get-AppxPackage -AllUsers -Name $App) {
				Get-Process | Where-Object { $_.Path -like "$($Package.InstallLocation)\*" } | Stop-Process -Force -ErrorAction SilentlyContinue
				$Package | Remove-AppxPackage -AllUsers
			}

			$Provisioned | Where-Object { $_.DisplayName -eq $App } | Remove-AppxProvisionedPackage -Online

		}

}

# 3. Funcao: remove Windows Capabilities ---------------------------------------------------#

function Remove-CapabilitiesCompletely {

		foreach ($Capability in $CapabilitiesToRemove) {

			Get-WindowsCapability -Online | Where-Object { $_.State -eq "Installed" -and $_.Name -like "$Capability*" } | Remove-WindowsCapability -Online

		}

}

# 4. Funcao: remove Windows Optional Features -----------------------------------------------#

function Remove-FeaturesCompletely {

		foreach ($Feature in $FeaturesToRemove) {

			Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq $Feature -and $_.State -notin "Disabled", "DisabledWithPayloadRemoved" } | Disable-WindowsOptionalFeature -Online -Remove -NoRestart

		}

}

# 5. Funcao: Ajustes no Registro e no Sistema -----------------------------------------------#

function Set-RegistryTweaks {

		foreach ($Tweak in $RegistryTweaks) {

			if ($Tweak.Name -eq "") {
				reg.exe add "HKCU\$($Tweak.Path)" /ve /t $Tweak.Type /d $Tweak.Value /f | Out-Null
			} else {
				reg.exe add "HKCU\$($Tweak.Path)" /v $Tweak.Name /t $Tweak.Type /d $Tweak.Value /f | Out-Null
			}

		}

		foreach ($Key in $ContentDeliveryManagerKeys) {

			reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v $Key /t REG_DWORD /d 0 /f | Out-Null

		}

		foreach ($Tweak in $RegistryTweaksHKLM) {

			reg.exe add "HKLM\$($Tweak.Path)" /v $Tweak.Name /t $Tweak.Type /d $Tweak.Value /f | Out-Null

		}

		foreach ($Key in $RegistryKeysToDelete) {

			reg.exe delete "HKLM\$Key" /f 2>&1 | Out-Null

		}

		foreach ($Panel in "ClassicStartMenu", "NewStartPanel") {

			foreach ($Icon in $DesktopIconsHidden) {
				reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\$Panel" /v $Icon /t REG_DWORD /d 1 /f | Out-Null
			}
			reg.exe add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\$Panel" /v "{645ff040-5081-101b-9f08-00aa002f954e}" /t REG_DWORD /d 0 /f | Out-Null

		}

		# Menu de contexto classico
		reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /f | Out-Null

		# Num Lock e Teclas de Aderencia na tela de login
		reg.exe add "HKU\.DEFAULT\Control Panel\Keyboard" /v InitialKeyboardIndicators /t REG_SZ /d 2 /f | Out-Null
		reg.exe add "HKU\.DEFAULT\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d 10 /f | Out-Null

		# Menu Iniciar sem apps fixados
		$StartKey = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Start"
		if (-not (Test-Path $StartKey)) { New-Item -Path $StartKey | Out-Null }
		Set-ItemProperty -Path $StartKey -Name "ConfigureStartPins" -Value '{"pinnedList":[]}' -Type String

		fsutil.exe behavior set disableLastAccess 1 | Out-Null
		net.exe accounts /maxpwage:UNLIMITED | Out-Null

		# Desativa a indexacao do Windows Search
		sc.exe config WSearch start= disabled | Out-Null
		sc.exe stop WSearch | Out-Null

}

# 6. Remocao do OneDrive -----------------------------------------------------------------------#

function Remove-OneDrive {

	Write-Host "`nRemovendo o OneDrive..." -ForegroundColor Cyan
	Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue

	foreach ($Setup in "$env:SystemRoot\System32\OneDriveSetup.exe", "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
		if (Test-Path $Setup) { Start-Process $Setup -ArgumentList "/uninstall" -Wait }
	}

	reg.exe delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDriveSetup /f 2>&1 | Out-Null

}

# 7. Execucao do script --------------------------------------------------------------------#

Remove-AppXCompletely
Remove-CapabilitiesCompletely
Remove-FeaturesCompletely
Set-RegistryTweaks
Remove-OneDrive

# Reinicia o Explorer para aplicar as alteracoes da interface (ele reabre sozinho)
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

Write-Host "`nProcesso concluido. Reinicie o sistema para aplicar todas as alteracoes." -ForegroundColor Cyan
Write-Host "`n=====================================================" -ForegroundColor Magenta
Write-Host "LEMBRETE: os apps abaixo nao podem ser removidos de" -ForegroundColor Magenta
Write-Host "forma confiavel via script neste ambiente. Remova-os" -ForegroundColor Magenta
Write-Host "manualmente em Configuracoes > Aplicativos > Aplicativos instalados" -ForegroundColor Magenta
$AppsParaRemocaoManual | ForEach-Object { Write-Host "  - $_" -ForegroundColor Magenta }
Write-Host "=====================================================" -ForegroundColor Magenta
