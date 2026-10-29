# ssl-setup/

Scripts to enable HTTPS on a ViciBox (openSUSE, ViciBox 11+) server and to renew the certificate later.

> **No certificate or private key is included in this repository, and none should ever be committed.** You supply your own files. The repo's `.gitignore` blocks `*.key` and `*.pem`.

| Script | What it does |
|---|---|
| `setup.sh` | Interactive first-time setup. Asks for the domain and the dialer's public IP, then updates `/etc/hosts`, `/etc/hostname`, Apache `default-server.conf` (with an HTTP to HTTPS redirect), all vhosts in `/etc/apache2/vhosts.d/`, `ssl-global.conf` and Asterisk `http.conf`. Restarts the web servers and asks before rebooting. |
| `update-ssl-V2.sh` | Certificate renewal. Backs up the current cert and key as `.bkp`, copies the new ones in, reloads Apache and the Asterisk `http` module. |

> Both scripts edit system configuration and need root. Back up `/etc/apache2`, `/etc/hosts` and `/etc/asterisk/http.conf` first, and try a test server before production.

## Before you run: set the file names

The scripts have certificate names written into them. Edit these lines for your own domain and files:

- `setup.sh` lines 10-11: `SSL_CRT` (currently `/etc/apache2/ssl.crt/fullchain.crt`) and `SSL_KEY` (currently a `*.beltalk.live` key name). The script exits if either file is missing or empty.
- `update-ssl-V2.sh` lines 4-9: `SOURCE_DIR`, `CRT_FILE` and `KEY_FILE`. By default it looks for the new files in `/root/Vicidial11-auto-setup-ssl/Updated-ssl-2026`. Create that folder, or change `SOURCE_DIR`, and place your new certificate and key there.

Known mismatches to watch for:
- `setup.sh` expects `fullchain.crt`, while `update-ssl-V2.sh` expects a different file name. Use one naming scheme for your server.
- `update-ssl-V2.sh` runs `systemctl reload httpd && systemctl reload apache2`. On a server that has only one of these services the first reload fails and the second never runs (VERIFY BEFORE USE on your OS).

## First-time setup

1. Copy your certificate to `/etc/apache2/ssl.crt/` and your private key to `/etc/apache2/ssl.key/` (the key file should be readable only by root).
2. Edit `SSL_CRT` and `SSL_KEY` in `setup.sh` to match.
3. Run:
   ```bash
   chmod +x setup.sh
   sudo ./setup.sh
   ```
4. Enter the domain (for example `dialer.<YOUR_DOMAIN>`) and the dialer's public IP when asked.

## Renewal

1. Put the new certificate and key in the `SOURCE_DIR` folder, with the names set in the script.
2. Run:
   ```bash
   sudo ./update-ssl-V2.sh
   ```
3. Verify:
   ```bash
   openssl x509 -in /etc/apache2/ssl.crt/<CERT_FILE> -noout -subject -dates
   ```

## Security note

Never publish a private key. If a key was ever committed to a public repository, treat it as compromised: have the certificate re-issued and the old one revoked. Removing the file later does not remove it from git history.
