# Project Submission   
## Environment  
(template code updated to 8.15, WebPack to Version 5)   
Truffle v5.5.18 (core: 5.5.18)  
Ganache v7.2.0  
Solidity - ^0.8.15 (solc-js)  
Node v16.15.1  
Web3.js v1.5.3  
webpack@5.73.0  

## Rubric Walk Through  
## 1. Smart Contract Seperation
Utilized interface FlightSuretyData to interact with FlightSuretyApp  

## 2. Dapp Created and Used for Contract Calls  
Utilized Webpack version 5 and Twitter Bootstrap 5.1.3  
Inspection shows no errors or warntings  

<img width="763" alt="Webpack5 Dapp running" src="https://user-images.githubusercontent.com/103458204/178373842-4a84e02a-22a1-454e-99bd-50ea0533c97b.png">  

<img width="1477" alt="Dapp Run Inspect" src="https://user-images.githubusercontent.com/103458204/178373850-0a380f66-1623-44d6-96c0-c740f2c95036.png">

  
## 3. Oracle Server Application
Server shown operating with Oracle Transaction & Flight Ins  
  
<img width="1405" alt="Webpack Server Oracle Output" src="https://user-images.githubusercontent.com/103458204/178387019-9b49dc01-c485-426e-baf1-d98441182698.png">  
  
  
## 4. Operational status control is implemented in contracts
 modifier requireIsOperational() used throughout contract  
   
## 5. Fail Fast Contract  
8/12 functions in the App and   
9/18 functions in the Data contract have fail fast modifiers in use  
  
## 6. Airline Contract Initialization, Multiparty Consensus, Airline Ante  
  
    √ (multiparty) has correct initial isOperational() value (94ms)
    √ (multiparty) can block access to setOperatingStatus() for non-Contract Owner account (559ms)
    √ (multiparty) can allow access to setOperatingStatus() for Contract Owner account (105ms)
    √ (multiparty) can block access to functions using requireIsOperational when operating status is false (170ms)  
    
    √ (airline)    First airline is registered when contract is deployed (55ms)
    √ (airline)    First airline is registered and funded (113ms)
    √ (airline)    Registers a flight (357ms)
    √ (airline)    Cannot register using registerAirline() if it is not funded (105ms)
    √ (airline)    Can register second airline (167ms)
    √ (airline)    Can register using registerAirline() if it is funded (338ms)
    √ (airline)    Consensus not reached, register airline 5 will fail (283ms)
    √ (airline)    conensus reached 4 airlines registered, success register airline 5 (184ms)  
      
      
## 7. Passenger Airline Choice, Passenger Payment
## Passenger Repayment, Passenger Withdraw, Insurance Payouts

    √ (passenger)  Check that multiple flights can be registered (676ms)
    √ (passenger)  Buys insurance at insurance price (180ms)
    √ (passenger)  Can withdraw passenger credit (140ms)
    √ (passenger)  Can withdraw (99ms)
    √ (passenger)  Can update any status code for flight status (1025ms)  
    
      
## 8. Functioning Oracle, Oracle Initialization, Oracle Updates, Oracle Functionality  
  Contract: Oracles  
Oracle Registered: 2, 8, 3  
Oracle Registered: 5, 7, 0  
Oracle Registered: 9, 7, 0  
Oracle Registered: 6, 1, 3  
Oracle Registered: 1, 3, 7  
Oracle Registered: 7, 0, 6  
Oracle Registered: 9, 6, 1  
Oracle Registered: 4, 9, 1  
Oracle Registered: 4, 6, 5  
Oracle Registered: 6, 7, 3  
Oracle Registered: 0, 3, 6  
Oracle Registered: 9, 6, 4  
Oracle Registered: 9, 0, 1  
Oracle Registered: 8, 4, 5  
Oracle Registered: 5, 3, 6  
Oracle Registered: 8, 4, 9  
Oracle Registered: 5, 7, 8  
Oracle Registered: 4, 7, 6  
Oracle Registered: 4, 0, 8  
    √ can register oracles (6730ms)  
    √ can request flight status (980ms)  
    
## Ganache  
  
  <img width="877" alt="Ganache" src="https://user-images.githubusercontent.com/103458204/178389692-d1a12f24-65f0-4613-88e5-2c9f3de01f60.png">
  <img width="810" alt="Truffle Test" src="https://user-images.githubusercontent.com/103458204/178391482-424cae7f-1526-4181-8ce8-bd7376b9f48c.png">

  
## Environment Notes for Upgrade to Solidity 8.15, WebPack 5, & Truffle 5.5
The current template code is Soliity 4 and the infrastructure utilizes older Truffle  
WebPack, Web3 and Bable libs that are difficult to install in a current environment  
given dependancies.  Pairing more up to date components reduces numerous errors that  
are difficult to debug.

Template Code :  
Very few changes are required, mostly updates to mappings within Structs, 
storage vs. memory and visibility of functions.  

Webpack 5 :  
now requires Polyfill, recommend updating/adding the following:
resolve: {
    extensions: [".js"],
    fallback: {
      crypto: require.resolve("crypto-browserify"),
      stream: require.resolve("stream-browserify"),
      assert: require.resolve("assert"),
      http: require.resolve("stream-http"),
      https: require.resolve("https-browserify"),
      os: require.resolve("os-browserify"),
      url: require.resolve("url"),
    }

in order to display components a simple window.global is required:
polyfill.js:

import { Buffer } from 'buffer';

window.global = window;
global.Buffer = Buffer;
global.process = {
    env: { DEBUG: undefined },
    version: '',
    nextTick: require('next-tick')
};

Open Zeppelin :  
import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";

# ORIGINAL README INCLUDED BELOW THIS LINE ..........................

# FlightSurety

FlightSurety is a sample application project for Udacity's Blockchain course.

## Install

This repository contains Smart Contract code in Solidity (using Truffle), tests (also using Truffle), dApp scaffolding (using HTML, CSS and JS) and server app scaffolding.

To install, download or clone the repo, then:

`npm install`
`truffle compile`

## Develop Client

To run truffle tests:

`truffle test ./test/flightSurety.js`
`truffle test ./test/oracles.js`

To use the dapp:

`truffle migrate`
`npm run dapp`

To view dapp:

`http://localhost:8000`

## Develop Server

`npm run server`
`truffle test ./test/oracles.js`

## Deploy

To build dapp for prod:
`npm run dapp:prod`

Deploy the contents of the ./dapp folder

## Resources

- [How does Ethereum work anyway?](https://medium.com/@preethikasireddy/how-does-ethereum-work-anyway-22d1df506369)
- [BIP39 Mnemonic Generator](https://iancoleman.io/bip39/)
- [Truffle Framework](http://truffleframework.com/)
- [Ganache Local Blockchain](http://truffleframework.com/ganache/)
- [Remix Solidity IDE](https://remix.ethereum.org/)
- [Solidity Language Reference](http://solidity.readthedocs.io/en/v0.4.24/)
- [Ethereum Blockchain Explorer](https://etherscan.io/)
- [Web3Js Reference](https://github.com/ethereum/wiki/wiki/JavaScript-API)
