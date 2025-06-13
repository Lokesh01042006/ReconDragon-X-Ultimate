#!/bin/bash

# ReconDragon-X Ultimate v1.1 Hardened Build 🐉

# Load Config (Telegram Notifier)
source config.env

# Global Vars
input=$1
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

# Input Sanitizer
domain=$(echo $input | sed -E 's~(http[s]?://)?(www\.)?~~' | cut -d/ -f1)

root_dir="${domain}_ReconDragon_${timestamp}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Notifier Function
notify() {
    curl -s -X POST https://api.telegram.org/bot${BOT_TOKEN}/sendMessage \
    -d chat_id=${CHAT_ID} \
    -d text="$1"
}

# Banner
echo -e "${CYAN}"
echo "██████╗ ███████╗ ██████╗  ██████╗ ███╗   ██╗██████╗  █████╗"
echo "██╔══██╗██╔════╝██╔═══██╗██╔═══██╗████╗  ██║██╔══██╗██╔══██╗"
echo "██║  ██║█████╗  ██║   ██║██║   ██║██╔██╗ ██║██║  ██║███████║"
echo "██║  ██║██╔══╝  ██║   ██║██║   ██║██║╚██╗██║██║  ██║██╔══██║"
echo "██████╔╝███████╗╚██████╔╝╚██████╔╝██║ ╚████║██████╔╝██║  ██║"
echo "╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝"
echo -e "${NC}"

if [ -z "$domain" ]; then
  echo -e "${RED}Usage: $0 <domain>${NC}"
  exit 1
fi

mkdir -p $root_dir/{subdomains,dns,urls,params,scans/ffuf,scans/nuclei,reports,logs}
logfile="$root_dir/logs/recondragon.log"
touch $logfile

notify "Recon Started: $domain"

########################################
# Subdomain Enumeration
########################################
echo -e "${YELLOW}[i] Subdomain Enumeration...${NC}"
subfinder -all -d $domain -silent > $root_dir/subdomains/subfinder.txt 2>> $logfile
assetfinder --subs-only $domain > $root_dir/subdomains/assetfinder.txt 2>> $logfile
amass enum -passive -d $domain > $root_dir/subdomains/amass.txt 2>> $logfile

cat $root_dir/subdomains/*.txt | sort -u > $root_dir/subdomains/all_subdomains.txt
subs=$(wc -l < $root_dir/subdomains/all_subdomains.txt)
echo -e "${GREEN}[+] Subdomains: ${subs}${NC}"

########################################
# DNS Resolution
########################################
echo -e "${YELLOW}[i] DNS Resolution...${NC}"
puredns resolve $root_dir/subdomains/all_subdomains.txt -r resolvers.txt -w $root_dir/dns/puredns_resolved.txt 2>> $logfile

if [ ! -s $root_dir/dns/puredns_resolved.txt ]; then
  echo -e "${RED}[!] Puredns failed, switching to massdns...${NC}"
  massdns -r resolvers.txt -t A -o S -w $root_dir/dns/massdns_raw.txt -q $root_dir/subdomains/all_subdomains.txt 2>> $logfile
  cat $root_dir/dns/massdns_raw.txt | awk '{print $1}' | sed 's/\.$//' | sort -u > $root_dir/dns/resolved.txt
else
  cp $root_dir/dns/puredns_resolved.txt $root_dir/dns/resolved.txt
fi

resolved=$(wc -l < $root_dir/dns/resolved.txt)
echo -e "${GREEN}[+] Resolved: ${resolved}${NC}"

########################################
# HTTP Probing (fixed version for latest httpx)
########################################
echo -e "${YELLOW}[i] HTTP Probing...${NC}"
httpx -l $root_dir/dns/resolved.txt -status-code -title -tech-detect -ip -cname -cdn -web-server -tls-probe -rl 50 -timeout 15 -retries 2 -o $root_dir/dns/httpx_raw.txt 2>> $logfile

grep -E '([23]0[0-9]|403)' $root_dir/dns/httpx_raw.txt | cut -d ' ' -f 1 | sort -u > $root_dir/dns/live_hosts.txt
live=$(wc -l < $root_dir/dns/live_hosts.txt)
echo -e "${GREEN}[+] Live Hosts: ${live}${NC}"

########################################
# URL Collection
########################################
echo -e "${YELLOW}[i] URL Collection...${NC}"
cat $root_dir/dns/live_hosts.txt | gau > $root_dir/urls/gau_raw.txt 2>> $logfile
cat $root_dir/dns/live_hosts.txt | waybackurls > $root_dir/urls/wayback_raw.txt 2>> $logfile
cat $root_dir/dns/live_hosts.txt | hakrawler -depth 3 -plain > $root_dir/urls/hakrawler_raw.txt 2>> $logfile

cat $root_dir/urls/*.txt | sort -u > $root_dir/urls/all_urls.txt
urls=$(wc -l < $root_dir/urls/all_urls.txt)
echo -e "${GREEN}[+] URLs: ${urls}${NC}"

########################################
# Parameter Mining
########################################
echo -e "${YELLOW}[i] Parameter Mining...${NC}"
grep "=" $root_dir/urls/all_urls.txt > $root_dir/params/param_urls.txt

for pattern in xss sqli ssrf redirect rce lfi ssti s3-buckets idor debug interestingparams interestingEXT; do
    cat $root_dir/urls/all_urls.txt | gf $pattern >> $root_dir/params/gf_${pattern}.txt 2>> $logfile
done

cat $root_dir/params/gf_*.txt | sort -u > $root_dir/params/gf_all.txt
arjun -i $root_dir/urls/all_urls.txt -t 20 -o $root_dir/params/arjun_params.txt 2>> $logfile

cat $root_dir/params/param_urls.txt $root_dir/params/arjun_params.txt $root_dir/params/gf_all.txt | sort -u > $root_dir/params/final_parameters.txt
cat $root_dir/params/final_parameters.txt | qsreplace FUZZ > $root_dir/params/fuzz_ready.txt
params=$(wc -l < $root_dir/params/final_parameters.txt)
echo -e "${GREEN}[+] Parameters: ${params}${NC}"

########################################
# Directory Bruteforce
########################################
echo -e "${YELLOW}[i] Directory Bruteforce...${NC}"
wordlist_path="./wordlists/fast-wordlist.txt"

bruteforce() {
    url=$1
    clean=$(echo $url | sed 's/https\?:\/\///g' | tr '/:' '__')
    ffuf -u ${url}/FUZZ -w ${wordlist_path} -t 50 -timeout 10 -ac -mc 200,204,301,302,307,401,403 -o $root_dir/scans/ffuf/${clean}.json -of json 2>> $logfile
}

export -f bruteforce
cat $root_dir/dns/live_hosts.txt | parallel -j 10 bruteforce
echo -e "${GREEN}[+] FFUF Completed.${NC}"

########################################
# Vulnerability Scanning
########################################
echo -e "${YELLOW}[i] Vulnerability Scanning...${NC}"
nuclei -l $root_dir/dns/live_hosts.txt -severity info,low,medium,high,critical -t $HOME/nuclei-templates/ -c 50 -timeout 15 -retries 2 -rl 50 -o $root_dir/scans/nuclei/nuclei_results.txt 2>> $logfile
vulns=$(wc -l < $root_dir/scans/nuclei/nuclei_results.txt)
echo -e "${GREEN}[+] Nuclei Results: ${vulns}${NC}"

########################################
# Reporting
########################################
echo -e "${YELLOW}[i] Generating Report...${NC}"
report="$root_dir/reports/${domain}_report.md"

echo "# ReconDragon-X Report for $domain" > $report
echo "_Generated on: $timestamp_" >> $report
echo "" >> $report

echo "## Subdomains: ${subs}" >> $report
echo "## Resolved: ${resolved}" >> $report
echo "## Live Hosts: ${live}" >> $report
echo "## URLs: ${urls}" >> $report
echo "## Parameters: ${params}" >> $report
echo "## Vulnerabilities: ${vulns}" >> $report

notify "Recon Completed for $domain 🔥 Report generated."
echo -e "${GREEN}[+] Scan Finished ✅${NC}"
