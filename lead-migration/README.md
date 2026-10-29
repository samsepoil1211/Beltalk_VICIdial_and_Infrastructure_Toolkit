# lead-migration/

Scripts for moving VICIdial leads between servers, plus a lead-group cleanup tool.

| Script | Where to run | What it does |
|---|---|---|
| `vici_lead_export.sh` | **Source** server | Exports all lead lists and leads into a package folder (`vicidial_lists.sql` + `vicidial_list.sql`). Described in its header as read-only: no deletes, no changes, safe on a live server. |
| `vici_lead_import.sh` | **Destination** server | Imports an export package. Supports `--dry-run`, an optional target campaign, and writes a rollback SQL file. |
| `lead-exporter.sh` | Any VICIdial server | Interactive lead-group manager. Shows lead groups and counts, can export to CSV, and can **permanently delete** every lead group except the protected ones. |

## Typical migration

1. On the source server (read-only):
   ```bash
   ./vici_lead_export.sh                      # writes to /tmp/vici_export_<timestamp>
   ./vici_lead_export.sh --outdir /mnt/backup # choose another folder
   ```
   Other option: `--socket <path>` (default `/var/run/mysql/mysql.sock`).
2. Copy the export folder to the destination server (for example with `rsync` or `scp`).
3. On the destination, do a dry run first:
   ```bash
   ./vici_lead_import.sh --package /tmp/vici_export_<timestamp> --dry-run
   ```
4. Run the real import:
   ```bash
   ./vici_lead_import.sh --package /tmp/vici_export_<timestamp>
   ./vici_lead_import.sh --package /tmp/vici_export_<timestamp> --campaign <CAMPAIGN_ID>
   ```
   A rollback file is written to `/tmp/vici_import_rollback_<timestamp>.sql`. Keep it until you have verified the import.
5. Verify lead counts per list on both servers before cleaning up the source.

Defaults to review at the top of each script: database `asterisk`, socket `/var/run/mysql/mysql.sock`, database user (`root` for export, `cron` for import).

**Do not commit export packages.** They contain customer data (the repo's `.gitignore` excludes `*.sql`).

## lead-exporter.sh: destructive

- Menu has three choices at the `Enter your choice [1/2/3]` prompt; the delete paths ask you to type `YES` before anything is removed.
- The delete paths remove rows from `vicidial_list` and `vicidial_lists` for every list **not** in `PROTECTED_GROUPS` (set in the script, default `998,999,1001`), and clean orphaned `vicidial_amd_log` rows.
- One path deletes **without** exporting first. Always export or back up the database before using any delete option.
- Set `DB_USER`, `DB_PASS` and `DB_NAME` at the top of the script for your server. Do not commit real credentials back to this repo.

Read-only check of list sizes before any run (VERIFY BEFORE USE on your schema):

```bash
mysql -u <DB_USER> -p asterisk -e "SELECT list_id, COUNT(*) FROM vicidial_list GROUP BY list_id;"
```
