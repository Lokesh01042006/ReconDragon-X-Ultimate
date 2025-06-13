#!/bin/bash

echo "🔥 Updating ReconDragon-X tools..."

echo "[*] Updating nuclei templates..."
nuclei -update-templates

echo "[*] Updating subfinder..."
subfinder -update

echo "[*] Updating gf patterns..."
cd ~/.gf-patterns && git pull && cp *.json ~/.gf/

echo "[*] All tools updated ✅"
