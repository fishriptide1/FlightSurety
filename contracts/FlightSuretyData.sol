// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner; // Account used to deploy contract
    bool private operational = true; // Blocks all state changes throughout the contract if false

    // Store Airline Information
    struct Airline {
        bool isRegistered;
        bool funded;
        mapping(string => uint) flightIDs;
    }
    mapping(address => Airline) private airlines;
    uint private countAirlines = 1; 
    mapping(address => uint) private airlineVotes;

    // Store Flight Information
    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
        uint id;
    }
    mapping(bytes32 => Flight) private flights;
    uint private flightCount = 1; 
    string[] private flightNumbers; 

    // Store Insurance Information
    struct Insurance {
        address[] passengers;  
        address airline; 
        string flight; 
        uint amount; 
    }
    mapping(uint => Insurance) private policies;
    mapping(address => uint256) private passengerCredits;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor(address firstAirline) {
        contractOwner = msg.sender;

        // Set first airline
        airlines[firstAirline].isRegistered = true;
        airlines[firstAirline].funded = true;
    }

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
    modifier requireIsOperational()
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that requires the "airline" to be registered
    */
    modifier requireRegisteredAirline(address airline) {
        require(airlines[airline].isRegistered == true, "Airline must be registered");
        _;
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireTenEther()
    {
        require(msg.value >= 10, "Airline must pay at least 10 ether");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational() view external returns(bool) {
        return operational;
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function registerAirline(address airline) external 
        requireIsOperational
    {
        require(!airlines[airline].isRegistered, "Airline is already registered.");

        //airlines[airline] = Airline(true, false);
        Airline storage rA = airlines[airline];
        rA.isRegistered = true;
        rA.funded = false;
        countAirlines = countAirlines.add(1);
    }

    /**
    * @dev Buy insurance for a flight
    *
    */
    function buy(address passenger, address airline, string memory flight) external payable
        requireIsOperational
        //requireRegisteredAirline(airline)
    {
        uint index = airlines[airline].flightIDs[flight];
        policies[index].passengers.push(passenger);

        payable(contractOwner).transfer(msg.value);
    }

    /**
    *  @dev Credits payouts to insurees
    */
    function creditInsurees(address airline, string memory flight) requireIsOperational external {
        uint index = airlines[airline].flightIDs[flight];
        uint amount = policies[index].amount;
        address[] memory passengers = policies[index].passengers;

        for (uint i=0; i < passengers.length; i++) {
            address passenger = passengers[i];
            uint256 currentCredit = passengerCredits[passenger];

            // Multiple by 1.5 for insurance payment
            uint256 m1 = amount.mul(3);
            uint256 div1 = m1.div(2);            
 
            // add to current amount
            uint256 creditAmount = currentCredit.add(div1);
            passengerCredits[passenger] = creditAmount;
        }
    }

    /**
    *  @dev Transfers eligible payout funds to insuree
    *
    */
    function pay(address passenger) external {
        uint256 passengerCreditAmount = passengerCredits[passenger];
        require(passengerCreditAmount > 0, "Passenger does not have enough credit");
        require(address(this).balance > 0, "Contract does not have enough credit");

        passengerCredits[passenger] = 0;
        payable(passenger).transfer(passengerCreditAmount);
    }

    /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund(address airline) public payable {
        airlines[airline].funded = true;
    }

    /**
    * @dev Creates a flight key using the airline, flight number and timestamp
    *
    */
    function getFlightKey(address airline, string memory flight, uint256 timestamp) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Returns the number of airlines that are registered
    *
    */
    function numberOfAirlines() external view
        requireIsOperational
        returns(uint)
    {
        return countAirlines;
    }

    /**
    * @dev checks if the address is an airline registered
    *
    */
    function isRegistered(address airline) view external
        returns(bool)
    {
        return airlines[airline].isRegistered;
    }

    /**
    * @dev Add vote to register airline
    *
    */
    function voteToRegisterAirline(address airline) external {
        uint currentNumberOfVotes = airlineVotes[airline];
        airlineVotes[airline] = currentNumberOfVotes.add(1);
    }

    /**
    * @dev Add vote to register airline
    *
    */
    function getNumberOfRegistrationVotes(address airline) external view
        returns(uint)
    {
        return airlineVotes[airline];
    }

    /**
    * @dev Add a flight to the flights mapping
    *
    */
    function registerFlight(address airline, string memory flight, uint256 timestamp) external
        requireIsOperational requireRegisteredAirline(airline)
    {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);

        flights[flightKey] = Flight(true, 0, timestamp, airline, flightCount);
        airlines[airline].flightIDs[flight] = flightCount;
        flightNumbers.push(flight);

        addInsurance(airline, flight);
    }

    /**
    * @dev Returns the flight numbers of the flights registered
    *
    */
    function getFlightNumbers() external view
        requireIsOperational
        returns(string[] memory)
    {
        return flightNumbers;
    }

    /**
    * @dev Returns the number of flights that are registered
    *
    */
    function numberOfFlights() external view
        requireIsOperational
        returns(uint)
    {
        return flightCount;
    }

    /**
    * @dev Add insurance to the policies mapping
    *
    */
    function addInsurance(address airline, string memory flight) internal {
        policies[flightCount].airline = airline;
        policies[flightCount].flight = flight;
        policies[flightCount].amount = 1 ether;

        // track total number of flights
        flightCount = flightCount.add(1);
    }

    /**
    * @dev Get flight insurance passenger addresses. This is used for unit testing.
    *
    */
    function getInsuranceOwners(address airline, string memory flight) view external returns(address[] memory) {
        uint index = airlines[airline].flightIDs[flight];
        return policies[index].passengers;
    }

    /**
    *  @dev helper function return amount for testing insurance amount 
    */
    function getPassengerCredit(address passenger) requireIsOperational external view returns(uint256) {
        return passengerCredits[passenger];
    }

    /**
    * @dev checks if the airline has paid registration fee
    *
    */
    function isFunded(address airline) view external returns(bool) {
        return airlines[airline].funded;
    }

    /**
    * @dev checks if the airline has paied registration fee
    *
    */
    function updateFlightStatus(address airline, string memory flight, uint256 timestamp, uint8 statusCode) external {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        flights[flightKey].statusCode = statusCode;
    }

    /**
    * @dev Gets the status of the flight
    *
    */
    function getFlightStatus(address airline, string memory flight, uint256 timestamp) view external returns(uint8) {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        return flights[flightKey].statusCode;
    }

    /**
    * @dev Fallback function for funding smart contract.
    */
    fallback() external payable 
    {
        fund(msg.sender);
    }

    /**
    * @dev Receive function, a fallback when call data is empty
    */
    receive() external payable {
        fund(msg.sender);
    }

}
