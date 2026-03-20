# Interval Command

A [DankMaterialShell](https://danklinux.com) bar widget that runs commands at configurable intervals and displays their output.

Run any shell command and show the result in your bar with a [Material Design icon](https://fonts.google.com/icons). Add as many widgets as you want — each one has its own command, icon, interval, and popout settings.

## Install

```sh
# Clone into your DMS plugins directory
git clone https://github.com/corcoran/dms-interval-command ~/.config/DankMaterialShell/plugins/intervalCommand

# Reload
dms ipc call plugins reload intervalCommandPlugin
```

Or symlink during development:

```sh
ln -sf ~/path/to/dms-interval-command ~/.config/DankMaterialShell/plugins/intervalCommand
```

## Settings

![Settings](screenshots/settings.jpg)

Click **Add Widget** to create a new widget. Each widget appears in the bar as a separate instance with its own settings:

| Setting | Description | Default |
|---------|-------------|---------|
| **Name** | Display name (shown in DMS "Add Widget" menu) | `Widget 1` |
| **Command** | Shell command to run | *(empty)* |
| **Icon** | Material Design icon name | `info` |
| **Refresh Interval** | Seconds between runs (1–300) | `10` |
| **Click Command** | Command to run when widget is clicked | *(empty)* |
| **Popout Enabled** | Show click command output in a popout panel | `false` |
| **Popout Refresh Interval** | Seconds between popout refreshes (1–300) | `5` |
| **Popout Width** | Width of the popout panel in pixels (200–1920) | `600` |
| **Popout Max Height** | Maximum height of the popout panel in pixels (100–1080) | `450` |

Bar display shows the first line of command output, truncated to 50 characters. Popout settings are hidden until **Popout Enabled** is checked. ANSI escape codes are automatically stripped from popout output.

## Examples

**Uptime** (using the included helper script):

- Command: `~/.config/DankMaterialShell/plugins/intervalCommand/uptime-compact.sh`
- Icon: `schedule`

**Memory usage:**

- Command: `free -h | awk '/Mem:/{print $3"/"$2}'`
- Icon: `memory`

**Arch updates** (gettin' fancy 😉):

- Command: `n=$(checkupdates 2>/dev/null | wc -l); [ "$n" -eq 0 ] && echo "up to date" || echo "$n update$([ "$n" -ne 1 ] && echo s)"`
- Icon: `system_update`
- Refresh Interval: `300`
- Click Command: `checkupdates`
- Popout Enabled: checked
- Popout Refresh Interval: `300`

**VPN status:**

- Command: `ip link show tun0 >/dev/null 2>&1 && echo "VPN Up" || echo "VPN Down"`
- Icon: `vpn_lock`
- Refresh Interval: `30`

**Public IP:**

- Command: `curl -s ifconfig.me`
- Icon: `language`
- Refresh Interval: `300`

**Uptime records popout:**

![Click command popout](screenshots/onclick.jpg)

- Command: `~/.config/DankMaterialShell/plugins/intervalCommand/uptime-compact.sh`
- Icon: `schedule`
- Click Command: `uprecords -s`
- Popout Enabled: checked
- Popout Refresh Interval: `60`

## uptime-compact.sh

Included helper script that shows uptime in a compact, readable format with smart precision — only displays the most relevant time units.

```
$ ./uptime-compact.sh
3d 7h

$ ./uptime-compact.sh --minutes
3d 7h 46m

$ ./uptime-compact.sh --seconds
3d 7h 46m 41s

$ ./uptime-compact.sh --help
Usage: uptime-compact.sh [OPTIONS]

Display system uptime in a compact, readable format.
Shows the two most relevant time units by default.

Options:
  --minutes   Always include minutes
  --seconds   Always include minutes and seconds
  --help, -h  Show this help message
```

The display adapts to the uptime duration:

| Uptime | Output |
|--------|--------|
| 2 months | `2mo 1w 3d 6h` |
| 2 weeks | `2w 1d 14h` |
| 3 days | `3d 7h` |
| 5 hours | `5h 23m` |
| 12 minutes | `12m 45s` |

## License

MIT
