
function Get-MultipartBody($boundary, $paths, $fields) {
    $boundary = "`r`n--" + $boundary
    $multipart = @($fields.Keys + $paths) | % {
            $name = if ($paths.IndexOf($_) -ne -1) {'upload_files'} else {$_}
            $contentDisposition = "Content-Disposition: form-data; name=`"$name`""
            $contentType = ''
            $data = ''
            if ($name -eq 'upload_files') {
                $filename = [IO.Path]::GetFileName($_)
                $contentDisposition = $contentDisposition + "; filename=`"$filename`""
                $contentType = "`r`n`Content-Type: application/x-msdownload"
                $bytes = [IO.File]::ReadAllBytes($_)
                $data = [Text.Encoding]::GetEncoding('ISO-8859-1').GetString($bytes)
            } else {
                $data = $fields.Item($_)
            }
            return $contentDisposition + $contentType + "`r`n`r`n" + $data
        }
    $middle = $multipart -join ($boundary + "`r`n")
    return $boundary + "`r`n" + $middle + $boundary + "--"
}

$product = 'Nexion Smart ERP'
$version = '24.1.0.1'
$user = $env:NEXION_USERNAME
$pass = $env:NEXION_PASSWORD
$files = @(".\NexionSmartERP-ApiService-AnyCPU-23.3.0.24")
$fields = @{
    product_name = $product_name
    version = $version
}
$boundary = [System.Guid]::NewGuid().ToString()
$body = Get-MultipartBody $boundary $files $fields

$endpoint = "https://www.nexion.com.ar"

Write-Host "Login API"
$login = @{identifier = $user; password = $pass }
Invoke-WebRequest -Uri "$endpoint/login" -Method Post -Body $login -SessionVariable session

Write-Host "Publish API"
Invoke-WebRequest -Uri "$endpoint/services/release/publish/add" -Method Post -Body $body -WebSession $session -ContentType "multipart/form-data; boundary=$boundary" -TimeoutSec 300000 -MaximumRedirection 0