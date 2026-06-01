# 01 - Code Standards

## Purpose
Define the coding standards and conventions for building Nexus so the codebase remains consistent, readable, and maintainable.

---

## 1. PHP / Laravel Standards
- Follow PSR-12 coding style
- Use Laravel service container and dependency injection
- Prefer small services and single-responsibility classes
- Keep controllers thin move logic into service classes
- Use form requests for validation
- Use resource classes for API output formatting
- Avoid `N+1` queries by eager loading relationships

### Formatting
- 4-space indentation
- One statement per line
- Align array keys vertically when practical
- Break long chains into multiple lines

---

## 2. JavaScript / frontend Standards
- Keep components small and declarative
- Use Tailwind utility classes with design tokens

### Formatting
- Keep line length under 120 characters

---

## 3. Workspace Conventions
- Use descriptive commit messages
- Branch names follow `feature/`, `fix/`, `docs/`, `chore/`
- Tag releases semantically: `v1.0.0`, `v1.1.0`
- Document architectural decisions in Markdown

---

## 4. Comments and Documentation
- Comment non-obvious business logic, not trivial code
- Use docblocks for public APIs and service methods
- Keep README and docs updated for major changes
- Add TODOs only with a clear migration plan

---

## 5. Dependency Management
- Prefer stable package versions over `dev-master`
- Lock dependencies in `composer.lock` and `package-lock.json`
- Review package compatibility before upgrades
- Keep package updates isolated to dedicated branches
