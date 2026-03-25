---
name: prove-it
description: Verify that changes actually work by validating at the highest appropriate level of abstraction — build it, run it, use it like a real user would. Use this skill after implementing any feature, fixing any bug, making configuration changes, or whenever you need to prove something works. Triggers on completing implementation, bug fixes, 'does this work', 'verify this', 'prove it', 'test this', or when about to claim a change is done. Also use when reproducing reported bugs — see it break before claiming to fix it. If you're unsure whether to verify, verify.
---

# Prove It

## The Principle

Prove your claims with real-world verification.

## The Process

### 1. Understand What You're Proving

Before touching verification, state your claim out loud:

- "This CLI flag now accepts negative numbers"
- "The Kafka consumer reconnects after broker restart"
- "This deployment manifest works in a real cluster"

The claim determines the verification level. A claim about CLI behavior means running the CLI. A claim about cluster behavior means running in a cluster.

### 1b. Maintain the Proof Log

Read `thoughts/proofs.md` if it exists. Before attempting to prove anything, write your claim to it. After each verification, update it with evidence.

This is how verification state survives compaction and session boundaries. Without it, the next session doesn't know what's been verified and re-runs 15-minute cluster replays to check something that already passed.

For the entry format, template, and rules, read `${CLAUDE_SKILL_DIR}/references/proof-log-format.md`.

### 2. Choose the Right Level — Progressive Verification

Don't jump straight to the highest level. Verify progressively — pass each level before moving up. Lower levels are fast and isolate code bugs. Higher levels are slow and surface environment bugs. Mixing them wastes time debugging environment problems when the code is wrong, or debugging code when the environment is wrong.

```
Unit (isolated function)                           <- pass this first
Component (real code, stubbed boundaries)          <- then this
Integration (real dependencies, real protocols)    <- then this
Real deployment / production-like environment      <- prove it here last
```

**The progression:**

1. **Unit tests pass.** The code logic is correct in isolation. Fast, repeatable, debuggable.
2. **Local integration passes.** The code works with real dependencies (real libraries, real protocols, real data). Catches serialization, auth, protocol negotiation issues that unit tests miss.
3. **Deployment verification passes.** The code works in the actual target environment. Catches DNS, TLS, SDAM, secret mounting, sidecar injection — things that don't exist locally.

**Don't stop at unit tests** — they're necessary but not sufficient. A passing unit test doesn't prove end-to-end behavior.

**Don't skip to deployment** — if unit tests fail, every deployment attempt wastes a full build/deploy/observe cycle debugging something you could have caught in seconds locally.

**The litmus test:** Would a real user exercise this feature the way you're verifying it? If not, you haven't reached the top yet. But get the lower levels green first.

### 3. Check for Existing Infrastructure

Before building anything new, look for what's already there:

- Existing test suites, Makefiles, docker-compose files
- CI pipelines that exercise this path
- Scripts in the repo (e.g., `thoughts/scripts/`, `hack/`, `test/`)
- Previously built verification tools

Reuse first. Build only what's missing. Repos accumulate test infrastructure over time — a fresh harness for something that already has coverage is waste, and it might miss constraints the existing infrastructure encodes.

### 4. Execute

Run the real thing. Capture the output. Read it carefully.

**For bug fixes, the sequence is non-negotiable:**

1. Reproduce the bug — see it fail with your own eyes
2. Apply the fix
3. Verify the fix — see it pass
4. Check for regressions

You haven't fixed a bug if you never saw it break.

**For features and changes:**

Build and run at the level you chose in step 2. If you chose "run the CLI," then build the binary and run commands. If you chose "run in a cluster," then deploy and verify pods, health checks, traffic.

### 5. Report Honestly

- State what you proved and what you didn't. If verification was partial, say so.
- Reference the proof artifact you created in step 7 — the user should be able to re-verify by running a single script or following a doc.

```
Good: "Verified the CLI accepts negative numbers by building and
       running `mytool --offset -5`. Output confirmed. Did NOT
       verify this in the Docker image — can't build it from here.
       Proof script: thoughts/scripts/verify-negative-offset.sh"

Bad:  "The change looks correct and should work."
```

100% intellectual honesty. If you can't fully verify, say what's missing. Don't silently downgrade.

### 6. Ask for Help When Stuck

If you're unsure about:

- What verification level is appropriate
- How to access the test environment
- Whether existing infrastructure covers this case
- How to reproduce a reported bug

**Ask.** Downgrading verification silently is worse than admitting you need guidance. This is especially important for environment-dependent verification — clusters, remote services, build systems you don't have access to.

### 7. Leave a Proof Artifact

Verification that only exists in a conversation transcript is worthless the moment the session ends. The user needs to be able to re-run your proof independently — both to trust it now and to catch regressions later.

**Default: executable script in `thoughts/scripts/`**

Write a script that reproduces your verification end-to-end. Name it descriptively (e.g., `verify-negative-offset.sh`, `prove-kafka-reconnect.sh`). The script should:

- Be executable (`chmod +x`)
- Exit 0 on success, non-zero on failure
- Print clear output showing what it checked and the result
- Be self-contained — anyone should be able to run it cold without reading the conversation
- Include a comment header explaining what it proves and when it was created

```bash
#!/usr/bin/env bash
# Proves: --format json flag outputs valid JSON
# Created: 2025-01-15 after fixing json output regression
set -euo pipefail

go build -o /tmp/mytool ./cmd/mytool
output=$(/tmp/mytool --format json --input testdata/sample.txt)
echo "$output" | jq . > /dev/null 2>&1 || { echo "FAIL: output is not valid JSON"; exit 1; }
echo "PASS: --format json produces valid JSON"
```

**Fallback: reproduction doc in `thoughts/reproductions/`**

Some verifications genuinely can't be scripted — they require a running cluster, a browser, manual UI interaction, specific hardware, or credentials you don't have. When that's the case, write a markdown doc instead. Name it to match the claim (e.g., `verify-k8s-deployment.md`, `prove-dark-mode-toggle.md`). The doc must include:

- **Claim**: what you're proving
- **Prerequisites**: what environment/access/state is needed
- **Steps**: numbered, exact commands or actions — specific enough that someone unfamiliar with the change can follow them
- **Expected results**: what success looks like at each step
- **What was actually observed**: your real output/screenshots/logs from when you ran it
- **Why this can't be scripted**: one sentence explaining the blocker

The fallback is for genuinely unscriptable scenarios. "It would take a while" or "it's complicated" are not valid reasons — those are reasons to write a better script. If the verification involves running commands and checking output, it's scriptable.

**Additionally, look for permanent homes:**

Beyond the proof artifact, consider whether the verification belongs somewhere more durable:

- Can this become a test case in an existing suite?
- Should this be a CI check?
- Does an existing script in `hack/`, `test/`, or `thoughts/scripts/` already cover this and just needs updating?

**Update the proof log** (`thoughts/proofs.md`) with a reference to the artifact. The proof log entry should point to the script or doc so a future session can both see WHAT was proven and HOW to re-prove it.

## Examples

### CLI Tool

**Claim:** "The `--format json` flag now works correctly"

| | Approach |
|---|---|
| Wrong | Write a unit test for the format-parsing function |
| Right | Build the binary, run `mytool --format json`, inspect output |

Users run commands, not internal functions. Verify what they'd actually do.

### Library Integration (e.g., Kafka Consumer)

**Claim:** "The consumer can read from the `proxymock mock` mock server as if it were a Kafka broker"

| | Approach |
|---|---|
| Wrong | Run `proxymock mock`, construct a raw payload and send it over a TCP connection |
| Right | Run `proxymock mock`, use the actual Kafka client library, connect to a real or mocked broker, produce a message, verify the consumer handles it |

Bespoke wire-protocol shortcuts don't prove the real library integration works. The consumer might fail on serialization, auth, or protocol negotiation that your shortcut bypassed entirely.

### Infrastructure / Deployment

**Claim:** "This app runs correctly in a Kubernetes cluster"

| | Approach |
|---|---|
| Wrong | Read the YAML and reason about whether it looks correct |
| Right | Apply the manifest, verify pods start, pass health checks, serve traffic |

If you can't access the cluster — say so. Don't downgrade to "the YAML looks fine." Ask for access or guidance.

## Antipatterns

- **"The code looks correct."** Static analysis is not verification. Reading code tells you what it SHOULD do. Running it tells you what it DOES. These diverge more often than you'd expect.
- **Bespoke shortcuts that don't match real usage.** If the feature uses library X, verify with library X. A hand-rolled alternative that produces similar bytes proves nothing about the actual integration.
- **Stopping at the lowest level when higher is available.** A passing unit test doesn't prove end-to-end behavior. If you CAN go higher, go higher. Unit tests are a floor, not a ceiling.
- **Jumping to the highest level without passing lower levels.** If you deploy to a cluster before unit tests pass, every failure could be code or environment — you can't tell which. Pass lower levels first so higher-level failures are always environment/integration issues, never code bugs.
- **Creating new infrastructure before checking for existing.** Look before you build. Existing test harnesses encode constraints and patterns that a fresh one will miss.
- **Claiming partial verification is full verification.** If you verified the happy path but not error handling, say so. Half-proved is not proved.
- **Silently downgrading when stuck.** Can't access the cluster? Can't build the image? Don't just test locally and call it done. State the gap and ask for help.
- **Ephemeral-only proof.** Running commands in the conversation and declaring victory leaves no artifact the user can re-run. If your proof dies with the session, it wasn't proof — it was a demo. Write the script or the reproduction doc.

