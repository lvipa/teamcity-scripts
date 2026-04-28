param(
    [string]$TeamCityUrl       = 'https://teamcity.web.com',
    [string]$ApiToken,
    [string]$ProjectLink,
    [string]$BuildConfigLink
)

# Простая функция логирования
function Write-Log {
    param(
        [ValidateSet('INFO','ERROR','DEBUG')]
        [string]$Level,
        [string]$Message
    )
    $time = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Write-Host "$time [$Level] $Message"
}

# Кодировка для кириллицы
$OutputEncoding = [System.Text.Encoding]::GetEncoding(1251)

# Разбираем ProjectLink (если указан)
if ($ProjectLink) {
    Write-Log INFO "Парсим projectId из $ProjectLink"
    if ($ProjectLink -match '/project/([^/?]+)') {
        $ProjectId = $Matches[1]
    }
    elseif ($ProjectLink -match 'projectId=([^&]+)') {
        $ProjectId = $Matches[1]
    }
    else {
        Write-Log ERROR "Не удалось извлечь projectId из $ProjectLink"
        exit 1
    }
    Write-Log INFO "projectId = '$($ProjectId)'"

    $locator = "locator=affectedProject:$ProjectId&"
}
else {
    Write-Log INFO "Параметр -ProjectLink не указан — ищем по всем проектам"
    $locator = ""  # просто не добавляем фильтр
}

# Разбираем BuildConfigLink
Write-Log INFO "Парсим buildTypeId из $BuildConfigLink"
if ($BuildConfigLink -match 'buildTypeId=([^&]+)') {
    $TargetBuildType = $Matches[1]
}
elseif ($BuildConfigLink -match '/buildConfiguration/([^/?]+)') {
    $TargetBuildType = $Matches[1]
}
else {
    Write-Log ERROR "Не удалось извлечь buildTypeId из $BuildConfigLink"
    exit 1
}
Write-Log INFO "buildTypeId = '$($TargetBuildType)'"

# Заголовки для REST
$headers = @{
    Authorization = "Bearer $ApiToken"
    Accept        = 'application/json'
}

# Запрашиваем список всех buildType’ов (с учётом locator, если он есть)
$urlAll = "$TeamCityUrl/app/rest/buildTypes?$locator`fields=buildType(id,name,projectName)"
#Write-Log DEBUG "URL для списка конфигураций: $urlAll"
try {
    $allConfigs = (Invoke-RestMethod -Uri $urlAll -Headers $headers -ErrorAction Stop).buildType
    Write-Log INFO "Найдено $($allConfigs.Count) конфигураций"
}
catch {
    Write-Log ERROR "Ошибка получения buildTypes: $_"
    exit 1
}

# Собираем результаты
$results = @()
foreach ($cfg in $allConfigs) {
    $id = $cfg.id
    #Write-Log DEBUG "Обрабатываем конфигурацию $($cfg.projectName) / $($cfg.name) ($id)"

    # 1) snapshot-зависимости
    $urlSnap = "$TeamCityUrl/app/rest/buildTypes/id:$id/snapshot-dependencies"
    try {
        $snapList = @( (Invoke-RestMethod -Uri $urlSnap -Headers $headers -ErrorAction Stop).'snapshot-dependency' )
    } catch {
        $snapList = @()
    }

    # 2) artifact-зависимости
    $urlArt = "$TeamCityUrl/app/rest/buildTypes/id:$id/artifact-dependencies"
    try {
        $artList = @( (Invoke-RestMethod -Uri $urlArt -Headers $headers -ErrorAction Stop).'artifact-dependency' )
    } catch {
        $artList = @()
    }

    # Для каждого совпавшего snapshot добавляем строку
    foreach ($dep in $snapList | Where-Object { $_.id -eq $TargetBuildType }) {
    #Write-Log INFO "Snapshot-зависимость найдена в $($id)"
    $results += [PSCustomObject]@{
        Project        = $cfg.projectName
        Configuration  = $cfg.name
        DependencyType = 'Snapshot'
        ViewLink       = "$TeamCityUrl/viewType.html?buildTypeId=$id"
        AdminDeps      = "$TeamCityUrl/admin/editDependencies.html?id=buildType%3A$id"
        }
    }


    # Для каждого совпавшего artifact добавляем строку
    foreach ($dep in $artList) {
    # проверяем, есть ли вложенный объект и совпадает ли его id
    if ($dep.'source-buildType' -and $dep.'source-buildType'.id -eq $TargetBuildType) {
        #Write-Log INFO "Artifact-зависимость найдена в $($id)"
        $results += [PSCustomObject]@{
            Project        = $cfg.projectName
            Configuration  = $cfg.name
            DependencyType = 'Artifact'
            ViewLink       = "$TeamCityUrl/viewType.html?buildTypeId=$id"
            AdminDeps      = "$TeamCityUrl/admin/editDependencies.html?id=buildType%3A$id"
            }
        }
    }
}

# Выводим таблицу с результатами
if ($results.Count -gt 0) {
    #Write-Log INFO "Найдено $($results.Count) зависимостей от '$($TargetBuildType)'"
    # $results |
        # Format-Table `
        # @{ Label = 'Тип зависимости';            Expression = { $_.DependencyType } }, `
        # @{ Label = 'Ссылка на сборку'; Expression = { $_.ViewLink } }`
    # -AutoSize
	Write-Log INFO "Список зависимостей:"
	foreach ($res in $results) {
		Write-Host "→ [$($res.DependencyType)] $($res.Configuration) — $($res.ViewLink)"
	}


    #$results |
    #Format-Table @{Label='Ссылка на сборку';Expression={$_.ViewLink}} -AutoSize
    # $results |
        # Format-Table `
        # @{ Label = 'Проект';           Expression = { $_.Project }       }, `
        # @{ Label = 'Конфигурация';     Expression = { $_.Configuration } }, `
        # @{ Label = 'Тип зависимости';            Expression = { $_.DependencyType } }, `
        # @{ Label = 'Ссылка на сборку'; Expression = { $_.ViewLink } }, `
        # @{ Label = 'Редактировать зависимости';  Expression = { $_.AdminDeps }      } `
    # -AutoSize
}
else {
    Write-Log INFO "Не найдено зависимостей от '$($TargetBuildType)'"
}
