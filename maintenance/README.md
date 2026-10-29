# maintenance/

Log cleanup and housekeeping scripts for VICIdial servers.

| Script | What it does |
|---|---|
| `cleanup.sh` | Adds up the size of the Asterisk, astguiclient and Apache log folders and deletes common junk logs when the total exceeds a threshold (default 500 MB). |
| `deep_clean.sh` | One-shot deep clean: removes old logs, stale PHP sessions and old files in `/tmp`, then runs VICIdial's own `AST_DB_optimize.pl`. |
| `logrotate-asterisk.sh` | Self-installing cleanup: copies itself to `/root/vicibox-toolkit/cleanup-final.sh`, installs a cron job (6:00, 10:00 and 14:00 IST via `CRON_TZ=Asia/Kolkata`), then runs the cleanup once. Safe to re-run; it does not duplicate the cron entry. |

> **These scripts delete files permanently.** Run the read-only checks below first, back up logs you may need, and avoid running during busy dialing hours.

## cleanup.sh

- Folders checked: `/var/log/asterisk`, `/var/log/astguiclient` and the Apache log folder (picked from `/etc/os-release`, default `/var/log/httpd`).
- When over the threshold it deletes files matching `*.log`, `*.old`, `*.gz`, `screenlog.*`, `agiout.*`, `safe_*`, `go_*`. Actions are written to `/cleanup-logs.txt`.
- Change `THRESHOLD_MB` at the top of the script to adjust the limit.

Read-only dry run (lists what would match):

```bash
for DIR in /var/log/asterisk /var/log/astguiclient /var/log/httpd; do
  [ -d "$DIR" ] && find "$DIR" -type f \( -name "*.log" -o -name "*.old" -o -name "*.gz" -o -name "screenlog.*" -o -name "agiout.*" -o -name "safe_*" -o -name "go_*" \)
done
```

Run:

```bash
sudo ./cleanup.sh
```

## deep_clean.sh

- Deletes Asterisk `*.txt` and `*.gz` logs, plus everything in `/var/log/astguiclient`, older than 14 days.
- Deletes Apache `*.log.*` files older than 14 days under `/var/log/apache2`. **On AlmaLinux/CentOS change `apache2` to `httpd` in the script.**
- Deletes PHP session files older than 2 days and files in `/tmp` older than 5 days.
- Runs `/usr/share/astguiclient/AST_DB_optimize.pl --debug` if present.
- Warns "ensure no active calls are routing" and waits 3 seconds. Take that warning seriously.

Run:

```bash
sudo ./deep_clean.sh
```

## logrotate-asterisk.sh

- Needs root. Installs itself and a cron entry marked `# vicidial-cleanup-auto`.
- Check what it installed:
  ```bash
  crontab -l | grep -B1 vicidial-cleanup-auto
  ls -l /root/vicibox-toolkit/
  ```
- To remove it, delete that cron line and the `/root/vicibox-toolkit/` folder.

## Verify after any run

```bash
df -h /
du -sh /var/log/asterisk /var/log/astguiclient
```
