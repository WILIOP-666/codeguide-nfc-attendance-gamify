flowchart TD
    A[Start App] --> B[Sign In Sign Up]
    B --> C{Auth Successful}
    C -->|Yes| D{Role Selection}
    C -->|No| B
    D -->|User| E[User Dashboard]
    D -->|Admin| F[Admin Dashboard]
    D -->|Owner| G[Owner Dashboard]
    F --> H[NFC Check In Screen]
    H --> I[Read Card UID]
    I --> J[Call record-attendance Edge Function]
    J --> K{Valid Card}
    K -->|Yes| L[Attendance Recorded\nPoints Awarded\nTrigger Realtime Update]
    K -->|No| M[Error Message]
    E --> N[View Attendance History]
    E --> O[View Points & Badges]
    E --> P[View Leaderboard]
    F --> Q[Manage Classes\nReview Attendance\nProcess Orders]
    G --> R[View Analytics Charts\nOverall Engagement\nLeaderboard]
    E --> S[Redeem Points for Merchandise]
    S --> T[Call process-redemption Edge Function]
    T --> U[Order Processed\nPoints Deducted\nNotification]
    L --> V[Realtime Update to Clients]
    U --> V
    M --> H