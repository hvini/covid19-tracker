#!/bin/bash

check_dependencies()
{
  type jq >/dev/null 2>&1 || { echo >&2 "jq is not installed. https://stedolan.github.io/jq/"; exit 1; }
  type curl >/dev/null 2>&1 || {  echo >&2 "curl is not installed. https://github.com/curl/curl"; exit 1; }
}

banner()
{
  if [ "$nobanner" != true ]; then
    echo "
  ___  __   _  _  __  ____     __  ___  
 / __)/  \ / )( \(  )(    \   /  \/ _ \ 
( (__(  O )\ \/ / )(  ) D (  (_/ /\__  )
 \___)\__/  \__/ (__)(____/   (__)(___/ 
    "
  fi
}

usage()
{
echo "usage: $0 [options]:

Copyright (c) 2020 hvini. Permission to include in application software
or to make digital or hard copies of part or all of this work is subject to the MIT License agreement.
https://github.com/hvini/covid19-tracker

common options:
  -a,  --list-all      List all countries statistics for today and yesterday.
  -c,  --country       Filters an historical and non historical list by country.
  -d,  --days          Filters an historical list by no. days { 15, 24, 30 or all }.
  -g,  --global        List global statistics for today and yesterday.
  -h,  --help          Open the help menu.
  -hI, --historical    Shows sparklines graphs for no. cases, deaths and recovered,
                       for global historical statistics. If a days filter is not entered,
                       the default value for the listing will be for the last 30 days.
  -n,  --no-banner     Hide the /covid19/ banner.
examples:
  ./covid.sh -a -c brazil
  ./covid.sh -hI -c brazil -d all
  ./covid.sh --global
  "
}

error()
{
  printf "Error: $@"
  exit 1;
}

exceptions()
{
  if [ "$listall" == true ] && [ "$listcountry" == true ]; then
    error "-a|--list-all and -c|--country cannot be mixed!\n"

  elif [ "$listall" == true ] && [ "$global" == true ]; then
    error "-a|--list-all and -g|--global cannot be mixed!\n"

  elif [ "$listall"  == true ] && [ "$historical" == true ]; then
    error "-a|--list-all and -hI|--historical cannot be mixed!\n"

  elif [ "$listall" == true ] && [ "$days" == true ]; then
    error "-a|--listall and -d|--days cannot be mixed!\n"

  elif [ "$global" == true ] && [ "$listcountry" == true ]; then
    error "-g|--global and -c|--country cannot be mixed!\n"

  elif [ "$global" == true ] && [ "$historical" == true ]; then
    error "-g|--global and -hI|--historical cannot be mixed!\n"

  elif [ "$global" == true ] && [ "$days" == true ]; then
    error "-g|--global and -d|--days cannot be mixed\n"
  fi
}

main()
{
  BASE_URL="https://disease.sh/v3/covid-19"
  ALLCOUNTRIES_URL="$BASE_URL/countries"
  HISTORICAL_URL="$BASE_URL/historical"

  exceptions

  if [ "$listall" == true ]; then
    banner
    printf "Listing all countries statistics\n"
    printf "Please, wait while the data is fetched, may take a while\n\n"
    data=$(curl -s -X GET "$ALLCOUNTRIES_URL" -H "accept: application/json")
    
    res=$(echo $data | jq -r '("country, population, cases, deaths, recovered"), (.[] | "\(.country), \(.population), \(.cases), \(.deaths), \(.recovered)")')
    printTable "," "$res"
  
  elif [ -n "$country" ] && [ -z "$historical" ]; then
    banner
    printf "country: $country\n\n"

    data=$(curl --fail -Ss -X GET "$ALLCOUNTRIES_URL/$country" -H "accept: application/json")
    
    cases=$(echo $data | jq ".cases")
    deaths=$(echo $data | jq ".deaths")
    recovered=$(echo $data | jq ".recovered")

    printf "${yellow}cases:${reset} ${cases}\t"
    printf "${red}deaths:${reset} ${deaths}\t"
    printf "${green}recovered:${reset} ${recovered}\t\n"
  
  elif [ -z "$country" ] && [ "$historical" == true ] && [ -z "$nodays" ]; then
    banner
    printf "Sparkline for global historical statistics\n\n"

    data=$(curl -s -X GET "$HISTORICAL_URL/all" -H "accept: application/json")
    
    cases=$(echo $data | jq -r '.cases' | jq '.[]')
    deaths=$(echo $data | jq -r '.deaths' | jq '.[]')
    recovered=$(echo $data | jq -r '.recovered' | jq '.[]')
    
    printf "cases: $(spark ${cases})\n\n"
    printf "deaths: $(spark ${deaths})\n\n"
    printf "recovered: $(spark ${recovered})\n\n"
  
  elif [ -z "$country" ] && [ "$historical" == true ] && [ -n "$nodays" ]; then
    (banner
    printf "Listing global historical statistics\n\n"

    data=$(curl -s -X GET "$HISTORICAL_URL/all?lastdays=$nodays" -H "accept: application/json")
    
    cases=$(echo $data | jq -r '.cases' | jq '.[]')
    deaths=$(echo $data | jq -r '.deaths' | jq '.[]')
    recovered=$(echo $data | jq -r '.recovered' | jq '.[]')

    printf "cases: $(spark ${cases})\n\n"
    printf "deaths: $(spark ${deaths})\n\n"
    printf "recovered: $(spark ${recovered})\n\n") | less -S

  elif [ -n "$country" ] && [ "$historical" == true ] && [ -z "$nodays" ]; then
    banner
    printf "country: ${country}\n\n"

    data=$(curl -s -X GET "$HISTORICAL_URL/$country" -H "accept: application/json")
    
    cases=$(echo $data | jq -r '.timeline.cases' | jq '.[]')
    deaths=$(echo $data | jq -r '.timeline.deaths' | jq '.[]')
    recovered=$(echo $data | jq -r '.timeline.recovered' | jq '.[]')

    printf "cases: $(spark ${cases})\n\n"
    printf "deaths: $(spark ${deaths})\n\n"
    printf "recovered: $(spark ${recovered})\n\n"

  elif [ -n "$country" ] && [ "$historical" == true ] && [ -n "$nodays" ]; then
    (banner
    printf "country: ${country}\n\n"

    data=$(curl -s -X GET "$HISTORICAL_URL/$country?lastdays=$nodays" -H "accept: application/json")
    
    cases=$(echo $data | jq -r '.timeline.cases' | jq '.[]')
    deaths=$(echo $data | jq -r '.timeline.deaths' | jq '.[]')
    recovered=$(echo $data | jq -r '.timeline.recovered' | jq '.[]')

    printf "cases: $(spark ${cases})\n\n"
    printf "deaths: $(spark ${deaths})\n\n"
    printf "recovered: $(spark ${recovered})\n\n") | less -S

  elif [ "$help" == true ]; then
    banner
    usage

  elif [ "$global" == true ]; then
    banner
    printf "Listing global statistics\n\n"

    data=$(curl -s -X GET "$BASE_URL/all" -H "accept: application/json")
    
    cases=$(echo $data | jq ".cases")
    deaths=$(echo $data | jq ".deaths")
    recovered=$(echo $data | jq ".recovered")
    
    printf "${yellow}cases:${reset} ${cases}\t"
    printf "${red}deaths:${reset} ${deaths}\t"
    printf "${green}recovered:${reset} ${recovered}\t\n"
  fi
}

basedir=$( cd `dirname $0`; pwd )
source ${basedir}/libs/spark
. ${basedir}/libs/util.bash

# colors
green=`tput setaf 2`
red=`tput setaf 1`
reset=`tput sgr0`
yellow=`tput setaf 3`

# shows usage menu if no parameter are entered
if [ $# -eq 0 ]; then
  usage
fi

# checking if all needed dependencies are installed
check_dependencies

# getting the input flags
while test $# -gt 0; do
  case "$1" in
    -a|--list-all)
    listall=true
    ;;
    -c|--country)
    listcountry=true
    shift
    country="$1"
    ;;
    -d|--days)
    days=true
    shift
    nodays="$1"
    ;;
    -g|--global)
    global=true
    ;;
    -h|--help)
    help=true
    ;;
    -hI|--historical)
    historical=true
    ;;
    -n|--no-banner)
    nobanner=true
    ;;
    *)
    printf "Invalid command '$1'\n"
    exit 1
  esac
  shift
done

main