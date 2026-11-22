<#
  coletar-hardware.ps1
  Inventario completo do PC (hardware + saude + o que pesa no sistema).
  Compativel com PowerShell 2.0 (Windows 7) em diante. Somente LEITURA:
  nao altera nada no PC.

  Uso local (pendrive):   powershell -ExecutionPolicy Bypass -File .\coletar-hardware.ps1
  Uso remoto:             Invoke-Command -Session $s -FilePath .\coletar-hardware.ps1
  Saida: texto na tela e arquivo inventario-<PC>-<data>.txt ao lado do script
         (quando rodado localmente).
#>

$ErrorActionPreference = 'SilentlyContinue'
$out = New-Object System.Collections.ArrayList

function Add-Line([string]$t) { [void]$out.Add($t) }
function Add-Section([string]$t) { Add-Line ''; Add-Line ('=' * 70); Add-Line "  $t"; Add-Line ('=' * 70) }
function GB($b) { if ($b) { '{0:N1} GB' -f ($b / 1GB) } else { '?' } }
function Add-Obj($objs, [string[]]$props) {
    foreach ($o in @($objs)) {
        foreach ($p in $props) { Add-Line ('  {0,-28}: {1}' -f $p, $o.$p) }
        Add-Line '  ---'
    }
}

Add-Line "INVENTARIO DO PC - gerado em $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# ---------------- Sistema ----------------
Add-Section 'SISTEMA OPERACIONAL'
$os = Get-WmiObject Win32_OperatingSystem
$cs = Get-WmiObject Win32_ComputerSystem
Add-Line "  Nome do PC                  : $($env:COMPUTERNAME)"
Add-Line "  Sistema                     : $($os.Caption) $($os.OSArchitecture)"
Add-Line "  Versao / Build              : $($os.Version) / SP $($os.ServicePackMajorVersion)"
Add-Line "  Instalado em                : $($os.ConvertToDateTime($os.InstallDate))"
Add-Line "  Ultimo boot                 : $($os.ConvertToDateTime($os.LastBootUpTime))"
Add-Line "  Fabricante / Modelo         : $($cs.Manufacturer) / $($cs.Model)"
Add-Line "  Tipo (1=desk 2=note)        : $($cs.PCSystemType)"
Add-Line "  Usuario logado              : $($cs.UserName)"
Add-Line "  PowerShell                  : $($PSVersionTable.PSVersion)"

# ---------------- Placa-mae / BIOS ----------------
Add-Section 'PLACA-MAE E BIOS'
$bb = Get-WmiObject Win32_BaseBoard
$bios = Get-WmiObject Win32_BIOS
Add-Line "  Placa-mae                   : $($bb.Manufacturer) $($bb.Product) (rev $($bb.Version))"
Add-Line "  BIOS                        : $($bios.Manufacturer) $($bios.SMBIOSBIOSVersion) ($($bios.ConvertToDateTime($bios.ReleaseDate)))"
Add-Line "  Serial                      : $($bios.SerialNumber)"
$fw = 'Legacy/BIOS (provavel)'
if (Test-Path 'HKLM:\System\CurrentControlSet\Control\SecureBoot\State') { $fw = 'UEFI' }
Add-Line "  Firmware                    : $fw"

# ---------------- CPU ----------------
Add-Section 'PROCESSADOR'
foreach ($c in @(Get-WmiObject Win32_Processor)) {
    Add-Line "  Modelo                      : $($c.Name.Trim())"
    Add-Line "  Nucleos / Threads           : $($c.NumberOfCores) / $($c.NumberOfLogicalProcessors)"
    Add-Line "  Clock max / atual           : $($c.MaxClockSpeed) MHz / $($c.CurrentClockSpeed) MHz"
    Add-Line "  Suporte 64 bits             : $(if ($c.DataWidth -eq 64) {'SIM'} else {'NAO (so 32 bits)'})"
    Add-Line "  Socket                      : $($c.SocketDesignation)"
    Add-Line "  Virtualizacao (VT)          : $($c.VirtualizationFirmwareEnabled)"
    Add-Line "  Uso agora                   : $($c.LoadPercentage) %"
}

# ---------------- RAM ----------------
Add-Section 'MEMORIA RAM'
Add-Line "  Total visivel               : $(GB $cs.TotalPhysicalMemory)"
Add-Line "  Livre agora                 : $('{0:N1} GB' -f ($os.FreePhysicalMemory / 1MB))"
$arr = Get-WmiObject Win32_PhysicalMemoryArray
Add-Line "  Slots na placa              : $($arr.MemoryDevices)"
Add-Line "  Maximo suportado            : $('{0:N0} GB' -f ($arr.MaxCapacity / 1MB))"
$tipos = @{20='DDR';21='DDR2';24='DDR3';26='DDR4';34='DDR5'}
foreach ($m in @(Get-WmiObject Win32_PhysicalMemory)) {
    $t = $tipos[[int]$m.SMBIOSMemoryType]; if (-not $t) { $t = $tipos[[int]$m.MemoryType] }; if (-not $t) { $t = "codigo $($m.SMBIOSMemoryType)" }
    Add-Line ("  Pente {0,-22}: {1} {2} {3} MHz  ({4} {5})" -f $m.DeviceLocator, (GB $m.Capacity), $t, $m.Speed, $m.Manufacturer, $m.PartNumber)
}

# ---------------- Discos ----------------
Add-Section 'DISCOS FISICOS'
$smart = @{}
foreach ($f in @(Get-WmiObject -Namespace root\wmi MSStorageDriver_FailurePredictStatus)) { $smart[$f.InstanceName] = $f.PredictFailure }
foreach ($d in @(Get-WmiObject Win32_DiskDrive)) {
    Add-Line "  Modelo                      : $($d.Model)"
    Add-Line "  Tamanho / Interface         : $(GB $d.Size) / $($d.InterfaceType)"
    Add-Line "  Serial                      : $($d.SerialNumber)"
    Add-Line "  Status WMI                  : $($d.Status)"
    $pf = $null; foreach ($k in $smart.Keys) { if ($k -like "*$($d.PNPDeviceID.Split('\')[-1])*") { $pf = $smart[$k] } }
    if ($pf -ne $null) { Add-Line "  SMART preve falha?          : $(if ($pf) {'SIM  <<< DISCO MORRENDO'} else {'nao'})" }
    Add-Line '  ---'
}
$pd = Get-WmiObject -Namespace root\Microsoft\Windows\Storage MSFT_PhysicalDisk
if ($pd) {
    $mt = @{0='desconhecido';3='HDD';4='SSD';5='SCM'}
    $hs = @{0='boa';1='ATENCAO';2='RUIM <<<';5='desconhecida'}
    foreach ($p in @($pd)) { Add-Line ("  {0,-28}: tipo {1}, saude {2}" -f $p.FriendlyName, $mt[[int]$p.MediaType], $hs[[int]$p.HealthStatus]) }
}

Add-Section 'PARTICOES / ESPACO'
foreach ($v in @(Get-WmiObject Win32_LogicalDisk -Filter 'DriveType=3')) {
    $pct = 0; if ($v.Size) { $pct = [math]::Round(100 * $v.FreeSpace / $v.Size) }
    Add-Line ("  {0}  {1,-10} total {2,-10} livre {3,-10} ({4}% livre)" -f $v.DeviceID, $v.FileSystem, (GB $v.Size), (GB $v.FreeSpace), $pct)
}

# ---------------- Video / Rede / Bateria ----------------
Add-Section 'PLACA DE VIDEO'
Add-Obj (Get-WmiObject Win32_VideoController) @('Name','AdapterRAM','DriverVersion','DriverDate','VideoModeDescription')

Add-Section 'REDE'
foreach ($n in @(Get-WmiObject Win32_NetworkAdapter -Filter 'PhysicalAdapter=True')) {
    Add-Line ("  {0} | MAC {1} | conectado: {2}" -f $n.Name, $n.MACAddress, ($n.NetConnectionStatus -eq 2))
}
foreach ($c in @(Get-WmiObject Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=True')) { Add-Line "  IP: $($c.IPAddress -join ', ')" }

Add-Section 'BATERIA (se notebook)'
$bat = Get-WmiObject Win32_Battery
if ($bat) {
    Add-Obj $bat @('Name','EstimatedChargeRemaining','BatteryStatus')
    $full = Get-WmiObject -Namespace root\wmi BatteryFullChargedCapacity
    $des  = Get-WmiObject -Namespace root\wmi BatteryStaticData
    if ($full -and $des -and $des.DesignedCapacity) { Add-Line ("  Saude da bateria            : {0}% da capacidade original" -f [math]::Round(100 * $full.FullChargedCapacity / $des.DesignedCapacity)) }
} else { Add-Line '  Sem bateria (desktop).' }

Add-Section 'TEMPERATURA (nem todo PC informa)'
$tz = Get-WmiObject -Namespace root\wmi MSAcpi_ThermalZoneTemperature
if ($tz) { foreach ($z in @($tz)) { Add-Line ('  {0}: {1:N0} C' -f $z.InstanceName, ($z.CurrentTemperature / 10 - 273.15)) } } else { Add-Line '  Nao disponivel.' }

# ---------------- O que pesa ----------------
Add-Section 'PROGRAMAS NA INICIALIZACAO'
foreach ($s in @(Get-WmiObject Win32_StartupCommand)) { Add-Line ("  {0,-30} {1}" -f $s.Name, $s.Command) }

Add-Section 'TOP 15 PROCESSOS POR MEMORIA'
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 15 | ForEach-Object { Add-Line ("  {0,-30} {1,8:N0} MB" -f $_.ProcessName, ($_.WorkingSet / 1MB)) }

Add-Section 'ANTIVIRUS'
foreach ($a in @(Get-WmiObject -Namespace root\SecurityCenter2 AntiVirusProduct)) { Add-Line "  $($a.displayName)" }

Add-Section 'PROGRAMAS INSTALADOS'
$keys = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
$apps = Get-ItemProperty $keys | Where-Object { $_.DisplayName } | Sort-Object DisplayName -Unique
Add-Line "  Total: $(@($apps).Count)"
foreach ($a in $apps) { Add-Line ("  {0} {1}" -f $a.DisplayName, $a.DisplayVersion) }

# ---------------- Erros que indicam hardware ruim ----------------
Add-Section 'ERROS DE DISCO/HARDWARE NO LOG (ultimos 30 dias)'
$desde = (Get-Date).AddDays(-30)
$ev = Get-EventLog -LogName System -After $desde -EntryType Error,Warning | Where-Object { @(7,11,15,51,55,129,153,41,6008) -contains $_.EventID }
if ($ev) {
    $ev | Group-Object Source, EventID | Sort-Object Count -Descending | ForEach-Object { Add-Line ("  {0,4}x  {1}" -f $_.Count, $_.Name) }
    Add-Line '  (7/51/153 = disco com setor ruim; 41/6008 = desligou sem querer; 129 = controlador travando)'
} else { Add-Line '  Nenhum erro relevante encontrado.' }

Add-Section 'TEMPO DE BOOT (Windows 7+)'
$boot = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Diagnostics-Performance/Operational'; Id=100} -MaxEvents 5
if ($boot) { foreach ($b in $boot) { $x = [xml]$b.ToXml(); $ms = ($x.Event.EventData.Data | Where-Object { $_.Name -eq 'BootTime' }).'#text'; Add-Line ("  {0}: {1:N0} s" -f $b.TimeCreated, ($ms / 1000)) } } else { Add-Line '  Sem registro (precisa rodar como Administrador).' }

# ---------------- Saida ----------------
$texto = $out -join "`r`n"
$texto
if ($MyInvocation.MyCommand.Path) {
    $arq = Join-Path (Split-Path $MyInvocation.MyCommand.Path) ("inventario-{0}-{1}.txt" -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd-HHmm'))
    $texto | Out-File -FilePath $arq -Encoding UTF8
    Write-Host "`nRelatorio salvo em: $arq" -ForegroundColor Green
}
