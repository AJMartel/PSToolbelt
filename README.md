# PSToolbelt
A toolbelt of useful Powershell functions in module form

For those on Windows, I wrote a handy Powershell function to use it as a hex editor. Confirmed working on Sublime Text 3, should work with any version of it as well. Total time to patch the EXE is about 5 seconds in all.

Here's how to use:

1. Open a Powershell console (Administrator level to avoid errors, although this worked fine for me in normal)
2. Run the following command to load the function from my GitHub (feel free to go the URL to investigate the function itself):

```powershell
Invoke-Expression (New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/nferrell/PSToolbelt/master/Public/Edit-FileHex.ps1")
```

1. Run the following command to "register" Sublime Text 3 (I'm using build 3126 on Win x64 as an example):

```powershell
Edit-FileHex -FilePath "C:\Program Files\Sublime Text 3\sublime_text.exe" -Offset 0xFC53B -Original 94 -Updated 95 -OverwriteOriginal
```

If you would like to test this out first, you can remove the `-OverwriteOriginal` switch from the command. This will create an edited clone titled **sublime_text (Hexed).exe** in the same folder as the original.
