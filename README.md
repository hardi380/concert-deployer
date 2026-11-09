# IBM Concert Automated OpenShift Deployer

Automated, reproducible deployment of **IBM Concert** (including **Concert Protect**, **Concert Workflows**, and **Concert DataApps**) on **Red Hat OpenShift (OCP)** using Ansible.

This repository allows you to deploy the complete IBM Concert platform simply by **pasting a single YAML manifest into your OpenShift Web Console** or executing it with `oc apply -f`.

---

## 🏗️ Architecture Overview

```mermaid
flowchart TD
    subgraph OpenShift ["Red Hat OpenShift Cluster"]
        subgraph InstallerNS ["Namespace: ibm-concert-installer"]
            Secret["Secret<br/>(IBM Entitlement Key & Password)"]
            ConfigMap["ConfigMap<br/>(Git Repo URL & Settings)"]
            Job["OpenShift Job<br/>(Ansible Runner Container)"]
        end

        subgraph TargetNS ["Namespace: ibm-concert"]
            Core["IBM Concert Core Platform"]
            Protect["IBM Concert Protect<br/>(Vulnerability & Security)"]
            Workflows["IBM Concert Workflows<br/>(Automation Engine)"]
            DataApps["IBM Concert DataApps<br/>(Integrations & Ingestion)"]
            Route["OpenShift Route (HTTPS UI)"]
        end

        Storage["StorageClasses<br/>(RWO & RWX Auto-detected)"]
    end

    GitHub["GitHub Repository<br/>(Ansible Playbooks & Roles)"]

    Secret --> Job
    ConfigMap --> Job
    GitHub -.->|Clones repo at runtime| Job
    Job -->|Orchestrates Deployment| TargetNS
    Job -->|Auto-provisions| Storage
    TargetNS --> Route
```

---

## 🚀 Quick Start: 1-Step OpenShift Deployment

### Step 1: Obtain your IBM Entitlement Key
1. Log in to [MyIBM Container Software Library](https://myibm.ibm.com/products-services/containerlibrary).
2. Click **Copy key** to copy your entitlement key for `cp.icr.io`.

### Step 2: Configure the Single-YAML Manifest
Open [`deploy/ocp-job-installer.yaml`](deploy/ocp-job-installer.yaml) and update the credentials section:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: concert-deployer-credentials
  namespace: ibm-concert-installer
type: Opaque
stringData:
  # Paste your IBM Entitlement Key here:
  IBM_ENTITLEMENT_KEY: "eyJh..."

  # Optional: Initial Concert UI admin password (or leave empty to auto-generate):
  CONCERT_ADMIN_PASSWORD: "MySecurePassword123!"
```

In the `ConfigMap` section of the same file, set the URL of your GitHub repository:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: concert-deployer-config
  namespace: ibm-concert-installer
data:
  GIT_REPO_URL: "https://github.com/<your-username>/concert-deployer.git"
  GIT_BRANCH: "main"
  CONCERT_NAMESPACE: "ibm-concert"
  CONCERT_VERSION: "3.1.0"
  ENABLE_PROTECT: "true"
  ENABLE_WORKFLOWS: "true"
  ENABLE_DATAAPPS: "true"
  STORAGE_CLASS_RWO: ""  # Auto-detected if empty (e.g. ocs-storagecluster-ceph-rbd, gp3-csi)
  STORAGE_CLASS_RWX: ""  # Auto-detected if empty (e.g. ocs-storagecluster-cephfs, nfs-client)
```

### Step 3: Paste Manifest into OpenShift
You can apply the manifest in either of two ways:

#### Option A: Via OpenShift Web Console
1. Log into your OpenShift Web Console as a Cluster Administrator.
2. In the top-right navigation bar, click the **`+` (Import YAML)** button.
3. Copy the full content of [`deploy/ocp-job-installer.yaml`](deploy/ocp-job-installer.yaml), paste it into the editor, and click **Create**.

#### Option B: Via OpenShift CLI (`oc`)
```bash
oc apply -f deploy/ocp-job-installer.yaml
```

---

## 📊 Monitoring Installation Progress

Follow the live installation logs in OpenShift:

```bash
oc logs -f job/ibm-concert-deployer -n ibm-concert-installer
```

Once the installation completes, the job will output the final access details:

```text
================================================================================
              🎉 IBM CONCERT DEPLOYMENT ON OPENSHIFT COMPLETED                  
================================================================================
Console URL:       https://ibm-concert-ui-ibm-concert.apps.mycluster.example.com
Admin Username:    concert-admin
Admin Password:    <Generated-Or-Configured-Password>
Namespace:         ibm-concert
Version:           3.1.0
StorageClass RWO:  ocs-storagecluster-ceph-rbd
StorageClass RWX:  ocs-storagecluster-cephfs
--------------------------------------------------------------------------------
Installed Components:
  - IBM Concert Core:      READY
  - IBM Concert Protect:   ENABLED
  - IBM Concert Workflows: ENABLED
  - IBM Concert DataApps:  ENABLED
--------------------------------------------------------------------------------
Active Pods:       14 / 14 running
================================================================================
```

---

## ⚙️ Configuration Reference

| Parameter | Default | Description |
| :--- | :--- | :--- |
| `IBM_ENTITLEMENT_KEY` | *(Required)* | IBM Entitlement Key to pull images from `cp.icr.io`. |
| `GIT_REPO_URL` | *(Required)* | GitHub URL of this repository containing Ansible playbooks. |
| `GIT_BRANCH` | `main` | Git branch to clone and execute. |
| `CONCERT_NAMESPACE` | `ibm-concert` | Target namespace for IBM Concert deployment. |
| `CONCERT_VERSION` | `3.1.0` | IBM Concert release version. |
| `CONCERT_ADMIN_PASSWORD` | `""` | Administrator password (auto-generated if empty). |
| `ENABLE_PROTECT` | `true` | Install IBM Concert Protect (security & vulnerability management). |
| `ENABLE_WORKFLOWS` | `true` | Install IBM Concert Workflows engine. |
| `ENABLE_DATAAPPS` | `true` | Install IBM Concert DataApps (ingestion & integrations). |
| `STORAGE_CLASS_RWO` | `""` | Block/RWO storage class (auto-detected if blank). |
| `STORAGE_CLASS_RWX` | `""` | File/RWX storage class (auto-detected if blank). |

---

## 💻 Alternative: Running Locally via CLI

If you prefer to run the Ansible deployment from your local workstation connected to OpenShift:

### 1. Prerequisites
- `oc` CLI logged into your cluster (`oc login`)
- Python 3.9+ with `pip`
- Ansible Core 2.16+

### 2. Install Dependencies
```bash
pip install -r requirements.txt
ansible-galaxy collection install -r requirements.yml
```

### 3. Run the Playbook
```bash
export IBM_ENTITLEMENT_KEY="your-key-here"
./scripts/run-local.sh
```

Or run Ansible directly:
```bash
ansible-playbook -i inventory/localhost.yml playbooks/install_concert.yml \
  -e "ibm_entitlement_key=${IBM_ENTITLEMENT_KEY}" \
  -e "enable_concert_protect=true" \
  -e "enable_concert_workflows=true" \
  -e "enable_concert_dataapps=true"
```

---

## 🔍 Verification & Diagnostics

To check the deployment status anytime:
```bash
ansible-playbook -i inventory/localhost.yml playbooks/verify_concert.yml
```

To list all running Concert pods:
```bash
oc get pods -n ibm-concert
```

To view the public Route:
```bash
oc get routes -n ibm-concert
```

---

## 🧹 Uninstallation

To completely remove IBM Concert and its namespace from the cluster:
```bash
ansible-playbook -i inventory/localhost.yml playbooks/uninstall_concert.yml
```
Or delete the installer job namespace:
```bash
oc delete namespace ibm-concert-installer
oc delete namespace ibm-concert
```

---

## 📁 Repository Structure

```text
concert-deployer/
├── ansible.cfg                    # Ansible configuration
├── requirements.yml               # Ansible Galaxy collections (k8s, openshift, community)
├── requirements.txt               # Python package dependencies
├── Containerfile                  # Container image definition for runner
├── deploy/
│   ├── ocp-job-installer.yaml     # Single-file copy-paste OpenShift manifest
│   └── ocp-job-installer-template.yaml # OpenShift Web Console Template Wizard
├── inventory/
│   ├── localhost.yml              # Local inventory target
│   └── group_vars/
│       └── all.yml                # Configuration parameters & defaults
├── playbooks/
│   ├── install_concert.yml        # Main orchestration playbook
│   ├── verify_concert.yml         # Status & health verification playbook
│   └── uninstall_concert.yml      # Cleanup & uninstaller playbook
├── roles/
│   ├── prerequisites/             # Storage, namespace, and RBAC discovery
│   ├── ibm_entitlement/           # Container registry pull secret creation
│   ├── concert_core/              # Core platform deployment & OpenShift Job
│   ├── concert_protect/           # Protect security components & policies
│   ├── concert_workflows/         # Automation workflows engine
│   ├── concert_dataapps/          # Ingestion & DataApps configuration
│   └── post_install/              # Route discovery & login credentials summary
└── scripts/
    └── run-local.sh               # Local CLI helper script
```
