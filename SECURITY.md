# Security Policy — uFawkesDojo

## Supported versions

| Version | Supported |
|---|---|
| `main` branch | ✅ Active — patches applied here first |
| Tagged releases | ✅ Critical fixes backported where practical |
| Older releases | ❌ No active support |

We follow [Semantic Versioning](https://semver.org). The first stable release
is `v0.1.0`. Check [CHANGELOG.md](./CHANGELOG.md) for what each release
contains.

---

## Reporting a vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Report privately using one of these channels, in order of preference:

1. **GitHub private vulnerability reporting** (preferred):
   [Security → Report a vulnerability](https://github.com/paruff/uFawkesDojo/security/advisories/new)
   — this keeps the report confidential until a fix is published.

2. **Email**: Contact the maintainer via the email address on the
   [paruff GitHub profile](https://github.com/paruff). Use the subject line
   `[uFawkesDojo] Security report`.

Include in your report:

- Affected component (e.g. learning platform, lab environments, Jekyll site,
  GitHub Pages config, CI/CD pipelines)
- Steps to reproduce or a minimal proof of concept
- Your assessment of severity and impact
- Whether you have already disclosed this elsewhere

---

## Response timeline

| Stage | Target |
|---|---|
| Acknowledgement | Within 72 hours of receipt |
| Initial triage and severity assessment | Within 5 business days |
| Fix or mitigation published | Depends on severity (see below) |
| Public disclosure | After fix is available, coordinated with reporter |

**Severity guidelines:**

- **Critical** (CVSS ≥ 9.0): fix targeted within 7 days
- **High** (CVSS 7.0–8.9): fix targeted within 14 days
- **Medium / Low**: addressed in the next scheduled release

We will credit reporters in the release notes and CHANGELOG unless you
request anonymity.

---

## Scope

This policy covers the uFawkesDojo repository and its default configuration.
It does not cover:

- Third-party components (Jekyll, GitHub Pages, Ruby gems, Docker images,
  lab environment tools). Report upstream vulnerabilities to those projects.
  We will update pinned versions promptly when upstream patches are available.
- Deployments where users have modified the default configuration.
- The broader [Fawkes IDP](https://github.com/paruff/fawkes) suite — each
  repo has its own security policy.

---

## Security design notes

These are known constraints in this release. They are documented here rather
than treated as vulnerabilities:

**Static learning platform on GitHub Pages.** No server-side code executes in
production; attack surface is limited to client-side HTML/CSS/JS and build-time
Liquid processing.

**Lab environments.** Labs run in isolated Docker Compose or Kubernetes
environments. Users should not run lab environments on production clusters.

**External links.** The platform links to external resources (GitHub, upstream
docs). We validate external links in CI but do not control their content.

**No secrets in the repo.** All configuration is public. GitHub Pages build
runs in an isolated environment with no access to maintainer secrets.

**Content Security Policy.** GitHub Pages does not support custom CSP headers;
the site relies on browser defaults and referrer policies.

---

## Dependency management

Ruby gem versions are pinned in `Gemfile.lock`. Docker images are pinned in
`compose.yaml` and CI. We review upstream release notes for security advisories
and update pinned versions as part of each release cycle. If a critical
upstream vulnerability is published between releases, we will cut a patch
release.

To check for outdated dependencies:

```bash
bundle outdated
docker compose pull --dry-run
```

---

## AI-generated content policy

See [AGENTS.md](./AGENTS.md). AI-generated documentation, lab guides, and
Jekyll templates require human review before merge — inaccurate learning
content misleads students.
