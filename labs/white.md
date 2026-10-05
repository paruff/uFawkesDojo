# =============================================================================

# WHITE BELT LAB FILES - Complete Lab Environments

# =============================================================================

# This file contains reference manifests for White Belt labs.
# Module 1 now uses uFawkesDevX (Docker Compose) - no Kubernetes manifests needed.
# Modules 2-4 remain Kubernetes-based (for now).

# =============================================================================

# MODULE 1 - LAB 1: Scaffold Service via Golden Path (uFawkesDevX)
#
# This lab runs against uFawkesDevX v1.0.1 (Docker Compose), not Kubernetes.
# See: white-belt/module-01-what-is-idp/lab-01/instructions.md
# The golden path template is provided by uFawkesDevX:
# https://github.com/paruff/uFawkesDevX/tree/v1.0.1/templates/python-flask-app
#
# No Kubernetes manifests are required for Module 1 Lab 1.

# =============================================================================

# MODULE 2 - LAB 2: Multi-Environment Deployment with Kustomize

# Directory: labs/module-02/

# =============================================================================

---

# labs/module-02/namespace-dev.yaml

apiVersion: v1
kind: Namespace
metadata:
  name: lab-module-2-dev
  labels:
    fawkes.io/module: "2"
    fawkes.io/environment: "dev"

---

# labs/module-02/namespace-prod.yaml

apiVersion: v1
kind: Namespace
metadata:
  name: lab-module-2-prod
  labels:
    fawkes.io/module: "2"
    fawkes.io/environment: "prod"

---

# labs/module-02/kustomize/base/kustomization.yaml

# Students will create this structure

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:

- deployment.yaml
- service.yaml

commonLabels:
  app: my-first-app

---

# labs/module-02/kustomize/base/deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-first-app
spec:
  replicas: 1 # Base configuration
  selector:
    matchLabels:
      app: my-first-app
  template:
    metadata:
      labels:
        app: my-first-app
    spec:
      containers: - name: app
        image: nginxdemos/hello:latest
        ports: - containerPort: 80

---

# labs/module-02/kustomize/base/service.yaml

apiVersion: v1
kind: Service
metadata:
  name: my-first-app
spec:
  type: ClusterIP
  selector:
    app: my-first-app
  ports:

- port: 80
  targetPort: 80

---

# labs/module-02/kustomize/overlays/dev/kustomization.yaml

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: lab-module-2-dev

bases:

- ../../base

patches:

- patch: |-
  - op: replace
    path: /spec/replicas
    value: 1
    target:
    kind: Deployment
    name: my-first-app

commonLabels:
  environment: dev

---

# labs/module-02/kustomize/overlays/prod/kustomization.yaml

apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: lab-module-2-prod

bases:

- ../../base

patches:

- patch: |-
  - op: replace
    path: /spec/replicas
    value: 3
    target:
    kind: Deployment
    name: my-first-app
- patch: |-
  - op: add
    path: /spec/template/spec/containers/0/resources
    value:
    requests:
    memory: "128Mi"
    cpu: "250m"
    limits:
    memory: "256Mi"
    cpu: "500m"
    target:
    kind: Deployment
    name: my-first-app

commonLabels:
  environment: prod

---

# labs/module-02/argocd-app-dev.yaml

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-first-app-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/student/my-first-app
    targetRevision: main
    path: k8s/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: lab-module-2-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions: - CreateNamespace=true

---

# labs/module-02/argocd-app-prod.yaml

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-first-app-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/student/my-first-app
    targetRevision: main
    path: k8s/overlays/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: lab-module-2-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions: - CreateNamespace=true

---

# =============================================================================

# MODULE 3 - LAB 3: DORA Metrics Dashboard

# Directory: labs/module-03/

# =============================================================================

---

# labs/module-03/namespace.yaml

apiVersion: v1
kind: Namespace
metadata:
  name: lab-module-3
  labels:
    fawkes.io/module: "3"

---

# labs/module-03/dora-exporter-deployment.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: dora-exporter
  namespace: monitoring
  labels:
    app: dora-exporter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dora-exporter
  template:
    metadata:
      labels:
        app: dora-exporter
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: dora-exporter
      containers: - name: exporter
        image: fawkes/dora-exporter:v1.0.0
        ports: - containerPort: 8080
        name: metrics
        env: - name: KUBERNETES_NAMESPACE
        valueFrom:
          fieldRef:
            fieldPath: metadata.namespace
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"

---

# labs/module-03/dora-exporter-service.yaml

apiVersion: v1
kind: Service
metadata:
  name: dora-exporter
  namespace: monitoring
  labels:
    app: dora-exporter
spec:
  type: ClusterIP
  selector:
    app: dora-exporter
  ports:

- port: 8080
  targetPort: 8080
  name: metrics

---

# labs/module-03/dora-exporter-servicemonitor.yaml

apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: dora-exporter
  namespace: monitoring
  labels:
    app: dora-exporter
spec:
  selector:
    matchLabels:
      app: dora-exporter
  endpoints:

- port: metrics
  interval: 30s
  path: /metrics

---

# labs/module-03/dora-exporter-rbac.yaml

# labs/module-03/dora-exporter-rbac.yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  name: dora-exporter
  namespace: monitoring

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: dora-exporter
rules:

- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods", "events"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["argoproj.io"]
  resources: ["applications"]
  verbs: ["get", "list", "watch"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dora-exporter
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: dora-exporter
subjects:

- kind: ServiceAccount
  name: dora-exporter
  namespace: monitoring

---

# labs/module-03/grafana-dashboard-configmap.yaml

apiVersion: v1
kind: ConfigMap
metadata:
  name: dora-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
  data:
    dora-metrics.json: |
    {
    "dashboard": {
    "title": "DORA Metrics",
    "panels": [
    {
    "title": "Deployment Frequency",
    "targets": [
    {
    "expr": "rate(deployments_total[7d])"
    }
    ]
    },
    {
    "title": "Lead Time for Changes",
    "targets": [
    {
    "expr": "histogram_quantile(0.95, rate(lead_time_seconds_bucket[1d]))"
    }
    ]
    },
    {
    "title": "Mean Time to Recovery",
    "targets": [
    {
    "expr": "histogram_quantile(0.95, rate(mttr_seconds_bucket[1d]))"
    }
    ]
    },
    {
    "title": "Change Failure Rate",
    "targets": [
    {
    "expr": "(rate(deployments_failed_total[7d]) / rate(deployments_total[7d])) * 100"
    }
    ]
    }
    ]
    }
    }

---

# labs/module-03/sample-app-with-annotations.yaml

# Updated deployment with Prometheus annotations

apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-first-app
  namespace: lab-module-3
  annotations:
    fawkes.io/dora-tracking: "true"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-first-app
  template:
    metadata:
      labels:
        app: my-first-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers: - name: app
        image: nginxdemos/hello:latest
        ports: - containerPort: 80
        name: http - containerPort: 8080
        name: metrics

---

# =============================================================================

# MODULE 4 - LAB: Your First Deployment (Guided)

# Directory: labs/module-04/

# =============================================================================

---

# labs/module-04/namespace.yaml

apiVersion: v1
kind: Namespace
metadata:
  name: lab-module-4
  labels:
    fawkes.io/module: "4"
    fawkes.io/belt: "white"

---

# labs/module-04/sample-app-template.yaml

# Template that students will fill in

apiVersion: apps/v1
kind: Deployment
metadata:
  name: TODO # Student fills this in
  namespace: lab-module-4
spec:
  replicas: TODO # Student sets this
  selector:
    matchLabels:
      app: TODO # Student sets this
  template:
    metadata:
      labels:
        app: TODO # Student sets this
    spec:
      containers: - name: app
        image: nginxdemos/hello:latest
        ports: - containerPort: 80

---

# labs/module-04/solution/deployment.yaml

# Reference solution (hidden from students initially)

apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: lab-module-4
  labels:
    app: my-app
    fawkes.io/lab: "module-4"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers: - name: app
        image: nginxdemos/hello:latest
        ports: - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"

---

apiVersion: v1
kind: Service
metadata:
  name: my-app
  namespace: lab-module-4
spec:
  type: ClusterIP
  selector:
    app: my-app
  ports:

- port: 80
  targetPort: 80

---

# =============================================================================

# SHARED RESOURCES - Used by multiple labs

# Directory: labs/shared/

# =============================================================================

---

# labs/shared/resource-quota.yaml

# Applied to each lab namespace for resource management

apiVersion: v1
kind: ResourceQuota
metadata:
  name: lab-quota
spec:
  hard:
    requests.cpu: "2"
    requests.memory: "4Gi"
    limits.cpu: "4"
    limits.memory: "8Gi"
    persistentvolumeclaims: "5"
    pods: "20"
    services: "10"

---

# labs/shared/network-policy.yaml

# Network isolation for lab environments

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: lab-isolation
spec:
  podSelector: {}
  policyTypes:

- Ingress
- Egress
  ingress:
- from:
  - namespaceSelector:
      matchLabels:
      fawkes.io/type: lab
      egress:
- to:
  - namespaceSelector:
      matchLabels:
      fawkes.io/type: lab
- to: # Allow DNS
  - namespaceSelector:
      matchLabels:
      name: kube-system
      ports:
  - protocol: UDP
    port: 53

---

# labs/shared/lab-rbac.yaml

# RBAC for lab users

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: lab-user
rules:

- apiGroups: ["", "apps", "networking.k8s.io"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["argoproj.io"]
  resources: ["applications"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: lab-user-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: lab-user
subjects:

- kind: Group
  name: fawkes-students
  apiGroup: rbac.authorization.k8s.io
