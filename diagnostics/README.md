# diagnostics/

Troubleshooting scripts. `vici_healthcheck_v1.sh` states in its header that it is READ-ONLY and safe on live calls. `voip-diagnostic_V2.sh` makes no such statement, so read it before running it on production. Avoid running either in a tight loop.

| Script | What it does |
|---|---|
| `vici_healthcheck_v1.sh` | Idle-agent diagnostic: checks calls, agent states, campaigns, hopper, dial levels, AMI connections, SIP registry and Asterisk/VICIdial log errors, then gives a verdict on whether the issue looks server-side or client-side (lead/data). Written for ViciBox 11 / Asterisk 13 / openSUSE. Saves a report to `/tmp/vici_idle_diag_<timestamp>.txt`. |
| `voip-diagnostic_V2.sh` | VoIP diagnostic for one agent extension: separates server problems from client (agent network/phone) problems. |

## vici_healthcheck_v1.sh

```bash
sudo ./vici_healthcheck_v1.sh
```

Defaults at the top of the script: MySQL socket `/var/run/mysql/mysql.sock` as `root`, database `asterisk`, logs `/var/log/asterisk/full` and `/var/log/asterisk/messages`. Change them if your server differs.

## voip-diagnostic_V2.sh

```bash
sudo ./voip-diagnostic_V2.sh <AGENT_IP> <SIP_EXTENSION> [SIP|PJSIP]
sudo ./voip-diagnostic_V2.sh 192.168.1.50 1001 SIP
```

- The channel type defaults to `SIP`. Pass `PJSIP` if your server uses it.
- Prints pass / warn / fail lines and a summary count.
- Its own usage text calls the script `voip_diag.sh`; that is just the original name.

## Keep the output private

Reports can contain agent names, IP addresses and call data. Do not paste them into public issues or commit them (the repo's `.gitignore` excludes `*.log`).
