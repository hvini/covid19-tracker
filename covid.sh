#!/bin/bash

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
    -a, --list-all    list statics for all countries
    -c, --country     list statics for a specific country
    -h, --help        open the help menu
    -n, --no-banner   hide the /covid19/ banner
    "
}

main()
{
  if [ "$listall" == true ]; then
    banner
    res=$(curl -X GET "https://disease.sh/v3/covid-19/countries" -H "accept: application/json")
    echo $res | jq -r '(["Country", "Cases", "Deaths", "Recovered"] | (., map(length*"-"))), (.[] | [.country, .cases, .deaths, .recovered]) | @csv' | column -t -s ","
  elif [ "$help" == true ]; then
    banner
    usage
  fi
}

if [ $# -eq 0 ]; then
  usage
fi

while test $# -gt 0; do
  case "$1" in
    -a|--list-all)
    shift
    listall=true
    ;;
    -h|--help)
    shift
    help=true
    ;;
    -n|--no-banner)
    shift
    nobanner=true
    ;;
  esac
done

main