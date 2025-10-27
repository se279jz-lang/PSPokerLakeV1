# A Data Lake for Betfair Poker Histories
PSPokerLakeV1 is a PowerShell-driven toolkit designed to transform Betfair Poker history files into a structured, disaster-resilient data lake. Built for analysts, engineers, and poker enthusiasts, it enables seamless ingestion of session logs and cash game data into a SQL-compliant format—ideal for downstream analytics, machine learning, and long-term archival.

### 🔍 Key Features
- Data Lake Compliance: Converts raw XML poker logs into a normalized database structure.

- Disaster Recovery Ready: Eliminates reliance on OS-level file systems, promoting continuity and redundancy.

- Modular Scripts: PowerShell orchestrators run sequentially, designed for ergonomic deployment and easy adaptation.

- Schema Fidelity: Preserves table and tournament structures for accurate historical replay and analysis.

#### 📁 Input Path Convention
Windows10 Betfair history path pattern
```
C:\Users\<windows-username>\AppData\Local\Betfair Poker\data\<betfair-username>\History\Data
├── Tables\       # Cash game history
├── Tournaments\  # Tournament session logs
```
### 🛠️ Tech Stack
- Languages: PowerShell (82%), T-SQL (18%)
- License: MIT
- Latest Release: PSPokerHistory_SqlLocalDbDataLake
