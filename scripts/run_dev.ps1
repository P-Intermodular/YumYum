param(
  [string]$Device = "chrome"
)

$ErrorActionPreference = "Stop"

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$envPath = Join-Path $projectRoot ".env"

if (-not (Test-Path $envPath)) {
  Write-Error "No existe .env. Usa .env.example como plantilla y rellena SUPABASE_ANON_KEY."
}

$values = @{}

Get-Content $envPath | ForEach-Object {
  $line = $_.Trim()

  if ($line.Length -eq 0 -or $line.StartsWith("#")) {
    return
  }

  $parts = $line -split "=", 2
  if ($parts.Count -ne 2) {
    return
  }

  $key = $parts[0].Trim()
  $value = $parts[1].Trim()

  if (
    ($value.StartsWith('"') -and $value.EndsWith('"')) -or
    ($value.StartsWith("'") -and $value.EndsWith("'"))
  ) {
    $value = $value.Substring(1, $value.Length - 2)
  }

  $values[$key] = $value
}

$requiredKeys = @("SUPABASE_URL", "SUPABASE_ANON_KEY")

foreach ($key in $requiredKeys) {
  if (-not $values.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($values[$key])) {
    Write-Error "Falta $key en .env."
  }
}

if ($values["SUPABASE_ANON_KEY"] -eq "pon_aqui_tu_anon_key") {
  Write-Error "Rellena SUPABASE_ANON_KEY en .env antes de arrancar la app."
}

$maskedKey = $values["SUPABASE_ANON_KEY"].Substring(0, [Math]::Min(8, $values["SUPABASE_ANON_KEY"].Length))
Write-Host "Supabase URL: $($values["SUPABASE_URL"])"
Write-Host "Supabase anon key cargada: $maskedKey... ($($values["SUPABASE_ANON_KEY"].Length) caracteres)"

Push-Location $projectRoot
try {
  flutter run `
    -d $Device `
    --dart-define="SUPABASE_URL=$($values["SUPABASE_URL"])" `
    --dart-define="SUPABASE_ANON_KEY=$($values["SUPABASE_ANON_KEY"])"
} finally {
  Pop-Location
}
