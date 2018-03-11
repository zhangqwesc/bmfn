#!/bin/bash

function networkUp() {

    #cryptogen tool
    which cryptogen
    if [ "$?" -ne 0 ]; then
        echo "cryptogen tool not found, exited"
        exit 1
    fi
    if [ -d crypto-config ]; then
        rm -rf crypto-config
    fi
    echo "cryptogen generate --config=./crypto-config.yaml"
    cryptogen generate --config=./crypto-config.yaml
    if [ "$?" -ne 0 ]; then
        echo "cryptogen generate faild, exited"
        exit 1
    fi
    echo "cryptogen generate success"

    #configtxgen tool
    which configtxgen
    if [ "$?" -ne 0 ]; then
        echo "configtxgen tool not found, exited"
        exit 1
    fi
    if [ -d channel-artifacts ]; then
        rm -rf channel-artifacts
    fi
    mkdir -p channel-artifacts

    echo  "FABRIC_CFG_PATH=${PWD} configtxgen -profile OrdererGenesis -outputBlock ./channel-artifacts/genesis.block"
    FABRIC_CFG_PATH=${PWD} configtxgen -profile OrdererGenesis -outputBlock ./channel-artifacts/genesis.block
    if [ "$?" -ne 0 ]; then
        echo "generate genesisBlock faild, exited"
        exit 1
    fi
    echo "generate genesisBlock success"

    echo "FABRIC_CFG_PATH=${PWD} configtxgen -profile BMFNChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID mychannel"
    FABRIC_CFG_PATH=${PWD} configtxgen -profile BMFNChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID mychannel
    if [ "$?" -ne 0 ]; then
        echo "create channel tx faild, exited"
        exit 1
    fi
    echo "create channel tx success"

    echo "FABRIC_CFG_PATH=${PWD} configtxgen -profile BMFNChannel -outputAnchorPeersUpdate ./channel-artifacts/Org0MSPanchors.tx -channelID mychannel -asOrg Org0MSP"
    FABRIC_CFG_PATH=${PWD} configtxgen -profile BMFNChannel -outputAnchorPeersUpdate ./channel-artifacts/Org0MSPanchors.tx -channelID mychannel -asOrg Org0MSP
    RCODE=$?
    echo "FABRIC_CFG_PATH=${PWD} configtxgen -profile BMFNChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP"
    FABRIC_CFG_PATH=${PWD} configtxgen -profile BMFNChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP
    if [ "$?" -ne 0 -o $RCODE -ne 0 ]; then
        echo "Update anchor peers faild, exited"
        exit 1
    fi
    echo "Update anchor peers success"

    echo 
    echo "#################################"
    echo "#####    docker-compose up ######"
    echo "#################################"
    docker-compose up -d
    echo 
    echo "started"
}

MODE=$1
if [ "$MODE" == "up" ]; then
    networkUp
elif [ "$MODE" == "down" ]; then
    docker-compose down
    echo "stoped"
else 
    echo "wrong command"
fi
