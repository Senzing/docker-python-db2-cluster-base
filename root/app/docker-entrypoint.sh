#!/usr/bin/env bash
# Make changes to files based on Environment Variables.

VERSION=1.0.0

# A file used to determine if/when this program has previously run.

SENTINEL_FILE=/opt/senzing/docker-runs.sentinel

# Return codes

OK=0
NOT_OK=1

# -----------------------------------------------------------------------------
# HTTP URL parsing functions
# -----------------------------------------------------------------------------

protocol() { echo "$(echo $1 | sed -e's,^\(.*://\).*,\1,g')"; }
driver()   { echo "$(echo $1 | cut -d ':' -f1)"; }
username() { echo "$(echo $1 | cut -d '/' -f3 | cut -d ':' -f1)"; }
password() { echo "$(echo $1 | cut -d ':' -f3 | cut -d '@' -f1)"; }
host()     { echo "$(echo $1 | cut -d '@' -f2 | cut -d ':' -f1)"; }
port()     { echo "$(echo $1 | cut -d ':' -f4 | cut -d '/' -f1)"; }
schema()   { echo "$(echo $1 | cut -d '/' -f4)"; }

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

# Short-circuit for certain commandline options.

if [ "$1" == "--version" ]; then
  echo "senzing-configuration-changes.sh version ${VERSION}"
  exit ${OK}
fi

# Make modifications based on SENZING_DATABASE_URL value.

if [ -z "${SENZING_CORE_DATABASE_URL}" ]; then
  echo "Using internal database"
else

  # Parse the SENZING_CORE_DATABASE_URL.

  PROTOCOL_CORE=$(protocol ${SENZING_CORE_DATABASE_URL})
  DRIVER_CORE=$(driver ${SENZING_CORE_DATABASE_URL})
  USERNAME_CORE=$(username ${SENZING_CORE_DATABASE_URL})
  PASSWORD_CORE=$(password ${SENZING_CORE_DATABASE_URL})
  HOST_CORE=$(host ${SENZING_CORE_DATABASE_URL})
  PORT_CORE=$(port ${SENZING_CORE_DATABASE_URL})
  SCHEMA_CORE=$(schema ${SENZING_CORE_DATABASE_URL})
  UPPERCASE_DRIVER_CORE=$(echo "${DRIVER_CORE}" | tr '[:lower:]' '[:upper:]')

  # Parse the SENZING_RES_DATABASE_URL.
   
  PROTOCOL_RES=$(protocol ${SENZING_RES_DATABASE_URL})
  DRIVER_RES=$(driver ${SENZING_RES_DATABASE_URL})
  USERNAME_RES=$(username ${SENZING_RES_DATABASE_URL})
  PASSWORD_RES=$(password ${SENZING_RES_DATABASE_URL})
  HOST_RES=$(host ${SENZING_RES_DATABASE_URL})
  PORT_RES=$(port ${SENZING_RES_DATABASE_URL})
  SCHEMA_RES=$(schema ${SENZING_RES_DATABASE_URL})
  UPPERCASE_DRIVER_RES=$(echo "${DRIVER_RES}" | tr '[:lower:]' '[:upper:]')
  
  # Parse the SENZING_LIBFEST_DATABASE_URL.

  PROTOCOL_LIBFE=$(protocol ${SENZING_LIBFE_DATABASE_URL})
  DRIVER_LIBFE=$(driver ${SENZING_LIBFE_DATABASE_URL})
  USERNAME_LIBFE=$(username ${SENZING_LIBFE_DATABASE_URL})
  PASSWORD_LIBFE=$(password ${SENZING_LIBFE_DATABASE_URL})
  HOST_LIBFE=$(host ${SENZING_LIBFE_DATABASE_URL})
  PORT_LIBFE=$(port ${SENZING_LIBFE_DATABASE_URL})
  SCHEMA_LIBFE=$(schema ${SENZING_LIBFE_DATABASE_URL})
  UPPERCASE_DRIVER_LIBFE=$(echo "${DRIVER_LIBFE}" | tr '[:lower:]' '[:upper:]')
  
  # Construct Senzing version of database URLs.

  NEW_SENZING_CORE_DATABASE_ALIAS_URL="db2://${USERNAME_CORE}:${PASSWORD_CORE}@SCHEMA_CORE"
  NEW_SENZING_RES_DATABASE_ALIAS_URL="db2://${USERNAME_RES}:${PASSWORD_RES}@SCHEMA_RES"
  NEW_SENZING_LIBFE_DATABASE_ALIAS_URL="db2://${USERNAME_LIBFE}:${PASSWORD_LIBFE}@SCHEMA_LIBFE"

  # Modify files in docker's Union File System.

  echo "" >> /etc/odbcinst.ini  # Create a file if it is not there.
  sed -i.$(date +%s) \
    -e "\$a[${UPPERCASE_DRIVER_CORE}]" \
    -e "\$aDescription = Db2 ODBC Driver" \
    -e "\$aDriver = /opt/IBM/db2/clidriver/lib/libdb2o.so" \
    -e "\$aFileUsage = 1" \
    -e "\$adontdlclose = 1\n" \
    /etc/odbcinst.ini

  sed -i.$(date +%s) \
    -e "s/{HOST_CORE}/${HOST_CORE}/" \
    -e "s/{HOST_RES}/${HOST_RES}/" \
    -e "s/{HOST_LIBFE}/${HOST_LIBFE}/" \
    -e "s/{PORT_CORE}/${PORT_CORE}/" \
    -e "s/{PORT_RES}/${PORT_RES}/" \
    -e "s/{PORT_LIBFE}/${PORT_LIBFE}/" \
    -e "s/{SCHEMA_CORE}/${SCHEMA_CORE}/" \
    -e "s/{SCHEMA_RES}/${SCHEMA_RES}/" \
    -e "s/{SCHEMA_LIBFE}/${SCHEMA_LIBFE}/" \
    /etc/odbc.ini

  sed -i.$(date +%s) \
    -e "s/{HOST_CORE}/${HOST_CORE}/" \
    -e "s/{HOST_RES}/${HOST_RES}/" \
    -e "s/{HOST_LIBFE}/${HOST_LIBFE}/" \
    -e "s/{PORT_CORE}/${PORT_CORE}/" \
    -e "s/{PORT_RES}/${PORT_RES}/" \
    -e "s/{PORT_LIBFE}/${PORT_LIBFE}/" \
    -e "s/{SCHEMA_CORE}/${SCHEMA_CORE}/" \
    -e "s/{SCHEMA_RES}/${SCHEMA_RES}/" \
    -e "s/{SCHEMA_LIBFE}/${SCHEMA_LIBFE}/" \
    /opt/IBM/db2/clidriver/cfg/db2dsdriver.cfg

  # Modify files in mounted volume, if needed.  The "sentinel file" is created after first run.

  if [ ! -f ${SENTINEL_FILE} ]; then

    sed -i.$(date +%s) \
      -e "s|G2Connection=sqlite3://na:na@/opt/senzing/g2/sqldb/G2C.db|G2Connection=${NEW_SENZING_CORE_DATABASE_ALIAS_URL}|" \
      /opt/senzing/g2/python/G2Project.ini

    sed -i.$(date +%s) \
      -e "s|CONNECTION=sqlite3://na:na@/opt/senzing/g2/sqldb/G2C.db|BACKEND=HYBRID\nCONNECTION=${NEW_SENZING_CORE_DATABASE_ALIAS_URL}|" \
      -e "\$a[NODE_1]" \
      -e "\$aCLUSTER_SIZE=1" \
      -e "\$aDB_1=${NEW_SENZING_RES_DATABASE_ALIAS_URL}\n" \
      -e "\$a[NODE_2]" \
      -e "\$aCLUSTER_SIZE=1" \
      -e "\$aDB_1=${NEW_SENZING_LIBFE_DATABASE_ALIAS_URL}\n" \
      -e "\$a[HYBRID]" \
      -e "\$aRES_FEAT=NODE_1" \
      -e "\$aRES_FEAT_EKEY=NODE_1" \
      -e "\$aRES_FEAT_LKEY=NODE_1" \
      -e "\$aRES_FEAT_STAT=NODE_1" \
      -e "\$aLIB_FEAT=NODE_2" \
      -e "\$aLIB_FEAT_HKEY=NODE_2" \
      /opt/senzing/g2/python/G2Module.ini

  fi
fi

# Append to a "sentinel file" to indicate when this script has been run.
# The sentinel file is used to identify the first run from subsequent runs for "first-time" processing.

echo "$(date)" >> ${SENTINEL_FILE}

# Run the command specified by the parameters.

exec $@
