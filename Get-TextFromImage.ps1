function Get-ImageTextFromClipboard (
  $JoinChar = " "
  ){

  $cogsResourceGroupName = "sacagov-intel"
  $cogsName = "sacaintel-cv"
  $cogsAccountFilePath = "C:\temp\cogs.cvs"

  $ErrorActionPreference = "Stop"

  $dateString = (Get-Date).ToString("yyyymmdd-HHMMss")
  $filePath = "C:\temp\$dateString.png"
  $image = Get-Clipboard -Format Image

  if (!$image) {
      throw New-Object Exception("No image available in clipboard.")
  }

  if ($image.Width -lt 50) {
      "Resizing width"
      $ratio = 50.0 / $image.Width
      $newSize = New-Object System.Drawing.Size(($image.Width * $ratio), ($image.Height * $ratio))
      $image = New-Object System.Drawing.Bitmap($image, $newSize)
  }
  if ($image.Height -lt 50) {
      "Resizing height"
      $ratio = 50.0 / $image.Height
      $newSize = New-Object System.Drawing.Size(($image.Width * $ratio), ($image.Height * $ratio))
      $image = New-Object System.Drawing.Bitmap($image, $newSize)
  }

  $image.Save($filePath)

  try {
      if (Test-Path $cogsAccountFilePath) {
          "Retrieving Cogs Key from cache"
          $info = (Get-Content $cogsAccountFilePath).Split(";")
          $cogsApi = $info[0]
          $cogsKey = $info[1]
      }

      else {
          "Retrieving Cogs Key from Azure"
          $cogsApi = (Get-AzureRmCognitiveServicesAccount -ResourceGroupName $cogsResourceGroupName -Name $cogsName).Endpoint + "/ocr"
          $cogsKey = (Get-AzureRmCognitiveServicesAccountKey -ResourceGroupName $cogsResourceGroupName -Name $cogsName).Key1

          "$cogsApi;$cogsKey" > $cogsAccountFilePath
      }

      $response = Invoke-WebRequest $cogsApi -Headers @{"Ocp-Apim-Subscription-Key"=$cogsKey} -Method Post -ContentType "application/octet-stream" -InFile $filePath
      $response
      $json = ConvertFrom-Json $response.Content

      $json.regions.lines.words
  
      $finalString = $json.regions.lines.words.text -join $JoinChar
      Set-Clipboard ($finalString)

      $finalString
  } finally {
      Remove-Item $filePath -ErrorAction SilentlyContinue
  }
}