#!/bin/bash -e

# Variables de configuración
db='focus_db2'
dump='focus_dump'
path='/var/www/html/tioso/db'

if [ "$1" == "-h" ]
then
	echo 
	echo "Uso restore_dump.sh [dump_name.tgz]"
	echo 
	echo "Sin argumentos se restaura un archivo $dump.tgz."
	echo "El archivo descomprimido debera llamarse $dump.dump"
	echo "Con un argumento se genera un archivo comprimido dump_name.tgz."
	echo "El archivo descomprimido debera llamarse dump_name.dump"
	echo 
	exit 1
fi

# me paro en el directoria de backup para simplicar los nombres
cd $path

# si paso algun parametro lo interpreto como un nombre de archivo
# de dump. Esperamos el nombre de archivo junto con la extension
if [ ! -z "$1" ]
then
	dump=$(echo "$1" | cut -f 1 -d'.')
fi

##########################################################
# descomprimo el archivo de dump (tiene que ser un tgz)
##########################################################
# el archivo descomprimido tiene que llamarse $dump.dump
##########################################################
tar zxf "$1"

# mato todas las conexiones a al db
echo "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE pid <> pg_backend_pid() AND datname = '$db';\
	DROP DATABASE $db; \
	CREATE DATABASE $db; \
	" | psql -U postgres -h localhost

# restauro el dump
psql -U postgres -h localhost "$db" < "$dump.dump"

# lo borro
rm -f "$dump.dump"
