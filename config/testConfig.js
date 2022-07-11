var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require("bignumber.js");

var Config = async function (accounts) {
  // These test addresses are useful when you need to add
  // multiple users in test scripts
  let testAddresses = [
    accounts[0],
    accounts[1],
    accounts[2],
    accounts[3],
    accounts[4],
    accounts[5],
    accounts[6],
  ];

  let weiMultiple = new BigNumber(10).pow(18);
  let insuranceAmount = 1 * weiMultiple; // 1 ether in Wei

  let flightSuretyData = await FlightSuretyData.new(testAddresses[1]);
  let flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address);

  return {
    insuranceAmount,
    testAddresses: testAddresses,
    flightSuretyData: flightSuretyData,
    flightSuretyApp: flightSuretyApp,
  };
};

module.exports = {
  Config: Config,
};
