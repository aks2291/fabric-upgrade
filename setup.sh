
clean() {
docker kill $(docker ps -qa)
docker rm $(docker ps -qa)
# docker images -a | grep "dev-" | awk '{print $3}' | xargs docker rmi
docker system prune -f
docker system prune --volumes -f
docker volume prune -f
docker network prune -f
}

createArtifacts() {
export FABRIC_CFG_PATH=$PWD
./bin/configtxgen -profile OrdererGenesis -channelID orderer-sys-channel -outputBlock ./channel-artifacts/genesis.block

export CHANNEL_NAME=mychannel
./bin/configtxgen -profile Org12Channel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME

# CREATE ANCHOR PEER CONFIG FOR ALL ORGS
./bin/configtxgen -profile Org12Channel -outputAnchorPeersUpdate ./channel-artifacts/ORG1anchors.tx -channelID $CHANNEL_NAME -asOrg ORG1
./bin/configtxgen -profile Org12Channel -outputAnchorPeersUpdate ./channel-artifacts/ORG2anchors.tx -channelID $CHANNEL_NAME -asOrg ORG2

}

createCAs() {
    docker-compose -f ./dockerfiles/docker-compose-ca.yaml up -d
}

createNet() {
 docker-compose -f ./dockerfiles/docker-compose-cli.yaml -f ./dockerfiles/docker-compose-couch.yaml up -d
 docker exec -ti cli bash -c "./cli-commands.sh"
}

# docker-compose -f ./dockerfiles/docker-compose-cli.yaml -f ./dockerfiles/docker-compose-couch.yaml down --volumes --remove-orphan
if [ $# -eq 0 ]
  then
    clean
    createArtifacts
    createCAs
    createNet
elif [ $1 = clean ]
then
    clean
elif [ $1 = art ]
then
    createArtifacts
elif [ $1 = ca ]
then
    createCAs
elif [ $1 = net ]
then
    clean
    createNet
fi

