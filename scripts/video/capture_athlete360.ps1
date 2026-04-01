param(
  [string]$Output = "athlete360_final.mp4",
  [int]$DurationSec = 45,
  [int]$Framerate = 30
)

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
  Write-Error "ffmpeg introuvable. Installe ffmpeg puis relance."
  exit 1
}

Write-Host "Capture video en cours: $Output ($DurationSec sec)"
& ffmpeg -y `
  -f gdigrab `
  -framerate $Framerate `
  -i desktop `
  -t $DurationSec `
  -vf "scale=1920:1080" `
  -c:v libx264 `
  -preset veryfast `
  -crf 21 `
  -pix_fmt yuv420p `
  $Output

Write-Host "Video generee: $Output"
