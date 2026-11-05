# Trainer Guide – Voting App End-to-End CI/CD

## Audience and duration
Beginner/intermediate DevOps learners. Suggested duration: 3–4 hours.

## Learning outcomes
Students explain CI/CD, Jenkins stages and credentials, SonarQube analysis and quality gates, Docker builds/tags, containerd image delivery, Kubernetes Deployments, Services, namespaces and rollouts.

## Suggested lesson plan

| Time | Topic | Demonstration |
|---|---|---|
| 0–20 min | Architecture | Git → Jenkins → SonarQube → Docker → Kubernetes |
| 20–40 min | Docker Compose | Start services; inspect network and volumes |
| 40–65 min | Jenkins | Unlock Jenkins; create Pipeline from SCM |
| 65–90 min | SonarQube | Create project and token; explain quality gate |
| 90–120 min | Docker | Explain Dockerfile, context, tags and ARM64 images |
| 120–145 min | Containerd | Import images into both Kubernetes nodes |
| 145–180 min | Kubernetes | Inspect pods, services, rollouts and port-forward |
| 180–210 min | Troubleshooting | Break an image tag, inspect events, recover |

## Trainer speaking script

### Opening
“Today we will build a full delivery path on one Mac. Jenkins orchestrates the pipeline. SonarQube analyzes source code. Docker builds the application images. Kubernetes runs the images as Deployments.”

### Docker Compose
“Compose starts the tools and dependencies. Jenkins and SonarQube are separate services. SonarQube stores its data in PostgreSQL. Named volumes preserve tool data across container restarts.”

Run:
```bash
docker compose ps
docker network ls
docker volume ls | grep -E 'jenkins|sonar'
```

### Jenkins
“Jenkins is the orchestrator. Pipeline as Code means the workflow is version-controlled in a Jenkinsfile. Each stage has its own logs and failure boundary.”

Explain checkout, parameters, credentials binding, stages and post actions.

### SonarQube
“Static analysis checks code without running the application. The quality gate gives the pipeline a measurable pass/fail decision.” The sample pipeline analyzes Vote and Result source folders; Worker is built and deployed but is not part of this basic scanner configuration.

### Docker and containerd
“Docker Desktop Kubernetes uses containerd on its nodes. A Docker-built image does not automatically appear in those containerd stores. The pipeline exports the image and imports it into both nodes.”

Run:
```bash
docker exec desktop-control-plane ctr -n k8s.io images ls
docker exec desktop-worker ctr -n k8s.io images ls
```

### Kubernetes
“Deployments declare the desired number of replicas. Services provide stable network identities. A namespace keeps this lab separate from other workloads.”

Run:
```bash
kubectl get all -n votingapp
kubectl get pods -o wide -n votingapp
kubectl describe deployment vote -n votingapp
kubectl rollout history deployment/vote -n votingapp
```

### Production discussion
“For production, use a secured remote registry such as JFrog, secrets management, persistent storage, ingress, resource limits, approvals and a hardened Jenkins architecture.”

## Exercises
1. Scale Vote from two replicas to three.
2. Change an image tag to a nonexistent value and inspect pod events.
3. Change source and observe SonarQube analysis.
4. Run another pipeline build and compare image tags.
5. Roll back using `kubectl rollout undo`.
