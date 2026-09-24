# Compila o SKDiscordServ e gera build/SKDiscordServ.jar
#
# Os jars em libs/ existem so para compilar - o servidor ja fornece todos
# eles em tempo de execucao, por isso o jar final fica com poucos KB e nao
# precisa de shading.
#
# Uso:  .\build.ps1
#       .\build.ps1 -Deploy 'C:\caminho\do\servidor\plugins'

param(
    [string]$Deploy = ''
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
Set-Location $root

# No Windows o instalador da Oracle poe java/javac num diretorio de atalhos
# (javapath) que NAO tem o jar.exe, entao ele precisa ser procurado no JDK.
function Resolve-JarTool {
    $onPath = Get-Command jar -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }
    if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\jar.exe")) {
        return "$env:JAVA_HOME\bin\jar.exe"
    }
    $candidate = Get-ChildItem 'C:\Program Files\Java' -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path "$($_.FullName)\bin\jar.exe" } |
        Sort-Object Name |
        Select-Object -Last 1
    if ($candidate) { return "$($candidate.FullName)\bin\jar.exe" }
    Write-Error "Nao achei o jar.exe. Defina JAVA_HOME apontando para um JDK."
}
$jarTool = Resolve-JarTool

$libs = (Get-ChildItem "$root\libs\*.jar" | ForEach-Object { $_.FullName }) -join ';'
if (-not $libs) {
    Write-Error @"
Nenhum jar em libs/. Sao necessarios para compilar:
  dev.folia:folia-api:26.1.2.build.8-stable   (repo.papermc.io)
  net.md-5:bungeecord-chat:1.21-R0.2-deprecated+build.21  (repo.papermc.io)
  net.kyori:adventure-api:4.26.1              (maven central)
  net.kyori:adventure-key:4.26.1
  net.kyori:adventure-text-serializer-legacy:4.26.1
  net.kyori:adventure-text-serializer-plain:4.26.1
  net.kyori:adventure-text-serializer-commons:4.26.1
  net.kyori:examination-api:1.3.0
  org.jetbrains:annotations:24.1.0
  com.google.guava:guava:33.6.0-jre
  com.google.errorprone:error_prone_annotations:2.48.0
"@
}

# sources.txt e regerado a cada build para nao esquecer arquivo novo.
Get-ChildItem "$root\src\main\java" -Recurse -Filter *.java |
    ForEach-Object { $_.FullName.Substring($root.Length + 1) } |
    Sort-Object |
    Set-Content "$root\sources.txt" -Encoding ascii

$classes = "$root\build\classes"
if (Test-Path $classes) { Remove-Item $classes -Recurse -Force }
New-Item -ItemType Directory -Force $classes | Out-Null

Write-Host "Compilando..." -ForegroundColor Cyan
& javac -encoding UTF-8 --release 21 -Xlint:all -cp $libs -d $classes '@sources.txt'
if ($LASTEXITCODE -ne 0) { Write-Error "A compilacao falhou." }

Copy-Item "$root\src\main\resources\plugin.yml", "$root\src\main\resources\config.yml" $classes

$jar = "$root\build\SKDiscordServ.jar"
& $jarTool --create --file $jar -C $classes .
if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao empacotar o jar." }

$size = [math]::Round((Get-Item $jar).Length / 1KB, 1)
Write-Host "OK -> build\SKDiscordServ.jar ($size KB)" -ForegroundColor Green

if ($Deploy) {
    if (-not (Test-Path $Deploy)) { Write-Error "Pasta de deploy nao existe: $Deploy" }
    Copy-Item $jar $Deploy -Force
    Write-Host "Copiado para $Deploy" -ForegroundColor Green
}
