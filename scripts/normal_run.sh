pre_start_action() {
  # Cleanup previous sockets
  rm -f /run/mysqld/mysqld.sock

}

post_start_action() {
  # advertise the mysql server is up.
 : 
}
