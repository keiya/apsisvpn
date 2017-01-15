CONF_DIR="/usr/local/etc/tinc"
BIN="/usr/local/sbin/tinc"
LIST="created_net.txt"

for net in $(cat "$LIST") ; do
  $BIN -n $net stop
  #ip link delete ${net}br type bridge
  rm -rv "${CONF_DIR}/$net"
done
rm -v "$LIST"
