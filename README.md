# DevOps Assessment: Terraform + Database Reliability

## 1. Overview

This repository contains:

- **Terraform** for an `Internet → ALB → ECS/Fargate → RDS` architecture on AWS, with `dev` and `prod` environments.
- A **local PostgreSQL environment** (Docker Compose) with migrations, seed data, and an optimized reporting query.
- **Backup and restore scripts** built on Postgres' native `pg_dump` / `pg_restore` tooling.

Actual AWS deployment is out of scope. The Terraform code is written to be realistic and production-oriented, but is validated locally with `fmt` / `init` / `validate` / `plan -refresh=false` rather than deployed.

```
Internet
   │
   ▼
  ALB  (public subnets)
   │
   ▼
ECS/Fargate service  (private subnets)
   │
   ▼
  RDS  (private subnets, only reachable from ECS)
```

## 2. Prerequisites

| Tool | Version | Needed for |
|---|---|---|
| Terraform | >= 1.6 | `terraform/` |
| Docker | recent | `docker-compose.yml` |
| Docker Compose | v2 (the `docker compose` subcommand) | local database |
| Git | any recent | cloning/submitting |
| `psql` client (optional) | any recent | manual DB inspection outside the container |

No AWS account or credentials are required to run the review commands below — the AWS provider only needs to be *configured*, not authenticated, for `plan -refresh=false` against a local backend with no prior state.

## 3. Repository Structure

```
.
├── terraform/
│   ├── modules/
│   │   ├── network/     # VPC, subnets, IGW/NAT, security groups
│   │   ├── ecs/         # ALB, ECS cluster/service/task, IAM, logs
│   │   └── rds/         # RDS instance + subnet group
│   └── envs/
│       ├── dev/         # dev-sized config, local backend
│       └── prod/        # prod-sized config, local backend
├── docker-compose.yml   # local Postgres
├── migrations/          # ordered schema migrations
│   ├── 001_create_hotel_bookings.sql
│   ├── 002_create_booking_events.sql
│   └── 003_add_indexes.sql
├── seed/
│   └── seed.sql          # 150 bookings + related events
├── scripts/
│   ├── init-db.sh        # runs migrations + seed on first container start
│   ├── backup.sh          # pg_dump-based backup
│   └── restore.sh         # pg_restore-based restore + verification
├── .github/workflows/terraform.yml   # optional PR plan workflow (Part 3)
├── .env.example
├── .gitignore
└── README.md
```

## 4. Terraform Setup

All Terraform commands are run **from inside an environment directory**, not from `terraform/` itself — `envs/dev` and `envs/prod` are the Terraform root modules; `modules/` is only referenced via `source = "../../modules/..."`.

```bash
cd terraform/envs/dev      # or terraform/envs/prod

terraform fmt
terraform init
terraform validate
terraform plan -refresh=false -var="db_password=local-test-password"
```

Notes:

- Both environments use a **local backend** (`backend "local"`) on purpose, so `terraform init` works without a pre-existing S3 bucket / DynamoDB table. `backend.tf` in each environment explains this, and `backend.tf.example-s3` shows the real backend you'd switch to before an actual deployment.
- `db_password` has no default in `prod` (and only a placeholder default in `dev`) so a real secret is never accidentally committed — pass it with `-var`, `TF_VAR_db_password`, or a `.tfvars` file that is gitignored.
- `plan -refresh=false` produces a plan to **create** all resources, since there is no prior state — that's expected for a from-scratch review.

## 5. Dev Environment

```bash
cd terraform/envs/dev
terraform init
terraform validate
terraform plan -refresh=false -var="db_password=local-test-password"
```

Dev is sized to be cheap and disposable:

- `db.t4g.micro`, 20 GB storage, single-AZ
- 1-day backup retention
- `deletion_protection = false`
- 1 ECS task, 256 CPU / 512 MB

## 6. Prod Environment

```bash
cd terraform/envs/prod
terraform init
terraform validate
terraform plan -refresh=false -var="db_password=some-strong-secret"
```

Prod is sized for real traffic and protected against accidental loss:

- `db.t4g.medium`, 100 GB storage, **Multi-AZ**
- **30-day** backup retention
- `deletion_protection = true`
- 2 ECS tasks, 512 CPU / 1024 MB
- Separate VPC CIDR (`10.1.0.0/16`) from dev (`10.0.0.0/16`) so the two never overlap if ever peered

| Setting | dev | prod |
|---|---|---|
| RDS instance class | db.t4g.micro | db.t4g.medium |
| RDS storage | 20 GB | 100 GB |
| Multi-AZ | no | yes |
| Backup retention | 1 day | 30 days |
| Deletion protection | false | true |
| ECS desired count | 1 | 2 |
| ECS task size | 256/512 | 512/1024 |

## 7. Database Setup

```bash
docker compose up -d
```

This starts a single Postgres 16 container. On the **first** run (empty volume), Postgres automatically executes `scripts/init-db.sh`, which applies every file in `migrations/` and then every file in `seed/`, in filename order.

Verify the database is healthy and reachable:

```bash
docker compose ps                       # STATUS should show "healthy"
docker exec -it hotelbooking-db psql -U app_admin -d hotelbooking -c '\dt'
```

You should see `hotel_bookings` and `booking_events` listed.

## 8. Migrations

Migrations live in `migrations/`, numbered so they always apply in a deterministic order:

- `001_create_hotel_bookings.sql` — core booking table
- `002_create_booking_events.sql` — event log, FK to `hotel_bookings`
- `003_add_indexes.sql` — the reporting index described below

They run automatically via `scripts/init-db.sh` the first time the container starts. To re-apply them against a running container manually (e.g. after editing a migration during development):

```bash
docker exec -i hotelbooking-db psql -U app_admin -d hotelbooking -f - < migrations/001_create_hotel_bookings.sql
```

Verify the schema:

```bash
docker exec -it hotelbooking-db psql -U app_admin -d hotelbooking -c '\d hotel_bookings'
docker exec -it hotelbooking-db psql -U app_admin -d hotelbooking -c '\d booking_events'
```

## 9. Seed Data

`seed/seed.sql` inserts 150 hotel bookings spread across 4 cities (`delhi`, `mumbai`, `bengaluru`, `chennai`), 4 organizations, and 4 statuses (`confirmed`, `cancelled`, `completed`, `pending`), with `created_at` spread over the last 60 days — so the assessment's "last 30 days" query has both matching and non-matching rows. It also inserts `booking_events` for a subset of bookings.

Verify:

```bash
docker exec -it hotelbooking-db psql -U app_admin -d hotelbooking -c \
  "SELECT COUNT(*) FROM hotel_bookings; SELECT COUNT(*) FROM booking_events;"
```

### Query optimization

The target query:

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

Without an index, this is a full sequential scan of `hotel_bookings` for every request. `003_add_indexes.sql` adds:

```sql
CREATE INDEX idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);
```

Why this index:

- `city` is an equality filter and `created_at` is a range filter, so putting `(city, created_at)` in that order as the index key lets Postgres do a single **index range scan** instead of scanning the whole table.
- `org_id`, `status`, and `amount` are added as `INCLUDE` columns rather than part of the search key. They're not used for filtering or ordering, but the query needs them for the `GROUP BY` / aggregation — including them lets Postgres answer the query as an **index-only scan** (no trip back to the heap for matching rows, once the visibility map is up to date).
- A composite index rather than two separate single-column indexes, because Postgres can only efficiently combine separate indexes with a bitmap AND, which is generally slower here than one index that already satisfies both predicates directly.

Check the plan yourself:

```bash
docker exec -it hotelbooking-db psql -U app_admin -d hotelbooking -c "
EXPLAIN ANALYZE
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;"
```

You should see `Index Only Scan using idx_hotel_bookings_city_created_at` (or a regular `Index Scan` if the visibility map isn't fully set yet) instead of `Seq Scan`.

## 10. Backup

```bash
./scripts/backup.sh
```

- **What's backed up:** the `hotelbooking` database in the running `hotelbooking-db` container.
- **Format:** `pg_dump --format=custom` — a compressed, non-plain-text dump that supports `pg_restore` (including parallel and selective-table restores), unlike plain SQL dumps.
- **Where:** `backups/hotelbooking_<YYYYmmdd_HHMMSS>.dump` (this directory is gitignored — dumps are never committed).
- **Verify the backup itself** (without restoring) by listing its contents:

```bash
docker exec -i hotelbooking-db pg_restore --list < backups/hotelbooking_<timestamp>.dump
```

The script checks that Docker is available, the container is running, and that the resulting file is non-empty, and it removes any partial file if `pg_dump` fails.

## 11. Restore

```bash
./scripts/restore.sh                       # restores the most recent backup
./scripts/restore.sh backups/some.dump      # restores a specific file
```

The restore does **not** overwrite the live `hotelbooking` database. Instead it:

1. Drops and recreates a separate `hotelbooking_restore` database on the same container.
2. Runs `pg_restore` into that fresh database.
3. Runs `SELECT COUNT(*)` against `hotel_bookings` and `booking_events` in the restored database and prints the counts, failing loudly if `hotel_bookings` comes back empty.

**Verify the restore worked** by comparing row counts between the live and restored databases:

```bash
docker exec -i hotelbooking-db psql -U app_admin -d hotelbooking         -c "SELECT COUNT(*) FROM hotel_bookings;"
docker exec -i hotelbooking-db psql -U app_admin -d hotelbooking_restore -c "SELECT COUNT(*) FROM hotel_bookings;"
```

Both counts should match.

## 12. Troubleshooting

| Problem | Likely cause / fix |
|---|---|
| Docker container not starting | Run `docker compose logs db` to see the actual Postgres error. Often a stale volume from an old, incompatible Postgres version — remove it with `docker compose down -v` and retry. |
| Port already in use | Something else is using 5432. Set `POSTGRES_PORT=5433` in `.env` (copy from `.env.example`) and re-run `docker compose up -d`. |
| Database not ready / connection refused | Wait for `docker compose ps` to show `healthy`, or check `docker compose logs db` for startup errors. |
| Terraform provider initialization failure | Usually a network/proxy issue reaching the Terraform provider registry. Confirm outbound HTTPS access, or configure a local provider mirror. |
| Terraform validation failure | Run `terraform fmt` first (a formatting issue often masks the real error), then re-run `terraform validate` and read the resource/line it points to. |
| Backup failure | Confirm the container is running (`docker compose ps`) and that `POSTGRES_USER`/`POSTGRES_DB` match your `.env`, then re-run `./scripts/backup.sh`. |
| Restore failure | Confirm a `.dump` file exists in `backups/`. If `pg_restore` reports version mismatches, make sure you're restoring into the same major Postgres version the dump was taken from (16). |
| Permission problems with shell scripts | Run `chmod +x scripts/*.sh` — they're committed as executable, but Git can lose that bit depending on how the repo was transferred. |

## 13. Verification Checklist

**Terraform:**

- [ ] `cd terraform/envs/dev && terraform fmt && terraform init && terraform validate && terraform plan -refresh=false -var="db_password=x"` succeeds
- [ ] `cd terraform/envs/prod && terraform fmt && terraform init && terraform validate && terraform plan -refresh=false -var="db_password=x"` succeeds
- [ ] Plan shows RDS with no public access, only reachable from the ECS security group
- [ ] dev vs prod differences (sizing, retention, deletion protection) are visible in `terraform.tfvars`

**Database:**

- [ ] `docker compose up -d` starts a healthy Postgres container
- [ ] `hotel_bookings` and `booking_events` tables exist with the expected columns
- [ ] `SELECT COUNT(*) FROM hotel_bookings;` returns ≥ 100 rows across multiple cities/orgs/statuses
- [ ] `EXPLAIN ANALYZE` on the target query shows an index scan, not a sequential scan
- [ ] `./scripts/backup.sh` produces a non-empty `.dump` file in `backups/`
- [ ] `./scripts/restore.sh` restores into `hotelbooking_restore` and row counts match the live database
- [ ] No secrets or real backups are committed to Git
