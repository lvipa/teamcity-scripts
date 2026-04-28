# TeamCity DevOps Tools

Набор PowerShell-скриптов для автоматизации работы с TeamCity через REST API.

## Возможности

### 🔍 Поиск сборок по параметрам
- поиск build configurations по имени/значению параметра
- быстрый переход к конфигурации

### 🔗 Анализ зависимостей
- поиск snapshot dependencies
- поиск artifact dependencies
- отображение зависимых сборок

## Использование

### Поиск сборок по параметру

```powershell
.\FindBuilds.ps1 `
  -ApiToken "TOKEN" `
  -ParamName "env.VERSION" `
  -ParamValue "1.0"
  ```

### Поиск зависимостей сборки

##Требования
PowerShell 5+
доступ к TeamCity REST API
###Примечание

API Token не хранится в репозитории.

```powershell
& %system.teamcity.build.workingDir%/FindBuildsDependencies.ps1 -ApiToken '%Api%' -BuildConfigLink '%BuildConfigLink%' -ProjectLink '%ProjectLink%'
# Аргумент -ProjectLink не обязательный, тогда поиск будет по всем сборкам
```

```powershell
& %system.teamcity.build.workingDir%/FindBuilds.ps1 -ApiToken '%Api%' -ParamValue '%ParamValue%' -ParamName '%ParamName%'
```

