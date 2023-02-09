#!/bin/bash -e

# Variables de configuración
db='focus_db2'
dump='focus_dump'
path='/var/www/html/focus/db'

if [ "$1" == "-h" ]
then
	echo 
	echo "Uso make_dump.sh [dump_name]"
	echo 
	echo "Sin argumentos se genera un archivo comprimido de nombre $dump.tgz."
	echo "Con un argumento se genera un archivo comprimido dump_name.tgz."
	echo 
	exit 1
fi

# me paro en el directoria de backup para simplicar los nombres
cd $path

# si paso algun parametro lo interpreto como un nombre de archivo
# de dump
if [ ! -z "$1" ]
then
	dump="$1"
fi

# si existe un dump lo renombro
if [ -f "$dump.tgz" ]
then
	mv "$dump.tgz" "prev_$dump.tgz"
fi

pg_dump --no-owner -U postgres -h localhost $db > "$dump.dump"

# comprimo el dump
tar zcf "$dump.tgz" "$dump.dump"

# lo borro
rm -f "$dump.dump"
