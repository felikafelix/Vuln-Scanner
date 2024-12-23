#!/bin/bash

# Domain Validation Function
print_label() {
    echo ""
    printf "%*s%s%*s" $(($(tput cols)/2 - ${#1}/2 - 1)) | tr ' ' '='
    printf " $1 "
    printf "%*s\n" $(($(tput cols)/2 - ${#1}/2 - 1)) | tr ' ' '='
    echo ""
}
# Usage examples
#print_label "SCAN RESULTS"
#print_label "ERROR" "!" "\e[31m"  # Red
#print_label "SUCCESS" "+" "\e[32m"  # Green
#print_label "WARNING" "*" "\e[33m"  # Yellow
validate_domain() {
    local domain="$1"
    
    # Regex for domain validation
    local domain_regex="^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"
    
    # Check if domain is empty or not provided
    if [[ -z "$domain" ]]; then
        echo "Error: Domain cannot be empty."
        return 1
    fi
    
    # Check domain length (max 255 characters)
    if [[ ${#domain} -gt 255 ]]; then
        echo "Error: Domain is too long (max 255 characters)."
        return 1
    fi
    
    # Check against regex pattern
    if [[ ! "$domain" =~ $domain_regex ]]; then
        echo "Error: Invalid domain format."
        return 1
    fi
    
    # Optional: Uncomment for DNS resolution check
    if ! host "$domain" &>/dev/null; then
        echo "Warning: Domain cannot be resolved. It might not exist or DNS is not accessible."
        read -p "Do you want to continue? (y/n): " continue_choice
        if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
            return 1
        fi
    fi
    
    return 0
}

# Dependencies check
if ! command -v figlet &>/dev/null && ! command -v toilet &>/dev/null; then
    echo "Error: figlet or toilet is required to display the banner. Please install one of them."
    echo "To install figlet: sudo apt-get install figlet"
    echo "To install toilet: sudo apt-get install toilet"
    exit 1
fi

# Display Banner
if command -v figlet &>/dev/null; then
    figlet -c "VULN-SCANNER"
    echo "      Web Application Vulnerability Scaner"
    echo ""
else
    toilet -f big -F border --gay "VULN-SCANNER"
fi

# Check if the OS is Kali Linux or not
if [[ "$(lsb_release -is)" != "Kali" ]]; then
    echo "This script only runs on Kali Linux ^^"
    exit 1
fi

# Default values
domain=""
port=""
protocol="https"
wpscan_api=""

# Functions
show_version() {
    echo "Vulnerability Scanner Shortcut 1.0"
    exit 0
}

show_help() {
    echo ""
    echo "Options:"
    echo "   -h, --help              Show this help message"
    echo "   -v, --version           Show the version of this script"
    echo "   --domain DOMAIN         (Mandatory) Specify the domain to scan"
    echo "   --port PORT             (Optional) Specify the port to use (default: 443 for HTTPS, 80 for HTTP)"
    echo "   --protocol PROTOCOL     (Mandatory) Specify the protocol to use (default: https)"
    echo "   --wpscan-api API_KEY    (Optional) Provide the WPScan API key"
    echo "   to use whatwaf, download and instal it yourself, https://github.com/Ekultek/WhatWaf, then symlink it to /usr/local/bin"
    exit 0
}

# Parse options
while [[ $# -gt 0 ]]; do
    current_arg="$1"
    
    # Aggressive parsing for concatenated options
    if [[ "$current_arg" == --domain*--* ]]; then
        # Extract domain (everything between --domain and next --)
        domain="${current_arg#--domain}"
        domain="${domain%%--*}"
        
        # Remove domain part from argument
        current_arg="${current_arg#*--}"
    fi

    case "$current_arg" in
        --help)
            show_help
            ;;
        --version)
            show_version
            ;;
        --domain*)
            # Multiple parsing strategies
            if [[ "$current_arg" == --domain=* ]]; then
                domain="${current_arg#*=}"
            elif [[ "$current_arg" == --domain ]]; then
                shift
                domain="$1"
            else
                # Aggressive extraction for cases like --domainsdfsa.cs
                domain="${current_arg#--domain}"
            fi

            if [[ -z "$domain" ]]; then
                echo "Error: --domain requires a valid argument."
                exit 1
            fi
            ;;
        --protocol*)
            # Multiple parsing strategies for protocol
            if [[ "$current_arg" == --protocol=* ]]; then
                protocol="${current_arg#*=}"
            elif [[ "$current_arg" == --protocol ]]; then
                shift
                protocol="$1"
            else
                # Aggressive extraction
                protocol="${current_arg#--protocol}"
            fi

            if [[ -z "$protocol" ]]; then
                echo "Error: --protocol requires a valid argument."
                exit 1
            fi

            if [[ "$protocol" != "http" && "$protocol" != "https" ]]; then
                echo "Error: --protocol must be either 'http' or 'https'."
                exit 1
            fi
            ;;
        --port*)
            # Multiple parsing strategies for port
            if [[ "$current_arg" == --port=* ]]; then
                port="${current_arg#*=}"
            elif [[ "$current_arg" == --port ]]; then
                shift
                port="$1"
            else
                # Aggressive extraction
                port="${current_arg#--port}"
            fi

            if [[ -z "$port" ]]; then
                echo "Error: --port requires a valid argument."
                exit 1
            fi
            ;;
        --wpscan-api*)
            # Multiple parsing strategies for wpscan-api
            if [[ "$current_arg" == --wpscan-api=* ]]; then
                wpscan_api="${current_arg#*=}"
            elif [[ "$current_arg" == --wpscan-api ]]; then
                shift
                wpscan_api="$1"
            else
                # Aggressive extraction
                wpscan_api="${current_arg#--wpscan-api}"
            fi

            if [[ -z "$wpscan_api" ]]; then
                echo "Error: --wpscan-api requires a valid argument."
                exit 1
            fi
            ;;
        *)
            # Catch-all for any unrecognized patterns
            echo "Error: Unknown option or malformed argument: $current_arg"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
    shift
done

# Validate domain
if ! validate_domain "$domain"; then
    echo "Domain validation failed. Please provide a valid domain."
    show_help
    exit 1
fi

# Validate mandatory options
if [[ -z "$domain" ]]; then
    echo "Error: --domain is required."
    show_help
    exit 1
fi

if [[ -z "$protocol" ]]; then
    echo "Error: --protocol is required."
    show_help
    exit 1
fi

# Derive URL
if [[ -z "$port" ]]; then
    # Set default port based on protocol
    if [[ "$protocol" == "https" ]]; then
        port=443
    elif [[ "$protocol" == "http" ]]; then
        port=80
    fi
fi
url="${protocol}://${domain}:${port}"

# Main script logic
echo "Domain to scan: $domain"
echo "Port: $port"
echo "Protocol: $protocol"
echo "Constructed URL: $url"

print_label "Warning!!"

# Warning for running this script using proxies
echo "Only run this script using a VPN or proxy, like ProxyChains or AnonSurf, that uses the Tor network and configures the IP to change every 1 second. This ensures your real IP isn't detected and blocked."
read -p "Are you sure to continue using the current system configuration? (y/n): " response

# Convert response to lowercase
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

# Check user response
if [[ "$response" == "y" || "$response" == "yes" ]]; then
    print_label "Start Scanning"
    echo "Scanning domain: $domain"
    echo "Using URL: $url"
    mkdir -p ./"$domain.vulnscan"
    print_label "Scanning WAF using wafw00f"
    wafw00f $url -v -a -o ./$domain.vulnscan/$domain.wafw00f.txt -f text
    print_label "Scanning WAF using whatwaf"
    whatwaf -u $url --verbose --output ./$domain.vulnscan/$domain.whatwaf.txt --force-file
    print_label "Scanning Services using NMAP"
    nmap -p- -sV -v $domain -Pn -sC --script vuln -oN "./$domain.vulnscan/$domain.nmap.txt" 2>&1
    print_label "Scanning Vulnerability using WPScan"
    # If WPScan API is provided, use it
    if [[ -n "$wpscan_api" ]]; then
        echo "Using WPScan API key: $wpscan_api"
        # Add WPScan logic here
        wpscan --url $url --random-user-agent --api-token $wpscan_api -o "./$domain.vulnscan/$domain.wpscan.txt" --plugins-detection mixed
    else
        echo "No WPScan API key provided. wpscan will not providing vulnerability on the output."
        wpscan --url $url --random-user-agent -o "./$domain.vulnscan/$domain.wpscan.txt" --plugins-detection mixed
        echo ""
    fi
    print_label "Scanning site dir using dirsearch"
    dirsearch -u $url --crawl --full-url --redirects-history -o "./$domain.vulnscan/$domain.dirsearch.csv" --format=csv -x 400-600
    print_label "Scanning Subdomains using subfinder"
    subfinder -d $domain -v -o ./$domain.vulnscan/$domain.subdomain.txt
    print_label "Searching parameter to FUZZ using paramspider"
    paramspider -d $url
    print_label "Creating wordlists based on $url"
    cewl -d 2 -m 5 --with-numbers -e $url -w ./$domain.vulnscan/$domain.wordlist.txt
    print_label "Scan Complete."
    echo "To view scanned file (txt,log,etc), use cat, more, less, etc"
    echo "example : cat filename.txt"
    echo "To view scanned file csv, use csvlook"
    echo "example : csvlook filename.csv"
    echo "if you don't have csvlook, install using : apt install csvkit, pip3 install csvkit, apt install python3-csvkit"

elif [[ "$response" == "n" || "$response" == "no" ]]; then
    echo "Stopping execution."
    exit 0
else
    echo "Invalid input. Please enter 'y' or 'n'."
    exit 1
fi