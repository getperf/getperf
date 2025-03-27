 mkdir view/JIDOUKA/AIX/
 echo '{}' > view/JIDOUKA/AIX/k1tirddb.json

cacti-cli -f -g ./lib/graph/AIX/indoubt_count.json

cacti-cli -f ./node/AIX/k1tirddb/indoubt_count.json --tenant JIDOUKA
