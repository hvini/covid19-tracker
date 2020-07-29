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
  ./covid.sh -hI -c brazil
  ./covid.sh --global
  "
}

err()
{
  echo "Error: $@"
  exit 1;
}

exceptions()
{
  if [ "$listall" == true ] && [ "$listcountry" == true ]; then
    err "-a|--list-all and -c|--country cannot be mixed!"

  elif [ "$listall" == true ] && [ "$global" == true ]; then
    err "-a|--list-all and -g|--global cannot be mixed!"

  elif [ "$listall"  == true ] && [ "$historical" == true ]; then
    err "-a|--list-all and -hI|--historical cannot be mixed!"

  elif [ "$global" == true ] && [ "$listcountry" == true ]; then
    err "-g|--global and -c|--country cannot be mixed!"

  elif [ "$global" == true ] && [ "$historical" == true ]; then
    err "-g|--global and -hI|--historical cannot be mixed!"
  fi
}

main()
{
  url="https://disease.sh/v3/covid-19"
  
  exceptions

  if [ "$listall" == true ]; then
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
    listcountry=true
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