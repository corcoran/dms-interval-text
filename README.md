# Interval Text

A [DankMaterialShell](https://danklinux.com) bar widget that displays custom command output on a configurable interval.

Run any shell command and show the result in your bar with a [Material Design icon](https://fonts.google.com/icons).

## Install

```sh
# Clone into your DMS plugins directory
git clone https://github.com/corcoran/dms-interval-text ~/.config/DankMaterialShell/plugins/IntervalText

# Reload
dms ipc call plugins reload intervalTextPlugin
```

Or symlink during development:

```sh
ln -sf ~/path/to/dms-interval-text ~/.config/DankMaterialShell/plugins/IntervalText
```

## Settings

| Setting | Description | Default |
|---------|-------------|---------|
| **Command** | Shell command to run | *(empty — shows "Configure me")* |
| **Icon** | Material Design icon name | `info` |
| **Refresh Interval** | Seconds between runs (1–300) | `10` |
| **Click Command** | Command to run when widget is clicked | *(empty)* |
| **Popout Enabled** | Show click command output in a popout panel | `false` |
| **Popout Refresh Interval** | Seconds between popout refreshes (1–300) | `5` |
| **Popout Width** | Width of the popout panel in pixels (200–1920) | `600` |
| **Popout Max Height** | Maximum height of the popout panel in pixels (100–1080) | `450` |

Bar display shows the first line of command output, truncated to 30 characters. Popout settings are hidden until **Popout Enabled** is checked. ANSI escape codes are automatically stripped from popout output.

## Examples

**Uptime** (using the included helper script):

- Command: `~/.config/DankMaterialShell/plugins/IntervalText/uptime-compact.sh`
- Icon: `schedule`

**Memory usage:**

- Command: `free -h | awk '/Mem:/{print $3}'`
- Icon: `memory`

**Hostname:**

- Command: `hostname`
- Icon: `computer`
- Refresh Interval: `300`

**Uptime records popout:**

- Command: `~/.config/DankMaterialShell/plugins/IntervalText/uptime-compact.sh`
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
