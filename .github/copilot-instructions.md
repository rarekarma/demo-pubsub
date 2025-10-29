<!-- Generated/updated by AI assistant on 2025-10-17 -->

# AI coding agent instructions for synckarma103

Purpose: give an AI coding agent concise, actionable context so it can make safe, useful changes in this Salesforce DX repository.

- Project root: `sfdx-project.json` declares package directory `force-app` (single-package source). Treat `force-app/main/default` as the primary source location for metadata.
- Scratch org definition: `config/project-scratch-def.json` contains org settings and feature flags. Use it when creating scratch orgs or running local org-specific tests.

Quick commands (run from repo root):

- Install dev deps: npm install
- Lint JS (Aura/LWC): npm run lint (uses eslint on **/{aura,lwc}/**/\*.js)
- Run unit tests (LWC Jest): npm test or npm run test:unit
- Watch tests: npm run test:unit:watch
- Format files: npm run prettier

Key patterns and conventions to follow when editing code:

- Metadata layout: Salesforce metadata lives under `force-app/main/default/*` grouped by type folders (aura, lwc, classes, objects, layouts, etc.). Add/remove files following Salesforce metadata XML conventions.
- LWC/Aura JS linting: ESLint rules are configured via the devDependencies listed in `package.json` (use the provided eslint plugins). When adding new LWC/Aura JS, ensure eslint passes for `**/{aura,lwc}/**/*.js`.
- Tests: unit tests are LWC Jest tests run via `@salesforce/sfdx-lwc-jest`. Place tests alongside components using the standard `__tests__` pattern. Use `--findRelatedTests` in lint-staged for pre-commit test runs.
- Formatting: Prettier is configured (includes Apex plugin) and run via lint-staged and `npm run prettier` — run this before committing large changes.

Integration and external dependencies:

- Salesforce CLI (`sf`) is required for org operations (deploy, convert, create scratch org). The project expects API version 64.0 per `sfdx-project.json`.
- Node devDependencies (listed in `package.json`) power linting and jest; CI should run `npm ci` then `npm test` and `npm run lint`.

When making changes, prefer minimal diffs and follow these rules:

- Keep metadata structure intact; when renaming metadata, update both the file and its accompanying -meta.xml.
- For JavaScript changes in LWC/Aura, run eslint and unit tests locally. Fix lint errors rather than suppressing rules.
- Avoid adding non-deterministic behavior or external network calls in unit tests. Mock platform APIs via LWC Jest or simple stubs.

Use current `sf` CLI flags (not legacy `sfdx` names)

- The repository uses the modern `sf` CLI. Flag names and short aliases differ from the older `sfdx` commands. Always confirm the correct flags before running or generating CLI commands.
- Quick mappings (common):
  - `-u <alias>` (sfdx) -> `--target-org <alias>` or short `-o <alias>` (sf)
  - `--resultformat` (sfdx) -> `--result-format` (sf)
  - `-p <path>` (sfdx force:source:deploy) -> use `--source-dir <dir>` or convert to MDAPI + `sf mdapi deploy start` for mdapi deploys
  - `--json` is supported on `sf` commands for machine-readable output.
- Checklist for agents generating CLI commands:
  1.  Run `sf <command> --help` to verify available flags in the installed CLI.
  2.  Prefer long flags (`--target-org`) when short flags are ambiguous or differ across tool versions.
  3.  Use `--json` for outputs you intend to parse programmatically.
  4.  When producing example commands in docs or CI workflows, test them locally (`sf <command> --help` and a dry run) to ensure the installed `sf` version accepts the flags.

Important: always generate accompanying -meta.xml files

- When adding or moving Salesforce metadata (Apex classes/triggers, CustomObject/PlatformEvent definitions, Aura/LWC bundles, Permission Sets, Layouts, Static Resources, etc.), always create the matching -meta.xml file in the same folder using the repository's API version (see `sfdx-project.json`).
- Examples: when adding `MyClass.cls` add `MyClass.cls-meta.xml`; when adding `MyTrigger.trigger` add `MyTrigger.trigger-meta.xml`; when adding an LWC folder `force-app/main/default/lwc/myComponent`, include `myComponent.js-meta.xml`.
- Checklist for agents creating metadata files:
  1.  Use the `sourceApiVersion` value from `sfdx-project.json` for `<apiVersion>`.
  2.  Set `<status>` to `Active` for Apex/Triggers unless a different status is required.
  3.  Validate filenames: the -meta.xml filename must exactly match the metadata filename plus `-meta.xml` suffix.
  4.  Run the repo error checker / compile/lint step (or `sf project deploy start --checkonly` in CI) to surface metadata validation errors.
  5.  Avoid committing private keys or other secrets in metadata files.

Files and locations that are authoritative for behaviour and should be referenced in PRs:

- `package.json` — scripts and dev tools
- `sfdx-project.json` — source path and API version
- `config/project-scratch-def.json` — scratch org settings
- `force-app/main/default/lwc` and `.../aura` — main component sources

If you need clarification or more context, ask for:

- intended org (prod vs scratch) for deployment
- whether new metadata should be added to `force-app` or packaged separately
- any CI requirements (branches, node version) if adding toolchain changes

If merging with an existing `.github/copilot-instructions.md`, preserve any hand-authored notes about high-risk areas (Apex classes, triggers, and permission set changes).

End of instructions. Request feedback if parts are unclear or you want coverage of CI or deployment flows.

Scratch org quick commands

These are the common local dev commands you can include in PRs or run locally (run from repo root):

```bash
# create a scratch org from the repo scratch def, set as default and alias it
sf org create scratch -f config/project-scratch-def.json -s -a synckarma-scratch

# deploy local source to the scratch org (sf replacement for source:push)
sf project deploy start -u synckarma-scratch

# open the scratch org in the browser
sf org open -u synckarma-scratch

# run Apex tests in the default org (use -u <alias> to target another org)
sf apex test run -u synckarma-scratch --resultformat human --wait 10
```

Packaging & deployment notes (concrete examples)

- For local iterative dev use `sf project deploy start -u <alias>` against a scratch org (see `config/project-scratch-def.json`).
- For non-scratch targets or CI, convert source to Metadata API format and deploy using `sf` commands:

```bash
## convert source to mdapi format
sf project convert -d mdapi_output/ -r force-app

## deploy mdapi package to an org
sf mdapi deploy start -d mdapi_output/ -u <target-org-alias>
```

- Alternatively, for installable released units prefer unlocked packages (not present in this repo by default). Use `sfdx force:package:version:create` and `sfdx force:package:install` when this project is converted into an unlocked package structure.

CI note

I added a minimal GitHub Actions workflow at `.github/workflows/ci.yml` that runs `npm ci`, then `npm run lint` and `npm test` on pushes and pull requests. Customize Node version and caching per your CI needs.
