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
  echo "
  usage: $0 [options]:

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
    -s,  --sort          Sort all countries list from greatest to least, by given a key 
                        {cases, deaths, recovered}
  examples:
    ./covid.sh -a -c brazil
    ./covid.sh -hI -c brazil -d all
    ./covid.sh --global
    ./covid.sh --list-all -s deaths
  "
}

error()
{
  printf "Error: $@"
  exit 1;
}

all_countries_exceptions()
{
  if [ "$listall" == true ] && [ "$listcountry" == true ]; then
    error "You cannot filter by country an all countries listing!\n"

  elif [ "$listall" == true ] && [ "$global" == true ]; then
    error "You cannot use an global listing with an all countries listing!\n"

  elif [ "$listall"  == true ] && [ "$historical" == true ]; then
    error "You cannot use an historical listing with an all countries listing!\n"

  elif [ "$listall" == true ] && [ "$days" == true ]; then
    error "You cannot use a day filter with an all countries listing!\n"
  fi
}

global_exceptions()
{
  if [ "$global" == true ] && [ "$listcountry" == true ]; then
    error "You cannot filter by country an global listing!\n"

  elif [ "$global" == true ] && [ "$historical" == true ]; then
    error "You cannot use an global listing with an historical!\n"

  elif [ "$global" == true ] && [ "$days" == true ]; then
    error "You cannot use a day filter with an global listing!\n"
  fi
}

sort_exceptions()
{
  if [ "$sort" == true ] && [ "$country" == true ]; then
    error "You cannot sort an filtered listing!\n"

  elif [ "$sort" == true ] && [ "$global" == true ]; then
    error "You cannot sort an global listing!\n"

  elif [ "$sort" == true ] && [ "$historical" == true ]; then
    error "You cannot sort an historical listing!\n"
  fi
}

main()
{
  BASE_URL="https://disease.sh/v3/covid-19"
  ALLCOUNTRIES_URL="$BASE_URL/countries"
  HISTORICAL_URL="$BASE_URL/historical"

  all_countries_exceptions
  global_exceptions
  sort_exceptions

  if [ "$listall" == true ]; then
    banner
    printf "Listing all countries statistics\n"
    
    if [ -n "$sortby" ]; then
      printf "sorted by: '$sortby'\n"
    fi

    printf "\nPlease, wait while the data is fetched, may take a while\n"
    data=$(curl -s -X GET "$ALLCOUNTRIES_URL/?sort=$sortby" -H "accept: application/json")
    res=$(echo $data | jq -r '("country, population, cases, deaths, recovered"), (.[] | "\(.country), \(.population), \(.cases), \(.deaths), \(.recovered)")')

    printTable "," "$res"
  
  elif [ -n "$country" ] && [ -z "$historical" ]; then
    banner
    printf "country: $country\n\n"

    data=$(curl --fail -Ss -X GET "$ALLCOUNTRIES_URL/$country" -H "accept: application/json")
    
    cases=$(echo $data | jq ".cases")
    deaths=$(echo $data | jq ".deaths")
    recovered=$(echo $data | jq ".recovered")

    printf "${blue}cases:${reset} ${cases}\n"
    printf "${blue}deaths:${reset} ${deaths}\n"
    printf "${blue}recovered:${reset} ${recovered}\n"
  
  elif [ -z "$country" ] && [ "$historical" == true ] && [ -z "$nodays" ]; then
    banner
    printf "Sparkline for global historical statistics\n\n"

    data=$(curl -s -X GET "$HISTORICAL_URL/all" -H "accept: application/json")
    
    cases=$(echo $data | jq -r '.cases' | jq '.[]')
    deaths=$(echo $data | jq -r '.deaths' | jq '.[]')
    recovered=$(echo $data | jq -r '.recovered' | jq '.[]')
    
    printf "${blue}cases:${reset} $(spark ${cases})\n\n"
    printf "${blue}deaths:${reset} $(spark ${deaths})\n\n"
    printf "${blue}recovered:${reset} $(spark ${recovered})\n\n"
  
  elif [ -z "$country" ] && [ "$historical" == true ] && [ -n "$nodays" ]; then
    (banner
    printf "Listing global historical statistics\n\n"

    data=$(curl -s -X GET "$HISTORICAL_URL/all?lastdays=$nodays" -H "accept: application/json")
    
    cases=$(echo $data | jq -r '.cases' | jq '.[]')
    deaths=$(echo $data | jq -r '.deaths' | jq '.[]')
    recovered=$(echo $data | jq -r '.recovered' | jq '.[]')

    printf "${blue}cases:${reset} $(spark ${cases})\n\n"
    printf "${blue}deaths:${reset} $(spark ${deaths})\n\n"
    printf "${blue}recovered:${reset} $(spark ${recovered})\n\n"

    printf "Tips:\n"
    printf "Use the left or right arrow to horizontal scroll the screen\n"
    printf "Press 'q' when done to quit\n\n") | less -S

  elif [ -n "$country" ] && [ "$historical" == true ] && [ -z "$nodays" ]; then
    banner
    printf "country: ${country}\n\n"

    data=$(curl -s -X GET "$HISTORICAL_URL/$country" -H "accept: application/json")
    
    cases=$(echo $data | jq -r '.timeline.cases' | jq '.[]')
    deaths=$(echo $data | jq -r '.timeline.deaths' | jq '.[]')
    recovered=$(echo $data | jq -r '.timeline.recovered' | jq '.[]')

    printf "${blue}cases:${reset} $(spark ${cases})\n\n"
    printf "${blue}deaths:${reset} $(spark ${deaths})\n\n"
    printf "${blue}recovered:${reset} $(spark ${recovered})\n\n"

  elif [ -n "$country" ] && [ "$historical" == true ] && [ -n "$nodays" ]; then
    (banner
    printf "country: ${country}\n\n"

    data=$(curl -s -X GET "$HISTORICAL_URL/$country?lastdays=$nodays" -H "accept: application/json")
    
    cases=$(echo $data | jq -r '.timeline.cases' | jq '.[]')
    deaths=$(echo $data | jq -r '.timeline.deaths' | jq '.[]')
    recovered=$(echo $data | jq -r '.timeline.recovered' | jq '.[]')

    printf "${blue}cases:${reset} $(spark ${cases})\n\n"
    printf "${blue}deaths:${reset} $(spark ${deaths})\n\n"
    printf "${blue}recovered:${reset} $(spark ${recovered})\n\n"
    
    printf "Tips:\n"
    printf "Use the left or right arrow to horizontal scroll the screen\n"
    printf "Press 'q' when done to quit\n\n") | less -S

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
    
    printf "${blue}cases:${reset} ${cases}\n"
    printf "${blue}deaths:${reset} ${deaths}\n"
    printf "${blue}recovered:${reset} ${recovered}\n"
  fi
}

basedir=$( cd `dirname $0`; pwd )
source ${basedir}/libs/spark
. ${basedir}/libs/util.bash
. ${basedir}/libs/progress.sh

# colors
green=`tput setaf 2`
red=`tput setaf 1`
reset=`tput sgr0`
yellow=`tput setaf 3`
blue=`tput setaf 4`

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
    -s|--sort)
    sort=true
    shift
    sortby="$1"
    ;;
    *)
    printf "Invalid command '$1'\n"
    exit 1
  esac
  shift
done

main