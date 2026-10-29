# Beltalk_VICIdial_and_Infrastructure_Toolkit
Production-tested Bash and Node.js tooling for running large VICIdial / ViciBox fleets: diagnostics, migrations, log rotation, recording portals and security hardening.

## Contents

Each folder has its own README with usage, prerequisites and safety notes.

| Folder | Purpose |
|---|---|
| [`installer/`](installer/) | One-script ViciBox/VICIdial install from scratch (with or without WebRTC and webphone) |
| [`ssl-setup/`](ssl-setup/) | HTTPS setup and certificate renewal (bring your own certificate) |
| [`security/`](security/) | firewalld profiles and Wazuh agent install |
| [`maintenance/`](maintenance/) | Log cleanup, deep clean and scheduled cleanup |
| [`diagnostics/`](diagnostics/) | Health check and VoIP diagnostics |
| [`lead-migration/`](lead-migration/) | Lead export/import between servers and lead-group cleanup |
| [`dialer/`](dialer/) | Independent dual-session agent dialing |
| [`recording-extraction/`](recording-extraction/) | Bulk recording extraction from a VICIdial server |
| [`custom-dev/`](custom-dev/) | Custom VICIdial features (lead-list names API, realtime dial level, self-service recording portal) |

> Many of these scripts change production systems or delete data. Read the folder README, run any read-only check first, and test on a non-production server.