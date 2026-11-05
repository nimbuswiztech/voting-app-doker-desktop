# Voting App – Docker Compose CI/CD for Docker Desktop Kubernetes

This project is tailored to the verified Mac environment:
- Docker Desktop Kubernetes provisioned with Kind
- Context: `docker-desktop`
- Kubernetes v1.36.1
- Nodes: `desktop-control-plane`, `desktop-worker`
- Runtime: containerd 2.3.1
- Architecture: ARM64

It reuses the existing cluster. It never creates, resets, upgrades or deletes Kubernetes.

## Architecture
Docker Compose runs Jenkins, SonarQube and SonarQube PostgreSQL. Jenkins checks out the Docker Samples Voting App, runs SonarQube analysis and quality-gate wait, builds ARM64 Vote/Result/Worker images, imports each image into both Kubernetes node containerd stores, applies manifests and waits for rollouts.

## Important compatibility note
Docker Desktop manages this Kind-based cluster. Do not assume it is equivalent to a cluster created by `kind create cluster`. The pipeline uses the actual Kubernetes context and node names. It imports images using `ctr` inside each node and sets `imagePullPolicy: Never`.

This requires Docker Desktop's node containers to be visible to Docker CLI. If `docker inspect desktop-control-plane` fails, enable Docker Desktop → Kubernetes → **Show system containers (advanced)**. If the current Docker Desktop release does not expose node containers to Docker CLI, do not recreate/reset the cluster; use a registry-based delivery method instead.

## Prerequisites
- Docker Desktop running with Kubernetes enabled
- Docker Compose v2, kubectl
- 16 GB RAM recommended; 12 GB minimum lab allocation
- 20 GB free disk
- Internet access for image downloads and GitHub checkout

## 1. Verify cluster
```bash
kubectl config current-context
kubectl get nodes -o wide
docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
```
Expected context `docker-desktop`; both nodes Ready.

## 2. Start tools
```bash
unzip VotingApp-DockerDesktop-Kind-CICD.zip
cd VotingApp-DockerDesktop-Kind-CICD
cp .env.example .env
# Edit .env and replace the example password.
./scripts/prepare.sh
./scripts/setup.sh
```
Prepare selects the existing context, writes a flattened kubeconfig with embedded certificates and checks node-container visibility. It does not deploy Kubernetes resources.

## 3. Tool URLs
- Jenkins: http://localhost:8080
- SonarQube: http://localhost:9000

Get Jenkins unlock password:
```bash
./scripts/jenkins-password.sh
```
Complete Jenkins setup and install suggested plugins.

## 4. SonarQube setup
1. Sign in to SonarQube. Fresh install: `admin` / `admin`; change the password.
2. Create project key `voting-app-training`.
3. Generate a user token.
4. In Jenkins → Manage Jenkins → Credentials, add a **Secret text** credential with ID `sonarqube-token`.

The scanner uses `sonar.qualitygate.wait=true`; no webhook is required.

## 5. Create Jenkins Pipeline job
1. New Item → `votingapp-cicd` → Pipeline.
2. Definition: Pipeline script from SCM.
3. SCM: Git; Repository URL: your Git repository containing this project.
4. Branch: `*/main` (adjust if needed).
5. Script Path: `jenkins/Jenkinsfile`.
6. Save. For private Git, configure a Jenkins Git credential.

## 6. Verify Jenkins
```bash
./scripts/check-jenkins-k8s.sh
```
This checks the mounted kubeconfig, Docker socket, node visibility and `ctr` availability.

## 7. Run pipeline
Jenkins → `votingapp-cicd` → Build with Parameters:
- APP_SOURCE_REPO: `https://github.com/dockersamples/example-voting-app.git`
- APP_BRANCH: `main`
- K8S_CONTEXT: `docker-desktop`
- DEPLOY_TO_K8S: checked
- PUBLISH_TO_JFROG: unchecked for the local-only lab; check it to publish to Artifactory
- JFROG_REGISTRY: optional registry path, e.g. `company.jfrog.io/docker-local`

Click Build. Stages: connectivity → checkout → validation → SonarQube quality gate → ARM64 image build → optional JFrog publish → import into both nodes → Kubernetes deployment → rollout verification.

### Optional JFrog Artifactory integration
1. Create a Docker-local repository in JFrog Artifactory and note the exact registry path.
2. In Jenkins → Credentials, create a **Username with password** credential with ID `jfrog-docker`. Use your JFrog username and an access token as the password.
3. On Build with Parameters, check `PUBLISH_TO_JFROG` and set `JFROG_REGISTRY` to the registry path supplied by JFrog, e.g. `company.jfrog.io/docker-local`.
4. The pipeline logs in using `--password-stdin`, tags and pushes the three images. Credentials are not stored in the Jenkinsfile.

## 8. Access app
Vote:
```bash
kubectl port-forward -n votingapp svc/voting-service 8081:80
```
Open http://localhost:8081.

Result (second terminal):
```bash
kubectl port-forward -n votingapp svc/result-service 8082:80
```
Open http://localhost:8082.

## Troubleshooting
### Jenkins cannot connect to API
```bash
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}{"\\n"}'
docker exec voting-jenkins kubectl config current-context
docker exec voting-jenkins kubectl get nodes
```
The API endpoint must be reachable from the Jenkins container and its TLS certificate must validate. Do not disable TLS verification.

### Node containers not visible
Enable Show system containers (advanced), then:
```bash
docker ps -a | grep -E 'desktop-control-plane|desktop-worker'
docker inspect desktop-control-plane
```

### ctr missing
```bash
docker exec desktop-control-plane ctr version
docker exec desktop-worker ctr version
```
If unavailable, use a cluster-reachable registry approach. Do not reset the cluster.

### Image not found
```bash
kubectl describe pod -n votingapp <pod-name>
docker exec desktop-control-plane ctr -n k8s.io images ls | grep voting-
docker exec desktop-worker ctr -n k8s.io images ls | grep voting-
```
Image tag must match and exist on both nodes.

### SonarQube startup
```bash
docker compose logs -f sonarqube
docker compose logs -f sonardb
```
Allocate more Docker Desktop memory if necessary.

## Stop lab
```bash
./scripts/teardown.sh
```
This stops only Compose services and retains volumes. It does not delete Kubernetes. To delete Jenkins/Sonar data too: `docker compose down -v`.

## Security and production limitations
- Training lab only.
- Jenkins mounts Docker socket and receives Kubernetes credentials; jobs can control Docker and the cluster.
- Do not expose Jenkins publicly or run untrusted pipelines.
- Voting App DB uses demo credentials and ephemeral storage.
- This project builds ARM64 images for this Mac. Change build strategy for other platforms.
- JFrog is not provisioned locally; it can be added as an external registry using Jenkins credentials.
