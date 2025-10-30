▶️ Step-by-Step Instructions to Run PSWorks Scripts Sequentially
1. 📁 Navigate to the Repository Folder
Open PowerShell and change directory to the cloned repo:

powershell
cd "C:\Path\To\PSPokerLakeV1\PSWorks"
2. 📜 Review Script Order
The scripts are designed to run in a logical sequence:

text
01_create-config.ps1
02_create-instance-db-tables.ps1
03_create-db-instance-tables.ps1
04_create-datalake-history.ps1
11_diagnostics.ps1
You should run them in this numeric order unless your config or environment requires skipping or customizing steps.

3. ▶️ Execute Each Script
Run each script one by one using:

powershell
.\01_create-config.ps1
.\02_create-instance-db-tables.ps1
.\03_create-db-instance-tables.ps1
.\04_create-datalake-history.ps1
.\11_diagnostics.ps1
4. 🛡️ Optional: Bypass Execution Policy (if blocked)
If you get a policy error, you can temporarily allow script execution:

powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
5. 🧪 Validate Output
After each script, check for:

Console output confirming success

Database tables created or updated

Logs or diagnostics (especially from 11_diagnostics.ps1)

Would you like a wrapper script to automate this sequence with logging and error handling? I can generate one that’s ergonomic and CI/CD-friendly.

clarify the data folder is akin to the history file folder root and that the files placed there do the job automatically to create localddb etc and upload subdirectioriesof xml history files endpoint
Here’s a clear and public-facing clarification you can include in your README or documentation:

📂 Understanding the Data Folder: Your History File Root
The Data folder acts as the root directory for your Betfair Poker history files. It mirrors the structure found under:

Code
C:\Users\<windows-username>\AppData\Local\Betfair Poker\data\<betfair-username>\History\Data
Within this folder, you should place your poker session logs in the following subdirectories:

Code
Data\
├── Tables\         # Cash game history files (XML)
├── Tournaments\    # Tournament session logs (XML)
Once these files are in place, the PowerShell scripts in the PSWorks folder will:

Auto-detect the folder structure

Create a local SQL Server LocalDB instance

Ingest and normalize the XML files

Populate a data lake–compliant schema

No manual intervention is needed beyond placing the files correctly. The system is designed for plug-and-play ingestion—just drop your history files into the right folders, run the scripts in order, and your local data lake will be ready for analysis or backup.
