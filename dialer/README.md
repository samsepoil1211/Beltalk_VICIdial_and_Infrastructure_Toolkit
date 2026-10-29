# dialer/

## vicidial-dual-dialing.sh: independent dual dialing

Lets one agent run **two independent agent panel sessions** (two browser tabs) on a single VICIdial server. Each tab has its own dial session, dispo, lead data and pause/ready state. Built for physical SIP phones (Eyebeam, X-Lite, Zoiper or hardphones).

> **This script patches VICIdial PHP files and edits the database.** Try it on a test server first. A VICIdial upgrade overwrites the patches, so re-run the script afterwards.

| Feature | Independent per tab? |
|---|---|
| Dialing, dispo, lead data/script, pause/ready | Yes |
| Hangup | **No.** Both tabs share one physical SIP channel, so hanging up in one ends the call in both. |

### What it changes

- `vicidial.php`: 3 line patches (turns off the duplicate-login session killer and its popup).
- `vdc_db_query.php`: 1 line patch (bypasses the INCALL dial block for the `_B` session).
- Database: adds a `_B` clone of every agent in `vicidial_users`, a `_B` entry in `phones` (conference and park extensions offset by +10000) and a free conference slot in `vicidial_conferences`.
- Cron: installs `/etc/cron.d/vicidial_dual_dial` (every 5 minutes) so new agents get a `_B` account automatically.
- Backups of the patched files go to `/root/vicidial_dual_dial_backup_YYYYMMDD_HHMMSS/`.

The script auto-detects the VICIdial webroot, MySQL credentials (VICIdial defaults, then `/etc/astguiclient.conf`) and the server IP.

### Usage

```bash
sudo bash vicidial-dual-dialing.sh            # full setup
sudo bash vicidial-dual-dialing.sh --status   # show patch status (read-only)
sudo bash vicidial-dual-dialing.sh --list     # list _B users and phones (read-only)
sudo bash vicidial-dual-dialing.sh --sync     # create _B for new agents (what cron runs)
sudo bash vicidial-dual-dialing.sh --revert   # full rollback
```

Run `--status` and `--list` first. If earlier manual patches exist, run `--revert` before a fresh install.

### Agent login

| | Tab 1 | Tab 2 |
|---|---|---|
| Browser | Normal window | Incognito window |
| Username | `1001` | `1001_B` |
| Phone extension | `1001` | `1001_B` |
| Password | same as the agent's | same as the agent's |

### Rollback removes

Restored `vicidial.php` and `vdc_db_query.php`, all `_B` users and phones, the `_B` conference slots and the cron job.

### Limitations

- Hangup is shared (see above).
- WebRTC softphones are not supported (no dual registration on one extension).
- Usernames longer than 18 characters are skipped (`user` is `varchar(20)` and `_B` adds two characters).
- Webroot default is `/srv/www/htdocs/agc` on openSUSE; typically `/var/www/html/agc` on CentOS/Debian.
- Tested (per the original author) on VICIdial 2.14-725c, openSUSE Leap 15, Asterisk 16 with chan_sip.
