param(
  [string]$CsvPath = 'C:\Users\sowin\baza_kabli_v2.csv',
  [string]$DatabasePath = 'assets/data/cables/local_cable_database.json',
  [switch]$ReplaceExisting
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Nz([string]$value) {
  if ($null -eq $value) { return '' }
  return $value
}

function FindCol([string[]]$columns, [string[]]$patterns) {
  foreach ($pattern in $patterns) {
    $found = $columns | Where-Object { $_ -match $pattern } | Select-Object -First 1
    if (-not [string]::IsNullOrWhiteSpace($found)) { return $found }
  }
  return $null
}

function ColValue($row, [string]$columnName) {
  if ([string]::IsNullOrWhiteSpace($columnName)) { return '' }
  $prop = $row.PSObject.Properties[$columnName]
  if ($null -eq $prop) { return '' }
  return [string]$prop.Value
}

function ToDouble([string]$v) {
  if ([string]::IsNullOrWhiteSpace($v)) { return $null }
  $n = $v.Trim().Replace(',', '.')
  $out = 0.0
  if ([double]::TryParse($n, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$out)) {
    return [double]$out
  }
  $m = [regex]::Match($n, '[0-9]+(?:\.[0-9]+)?')
  if ($m.Success -and [double]::TryParse($m.Value, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$out)) {
    return [double]$out
  }
  return $null
}

function Cross([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return $null }
  if ($s -match '^[0-9]+x[0-9]+x([0-9]+(?:[\.,][0-9]+)?)$') { return ToDouble $Matches[1] }
  if ($s -match '^[0-9]+x([0-9]+(?:[\.,][0-9]+)?)$') { return ToDouble $Matches[1] }
  if ($s -match '([0-9]+(?:[\.,][0-9]+)?)\s*mm') { return ToDouble $Matches[1] }
  $m = [regex]::Matches($s, '[0-9]+(?:[\.,][0-9]+)?')
  if ($m.Count -eq 0) { return $null }
  return ToDouble $m[$m.Count - 1].Value
}

function DefaultDiameter([double]$cross, [string]$wireCfg) {
  $base = [Math]::Sqrt([Math]::Max($cross, 0.25)) * 2.2
  switch ($wireCfg) {
    'pair' { return [Math]::Round($base * 2.1, 1) }
    'twoWire' { return [Math]::Round($base * 2.3, 1) }
    'threeWire' { return [Math]::Round($base * 2.7, 1) }
    'fourWire' { return [Math]::Round($base * 3.0, 1) }
    'fiveWire' { return [Math]::Round($base * 3.3, 1) }
    'sevenWire' { return [Math]::Round($base * 3.7, 1) }
    'twelvWire' { return [Math]::Round($base * 4.2, 1) }
    'twentyFiveWire' { return [Math]::Round($base * 5.1, 1) }
    default { return [Math]::Round($base * 2.0, 1) }
  }
}

function WireCfg([string]$s) {
  if ([string]::IsNullOrWhiteSpace($s)) { return 'single' }
  $r = $s.ToLowerInvariant().Replace(' ', '')
  if ($r -match '^[0-9]+x2x[0-9]+([\.,][0-9]+)?$') { return 'pair' }
  if ($r -match '^([0-9]+)x') {
    switch ([int]$Matches[1]) {
      1 { return 'single' }
      2 { return 'twoWire' }
      3 { return 'threeWire' }
      4 { return 'fourWire' }
      5 { return 'fiveWire' }
      7 { return 'sevenWire' }
      12 { return 'twelvWire' }
      25 { return 'twentyFiveWire' }
      default { return 'single' }
    }
  }
  return 'single'
}

function MapType([string]$tRaw, [string]$cRaw) {
  $t = (Nz $tRaw).ToLowerInvariant()
  $c = (Nz $cRaw).ToLowerInvariant()

  if ($t -like '*ydyp*') { return 'ydyp' }
  if ($t -match '^ydy') { return 'ydy' }
  if ($t -like '*omy*' -or $t -like '*owy*' -or $t -like '*nym-j*') { return 'omy' }
  if ($t -match '^yky$') { return 'yky' }
  if ($t -match '^yaky$') { return 'yaky' }
  if ($t -like 'n2xh*' -and $t -notlike '*fe180*') { return 'n2xh' }
  if ($t -like '*nhxh*' -or $t -like '*(n)hxh*' -or $t -like '*fe180*e90*') { return 'nhxh' }
  if ($t -like '*hdgs*') { return 'hdgs' }
  if ($t -like '*hlgs*') { return 'hlgs' }
  if ($t -like '*htksh*') { return 'htksh' }
  if ($t -like '*u/utp*') { if ($t -like '*6*') { return 'utp6' } return 'utp5e' }
  if ($t -like '*f/utp*') { return 'futp6' }
  if ($t -like '*s/ftp*' -or $t -like '*f/ftp*') { return 'sftp7' }
  if ($t -like '*rg6*') { return 'rg6' }
  if ($t -like '*rg11*') { return 'rg11' }
  if ($t -like '*yntksy*' -or $t -like '*ytksy*') { return 'ytnksy' }
  if ($t -like '*liyy*') { return 'liyy' }
  if ($t -like '*liycy*') { return 'liycyekaprn' }
  if ($t -like '*ysly*' -or $t -like '*jz*') { return 'ysly' }
  if ($t -like '*h07rn-f*') { return 'h07rnf' }
  if ($t -like '*h01n2-d*') { return 'h07rnf' }
  if ($t -like '*h1z2z2-k*') { return 'h07rnf' }
  if ($t -like '*lgy*' -or $t -like '*h07v-k*' -or $t -like '*dy*') { return 'ydy' }

  if ($t -like '*hdhp*') { return 'hdgs' }

  if ($t -like '*w-notktsd*' -or $t -like '*z-xotktsd*' -or $t -like '*ftth*drop*') {
    return 'xztkmxpwz'
  }
  if ($t -like '*yhakxs*') { return 'yhakxs' }
  if ($t -like '*xhakxs*' -or $t -like '*ykxs*') { return 'xhakxs' }
  if ($t -like '*xruhakxs*') { return 'xruhakxs' }
  if ($t -like '*a2xsy*' -or $t -like '*yakxs*') { return 'a2xsy' }
  if ($t -like '*na2xsy*') { return 'na2xsy' }
  if ($c -like '*sn*' -or $c -like '*ziemne*') { return 'yky' }

  if ($c -like '*swiatlowod*') { return 'xztkmxpwz' }
  if ($c -like '*alarm*' -or $c -like '*tel*') { return 'ytnksy' }
  if ($c -like '*lan*' -or $c -like '*it*' -or $c -like '*multimedia*') { return 'utp6' }
  if ($c -like '*ppoz*') { return 'nhxh' }
  if ($c -like '*przemys*' -or $c -like '*spawal*' -or $c -like '*fotowoltaika*') { return 'h07rnf' }
  if ($c -like '*instalacyjne*') { return 'ydy' }

  return 'ydy'
}

function Material([string]$tRaw, [string]$cRaw) {
  $t = (Nz $tRaw).ToLowerInvariant()
  $c = (Nz $cRaw).ToLowerInvariant()
  if ($t -match 'yaky|yhakxs|a2xsy|na2xsy|yakxs') { return 'al' }
  if ($c -like '*sn*' -and $t -like '*yha*') { return 'al' }
  return 'cu'
}

function App([string]$type, [string]$catRaw) {
  $cat = (Nz $catRaw).ToLowerInvariant()
  switch ($type) {
    'ydy' { return 'electrical' }
    'ydyp' { return 'electrical' }
    'omy' { return 'electrical' }
    'yky' { return 'power' }
    'yaky' { return 'power' }
    'n2xh' { return 'power' }
    'nhxh' { return 'fireproof' }
    'hdgs' { return 'fireproof' }
    'hlgs' { return 'fireproof' }
    'htksh' { return 'fireproof' }
    'utp5e' { return 'telecom' }
    'utp6' { return 'telecom' }
    'futp6' { return 'telecom' }
    'sftp7' { return 'telecom' }
    'rg6' { return 'telecom' }
    'rg11' { return 'telecom' }
    'ytnksy' { return 'telecom' }
    'liyy' { return 'control' }
    'liycyekaprn' { return 'control' }
    'ysly' { return 'control' }
    'h07rnf' { return 'industrial' }
    'yhakxs' { return 'mediumVoltage' }
    'xhakxs' { return 'mediumVoltage' }
    'xruhakxs' { return 'mediumVoltage' }
    'a2xsy' { return 'mediumVoltage' }
    'na2xsy' { return 'mediumVoltage' }
    default {
      if ($cat -like '*alarm*' -or $cat -like '*lan*' -or $cat -like '*multimedia*' -or $cat -like '*swiatlowod*') { return 'telecom' }
      if ($cat -like '*ppoz*') { return 'fireproof' }
      if ($cat -like '*sn*' -or $cat -like '*ziemne*') { return 'mediumVoltage' }
      if ($cat -like '*przemys*' -or $cat -like '*spawal*') { return 'industrial' }
      return 'electrical'
    }
  }
}

function Group([string]$t) {
  switch ($t) {
    'ydy' { return 1 }
    'ydyp' { return 1 }
    'omy' { return 1 }
    'yky' { return 2 }
    'yaky' { return 2 }
    'n2xh' { return 2 }
    'hdgs' { return 3 }
    'hlgs' { return 3 }
    'nhxh' { return 3 }
    'htksh' { return 3 }
    'utp5e' { return 4 }
    'utp6' { return 4 }
    'futp6' { return 4 }
    'sftp7' { return 4 }
    'rg6' { return 4 }
    'rg11' { return 4 }
    'ytnksy' { return 4 }
    'liyy' { return 5 }
    'liycyekaprn' { return 5 }
    'ysly' { return 5 }
    'h07rnf' { return 5 }
    'yhakxs' { return 6 }
    'xhakxs' { return 6 }
    'xruhakxs' { return 6 }
    'a2xsy' { return 6 }
    'na2xsy' { return 6 }
    default { return 1 }
  }
}

function TubeStd([string]$app) {
  switch ($app) {
    'mediumVoltage' { return 'rgk' }
    'power' { return 'rgk' }
    'telecom' { return 'rc' }
    'fireproof' { return 'rck' }
    default { return 'rck' }
  }
}

function Hs31([double]$d) {
  if ($d -le 2.8) { return '3/1' }
  if ($d -le 5.5) { return '6/2' }
  if ($d -le 8.5) { return '9/3' }
  if ($d -le 11.0) { return '12/4' }
  if ($d -le 17.0) { return '19/6' }
  if ($d -le 22.0) { return '24/8' }
  if ($d -le 36.0) { return '40/13' }
  if ($d -le 48.0) { return '52/18' }
  if ($d -le 65.0) { return '70/25' }
  return '95/25'
}

function Hs21([double]$d) {
  if ($d -le 2.0) { return '2.4/1.2' }
  if ($d -le 4.0) { return '4.8/2.4' }
  if ($d -le 8.0) { return '9.5/4.8' }
  if ($d -le 16.0) { return '19.1/9.5' }
  if ($d -le 32.0) { return '38.1/19.1' }
  if ($d -le 65.0) { return '76.2/38.1' }
  return '100/50'
}

if (-not (Test-Path $CsvPath)) { throw "Brak pliku CSV: $CsvPath" }
if (-not (Test-Path $DatabasePath)) { throw "Brak bazy JSON: $DatabasePath" }

$backupPath = [System.IO.Path]::Combine(
  [System.IO.Path]::GetDirectoryName($DatabasePath),
  'local_cable_database.backup_before_csv_import_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.json'
)
Copy-Item $DatabasePath $backupPath -Force

$rows = Import-Csv -Path $CsvPath -Delimiter ';'
$db = Get-Content $DatabasePath -Raw | ConvertFrom-Json

$first = $rows | Select-Object -First 1
$columns = $first.PSObject.Properties.Name

$colCategory = FindCol $columns @('^Kategoria$')
$colType = FindCol $columns @('^Typ\s*kabla$')
$colSize = FindCol $columns @('Przekr', 'Rozmiar')
$colDiameter = FindCol $columns @('rednica.*\[mm\]', 'd\)\s*\[mm\]')
$colProducer = FindCol $columns @('^Producent$')
$colHalogen = FindCol $columns @('Halogen')
$colUsage = FindCol $columns @('Zastosowanie')
$colVoltage = FindCol $columns @('Napi', 'znamionowe')

$list = New-Object System.Collections.Generic.List[object]
$idx = @{}
if (-not $ReplaceExisting) {
  for ($i = 0; $i -lt $db.Count; $i++) {
    $it = $db[$i]
    $k = "{0}|{1}|{2}|{3}" -f $it.material, $it.type, $it.wireConfiguration, $it.crossSection
    $idx[$k] = $list.Count
    $list.Add($it)
  }
}

$mapped = 0
$added = 0
$updated = 0
$skipped = 0
$skippedTypes = @{}

foreach ($r in $rows) {
  $category = ColValue $r $colCategory
  $typeLabel = ColValue $r $colType
  $sizeLabel = ColValue $r $colSize
  $diameterLabel = ColValue $r $colDiameter
  $producer = ColValue $r $colProducer
  $halogen = ColValue $r $colHalogen
  $usage = ColValue $r $colUsage
  $voltage = ColValue $r $colVoltage

  $type = MapType $typeLabel $category
  if ($null -eq $type) {
    $skipped++
    $name = [string]$typeLabel
    if (-not $skippedTypes.ContainsKey($name)) { $skippedTypes[$name] = 0 }
    $skippedTypes[$name]++
    continue
  }

  $diameter = ToDouble ([string]$diameterLabel)
  $cross = Cross ([string]$sizeLabel)
  if ($null -eq $cross) { $cross = 1.0 }

  $material = Material $typeLabel $category
  $application = App $type $category
  $wire = WireCfg ([string]$sizeLabel)
  if ($null -eq $diameter) { $diameter = DefaultDiameter ([double]$cross) $wire }
  $group = Group $type
  $tube = TubeStd $application

  $maxV = [string]$voltage
  if ([string]::IsNullOrWhiteSpace($maxV) -or $maxV -eq '---') {
    if ($application -eq 'mediumVoltage') { $maxV = '12/20 kV' }
    elseif ($application -eq 'telecom') { $maxV = '300V' }
    else { $maxV = '0.6/1 kV' }
  }

  $temp = if ($application -eq 'mediumVoltage') { '-40C do +90C' } else { '-30C do +70C' }

  $obj = [pscustomobject]@{
    material = $material
    type = $type
    crossSection = [Math]::Round([double]$cross, 3)
    coreType = 're'
    outerDiameter = [Math]::Round([double]$diameter, 3)
    heatShrinkSleeve = Hs31 ([double]$diameter)
    heatShrinkLabel = Hs21 ([double]$diameter)
    application = $application
    maxVoltage = $maxV
    temperatureRange = $temp
    wireConfiguration = $wire
    groupNumber = $group
    recommendedTubeStandard = $tube
    source = 'csv:baza_kabli_v2'
    sourceCategory = [string]$category
    sourceType = [string]$typeLabel
    sourceSize = [string]$sizeLabel
    manufacturer = [string]$producer
    cpr = ''
    insulation = ''
    halogenFree = [string]$halogen
    notes = ''
    usage = [string]$usage
    importedAt = (Get-Date).ToString('s')
  }

  $key = "{0}|{1}|{2}|{3}" -f $obj.material, $obj.type, $obj.wireConfiguration, $obj.crossSection
  if ($ReplaceExisting) {
    $list.Add($obj)
    $added++
  }
  else {
    if ($idx.ContainsKey($key)) {
      $list[$idx[$key]] = $obj
      $updated++
    }
    else {
      $idx[$key] = $list.Count
      $list.Add($obj)
      $added++
    }
  }

  $mapped++
}

$list | ConvertTo-Json -Depth 12 | Set-Content -Path $DatabasePath -Encoding UTF8

Write-Output "Backup: $backupPath"
if ($ReplaceExisting) {
  Write-Output "Mode: replace-existing"
}
else {
  Write-Output "Mode: merge-upsert"
}
Write-Output "CSV rows: $($rows.Count)"
Write-Output "Mapped: $mapped"
Write-Output "Added: $added"
Write-Output "Updated: $updated"
Write-Output "Skipped: $skipped"
if ($skippedTypes.Count -gt 0) {
  Write-Output "Top skipped types:"
  $skippedTypes.GetEnumerator() |
    Sort-Object Value -Descending |
    Select-Object -First 12 |
    ForEach-Object { Write-Output (" - {0}: {1}" -f $_.Key, $_.Value) }
}
