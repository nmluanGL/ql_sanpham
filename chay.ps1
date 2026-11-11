param(
  [string]$Device = 'chrome',
  [Parameter(Mandatory = $true)][string]$CloudName,
  [Parameter(Mandatory = $true)][string]$UploadPreset
)
Push-Location $PSScriptRoot
try {
  flutter run -d $Device "--dart-define=CLOUDINARY_CLOUD_NAME=$CloudName" "--dart-define=CLOUDINARY_UPLOAD_PRESET=$UploadPreset"
} finally {
  Pop-Location
}
