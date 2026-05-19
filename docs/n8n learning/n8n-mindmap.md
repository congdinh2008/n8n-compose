# 🧠 N8N Mindmap — Từ Cơ Bản Đến Chuyên Sâu

> **Phiên bản:** May 2026 · **Tác giả:** Cong Dinh
> **Mục đích:** Khung kiến thức training, consulting, brand building
> **Đối tượng:** Mixed track — Business + Technical

---

## 📌 Cách dùng file này

- **Render Mermaid:** GitHub, GitLab, Notion, Obsidian, Typora, VS Code (extension Mermaid Preview), HackMD
- **Export PNG/SVG:** Mermaid Live Editor — `https://mermaid.live`
- **Track filtering:** Mỗi nhánh có badge `[🏢 BIZ]`, `[⚙️ TECH]`, hoặc `[🎯 MIX]`

---

## 🗺️ Mindmap chính (Tổng quan)

```mermaid
mindmap
  root((n8n<br/>Fair-code<br/>Workflow Automation))
    1. Foundations 🎯
      n8n là gì
        nodemation
        186k+ GitHub stars
        Fair-code license
      So sánh
        vs Zapier (cloud only)
        vs Make (visual UX)
        vs Power Automate (MS eco)
      Kiến trúc
        Editor UI
        Workflow Engine
        Database
        Task Runners
        Queue Redis
      Use cases tổng quan
        Business
        Personal
        AI
        Data ETL
    2. Installation ⚙️
      n8n Cloud
        Managed SaaS
        14-day trial
      Docker Compose
        Phổ biến nhất
        Postgres + Redis
        Nginx Traefik
      npm install
        Dev only
      Kubernetes
        Helm chart
        HPA autoscale
      Cloud Providers
        AWS ECS EKS
        Azure Container Apps
        GCP Cloud Run
        VPS Hetzner Contabo
    3. Core Concepts 🎯
      Workflows
        Lifecycle Draft Active
        JSON structure
        Tags Folders
      Nodes
        Trigger nodes
        Action nodes
        Logic nodes
        500+ built-in
      Connections
        Main
        Error
        AI Tool Memory Model
      Data Structure
        Items array
        json binary pairedItem
      Credentials
        OAuth2 API key
        AES-256 encryption
        External secrets
      Triggers
        Schedule cron
        Webhook
        App push poll
        Form
      Executions
        Status modes
        Retention policy
    4. Expressions & Code ⚙️
      Syntax {{ }}
        $json $input
        $now $workflow
        $env $execution
      Built-in helpers
        Luxon DateTime
        Array map filter
        JMESPath
        Crypto
      Code Node JS
        Run all vs each
        Built-in libs
      Code Node Python
        Pyodide runtime
      HTTP Request
        Auth methods
        Pagination
        Retry backoff
    5. Patterns & Errors ⚙️
      Design Patterns
        Sequential
        Conditional IF Switch
        Fan-out parallel
        Fan-in merge
        Loop Over Items
        Wait Delay
        Circuit Breaker
      Sub-workflows
        Execute Workflow
        DRY reusability
      Error Handling
        Error Trigger
        Continue On Fail
        Stop and Error
      Retry Logic
        Exponential backoff
        Idempotency
        Dead letter queue
      Debugging
        Pin data
        Step execution
        Console log
    6. AI & LangChain 🎯
      n8n 2.0 Jan 2026
        70+ AI nodes
        75% customers use AI
      LLM Providers
        OpenAI GPT-4 o1
        Anthropic Claude
        Google Gemini
        Ollama Hugging Face
        Groq Mistral
      AI Agents
        ReAct
        Tools agent
        OpenAI Functions
        Conversational
      Memory Types
        Buffer
        Window
        Summary
        Vector store
      RAG Pipeline
        Vector stores Pinecone Qdrant pgvector
        Embeddings
        Document loaders
        Splitters
        Retrieval similarity MMR
      Multi-Agent
        Supervisor
        Worker specialized
        Coordination
      AI Use Cases
        Support chatbot RAG
        Document processing
        Content generation
        Lead qualification
        Voice agents Vapi
      Evaluation
        Eval nodes
        LLM-as-judge
        Guardrails
    7. Production ⚙️
      Queue Mode
        Less 1k exec standard
        1k-10k 1 worker
        10k+ multi workers
      Architecture
        Main process
        Workers Redis pull
        Webhook processors
        Postgres required
      Critical Config
        EXECUTIONS_MODE queue
        ENCRYPTION_KEY identical
        QUEUE_BULL_REDIS_HOST
        Concurrency limit
      Resource Planning
        200-500MB per worker
        Node heap size
        Binary filesystem mode
        DB retention
      Monitoring
        Prometheus metrics
        Health checks
        Centralized logging
        Grafana alerts
      Backup DR
        pg_dump daily
        Workflow export Git
        Credentials encrypted
        Binary S3
      Kubernetes
        HPA Redis depth
        Pod separation
        PVC StatefulSet
        Network policy
    8. Enterprise 🏢
      CRM Sales
        Lead capture score
        Pipeline sync bi-direction
        Quote DocuSign
        Follow-up sequence
      Marketing
        Email drip
        Cross-platform social
        Lead nurturing
        Unified analytics
      HR
        Onboarding accounts
        Offboarding revoke
        Leave approval
        Performance review
      Finance
        Invoice auto
        Reconciliation
        Expense OCR
        Revenue dashboard
      Customer Support
        Ticket routing AI
        SLA monitoring
        AI first response
        CSAT survey
      Data ETL
        Source staging warehouse
        Schedule batch
        CDC incremental
        Validation
    9. Personal 🏢
      Email Inbox Zero
        Auto-classify
        Auto-reply context
        Daily digest AI
        Action extraction
      Social Media Brand
        Idea to publish pipeline
        Cross-posting adapt
        Analytics
        Engagement
      Personal Finance
        SMS bank parse
        Budget alert
        Investment tracking
        Crypto alerts
      Learning
        RSS YouTube curation
        Reading list TLDR
        Anki flashcards
        Course progress
      Home IoT
        Home Assistant
        Doorbell photo
        Morning briefing
    10. Best Practices 🎯
      Naming
        Workflow Team Purpose Trigger
        Node action-based
        Tags domain env
        Sticky notes
      Security
        Least privilege creds
        Encryption key 32+ chars
        HTTPS force
        Webhook HMAC
        RBAC
        Audit log
        Rotation 90 days
      Performance
        Batch 100 items
        Binary filesystem
        Pagination built-in
        Cache Redis
        Rate limiting Wait
        Concurrency control
      Reliability
        Idempotency
        Error workflow alert
        Timeout always
        Circuit breaker
        Monitoring Slack
      Testing
        Pin sample data
        Staging env
        Schema validation
        AI eval suite
      Version Control
        CLI export Git
        Source Control feature
        CI lint deploy
        Tag releases
      Documentation
        Sticky notes Why
        Runbook link
        External docs Notion
    11. Case Studies 🎯
      Delivery Hero
        200h month saved
        Single workflow
      Vodafone
        5000 person-days year
        33 workflows incident
      Musixmatch
        47 days engineering
        4 months
      StepStone
        25x faster integration
        Data ingestion
      TechStore.vn
        Order fulfillment
        80 percent auto
      CloudMetrics.io
        Queue mode 4 workers
        50k exec day
      ROI metrics
        240 percent average
        3.7 dollar return per 1
        10-15k saved monthly
    12. Troubleshooting ⚙️
      Installation
        Permission Docker UID
        Port conflict 5678
        DB connection
        SQLite lock
      Execution Errors
        undefined json
        Timeout config
        Out of memory
        Rate limit 429
      Webhook
        Not registered
        WEBHOOK_URL config
        HTTPS cert
        Body parsing
      Queue Mode
        Jobs stuck
        Credential decrypt
        Webhook slow
        Memory leak
      Debugging
        Execution logs
        Pin data
        Console log
        curl test
    13. Ecosystem 🎯
      Official
        docs.n8n.io
        Templates 5000+
        Community forum
        GitHub repo
        YouTube
      Community Nodes
        Self-hosted only
        Vector DB nodes
        Niche APIs
      Custom Nodes
        TypeScript
        n8n-nodes- npm
        Local link test
      Career Opportunities
        Freelance 50-150 hour
        Agency 25k+ month
        Training consulting
        Templates marketplace
      Learning Path
        Week 1-2 Foundation
        Week 3-4 Code Errors
        Week 5-6 AI RAG
        Week 7-8 Production
        Week 9-12 Real project
```

---

## 🌳 Mindmap chi tiết theo từng nhánh

### Nhánh 1: Foundations — Nền tảng [🎯 MIX]

```mermaid
mindmap
  root((1. Foundations))
    n8n là gì
      nodemation đọc n-eight-n
      Fair-code OSS
      Visual + Code
      186k+ GitHub stars 2026
    Fair-code License
      Free self-host
      Free revenue under 1M
      Commercial enterprise
      Khác MIT Apache
    So sánh platforms
      n8n
        Self-host
        Free
        500+ nodes
        JS Python AI
      Zapier
        Cloud only
        6000+ apps
        Easy expensive
      Make
        Cloud only
        Visual nice
        Pay per operation
      Power Automate
        Microsoft eco
        Enterprise integration
    Khi nào chọn n8n
      Data privacy
      Custom code
      Full control
      Budget limit
    Kiến trúc Components
      Editor Vue.js UI
      Workflow Engine Node.js
      Database SQLite Postgres
      Task Runners isolated
      Queue Redis optional
    Use cases tổng quan
      Business CRM HR Finance
      Personal email social
      AI chatbot RAG agent
      Data ETL warehouse
```

### Nhánh 2: Installation & Setup [⚙️ TECH]

```mermaid
mindmap
  root((2. Installation))
    n8n Cloud
      Managed SaaS
      14 days trial
      Active workflow pricing
      Best for POC team nhỏ
    Docker Compose
      Phổ biến nhất self-host
      Services
        n8n
        postgres
        redis
        nginx traefik
      Volume mounts
        ~/.n8n
        postgres data
      Env vars critical
        N8N_ENCRYPTION_KEY 32 chars
        N8N_HOST
        WEBHOOK_URL
        DB_TYPE postgresdb
    npm install
      npm install n8n -g
      n8n start
      Dev learning only
      Không production
    Kubernetes
      Helm chart official
      community-charts n8n
      Deployment
        Main pod
        Worker pods
        Webhook pods
      HPA
        CPU based
        Redis queue depth
      StatefulSet
        PostgreSQL
        Redis
    Cloud Providers
      AWS
        ECS Fargate
        EKS
        RDS PostgreSQL
        ElastiCache Redis
      Azure
        Container Apps
        AKS
        Azure DB Postgres
        Azure Cache Redis
      GCP
        Cloud Run
        GKE
        Cloud SQL
        Memorystore
      VPS
        Hetzner
        Contabo
        DigitalOcean
        Cost effective
```

### Nhánh 3: Core Concepts [🎯 MIX]

```mermaid
mindmap
  root((3. Core Concepts))
    Workflows
      Định nghĩa chuỗi nodes
      Lifecycle
        Draft
        Active
        Deactivated
        Archived
      JSON structure
        nodes array
        connections object
        settings
      Organization
        Tags domain env
        Folders projects
    Nodes
      Trigger nodes
        Schedule cron
        Webhook HTTP
        App events Gmail Slack
        Form built-in
      Action nodes
        HTTP Request
        Database query
        Send Email
        500+ integrations
      Logic nodes
        IF condition
        Switch route
        Merge combine
        Loop Over Items
        Wait Delay
    Connections
      Main data flow
      Error output 2
      AI connections
        Tool
        Memory
        Model
    Data Structure
      Items array
        json data chính
        binary files
        pairedItem lineage
      Manipulation patterns
        Direct access $json.x
        Mapping items
        Filtering
    Credentials
      Types
        API Key
        OAuth2
        Basic Auth
        Custom
      Storage
        AES-256 encrypted
        N8N_ENCRYPTION_KEY
      Sharing
        Per-user
        Shared
        Project-scoped Enterprise
      External
        Vault
        AWS Secrets
    Triggers chi tiết
      Schedule
        Cron expression
        Interval
        Timezone aware
      Webhook
        REST endpoint
        Test vs Production URL
        Response immediate
      App Trigger Push
        Realtime
        Gmail Slack Stripe
      App Trigger Poll
        n8n polls
        Configurable interval
      Manual testing only
    Executions
      Modes
        Manual
        Trigger
        Webhook
        Retry
      Status
        Success
        Error
        Running
        Canceled
        Waiting
      Settings
        Save successful
        Save errors only
        Retention days
```

### Nhánh 4: Expressions & Code Node [⚙️ TECH]

```mermaid
mindmap
  root((4. Expressions & Code))
    Expression Syntax
      {{ expression }}
      JavaScript template literals
      Current item
        $json.field
      First all items
        $input.first().json.x
        $input.all()
      Other nodes
        $('Node Name').item.json.x
      Variables
        $now $today
        $workflow
        $execution
        $env
    Built-in Helpers
      Date Time Luxon
        $now.plus({days: 7})
        .format('yyyy-MM-dd')
        .diff()
      String
        toUpperCase
        replaceAll
        split
        trim
      Array
        map filter reduce
        sort find
        slice flat
      JMESPath query
        $jmespath syntax
      Crypto
        hash uuid
        randomBytes
    Code Node JavaScript
      2 modes
        Run Once for All
        Run Once for Each
      Return shape
        Array of json items
      Built-in libs
        crypto
        axios limited
        lodash
      External modules
        NODE_FUNCTION_ALLOW_EXTERNAL
      Best practice
        Khi expression quá phức tạp
        Easy test maintain
    Code Node Python
      Pyodide runtime
      Slower than JS
      Limited libs
      Data science use case
    HTTP Request Deep
      Authentication
        None
        Basic
        Header
        OAuth2
        Bearer
        Custom
      Pagination handlers
        Offset
        Page number
        Link header
        Next URL
      Retry
        Configurable retries
        Exponential backoff
      Streaming
        Binary data
        SSE
```

### Nhánh 5: Workflow Patterns & Error Handling [⚙️ TECH]

```mermaid
mindmap
  root((5. Patterns & Errors))
    Design Patterns
      Sequential
        A to B to C
      Conditional
        IF node binary
        Switch multi-route
      Parallel Fan-out
        Split branches
        Concurrent execution
      Fan-in Merge
        Combine results
        Wait for all
      Loop Over Items
        Batch processing
        Configurable size
      Wait Delay
        Sync seconds
        Async resume event
      Circuit Breaker
        Detect cascading fail
        Auto-pause
    Sub-workflows
      Execute Workflow node
      Function call pattern
      Input output mapping
      Use cases
        Shared logic
        Microservice
        Version control
      Best practice
        DRY principle
        Tách auth log notify
    Error Handling
      Error Trigger workflow
        Catches errors
        Receives error context
      Continue On Fail
        Node setting
        Không break flow
      Try Catch pattern
        IF check error
      Stop and Error node
        Throw custom
    Retry Logic
      Node-level retry
        Max attempts
        Wait time
      Exponential backoff
        Wait 2^n seconds
      Idempotency
        Same input same result
      Dead letter queue
        Store failed
        Manual retry later
    Debugging
      Pin data
        Lock output
        No re-call API
      Execute previous nodes
        Re-run from any
      Step-by-step
        Test each node
      Console log
        Code node debug
        Execution logs
```

### Nhánh 6: AI & LangChain [🎯 MIX — HOT 2026]

```mermaid
mindmap
  root((6. AI & LangChain))
    n8n 2.0 release
      January 2026
      AI-first orchestration
      Native LangChain
      70+ AI nodes
      75 percent customers use
    LLM Providers
      OpenAI
        GPT-4
        GPT-4o
        o1 reasoning
        Embeddings
        Vision
      Anthropic
        Claude Opus
        Sonnet Haiku
        Strong reasoning
      Google
        Gemini Pro Flash
        Vertex AI
      Open Source
        Ollama self-host
        Hugging Face
        LM Studio
      Specialized
        Mistral
        Groq fast inference
        Together AI
    AI Agents
      Agent types
        ReAct reasoning
        Tools agent
        OpenAI Functions
        Conversational
      Tools available
        HTTP Request
        Code node
        Sub-workflows
        Custom MCP
      Memory
        Buffer last N
        Window sliding
        Summary compress
        Vector store retrieval
      Output Parser
        Auto-fix
        Structured JSON Schema
    RAG Pipeline
      Vector Stores
        Pinecone
        Qdrant
        Supabase
        Postgres pgvector
        Weaviate
      Embeddings
        OpenAI text-embedding-3
        Cohere
        Local sentence-transformers
      Document Loaders
        PDF
        Web scraping
        GDrive
        Notion
      Splitters
        Recursive character
        Token-based
        Semantic
      Retrieval
        Similarity cosine
        MMR diversity
        Hybrid keyword vector
    Multi-Agent
      Pattern
        Supervisor orchestrator
        Worker specialized
      Specialized agents
        Research agent
        Writer agent
        Critic agent
      Coordination
        Shared memory
        Message passing
      Use case
        Complex tasks
        Beyond single agent
    AI Use Cases
      Customer Support
        Chatbot RAG KB
        Escalate human
      Document Processing
        Invoice extraction
        Contract parsing
        OCR
      Content Generation
        Social posts
        Email drafts
        SEO content
      Lead Qualification
        AI scoring
        Next action suggest
      Data Enrichment
        Fill from web LinkedIn
      Voice Agents
        n8n Vapi
        ElevenLabs Twilio
        24/7 receptionist
    AI Evaluation
      Eval nodes built-in
      LLM-as-judge
        Score with another LLM
      Guardrails
        JSON Schema validate
        Content filter
      Roadmap 2026
        Deeper eval tooling
```

### Nhánh 7: Production & Scaling [⚙️ TECH]

```mermaid
mindmap
  root((7. Production & Scaling))
    Queue Mode khi nào
      Less 1000 exec day
        Standard + Postgres
      1k-10k exec day
        Queue + 1 worker
      Over 10k exec day
        Queue + multi workers
        Webhook processors riêng
      Trigger upgrade
        Webhook latency over 1s
        Over 10-20 concurrent
    Architecture
      Main process
        UI
        Push jobs to Redis
      Workers
        Pull from Redis
        Execute workflows
        Update status
      Webhook processors
        High-volume webhooks
        Separate scaling
      Redis broker required
      PostgreSQL required
        SQLite NOT supported
    Critical Config
      EXECUTIONS_MODE queue
        Set main + all workers
      N8N_ENCRYPTION_KEY
        IDENTICAL all workers
        Khác key → decrypt fail
      QUEUE_BULL_REDIS_HOST
      N8N_CONCURRENCY_PRODUCTION_LIMIT
    Resource Planning
      Worker memory
        200-500MB each
        More for heavy transform
      Node.js heap
        max-old-space-size 4096
      Binary data
        filesystem mode
        S3 cho file lớn
      DB sizing
        Plan execution retention
    Monitoring
      Prometheus
        N8N_METRICS true
        /metrics endpoint
      Key Metrics
        Redis queue length
        Worker concurrency
        Exec duration
        Error rate
      Health checks
        /healthz
        /healthz/readiness
      Logging
        Centralize Loki ELK
        workflow_id execution_id
      Alerting
        Grafana rules
        Queue backlog
        Failed execs
    Backup DR
      Database
        pg_dump daily
        WAL archive
      Workflow export
        CLI n8n export
        Commit Git
      Credentials backed up
        Encrypted in DB
        Need ENCRYPTION_KEY restore
      Binary data
        S3 versioning
        FS snapshot
    Kubernetes
      HPA strategy
        Redis queue depth metric
      Pod separation
        main deployment
        worker deployment
        webhook deployment
      Storage
        PVC binary
        RDS Cloud SQL DB
      Network policy
        Restrict ingress egress
        Isolate workers
```

### Nhánh 8: Enterprise Use Cases [🏢 BIZ]

```mermaid
mindmap
  root((8. Enterprise))
    CRM Sales
      Lead capture
        Form to score to route
        Round-robin distribution
      Pipeline sync
        HubSpot Salesforce Pipedrive
        Bi-directional
      Quote Proposal
        Template generation
        DocuSign integration
      Follow-up
        Sequence by stage
        Idle deal alert
    Marketing
      Email Campaigns
        Drip sequences
        Segmentation
        A/B testing
      Social Media
        Cross-post FB IG TikTok LinkedIn
        Single source many platforms
      Lead Nurturing
        Score-based content
        Behavior triggered
      Analytics
        GA4 + ad platforms
        Unified dashboard
    HR Employee
      Onboarding
        Account creation
          Google Workspace
          Slack GitHub
        Welcome email
        Training schedule
      Offboarding
        Revoke access
        Archive data
        Exit interview
      Leave Management
        Form approval workflow
        Calendar update
        Balance tracking
      Performance
        360 feedback aggregate
        Review cycle reminders
    Finance Invoice
      Invoice Generation
        Shopify Stripe order
        PDF generation
        Email send
      Payment Tracking
        Reconcile bank
        QuickBooks Xero sync
      Expense Approval
        Receipt OCR
        Manager approve
        Reimbursement
      Reporting
        Daily revenue
        Churn alerts
        Forecast
    Customer Support
      Ticket Routing
        AI categorize
        Assign team
      SLA Monitoring
        Breach alert
        Priority escalation
      AI First Response
        RAG bot FAQ
        Escalate complex
      CSAT Survey
        Post-close send
        Aggregate insights
    Data ETL Integration
      Pattern ELT
        Source staging warehouse
      Schedule batch
        Daily hourly sync
        BigQuery Snowflake
      CDC incremental
        Webhook triggered
        Real-time updates
      Validation
        Schema check
        Anomaly detection
```

### Nhánh 9: Personal Productivity [🏢 BIZ]

```mermaid
mindmap
  root((9. Personal Productivity))
    Email Inbox Zero
      Auto-classify
        AI labels
        Newsletter important spam
      Auto-reply
        Out-of-office
        Context-aware
      Daily Digest
        AI summary unread
      Action Extraction
        Email to Notion Todoist
        Todo from content
    Social Media Brand
      Content Pipeline
        Idea Notion
        AI draft
        Review
        Schedule
      Cross-posting
        TikTok FB YouTube X LinkedIn
        Format adapt platform
      Analytics
        Pull metrics
        Weekly dashboard
      Engagement
        Auto-DM new followers
        Comment reply suggest
    Personal Finance
      Expense Tracking
        SMS bank parse
        Google Sheets Notion
      Budget Alert
        Daily vs budget
        Threshold notify
      Investment Tracking
        Binance crypto
        Chứng khoán VN
        Portfolio dashboard
      Crypto Alerts
        Price threshold
        Whale movement on-chain
    Learning Knowledge
      Content Curation
        RSS YouTube X
        AI summarize
        Notion KB
      Reading List
        Save links
        AI TLDR
        Weekly digest
      Flashcards
        Auto-generate Anki
        From notes
      Course Progress
        Udemy Coursera track
        Streak logging
    Home IoT
      Home Assistant
        Trigger sensor event
      Notifications
        Doorbell photo Telegram
        Smart alerts
      Routines
        Morning briefing
          Weather
          Traffic
          Calendar
          Voice speaker
```

### Nhánh 10: Best Practices [🎯 MIX]

```mermaid
mindmap
  root((10. Best Practices))
    Naming Organization
      Workflow naming
        Team-Purpose-Trigger
        Sales-LeadCapture-Webhook
      Node naming
        Action-based
        Fetch active leads
        Không HTTP1
      Tags strategy
        Domain sales hr finance
        Env prod dev
      Sticky notes
        Document logic
        Edge cases
        Owner
    Security
      Credentials
        Least privilege scope
        Rotate 90 days
      Encryption key
        32+ chars
        Secret manager
        Không commit Git
      HTTPS Force
        Let's Encrypt
        Cloudflare proxy
      Webhook Auth
        Header token
        HMAC signature
      RBAC
        User roles
        Project credentials
      Audit Log
        Track changes
        Who when what
    Performance
      Batch processing
        Avoid 10k items at once
        Split 100 batches
      Binary filesystem mode
        Không RAM
      Pagination
        Built-in handlers
        Always for large data
      Cache
        Redis static
        TTL configurable
      Rate limiting
        Respect API limits
        Wait node backoff
      Concurrency control
        Limit parallel
        Avoid downstream overload
    Reliability
      Idempotency
        2 runs same input
        Same result no side effect
      Error workflow
        Dedicated catch alert
      Timeout
        Set every HTTP call
        Default infinity nguy hiểm
      Circuit breaker
        Pause on cascading fail
      Monitoring
        Slack Telegram alerts
        On every fail
    Testing QA
      Test data
        Pin sample
        Không gọi prod API
      Staging env
        Separate instance
      Manual test workflows
        Verify sub-workflows
      Schema validation
        JSON Schema input output
      AI Eval suite
        Batch prompts
        Quality scoring
    Version Control CICD
      CLI Export
        n8n export workflow all
        Commit JSON to Git
      Source Control feature
        Enterprise built-in
        Git sync native
      CI Pipeline
        Lint workflow JSON
        Deploy staging test prod
      Workflow versioning
        Tag releases
        Rollback path
    Documentation
      Sticky notes
        Why this exists
        Edge cases
        Owner contact
      Workflow description
        Trigger info
        Owner
        Dependencies
        Runbook link
      External docs
        Notion Confluence
        Business logic complex
```

### Nhánh 11: Case Studies — Real-world ROI [🎯 MIX]

```mermaid
mindmap
  root((11. Case Studies))
    Delivery Hero
      Industry food delivery global
      200 hours month saved
      Single workflow
      Internal ops automation
    Vodafone
      Industry telecom enterprise
      5000 person-days year
      33 automated workflows
      Incident management
    Musixmatch
      Industry music tech
      47 days engineering 4 months
      Engineering redirect core product
    StepStone
      Industry job marketplace
      25x faster integration
      Data ingestion automation
    TechStore.vn ecommerce VN
      Order fulfillment
        Shopify order
        Stock check
        Carrier API
        SMS customer
        CRM update
      80 percent auto-processed
      Save 4-5 ops staff
    CloudMetrics.io SaaS
      Customer onboarding
      Billing automation
      Churn prediction
      Queue mode 4 workers
      Redis cluster
      50k execution day
    ROI Industry Average
      240 percent automation ROI
      3.7 dollar return per 1 AI
      10-15k saved monthly enterprise
      Beyond labor
        Error reduction
        Faster cash cycle
        Customer retention
```

### Nhánh 12: Troubleshooting [⚙️ TECH]

```mermaid
mindmap
  root((12. Troubleshooting))
    Installation Issues
      Permission denied Docker
        Fix UID GID
        N8N_USER setting
      Port conflict 5678
        Change N8N_PORT
      DB connection refused
        Check network containers
        Service names
      SQLite lock errors
        Migrate to PostgreSQL
        Critical for prod
    Workflow Execution Errors
      Cannot read property undefined
        Item structure wrong
        Check $json shape
      Timeout errors
        EXECUTIONS_TIMEOUT
        Node-level timeout
      Out of memory
        Increase heap
        Batch processing
        Binary filesystem
      Rate limit 429
        Wait node
        Exponential backoff
    Webhook Issues
      Not triggering
        Check WEBHOOK_URL
        Workflow active
      Webhook not registered
        Activate workflow
        Wait 1-2 seconds
      HTTPS cert error
        Verify SSL chain
        openssl s_client
      Body parsing fail
        Content-Type header
        JSON vs form-data
    Queue Mode Issues
      Jobs stuck queue
        Check worker logs
        Redis connection
      Credential decrypt fail
        ENCRYPTION_KEY mismatch
        Common pitfall
      Webhook slow
        Add webhook processors
      Memory leak worker
        MAX_PAYLOAD_SIZE
        Restart periodic
    Debugging Workflow
      Execution logs
        Editor Executions panel
      Pin data
        Lock output node
        Re-run faster
      Console log
        Code node debug
        Container logs
      Test webhook
        curl POST production URL
```

### Nhánh 13: Ecosystem & Career [🎯 MIX]

```mermaid
mindmap
  root((13. Ecosystem))
    Official Resources
      docs.n8n.io
        Always latest
      Templates n8n.io workflows
        5000+ ready-to-use
      Community forum
        community.n8n.io
        Q&A sharing
      GitHub repo
        n8n-io/n8n
        Issues PRs
      YouTube channel
        Official tutorials
    Community Nodes
      Self-hosted only
      Install Settings
      Popular categories
        Vector DB nodes
        Niche API
        Web scraping
      Security review trước cài
    Custom Nodes Build
      Tech stack
        TypeScript
        n8n-workflow types
      Structure
        .node.ts
        .credentials.ts
        icon.svg
      Publish
        npm prefix n8n-nodes-
      Test local
        npm link
        Restart n8n
    Career Business
      Freelance
        50-150 USD hour
        SMB clients
      Agency model
        25k+ month achievable
        Automation as service
      Training Consulting
        Course workshop
        Enterprise consult
      Templates Marketplace
        Sell workflow templates
    Learning Path 12 weeks
      Week 1-2 Foundation
        Install
        First 5 workflows
        UI navigation
      Week 3-4 Code Errors
        Expressions
        Code node
        Error handling
      Week 5-6 AI RAG
        LangChain basics
        1 RAG project
        AI agent build
      Week 7-8 Production
        Docker deploy
        Queue mode
        Monitoring
      Week 9-12 Real Project
        Client work
        Case study riêng
        Portfolio
```

---

## 🎯 Learning Paths theo đối tượng

```mermaid
flowchart TD
    Start[👤 Bạn là ai?] --> Q1{Đối tượng?}

    Q1 -->|Business User| BizPath[🏢 Business Track]
    Q1 -->|Developer| DevPath[⚙️ Developer Track]
    Q1 -->|DevOps SRE| OpsPath[🛠️ DevOps Track]
    Q1 -->|AI Engineer| AIPath[🤖 AI Track]

    BizPath --> B1[1. Foundations]
    B1 --> B2[3. Core Concepts]
    B2 --> B3[8. Enterprise Use Cases]
    B3 --> B4[9. Personal Productivity]
    B4 --> B5[11. Case Studies]
    B5 --> B6[10. Best Practices basic]

    DevPath --> D1[3. Core Concepts]
    D1 --> D2[4. Expressions & Code]
    D2 --> D3[5. Patterns & Errors]
    D3 --> D4[10. Best Practices full]
    D4 --> D5[6. AI & LangChain]

    OpsPath --> O1[2. Installation]
    O1 --> O2[7. Production & Scaling]
    O2 --> O3[10. Security + Perf]
    O3 --> O4[12. Troubleshooting]

    AIPath --> A1[3. Core Concepts]
    A1 --> A2[4. Expressions]
    A2 --> A3[6. AI & LangChain DEEP]
    A3 --> A4[11. AI Case Studies]

    style BizPath fill:#f59e0b,stroke:#fff,color:#fff
    style DevPath fill:#06b6d4,stroke:#fff,color:#fff
    style OpsPath fill:#10b981,stroke:#fff,color:#fff
    style AIPath fill:#a855f7,stroke:#fff,color:#fff
```

---

## 📚 Reference — Cheatsheet nhanh

### Critical Environment Variables

| Variable | Mục đích | Bắt buộc |
|----------|----------|----------|
| `N8N_ENCRYPTION_KEY` | Encrypt credentials (32+ chars) | ✅ Có |
| `DB_TYPE=postgresdb` | PostgreSQL production | ✅ Có |
| `N8N_PROTOCOL=https` | Force HTTPS | ✅ Có |
| `WEBHOOK_URL` | Public webhook URL | ✅ Webhook |
| `EXECUTIONS_MODE=queue` | Queue mode | ✅ Scale |
| `QUEUE_BULL_REDIS_HOST` | Redis broker | ✅ Queue |
| `N8N_METRICS=true` | Prometheus endpoint | 🟡 Khuyến nghị |
| `GENERIC_TIMEZONE` | Default TZ | 🟡 Khuyến nghị |

### Common Expressions

```javascript
// Access data
{{ $json.field_name }}
{{ $input.first().json.field }}
{{ $('Node Name').all() }}

// Date/time
{{ $now.format('yyyy-MM-dd') }}
{{ DateTime.fromISO($json.date) }}

// Operations
{{ $input.all().map(item => item.json.name) }}
{{ $input.all().filter(item => item.json.status === 'active') }}
{{ $input.all().reduce((sum, item) => sum + item.json.amount, 0) }}
```

### CLI essentials

```bash
# Start n8n
docker-compose up -d

# View logs
docker-compose logs -f n8n

# Export all workflows
n8n export:workflow --all --output=./workflows/

# Test webhook
curl -X POST https://n8n.domain.com/webhook/test \
  -H "Content-Type: application/json" \
  -d '{"test": true}'

# Backup database
docker-compose exec postgres pg_dump -U n8n n8n > backup.sql
```

---

## 🔗 Sources & References

- [n8n Official Docs](https://docs.n8n.io)
- [n8n Blog](https://blog.n8n.io)
- [Queue Mode Configuration](https://docs.n8n.io/hosting/scaling/queue-mode/)
- [AI Agents Guide 2026](https://blog.n8n.io/ai-agents-examples/)
- [n8n Case Studies](https://n8n.io/case-studies/)
- [Community Forum](https://community.n8n.io)
- [GitHub Repository](https://github.com/n8n-io/n8n)
- Docs nội bộ workspace: `/docs` (21 files)

---

**Phiên bản:** 1.0 · **Last updated:** May 18, 2026 · **License:** Personal use
