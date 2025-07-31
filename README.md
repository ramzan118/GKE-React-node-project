# GKE-React-node-spanner-project
# 📦 GKE React-Node Project

This is a full-stack React + Node.js application deployed on Google Kubernetes Engine (GKE) using GitHub Actions with a blue-green CI/CD pipeline and instant rollback capability. It connects to Google Spanner for backend data storage and uses Google Secret Manager to securely store sensitive credentials.

---

## 🛠️ Tech Stack

- Frontend: React
- Backend: Node.js + Express
- Database: Google Spanner
- CI/CD: GitHub Actions + Flagger
- Secrets: Google Secret Manager
- Containerization: Docker
- Orchestration: Kubernetes (GKE)
- Branching Strategy: GitFlow

---

## 🚀 Setup & Deployment Guide

### 1. Create GCP Project & Enable APIs

```bash
gcloud projects create gke-react-node-project --name="GKE React Node Project"
gcloud config set project gke-react-node-project

gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  spanner.googleapis.com \
  iam.googleapis.com
2. Dockerfile (Combined React + Node)
Dockerfile
# Stage 1: Build React frontend
FROM node:18-alpine AS frontend
WORKDIR /app
COPY gke-react-front/package*.json ./gke-react-front/
RUN cd gke-react-front && npm install && npm run build

# Stage 2: Build Node backend
FROM node:18-alpine AS backend
WORKDIR /app
COPY gke-node-backend/package*.json ./gke-node-backend/
RUN cd gke-node-backend && npm install

# Final Stage
FROM node:18-alpine
WORKDIR /app
COPY --from=frontend /app/gke-react-front/build ./public
COPY --from=backend /app/gke-node-backend ./
EXPOSE 8080
CMD ["node", "server.js"]
3. Store DB Credentials in Secret Manager
bash
echo -n "your-spanner-connection-string" | gcloud secrets create spanner-db-connection-string \
  --data-file=- \
  --replication-policy="automatic"

gcloud secrets add-iam-policy-binding spanner-db-connection-string \
  --member="serviceAccount:github-actions-sa@gke-react-node-project.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
4. Create Spanner Instance & DB
bash
gcloud spanner instances create react-node-instance \
  --config=regional-us-central1 \
  --description="React Node Spanner Instance" \
  --nodes=1

gcloud spanner databases create react-node-db \
  --instance=react-node-instance
5. Create GKE Cluster
bash
gcloud container clusters create my-cluster \
  --zone=us-central1-c \
  --num-nodes=3 \
  --enable-ip-alias \
  --workload-pool=gke-react-node-project.svc.id.goog
6. Blue-Green Deployment with Flagger
bash
kubectl apply -f https://raw.githubusercontent.com/fluxcd/flagger/main/artifacts/flagger/crd.yaml
kubectl apply -f https://raw.githubusercontent.com/fluxcd/flagger/main/artifacts/flagger/flagger.yaml
Then create your Canary CRD for deployment control.

7. GitHub Actions Workflow
File: .github/workflows/deploy.yml

yaml
name: Deploy to GKE

on:
  push:
    branches:
      - develop

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Authenticate with GCP
        uses: google-github-actions/auth@v1
        with:
          credentials_json: ${{ secrets.GCP_CREDENTIALS }}

      - name: Configure kubectl
        run: |
          gcloud container clusters get-credentials my-cluster --zone us-central1-c

      - name: Deploy to GKE
        run: |
          kubectl apply -f k8s/deployment.yaml
8. Test the App in Browser
After deploying:

bash
kubectl get svc react-node-app-service
Open: http://<EXTERNAL_IP>:8080

🌿 GitFlow Branching Strategy
main: Production-ready code

develop: Active development

feature/*: Feature branches

release/*: Release prep branches

hotfix/*: Emergency fixes

Use git flow init to start.
