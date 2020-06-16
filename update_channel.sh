# Stage 2
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/msp/tlscacerts/tlsca.brownbag.com-cert.pem
upfd=/home/avinash/Desktop/bb2/upgrade
orgName="org1 org2 orderer"
org="org1 org2"
binpath=/home/avinash/Desktop/bb2/bin
configpath=/home/avinash/Desktop/bb2/config

verify() {
    result=$1
    function=$2
    if [ $result -eq 0 ]
    then 
    echo "$function done"
    else
    echo "$function fail"
    fi
}

pullTranslate() {
    docker exec cli sh -c "export CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH; export CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID; \
    export CORE_PEER_TLS_CERT_FILE=$CORE_PEER_TLS_CERT_FILE; export CORE_PEER_TLS_KEY_FILE=$CORE_PEER_TLS_KEY_FILE; \
    export CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE; \
    peer channel fetch config config_block.pb -o orderer.brownbag.com:7050 -c $CH_NAME --tls --cafile $ORDERER_CA"
    docker cp cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/config_block.pb $upfd/config_block.pb
    verify $? copying-pull

    $binpath/./configtxlator proto_decode --input $upfd/config_block.pb --type common.Block --output $upfd/config_block.json
    jq .data.data[0].payload.data.config $upfd/config_block.json > $upfd/config.json
    cp $upfd/config.json $upfd/modified_config.json
    verify $? translate
}

submit(){
    
    docker exec cli sh -c "export CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH; export CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID; \
    export CORE_PEER_TLS_CERT_FILE=$CORE_PEER_TLS_CERT_FILE; export CORE_PEER_TLS_KEY_FILE=$CORE_PEER_TLS_KEY_FILE; \
    export CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE; export CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS; \
    peer channel update -f config_update_in_envelope.pb -c $CH_NAME -o orderer.brownbag.com:7050 --tls --cafile $ORDERER_CA"
    verify $? submission
}

signfrom() {

            docker exec cli sh -c "export CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH; export CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID; \
            export CORE_PEER_TLS_CERT_FILE=$CORE_PEER_TLS_CERT_FILE; export CORE_PEER_TLS_KEY_FILE=$CORE_PEER_TLS_KEY_FILE; \
            export CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE; export CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS; \
            peer channel signconfigtx -f config_update_in_envelope.pb"
            verify $? Signing
}

reEncode(){
    pushd $upfd
    $binpath/./configtxlator proto_encode --input config.json --type common.Config --output config.pb
    $binpath/./configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
    $binpath/./configtxlator compute_update --channel_id $CH_NAME --original config.pb --updated modified_config.pb --output config_update.pb
    $binpath/./configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
    echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CH_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
    $binpath/./configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb
    verify $? Re-encoding
    popd

}




######################## ORDERER Channel update Start###########################
# orderer system channel upgrade
CH_NAME=orderer-sys-channel
CORE_PEER_ADDRESS=peer0.org1.brownbag.com:7051
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/users/Admin@brownbag.com/msp
CORE_PEER_LOCALMSPID=OrdererMSP
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/tls/ca.crt

pullTranslate

jq -s '.[0] * {"channel_group":{"groups":{"Orderer": {"values": {"Capabilities": .[1].orderer}}}}}' $upfd/config.json $configpath/./capabilities.json > $upfd/modified_config_1.json
jq -s '.[0] * {"channel_group":{"values": {"Capabilities": .[1].channel}}}' $upfd/modified_config_1.json $configpath/./capabilities.json > $upfd/modified_config.json

reEncode

docker cp $upfd/config_update_in_envelope.pb cli:/opt/gopath/src/github.com/hyperledger/fabric/peer
submit

echo "removing file at /home/avinash/Desktop/bb2/upgrade/*"
rm -rf /home/avinash/Desktop/bb2/upgrade/*

######################## ORDERER Channel update END###########################

######################## APPLICATION Channel update START###########################
# Applcation channel upgrade
CH_NAME=mychannel
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/users/Admin@org1.brownbag.com/msp
CORE_PEER_LOCALMSPID=ORG1MSP
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/ca.crt
CORE_PEER_ADDRESS=peer0.org1.brownbag.com:7051

pullTranslate

jq -s '.[0] * {"channel_group":{"groups":{"Orderer": {"values": {"Capabilities": .[1].orderer}}}}}' $upfd/config.json $configpath/./capabilities.json > $upfd/modified_config_1.json
jq -s '.[0] * {"channel_group":{"values": {"Capabilities": .[1].channel}}}' $upfd/modified_config_1.json $configpath/./capabilities.json > $upfd/modified_config_2.json
jq -s '.[0] * {"channel_group":{"groups":{"Application": {"values": {"Capabilities": .[1].application}}}}}' $upfd/modified_config_2.json $configpath/./capabilities.json > $upfd/modified_config.json

reEncode
docker cp $upfd/config_update_in_envelope.pb cli:/opt/gopath/src/github.com/hyperledger/fabric/peer
# get signature from peer0.org1
CH_NAME=mychannel
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/users/Admin@org1.brownbag.com/msp
CORE_PEER_LOCALMSPID=ORG1MSP
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/ca.crt
CORE_PEER_ADDRESS=peer0.org1.brownbag.com:7051

signfrom
# get signature from peer0.org2
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/users/Admin@org2.brownbag.com/msp
CORE_PEER_LOCALMSPID=ORG2MSP
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/peers/peer0.org2.brownbag.com/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/peers/peer0.org2.brownbag.com/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/peers/peer0.org2.brownbag.com/tls/ca.crt
CORE_PEER_ADDRESS=peer0.org2.brownbag.com:8051

signfrom

# submit using orderer admin
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/users/Admin@brownbag.com/msp
CORE_PEER_LOCALMSPID=OrdererMSP
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/tls/ca.crt

submit
echo "removing file at /home/avinash/Desktop/bb2/upgrade/*"
rm -rf /home/avinash/Desktop/bb2/upgrade/*
######################## APPLICATION Channel update END###########################


######################## LIFECYCLE ENABLEMENT update START###########################
# Enable lifecycle
# system


# system channel for lifecycle
CONSORTIUM_NAME=ORG12Consortium
CH_NAME=orderer-sys-channel
CORE_PEER_ADDRESS=peer0.org1.brownbag.com:7051
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/users/Admin@brownbag.com/msp
CORE_PEER_LOCALMSPID=OrdererMSP
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/tls/ca.crt

pullTranslate

ORGNAME=ORG1
jq -s ".[0] * {\"channel_group\":{\"groups\":{\"Consortiums\":{\"groups\": {\"$CONSORTIUM_NAME\": {\"groups\": {\"$ORGNAME\": {\"policies\": .[1].${ORGNAME}Policies}}}}}}}}" $upfd/config.json $configpath/./enable_lifecycle.json > $upfd/modified_config_1.json

ORGNAME=ORG2
jq -s ".[0] * {\"channel_group\":{\"groups\":{\"Consortiums\":{\"groups\": {\"$CONSORTIUM_NAME\": {\"groups\": {\"$ORGNAME\": {\"policies\": .[1].${ORGNAME}Policies}}}}}}}}" $upfd/modified_config_1.json $configpath/./enable_lifecycle.json > $upfd/modified_config.json

reEncode
# copy the config_update block
docker cp $upfd/config_update_in_envelope.pb cli:/opt/gopath/src/github.com/hyperledger/fabric/peer

CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/users/Admin@org1.brownbag.com/msp
CORE_PEER_LOCALMSPID=ORG1MSP
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/ca.crt
CORE_PEER_ADDRESS=peer0.org1.brownbag.com:7051

signfrom
# get signature from peer0.org2
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/users/Admin@org2.brownbag.com/msp
CORE_PEER_LOCALMSPID=ORG2MSP
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/peers/peer0.org2.brownbag.com/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/peers/peer0.org2.brownbag.com/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/peers/peer0.org2.brownbag.com/tls/ca.crt
CORE_PEER_ADDRESS=peer0.org2.brownbag.com:8051

signfrom

CORE_PEER_ADDRESS=peer0.org1.brownbag.com:7051
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/users/Admin@brownbag.com/msp
CORE_PEER_LOCALMSPID=OrdererMSP
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/tls/ca.crt

submit

echo "removing file at /home/avinash/Desktop/bb2/upgrade/*"
rm -rf /home/avinash/Desktop/bb2/upgrade/*
# -------------- # system channel for lifecycle update end ----------#


# Application channel lifecycle
CH_NAME=mychannel
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/users/Admin@org1.brownbag.com/msp
CORE_PEER_LOCALMSPID=ORG1MSP
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/ca.crt
CORE_PEER_ADDRESS=peer0.org1.brownbag.com:7051

pullTranslate

ORGNAME=ORG1
jq -s ".[0] * {\"channel_group\":{\"groups\":{\"Application\": {\"groups\": {\"$ORGNAME\": {\"policies\": .[1].${ORGNAME}Policies}}}}}}" $upfd/config.json $configpath/./enable_lifecycle.json > $upfd/modified_config_1.json

ORGNAME=ORG2
jq -s ".[0] * {\"channel_group\":{\"groups\":{\"Application\": {\"groups\": {\"$ORGNAME\": {\"policies\": .[1].${ORGNAME}Policies}}}}}}" $upfd/modified_config_1.json $configpath/./enable_lifecycle.json > $upfd/modified_config_2.json


jq -s '.[0] * {"channel_group":{"groups":{"Application": {"policies": .[1].appPolicies}}}}' $upfd/modified_config_2.json $configpath/./enable_lifecycle.json > $upfd/modified_config_3.json
jq -s '.[0] * {"channel_group":{"groups":{"Application": {"values": {"ACLs": {"value": {"acls": .[1].acls}}}}}}}' $upfd/modified_config_3.json $configpath/./enable_lifecycle.json > $upfd/modified_config.json

reEncode

# copy the config_update block
docker cp $upfd/config_update_in_envelope.pb cli:/opt/gopath/src/github.com/hyperledger/fabric/peer

signfrom

# get signature from peer0.org2
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/users/Admin@org2.brownbag.com/msp
CORE_PEER_LOCALMSPID=ORG2MSP
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/peers/peer0.org2.brownbag.com/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/peers/peer0.org2.brownbag.com/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/peers/peer0.org2.brownbag.com/tls/ca.crt
CORE_PEER_ADDRESS=peer0.org2.brownbag.com:8051

signfrom

CORE_PEER_ADDRESS=peer0.org1.brownbag.com:7051
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/users/Admin@brownbag.com/msp
CORE_PEER_LOCALMSPID=OrdererMSP
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/tls/ca.crt

submit

echo "removing file at /home/avinash/Desktop/bb2/upgrade/*"
rm -rf /home/avinash/Desktop/bb2/upgrade/*
