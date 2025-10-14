# Navigate to your PHH work folder
Set-Location $PSScriptRoot

# Initialize Git if not already done
if (-not (Test-Path ".git")) {
    git init
    git branch -m main
}

# Add all files and commit
git add .
git commit -m "Initial commit of PHH work folder"

# Set remote (replace with your actual repo URL)
$remoteUrl = "https://github.com/cnua/PokerHandHistoryETL.git"
git remote add origin $remoteUrl

# Push to remote
git push -u origin main
