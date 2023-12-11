// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

contract VRFv2Consumer is VRFConsumerBaseV2, ConfirmedOwner {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    //requestId --> requestStatus
    mapping(uint256 => RequestStatus) public s_requests; 
    
    //////////
    //declaring variables
    /////////

    //the manager of "VRFCoordinatorV2Interface" type
    // the ccordinator will help us in generating random number. 
    //From network to network the coordinator difffers
    VRFCoordinatorV2Interface COORDINATOR;

    // The sunscription Id from chainlink VRF.
    uint64 s_subscriptionId;

    // Put request IDs in an array
    uint256[] public requestIds;
    // taking the last request ID
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price will be used by the executing functions 
    // So that accidentally or maliciously extra ether is not fetched.
    // To see Visit https://docs.chain.link/vrf/v2/subscription/supported-networks#sepolia-testnet
    // This is the 150 gwei Key Hash for the sepolia test net
    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;

    // Depends on the number of requested values that you want sent to the fulfillRandomWords() function. 
    //Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. 
    //Test and adjust this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords() function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 2;

    /**
     FOR SEPOLIA NETWORK THE COORDINATOR: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
    **/
    constructor(uint64 subscriptionId) VRFConsumerBaseV2(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625) ConfirmedOwner(msg.sender) {
        COORDINATOR = VRFCoordinatorV2Interface(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );
        s_subscriptionId = subscriptionId;
    }

    // After the subscription is funded sufficiently we will execute this function to request random words
    // at the end of executing this function the request for random workds will be successul 
    // and we will get the request IDs for each number of words we requested. (Here we requested for 2 words)
    // after that this function will internally call the next function "fulfillRandomWords"
    // where exactly the generation of random words will happen
    function requestRandomWords() external onlyOwner returns (uint256 requestId){
        
        // Will revert if subscription is not set and funded.
        // requesting through the co-ordinator for id by giving the following parameter
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    
        // after getting ID mapping the initial information with respect to the received ID
        // initially the array "randomWords" is empty because the words are not generated yet
        // existance is true
        // but fulfilled is false
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });

        // the generated request ID is pushed in the array declared above
        requestIds.push(requestId);
        lastRequestId = requestId; // last request ID is set
        emit RequestSent(requestId, numWords); // emit the event of a successful request
        return requestId;
    }

//this is an internal function.
// this is called and handled by the requestRandomWords() function internally
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {

        //checks if the ID exist or no means the ID is generated or not
        require(s_requests[_requestId].exists, "request not found");

        // after confirming ID, mapping the generated words information(in struct) with respect to the received ID
        // initially the array "randomWords" is empty because the words are not generated yet

        // after generating the "fulfilled" is made true
        s_requests[_requestId].fulfilled = true;

        // the array of generated words is also set
        s_requests[_requestId].randomWords = _randomWords;

        emit RequestFulfilled(_requestId, _randomWords); // emit the event of a successful generation of random words
    }

//We can check if the request of generating random number is successful or not
// and also see the generated numbers themselves
    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        //checks if the words with the given ID exist or not, means if the words is generated or not
        require(s_requests[_requestId].exists, "request not found");
        
        // if ok. then take array of the generated random words
        RequestStatus memory request = s_requests[_requestId];
        
        // make the words within our desired range(Here we wanted to get random words between 0 to 4)
        uint256[] memory finalWords= new uint256[](request.randomWords.length);
        for(uint i =0; i<request.randomWords.length; i++){
             finalWords[i]=(request.randomWords[i]%5);
        }

        return (request.fulfilled, finalWords);
    }
}
