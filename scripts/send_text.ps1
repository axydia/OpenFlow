param(
  [Parameter(Mandatory = $true)]
  [string]$EncodedText,
  [string]$WindowHandle = "0"
)

try {
  $Text = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedText))
} catch {
  throw "Failed to decode UTF-8 text for sending."
}

if ([string]::IsNullOrEmpty($Text)) {
  exit 0
}

Add-Type -AssemblyName System.Windows.Forms

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinApi {
  public const uint WM_PASTE = 0x0302;
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string cls, string wnd);
  [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr w, IntPtr l);
}
"@

$hwnd = [long]0
[long]::TryParse($WindowHandle, [ref]$hwnd) | Out-Null
$targetWindow = if ($hwnd -gt 0) { [IntPtr]::new($hwnd) } else { [WinApi]::GetForegroundWindow() }

# Set clipboard — intentionally not restored so text stays available for manual Ctrl+V
[System.Windows.Forms.Clipboard]::SetText($Text)
Start-Sleep -Milliseconds 120

if ([WinApi]::IsWindow($targetWindow)) {
  $scintilla = [WinApi]::FindWindowEx($targetWindow, [IntPtr]::Zero, "Scintilla", $null)

  if ($scintilla -ne [IntPtr]::Zero) {
    # Notepad++ / Scintilla: WM_PASTE direct, no focus required
    [WinApi]::SendMessage($scintilla, [WinApi]::WM_PASTE, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
  } else {
    # Standard apps: bring to front then paste
    [WinApi]::SetForegroundWindow($targetWindow) | Out-Null
    Start-Sleep -Milliseconds 80
    [System.Windows.Forms.SendKeys]::SendWait('^v')
  }
}

[Console]::Out.WriteLine('__OPENFLOW_PASTE_OK__')
