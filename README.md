# PokerHandHistoryETL
with respect to betfair poker history files
	create a datalake compliant database 
		promotes continuity
		disaster recovery
		take off the OS file system for data redundancy
### windows powershell script design
	C:\Users\<windows-username>\AppData\Local\Betfair Poker\data\<betfair-username>\History\Data
	├── Tables\         # Cash game history
	├── Tournaments\    # Tournament session logs