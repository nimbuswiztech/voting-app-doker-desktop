# Architecture

```mermaid
flowchart TD
  G[GitHub Voting App] --> J[Jenkins in Compose]
  J --> S[SonarQube]
  S --> P[(PostgreSQL)]
  J --> B[Build ARM64 images]
  B --> I[docker save stream]
  I --> C[ctr import into both Kind node stores]
  C --> K[Existing Docker Desktop Kubernetes]
  K --> V[Vote]
  K --> R[Result]
  K --> W[Worker]
  V --> Redis[(Redis)]
  W --> Redis
  W --> DB[(Voting PostgreSQL)]
  R --> DB
```

Context: `docker-desktop`; nodes: `desktop-control-plane`, `desktop-worker`; Kubernetes v1.36.1; containerd 2.3.1; ARM64.

The pipeline assumes node containers are visible to Docker and expose `ctr`. Setup preflight checks Docker visibility. No cluster creation or deletion is performed.
