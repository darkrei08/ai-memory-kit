# ==============================================================================
# ai-memory-kit — Windows installer (mirror of install.sh).
#
# Installs the aimem CLI (run via a POSIX sh: Git Bash / WSL / MSYS), the memory
# templates, and the project-memory skill into detected agents. Idempotent.
#
# Usage:
#   pwsh -File install.ps1                 # everything for detected agents
#   pwsh -File install.ps1 -List           # show plan, install nothing
#   pwsh -File install.ps1 -Agents pi,claude
#   pwsh -File install.ps1 -NoSkill
#   pwsh -File install.ps1 -Prefix C:\tools\aimem
# ==============================================================================
param(
  [switch]$List,
  [switch]$NoSkill,
  [string]$Agents = "",
  [string]$Prefix = "$HOME\.local"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Repo = "darkrei08/ai-memory-kit"
$Ref  = if ($env:AIMEM_REF) { $env:AIMEM_REF } else { "main" }
$SkillName = "project-memory"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Resolve source: run-from-clone, else download the tarball.
$Src = $ScriptDir
$Cleanup = $null
if (-not (Test-Path (Join-Path $Src "bin/aimem"))) {
  $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("aimem-" + [guid]::NewGuid())
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  $Cleanup = $tmp
  Write-Host "Fetching $Repo@$Ref ..."
  $tarball = Join-Path $tmp "src.tar.gz"
  Invoke-WebRequest -Uri "https://codeload.github.com/$Repo/tar.gz/refs/heads/$Ref" -OutFile $tarball
  tar -xz -C $tmp -f $tarball
  $Src = (Get-ChildItem -Path $tmp -Directory -Filter "ai-memory-kit-*" | Select-Object -First 1).FullName
  if (-not $Src -or -not (Test-Path (Join-Path $Src "bin/aimem"))) { throw "could not locate kit sources after fetch" }
}

$BinDir   = Join-Path $Prefix "bin"
$ShareDir = Join-Path $Prefix "share/ai-memory-kit"

# Agent skill targets (mirror of install.sh).
$Targets = [ordered]@{
  pi          = "$HOME\.pi\agent\skills"
  claude      = "$HOME\.claude\skills"
  gemini      = "$HOME\.gemini\skills"
  cursor      = "$HOME\.cursor\skills"
  antigravity = "$HOME\.antigravity\skills"
  codex       = "$HOME\.codex\skills"
  opencode    = "$HOME\.config\opencode\skills"
  generic     = "$HOME\.config\agent-skills"
}
$Presence = [ordered]@{
  pi = "$HOME\.pi"; claude = "$HOME\.claude"; gemini = "$HOME\.gemini";
  cursor = "$HOME\.cursor"; antigravity = "$HOME\.antigravity";
  codex = "$HOME\.codex"; opencode = "$HOME\.config\opencode"; generic = "$HOME\.config"
}
function Get-Agents {
  if ($Agents) { return ($Agents -split "," | ForEach-Object { $_.Trim() }) }
  return $Targets.Keys
}

if ($List) {
  Write-Host "Source:    $Src"
  Write-Host "CLI ->     $BinDir\aimem"
  Write-Host "Templates ->$ShareDir\templates"
  foreach ($a in Get-Agents) {
    $present = if (Test-Path $Presence[$a]) { "yes" } else { "no" }
    Write-Host ("{0,-13} {1,-42} {2}" -f $a, "$($Targets[$a])\$SkillName", $present)
  }
  if ($Cleanup) { Remove-Item -Recurse -Force $Cleanup }
  exit 0
}

function Mirror($from, $to) {
  New-Item -ItemType Directory -Force -Path $to | Out-Null
  Copy-Item -Recurse -Force (Join-Path $from "*") $to
}

# 1) CLI (+ a .cmd shim that runs it via sh)
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
Copy-Item -Force (Join-Path $Src "bin/aimem") (Join-Path $BinDir "aimem")
$shim = "@echo off`r`nsh `"%~dp0aimem`" %*`r`n"
Set-Content -Path (Join-Path $BinDir "aimem.cmd") -Value $shim -NoNewline
Write-Host "ok   CLI       -> $BinDir\aimem (run via sh; aimem.cmd shim added)"

# 2) templates + hooks
New-Item -ItemType Directory -Force -Path "$ShareDir\templates","$ShareDir\hooks" | Out-Null
Mirror (Join-Path $Src "templates") "$ShareDir\templates"
Copy-Item -Recurse -Force (Join-Path $Src "hooks/*") "$ShareDir\hooks" -ErrorAction SilentlyContinue
Write-Host "ok   templates -> $ShareDir\templates"

# 3) skill into detected agents
if (-not $NoSkill) {
  if (-not (Test-Path (Join-Path $Src "skills/$SkillName/SKILL.md"))) { throw "skill source missing" }
  foreach ($a in Get-Agents) {
    if (-not $Targets.Contains($a)) { Write-Host "skip $a (unknown)"; continue }
    if (-not (Test-Path $Presence[$a])) { Write-Host "skip $a (not detected)"; continue }
    Mirror (Join-Path $Src "skills/$SkillName") (Join-Path $Targets[$a] $SkillName)
    Write-Host "ok   skill     -> $($Targets[$a])\$SkillName"
  }
}

if ($Cleanup) { Remove-Item -Recurse -Force $Cleanup }
Write-Host ""
Write-Host "Done. In any project run:  aimem init"
