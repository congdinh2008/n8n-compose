# Repository Guidelines

## Project Structure & Module Organization

This repository contains self-hosted n8n infrastructure plus importable workflow templates.

- `docker-compose.yml` runs local n8n and PostgreSQL.
- `example.env` is the safe template for local configuration; `.env` is ignored.
- `terraform/{aws,azure,gcp}/modules/n8n/` contains reusable provider modules.
- `terraform/{aws,azure,gcp}/environments/dev/` contains deployable dev environments and example tfvars files.
- `workflows/` contains n8n workflow exports grouped by `personal/`, `enterprise/`, `education/`, and reusable `common/` patterns.
- `docs/` contains implementation notes, learning material, and project summaries.

## Build, Test, and Development Commands

Use Docker Compose for local development:

```bash
cp example.env .env
docker-compose up -d
docker-compose logs -f n8n
docker-compose down
```

Run Terraform from the target environment directory:

```bash
cd terraform/aws/environments/dev
cp terraform.example.tfvars terraform.tfvars
terraform init
terraform validate
terraform plan
```

Validate workflow JSON before committing:

```bash
find workflows -name '*.json' -print0 | xargs -0 jq empty
```

## Coding Style & Naming Conventions

Use two-space indentation for JSON workflow exports and Terraform formatting for `.tf` files. Run `terraform fmt -recursive` after Terraform edits. Name workflow folders with numeric prefixes and kebab-case, for example `workflows/enterprise/14-outlook-slack-inbox/`. Prefer `workflow.json` plus `GUIDE.md` for complete workflow packages; variant exports may use descriptive suffixes such as `workflow-gemini.json`.

## Testing Guidelines

There is no centralized automated test suite. Validate changes with the smallest relevant checks: `jq empty` for workflow JSON, `terraform validate` for infrastructure, and a local n8n import/test run for changed workflows. For guide changes, verify links and example credentials or environment variables match the workflow nodes.

## Commit & Pull Request Guidelines

Recent commits use concise conventional prefixes such as `feat:`, `security:`, and `refactor:`. Keep the subject imperative and specific, for example `feat: add Slack product RAG workflow`.

Pull requests should include a short summary, changed workflow or provider paths, validation commands run, and screenshots or n8n execution notes when UI behavior changes. Link related issues when available.

## Security & Configuration Tips

Never commit `.env`, `terraform.tfvars`, state files, credentials CSVs, API keys, tokens, or exported n8n credentials. Add new required variables to `example.env` or `terraform.example.tfvars` with safe placeholder values. Keep local n8n bound to `127.0.0.1:5678` unless intentionally exposing it.
