#!/bin/bash

# ReconDragon-X Ultimate v1.1 Installer 🐉

echo "🔥 Installing Dependencies..."
sudo apt update -y && sudo apt install -y golang git python3 python3-pip jq parallel massdns puredns curl

echo "🔥 Installing Go Tools..."
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/tomnomnom/assetfinder@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/tomnomnom/gf@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/ffuf/ffuf/v2@latest

echo "🔥 Installing Python Tools..."
pip3 install hakrawler arjun qsreplace

echo "🔥 Installing GF Patterns..."
mkdir -p ~/.gf
git clone https://github.com/1ndianl33t/Gf-Patterns ~/.gf-patterns || cd ~/.gf-patterns && git pull
cp ~/.gf-patterns/*.json ~/.gf/

echo "🔥 Installation Complete ✅"
