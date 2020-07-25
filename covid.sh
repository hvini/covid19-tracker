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
  banner
  echo "Usage: $0 [Options]:
    -a, --list-all    List all countries
    -c, --country     Specific a country
    -h, --help        Help menu
    -n, --no-banner   Hide banner
    "
}

main()
{
  if [ $# -lt 1 ]; then
    usage
  fi

  if [ "$listall" == true ]; then
      alldata=$(curl -X GET "https://disease.sh/v3/covid-19/countries" -H "accept: application/json")
      echo $alldata | jq -r '(["Country", "Cases", "Deaths", "Recovered"] | (., map(length*"-"))), (.[] | [.country, .cases, .deaths, .recovered]) | @csv' | column -t -s ","
  fi
}

while test $# -gt 0; do
  case "$1" in
    -a|--list-all)
    shift
    listall=true
    ;;
    -n|--no-banner)
    shift
    nobanner=true
    ;;
  esac
done

main