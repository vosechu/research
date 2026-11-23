---
name: unity-mod-audit
description: Use when Chuck wants to know whether a Unity game mod, Steam Workshop download, or any .NET DLL is safe to run. Decompiles the assemblies with ilspycmd and flags the code that touches the network, launches programs, calls native libraries, loads code at runtime, reads or writes files, or hides data in packed blocks. Static only; it never runs the mod.
---

# Auditing Unity mods

Unity mods are .NET DLLs that run with the player's full permissions. This reads them without running them.

## Run it

    ruby ~/github/research/dotclaude/skills/unity-mod-audit/scripts/audit.rb --out DIR PATH...

- `PATH` is a mod folder (every `.dll` below it) or one `.dll`. `--out` is where the decompiled C# goes (default `./unity-audit-out`). `--max-sites N` sets how many locations show per finding (default 5).
- Needs `ilspycmd` (`dotnet tool install -g ilspycmd`; found on `PATH` or in `~/.dotnet/tools`).
- Copy the mods off the machine they were downloaded to into a **new, empty directory** first (`rsync` without the images is enough). Never run, import or open them from there.
- Workshop mods live in `~/.local/share/Steam/steamapps/workshop/content/<AppID>/`. The AppID is in `steamapps/appmanifest_*.acf`.
- `--skip-known` drops framework, Unity and Harmony DLLs by name. Use it on a game's `Managed` folder, not on mods: a malicious mod could name its DLL `System.Core.dll`.

## Read the report

SUMMARY lists each DLL worst-first. Each DLL then lists findings by category with `file:line`, and the decompiled C# is in `--out`, so open the flagged file and read the code around it.

| Category | Severity | What it means |
|---|---|---|
| `network`, `process`, `native`, `dynamic_code`, `steam_auth`, `secrets` | high | Reach out, run programs, call native code, load code, or hunt credentials. Needs a reason you can see in the code. |
| `packed`, `embedded`, `native_dll` | high | High-entropy blocks, odd PE sections, a file hidden inside the DLL, or a DLL that is not .NET. A normal mod has none. |
| `layout` | high / medium | Executable in a non-DLL file, symlink, fake image, hidden file. |
| `links`, `files`, `environment`, `encoding` | medium | Often legitimate (a button that opens the author's site, a config file, base64 for save data). Read the call site. |
| `il_patching`, `threads` | low | Harmony transpilers and background work. Normal for patch mods. |

A finding is a place to read, not a verdict. Open the file and decide whether the code does what the mod claims. Clean means none of the patterns matched, not that the mod is safe.

## Limits

- It matches patterns in decompiled C#. A mod that builds a call from pieces at runtime, or only misbehaves after a date, can slip past. Read anything that unpacks data and then loads or runs it.
- IL2CPP games (`GameAssembly.dll` and `global-metadata.dat`) have no managed code to decompile; use Il2CppDumper instead.
- Obfuscated assemblies decompile to unreadable names. Treat that as suspicious in a mod.
- Some games have their own gate (Probably Stolen lists each mod's declared capabilities and refuses to load a mod until the player approves it). Compare the manifest's declared capabilities with what the code does.

## Tests

    ruby ~/github/research/dotclaude/skills/unity-mod-audit/scripts/audit_test.rb
