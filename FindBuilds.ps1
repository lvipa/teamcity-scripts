param(
  [string]$TeamCityUrl = 'https://teamcity.web.com',
  [string]$ApiToken,
  [string]$ParamName   = $null,
  [string]$ParamValue  = $null
)

# Устанавливаем кодировку для корректного вывода кириллицы
$OutputEncoding = [System.Text.Encoding]::GetEncoding("windows-1251")

# Заголовки с Bearer‑токеном
$headers = @{
  Authorization = "Bearer $ApiToken"
  Accept        = 'application/json'
}

# Получаем все Build Configurations
$allConfigsUri = "$TeamCityUrl/app/rest/buildTypes?fields=buildType(id,name,projectName)"
$allConfigs = (Invoke-RestMethod -Uri $allConfigsUri -Headers $headers).buildType

# Перебираем конфигурации и параметры
$matches = foreach ($cfg in $allConfigs) {
  $paramsUri = "$TeamCityUrl/app/rest/buildTypes/id:$($cfg.id)/parameters"
	Write-Host "🔍 Проверяю параметры для: $($cfg.id) / $($cfg.name)"
	Write-Host "URI: $paramsUri"

  # $paramsResponse = Invoke-RestMethod -Uri $paramsUri -Headers $headers
	try {
		$paramsResponse = Invoke-RestMethod -Uri $paramsUri -Headers $headers
	}
	catch {
	  Write-Host "❌ Ошибка при запросе параметров для конфигурации: $($cfg.id)" -ForegroundColor Red
	  Write-Host "→ URL: $paramsUri"
	  Write-Host "→ Сообщение: $($_.Exception.Message)" -ForegroundColor DarkRed
	  continue
	}

  $params = $paramsResponse.property

  foreach ($p in $params) {
    $isMatch = $false

    if ($ParamName -and $ParamValue) {
      if ($p.name -eq $ParamName -and $p.value -and $p.value.Trim() -eq $ParamValue) {
        $isMatch = $true
      }
    }
    elseif ($ParamName) {
      if ($p.name -eq $ParamName) { $isMatch = $true }
    }
    elseif ($ParamValue) {
      if ($p.value -and $p.value.Trim() -like "*$ParamValue*") { $isMatch = $true }
    }

    if ($isMatch) {
      [PSCustomObject]@{
        #ConfigId     = $cfg.id
        #ConfigName   = $cfg.name
        #ProjectName  = $cfg.projectName
        Link         = "$TeamCityUrl/viewType.html?buildTypeId=$($cfg.id)"
        ParamName    = $p.name
        ParamValue   = $p.value
      }

      break
    }
  }
}

# Выводим результаты с кликабельной ссылкой
# if ($matches) {
  # $matches | Format-Table -AutoSize
# }
# else {
  # Write-Host "Нет конфигураций, подходящих под указанный фильтр."
# }
if ($matches) {
  foreach ($match in $matches) {
    Write-Host "`n[$($match.ParamName)] = " -ForegroundColor Yellow -NoNewline
    Write-Host "$($match.ParamValue)"      -ForegroundColor Green -NoNewline
    Write-Host "  →  "                      -ForegroundColor DarkGray -NoNewline
    Write-Host "$($match.Link)"            -ForegroundColor Cyan
  }
}
else {
  Write-Host "Нет конфигураций, подходящих под указанный фильтр." -ForegroundColor Red
}
