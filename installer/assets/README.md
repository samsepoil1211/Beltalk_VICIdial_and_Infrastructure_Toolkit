# installer/assets/

Config files that `install-vicidial.sh` copies onto the server. They come from the `Vicidial-scratch-install` helper repo, which the installer otherwise clones at run time (`REPO_URL`, step 03). They are kept here so you can review and version them with the installer.

| File | Used for | Where the installer puts it |
|---|---|---|
| `extensions.conf` | Asterisk dialplan | `/etc/asterisk/extensions.conf` |
| `confbridge-vicidial.conf` | ConfBridge profiles | `/etc/asterisk/` |
| `asterisk-sip.conf` | SIP settings (`DOMAINNAME` is replaced with your SSL domain) | `/etc/asterisk/sip.conf` (SSL step; VERIFY the exact condition in the script) |
| `viciportal-ssl.conf` | Apache SSL vhost (`DOMAINNAME` is replaced) | `/etc/httpd/conf.d/viciportal-ssl.conf` |
| `cpanfile` | Perl module list | installed with `cpm` from the helper checkout |

Notes:
- The installer still clones the helper repo at run time. Editing files here does **not** change what an installation uses unless you also point `REPO_URL` (or the script) at a copy of this folder. VERIFY BEFORE USE.
- The trunk lines in `extensions.conf` (for example `PASSWORD@sip.provider.net`, `10.10.10.16`) are VICIdial sample placeholders. Replace them with your real carrier details on the server, never in this repo.
- The remaining legacy installers in the helper repo (Alma/Rocky/Debian/CentOS scripts) are not copied.