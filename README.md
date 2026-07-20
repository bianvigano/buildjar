# buildjar

Universal Java project builder — auto-detect Gradle/Maven, auto-detect mod loader, one command to build.

```bash
buildjar              # fat JAR
buildjar --menu       # interactive menu
buildjar --watch      # auto-rebuild
buildjar server1      # load saved preset
```

## Features

- **Auto-detect build system** — Gradle (gradlew/gradle) or Maven (mvn)
- **Auto-detect mod loader** — Fabric/Quilt → remapJar, NeoForge → build, Forge → jarJar, Paper/Spigot → shadowJar
- **12 modes**: build, scan, menu, watch, test, check-updates, version bump, push (SCP), install, presets, help/dry-run, quiet
- **Preset system** — save flags as named presets, auto-load `.buildjar` from project dir
- **Modular** — 1 entry script + 9 library modules in `/usr/local/lib/buildjar/lib/`

## Quick Install

```bash
sudo mkdir -p /usr/local/lib/buildjar/lib
sudo cp buildjar /usr/local/bin/buildjar
sudo cp lib/*.sh /usr/local/lib/buildjar/lib/
sudo chmod -R 755 /usr/local/lib/buildjar
sudo chmod +x /usr/local/bin/buildjar
```

Optional alias:
```bash
echo "alias bikinjar='buildjar'" >> ~/.bash_aliases
source ~/.bashrc
```

## Requirements

- Java JDK (javac required)
- inotify-tools (`sudo apt install inotify-tools`) — only for `--watch`
- SCP — only for `--push`

## Usage

```bash
buildjar                          # Build fat JAR
buildjar --scan                   # Analyze project
buildjar --menu                   # Interactive menu
buildjar --watch                  # Auto-rebuild on changes
buildjar --test                   # Run tests only
buildjar --check-updates          # Show outdated deps
buildjar --version patch          # Bump version
buildjar --install ~/server/plugins  # Build + copy
buildjar --push user@host:/path   # Build + SCP
buildjar --save mypreset          # Save flags as preset
buildjar mypreset                 # Load preset
buildjar --list                   # List presets
buildjar --help                   # Full help
```

## Files

```
/usr/local/bin/buildjar           # Entry script (~145 lines)
/usr/local/lib/buildjar/lib/
  utils.sh       Colors, logging
  detect.sh      Project detection, mod loader, Java version
  build.sh       Gradle/Maven build engine
  presets.sh     Save/load/list presets (~/.local/share/buildjar/)
  scan.sh        Project analysis
  version.sh     Version bump (patch/minor/major)
  watch.sh       File watch + auto-rebuild
  extra.sh       Test runner, dep check, SCP push
  menu.sh        Interactive menu, help page
```

## Presets

Save flags once, reuse:
```bash
buildjar --install ~/server/plugins --no-daemon --save server1
buildjar server1   # same as above
```

Project auto-load — create `.buildjar` in project root:
```
INSTALL_DIR=/home/me/server/plugins
CLEAN=true
```

## Examples

```bash
# Paper plugin
buildjar --install ~/server/plugins

# Fabric mod → auto remapJar
cd my-mod && buildjar -o ~/mods

# Clean CI build
buildjar --clean --no-daemon -q

# Dev loop — auto-rebuild on save
buildjar --watch --install ~/server/plugins

# Ship: bump + build + push
buildjar --version patch
buildjar server1
```

## License

MIT
