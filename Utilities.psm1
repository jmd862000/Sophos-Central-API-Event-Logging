#Encrypt API Key and Store in DB
function Get-EncryptedApiKeys{
    $key = Read-Host -Prompt "Enter the API Key: "
    $auth = Read-Host -Prompt "Enter the Authorization: "
    $Password = $env:APIHASH
    $Salt = $null
    $EncryptedText = $null

    Encrypt-String -PlainText $key -Salt ([ref]$Salt) -EncryptedText ([ref]$EncryptedText) -Password $Password
    Write-Output "ApiKey is: $EncryptedText"
    Write-Output "ApiSalt is: $Salt"
    Write-Output "PlainText API is: $(Decrypt-String -EncryptedText $EncryptedText -Password $Password -Salt $Salt)"

    Encrypt-String -PlainText $auth -Salt ([ref]$Salt) -EncryptedText ([ref]$EncryptedText) -Password $Password
    Write-Output "Auth is: $EncryptedText"
    Write-Output "AuthSalt is: $Salt"
    Write-Output "PlainText Auth is: $(Decrypt-String -EncryptedText $EncryptedText -Password $Password -Salt $Salt)"
}
#Convert JSON to Hashtable
function ConvertFrom-JsonToHashtable {
    Param(
       [string]$InputObject
    );
    if ($InputObject) {
       $input = $InputObject
    }
    $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $hashtable = $serializer.Deserialize($input, [System.Collections.Hashtable])
    return $hashtable
 }
 
 function Get-ExpandedConfigFromJson ([string]$inputJson,[string]$apikey,[string]$authorization){
    $expanded = $ExecutionContext.InvokeCommand.ExpandString($inputJson)
    $output = ConvertFrom-JsonToHashtable -InputObject $expanded
    return $output
}

function Encrypt-String () {
    Param([string]$PlainText,
    [string]$Password,
    [ref]$Salt,
    [ref]$EncryptedText);
    $deriveBytes = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password,32)
    [byte[]]$EncryptedMessage=$null
    $result = AESEncrypt ([System.Text.Encoding]::ASCII.GetBytes($PlainText)) ([System.Text.Encoding]::ASCII.GetBytes($Password)) ([ref]$EncryptedMessage) $deriveBytes.Salt
    if($result){
        $Salt.Value = [System.Convert]::ToBase64String($deriveBytes.Salt)
    }else{
        throw
    }
    $EncryptedText.Value = [System.Convert]::ToBase64String($EncryptedMessage)
}

function Decrypt-String(){
    Param(
        [string]$EncryptedText,
        [string]$Password,
        [string]$Salt
    );
    $byteSalt = [System.Convert]::FromBase64String($Salt)
    $byteCipher = [System.Convert]::FromBase64String($EncryptedText)
    [byte[]]$bytePlainText = $null
    $result = AESDecrypt $byteCipher ([System.Text.Encoding]::ASCII.GetBytes($Password)) ([ref]$bytePlainText) $byteSalt
    if($result){
        $PlainText = ([System.Text.Encoding]::UTF8.GetString($bytePlainText))
    }else{
        throw
    }
    return $PlainText
}

function AESEncrypt()
{
	Param(
		[Parameter(Mandatory=$true)][byte[]]$aBytesToBeEncrypted,
		[Parameter(Mandatory=$true)][byte[]]$aPasswordBytes,
		[Parameter(Mandatory=$true)][ref]$raEncryptedBytes,
		[Parameter(Mandatory=$false)][byte[]]$aCustomSalt
	)		
    [byte[]] $encryptedBytes = @()
    # Salt must have at least 8 Bytes!!
    # Encrypt and decrypt must use the same salt
    # Define your own Salt here
    [byte[]]$aSaltBytes = @(4,7,12,254,123,98,34,12,67,12,122,111) 
	if($aCustomSalt.Count -ge 1)
	{
		$aSaltBytes=$aCustomSalt
	}	
    [System.IO.MemoryStream] $oMemoryStream = new-object System.IO.MemoryStream
    [System.Security.Cryptography.RijndaelManaged] $oAES = new-object System.Security.Cryptography.RijndaelManaged
    $oAES.KeySize = 256;
    $oAES.BlockSize = 128;
    [System.Security.Cryptography.Rfc2898DeriveBytes] $oKey = new-object System.Security.Cryptography.Rfc2898DeriveBytes($aPasswordBytes, $aSaltBytes, 1000);
    $oAES.Key = $oKey.GetBytes($oAES.KeySize / 8);
    $oAES.IV = $oKey.GetBytes($oAES.BlockSize / 8);
    $oAES.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $oCryptoStream = new-object System.Security.Cryptography.CryptoStream($oMemoryStream, $oAES.CreateEncryptor(), [System.Security.Cryptography.CryptoStreamMode]::Write)
	try
	{
		$oCryptoStream.Write($aBytesToBeEncrypted, 0, $aBytesToBeEncrypted.Length);
		$oCryptoStream.Close();
	}
	catch [Exception]
	{
		$raEncryptedBytes.Value=[system.text.encoding]::ASCII.GetBytes("Error occured while encoding string. Salt or Password incorrect?")
		return $false
	}	
    $oEncryptedBytes = $oMemoryStream.ToArray();
    $raEncryptedBytes.Value=$oEncryptedBytes;
	return $true
}

function AESDecrypt()
{
	Param(
		[Parameter(Mandatory=$true)][byte[]]$aBytesToDecrypt,
		[Parameter(Mandatory=$true)][byte[]]$aPasswordBytes,
		[Parameter(Mandatory=$true)][ref]$raDecryptedBytes,
		[Parameter(Mandatory=$false)][byte[]]$aCustomSalt
	)	
    [byte[]]$oDecryptedBytes = @();
	# Salt must have at least 8 Bytes!!
	# Encrypt and decrypt must use the same salt
    [byte[]]$aSaltBytes = @(4,7,12,254,123,98,34,12,67,12,122,111) 
	if($aCustomSalt.Count -ge 1)
	{
		$aSaltBytes=$aCustomSalt
	}
    [System.IO.MemoryStream] $oMemoryStream = new-object System.IO.MemoryStream
    [System.Security.Cryptography.RijndaelManaged] $oAES = new-object System.Security.Cryptography.RijndaelManaged
    $oAES.KeySize = 256;
    $oAES.BlockSize = 128;
    [System.Security.Cryptography.Rfc2898DeriveBytes] $oKey = new-object System.Security.Cryptography.Rfc2898DeriveBytes($aPasswordBytes, $aSaltBytes, 1000);
    $oAES.Key = $oKey.GetBytes($oAES.KeySize / 8);
    $oAES.IV = $oKey.GetBytes($oAES.BlockSize / 8);
    $oAES.Mode = [System.Security.Cryptography.CipherMode]::CBC
	$oCryptoStream = new-object System.Security.Cryptography.CryptoStream($oMemoryStream, $oAES.CreateDecryptor(), [System.Security.Cryptography.CryptoStreamMode]::Write)
	try
	{
		$oCryptoStream.Write($aBytesToDecrypt, 0, $aBytesToDecrypt.Length)
		$oCryptoStream.Close()
	}
	catch [Exception]
	{
		$raDecryptedBytes.Value=[system.text.encoding]::ASCII.GetBytes("Error occured while decoding string. Salt or Password incorrect?")
		return $false
	}
    $oDecryptedBytes = $oMemoryStream.ToArray();
	$raDecryptedBytes.Value=$oDecryptedBytes
	return $true
}