# TeamCity REST API utilities

Small PowerShell utilities for investigating TeamCity build configurations without manually opening every configuration in the UI. They are useful when assessing the impact of a CI/CD change or locating a configuration by a known parameter.

## Included scripts

| Script | Purpose |
| --- | --- |
| `FindBuilds.ps1` | Searches build configurations for a parameter name, a value, or both; prints a direct link to each match. |
| `FindBuildsDependencies.ps1` | Finds build configurations that have a snapshot or artifact dependency on a selected build type. An optional project link narrows the search. |

## Requirements

- Windows PowerShell 5.1+ or PowerShell 7+
- Access to the TeamCity REST API
- A TeamCity personal access token with read access to the relevant projects

## Usage

### Find configurations by parameter

```powershell
.\FindBuilds.ps1 `
  -TeamCityUrl "https://teamcity.example.com" `
  -ApiToken "<token>" `
  -ParamName "env.VERSION" `
  -ParamValue "1.0"
```

`-ParamName` and `-ParamValue` may be used independently. When both are supplied, the script looks for an exact name/value pair.

### Find reverse dependencies of a build configuration

```powershell
.\FindBuildsDependencies.ps1 `
  -TeamCityUrl "https://teamcity.example.com" `
  -ApiToken "<token>" `
  -ProjectLink "https://teamcity.example.com/project/ExampleProject" `
  -BuildConfigLink "https://teamcity.example.com/viewType.html?buildTypeId=Example_Build"
```

The script reports both snapshot and artifact dependencies, with a direct link to every dependent configuration.

## Security notes

- The repository contains no token, server address or project data.
- Pass tokens at runtime; do not put them in scripts, commit history or screenshots.
- The default URL in the scripts is only a placeholder — always provide your own `-TeamCityUrl`.

## Scope

These are deliberately small, read-only investigation tools. They are intended as examples of working with the TeamCity REST API and can be adapted to a team’s own access model and reporting format.

