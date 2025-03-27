ls lib/graph/Db2/*.json | grep -v sql_top | xargs -I {} cacti-cli -f -g {}
