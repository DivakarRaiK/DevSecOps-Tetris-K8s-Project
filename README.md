# DevSecOps Pipeline — Tetris on AWS EKS

![DevSecOps](https://img.shields.io/badge/DevSecOps-End--to--End-brightgreen?style=for-the-badge)
![AWS EKS](https://img.shields.io/badge/AWS-EKS-FF9900?style=for-the-badge&logo=amazon-aws)
![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?style=for-the-badge&logo=jenkins)
![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?style=for-the-badge)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?style=for-the-badge&logo=terraform)
![SonarQube](https://img.shields.io/badge/SonarQube-Code%20Quality-4E9BCD?style=for-the-badge)
![Trivy](https://img.shields.io/badge/Trivy-Security-1904DA?style=for-the-badge)
![Docker](https://img.shields.io/badge/Docker-Containerization-2496ED?style=for-the-badge&logo=docker)

---

## What This Project Demonstrates

A **production-grade DevSecOps pipeline** on AWS that automates the full software delivery lifecycle of a containerized application — from a developer's code push all the way to a live, publicly accessible deployment on Kubernetes — with **security gates enforced at every stage**.

The key engineering decisions here were intentional:

- **Why shift-left security?** Catching vulnerabilities at the code and dependency stage (SonarQube + OWASP) is orders of magnitude cheaper than finding them in production
- **Why GitOps with ArgoCD?** The cluster state is always declarative and auditable — no manual `kubectl apply` that no one can trace
- **Why Terraform for everything?** Zero manual console clicking — the entire infrastructure is reproducible, version-controlled, and destroyable in one command
- **Why two app versions (V1 + V2)?** To demonstrate the full image update → manifest change → ArgoCD auto-sync loop end-to-end

---

## Architecture

![Architecture](assets/architecture.svg)

---

## Tech Stack & Why Each Tool

| Tool | Role | Why This Tool |
|------|------|---------------|
| **AWS EKS** | Kubernetes cluster | Managed control plane — no manual kubeadm, production-grade HA |
| **Terraform** | Infrastructure as Code | Both Jenkins EC2 and EKS cluster provisioned — fully reproducible |
| **Jenkins** | CI/CD orchestration | Declarative pipeline, rich plugin ecosystem, self-hosted control |
| **SonarQube** | Static code analysis | Quality gate blocks the pipeline if code standards are not met |
| **OWASP Dependency-Check** | Dependency CVE scanning | Catches known vulnerabilities in npm packages before build |
| **Trivy** | Container security | Scans both filesystem and final Docker image against latest CVE DB |
| **Docker** | Containerization | Immutable, portable artifacts pushed to Docker Hub |
| **ArgoCD** | GitOps deployment | Cluster always matches Git — drift detection and auto-healing |

---

## Pipeline Flow

```
Code Push → Jenkins Trigger
    │
    ├── SonarQube Analysis ──► Quality Gate (blocks on failure)
    ├── OWASP Dependency Check ──► CVE Report
    ├── Trivy File System Scan
    ├── Docker Build + Push to Docker Hub
    ├── Trivy Image Scan ──► Vulnerability Report
    └── Update Kubernetes Manifest (image tag)
              │
              ▼
         ArgoCD detects manifest change
              │
              ▼
         Auto-sync to EKS Cluster
              │
              ▼
         Live App on AWS LoadBalancer
```

---

## Infrastructure — Provisioned via Terraform

Both the Jenkins CI server and the EKS cluster were provisioned entirely via Terraform — no manual AWS console interaction.

![EKS Cluster Active](assets/eks-cluster-active.png)
*Tetris-EKS-Cluster running Kubernetes v1.33 — Active on AWS EKS*

![kubectl get nodes](assets/kubectl-get-nodes.png)
*Two worker nodes Ready — connected via `aws eks update-kubeconfig`*

![Jenkins Infra Pipeline](assets/jenkins-infra-pipeline.png)
*Jenkins Terraform pipeline — Build #2 successful across all stages*

![Terraform Apply Success](assets/terraform-apply-success.png)
*`Apply complete! Resources: 1 added` — EKS node group created*

---

## Security Gates

Security is not an afterthought — it is woven into the pipeline. The build cannot proceed past the Quality Gate if SonarQube finds issues that breach the threshold.

### SonarQube — Quality Gate in Action

**V1** passed the quality gate cleanly on the first run.

**V2 Build #1 failed** at the SonarQube stage — the pipeline was configured with an incorrect SonarQube token for the V2 project, causing the analysis to fail and the quality gate to report failed conditions. The entire pipeline was blocked at that point — nothing after the Quality Check stage ran. This is the pipeline doing its job — a misconfiguration is caught early before anything gets built or deployed.

The token was corrected in the Jenkins credentials, the pipeline re-triggered on Build #2, SonarQube analyzed successfully, the quality gate passed, and the full pipeline completed.

This is an important real-world lesson — **credential and token management is as critical as the code itself** in a DevSecOps pipeline.

![SonarQube Quality Gate Failed](assets/sonarqube-quality-gate-failed.png)
*V2 Build #1 — Quality Gate ❌ Failed due to incorrect SonarQube token configuration. Pipeline hard-stopped — no build, no deployment ran.*

![SonarQube Quality Gate Passed](assets/sonarqube-quality-gate-passed.png)
*V2 Build #2 — Quality Gate ✅ Passed after correcting the token. 0 new issues, 0 security violations. Full pipeline proceeded.*

![SonarQube Dashboard](assets/sonarqube-dashboard.png)
*Final project state — Security Grade A, 0 duplications, quality gate passing*

### OWASP Dependency-Check — CVEs Identified and Logged

![OWASP Dependency Check](assets/owasp-dependency-check.png)
*CVEs surfaced across npm packages — Critical, High, and Medium severity findings logged as build artifacts*

### Trivy — Image Scan

![Trivy Image Scan](assets/trivy-image-scan.png)
*Trivy scanning `divakarraik/tetrisv2` against the latest vulnerability DB — OS and language-specific CVEs reported*

---

## CI/CD Pipeline — Jenkins

### Tetris V1

![V1 Jenkins Stage View](assets/v1-jenkins-stage-view.png)
*All stages green — Build #4. Full run ~26 minutes including OWASP deep scan*

![V1 Jenkins Success](assets/v1-jenkins-success.png)
*`Finished: SUCCESS`*

### Tetris V2

![V2 Jenkins Stage View](assets/v2-jenkins-stage-view.png)
*All stages green — Build #2. Full run ~8 min 55s*

![V2 Trivy File Scan](assets/v2-trivy-file-scan.png)
*Trivy downloading fresh vulnerability DB and scanning workspace before Docker build*

![V2 Jenkins Success](assets/v2-jenkins-success.png)
*`Finished: SUCCESS`*

### All Pipelines

![Jenkins All Pipelines](assets/jenkins-all-pipelines.png)
*All three pipelines healthy — DevSecOps-Tetris-K8s-Project, tetris-v1, tetris-v2*

---

## Docker Hub — Images Published

![Docker Hub Images](assets/dockerhub-images.png)
*Both `divakarraik/tetrisv1` and `divakarraik/tetrisv2` pushed successfully*

---

## GitOps Deployment — ArgoCD

ArgoCD watches `Manifest-file/`. When Jenkins updates the image tag and pushes to Git, ArgoCD detects the diff and automatically syncs the cluster — no manual deployment step, full audit trail.

![ArgoCD Pods Running](assets/argocd-pods-running.png)
*All ArgoCD components running in the `argocd` namespace on EKS*

![ArgoCD App Synced](assets/argocd-app-synced.png)
*tetris-app — Status: Healthy and Synced. Auto-sync triggered by image tag update.*

![ArgoCD App Healthy](assets/argocd-app-healthy.png)
*Full resource tree: tetris-app → Service + Deployment → ReplicaSet — all healthy*

---

## Live Application

![kubectl pods and svc](assets/kubectl-pods-svc.png)
*3 pods running, tetris-service exposed as AWS LoadBalancer*

### Tetris V1 — Live on AWS ELB

![Tetris V1 Live](assets/tetris-v1-live-1.png)

![Tetris V1 Gameplay](assets/tetris-v1-live-2.png)

### Tetris V2 — Live on AWS ELB

V2 ships a completely redesigned dark-themed UI — deployed through the same pipeline demonstrating the full image update → ArgoCD sync loop.

![Tetris V2 Start](assets/tetris-v2-start.png)

![Tetris V2 Live](assets/tetris-v2-live-1.png)

![Tetris V2 Gameplay](assets/tetris-v2-live-2.png)

---

## Repository Structure

```
DevSecOps-Tetris-K8s-Project/
├── EKS-TF/                  # Terraform — AWS EKS cluster + node group
├── Jenkins-Server-TF/       # Terraform — Jenkins EC2 instance
├── Jenkins-Pipeline-Code/   # Declarative Jenkinsfile
├── Manifest-file/           # Kubernetes Deployment + Service manifests
├── Tetris-V1/               # React Tetris — Version 1
├── Tetris-V2/               # React Tetris — Version 2 (redesigned UI)
└── assets/                  # Architecture diagram + pipeline screenshots
```

---

## Key Takeaways

**Infrastructure as Code** — Zero manual provisioning. `terraform apply` spins up the entire stack; `terraform destroy` tears it down cleanly.

**Security at every stage** — SonarQube enforces a quality gate. OWASP scans all dependencies. Trivy scans both the workspace and the final image. No vulnerability goes undetected.

**GitOps mindset** — The cluster state is never modified directly. Everything flows through Git → ArgoCD → EKS. Full audit trail, automatic drift correction.

**Real AWS infrastructure** — This ran on a live EKS cluster with real EC2 worker nodes, a real AWS LoadBalancer, and real DNS. Not a local minikube setup.

---

## License

Apache-2.0 — see [LICENSE](LICENSE)
