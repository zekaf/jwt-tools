#!/bin/bash
#
# Description:
# This script creates an JWT 
# Using the base64 command for encoding
#

# error function
function error(){
  echo "Error: File $1 not found."
  exit 1
}

# replace a string in an existing file
function replaceVar(){
  VAR1="$1"
  VAR2="$2"
  FILE="$3"
  CMD="perl -pi -e 's|${VAR1}|${VAR2}|g' $FILE"
  eval $CMD
}

# variables
TMP_DIR="tmp/jwt
CONF_DIR="conf"
JWT_CONF_FILE="$CONF_DIR/jwt/jwt.conf"
DLT_CONF_FILE="$CONF_DIR/dlt/wallet.conf"
HEADER_TEMPLATE=
PAYLOAD_TEMPLATE=
iss="$ISSUER"

# create temporary directory
[ -d "$TMP_DIR" ] || mkdir -p $TMP_DIR

# get address value from NMC
nshow=$(namecoin-cli -datadir=$DATA_DIR name_show "$iss")
NMC_ADDRESS=$(echo $nshow | python -c "import sys, json; print json.load(sys.stdin)['address']")

# create message
[ -r "$CONF_DIR/jwt/header.template" ] && cp $CONF_DIR/jwt/header.template $TMP_DIR/header || error "$CONF_DIR/jwt/header.template"
[ -r "$CONF_DIR/jwt/payload.template" ] && cp $CONF_DIR/jwt/payload.template $TMP_DIR/payload || error "$CONF_DIR/jwt/payload.template"
[ -r "$CONF_DIR/jwt/jwt.con" ] || error "$CONF_DIR/jwt/jwt.con
replaceVar "ALGORITHM" ${ALGORITHM} $TMP_DIR/header
replaceVar "ISSUER" "${ISSUER}" $TMP_DIR/payload
if [ -z "$EXPIRYDATE" ]; then
    DATE=$(perl -e '$x=time+(${HOURS}*3600);print $x')
    replaceVar "EXPIRYDATE" "${DATE}" $TMP_DIR/payload
else
    replaceVar "EXPIRYDATE" "${EXPIRYDATE}" $TMP_DIR/payload
fi
header=$(cat $TMP_DIR/header)
payload=$(cat $TMP_DIR/payload)
message=$header.$payload 
echo $message > $TMP_DIR/message

# unlock wallet for n seconds
namecoin-cli -datadir=$NMC_DATA_DIR walletpassphrase "${NMC_WALLET_PWD}" $NMC_UNLOCK_SEC &>/dev/null

# sign message
signature=$(namecoin-cli -datadir=$NMC_DATA_DIR signmessage "${NMC_ADDRESS}" "${message}") 

# create unencoded_token
unencoded_token="$message.$signature"
echo $unencoded_token > $TMP_DIR/unencoded_token

# create access_token 
enc="$(echo -n "$header" | base64 | tr -d '\n')"
enc="$enc.$(echo "$payload" | base64 | tr -d '\n')"
enc="$enc.$(echo "$signature" | base64 | tr -d '\n')"
echo $enc > $TMP_DIR/access_token

# print access_token
cat $TMP_DIR/access_token

exit 0
