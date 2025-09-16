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

# Set up AES decryption parameters (must be the same as encryption)
$aes = New-Object System.Security.Cryptography.AesManaged
$aes.KeySize = 256
$aes.BlockSize = 128
$aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
$aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
$aes.Key = $key

# Create the decryptor and file streams
$inStream = New-Object System.IO.FileStream($FilePath, [System.IO.FileMode]::Open)
$iv = New-Object byte[]($aes.IV.Length)

# Read the IV from the beginning of the encrypted file
$inStream.Read($iv, 0, $iv.Length)
$aes.IV = $iv

# Create the decryptor and a new file stream for the output
$decryptor = $aes.CreateDecryptor()
$outFile = $FilePath.FullName.Replace(".enc", "")
$outStream = New-Object System.IO.FileStream($outFile, [System.IO.FileMode]::Create)

# Use CryptoStream to perform the decryption
$cryptoStream = New-Object System.Security.Cryptography.CryptoStream($outStream, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
$inStream.CopyTo($cryptoStream)

try {
    $cryptoStream.Close()

}
catch {
    Write-Error "Decryption failed. Password was likely incorrect"
    exit
}
finally {
    $inStream.Close()
    $outStream.Close()
}



Write-Host "File '$FilePath' decrypted successfully to '$outFile'"