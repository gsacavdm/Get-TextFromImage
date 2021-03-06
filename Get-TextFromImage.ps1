function Get-TextFromImage {
  
  [CmdletBinding(DefaultParameterSetName = ”ImagePath”)]
  
  param(
    [Parameter(ParameterSetName = 'ImagePath', Mandatory = $true)]
    $ImagePath,
    
    [Parameter(ParameterSetName = 'FromClipboard')]
    [Switch]
    $FromClipboard,
  
    [Switch]
    $ToClipboard,
  
    $CogsResourceGroupName,
    $CogsAccountName,
    $JoinChar = " ",
    $TempLocation = $env:TEMP
  )
    
  $CogsAccountFilePath = "$TempLocation\cogs.cvs"
  
  $ErrorActionPreference = "Stop"
  
  $dateString = (Get-Date).ToString("yyyymmdd-HHMMss")
  $filePath = "$TempLocation\$dateString.png"
    
  if ($FromClipboard) {
    Write-Verbose "Getting image from clipboard."
    $image = Get-Clipboard -Format Image
    if (!$image) {
      throw New-Object Exception("No image available in clipboard.")
    }
  }
  else {
    Write-Verbose "Getting image from path."
    try { $image = New-Object System.Drawing.Bitmap($ImagePath) } catch {}
    if (!$image) {
      throw New-Object Exception("Unable to load image from [$ImagePath].")
    }
  }
  
  if ($image.Width -lt 50) {
    Write-Verbose "Resizing width"
    $ratio = 50.0 / $image.Width
    $newSize = New-Object System.Drawing.Size(($image.Width * $ratio), ($image.Height * $ratio))
    $image = New-Object System.Drawing.Bitmap($image, $newSize)
  }
  if ($image.Height -lt 50) {
    Write-Verbose "Resizing height"
    $ratio = 50.0 / $image.Height
    $newSize = New-Object System.Drawing.Size(($image.Width * $ratio), ($image.Height * $ratio))
    $image = New-Object System.Drawing.Bitmap($image, $newSize)
  }
  
  $image.Save($filePath)
  
  try {
    Write-Verbose "Checking cache at $CogsAccountFilePath"
    if (Test-Path $CogsAccountFilePath) {
      Write-Verbose "Retrieving cogs key from cache"
      $info = (Get-Content $cogsAccountFilePath).Split(";")
      $cogsApi = $info[0]
      $cogsKey = $info[1]
    }
    else {
      Write-Verbose "Retrieving cogs key from Azure"
      if (!$CogsResourceGroupName -or !$CogsAccountName) {
        throw New-Object Exception("Please provide CogsResourceGroup and CogsAccountName")
      }
  
      $cogsApi = (Get-AzureRmCognitiveServicesAccount -ResourceGroupName $CogsResourceGroupName -Name $CogsAccountName).Endpoint + "/ocr"
      $cogsKey = (Get-AzureRmCognitiveServicesAccountKey -ResourceGroupName $CogsResourceGroupName -Name $CogsAccountName).Key1
  
      Write-Verbose "Saving cogs account and key in cache"
      "$cogsApi;$cogsKey" > $cogsAccountFilePath
    }
  
    $response = Invoke-WebRequest $cogsApi -Headers @{"Ocp-Apim-Subscription-Key" = $cogsKey} -Method Post -ContentType "application/octet-stream" -InFile $filePath
    Write-Verbose $response
    $json = ConvertFrom-Json $response.Content
  
    Write-Verbose ($json.regions.lines.words | Out-String)  
    $finalString = $json.regions.lines.words.text -join $JoinChar
        
    if ($ToClipboard) { Set-Clipboard ($finalString) }
    Write-Host $finalString
        
  }
  finally {
    Remove-Item $filePath -ErrorAction SilentlyContinue
  }
}