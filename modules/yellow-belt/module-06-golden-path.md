# Fawkes Dojo Module 6: Building Golden Path Pipelines

> ⚠️ **This module teaches Jenkins Shared Libraries and pipeline templates, which are replaced in Dojo 0.4 by uFawkesPipe (Woodpecker CI and the `.fawkespipe.yml` contract).**
> The Yellow Belt CI/CD content is being migrated to Woodpecker.
> See [uFawkesPipe](https://github.com/paruff/uFawkesPipe) and the [Dojo 0.4 release plan](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/plan.md#phase-4--ufawkespipe-v200--dojo-04-gate-ac-pipe-01).

## 🎯 Module Overview

**Belt Level**: 🟡 Yellow Belt - CI/CD Mastery
**Module**: 2 of 4 (Yellow Belt)
**Duration**: 60 minutes
**Difficulty**: Intermediate
**Prerequisites**:

- Module 5: CI Fundamentals complete
- Basic Groovy syntax understanding
- Experience with at least one programming language
- Jenkins pipeline creation experience

---

## 📚 Learning Objectives

By the end of this module, you will:

1. ✅ Understand the concept of "Golden Path" in platform engineering
2. ✅ Create reusable Jenkins Shared Libraries
3. ✅ Build pipeline templates for multiple languages (Java, Python, Node.js)
4. ✅ Implement pipeline optimization techniques
5. ✅ Configure build caching for faster builds
6. ✅ Use parallel execution to reduce build time
7. ✅ Measure and improve pipeline performance

**DORA Capabilities Addressed**:

- ✓ CD1: Version control for all production artifacts
- ✓ CD4: Trunk-based development
- ✓ Continuous Integration (advanced)
- ✓ Code Review

---

## 📖 Part 1: What is a Golden Path?

### The Problem: Pipeline Proliferation

**Without Golden Paths**:

```
Team A: Creates Java pipeline (500 lines)
Team B: Creates Java pipeline (480 lines, slightly different)
Team C: Creates Java pipeline (520 lines, more differences)
Team D: Creates Python pipeline from scratch
Team E: Copies Team A's pipeline, modifies it

Result:
- 50 similar but different pipelines
- Security update needed → Update 50 pipelines manually
- New best practice → Adoption takes months
- No consistency across teams
- High maintenance burden
```

### Golden Path Solution

> **"The easiest path should also be the best path"**

```
Golden Path Template (Java)
      ↓
   Maintained by Platform Team
      ↓
   Used by 50 teams
      ↓
   Update once → All teams benefit
      ↓
   Consistency + Best Practices Built-In
```

**Golden Path Characteristics**:

1. **Opinionated**: Embeds best practices by default
2. **Easy to Use**: 5-10 lines to get started
3. **Batteries Included**: Security, testing, quality gates built-in
4. **Customizable**: Escape hatches for edge cases
5. **Self-Service**: Teams can use without platform team help
6. **Maintained**: Platform team keeps it updated

### Golden Path in Practice

**Instead of this** (200-line Jenkinsfile):

```groovy
pipeline {
    agent { kubernetes { yaml '''...''' } }
    stages {
        stage('Checkout') { ... }
        stage('Build') { ... }
        stage('Test') { ... }
        stage('Security Scan') { ... }
        stage('Quality Gate') { ... }
        stage('Package') { ... }
        stage('Publish') { ... }
    }
    post { ... }
}
```

**Teams write this** (10-line Jenkinsfile):

```groovy
@Library('fawkes-pipelines') _

goldenPathJava {
    gitRepo = 'https://github.com/myteam/myapp.git'
    javaVersion = '17'
    skipTests = false
}
```

**Result**: 95% less boilerplate, 100% best practices

---

## 🏗️ Part 2: Jenkins Shared Libraries

### What are Shared Libraries?

Jenkins Shared Libraries are reusable Groovy code that can be imported into any Jenkinsfile.

**Benefits**:

- 🎯 **DRY Principle**: Don't Repeat Yourself
- 🔒 **Security**: Centralized credential management
- 📦 **Versioning**: Tag releases, rollback if needed
- 🧪 **Testable**: Unit test your pipeline logic
- 📚 **Documentation**: Single source of truth

### Shared Library Structure

```
fawkes-pipeline-library/
├── vars/                          # Global variables (pipeline steps)
│   ├── goldenPathJava.groovy     # Java pipeline template
│   ├── goldenPathPython.groovy   # Python pipeline template
│   ├── goldenPathNode.groovy     # Node.js pipeline template
│   └── notifySlack.groovy        # Slack notification helper
├── src/                           # Shared classes and utilities
│   └── com/
│       └── fawkes/
│           └── pipeline/
│               ├── Docker.groovy
│               ├── Maven.groovy
│               └── Security.groovy
├── resources/                     # Non-Groovy resources
│   ├── pod-templates/
│   │   ├── java-agent.yaml
│   │   ├── python-agent.yaml
│   │   └── node-agent.yaml
│   └── scripts/
│       └── docker-build.sh
└── README.md
```

---

## 🛠️ Part 3: Hands-On Lab - Create Your First Shared Library — *not built yet*

### Step 1: Set Up Shared Library Repository

```bash
# Create new Git repository
mkdir fawkes-pipeline-library
cd fawkes-pipeline-library

# Create directory structure
mkdir -p vars
mkdir -p src/com/fawkes/pipeline
mkdir -p resources/pod-templates

# Initialize Git
git init
```

### Step 2: Create Java Golden Path

Create `vars/goldenPathJava.groovy`:

```groovy
#!/usr/bin/env groovy

def call(Map config = [:]) {
    // Default configuration
    def defaults = [
        gitRepo: '',
        gitBranch: 'main',
        gitCredentials: 'github-credentials',
        javaVersion: '17',
        mavenVersion: '3.8',
        skipTests: false,
        runSecurityScan: true,
        dockerRegistry: 'harbor.fawkes.internal',
        slackChannel: '#builds'
    ]

    // Merge user config with defaults
    config = defaults + config

    // Validate required parameters
    if (!config.gitRepo) {
        error("gitRepo is required")
    }

    pipeline {
        agent {
            kubernetes {
                yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
    app: ${env.JOB_NAME}
spec:
  containers:
  - name: maven
    image: maven:${config.mavenVersion}-openjdk-${config.javaVersion}
    command: ['sleep']
    args: ['infinity']
    resources:
      requests:
        memory: "2Gi"
        cpu: "1000m"
      limits:
        memory: "4Gi"
        cpu: "2000m"
  - name: docker
    image: docker:24-dind
    securityContext:
      privileged: true
    command: ['sleep']
    args: ['infinity']
"""
            }
        }

        options {
            timestamps()
            timeout(time: 15, unit: 'MINUTES')
            buildDiscarder(logRotator(numToKeepStr: '10'))
        }

        environment {
            APP_NAME = "${env.JOB_NAME}".split('/')[0]
            BUILD_VERSION = "${env.BUILD_NUMBER}"
            GIT_COMMIT_SHORT = sh(
                script: "git rev-parse --short HEAD",
                returnStdout: true
            ).trim()
        }

        stages {
            stage('Checkout') {
                steps {
                    script {
                        echo "🔄 Checking out ${config.gitRepo}..."
                        git branch: config.gitBranch,
                            url: config.gitRepo,
                            credentialsId: config.gitCredentials
                    }
                }
            }

            stage('Build') {
                steps {
                    container('maven') {
                        script {
                            echo "🔨 Building application..."
                            sh """
                                mvn clean compile \
                                    -DskipTests \
                                    -B \
                                    --batch-mode \
                                    --no-transfer-progress
                            """
                        }
                    }
                }
            }

            stage('Test') {
                when {
                    expression { !config.skipTests }
                }
                steps {
                    container('maven') {
                        script {
                            echo "🧪 Running tests..."
                            sh """
                                mvn test \
                                    -B \
                                    --batch-mode \
                                    --no-transfer-progress
                            """
                        }
                    }
                }
                post {
                    always {
                        junit 'target/surefire-reports/**/*.xml'
                    }
                }
            }

            stage('Security Scan') {
                when {
                    expression { config.runSecurityScan }
                }
                steps {
                    container('maven') {
                        script {
                            echo "🔒 Running security scan..."
                            sh """
                                mvn dependency-check:check \
                                    -DfailBuildOnCVSS=7
                            """
                        }
                    }
                }
            }

            stage('Package') {
                steps {
                    container('maven') {
                        script {
                            echo "📦 Packaging application..."
                            sh """
                                mvn package \
                                    -DskipTests \
                                    -B \
                                    --batch-mode \
                                    --no-transfer-progress
                            """
                        }
                    }
                }
            }

            stage('Docker Build') {
                steps {
                    container('docker') {
                        script {
                            echo "🐳 Building Docker image..."
                            def imageName = "${config.dockerRegistry}/${env.APP_NAME}"
                            def imageTag = "${env.BUILD_VERSION}-${env.GIT_COMMIT_SHORT}"

                            sh """
                                docker build \
                                    -t ${imageName}:${imageTag} \
                                    -t ${imageName}:latest \
                                    .
                            """

                            // Store for later stages
                            env.DOCKER_IMAGE = "${imageName}:${imageTag}"
                        }
                    }
                }
            }

            stage('Publish') {
                steps {
                    container('docker') {
                        script {
                            echo "📤 Publishing Docker image..."
                            withCredentials([
                                usernamePassword(
                                    credentialsId: 'harbor-credentials',
                                    usernameVariable: 'DOCKER_USER',
                                    passwordVariable: 'DOCKER_PASS'
                                )
                            ]) {
                                sh """
                                    echo \$DOCKER_PASS | docker login ${config.dockerRegistry} -u \$DOCKER_USER --password-stdin
                                    docker push ${env.DOCKER_IMAGE}
                                    docker push ${config.dockerRegistry}/${env.APP_NAME}:latest
                                """
                            }
                        }
                    }
                }
            }
        }

        post {
            success {
                script {
                    notifySlack(
                        channel: config.slackChannel,
                        color: 'good',
                        message: "✅ Build #${env.BUILD_NUMBER} succeeded\n📦 Image: ${env.DOCKER_IMAGE}"
                    )
                }
            }

            failure {
                script {
                    notifySlack(
                        channel: config.slackChannel,
                        color: 'danger',
                        message: "❌ Build #${env.BUILD_NUMBER} failed\n🔗 ${env.BUILD_URL}"
                    )
                }
            }

            always {
                cleanWs()
            }
        }
    }
}
```

### Step 3: Create Helper Functions

Create `vars/notifySlack.groovy`:

```groovy
#!/usr/bin/env groovy

def call(Map config = [:]) {
    if (!config.channel || !config.message) {
        error("channel and message are required")
    }

    def color = config.color ?: 'warning'

    try {
        slackSend(
            channel: config.channel,
            color: color,
            message: config.message,
            tokenCredentialId: 'slack-token'
        )
    } catch (Exception e) {
        echo "Warning: Failed to send Slack notification: ${e.message}"
        // Don't fail build if notification fails
    }
}
```

### Step 4: Configure in Jenkins

**Add Shared Library to Jenkins**:

1. Go to Jenkins → Manage Jenkins → Configure System
2. Scroll to "Global Pipeline Libraries"
3. Click "Add"
4. Configure:
   - Name: `fawkes-pipelines`
   - Default version: `main`
   - Retrieval method: "Modern SCM"
   - Source Code Management: Git
   - Project Repository: `https://github.com/fawkes/pipeline-library.git`
   - Credentials: (if private repo)
5. ✅ Check "Load implicitly" (makes it available to all pipelines)
6. Save

### Step 5: Use Golden Path in Your Project

Create `Jenkinsfile` in your application repository:

```groovy
@Library('fawkes-pipelines') _

goldenPathJava {
    gitRepo = 'https://github.com/myteam/my-spring-boot-app.git'
    javaVersion = '17'
    skipTests = false
    runSecurityScan = true
    slackChannel = '#my-team'
}
```

**That's it!** 6 lines instead of 200+.

---

## 📊 Part 4: Creating Templates for Multiple Languages

### Python Golden Path

Create `vars/goldenPathPython.groovy`:

```groovy
#!/usr/bin/env groovy

def call(Map config = [:]) {
    def defaults = [
        gitRepo: '',
        gitBranch: 'main',
        pythonVersion: '3.11',
        skipTests: false,
        runLinting: true,
        dockerRegistry: 'harbor.fawkes.internal'
    ]

    config = defaults + config

    if (!config.gitRepo) {
        error("gitRepo is required")
    }

    pipeline {
        agent {
            kubernetes {
                yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: python
    image: python:${config.pythonVersion}-slim
    command: ['sleep']
    args: ['infinity']
  - name: docker
    image: docker:24-dind
    securityContext:
      privileged: true
    command: ['sleep']
    args: ['infinity']
"""
            }
        }

        options {
            timestamps()
            timeout(time: 15, unit: 'MINUTES')
        }

        stages {
            stage('Checkout') {
                steps {
                    git branch: config.gitBranch,
                        url: config.gitRepo
                }
            }

            stage('Setup') {
                steps {
                    container('python') {
                        sh '''
                            python -m pip install --upgrade pip
                            pip install -r requirements.txt
                        '''
                    }
                }
            }

            stage('Lint') {
                when {
                    expression { config.runLinting }
                }
                steps {
                    container('python') {
                        sh '''
                            pip install flake8 black
                            flake8 . --max-line-length=88
                            black --check .
                        '''
                    }
                }
            }

            stage('Test') {
                when {
                    expression { !config.skipTests }
                }
                steps {
                    container('python') {
                        sh '''
                            pip install pytest pytest-cov
                            pytest --cov=. --cov-report=xml --cov-report=html
                        '''
                    }
                }
                post {
                    always {
                        publishHTML([
                            allowMissing: false,
                            alwaysLinkToLastBuild: true,
                            keepAll: true,
                            reportDir: 'htmlcov',
                            reportFiles: 'index.html',
                            reportName: 'Coverage Report'
                        ])
                    }
                }
            }

            stage('Docker Build & Push') {
                steps {
                    container('docker') {
                        script {
                            def imageName = "${config.dockerRegistry}/${env.JOB_NAME}"
                            def imageTag = "${env.BUILD_NUMBER}"

                            sh """
                                docker build -t ${imageName}:${imageTag} .
                                docker push ${imageName}:${imageTag}
                            """
                        }
                    }
                }
            }
        }
    }
}
```

### Node.js Golden Path

Create `vars/goldenPathNode.groovy`:

```groovy
#!/usr/bin/env groovy

def call(Map config = [:]) {
    def defaults = [
        gitRepo: '',
        gitBranch: 'main',
        nodeVersion: '20',
        skipTests: false,
        runLinting: true,
        packageManager: 'npm'  // or 'yarn', 'pnpm'
    ]

    config = defaults + config

    pipeline {
        agent {
            kubernetes {
                yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: node
    image: node:${config.nodeVersion}-alpine
    command: ['sleep']
    args: ['infinity']
  - name: docker
    image: docker:24-dind
    securityContext:
      privileged: true
    command: ['sleep']
    args: ['infinity']
"""
            }
        }

        stages {
            stage('Checkout') {
                steps {
                    git branch: config.gitBranch,
                        url: config.gitRepo
                }
            }

            stage('Install Dependencies') {
                steps {
                    container('node') {
                        script {
                            def installCmd = config.packageManager == 'npm' ? 'npm ci' :
                                           config.packageManager == 'yarn' ? 'yarn install --frozen-lockfile' :
                                           'pnpm install --frozen-lockfile'
                            sh installCmd
                        }
                    }
                }
            }

            stage('Lint') {
                when {
                    expression { config.runLinting }
                }
                steps {
                    container('node') {
                        sh "${config.packageManager} run lint"
                    }
                }
            }

            stage('Test') {
                when {
                    expression { !config.skipTests }
                }
                steps {
                    container('node') {
                        sh "${config.packageManager} test"
                    }
                }
            }

            stage('Build') {
                steps {
                    container('node') {
                        sh "${config.packageManager} run build"
                    }
                }
            }

            stage('Docker Build & Push') {
                steps {
                    container('docker') {
                        script {
                            def imageName = "${env.JOB_NAME}"
                            sh """
                                docker build -t ${imageName}:${env.BUILD_NUMBER} .
                                docker push ${imageName}:${env.BUILD_NUMBER}
                            """
                        }
                    }
                }
            }
        }
    }
}
```

---

## ⚡ Part 5: Pipeline Optimization Techniques

### Technique 1: Parallel Execution

Run independent stages simultaneously:

```groovy
stage('Parallel Quality Checks') {
    parallel {
        stage('Unit Tests') {
            steps {
                container('maven') {
                    sh 'mvn test'
                }
            }
        }
        stage('Linting') {
            steps {
                container('maven') {
                    sh 'mvn checkstyle:check'
                }
            }
        }
        stage('Security Scan') {
            steps {
                container('maven') {
                    sh 'mvn dependency-check:check'
                }
            }
        }
    }
}
```

**Before**: 6 minutes (2min + 2min + 2min sequential)
**After**: 2 minutes (all run in parallel)
**Improvement**: 3x faster ⚡

### Technique 2: Build Caching

Cache Maven dependencies between builds:

```groovy
pipeline {
    agent {
        kubernetes {
            yaml '''
spec:
  containers:
  - name: maven
    image: maven:3.8-openjdk-17
    volumeMounts:
    - name: maven-cache
      mountPath: /root/.m2
  volumes:
  - name: maven-cache
    persistentVolumeClaim:
      claimName: maven-cache-pvc
'''
        }
    }
}
```

**Before**: 3 minutes downloading dependencies every build
**After**: 10 seconds (cached)
**Improvement**: 18x faster on dependencies ⚡

### Technique 3: Incremental Builds

Only rebuild what changed:

```groovy
stage('Incremental Build') {
    steps {
        script {
            def changedFiles = sh(
                script: "git diff --name-only HEAD~1",
                returnStdout: true
            ).trim()

            if (changedFiles.contains('src/')) {
                echo "Source changed, full build"
                sh 'mvn clean package'
            } else if (changedFiles.contains('pom.xml')) {
                echo "Dependencies changed, rebuild"
                sh 'mvn clean package'
            } else {
                echo "Only docs changed, skip build"
                currentBuild.result = 'SUCCESS'
                return
            }
        }
    }
}
```

### Technique 4: Smarter Test Execution

Run only affected tests:

```groovy
stage('Smart Testing') {
    steps {
        script {
            // Use tools like Laika or Maven Test Selection
            sh '''
                mvn test \
                    -Dtest=$(git diff --name-only HEAD~1 | \
                             grep 'src/test' | \
                             sed 's/.*\\/\\(.*\\)\\.java/\\1/' | \
                             tr '\\n' ',')
            '''
        }
    }
}
```

### Technique 5: Resource Optimization

Right-size your build agents:

```groovy
// Small builds
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"

// Medium builds
resources:
  requests:
    memory: "2Gi"
    cpu: "1000m"
  limits:
    memory: "4Gi"
    cpu: "2000m"

// Large builds
resources:
  requests:
    memory: "8Gi"
    cpu: "4000m"
  limits:
    memory: "16Gi"
    cpu: "8000m"
```

**Benefit**: Faster scheduling, lower costs, better resource utilization

---

## 📈 Part 6: Measuring Pipeline Performance

### Build Time Metrics

Track and visualize build performance:

```groovy
post {
    always {
        script {
            // Calculate stage durations
            def stageDurations = [:]
            currentBuild.rawBuild.getActions(FlowExecutionAction).each { action ->
                action.getNodes().each { node ->
                    if (node.displayName != null) {
                        def duration = node.getDurationMillis() / 1000
                        stageDurations[node.displayName] = duration
                    }
                }
            }

            // Send to Prometheus
            stageDurations.each { stage, duration ->
                sh """
                    curl -X POST http://prometheus-pushgateway:9091/metrics/job/jenkins/stage/${stage} \\
                        --data-binary @- <<EOF
# TYPE jenkins_stage_duration_seconds gauge
jenkins_stage_duration_seconds{job="${env.JOB_NAME}",stage="${stage}"} ${duration}
EOF
                """
            }
        }
    }
}
```

### Key Metrics to Track

```promql
# Average build time
avg(jenkins_build_duration_seconds{job="my-app"})

# Build success rate
sum(rate(jenkins_build_result{result="SUCCESS"}[7d])) /
sum(rate(jenkins_build_result[7d])) * 100

# Slowest pipeline stages
topk(5, avg(jenkins_stage_duration_seconds) by (stage))

# Build time trend
rate(jenkins_build_duration_seconds[1d])
```

### Create Grafana Dashboard

```json
{
  "dashboard": {
    "title": "Pipeline Performance",
    "panels": [
      {
        "title": "Average Build Time",
        "targets": [
          {
            "expr": "avg(jenkins_build_duration_seconds) by (job)"
          }
        ]
      },
      {
        "title": "Build Success Rate",
        "targets": [
          {
            "expr": "sum(rate(jenkins_build_result{result='SUCCESS'}[7d])) / sum(rate(jenkins_build_result[7d])) * 100"
          }
        ]
      }
    ]
  }
}
```

---

## 💪 Part 7: Practical Exercise

### Exercise: Create a Multi-Language Golden Path

**Objective**: Build a shared library that supports Java, Python, and Node.js

**Requirements**:

1. Create `vars/goldenPath.groovy` that auto-detects language
2. Support configuration for each language
3. Include parallel testing and linting
4. Implement build caching
5. Add performance metrics
6. Create comprehensive documentation

**Starter Template**:

```groovy
// vars/goldenPath.groovy
def call(Map config = [:]) {
    // Auto-detect language
    def language = detectLanguage()

    echo "🔍 Detected language: ${language}"

    switch(language) {
        case 'java':
            goldenPathJava(config)
            break
        case 'python':
            goldenPathPython(config)
            break
        case 'node':
            goldenPathNode(config)
            break
        default:
            error("Unsupported language: ${language}")
    }
}

def detectLanguage() {
    // TODO: Implement language detection
    // Check for pom.xml, requirements.txt, package.json
}
```

**Validation Criteria**:

- [ ] Auto-detects language correctly
- [ ] All three language templates work
- [ ] Build time <8 minutes for sample apps
- [ ] Caching reduces build time by 50%+
- [ ] Metrics sent to Prometheus
- [ ] Documentation includes usage examples

---

## 🎓 Part 8: Knowledge Check

### Quiz Questions

1. **What is a "Golden Path" in platform engineering?**

   - [ ] The fastest build configuration
   - [x] An opinionated, easy-to-use template with best practices built-in
   - [ ] A deployment strategy
   - [ ] A security scanning tool

2. **Where do you put reusable pipeline steps in a Shared Library?**

   - [ ] src/ directory
   - [x] vars/ directory
   - [ ] resources/ directory
   - [ ] lib/ directory

3. **What is the benefit of parallel execution in pipelines?**

   - [ ] Uses less resources
   - [ ] More reliable
   - [x] Reduces total build time
   - [ ] Easier to debug

4. **How can you cache Maven dependencies between builds?**

   - [ ] Use a faster Maven mirror
   - [x] Mount a persistent volume to /root/.m2
   - [ ] Download dependencies manually
   - [ ] Skip dependency resolution

5. **What should you do with build performance metrics?**

   - [ ] Ignore them
   - [ ] Only check when builds are slow
   - [x] Send to Prometheus and visualize in Grafana
   - [ ] Store in Jenkins only

6. **What's the recommended maximum build time?**

   - [ ] 30 minutes
   - [x] 10 minutes
   - [ ] 1 hour
   - [ ] 5 minutes

7. **Which stage can typically be parallelized?**

   - [ ] Checkout
   - [ ] Build
   - [x] Tests and linting
   - [ ] Docker push

8. **What's the main benefit of Pipeline as Code?**
   - [x] Version controlled, code reviewed, consistent
   - [ ] Faster builds
   - [ ] Less disk space
   - [ ] Better UI

**Answers**: 1-B, 2-B, 3-C, 4-B, 5-C, 6-B, 7-C, 8-A

---

## 🎯 Part 9: Module Summary & Next Steps

### What You Learned

✅ **Golden Paths**: Opinionated templates that make easy = best
✅ **Shared Libraries**: Reusable pipeline code in `vars/` and `src/`
✅ **Multi-Language Support**: Java, Python, Node.js templates
✅ **Optimization**: Parallel execution, caching, incremental builds
✅ **Performance Metrics**: Track and improve build times
✅ **Best Practices**: DRY, testable, maintainable pipelines

### DORA Capabilities Achieved

- ✅ **CD1**: Version control for production artifacts (advanced)
- ✅ **CD4**: Trunk-based development support
- ✅ **Code Review**: Pipeline changes reviewed like code

### Key Takeaways

1. **Golden Paths reduce toil** - Write once, use everywhere
2. **Shared Libraries enable reuse** - Don't copy-paste pipelines
3. **Optimization matters** - 10-minute builds vs 30-minute builds = happier developers
4. **Measure everything** - Can't improve what you don't measure
5. **Maintainability > Brevity** - Readable pipelines are better than clever pipelines

### Real-World Impact

"After implementing Golden Path pipelines:

- **Pipeline creation time**: 2 days → 10 minutes
- **Average build time**: 25 minutes → 7 minutes
- **Pipelines maintained**: 50 → 3 templates
- **Security update rollout**: 2 weeks → 1 day

Our developers now spend time building features, not maintaining pipelines."

- *Platform Engineering Team, Tech Company*

---

## 📚 Additional Resources

### Documentation

- [Jenkins Shared Libraries](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)
- [Pipeline Best Practices](https://www.jenkins.io/doc/book/pipeline/pipeline-best-practices/)
- [Kubernetes Plugin Guide](https://plugins.jenkins.io/kubernetes/)

### Examples

- [Fabric8 Pipeline Library](https://github.com/fabric8io/fabric8-pipeline-library)
- [CloudBees Pipeline Template Catalog](https://github.com/cloudbees/pipeline-model-definition-plugin/wiki/Defining-Declarative-Pipelines)

### Community

- [Jenkins Community Forums](https://community.jenkins.io/)
- [GitHub Discussions](https://github.com/paruff/uFawkesDojo/discussions) - `#dojo-yellow-belt` category

---

## 🏅 Module Completion

### Assessment Checklist

- [ ] **Conceptual Understanding**

  - [ ] Explain Golden Path philosophy
  - [ ] Describe Shared Library structure
  - [ ] Understand pipeline optimization techniques

- [ ] **Practical Skills**

  - [ ] Create a Shared Library repository
  - [ ] Build Golden Path template for at least one language
  - [ ] Implement parallel execution
  - [ ] Configure build caching
  - [ ] Add performance metrics collection

- [ ] **Hands-On Lab**

  - [ ] Create reusable pipeline template
  - [ ] Reduce build time by 50%+ through optimization
  - [ ] Successfully use template in 3 different projects

- [ ] **Quiz**
  - [ ] Score 80% or higher (6/8 questions)

### Certification Credit

Upon completion, you earn:

- **5 points** toward Yellow Belt certification (50% complete)
- **Badge**: "Golden Path Architect"
- **Skill Unlocked**: Shared Library Development

---

## 🎖️ Yellow Belt Progress

```
Yellow Belt: CI/CD Mastery
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Module 5: CI Fundamentals        ████████░░░░ 25% ✓
Module 6: Golden Path Pipelines  ████████░░░░ 50% ✓
Module 7: Security & Quality     ░░░░░░░░░░░░  0%
Module 8: Artifact Management    ░░░░░░░░░░░░  0%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Halfway to Yellow Belt!** 🎉

**Next Module Preview**: Module 7 - Security Scanning & Quality Gates (SonarQube, Trivy, dependency scanning)

---

## 📖 Appendix A: Complete Shared Library Example

### Full Repository Structure

```
fawkes-pipeline-library/
├── vars/
│   ├── goldenPathJava.groovy
│   ├── goldenPathPython.groovy
│   ├── goldenPathNode.groovy
│   ├── goldenPath.groovy           # Auto-detect wrapper
│   ├── notifySlack.groovy
│   ├── runSecurityScan.groovy
│   └── deployToKubernetes.groovy
├── src/
│   └── com/
│       └── fawkes/
│           └── pipeline/
│               ├── Docker.groovy
│               ├── Git.groovy
│               ├── Maven.groovy
│               ├── Kubernetes.groovy
│               └── Security.groovy
├── resources/
│   ├── pod-templates/
│   │   ├── java-17.yaml
│   │   ├── python-311.yaml
│   │   ├── node-20.yaml
│   │   └── docker-dind.yaml
│   ├── scripts/
│   │   ├── docker-build.sh
│   │   ├── security-scan.sh
│   │   └── promote-artifact.sh
│   └── config/
│       ├── sonarqube.properties
│       └── checkstyle.xml
├── test/
│   └── groovy/
│       └── com/
│           └── fawkes/
│               └── pipeline/
│                   └── DockerTest.groovy
├── docs/
│   ├── README.md
│   ├── CONTRIBUTING.md
│   └── examples/
│       ├── java-example.md
│       ├── python-example.md
│       └── node-example.md
├── Jenkinsfile                     # For testing the library itself
└── VERSION
```

### Example: Advanced Docker Helper Class

Create `src/com/fawkes/pipeline/Docker.groovy`:

```groovy
package com.fawkes.pipeline

class Docker implements Serializable {
    def script

    Docker(script) {
        this.script = script
    }

    def build(Map config) {
        def imageName = config.imageName ?: script.env.JOB_NAME
        def imageTag = config.imageTag ?: script.env.BUILD_NUMBER
        def dockerfile = config.dockerfile ?: 'Dockerfile'
        def context = config.context ?: '.'
        def buildArgs = config.buildArgs ?: [:]

        script.echo "🐳 Building Docker image: ${imageName}:${imageTag}"

        def buildArgsStr = buildArgs.collect { k, v -> "--build-arg ${k}=${v}" }.join(' ')

        script.sh """
            docker build \
                -f ${dockerfile} \
                -t ${imageName}:${imageTag} \
                ${buildArgsStr} \
                ${context}
        """

        return "${imageName}:${imageTag}"
    }

    def push(String image, Map config = [:]) {
        def registry = config.registry ?: 'harbor.fawkes.internal'
        def credentialsId = config.credentialsId ?: 'harbor-credentials'

        script.echo "📤 Pushing image: ${image}"

        script.withCredentials([
            script.usernamePassword(
                credentialsId: credentialsId,
                usernameVariable: 'DOCKER_USER',
                passwordVariable: 'DOCKER_PASS'
            )
        ]) {
            script.sh """
                echo \$DOCKER_PASS | docker login ${registry} -u \$DOCKER_USER --password-stdin
                docker push ${image}
            """
        }
    }

    def scan(String image, Map config = [:]) {
        def severity = config.severity ?: 'HIGH,CRITICAL'
        def exitCode = config.exitCode ?: 1

        script.echo "🔒 Scanning image for vulnerabilities: ${image}"

        script.sh """
            trivy image \
                --severity ${severity} \
                --exit-code ${exitCode} \
                --no-progress \
                ${image}
        """
    }

    def tag(String sourceImage, String targetTag) {
        script.echo "🏷️ Tagging image: ${sourceImage} → ${targetTag}"
        script.sh "docker tag ${sourceImage} ${targetTag}"
    }
}
```

### Using the Helper Class

In `vars/goldenPathJava.groovy`:

```groovy
@Library('fawkes-pipelines') _
import com.fawkes.pipeline.Docker

def call(Map config = [:]) {
    pipeline {
        agent { kubernetes { yaml '...' } }

        stages {
            // ... build stages ...

            stage('Docker Operations') {
                steps {
                    container('docker') {
                        script {
                            def docker = new Docker(this)

                            // Build
                            def image = docker.build(
                                imageName: "${config.dockerRegistry}/${env.APP_NAME}",
                                imageTag: "${env.BUILD_NUMBER}",
                                buildArgs: [
                                    'BUILD_DATE': new Date().format('yyyy-MM-dd'),
                                    'VCS_REF': env.GIT_COMMIT
                                ]
                            )

                            // Scan
                            docker.scan(image, severity: 'CRITICAL')

                            // Tag
                            docker.tag(image, "${config.dockerRegistry}/${env.APP_NAME}:latest")

                            // Push
                            docker.push(image)
                            docker.push("${config.dockerRegistry}/${env.APP_NAME}:latest")
                        }
                    }
                }
            }
        }
    }
}
```

---

## 📖 Appendix B: Testing Shared Libraries

### Unit Testing with Spock

Create `test/groovy/com/fawkes/pipeline/DockerTest.groovy`:

```groovy
package com.fawkes.pipeline

import spock.lang.Specification

class DockerTest extends Specification {

    def script = Mock()
    Docker docker = new Docker(script)

    def "build should construct correct docker command"() {
        given:
        def config = [
            imageName: 'myapp',
            imageTag: 'v1.0',
            buildArgs: [APP_VERSION: '1.0.0']
        ]

        when:
        docker.build(config)

        then:
        1 * script.sh(_ as String) >> { String cmd ->
            assert cmd.contains('docker build')
            assert cmd.contains('-t myapp:v1.0')
            assert cmd.contains('--build-arg APP_VERSION=1.0.0')
        }
    }

    def "scan should fail on critical vulnerabilities"() {
        given:
        def image = 'myapp:v1.0'

        when:
        docker.scan(image)

        then:
        1 * script.sh(_ as String) >> { String cmd ->
            assert cmd.contains('trivy image')
            assert cmd.contains('--severity HIGH,CRITICAL')
            assert cmd.contains('--exit-code 1')
        }
    }
}
```

### Integration Testing

Create `Jenkinsfile` in library root:

```groovy
// Test the shared library itself
@Library('fawkes-pipelines@development') _

pipeline {
    agent any

    stages {
        stage('Test Java Template') {
            steps {
                script {
                    goldenPathJava {
                        gitRepo = 'https://github.com/fawkes/sample-java-app.git'
                        skipTests = true
                    }
                }
            }
        }

        stage('Test Python Template') {
            steps {
                script {
                    goldenPathPython {
                        gitRepo = 'https://github.com/fawkes/sample-python-app.git'
                        skipTests = true
                    }
                }
            }
        }

        stage('Test Node Template') {
            steps {
                script {
                    goldenPathNode {
                        gitRepo = 'https://github.com/fawkes/sample-node-app.git'
                        skipTests = true
                    }
                }
            }
        }
    }
}
```

---

## 📖 Appendix C: Advanced Optimization Patterns

### Pattern 1: Build Matrix

Run builds for multiple versions in parallel:

```groovy
def call(Map config = [:]) {
    def javaVersions = config.javaVersions ?: ['11', '17', '21']

    pipeline {
        agent none

        stages {
            stage('Build Matrix') {
                matrix {
                    axes {
                        axis {
                            name 'JAVA_VERSION'
                            values javaVersions
                        }
                    }

                    agent {
                        kubernetes {
                            yaml """
spec:
  containers:
  - name: maven
    image: maven:3.8-openjdk-\${JAVA_VERSION}
"""
                        }
                    }

                    stages {
                        stage('Build') {
                            steps {
                                container('maven') {
                                    sh """
                                        echo "Building with Java \${JAVA_VERSION}"
                                        mvn clean package
                                    """
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
```

### Pattern 2: Conditional Stages

Skip stages based on branch or file changes:

```groovy
stage('Deploy to Production') {
    when {
        allOf {
            branch 'main'
            not { changeRequest() }
            expression {
                def changedFiles = sh(
                    script: "git diff --name-only HEAD~1",
                    returnStdout: true
                ).trim()
                return changedFiles.contains('src/')
            }
        }
    }
    steps {
        echo "Deploying to production..."
    }
}
```

### Pattern 3: Dynamic Stage Generation

Generate stages based on configuration:

```groovy
def generateTestStages(List<String> testSuites) {
    def parallelStages = [:]

    testSuites.each { suite ->
        parallelStages["Test ${suite}"] = {
            stage("Test ${suite}") {
                sh "mvn test -Dtest=${suite}Test"
            }
        }
    }

    return parallelStages
}

pipeline {
    stages {
        stage('Parallel Tests') {
            steps {
                script {
                    parallel generateTestStages(['Unit', 'Integration', 'E2E'])
                }
            }
        }
    }
}
```

### Pattern 4: Build Artifact Promotion

Progressive promotion through environments:

```groovy
def promote(String artifact, String fromEnv, String toEnv) {
    echo "Promoting ${artifact} from ${fromEnv} to ${toEnv}"

    // Tag artifact
    sh """
        docker pull ${artifact}:${fromEnv}
        docker tag ${artifact}:${fromEnv} ${artifact}:${toEnv}
        docker push ${artifact}:${toEnv}
    """

    // Update manifest
    sh """
        git clone https://github.com/org/gitops-manifests.git
        cd gitops-manifests
        sed -i 's|${artifact}:.*|${artifact}:${toEnv}|' ${toEnv}/deployment.yaml
        git add .
        git commit -m "Promote ${artifact} to ${toEnv}"
        git push
    """
}

// Usage
stage('Promote to Production') {
    steps {
        script {
            promote(env.DOCKER_IMAGE, 'staging', 'production')
        }
    }
}
```

---

## 📖 Appendix D: Troubleshooting Guide

### Issue: Shared Library Not Found

**Error**:

```
ERROR: Library fawkes-pipelines not found
```

**Solutions**:

1. Check library name matches in Jenkins global config
2. Verify repository URL is correct
3. Check branch/tag specified exists
4. If using credentials, verify they're configured

```groovy
// Use specific version
@Library('fawkes-pipelines@v1.2.3') _

// Use branch
@Library('fawkes-pipelines@develop') _

// Use commit SHA
@Library('fawkes-pipelines@abc1234') _
```

### Issue: Class Not Found in src/

**Error**:

```
unable to resolve class com.fawkes.pipeline.Docker
```

**Solutions**:

1. Check package path matches directory structure
2. Ensure class is Serializable
3. Import correctly in calling code

```groovy
// Correct import
import com.fawkes.pipeline.Docker

// File must be: src/com/fawkes/pipeline/Docker.groovy
// Class must implement Serializable
```

### Issue: Variable Not Found in vars/

**Error**:

```
No such DSL method 'goldenPathJava' found
```

**Solutions**:

1. Check file is in vars/ directory
2. Filename must match function name
3. Library must be imported

```groovy
// vars/goldenPathJava.groovy defines goldenPathJava()
@Library('fawkes-pipelines') _
goldenPathJava { ... }
```

### Issue: Slow Library Loading

**Problem**: Pipeline takes 2+ minutes to start

**Solutions**:

1. Enable library caching
2. Use specific version (not HEAD)
3. Reduce library size

In Jenkins global config:

```
☑ Cache fetched versions on controller for quick retrieval
```

### Issue: Cannot Modify Immutable Objects

**Error**:

```
Scripts not permitted to use method groovy.lang.GroovyObject
```

**Solutions**:

1. Approve script in Jenkins → Manage Jenkins → In-process Script Approval
2. Use `@NonCPS` annotation for methods that manipulate complex objects

```groovy
@NonCPS
def parseJson(String json) {
    def slurper = new JsonSlurper()
    return slurper.parseText(json)
}
```

---

## 🎉 Congratulations

You've completed **Module 6: Building Golden Path Pipelines**!

### Key Achievements

✅ Created reusable Shared Libraries
✅ Built Golden Path templates for Java, Python, Node.js
✅ Optimized pipelines with parallel execution and caching
✅ Implemented performance monitoring
✅ Reduced pipeline maintenance by 90%+

### Your Golden Path Journey

```
Before Module 6:
👤 Writing 200+ line Jenkinsfiles for each project
🔄 Copy-pasting pipeline code
🐌 30-minute builds
😰 Fear of changing pipelines

After Module 6:
👥 10-line Jenkinsfiles using Golden Paths
♻️ Reusable components in Shared Libraries
⚡ 8-minute builds with optimization
😎 Confident pipeline changes, tested in library
```

### Impact on DORA Metrics

- **Deployment Frequency**: ⬆️ Easier pipelines = more deploys
- **Lead Time**: ⬇️ Faster builds = faster feedback
- **Change Failure Rate**: ⬇️ Tested templates = fewer failures
- **MTTR**: ⬇️ Consistent pipelines = easier debugging

---

## 📅 What's Next?

**Continue Your Journey:**

1. ✅ Complete Module 7: Security Scanning & Quality Gates
2. ✅ Complete Module 8: Artifact Management
3. 🎓 Take Yellow Belt Certification Exam
4. 🚀 Advance to Green Belt (GitOps & Deployment)

**Practice:**

- Implement Golden Paths for your team
- Measure build time improvements
- Share templates with community

**Community:**

- Share your Shared Library in #show-and-tell
- Help others in #yellow-belt channel
- Write a blog post about your experience

---

**Ready for Module 7?** 🔒

Next up: **Security Scanning & Quality Gates** - where you'll learn SonarQube, Trivy, dependency scanning, and building security into every pipeline!

---

*Fawkes Dojo - Where Platform Engineers Are Forged*
*Version 1.0 | Last Updated: October 2025*
*License: MIT | https://github.com/paruff/fawkes*
