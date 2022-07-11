var Test = require("../config/testConfig.js");
var BigNumber = require("bignumber.js");
const Web3 = require("web3");
var debug = require("debug")("FlightSuretyTests");

contract("Flight Surety Tests", async (accounts) => {
  var config;
  before("setup contract", async () => {
    config = await Test.Config(accounts);
  });

  const owner = 0;
  const firstAirline = 1;
  const airline2 = 2;
  const airline3 = 3;
  const airline4 = 4;
  const airline5 = 5;
  const passenger = 6;

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  // debug("Testing Accounts :", accounts);

  it(`(multiparty) has correct initial isOperational() value`, async function () {
    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");
  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {
    // Ensure that access is denied for non-Contract Owner account
    let accessDenied = false;
    try {
      await config.flightSuretyData.setOperatingStatus(false, {
        from: config.testAddresses[airline2],
      });
    } catch (e) {
      accessDenied = true;
    }

    assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {
    // Ensure that access is allowed for Contract Owner account
    let accessDenied = false;
    try {
      await config.flightSuretyData.setOperatingStatus(false);
    } catch (e) {
      accessDenied = true;
    }

    assert.equal(
      accessDenied,
      false,
      "Access not restricted to Contract Owner"
    );
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {
    await config.flightSuretyData.setOperatingStatus(false);

    let reverted = false;
    try {
      await config.flightSurety.setTestingMode(true);
    } catch (e) {
      reverted = true;
    }

    assert.equal(reverted, true, "Access not blocked for requireIsOperational");

    // Set it back for other tests to work
    await config.flightSuretyData.setOperatingStatus(true);
  });

  it(`(airline)    First airline is registered when contract is deployed`, async function () {
    let result = await config.flightSuretyApp.isRegistered(
      config.testAddresses[firstAirline],
      { from: config.testAddresses[owner] }
    );
    assert.equal(result, true, "First airline should be registered");
  });

  it("(airline)    First airline is registered and funded", async () => {
    let result = await config.flightSuretyApp.isRegistered(
      config.testAddresses[firstAirline],
      { from: config.testAddresses[owner] }
    );

    let funded = await config.flightSuretyApp.isFunded(
      config.testAddresses[firstAirline]
    );

    assert.equal(funded, true, "First airline preset to funded");
    assert.equal(result, true, "First airline preset to registered");
  });

  it("(airline)    Registers a flight", async () => {
    let timestamp = Math.floor(Date.now() / 1000);

    let didRegisterFlight = true;
    let flight = "ND1309"; // Course number

    try {
      await config.flightSuretyApp.registerFlight(
        config.testAddresses[firstAirline],
        flight,
        timestamp
      );
    } catch (e) {
      didRegisterFlight = true;
    }

    let result = await config.flightSuretyApp.fetchFlightStatus(
      config.testAddresses[firstAirline],
      flight,
      timestamp
    );

    assert.equal(didRegisterFlight, true, "Flight failed to be registered");
    assert.equal(result.logs[0].args[2], flight, "Flight should be registered");
  });

  it("(airline)    Cannot register using registerAirline() if it is not funded", async () => {
    var canRegister = true;

    try {
      await config.flightSuretyApp.registerAirline(
        config.testAddresses[airline3],
        {
          from: config.testAddresses[airline2],
        }
      );
    } catch (e) {
      canRegister = false;
    }

    assert.equal(
      canRegister,
      false,
      "Airline should not be able to register another airline if it hasn't provided funding"
    );
  });

  it("(airline)    Can register second airline", async () => {
    await config.flightSuretyApp.registerAirline(
      config.testAddresses[airline2],
      {
        from: config.testAddresses[firstAirline],
      }
    );

    let result = await config.flightSuretyApp.isRegistered(
      config.testAddresses[airline2],
      { from: config.testAddresses[firstAirline] }
    );

    assert.equal(
      result,
      true,
      "First airline is able to register a second airline"
    );
  });

  it("(airline)    Can register using registerAirline() if it is funded", async () => {
    let registrationFee = Web3.utils.toWei("10", "ether");

    await config.flightSuretyApp.fund(config.testAddresses[airline2], {
      from: config.testAddresses[airline2],
      value: registrationFee,
      gasPrice: 0,
    });
    let funded = await config.flightSuretyApp.isFunded(
      config.testAddresses[airline2]
    );

    await config.flightSuretyApp.registerAirline(
      config.testAddresses[airline3],
      {
        from: config.testAddresses[airline2],
      }
    );

    let result = await config.flightSuretyApp.isRegistered(
      config.testAddresses[airline3],
      { from: config.testAddresses[airline2] }
    );
    assert.equal(funded, true, "Airline is Not Funded");
    assert.equal(
      result,
      true,
      "Airline should be able to register another airline if it has provided funding"
    );
  });

  it("(airline)    Consensus not reached, register airline 5 will fail", async () => {
    // Register Airline 4 and attempt to Register Airline 5 (fails consensus)
    await config.flightSuretyApp.registerAirline(
      config.testAddresses[airline4],
      {
        from: config.testAddresses[firstAirline],
      }
    );
    await config.flightSuretyApp.registerAirline(
      config.testAddresses[airline5],
      {
        from: config.testAddresses[firstAirline],
      }
    );

    let result = await config.flightSuretyApp.isRegistered(
      config.testAddresses[airline5],
      { from: config.testAddresses[firstAirline] }
    );
    assert.equal(result, false, "Fifth airline should not be registered");
  });

  it("(airline)    conensus reached 4 airlines registered, success register airline 5", async () => {
    // Register Airline 5 with consensus from airline 2, should succeed
    await config.flightSuretyApp.registerAirline(
      config.testAddresses[airline5],
      { from: config.testAddresses[airline2] }
    );

    let result = await config.flightSuretyApp.isRegistered(
      config.testAddresses[airline5],
      { from: config.testAddresses[firstAirline] }
    );
    assert.equal(result, true, "Fifth airline should be registered");
  });

  it("(passenger)  Check that multiple flights can be registered", async () => {
    let timestamp1 = Math.floor(Date.now() / 1000);
    let flight1 = "ND1309a"; // Course number

    await config.flightSuretyApp.registerFlight(
      config.testAddresses[firstAirline],
      flight1,
      timestamp1
    );

    let timestamp2 = Math.floor(Date.now() / 1000);
    let flight2 = "ND1309b"; // Course number

    await config.flightSuretyApp.registerFlight(
      config.testAddresses[firstAirline],
      flight2,
      timestamp2
    );

    let flightNumbers = await config.flightSuretyApp.getFlightNumbers.call();
    //debug("Flight Numbers: ", flightNumbers);

    // check 3 added flight numbers
    assert.equal(flightNumbers[0], "ND1309", "Flight 1 matches");
    assert.equal(flightNumbers[1], "ND1309a", "Flight 2 matches");
    assert.equal(flightNumbers[2], "ND1309b", "Flight 3 matches");
  });

  it("(passenger)  Buys insurance at insurance price", async () => {
    let flight = "ND1309"; // Course number

    let curBal = new BigNumber(
      await web3.eth.getBalance(config.testAddresses[passenger])
    );

    await config.flightSuretyApp.buy(
      config.testAddresses[firstAirline],
      flight,
      {
        from: config.testAddresses[passenger],
        value: config.insuranceAmount,
        gasPrice: 0,
      }
    );

    let passengers = await config.flightSuretyData.getInsuranceOwners.call(
      config.testAddresses[firstAirline],
      flight,
      { from: config.testAddresses[passenger] }
    );
    let isPassengerInsured = passengers.includes(
      config.testAddresses[passenger]
    );

    let newBal = new BigNumber(
      await web3.eth.getBalance(config.testAddresses[passenger])
    );

    let result = curBal.minus(newBal);

    assert.equal(isPassengerInsured, true, "Passenger address does not match");
    assert.equal(
      result,
      config.insuranceAmount,
      "Balance deducted is not correct"
    );
  });

  it("(passenger)  Can withdraw passenger credit", async () => {
    let flight = "ND1309"; // Course number
    await config.flightSuretyData.creditInsurees(
      config.testAddresses[firstAirline],
      flight
    );

    let result = await config.flightSuretyApp.getPassengerCredit.call(
      config.testAddresses[passenger]
    );

    let multipliedAmount = BigNumber(config.insuranceAmount).multipliedBy(
      BigNumber(1.5)
    );

    assert.equal(
      result,
      multipliedAmount.toNumber(),
      "Passenger does not match the exepected value"
    );
  });

  it("(passenger)  Can withdraw", async () => {
    let curBal = BigNumber(
      await web3.eth.getBalance(config.testAddresses[passenger])
    );

    await config.flightSuretyApp.withdraw({
      from: config.testAddresses[passenger],
      gasPrice: 0,
    });

    let newBal = BigNumber(
      await web3.eth.getBalance(config.testAddresses[passenger])
    );
    let result = newBal.minus(curBal);
    let expected = Web3.utils.toWei("1.5", "ether");

    assert.equal(
      result,
      expected,
      "Balance difference does not match the exepected value"
    );
  });

  it("(passenger)  Can update any status code for flight status", async () => {
    let timestamp = Math.floor(Date.now() / 1000);
    let flight = "ND1309"; // Course number

    let flightStatusCodes = [
      "UNKNOWN",
      "ON_TIME",
      "LATE_AIRLINE",
      "LATE_WEATHER",
      "LATE_TECHNICAL",
      "LATE_OTHER",
    ];
    for (let idx = 0; idx < flightStatusCodes.length; idx++) {
      let code = new BigNumber(
        await config.flightSuretyApp.getStatusCode(flightStatusCodes[idx])
      );

      await config.flightSuretyData.updateFlightStatus(
        config.testAddresses[firstAirline],
        flight,
        timestamp,
        code.toNumber()
      );

      let result = await config.flightSuretyData.getFlightStatus(
        config.testAddresses[firstAirline],
        flight,
        timestamp
      );
      assert.equal(result, code.toNumber(), "Flight status should be updated");
    }
  });
});
