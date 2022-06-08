import http from "k6/http";
import { check, fail, sleep } from "k6";

export function getRandomInt(max) {
  return Math.floor(Math.random() * max);
}

export const basicThresholds = {
  "checks{responseStatusChecks:query}": [{ threshold: "rate == 1.00" }],
  "checks{responseStatusChecks:status}": [{ threshold: "rate == 1.00" }],
  "checks{responseStatusChecks:result}": [{ threshold: "rate == 1.00" }],
  "checks{responseDataChecks:query}": [{ threshold: "rate == 1.00" }],
  "checks{responseDataChecks:status}": [{ threshold: "rate == 1.00" }],
};

export function sendRequest(query) {
  const server = __ENV.SERVER_URL;
  const auth = __ENV.SAS;

  const queryUrl = `${server}/graphql?${auth}`;
  const res = http.post(queryUrl, JSON.stringify({ query: query }), {});

  const queryResStatusCheck = check(
    res,
    {
      "query response: status must be 200": (r) => r.status === 200,
    },
    { responseStatusChecks: "query" }
  );
  if (!queryResStatusCheck) {
    fail(`Wrong 'query' response status: ${res.status}`);
  }

  const queryResDataCheck = check(
    res,
    {
      "query response: no errors returned": (r) =>
        !r.json().hasOwnProperty("errors"),
      //'query response: there is cube data': (r) => r.json()['data'].hasOwnProperty('cube'),
    },
    { responseDataChecks: "query" }
  );
  if (!queryResDataCheck) {
    fail(`Wrong 'query' response data: ${JSON.stringify(res.json())}`);
  }

  return JSON.parse(res.body);
}

export function waitForOperationFinished(promise) {
  const server = __ENV.SERVER_URL;

  const requestURL = promise.url;
  const token = promise.key;

  const statusURL = `${server}/${requestURL}/status`;
  const options = {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  };

  var fetchStatus = "";
  while (true) {
    const res = http.get(statusURL, options);

    const statusResStatusCheck = check(
      res,
      {
        "status response: status must be 200/202": (r) =>
          r.status === 200 || r.status == 202,
      },
      { responseStatusChecks: "status" }
    );
    if (!statusResStatusCheck) {
      fail(`Wrong res status ${res.status}`);
    }

    const queryResDataCheck = check(
      res,
      {
        "status response: fetch status is present": (r) =>
          r.json().hasOwnProperty("status"),
      },
      { responseDataChecks: "status" }
    );
    if (!queryResDataCheck) {
      fail(`Wrong 'query' response data: ${JSON.stringify(res.json())}`);
    }

    fetchStatus = JSON.parse(res.body).status;
    console.log(`Current progress is ${JSON.parse(res.body).progress}`);

    if (fetchStatus === "finished") {
      break;
    } else {
      // Result.Status (code in go) indicates there is a bug in status if we first ask for result too early?
      // unclear. Real error is due to pod restart
      sleep(0.5);
    }
  }
}

export function retrieveResult(promise) {
  const server = __ENV.SERVER_URL;

  const requestURL = promise.url;
  const token = promise.key;

  const options = {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  };

  const dataURL = `${server}/${requestURL}`;
  const res = http.get(dataURL, options);
  const dataResStatusCheck = check(
    res,
    {
      "result response: status must be 200": (r) => r.status === 200,
    },
    { responseStatusChecks: "result" }
  );
  if (!dataResStatusCheck) {
    fail(`Wrong 'result' response status: ${res.status}`);
  }
}
