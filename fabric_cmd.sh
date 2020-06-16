./bin/cryptogen generate --output="crypto-config" --config=crypto-config.yaml

peer chaincode query -C mychannel -n mycc -c '{"Args":["queryAllCars"]}'
peer chaincode query -C mychannel -n mycc -c '{"Args":["queryCar", "CAR0"]}' #CAR0 - CAR9

########### Invoke chaincode ############# Create a car
peer chaincode invoke -o orderer.brownbag.com:7050 --tls --cafile $ORDERER_CA -C mychannel -n mycc \
--peerAddresses peer0.org1.brownbag.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/ca.crt \
--peerAddresses peer0.org2.brownbag.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/peers/peer0.org2.brownbag.com/tls/ca.crt -c '{"Args":["createCar","CAR10","BMW","XL50","white", "Bob"]}' --waitForEvent

# install and invoke new lifecycle chaincode
# install chaincode
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/brownbag.com/orderers/orderer.brownbag.com/msp/tlscacerts/tlsca.brownbag.com-cert.pem

VERSION=2.0
SEQUENCE=1
CHANNEL_NAME=mychannel
CHAINCODE_NAME=mycc
PACKAGE_ID=mycc_2.0:d92ee69ca18b2dbd66b2df8a7781312b9c5a782a6bbdf4fea9813bcb39d2cbdb

# package chaincode 
peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz --path /opt/gopath/src/github.com/chaincode/javascript --lang node --label ${CHAINCODE_NAME}_${VERSION}
peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz

peer lifecycle chaincode approveformyorg -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} -v ${VERSION} --sequence ${SEQUENCE} --init-required --package-id $PACKAGE_ID --tls true --cafile $ORDERER_CA --signature-policy "OR ('ORG1MSP.member','ORG2MSP.member')"
peer lifecycle chaincode checkcommitreadiness -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} -v ${VERSION} --sequence ${SEQUENCE} --init-required --tls true --cafile $ORDERER_CA --signature-policy "OR ('ORG1MSP.member','ORG2MSP.member')" --output json

peer lifecycle chaincode commit -o orderer.brownbag.com:7050 -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} -v ${VERSION} --sequence ${SEQUENCE} --init-required --tls true --cafile $ORDERER_CA --signature-policy "OR ('ORG1MSP.member','ORG2MSP.member')" \
--peerAddresses peer0.org1.brownbag.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/ca.crt \
--peerAddresses peer0.org2.brownbag.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/peers/peer0.org2.brownbag.com/tls/ca.crt


peer chaincode invoke -o orderer.brownbag.com:7050 --isInit --tls true --cafile $ORDERER_CA -C ${CHANNEL_NAME} -n ${CHAINCODE_NAME} \
--peerAddresses peer0.org1.brownbag.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/ca.crt \
--peerAddresses peer0.org2.brownbag.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/peers/peer0.org2.brownbag.com/tls/ca.crt \
-c '{"Args":["createCar","CAR12","BMW","XL50","white", "Bob"]}' --waitForEvent


# Org2 peer0 MSP
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/users/Admin@org2.brownbag.com/msp
CORE_PEER_LOCALMSPID=ORG2MSP
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/peers/peer0.org2.brownbag.com/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/peers/peer0.org2.brownbag.com/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.brownbag.com/peers/peer0.org2.brownbag.com/tls/ca.crt
CORE_PEER_ADDRESS=peer0.org2.brownbag.com:8051

# Org1 peer0 MSP
CH_NAME=mychannel
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/users/Admin@org1.brownbag.com/msp
CORE_PEER_LOCALMSPID=ORG1MSP
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/server.crt
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/server.key
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.brownbag.com/peers/peer0.org1.brownbag.com/tls/ca.crt
CORE_PEER_ADDRESS=peer0.org1.brownbag.com:7051