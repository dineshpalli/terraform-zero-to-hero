“Dev”, “QA”, and “Prod” are shorthand for the three classic stages in a software delivery pipeline.
Each stage is an isolated environment—a self‑contained copy of your application plus all the services it talks to—set up so that changes can move safely from the developer’s keyboard to end users.

Aspect	Dev (Development)	QA (Quality Assurance / Test / Staging)	Prod (Production)
Primary purpose	Build new features, fix bugs, experiment	Verify that what was built works and doesn’t break anything else	Serve real users and real data
Typical users	Software engineers, sometimes ops/infra	Testers, QA engineers, product owners, automated test runners	Customers, end‑users, support staff
Expected stability	Lowest – frequent resets, debug logs on, crashes acceptable	Medium – must stay up long enough for tests; occasional resets	Highest – high uptime, strict SLO/SLA targets
Data	Synthetic or developer‑generated	Freshly seeded realistic data or masked copies of prod	Live, authoritative business data
Access & permissions	Wide‑open to the dev team; minimal security walls	Restricted to dev + QA teams; some security controls	Locked down: principle‑of‑least‑privilege, audited changes
Tooling & configs	Hot‑reload, debuggers, verbose logging, feature flags on	Test harnesses, integration suites, canary toggles	Monitoring, alerting, rate‑limiters, A/B switches
Deploy cadence	Multiple times per day	After each change set is code‑reviewed; often automatic	On a schedule or via automated promotion after QA sign‑off
Rollback strategy	N/A – just redeploy or recreate	Re‑run previous build or re‑seed environment	Blue‑green, canary, or versioned rollbacks to ensure uptime
Infrastructure size/scale	Smallest, cost‑optimized	Mirrors prod topology but often scaled down	Full scale, often multi‑AZ/region, hardened infra


⸻

How the three environments fit into a delivery pipeline

  Developers
     ↓   (commit)
  ┌─────────┐
  │  Dev    │  ← unit tests, local debugging
  └─────────┘
     ↓   (merge / CI promote)
  ┌─────────┐
  │   QA    │  ← integration & regression suites, user‑acceptance tests
  └─────────┘
     ↓   (manual or automatic gate)
  ┌─────────┐
  │  Prod   │  ← live traffic, real incidents, business KPIs
  └─────────┘

	1.	Dev: Every code change lands here first. Engineers iterate quickly, often “breaking things” to confirm behavior.
	2.	QA: Code automatically promoted runs through exhaustive tests: automated regression, performance, security scanning, and sometimes manual exploratory testing.
	3.	Prod: Once QA stamps approval, the exact same artifact is deployed to the production environment, sometimes via a canary or blue‑green rollout to minimize risk.

⸻

Why keep the stages separate?
	•	Risk containment – A failure in Dev or QA won’t affect paying customers.
	•	Reproducibility – QA can reproduce Prod issues safely and reliably.
	•	Compliance & security – Prod often has stricter audit and data‑handling rules.

⸻

Good practices
	•	Configuration‑as‑code: Define Dev, QA, and Prod in Terraform/Ansible/Kubernetes manifests so you can recreate them deterministically.
	•	Promotion, not rebuild: Build an artifact once, then promote the same artifact through Dev ➜ QA ➜ Prod to eliminate “works on my machine” drift.
	•	Observability parity: Instrument QA almost as well as Prod so you can catch performance regressions before users do.
	•	Data hygiene: Never copy sensitive Prod data to Dev; instead use synthetic or anonymized data sets.

⸻

TL;DR
	•	Dev = playground for rapid change
	•	QA = proving ground for correctness and safety
	•	Prod = the real thing, where uptime and user experience rule

Keeping them distinct lets you move fast and protect the business.