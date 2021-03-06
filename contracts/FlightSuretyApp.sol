// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;
    
    uint private constant MIN_AIRLINES = 4;

    address private contractOwner;          // Account used to deploy contract

    //     struct Flight {
    //     bool isRegistered;
    //     uint8 statusCode;
    //     uint256 updatedTimestamp;        
    //     address airline;
    // }
    // mapping(bytes32 => Flight) private flights;
    
    iFlightSuretyData flightSuretyData;

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() {
         // Modify to call data contract's status
        require(true, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the airline to have paid registration fee to be the function caller
    */
    modifier requireIsFunded() {
        bool funded = flightSuretyData.isFunded(msg.sender);
        require(funded == true, "Airline has not been funded");
        _;
    }

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event BuyRequest(address airline, string flight);

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor(address dataContract) {
        contractOwner = msg.sender;
        flightSuretyData = iFlightSuretyData(payable(dataContract));
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view returns(bool) {
        return flightSuretyData.isOperational();  // Modify to call data contract's status
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/


   /**
    * @dev Add an airline to the registration queue
    *
    */
    function registerAirline(address airline) external
        requireIsOperational
        requireIsFunded
        returns(bool success, uint256 votes)
    {
        success = false;
        votes = 1;

        if (flightSuretyData.numberOfAirlines() >= MIN_AIRLINES) {
            flightSuretyData.voteToRegisterAirline(airline);

            // at least half airlines have to approve new registration
            votes = flightSuretyData.getNumberOfRegistrationVotes(airline);
            //uint numberOfVotesNeeded = MIN_AIRLINES.div(2);

            if (votes >= MIN_AIRLINES.div(2)) {
                flightSuretyData.registerAirline(airline);
                success = true;
            }

        } else {
            flightSuretyData.registerAirline(airline);
            success = true;
        }

        return (success, votes);
    }

    /**
    * @dev Register a future flight for insuring.
    *
    */
    function registerFlight(address airline, string memory flight, uint256 timestamp) external
        requireIsOperational
    {
        flightSuretyData.registerFlight(airline, flight, timestamp);
    }

    /**
    * @dev Called after oracle has updated flight status
    *
    */
    function processFlightStatus(address airline, string memory flight, uint256 timestamp, uint8 statusCode) internal
        requireIsOperational
    {
        flightSuretyData.updateFlightStatus(airline, flight, timestamp, statusCode);
    }

    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus(address airline, string memory flight, uint256 timestamp) external {
        uint8 index = getRandomIndex(msg.sender);

        // // Generate a unique key for storing the request
        // bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        // oracleResponses[key] = ResponseInfo({requester: msg.sender, isOpen: true});

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));

        ResponseInfo storage request = oracleResponses[key];
        request.requester = msg.sender;
        request.isOpen = true;
        
        emit OracleRequest(index, airline, flight, timestamp);
    }

    /**
    * @dev check if Airline registered
    *
    */   
    function isRegistered(address airline) external view returns(bool)
    {
        return flightSuretyData.isRegistered(airline);
    }

    /**
    * @dev check if Airline fnded
    *
    */   
    function isFunded(address airline) external view returns(bool)
    {
        return flightSuretyData.isFunded(airline);
    }


    /**
     * @dev Fund an Airline
     *
     */
     function fund(address airline) public payable
        requireIsOperational
     {
         flightSuretyData.fund{ value: msg.value }(airline);
     }

    /**
     * @dev Called after oracle has updated flight status
     *
     */
     function withdraw() external payable
        requireIsOperational
     {
         flightSuretyData.pay(msg.sender);
     }

    /**
    * @dev helper function to return valid flight status code
    *      real world logic would replace this
    *
    */
    function getStatusCode(string memory statusCodeDescription) public pure returns(uint8)
    {
        uint8 code = STATUS_CODE_UNKNOWN;

        if (keccak256(abi.encodePacked(statusCodeDescription)) == 
            keccak256(abi.encodePacked("UNKNOWN"))) 
        {
            code = STATUS_CODE_UNKNOWN;
        } else if (keccak256(abi.encodePacked(statusCodeDescription)) == 
            keccak256(abi.encodePacked("ON_TIME"))) 
        {
            code = STATUS_CODE_ON_TIME;
        } else if (keccak256(abi.encodePacked(statusCodeDescription)) == 
            keccak256(abi.encodePacked("LATE_AIRLINE"))) 
        {
            code = STATUS_CODE_LATE_AIRLINE;
        } else if (keccak256(abi.encodePacked(statusCodeDescription)) == 
            keccak256(abi.encodePacked("LATE_WEATHER"))) 
        {
            code = STATUS_CODE_LATE_WEATHER;
        } else if (keccak256(abi.encodePacked(statusCodeDescription)) == 
            keccak256(abi.encodePacked("LATE_TECHNICAL"))) 
        {
            code = STATUS_CODE_LATE_TECHNICAL;
        } else if (keccak256(abi.encodePacked(statusCodeDescription)) == 
            keccak256(abi.encodePacked("LATE_OTHER"))) 
        {
            code = STATUS_CODE_LATE_OTHER;
        }
        return code;
    }

    /**
     * @dev Passenger purchase flight insurance
     *
     */
    function buy(address airline, string memory flight) external payable
        requireIsOperational
    {
        flightSuretyData.buy(msg.sender, airline, flight);
        emit BuyRequest(airline, flight);
    }

    /**
     * @dev Gets the flight numbers
     *
     */
    function getFlightNumbers() external view
        requireIsOperational
        returns(string[] memory)
    {
        return flightSuretyData.getFlightNumbers();
    }

    /**
    *  @dev Passenger amount for credit
    */
    function getPassengerCredit(address passenger) requireIsOperational external view returns(uint256) {
        return flightSuretyData.getPassengerCredit(passenger);
    }



    /********************************************************************************************/
    /*                                     ORACLE MANAGEMENT                                    */
    /********************************************************************************************/
    // region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);

    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({isRegistered: true, indexes: indexes});
    }

    function getMyIndexes() view external returns(uint8[3] memory) {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string memory flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }

    function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account) internal returns(uint8[3] memory) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);

        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address account) internal returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}

interface iFlightSuretyData {
    function registerAirline(address airline) external;
    function numberOfAirlines() external view returns(uint);
    function getFlightNumbers() external view returns(string[] memory);
    function isOperational() view external returns(bool);
    function isRegistered(address airline) view external returns(bool);
    function registerFlight(address airline, string memory flight, uint256 timestamp) external;
    function fund(address airline) external payable;
    function buy(address passenger, address airline, string memory flight) external payable;
    function pay(address passenger) external;
    function getPassengerCredit(address passenger) external view returns(uint256);
    function isFunded(address airline) view external returns(bool);
    function updateFlightStatus(address airline, string memory flight, uint256 timestamp, uint8 statusCode) external;
    function voteToRegisterAirline(address airline) external;
    function getNumberOfRegistrationVotes(address airline) external returns(uint);
}
