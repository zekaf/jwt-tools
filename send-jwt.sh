
#!/bin/bash
#
# Send JWT on the HTTP Authorization header 
#

# error function
function error(){
  echo "Error: File $1 not found."
  exit 1
}

# chech arguments
if [ $# -ne 2 ]; then
  echo
  echo "Invalid number of arguments."
  echo "Usage: ./$(basename "$0") <host> <port>"
  echo
  exit 1
fi

TMP_DIR="tmp/jwt
JWT=$(cat $TMP_DIR/access_token)
HOST="$1"
PORT="$2"

curl -H "Authorization: Token ${JWT}" ${HOST}:${PORT} || printf '%s\n' $?
