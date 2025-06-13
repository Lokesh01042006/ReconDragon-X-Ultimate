# 🔥 ReconDragon-X Ultimate 🐉

> Fully automated Bug Bounty Reconnaissance Framework  
> Developed by **Lokesh**

---

## ⚔️ Features

- ✅ Subdomain Enumeration
- ✅ DNS Resolution (PureDNS + MassDNS)
- ✅ HTTP Probing (httpx)
- ✅ URL Collection (gau, waybackurls, hakrawler)
- ✅ Parameter Discovery (gf, arjun, qsreplace)
- ✅ Directory Bruteforce (ffuf)
- ✅ Vulnerability Scanning (nuclei)
- ✅ Telegram Notifications
- ✅ Fully Automated SaaS-grade Recon Engine

---

## ⚙ Requirements

- Linux (Kali Linux or any Debian based OS)
- Python3
- Golang
- GitHub Account (for installation)
- Telegram Account (for notifications)

---

## 🚀 Installation

### 1️⃣ Clone Repository

git clone https://github.com/Lokesh01042006/ReconDragon-X-Ultimate.git  
cd ReconDragon-X-Ultimate

### 2️⃣ Give Permissions

chmod +x install.sh update.sh recondragon.sh

### 3️⃣ Install Dependencies

./install.sh

---

## 🔐 Telegram Notification Setup

### 1️⃣ Create Telegram Bot

- Talk to @BotFather
- Run /newbot → Get your BOT TOKEN

### 2️⃣ Get Chat ID

- Send message to your bot.
- Visit this URL:

https://api.telegram.org/bot<YOUR-TOKEN>/getUpdates

- Copy your chat id from response.

### 3️⃣ Edit Config

nano config.env

Paste:

BOT_TOKEN="your-telegram-bot-token"  
CHAT_ID="your-chat-id"

✅ Save.

---

## 🌐 DNS Resolvers Setup

Edit your resolvers.txt file:

nano resolvers.txt

Paste some public resolvers:

1.1.1.1  
8.8.8.8  
8.8.4.4  
9.9.9.9  
208.67.222.222

---

## 📂 Wordlist (already included)

If missing:

mkdir wordlists  
wget https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt -O wordlists/fast-wordlist.txt

---

## 🚀 Usage

./recondragon.sh target.com

or full URL:

./recondragon.sh https://sub.target.com/path

✅ Recon fully automated.

---

## 🔄 Update Tools

./update.sh

---

## 📊 Output

- Subdomains
- Resolved Domains
- Live Hosts
- URLs
- Parameters
- Vulnerabilities
- Reports generated automatically.

---

## 🔥 Author

- Developed by Lokesh
- Built with ❤️ for Bug Bounty Hunters

---

## 📄 License

MIT License — Free to use, modify & share!

---

