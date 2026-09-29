# Sincronização de arquivos

$serverus = "\\100.80.135.72\Serverus"

Write-Host "Iniciando a sincronização em 5" -ForegroundColor Cyan
Start-Sleep -Seconds 1
Write-Host "`nIniciando a sincronização em 4" -ForegroundColor Cyan
Start-Sleep -Seconds 1
Write-Host "`nIniciando a sincronização em 3" -ForegroundColor Yellow
Start-Sleep -Seconds 1
Write-Host "`nIniciando a sincronização em 2" -ForegroundColor Yellow
Start-Sleep -Seconds 1
Write-Host "`nIniciando a sincronização em 1" -ForegroundColor Red
Start-Sleep -Seconds 1

Write-Host "`nSincronizando documentos..." -ForegroundColor Cyan
robocopy "$serverus\mnt\dados\Documentos" "D:\Backup\Documentos" /MIR /R:3 /W:5 /FFT /NDL

Write-Host "`nSincronizando imagens..." -ForegroundColor Cyan
robocopy "$serverus\mnt\dados\Imagens" "D:\Backup\Imagens" /MIR /R:3 /W:5 /FFT /NDL

Write-Host "`nSincronizando mídias..." -ForegroundColor Cyan
robocopy "$serverus\mnt\dados\Mídias" "D:\Backup\Mídias" /MIR /R:3 /W:5 /FFT /NDL

Write-Host "`nSincronizando músicas..." -ForegroundColor Cyan
robocopy "$serverus\mnt\dados\Músicas" "D:\Backup\Músicas" /MIR /R:3 /W:5 /FFT /NDL

Write-Host "`nSincronizando jogos..." -ForegroundColor Cyan
robocopy "$serverus\mnt\dados\Jogos\Arquivos de Jogos" "D:\Backup\Jogos\Arquivos de Jogos" /MIR /R:3 /W:5 /FFT /NDL
robocopy "$serverus\mnt\dados\Jogos\Jogos Android" "D:\Backup\Jogos\Jogos Android" /MIR /R:3 /W:5 /FFT /NDL

Write-Host "`nSincronizando Vídeos..." -ForegroundColor Cyan
robocopy "$serverus\mnt\dados\Vídeos\Diversos" "D:\Backup\Vídeos\Diversos" /MIR /R:3 /W:5 /FFT /NDL
robocopy "$serverus\mnt\dados\Vídeos\Friends" "D:\Backup\Vídeos\Friends" /MIR /R:3 /W:5 /FFT /NDL
robocopy "$serverus\mnt\dados\Vídeos\Shows" "D:\Backup\Vídeos\Shows" /MIR /R:3 /W:5 /FFT /NDL

Write-Host "`nScript encerrado!" -ForegroundColor Green
