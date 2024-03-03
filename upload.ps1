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

$fields = @{}
$files = @("binary.exe")
$boundary = [System.Guid]::NewGuid().ToString()
$body = Get-MultipartBody $boundary $files $fields

Write-Host "File.io Upload"
$result = Invoke-RestMethod -Uri "https://file.io" -Method Post -Body $body -ContentType "multipart/form-data; boundary=$boundary" -TimeoutSec 300000 -MaximumRedirection 0
Write-Host "File is at https://file.io/$($result.key)"