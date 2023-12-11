# Random Number (Between 0 to 5) Generate Using Chainlink Oracle

The COORDINATOR address that we used to interact and get the random number was for "sepolia" test net. So you need to deploy it on sepolia test net.

```shell
1. Deploy the smart contract on sepolia test-net
2. Copy the contract address and put it in the chainlink to add as consumer
3. Call the "requestRandomWords" function
4. Get the latest requestID
4. Call the "getRequestStatus" function to check if the fulfilled status is true
5. if true then you will be able to see the generated random numbers in an array
```
