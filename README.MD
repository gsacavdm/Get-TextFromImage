﻿# Get-TextFromImage

This PowerShell commandlet leverages Azure Cognitive Services, specifically the Computer Vision API, to perform optical character recognition on an image on disk or on your clipboard.

**WARNING** This commandlet persists your Cognitive Services Account Name and Key on disk for convenience.

Personally, I use this the most when dealing with applications that don't let me copy text. I can take screenshot of the chunk of text (made easier with Windows + S from OneNote), run the command and TA-DA, I have the text in my clipboard for easy use.

```PowerShell
Get-TextFromImage -FromClipboard -ToClipboard
```

![Get-TextFromImage Demo](demo.gif "Demo")

