# Domain: [DOMAIN NAME]

**Last updated:** [YYYY-MM-DD]
**Maintainer:** [WHO KEEPS THIS CURRENT]

<!--
  A domain spec describes how a system/module/domain works RIGHT NOW.
  Not what's planned. Not what it used to be. The current state of truth.
  
  Update this document every time a feature or bugfix changes this domain.
  If you're reading this and it's wrong, fix it.
-->

## Overview

[2-3 sentence summary of what this domain does and why it exists.]

## Data Model

<!--
  Key entities, their relationships, and important fields.
  Not a full schema dump — the important stuff that someone needs
  to understand to work in this domain.
-->

### [Entity Name]

- **Table/Collection:** `table_name`
- **Key fields:**
  - `field_name` (type) — [purpose]
  - `field_name` (type) — [purpose]
- **Relationships:** [How it connects to other entities]
- **Invariants:** [Rules that must always be true, e.g. "status can only transition forward"]

## Key Flows

<!--
  The main operations / workflows in this domain.
  Describe what happens, not how the code is structured.
-->

### [Flow Name, e.g. "Charge Processing"]

1. [Step 1 — what happens]
2. [Step 2 — what happens]
3. [Step 3 — what happens]

**Entry points:** `path/to/handler.ext`, `path/to/webhook.ext`
**Key files:** `path/to/service.ext`, `path/to/model.ext`

## Integration Points

<!--
  Where this domain touches other domains or external services.
-->

- **[External Service/API]:** [How we integrate, what we use it for]
- **[Internal Domain]:** [How they interact, data flow direction]

## Configuration

<!--
  Environment variables, feature flags, config files that affect this domain.
-->

- `ENV_VAR_NAME` — [what it controls, default value]
- `config.key` — [what it controls]

## Edge Cases & Gotchas

<!--
  Things that have bitten people before. Hard-won knowledge.
  Future-you (and future agents) will thank present-you.
-->

- [Edge case or non-obvious behavior and how it's handled]
- [Common mistake and how to avoid it]

## Monitoring & Observability

<!--
  How to tell if this domain is healthy or broken.
-->

- **Logs:** [Where to look, key log patterns]
- **Metrics:** [Key metrics, dashboards]
- **Alerts:** [What triggers alerts, who gets paged]
