#!/bin/bash

################################################################################################################
# progressbar.sh - Displays a full width progress bar depending on a given percentage                          #
# Usage : ./progressbar.sh 100                                                                                 #
# Author: Axel Floquet-Trillot                                                                                 #
################################################################################################################

bar='['

length=$(($(tput cols)-$(echo "$1" | wc -c)-4))
for ((i=0;i<$length;i++)); do
  if [ $i -lt $(($1*$length/100)) ]; then
    bar+='#'
  else
    bar+=' '
  fi
done

bar+="] $1%"

echo "$bar"