#!/bin/bash

check_dependencies()
{
  type jq >/dev/null 2>&1 || { echo >&2 "jq is not installed. https://stedolan.github.io/jq/"; exit 1; }
  type curl >/dev/null 2>&1 || {  echo >&2 "curl is not installed. https://stedolan.github.io/jq/"; exit 1; }
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
  -a,  --list-all      list all countries statistics for today and yesterday
  -c,  --country       list statistics for an specific country
  -g,  --global        list global statistics for today and yesterday
  -h,  --help          open the help menu
  -hI, --historical    list global historical { last 30 days } statistics
  -n,  --no-banner     hide the /covid19/ banner
examples:
  ./covid.sh -c brazil
  ./covid.sh --global
  "
}

err()
{
  echo "Error: $@"
  exit 1;
}

main()
{
  url="https://disease.sh/v3/covid-19"

  if [ "$listall" == true ] && [ -n "$country" ]; then
    err "list all and country cannot be mixed!"

  elif [ "$listall" == true ]; then
    banner
    echo ""
    res=$(curl --progress-bar -X GET "$url/countries" -H "accept: application/json")
    echo ""
    echo $res | jq -r '(["country", "cases", "deaths", "recovered"] | (., map(length*"-"))), (.[] | [.country, .cases, .deaths, .recovered]) | @csv' | column -t -s ","
  
  elif [ -n "$country" ] && [ -z "$historical" ]; then
    banner
    echo "country: $country"
    echo ""
    res=$(curl --fail --progress-bar -X GET "$url/countries/$country" -H "accept: application/json")
    echo ""
    echo $res | jq -r '(["country", "cases", "deaths", "recovered"] | (., map(length*"-"))), ([.country, .cases, .deaths, .recovered]) | @csv' | column -t -s ","
  
  elif [ -z "$country" ] && [ "$historical" == true ]; then
    banner
    printf "global\n\n"

    res=$(curl --progress-bar -X GET "$url/historical/all" -H "accept: application/json")

    cases=$(echo $res | jq -r '.cases' | jq '.[]')
    deaths=$(echo $res | jq -r '.deaths' | jq '.[]')
    recovered=$(echo $res | jq -r '.recovered' | jq '.[]')

    printf "\ncases: $(spark ${cases})\n\n"
    printf "deaths: $(spark ${deaths})\n\n"
    printf "recovered: $(spark ${recovered})\n\n"

  elif [ -n "$country" ] && [ "$historical" == true ]; then
    banner
    printf "country: ${country}\n\n"

    res=$(curl --progress-bar -X GET "$url/historical/$country" -H "accept: application/json")
    
    cases=$(echo $res | jq -r '.timeline.cases' | jq '.[]')
    deaths=$(echo $res | jq -r '.timeline.deaths' | jq '.[]')
    recovered=$(echo $res | jq -r '.timeline.recovered' | jq '.[]')

    printf "\ncases: $(spark ${cases})\n\n"
    printf "deaths: $(spark ${deaths})\n\n"
    printf "recovered: $(spark ${recovered})\n\n"

  elif [ "$help" == true ]; then
    banner
    usage

  elif [ "$global" == true ]; then
    banner
    echo ""
    res=$(curl --progress-bar -X GET "$url/all" -H "accept: application/json")
    echo ""
    echo $res | jq -r '(["cases", "deaths", "recovered"] | (., map(length*"-"))), ([.cases, .deaths, .recovered]) | @csv' | column -t -s ","
  fi
}

basedir=$( cd `dirname $0`; pwd )
source ${basedir}/libs/spark

check_dependencies

if [ $# -eq 0 ]; then
  usage
fi

while test $# -gt 0; do
  case "$1" in
    -a|--list-all)
    listall=true
    ;;
    -c|--country)
    country="$2"
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
  esac
  shift
done

main