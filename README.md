# Vuln-Scanner
## Web Application Vulnerability Scanner

![vuln-scanner-options](https://github.com/user-attachments/assets/af6763ca-fbb0-43f9-a01c-e78eb3dfa0f8)



### About
---

vuln-scanner allows you to scanning web vulnerability using many tools on kali linux instantly. this program mainly is use and tested using kali linux. it makes _pentesting_ more easier for vulnerability analisys of your client's web and save more time.

### Installation
---
To install `vuln-scaner`, follow these steps:

```
curl -LO https://github.com/felikafelix/Vuln-Scanner/releases/latest/download/vulnscan.tar.gz
tar -xzvf vulnscan.tar.gz
sudo chmod +x vulnscan
sudo mv vulnscan /usr/local/bin
```
### Usage
---
To use `vuln-scanner`, follow these steps:
```
vulnscan --domain example.com
```
### Examples
---
Here are a few examples of how to use vuln-scanner:
- help message:
  ```
  vulnscan --help
  ```
- perform basic scan:
  ```
  vulnscan --domain example.com
  ```
- perform scan using wpscan api:
  - using wpscan api, will give you any CVE or any known vulnerability on wpscan job
  ```
  vulnscan --domain example.com --wpscan-api API_KEY
  ```
- perform custom scan
  ```
  vulnscan --protocol http --wpscan-api API_KEY --domain example.com --port PORT
  ```
  
### Notes
---
This script is performing scan using some of the *built-in* programs from [Kali Linux](https://www.kali.org), and tested using [Kali Linux](https://www.kali.org)

### Tools used in this script
---
- tools built in Kali Linux:
  - wpscan
  - nmap
  - cewl
  - wafw00f
  - whatweb
- other tools:
  - [dirsearch](https://github.com/maurosoria/dirsearch.git)
  - [subfinder](https://github.com/projectdiscovery/subfinder)
  - [paramspider](https://github.com/devanshbatham/ParamSpider.git)
  - [whatwaf](https://github.com/Ekultek/WhatWaf.git)
 
### Tips
---
- for safety, ensure **running this script using proxychains or anonsurf**
- anonsurf will route all your traffic inside the vm to __TOR__ network
- proxychains will do the same, but just specific program run using proxychains. the program will run inside sandbox
- you can configure TOR's MaxCircuitDirtiness to 1, or any value you want


> **DO NOT USE FOR SCAN PEOPLE'S WEB WITHOUT THEIR PERMISSION**
