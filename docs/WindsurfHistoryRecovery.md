# Recovering lost Dart screens from Windsurf history

This project sometimes needs to recover deleted Flutter screens (e.g. `reading_tab_page.dart`) from the Windsurf editor history.

This folder on Windows usually contains that history:

```text
C:\Users\<username>\AppData\Roaming\Windsurf\User\History
```

## PowerShell helper script

Use the `tools/windsurf_history_recovery.ps1` script to search history directories for Dart files that *mention* a target file name in their contents.

Example usage (from a normal PowerShell window):

```powershell
cd C:\Users\jessi\Downloads\QuizVocab2

# Adjust the HistoryRoot to your actual Windows username/path
$historyRoot = "C:\Users\jessi\AppData\Roaming\Windsurf\User\History"

# Look for any Dart files in history whose contents mention 'reading_tab_page.dart'
.\tools\windsurf_history_recovery.ps1 -HistoryRoot $historyRoot -TargetFileName "reading_tab_page.dart"
```

The script will:

- Walk every subfolder under the history root (most recent first).
- Find all `*.dart` files.
- Read their contents and check if they contain the string given by `-TargetFileName`.
- Print a small table with:
  - `DartPath`      – full path to the Dart file in history.
  - `DartModified`  – last modification time.
  - `HistoryFolder` – the history directory that contained it.

Take the **most recent** candidate (first rows) as the likely latest version.

## Restoring a file into this project

1. Run the script as above.
2. Identify the best `DartPath` candidate.
3. Either:
   - Open that path in Windsurf/VSCode and copy its contents into the corresponding `lib/screens/...` file in this project, or
   - Paste the **full path** or file contents into a chat with the AI assistant and ask it to restore that file here.

This is the standard procedure to recover lost screens such as:

- `lib/screens/reading_tab_page.dart`
- `lib/screens/listening_tab_page.dart`
- Any other Dart screen that was edited in Windsurf but removed in the Git workspace.
