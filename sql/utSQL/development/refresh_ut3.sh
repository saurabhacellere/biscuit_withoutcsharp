#!/usr/bin/env bash

#goto git root directory
git rev-parse && cd "$(git rev-parse --show-cdup)"

. development/env.sh

cd source

"${SQLCLI}" sys/${ORACLE_PWD}@//${CONNECTION_STR} AS SYSDBA <<-SQL
@uninstall ${UT3_OWNER}
@install ${UT3_OWNER}
exit
SQL
