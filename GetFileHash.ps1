[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $Path
)

$Path = Resolve-Path -Path $Path

if (-not (Test-Path -Path $Path -PathType Leaf)) {
    Write-Error "File not found: $Path"
    return $null
}

try {
    $cryptoProvider = New-Object System.Security.Cryptography.SHA256Managed
    $fileStream = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    $hashBytes = $cryptoProvider.ComputeHash($fileStream)
    $hashString = [System.BitConverter]::ToString($hashBytes).Replace('-', '').ToLower()
    return $hashString
}
catch {
    Write-Error "Failed to compute hash for '$Path'. Error: $_"
    return $null
}
finally {
    if ($fileStream) {
        $fileStream.Close()
        $fileStream.Dispose()
    }
    if ($cryptoProvider) {
        $cryptoProvider.Dispose()
    }
}
