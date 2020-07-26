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
  
  command           description
  -------           -----------
  -a, --list-all    list statics for all countries
  -c, --country     list statics for an specific country
  -h, --help        open the help menu
  -n, --no-banner   hide the /covid19/ banner
  "
}

main()
{
  url="https://disease.sh/v3/covid-19/countries"

  if [ "$listall" == true ] && [ ! -z "$country" ]; then
    echo "list all and country cannot be mixed!"

  elif [ "$listall" == true ]; then
    banner
    echo ""
    res=$(curl --progress-bar -X GET "$url" -H "accept: application/json")
    echo ""
    echo $res | jq -r '(["country", "cases", "deaths", "recovered"] | (., map(length*"-"))), (.[] | [.country, .cases, .deaths, .recovered]) | @csv' | column -t -s ","
  
  elif [ ! -z "$country" ]; then
    banner
    echo "country: $country"
    echo ""
    res=$(curl --fail --progress-bar -X GET "$url/$country" -H "accept: application/json")
    echo ""
    echo $res | jq -r '(["country", "cases", "deaths", "recovered"] | (., map(length*"-"))), ([.country, .cases, .deaths, .recovered]) | @csv' | column -t -s ","
  
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
    listall=true
    ;;
    -c|--country)
    country="$2"
    ;;
    -h|--help)
    help=true
    ;;
    -n|--no-banner)
    nobanner=true
    ;;
  esac
  shift
done

main