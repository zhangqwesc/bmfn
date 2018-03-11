#!/bin/bash

function setEnvironments() {
    if [ "$1" -eq 0 ]; then
        CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org0.zhang.com/users/Admin@org0.zhang.com/msp
        CORE_PEER_ADDRESS=peer0.org0.zhang.com:7051
        CORE_PEER_LOCALMSPID="Org0MSP"
        CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org0.zhang.com/peers/peer0.org0.zhang.com/tls/ca.crt
    else
        CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.zhang.com/users/Admin@org1.zhang.com/msp
        CORE_PEER_ADDRESS=peer0.org1.zhang.com:7051
        CORE_PEER_LOCALMSPID="Org1MSP"
        CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.zhang.com/peers/peer0.org1.zhang.com/tls/ca.crt
    fi
}
ORDERERCAFILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/zhang.com/orderers/orderer.zhang.com/msp/tlscacerts/tlsca.zhang.com-cert.pem

#create channel
peer channel create -o orderer.zhang.com:7050 -c mychannel -f ./channel-artifacts/channel.tx --tls --cafile $ORDERERCAFILE
if [ "$?" -ne 0 ]; then 
    echo "Something wrong"
    exit 1
fi

#join channel for peer0.org0
peer channel join -b mychannel.block
if [ "$?" -ne 0 ]; then 
    echo "Something wrong"
    exit 1
fi

#join channel for peer0.org1
setEnvironments 1
peer channel join -b mychannel.block
if [ "$?" -ne 0 ]; then 
    echo "Something wrong"
    exit 1
fi
setEnvironments 0

#update anchor peer for org0
peer channel update -o orderer.zhang.com:7050 -c mychannel -f ./channel-artifacts/Org0MSPanchors.tx \
    --tls --cafile $ORDERERCAFILE
if [ "$?" -ne 0 ]; then 
    echo "Something wrong"
    exit 1
fi

#update anchor peer for org1
setEnvironments 1
peer channel update -o orderer.zhang.com:7050 -c mychannel -f ./channel-artifacts/Org1MSPanchors.tx \
    --tls --cafile $ORDERERCAFILE
if [ "$?" -ne 0 ]; then 
    echo "Something wrong"
    exit 1
fi
setEnvironments 0

#install chaincode for org0 and org1
echo '################################'
echo '#####    install chaincode #####'
echo '################################'
peer chaincode install -n mycc -v 1.0 -p "github.com/chaincode/test"
if [ "$?" -ne 0 ]; then 
    echo "Something wrong"
    exit 1
fi
setEnvironments 1
peer chaincode install -n mycc -v 1.0 -p "github.com/chaincode/test"
setEnvironments 0

#instantiate chaincode for org0
echo '##########################################'
echo '##### instantiate chaincode for Org0 #####'
echo '##########################################'
peer chaincode instantiate -o orderer.zhang.com:7050 --tls --cafile $ORDERERCAFILE \
    -C mychannel -n mycc -v 1.0 -c '{"Args":["init", "pop", "300", "bob", "500"]}' -P "OR ('Org0MSP.peer', 'Org1MSP.peer')"
if [ "$?" -ne 0 ]; then 
    echo "Something wrong"
    exit 1
fi

echo '############### QUERY ###############'
peer chaincode query -C mychannel -n mycc -v 1.0 -c '{"Args":["query", "pop"]}'
if [ "$?" -ne 0 ]; then 
    echo "Something wrong"
    exit 1
fi
#setEnvironments 1
peer chaincode query -C mychannel -n mycc -v 1.0 -c '{"Args":["query", "pop"]}'
if [ "$?" -ne 0 ]; then 
    echo "Something wrong"
    exit 1
fi