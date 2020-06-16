export VERSION=1.0
export CHANNEL_NAME=mychannel
export CHAINCODE_NAME=mycc
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/msp/tlscacerts/tlsca.brownbag.com-cert.pem

setENV() {

    # params orgname port MSPID join/create/install

    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$1.brownbag.com/users/Admin@$1.brownbag.com/msp
    CORE_PEER_ADDRESS=peer0.$1.brownbag.com:$2
    CORE_PEER_LOCALMSPID=$3
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$1.brownbag.com/peers/peer0.$1.brownbag.com/tls/ca.crt

    if [ $4 = join_update ]
    then
        peer channel join -b $CHANNEL_NAME.block
        peer channel update -o orderer.brownbag.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${1^^}anchors.tx --tls --cafile $ORDERER_CA
    elif [ $4 = install ]
    then
        peer chaincode install -n $CHAINCODE_NAME -v $VERSION -l node -p /opt/gopath/src/github.com/chaincode/javascript

    elif [ $4 = create ]
    then
        
        peer channel create -o orderer.brownbag.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls --cafile $ORDERER_CA
    else
        echo "Only environment variable is set for " $1
    fi

}
######### Create Channel nippon ##############
setENV org1 7051 ORG1MSP create
echo "Added the 10s delay after create channel...."
sleep 10s

############# Join channel ##############
setENV org1 7051 ORG1MSP join_update
setENV org2 8051 ORG2MSP join_update


echo "Added the 10s delay after join channel...."
sleep 10s

############# Install chaincode ##############
setENV org1 7051 ORG1MSP install
setENV org2 8051 ORG2MSP install


echo "Added the 10s delay after Chaincode install...."
sleep 10s

############# Instantiate chaincode ##############
peer chaincode instantiate -o orderer.brownbag.com:7050 --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CHAINCODE_NAME -v $VERSION -c '{"Args":["initLedger"]}' -P "OR ('ORG1MSP.member','ORG2MSP.member')"
echo "Added the 10s delay after Chaincode instantiate...."
sleep 10s

############# Query answer must be a=100 ##############
# peer chaincode query -C nippon -n shipmentcc -c '{"function":"getTemperatureExcursion","Args":["12", "21"]}'
# peer chaincode query -C nippon -n shipmentcc -c '{"Args":["getTemperatureExcursion","12", "21"]}'
# sleep 5s
############# Query answer must be b=200 ##############
# peer chaincode query -C $CHANNEL_NAME -n $CHAINCODE_NAME -c '{"Args":["query","b"]}'

####### Cli commands over ###############
