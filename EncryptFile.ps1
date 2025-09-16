param (
    [Parameter(Mandatory=$true)]
    [System.IO.FileInfo]$FilePath,

    [Parameter(Mandatory=$true)]
    [SecureString]$Password
)

# Convert SecureString to a byte array and set key length to 32 bytes (256 bits)
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$bytes = [System.Text.Encoding]::UTF8.GetBytes(
    [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

# Ensure the key is exactly 32 bytes long for AES-256
[Array]::Resize([ref]$bytes, 32)
$key = $bytes


# Set up AES encryption parameters
$aes = New-Object System.Security.Cryptography.AesManaged
$aes.KeySize = 256
$aes.BlockSize = 128
$aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
$aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
$aes.Key = $key
$aes.GenerateIV()
$iv = $aes.IV

# Create the encryptor and file streams
$encryptor = $aes.CreateEncryptor()
$inStream = New-Object System.IO.FileStream($FilePath, [System.IO.FileMode]::Open)
$outStream = New-Object System.IO.FileStream("$FilePath.enc", [System.IO.FileMode]::Create)

# Write the IV to the output file first
$outStream.Write($iv, 0, $iv.Length)

# Use CryptoStream to perform the encryption
$cryptoStream = New-Object System.Security.Cryptography.CryptoStream($outStream, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
$inStream.CopyTo($cryptoStream)

$cryptoStream.Close()
$inStream.Close()
$outStream.Close()

Write-Host "File '$FilePath' encrypted successfully to '$($FilePath).enc'"