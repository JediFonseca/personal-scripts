Write-Host "Esse script irá sincronizar todos os arquivos da pasta ""E:\Minhas Músicas"" com o Google Drive." -ForegroundColor Yellow
Write-Host "Essa operação irá espelhar a pasta do PC no GDrive e não o contrário." -ForegroundColor Red
Write-Host "Arquivos no GDrive que não estão no PC serão APAGADOS!" -ForegroundColor Red

Write-Host "Pressione ENTER para iniciar a execução do script ou CTRL+C para cancelar." -ForegroundColor Yellow
Read-Host

rclone sync "E:\Minhas Músicas" "GDrive,root_folder_id=1WaU8_MxTIr3Y9O3ie43NzbfTXi6fKWLo:" -P

Write-Host "Sincronização concluída!" -ForegroundColor Green
[System.Media.SystemSounds]::Asterisk.Play()