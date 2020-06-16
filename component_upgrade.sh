# Stage 1
########################### ORDERER ################
# BACKUP location
LEDGERS_BACKUP=backup
IMAGE_TAG=2.0
COUCHDB_TAG=0.4
ENV_FOLDER=./docker_env_list
# ###### Orderer backup and Upgrade in rolling fashion #####
# Stop orderer first
ORDERER_CONTAINER=orderer.brownbag.com
docker stop $ORDERER_CONTAINER
mkdir ./$LEDGERS_BACKUP/$ORDERER_CONTAINER
docker cp $ORDERER_CONTAINER:/var/hyperledger/production/orderer/ ./$LEDGERS_BACKUP/$ORDERER_CONTAINER/data

# backup msp tls and genesis block
docker cp $ORDERER_CONTAINER:/var/hyperledger/orderer/ ./$LEDGERS_BACKUP/$ORDERER_CONTAINER/msp

# remove orderer container
docker rm -f $ORDERER_CONTAINER

# Upgrade the orderer with new images and start with backup
docker run -d -v $(pwd)/$LEDGERS_BACKUP/$ORDERER_CONTAINER/data/:/var/hyperledger/production/orderer/ \
            -v $(pwd)/$LEDGERS_BACKUP/$ORDERER_CONTAINER/msp/:/var/hyperledger/orderer/ \
            --env-file $ENV_FOLDER/$ORDERER_CONTAINER.list \
            --name $ORDERER_CONTAINER \
            -w /opt/gopath/src/github.com/hyperledger/fabric \
            -p 7050:7050 \
            --network=net_bb2 \
            hyperledger/fabric-orderer:$IMAGE_TAG orderer

# check version orderer 
docker exec orderer.brownbag.com sh -c "orderer version"
########################### ORDERER END ################

# Upgrade the peers and their databases
########################### ORG1 ################

PEER_CONTAINER=peer0.org1.brownbag.com
docker stop $PEER_CONTAINER
mkdir ./$LEDGERS_BACKUP/$PEER_CONTAINER
# backup data, msp and tls
docker cp $PEER_CONTAINER:/var/hyperledger/production/ ./$LEDGERS_BACKUP/$PEER_CONTAINER/data
docker cp $PEER_CONTAINER:/etc/hyperledger/fabric/msp ./$LEDGERS_BACKUP/$PEER_CONTAINER/msp
docker cp $PEER_CONTAINER:/etc/hyperledger/fabric/tls ./$LEDGERS_BACKUP/$PEER_CONTAINER/tls
docker rm -f $PEER_CONTAINER

# remove all chaincode containers of peer0.org1
CC_CONTAINERS=$(docker ps -a | grep dev-$PEER_CONTAINER | awk '{print $1}')
if [ -n "$CC_CONTAINERS" ] ; then docker rm -f $CC_CONTAINERS ; fi

CC_IMAGES=$(docker images | grep dev-$PEER_CONTAINER | awk '{print $1}')
if [ -n "$CC_IMAGES" ] ; then docker rmi -f $CC_IMAGES ; fi

# CouchDB for peer0.org1
COUCHDB_CONTAINER=couchdb-org1
docker stop $COUCHDB_CONTAINER
docker rm -f $COUCHDB_CONTAINER

# couchdb up
docker run -d \
--env-file $ENV_FOLDER/couchdb.list \
-p 5984:5984 --name $COUCHDB_CONTAINER  \
--network=net_bb2 \
hyperledger/fabric-couchdb:$COUCHDB_TAG

# peer databases upgrades
docker run --rm -v $(pwd)/$LEDGERS_BACKUP/$PEER_CONTAINER/data:/var/hyperledger/production/ \
            -v $(pwd)/$LEDGERS_BACKUP/$PEER_CONTAINER/msp:/etc/hyperledger/fabric/msp/ \
            -v $(pwd)/$LEDGERS_BACKUP/$PEER_CONTAINER/tls:/etc/hyperledger/fabric/tls/ \
            --env-file $ENV_FOLDER/$PEER_CONTAINER.list \
            --env-file $ENV_FOLDER/peer-base.list \
            -p 7051:7051 \
            --name $PEER_CONTAINER \
            --network=net_bb2 \
            -w /opt/gopath/src/github.com/hyperledger/fabric/peer \
            hyperledger/fabric-peer:$IMAGE_TAG peer node upgrade-dbs

docker run -d -v $(pwd)/$LEDGERS_BACKUP/$PEER_CONTAINER/data:/var/hyperledger/production/ \
            -v $(pwd)/$LEDGERS_BACKUP/$PEER_CONTAINER/msp:/etc/hyperledger/fabric/msp/ \
            -v $(pwd)/$LEDGERS_BACKUP/$PEER_CONTAINER/tls:/etc/hyperledger/fabric/tls/ \
            -v /var/run/:/host/var/run/ \
            --env-file $ENV_FOLDER/$PEER_CONTAINER.list \
            --env-file $ENV_FOLDER/peer-base.list \
            -p 7051:7051 \
            --name $PEER_CONTAINER \
            --network=net_bb2 \
            -w /opt/gopath/src/github.com/hyperledger/fabric/peer \
            hyperledger/fabric-peer:$IMAGE_TAG peer node start

########################### ORG1 END ################


########################### ORG2 ################

PEER_CONTAINER=peer0.org2.brownbag.com
docker stop $PEER_CONTAINER
mkdir ./$LEDGERS_BACKUP/$PEER_CONTAINER
# backup data, msp and tls
docker cp $PEER_CONTAINER:/var/hyperledger/production/ ./$LEDGERS_BACKUP/$PEER_CONTAINER/data
docker cp $PEER_CONTAINER:/etc/hyperledger/fabric/msp ./$LEDGERS_BACKUP/$PEER_CONTAINER/msp
docker cp $PEER_CONTAINER:/etc/hyperledger/fabric/tls ./$LEDGERS_BACKUP/$PEER_CONTAINER/tls
docker rm -f $PEER_CONTAINER

# remove all chaincode containers of peer0.org2
CC_CONTAINERS=$(docker ps -a | grep dev-$PEER_CONTAINER | awk '{print $1}')
if [ -n "$CC_CONTAINERS" ] ; then docker rm -f $CC_CONTAINERS ; fi

CC_IMAGES=$(docker images | grep dev-$PEER_CONTAINER | awk '{print $1}')
if [ -n "$CC_IMAGES" ] ; then docker rmi -f $CC_IMAGES ; fi

# CouchDB for peer0.org2
COUCHDB_CONTAINER=couchdb-org2
docker stop $COUCHDB_CONTAINER
docker rm -f $COUCHDB_CONTAINER

# couchdb up
docker run -d \
--env-file $ENV_FOLDER/couchdb.list \
-p 6984:5984 \
--name $COUCHDB_CONTAINER  \
--network=net_bb2 \
hyperledger/fabric-couchdb:$COUCHDB_TAG

# peer databases upgrades
docker run --rm -v $(pwd)/$LEDGERS_BACKUP/$PEER_CONTAINER/data:/var/hyperledger/production/ \
            -v $(pwd)/$LEDGERS_BACKUP/$PEER_CONTAINER/msp:/etc/hyperledger/fabric/msp/ \
            -v $(pwd)/$LEDGERS_BACKUP/$PEER_CONTAINER/tls:/etc/hyperledger/fabric/tls/ \
            --env-file $ENV_FOLDER/$PEER_CONTAINER.list \
            --env-file $ENV_FOLDER/peer-base.list \
            -p 8051:8051 \
            --name $PEER_CONTAINER \
            --network=net_bb2 \
            -w /opt/gopath/src/github.com/hyperledger/fabric/peer \
            hyperledger/fabric-peer:$IMAGE_TAG peer node upgrade-dbs

docker run -d -v $(pwd)/$LEDGERS_BACKUP/$PEER_CONTAINER/data:/var/hyperledger/production/ \
            -v $(pwd)/$LEDGERS_BACKUP/$PEER_CONTAINER/msp:/etc/hyperledger/fabric/msp/ \
            -v $(pwd)/$LEDGERS_BACKUP/$PEER_CONTAINER/tls:/etc/hyperledger/fabric/tls/ \
            -v /var/run/:/host/var/run/ \
            --env-file $ENV_FOLDER/$PEER_CONTAINER.list \
            --env-file $ENV_FOLDER/peer-base.list \
            -p 8051:8051 \
            --name $PEER_CONTAINER \
            --network=net_bb2 \
            -w /opt/gopath/src/github.com/hyperledger/fabric/peer \
            hyperledger/fabric-peer:$IMAGE_TAG peer node start

########################### ORG2 END ################

# ############# CLI Upgrade ###############
PEER_CONTAINER=cli
docker stop $PEER_CONTAINER
docker rm -f $PEER_CONTAINER

docker run -d -v $(pwd)/chaincode/:/opt/gopath/src/github.com/chaincode \
            -v $(pwd)/crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ \
            -v $(pwd)/channel-artifacts:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/ \
            -v $(pwd)/cli-commands.sh:/opt/gopath/src/github.com/hyperledger/fabric/peer/cli-commands.sh \
            -v /var/run/:/host/var/run/ \
            --env-file $ENV_FOLDER/$PEER_CONTAINER.list \
            --name $PEER_CONTAINER \
            --network=net_bb2 \
            --tty=true \
            -w /opt/gopath/src/github.com/hyperledger/fabric/peer \
            hyperledger/fabric-tools:$IMAGE_TAG /bin/bash

# ############# CLI Upgrade END ###############