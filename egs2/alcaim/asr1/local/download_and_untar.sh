#!/bin/bash

# Copyright   2014  Johns Hopkins University (author: Daniel Povey)
#             2020  Universidade Federal de Santa Catarina (author: André Schlichting)
# Apache 2.0

remove_archive=false

if [ "$1" == --remove-archive ]; then
  remove_archive=true
  shift
fi

if [ $# -ne 3 ]; then
  echo "Usage: $0 [--remove-archive] <data-base> <url-base> <corpus-part>"
  echo "e.g.: $0 /export/a15/vpanayotov/data www.openslr.org/resources/11 dev-clean"
  echo "With --remove-archive it will remove the archive after successfully un-tarring it."
  echo "<corpus-part> can be one of: dev-clean, test-clean, dev-other, test-other,"
  echo "          train-clean-100, train-clean-360, train-other-500."
  exit 1
fi

data=$1
url=$2
part=$3

if [ ! -d "$data" ]; then
  echo "$0: no such directory $data"
  exit 1
fi

part_ok=false
list="lapsbm-val lapsbm-test voxforge-ptbr alcaim sid pt"
for x in $list; do
  if [ "$part" == $x ]; then part_ok=true; fi
done
if ! $part_ok; then
  echo "$0: expected <corpus-part> to be one of $list, but got '$part'"
  exit 1
fi

if [ -z "$url" ]; then
  echo "$0: empty URL base."
  exit 1
fi

if [ -f $data/${part}.complete ]; then
  echo "$0: data part $part was already successfully extracted, nothing to do."
  exit 0
else
  mkdir -p $data/$part
fi

sizes="68644160 51664659 373263333 12849484681 1034271578 1454367644"

if [ -f $data/$part.tar.gz ]; then
  size=$(/bin/ls -l $data/$part.tar.gz | awk '{print $5}')
  size_ok=false
  for s in $sizes; do if [ $s == $size ]; then size_ok=true; fi; done
  if ! $size_ok; then
    echo "$0: removing existing file $data/$part.tar.gz because its size in bytes $size"
    echo "does not equal the size of one of the archives."
    rm $data/$part.tar.gz
  else
    echo "$data/$part.tar.gz exists and appears to be complete."
  fi
fi

if [ ! -f $data/$part.tar.gz ]; then
  if ! which wget >/dev/null; then
    echo "$0: wget is not installed."
    exit 1
  fi
  full_url=$url/$part.tar.gz
  echo "$0: downloading data from $full_url.  This may take some time, please be patient."

  if ! wget -P $data --no-check-certificate $full_url; then
    echo "$0: error executing wget $full_url"
    exit 1
  fi
fi

if ! pigz -dc $data/$part.tar.gz | tar xf - -C $data/$part; then
  echo "$0: error un-tarring archive $data/$part.tar.gz"
  exit 1
fi

touch $data/${part}.complete

echo "$0: Successfully downloaded and un-tarred $data/$part.tar.gz"

if $remove_archive; then
  echo "$0: removing $data/$part.tar.gz file since --remove-archive option was supplied."
  rm $data/$part.complete
  rm $data/$part.tar.gz
fi
