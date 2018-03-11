package main

import (
	"fmt"
	"strconv"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

type myChainCode struct{}

func (t *myChainCode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("myChainCode Init")
	_, args := stub.GetFunctionAndParameters()
	var Key string
	var Val int

	if len(args) != 2 {
		return shim.Error("Incorrect number of arguments. Expecting 2")
	}

	Key = args[0]
	Val, err := strconv.Atoi(args[1])
	if err != nil {
		return shim.Error(err.Error())
	}
	fmt.Printf("Recv Key = %s, Val = %d\n", Key, Val)
	err = stub.PutState(Key, []byte(strconv.Itoa(Val)))
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(nil)
}

func (t *myChainCode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	fmt.Println("myChainCode Invoke")
	function, args := stub.GetFunctionAndParameters()
	if function == "add" {
		return t.add(stub, args)
	} else if function == "sub" {
		return t.sub(stub, args)
	} else if function == "query" {
		return t.query(stub, args)
	}
	return shim.Error("Invalid invoke function name. Expecting 'add', 'sub' and the 'query'")
}
func (t *myChainCode) add(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var Key string
	var Val, addNum int
	Key = args[0]
	addNum, err := strconv.Atoi(args[1])
	if err != nil {
		return shim.Error("Expecting an integer")
	}
	Valbytes, err := stub.GetState(Key)
	if err != nil {
		return shim.Error("Failed to get state")
	}
	if Valbytes == nil {
		return shim.Error("Entity not found")
	}
	Val, _ = strconv.Atoi(string(Valbytes))
	err = stub.PutState(Key, []byte(strconv.Itoa(Val+addNum)))
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success(nil)
}

func (t *myChainCode) sub(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	return shim.Success(nil)
}

func (t *myChainCode) query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	Key := args[0]
	valBytes, err := stub.GetState(Key)
	if err != nil {
		return shim.Error("Faild to get state")
	}
	if valBytes == nil {
		return shim.Error("Entity not found")
	}
	fmt.Printf("Query %s: %s\n", Key, string(valBytes))
	return shim.Success(valBytes)
}

func main() {
	err := shim.Start(new(myChainCode))
	if err != nil {
		fmt.Printf("Error starting myChainCode:%v\n", err)
	}
}
