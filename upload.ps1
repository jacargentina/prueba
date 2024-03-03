function Get-MultipartBody($boundary, $files, $fields) {
    $tempFile = [System.IO.Path]::GetTempFileName()
    $UTF8woBOM = New-Object "System.Text.UTF8Encoding" -ArgumentList @($false)
    # Campos
    if ($fields.Keys.Count -gt 0) {
        $sw = New-Object System.IO.StreamWriter($tempFile, $true, $UTF8woBOM)
        foreach($field in $fields.Keys) {
            $sw.Write("`r`n--$boundary`r`nContent-Disposition: form-data; name=`"$field`"`r`n`r`n$($fields.Item($field))")
        }
        $sw.Close()
    }
    # Archivos binarios
    if ($files.Length -gt 0) {
        $files | % {
            $sw = New-Object System.IO.StreamWriter($tempFile, $true, $UTF8woBOM)
            $fileName = [System.IO.Path]::GetFileName($_)
            $sw.Write("`r`n--$boundary`r`nContent-Disposition: form-data;name=`"upload_files`";filename=`"$fileName`"`r`n`r`n")
            $sw.Close()

            $fs = New-Object System.IO.FileStream($tempFile, [System.IO.FileMode]::Append)
            $bw = New-Object System.IO.BinaryWriter($fs)
            $fileBinary = [System.IO.File]::ReadAllBytes($_)
            $bw.Write($fileBinary)
            $bw.Close()
        }
    }
    $sw = New-Object System.IO.StreamWriter($tempFile, $true, $UTF8woBOM)
    $sw.Write("`r`n--$boundary--`r`n")
    $sw.Close()
    $tempFile
}

$fields = @{name="Javier"; lastname="Castro"}
$files = @("binary.exe")
$boundary = [System.Guid]::NewGuid().ToString()
$tempFile = Get-MultipartBody $boundary $files $fields

Write-Host "File.io Upload"
$result = Invoke-RestMethod -Uri "https://file.io" -Method Post -ContentType "multipart/form-data; boundary=$boundary" -InFile $tempFile
Write-Host "File is at https://file.io/$($result.key)"