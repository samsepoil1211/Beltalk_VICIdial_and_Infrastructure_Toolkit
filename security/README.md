# security/

Firewall and host-security helpers for ViciBox servers.

| Script | What it does |
|---|---|
| `Firewalld-template.sh` | Interactive firewalld setup with three profiles: VICIdial 8 (no WebRTC), VICIdial 11 (WebRTC), General Purpose. Optionally adds custom ports. |
| `wazuh-agent.sh` | Installs a Wazuh agent RPM (openSUSE by default), points it at your Wazuh manager, adds a `/var/log/messages` log source and an active-response script. |

> Both scripts change the system and need root. Test on a staging server first and take a backup.

## Firewalld-template.sh

- Detects the OS from `/etc/os-release` and installs firewalld with the matching package manager (openSUSE/SLES, AlmaLinux/CentOS/RHEL, Debian/Ubuntu).
- Enables and starts firewalld, applies the chosen profile, then reloads.

Port lists in the script:

| Profile | Ports |
|---|---|
| VICIdial 8 | 22, 80, 443, 3306, 5060, 5061, 5038, 10000-20000 |
| VICIdial 11 (WebRTC) | 22, 80, 443, 3306, 5060, 5061, 8088, 8089, 10000-20000 |
| General Purpose | 22, 80, 443 |

Run:

```bash
sudo ./Firewalld-template.sh
```

**Review before use**
- The script adds every port as **TCP**. RTP (10000-20000) is normally **UDP**, and SIP is often UDP as well. Add the UDP range yourself if needed (VERIFY BEFORE USE against your carrier and phone setup):
  ```bash
  sudo firewall-cmd --permanent --add-port=10000-20000/udp
  sudo firewall-cmd --reload
  ```
- Ports 3306 (MariaDB) and 5038 (AMI) should not be open to the internet. Restrict them to trusted addresses with firewalld rich rules or zones.

Read-only checks:

```bash
firewall-cmd --list-all
systemctl status firewalld
```

## wazuh-agent.sh

- Requires the manager address in the `MANAGER_IP` environment variable. The script stops with an error if it is not set (there is no built-in default).
- Imports the Wazuh GPG key and installs the RPM (the script pins an example version, 4.4.5; update the URL to a current release).
- Writes the manager address into `/var/ossec/etc/ossec.conf`, appends a localfile for `/var/log/messages`, creates `/var/ossec/active-response/bin/firewall-drop.sh` (iptables based) and enables the `wazuh-agent` service.

Run:

```bash
sudo MANAGER_IP=<MANAGER_IP> ./wazuh-agent.sh
```

Verify:

```bash
systemctl status wazuh-agent
tail -n 100 /var/ossec/logs/ossec.log
```

**Review before use**
- It edits `ossec.conf`. If you already have a configuration, check the result for valid XML.
- The active-response script uses iptables, which can conflict with firewalld on some systems.
- RPM only. Debian/Ubuntu need the `.deb` flow (not included).
