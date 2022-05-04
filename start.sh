#/bin/bash

evm='https://github.com/KYVENetwork/evm/releases/download/v1.0.3/evm-linux.zip'
bitcion='https://github.com/kyve-org/bitcoin/releases/download/v0.0.0/kyve-bitcoin-linux.zip'
solana='https://github.com/kyve-org/solana/releases/download/v0.0.0/kyve-solana-linux.zip'
zilliqa='https://github.com/kyve-org/zilliqa/releases/download/v0.0.0/kyve-zilliqa-linux.zip'

function checkInt() {
  expr $1 + 0&>/dev/null
  [ $? -ne 0 ] && { echo "$2 must be integer."; return 1; }
  return 0
}
function checkMenmonic() {
  [ $(echo $#) -ne 12 -a $(echo $#) -ne 24 ] && { echo "Menmonic must be 12 or 24 words."; return 1; }
  return 0
}
function checkPath() {
  [ ! -f "$1" ] && { echo "It must be a file path."; return 1; }
  return 0
}

until [[ $? -eq 0 ]] && [[ -n "$pool" ]]
do
  read -p 'Pool ID: ' pool < /dev/tty
  checkInt $pool echo "Pool ID"
done
until [ $? -eq 0 ] && [[ -n "$mnemonic" ]]
do
  read -p 'Mnemonic: ' mnemonic < /dev/tty
  checkMenmonic $mnemonic
done
until [ $? -eq 0 ] && [[ -n "$initialStake" ]]
do
  read -p 'InitialStake: ' initialStake < /dev/tty
  checkInt $initialStake echo "Initial stake"
done

read -p 'Ar wallet json(If you saved json file on this device, just press Enter): ' arjson < /dev/tty
if [ -z "$arjson" ]
then
  until [[ $? -eq 0 ]] && [[ -n "$arpath" ]]
  do
    read -e -p 'Ar wallet path: ' arpath < /dev/tty
    checkPath $arpath
  done
else
  echo $arjson > $HOME/ar.json
  arpath="$HOME/ar.json"
fi

if [ $pool -eq 0 -o $pool -eq 1 ]
then
  url=$evm
elif [ $pool -eq 3 ]
then
  url=$bitcoin
elif [ $pool -eq 4 ]
then
  url=$solana
elif [ $pool -eq 5 ]
then
  url=$zilliqa
else
  url=$evm
fi

cd $HOME
wget $url -O KYVE.zip
ziplog=$(unzip -o -d /usr/local/bin KYVE.zip | grep '/usr/local/bin/')
filearr=(${ziplog//inflating:/})
binary=${filearr##*/}
chmod a+rx /usr/local/bin/$binary

sudo tee <<EOF >/dev/null /etc/systemd/system/kyve.service
[Unit]
Description=Kyve Validator
After=network-online.target

[Service]
User=$USER
ExecStart=$binary --poolId $pool --mnemonic $mnemonic --initialStake $initialStake --keyfile $arpath --network korellia
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

systemctl enable kyve
systemctl daemon-reload
systemctl start kyve
