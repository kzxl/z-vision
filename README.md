# z-vision — Token-Diet Windows Desktop Vision & Safe Agent Arm

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Runtime](https://img.shields.io/badge/Runtime-Node.js%2022+-339933?logo=node.js)](https://nodejs.org)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11%20x64-0078D6?logo=windows)](https://learn.microsoft.com/en-us/windows/win32/winauto/entry-uiauto-win32)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-0%20npm%20%7C%20No%20.NET%20SDK-brightgreen.svg)](#zero-sdk-native-architecture)

> **Give AI coding agents crisp Windows desktop eyes and a guarded precision arm without burning vision tokens.**  
> `z-vision` pairs a token-diet **Node.js 22+ MCP server** with an on-the-fly **C# 5 native Windows host** compiled by stock `.NET Framework 4.x` `csc.exe` — zero npm packages, zero .NET SDK required, and built-in **Esc / Ctrl+Alt+F12** emergency stop.

---

## Key Capabilities

### Desktop Vision ("Eyes")
- **Compact UI Automation Tree (`zvision_observe`)**: Walks `UIAutomationClient` controls with bounded depth and returns 1-line-per-control summaries (`[0] Button "Save" aid=btnSave (420,310 80x28) [Invoke]`) — ~10–15 tokens/control.
- **64-Bit Perceptual dHash Gating (`with_image: "auto"`)**: Computes a 9x8 BT.709 grayscale difference hash on every frame. When the Hamming distance vs. the prior frame is `<= 2` and UIA nodes are present, redundant screenshots are suppressed automatically to save vision tokens.
- **Per-Monitor DPI-Aware Capture**: Captures target windows via `PrintWindow(PW_RENDERFULLCONTENT)` with `BitBlt` fallback and scales screenshot coordinates back to physical screen coordinates.
- **Native Windows WinRT OCR (`zvision_ocr`)**: Uses `Windows.Media.Ocr` directly from Windows 10/11 WinMetadata returning lines, words, and absolute screen bounding boxes (gracefully degrades if WinMetadata is absent).
- **Template Matching**: Coarse-to-fine Normalized Cross Correlation (NCC) over grayscale buffers for owner-drawn icons or custom surfaces.

### Precision Agent Arm ("Hands")
- **Physical + Semantic Actuation (`zvision_act`)**:
  - `SendInput` mouse (`click`, `double_click`, `right_click`, `move`, multi-point `drag` strokes, vertical/horizontal `scroll`) across multi-monitor virtual desktops (`MOUSEEVENTF_VIRTUALDESK`).
  - Full UTF-16 / Vietnamese diacritic typing via `KEYEVENTF_UNICODE`, STA clipboard-preserving `paste`, hotkey chords (`key`), and semantic UIA `Invoke` / `Value.SetValue` / `Toggle` / `Select` (`physical: false`).
- **Batch Plans (`zvision_plan`)**: Pre-validates and executes up to **50 sequential steps** in a single turn (`click`, `type`, `paste`, `key`, `wait_settle` via dHash stability, `wait_text`, `sleep`), stopping immediately on the first error or emergency stop.

### Safety & Control Fences
- **One-Use `observation_id` + Window Drift Guard**: Every `zvision_act` / `zvision_plan` consumes its `observation_id` once and aborts (`stale_observation`) if the window moved/resized beyond `4px` or if Stop occurred.
- **Process Tier Isolation**:
  - `blocked`: UAC / credential dialogs (`consent.exe`, `CredentialUIBroker.exe`, `LogonUI.exe`, `LockApp.exe`) block all input.
  - `click-only`: Terminals and IDEs (`WindowsTerminal`, `pwsh`, `cmd`, `Code`, `devenv`, `rider64`, `regedit`, etc.) reject typing/keystrokes unless `allow_restricted: true` is explicitly passed.
- **Sensitive Action Confirmation**: Blocks English/Vietnamese destructive labels (`delete`, `pay`, `submit`, `password`, `xóa`, `thanh toán`, `chuyển khoản`, `đăng nhập`, ...) and dangerous hotkeys (`Alt+F4`, `Win+R`, `Ctrl+Alt+Del`) unless `confirm_sensitive: true` + `reason` are supplied.
- **Hardware Emergency Stop (`zvision_stop`)**: Dedicated low-level hook (`WH_KEYBOARD_LL`) intercepts physical **`Esc`** or **`Ctrl+Alt+F12`**, latches `emergency_stopped`, and releases all held keys/mouse buttons tracked in `InputLedger`.

---

## MCP Tools (7 Focused Tools)

| Tool | Purpose |
| :--- | :--- |
| `zvision_status` | Inspect monitors/DPI, WinRT OCR availability/languages, and emergency-stop state |
| `zvision_windows` | List visible desktop windows (`hwnd`, `pid`, `process`, `title`, `bounds`) with optional filter |
| `zvision_observe` | Read compact UIA tree, 64-bit `dhash`, optional WinRT OCR, and dHash-gated screenshot; issues one-use `observation_id` |
| `zvision_act` | Execute one guarded action targeting UIA `index`, unique `automation_id`/`name`, `ocr_text`, or `[x, y]` |
| `zvision_plan` | Pre-validate and run 1..50 sequential steps (with `wait_settle` / `wait_text`) in one turn |
| `zvision_ocr` | Run WinRT OCR on a window or screen ROI `[x, y, w, h]` returning screen coordinates |
| `zvision_stop` | Latch emergency stop, reset stop state, or release all held inputs |

---

## Zero-SDK Native Architecture

1. On first run on Windows, `scripts/lib/native-builder.mjs` locates stock `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`, GAC `UIAutomation*` / `WindowsBase` assemblies, and `C:\Windows\System32\WinMetadata\Windows.*.winmd`.
2. It compiles `scripts/native/*.cs` into `~/.z-plugin/z-vision/bin/ZVisionHost-<sha256>.exe` (override with `ZVISION_DATA_DIR`).
3. If `WinMetadata` is unavailable on a machine, it automatically falls back to compiling core UIA + Capture + dHash + SendInput without WinRT OCR.
4. `scripts/lib/host-client.mjs` spawns `ZVisionHost.exe` lazily over UTF-8 newline-delimited JSON stdio and shuts it down after idle timeout.

---

## Installation

### Google Antigravity & ZCode
```powershell
git clone https://github.com/kzxl/z-vision.git
cd z-vision
powershell -ExecutionPolicy Bypass -File install.ps1
```

### Cursor / Claude Code / Any MCP Client
Add to your `.cursor/mcp.json` or `.claude_mcp.json`:
```json
{
  "mcpServers": {
    "z-vision": {
      "command": "node",
      "args": ["C:/path/to/z-vision/scripts/mcp-server.mjs"]
    }
  }
}
```

### Standalone CLI
```bash
npm run build
node scripts/cli.mjs status
node scripts/cli.mjs windows
node scripts/cli.mjs observe 0 --image
node scripts/cli.mjs ocr 0
node scripts/cli.mjs stop
```

---

## Testing

```bash
npm run check
npm test
```

Runs safety-policy unit tests, mock-transport vision-engine tests, MCP JSON-RPC stdio smoke tests, and on Windows compiles `ZVisionHost.exe` via `csc.exe` and executes read-only `status`, `windows`, `observe`, `ocr`, and `stop`/`reset` checks.

---

## License

MIT — see [LICENSE](LICENSE). Part of the [z-plugin](https://github.com/kzxl/z-plugin) ecosystem.
