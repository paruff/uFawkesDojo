# Module 1: Internal Delivery Platforms - What and Why

**Belt Level**: 🥋 White Belt
**Duration**: 60 minutes
**Prerequisites**: Basic command line, Git, Docker knowledge
**DORA Capabilities**: Continuous Delivery (introduction)

---

## 1. Learning Objectives (3 minutes)

### What You'll Learn

By the end of this module, you will be able to:

- ✅ Define what an Internal Delivery Platform (IDP) is and explain its core components
- ✅ Articulate why organizations need IDPs using concrete business metrics
- ✅ Explain the "Platform as a Product" mindset and its benefits
- ✅ Identify the key stakeholders and their needs in platform engineering
- ✅ Navigate the uFawkesDevX platform (Backstage portal, Coder, Score service) and understand its architecture
- ✅ Recognize how Team Topologies concepts apply to platform teams
- ✅ Use a golden-path Cookiecutter template to scaffold a production-ready service

### Why It Matters

**The Problem**: Modern software delivery involves dozens of tools, complex configurations, and countless decisions that slow teams down. According to the 2023 State of DevOps Report:

- Elite performers deploy **417 times more frequently** than low performers
- They have a **5,788 times lower** change failure rate
- Their lead time for changes is **6,570 times faster**

**The Solution**: Internal Delivery Platforms abstract away complexity and provide "golden paths" that enable teams to move fast while maintaining quality and security.

**Your Role**: Understanding IDPs is the foundation for everything else in this dojo. You can't improve what you don't understand.

### Success Criteria

You've mastered this module when you can:

- Explain to a colleague why your organization needs a platform (in business terms)
- Navigate the uFawkesDevX Backstage portal confidently
- Identify which uFawkesDevX components serve which developer needs
- Articulate the difference between "platform" and "just some scripts"
- Scaffold a new service using a golden-path template and register it in Backstage

---

## 2. Theory & Concepts (15 minutes)

### 📺 Video: What is an Internal Delivery Platform? (7 minutes) — *not built yet*

> **[VIDEO PLACEHOLDER]** > **Script Summary** *(video not produced)*:
>
> - Opening: Show developer frustration with 12-step deployment process
> - Definition: IDP as "self-service platform that provides golden paths"
> - Key components: Portal, CI/CD, Observability, Infrastructure
> - Platform as Product: treating developers as customers
> - uFawkesDevX tour: Show actual platform in action
> - Closing: "A platform that makes the right thing the easy thing"

### What is an Internal Delivery Platform?

An **Internal Delivery Platform (IDP)** is a curated set of tools, services, and self-service capabilities that application teams use to deliver and manage their software with minimal friction.

Think of it as **"paved roads for software delivery"**—just as cities build roads so citizens don't have to navigate rough terrain, platforms build golden paths so developers don't have to navigate infrastructure complexity.

#### The Three Characteristics of an IDP

1. **Self-Service**: Developers can provision resources, deploy applications, and access tools without waiting for tickets or manual intervention

2. **Curated & Opinionated**: The platform team makes thoughtful decisions about tools, patterns, and workflows, reducing cognitive load for app teams

3. **Built on Standards**: Uses industry-standard tools and practices, avoiding vendor lock-in and enabling portability

#### What an IDP is NOT

❌ **Not a PaaS**: Unlike Heroku or Cloud Foundry, IDPs give developers more control and flexibility
❌ **Not just CI/CD**: CI/CD is one component, but IDPs include much more (observability, security, governance)
❌ **Not "throw tools over the wall"**: True platforms treat developers as customers and measure satisfaction
❌ **Not one-size-fits-all**: Platforms provide flexibility for different application types and team maturity levels

### The Platform as a Product Mindset

Traditional IT: *"Here are some tools. Figure it out yourself."*
Platform Engineering: *"What do you need to be productive? Let me build that for you."*

#### Key Principles

**1. Developers are Your Customers**

- Understand their pain points through interviews and surveys
- Measure satisfaction with NPS (Net Promoter Score)
- Iterate based on feedback, not assumptions

**2. Build for the 80% Use Case**

- Provide golden paths for common scenarios
- Allow escape hatches for advanced users
- Don't try to solve every edge case immediately

**3. Measure Platform Value**

- Track adoption rates (% of teams using the platform)
- Monitor time saved (before vs. after metrics)
- Calculate cost efficiency (infrastructure + personnel)

**4. Treat It Like a Product**

- Maintain a roadmap based on customer needs
- Version releases and communicate changes
- Provide documentation and support

### Team Topologies & Enabling Teams

The book *Team Topologies* by Matthew Skelton and Manuel Pais introduces four fundamental team types. Platform teams are **Enabling Teams**.

#### The Four Team Types

1. **Stream-Aligned Teams**: Product/feature teams that deliver value to customers
2. **Enabling Teams**: Help stream-aligned teams overcome obstacles (platform teams!)
3. **Complicated Subsystem Teams**: Specialists for complex subsystems
4. **Platform Teams**: Provide internal services to reduce cognitive load

#### Platform Team Responsibilities

As a platform engineer, your job is to:

- **Reduce cognitive load**: Abstract away infrastructure complexity
- **Enable autonomy**: Give teams self-service capabilities
- **Accelerate delivery**: Remove blockers and reduce lead time
- **Ensure quality**: Build in security, testing, and observability
- **Continuously improve**: Treat the platform as a product that evolves

### Why Organizations Need IDPs

#### The Developer Productivity Crisis

Modern developers spend **70-80% of their time** on non-value-added activities:

- Waiting for environments to be provisioned
- Debugging CI/CD failures
- Figuring out deployment procedures
- Managing infrastructure configurations
- Coordinating with 5+ teams for a single deployment

#### The Business Impact

Without a platform:

- **Slower time to market**: Weeks or months to deploy new services
- **Higher operational costs**: Manual work doesn't scale
- **Increased risk**: No standardization leads to security vulnerabilities
- **Developer attrition**: Frustrated developers leave for better experiences

With a platform:

- **Faster deployments**: From weeks to minutes
- **Lower costs**: Automation reduces manual work by 60-80%
- **Better security**: Security built into golden paths
- **Happier developers**: NPS increases by 30-50 points

#### Real-World Example: Spotify

Spotify's Backstage (which uFawkesDevX uses!) reduced their time to:

- **Provision a new service**: From 4 weeks → 5 minutes
- **Deploy to production**: From 2 hours → 10 minutes
- **Onboard a new developer**: From 2 weeks → 1 day

### uFawkesDevX Platform Architecture

uFawkesDevX provides a complete IDP developer experience plane built on industry-standard open-source tools, running entirely in Docker Compose—no Kubernetes cluster required.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         uFawkesDevX (Docker Compose)                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      Developer Experience Layer                     │   │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │   │
│  │  │   Backstage      │  │     Coder        │  │  Score Service   │  │   │
│  │  │   (Portal)       │  │  (Cloud IDE)     │  │  (Workload API)  │  │   │
│  │  │  • Catalog       │  │  • Workspaces    │  │  • Validation    │  │   │
│  │  │  • TechDocs      │  │  • Devcontainers │  │  • Pipeline      │  │   │
│  │  │  • Scaffolder    │  │                  │  │    Triggers      │  │   │
│  │  └──────────────────┘  └──────────────────┘  └──────────────────┘  │   │
│  │         │                     │                      │              │   │
│  │         └─────────────────────┼──────────────────────┘              │   │
│  │                               ▼                                     │   │
│  │  ┌──────────────────────────────────────────────────────────────┐  │   │
│  │  │              API Gateway (nginx) — Unified Entry Point       │  │   │
│  │  │              /api/score  /api/plugins  /backstage            │  │   │
│  │  └──────────────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│  ┌─────────────────────────────────▼──────────────────────────────────┐  │
│  │                    Core Platform Services                          │  │
│  │  ┌──────────────────────────────────────────────────────────────┐  │  │
│  │  │  Plugin Manager — Manages platform extensions and plugins    │  │  │
│  │  └──────────────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                    │                                        │
│  ┌─────────────────────────────────▼──────────────────────────────────┐  │
│  │                 Data & Runtime Layer                               │  │
│  │  ┌──────────────┐  ┌──────────────────────────────────────────┐  │  │
│  │  │  PostgreSQL  │  │  Host Docker Daemon                      │  │  │
│  │  │  (External)  │  │  (Coder provisions workspace containers) │  │  │
│  │  │  • coder DB  │  │                                        │  │  │
│  │  │  • backstage │  │                                        │  │  │
│  │  │  • score DB  │  │                                        │  │  │
│  │  └──────────────┘  └──────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────▼─────────┐
                    │  Golden Path      │
                    │  Cookiecutter     │
                    │  Templates        │
                    │  • Python Flask   │
                    │  • Java Spring    │
                    │  • Node Express   │
                    │  • Go HTTP        │
                    └───────────────────┘
```

#### Key uFawkesDevX Components

| Component              | Purpose                                           | Technology                           |
| ---------------------- | ------------------------------------------------- | ------------------------------------ |
| **Backstage**          | Developer portal — service catalog, TechDocs, scaffolder | Backstage by Spotify (custom build) |
| **Coder**              | Cloud IDE — provisions ephemeral devcontainer workspaces | Coder v2.34.3                        |
| **Score Service**      | Validates Score workload specs, triggers pipelines | Custom Go service                    |
| **Plugin Manager**     | Manages platform extensions and plugins           | Custom Node.js service               |
| **API Gateway**        | Unified entry point for all platform APIs         | nginx 1.27-alpine                    |
| **Golden Path Templates** | Cookiecutter templates for pre-wired services | Cookiecutter + devcontainer + Score  |

### Common Pitfalls & How to Avoid Them

#### ❌ Pitfall 1: Building in Isolation

**Problem**: Platform team builds what they *think* developers need without asking them.
**Solution**: Conduct regular developer interviews, track NPS, dogfood your own platform.

#### ❌ Pitfall 2: Too Much Control

**Problem**: Platform so restrictive that developers route around it.
**Solution**: Provide golden paths for 80% of cases, escape hatches for edge cases.

#### ❌ Pitfall 3: No Documentation

**Problem**: Great platform, but no one knows how to use it.
**Solution**: Documentation is a first-class feature. Use TechDocs, record videos, provide examples.

#### ❌ Pitfall 4: Ignoring Feedback

**Problem**: Developers complain but nothing changes.
**Solution**: Public roadmap, regular releases, visible responsiveness to feedback.

#### ❌ Pitfall 5: No Metrics

**Problem**: Can't prove platform value to leadership.
**Solution**: Track DORA metrics, adoption rates, time saved, cost efficiency.

---

## 3. Demonstration (10 minutes)

### 📺 Video: uFawkesDevX Platform Tour (10 minutes) — *not built yet*

> **[VIDEO PLACEHOLDER]** > **Script** *(video not produced)*: Instructor walks through uFawkesDevX platform showing:
>
> 1. **Backstage Home** (2 min)
>    - Overview page, quick links
>    - Component search
> 2. **Service Catalog** (3 min)
>    - Browse pre-populated uFawkes planes (DevX, Pipe, Obs, Sec)
>    - View service details (APIs, docs, owner)
>    - Score service and Plugin Manager components
> 3. **TechDocs** (1 min)
>    - Navigate documentation
>    - Search functionality
> 4. **Scaffolder / Golden Paths** (2 min)
>    - Show Cookiecutter templates available
>    - Demonstrate scaffolding a new service
> 5. **Coder Workspaces** (2 min)
>    - Create workspace from scaffolded repo
>    - Show devcontainer in action

> **Key Message**: "Notice how everything you need is in one place. No jumping between 12 different tools. The golden path takes you from 'new service idea' to 'running in a devcontainer' in minutes."

### Key Takeaways from Demo

1. **Single Pane of Glass**: All your tools accessible from Backstage
2. **Self-Service**: Create new services in minutes, not weeks
3. **Discoverability**: Find services, docs, and owners easily
4. **Standardization**: Every service follows the same patterns via golden paths
5. **No Cluster Required**: Runs entirely in Docker Compose on your laptop

---

## 4. Hands-On Lab (20 minutes)

### Lab Overview

You'll start the uFawkesDevX platform, explore the Backstage catalog, scaffold a new service using a golden-path Cookiecutter template, and register it in Backstage.

**Time Estimate**: 20 minutes
**Difficulty**: Beginner (basic Docker knowledge required)
**Auto-Graded**: Yes
**Points**: 50

### Lab Environment

When you start this lab, you'll provision:

- ✅ uFawkesDevX v1.0.1 stack running locally in Docker Compose
- ✅ Local PostgreSQL with required databases (coder, backstage, score)
- ✅ Backstage catalog pre-populated with uFawkes plane components
- ✅ Golden-path Cookiecutter templates ready to use

**Environment will be available as long as you keep the containers running.**

➡️ **[Lab 01: Deploy a Service via Golden Path Template](white-belt/module-01-what-is-idp/lab-01/instructions.md)**

This lab walks you through starting the uFawkesDevX platform, exploring the Backstage catalog, and scaffolding a new service (`hello-devx`) using the Fawkes golden path template.

**Validation**: `bash white-belt/module-01-what-is-idp/lab-01/validate.sh`

---

## 5. Knowledge Check (5 minutes)

### Quiz: Internal Delivery Platforms Fundamentals

**Instructions**: Answer all 10 questions. You need 8/10 (80%) to pass. Unlimited attempts allowed.

#### Question 1

**What is the primary purpose of an Internal Delivery Platform?**

- [ ] A) Replace all existing tools with a single monolithic system
- [x] B) Provide self-service golden paths that reduce cognitive load for developers
- [ ] C) Control everything developers do to enforce policies
- [ ] D) Eliminate the need for DevOps or platform engineers

**Explanation**: IDPs are about **enabling developers** through self-service and curated tools, not controlling or replacing everything.

---

#### Question 2

**According to Team Topologies, what type of team is a platform team?**

- [ ] A) Stream-aligned team
- [x] B) Enabling team
- [ ] C) Complicated subsystem team
- [ ] D) Infrastructure team

**Explanation**: Platform teams are **enabling teams** that help stream-aligned teams overcome obstacles and reduce cognitive load.

---

#### Question 3

**What does "Platform as a Product" mean?**

- [ ] A) Selling your platform to external customers
- [x] B) Treating internal developers as customers and measuring their satisfaction
- [ ] C) Using product management tools to track platform development
- [ ] D) Making the platform a commercial product

**Explanation**: It means treating **developers as customers**, understanding their needs, and measuring satisfaction—just like a real product.

---

#### Question 4

**Which of these is NOT a characteristic of a well-designed IDP?**

- [ ] A) Self-service capabilities
- [ ] B) Opinionated but flexible
- [x] C) Forces all teams to use exactly the same tools with no exceptions
- [ ] D) Built on industry standards

**Explanation**: Good platforms are **opinionated but provide escape hatches**. Forcing everyone into identical workflows leads to teams routing around the platform.

---

#### Question 5

**What is Backstage in the uFawkesDevX platform?**

- [ ] A) The CI/CD pipeline tool
- [x] B) The developer portal that provides a single pane of glass
- [ ] C) The Kubernetes orchestration system
- [ ] D) The monitoring and observability tool

**Explanation**: **Backstage is the developer portal**—the single interface where developers access all platform services.

---

#### Question 6

**Why do organizations invest in Internal Delivery Platforms?**

- [ ] A) Because it's a trendy thing to do
- [ ] B) To give platform teams more control
- [x] C) To accelerate delivery, reduce costs, and improve developer experience
- [ ] D) To replace cloud providers

**Explanation**: IDPs deliver **business value** through faster delivery, lower costs, better security, and improved developer satisfaction.

---

#### Question 7

**What does "golden path" mean in platform engineering?**

- [x] A) The recommended, easy-to-follow path for common use cases
- [ ] B) The most expensive way to deploy applications
- [ ] C) A strict requirement that all teams must follow
- [ ] D) The path used only by senior engineers

**Explanation**: A **golden path** is the easy, paved road for the 80% use case—making the right thing the easy thing.

---

#### Question 8

**Which metric is NOT typically used to measure platform success?**

- [ ] A) Developer Net Promoter Score (NPS)
- [ ] B) Platform adoption rate
- [ ] C) Time saved per deployment
- [x] D) Number of tickets closed by the platform team

**Explanation**: Platform success is about **developer outcomes** (NPS, adoption, time saved), not just operational metrics like ticket volume.

---

#### Question 9

**In uFawkesDevX, which tool provisions cloud IDE workspaces?**

- [ ] A) Backstage
- [x] B) Coder
- [ ] C) Score Service
- [ ] D) Plugin Manager

**Explanation**: **Coder** provisions ephemeral devcontainer workspaces on the host Docker daemon.

---

#### Question 10

**What is a common pitfall when building an IDP?**

- [x] A) Building in isolation without talking to developers
- [ ] B) Using industry-standard open-source tools
- [ ] C) Providing documentation and examples
- [ ] D) Measuring platform adoption and satisfaction

**Explanation**: Building **without developer input** is the #1 pitfall—you end up solving the wrong problems.

---

### Quiz Results

**Score: X / 10**

- ✅ **Passed** (8+): Great job! You're ready to move to the next section.
- ❌ **Not Yet** (<8): Review the content and try again. Focus on areas you missed.

**Incorrect answers?** Each question links back to the relevant section for review.

---

## 6. Reflection & Next Steps (5 minutes)

### What You Learned

Congratulations! 🎉 You've completed Module 1. Let's recap:

✅ **You now understand**:

- What an Internal Delivery Platform is and why it matters
- The "Platform as a Product" mindset
- How Team Topologies applies to platform teams
- The uFawkesDevX platform architecture and components
- How to navigate Backstage and find information
- How to scaffold a service using a golden-path template

✅ **You can now**:

- Explain the business value of IDPs to colleagues
- Navigate the uFawkesDevX Backstage portal confidently
- Identify the core components of the platform
- Scaffold a new service from a golden-path template

### How This Connects to Your Work

**For Developers**:

- You now understand why your company invested in a platform
- You know where to find docs, who to ask for help, and how to create new services
- You can take advantage of golden paths instead of reinventing the wheel

**For Platform Engineers**:

- You understand your role as an "enabling team"
- You know how to treat developers as customers
- You can articulate the value of the platform to stakeholders

**For Leaders**:

- You can explain how platforms accelerate delivery and reduce costs
- You understand the metrics that matter (DORA, NPS, adoption)
- You can make the case for platform investments

### Reflection Questions

Take 2 minutes to think about:

1. **What surprised you most about IDPs?**

    - Was there a concept that changed your perspective?

2. **How does your current workflow compare?**

    - Are you using a platform? Doing things manually? Somewhere in between?

3. **What would improve your developer experience?**

    - If you could wave a magic wand, what would you change?

4. **Who could benefit from this knowledge?**

    - Think of 2-3 colleagues who should go through this module

### Additional Resources

**📚 Further Reading**:

- [Team Topologies Book](https://teamtopologies.com) - Foundation for platform thinking
- [Backstage Documentation](https://backstage.io/docs/overview/what-is-backstage) - Learn more about Backstage
- [Platform Engineering Community](https://platformengineering.org) - Join the community
- [DORA Research](https://dora.dev) - Dive into the research behind DORA metrics

**🎥 Videos to Watch**:

- "What is Platform Engineering?" by Luca Galante (10 min)
- "Spotify's Backstage Journey" (15 min)
- "Building a Platform as a Product" by Camille Fournier (30 min)

**💬 Community**:

- Join [GitHub Discussions](https://github.com/paruff/uFawkesDojo/discussions) for `#dojo-white-belt`
- Share your "aha!" moments
- Help others who are just starting

### Preview: Module 2

**Next Up: DORA Metrics - The North Star**

In Module 2, you'll learn:

- The five DORA metrics, including Deployment Rework Rate
- Why these metrics matter to your business
- How uFawkesObs automatically tracks DORA metrics
- How to interpret your team's metrics and drive improvement

**Time**: 60 minutes
**Hands-On**: Send real events to a live DORA dashboard

**Get Ready**: Think about your team's current deployment process. How long does it take? How often do you deploy? How often do deployments fail?

---

## Module Completion

### ✅ You've Completed Module 1

**Next Steps**:

1. ✅ Mark this module complete in your Backstage profile
2. 📊 View your progress on the Dojo dashboard
3. 💬 Share your completion in `#dojo-achievements` (optional but encouraged!)
4. ➡️ **Continue to Module 2** when ready

**Time Investment**: 60 minutes
**Skills Gained**: Platform fundamentals, Backstage navigation, golden-path scaffolding
**Progress**: 1 of 4 modules toward White Belt (25% complete)

---

**Questions or Issues?**

- 💬 Ask in [GitHub Discussions](https://github.com/paruff/uFawkesDojo/discussions) for `#dojo-white-belt`
- 📧 Email: dojo@ufawkes.dev
- 🐛 Report bugs: [GitHub Issues](https://github.com/paruff/fawkes/issues)

**Feedback?**

- Rate this module (takes 30 seconds)
- Suggest improvements
- Help us make the dojo better!

---

**Module Author**: Fawkes Learning Team
**Last Updated**: October 2026
**Version**: 2.0
