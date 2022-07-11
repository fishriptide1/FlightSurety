import "./polyfill.js";
import DOM from "./dom";
import Contract from "./contract";
import "./styles/flightSurety.scss";

(async () => {
  let result = null;

  let contract = new Contract("localhost", () => {
    // Read transaction
    contract.isOperational((error, result) => {
      console.log(error, result);
      display("Operational Status", "Check if contract is operational", [
        { label: "Operational Status", error: error, value: result },
      ]);
    });

    contract.getFlightNumbers((error, result) => {
      console.log(error, result);
      displayFlights([{ label: result }]);
    });

    // User-submitted transaction
    DOM.elid("submit-oracle").addEventListener("click", () => {
      let flight = DOM.elid("flight-number").value;
      // Write transaction
      contract.fetchFlightStatus(flight, (error, result) => {
        display("Oracles", "Trigger oracles", [
          {
            label: "Fetch Flight Status",
            error: error,
            value: result.flight + " " + result.timestamp,
          },
        ]);
      });
    });

    DOM.elid("buy-insurance").addEventListener("click", () => {
      let flight = DOM.elid("flight-number-ins").value;
      // Write transaction
      contract.buyInsurance(flight, (error, result) => {
        display("Flight Insurance", "Buy Insurance", [
          {
            label: "Insurance",
            error: error,
            value: result.airline + " " + result.flight,
          },
        ]);
      });
    });
  });
})();

function display(title, description, results) {
  let displayDiv = DOM.elid("display-wrapper-fl");
  let section = DOM.section();
  section.appendChild(DOM.h2(title));
  section.appendChild(DOM.h5(description));
  results.map((result) => {
    let row = section.appendChild(DOM.div({ className: "row" }));
    row.appendChild(DOM.div({ className: "col-sm-4 field" }, result.label));
    row.appendChild(
      DOM.div(
        { className: "col-sm-8 field-value" },
        result.error ? String(result.error) : String(result.value)
      )
    );
    section.appendChild(row);
  });
  displayDiv.append(section);
}

function displayFlights(results) {
  let displayDiv = DOM.elid("display-wrapper-fl");
  let section = DOM.section();
  section.appendChild(DOM.h2("Flight Numbers"));
  section.appendChild(
    DOM.h5("Type the flight number of the flight you want to be insured")
  );

  results.map((result) => {
    for (let i = 0; i < result.label.length; i++) {
      let row = section.appendChild(DOM.div({ className: "row" }));
      row.appendChild(
        DOM.div({ className: "col-sm-left field" }, result.label[i])
      );
      section.appendChild(row);
    }
  });
  displayDiv.append(section);
}
