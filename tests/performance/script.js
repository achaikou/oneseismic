import http from "k6/http";
import { check, fail, sleep } from "k6";
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';


// one user gets the same piece of data (slice-curtain)
// one user gets random pieces of data
// many users get many pieces of data

// What about cache?

// add this thing as command line parameters?
export const options = {
  scenarios: {
    basic: {
      executor: "constant-vus",
      vus: 1,
      duration: "5s",
      //exec: "request",
    },
  },

  thresholds: {
    "checks{responseStatusChecks:query}": [{threshold: 'rate == 1.00'}],
    "checks{responseStatusChecks:status}": [{threshold: 'rate == 1.00'}],
    "checks{responseStatusChecks:result}": [{threshold: 'rate == 1.00'}],
    "checks{responseDataChecks:query}": [{threshold: 'rate == 1.00'}], //setup likely down
    "checks{responseDataChecks:status}": [{threshold: 'rate == 1.00'}],
  },
};

function sendRequest() {
  const server = __ENV.SERVER_URL;
  const auth   = __ENV.SAS
  const guid   = __ENV.GUID

  const query = `
  query getSlice{
    cube (id: "${guid}") {
        sliceByIndex(dim: 0, index: 0)
    }
  }`;

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
      'query response: no errors returned': (r) => !r.json().hasOwnProperty('errors'),
      //'query response: there is cube data': (r) => r.json()['data'].hasOwnProperty('cube'),
    },
    { responseDataChecks: "query" }
  );
  if (!queryResDataCheck) {
    fail(`Wrong 'query' response data: ${JSON.stringify(res.json())}`);
  }

  const queryRes = JSON.parse(res.body);
  return queryRes.data.cube.sliceByIndex;
}

function waitForOperationFinished(promise) {
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
  while (fetchStatus !== "finished") {
    const res = http.get(statusURL, options);

    const statusResStatusCheck = check(
      res,
      {
        "status response: status must be 200/202": (r) => r.status === 200 || r.status == 202,
      },
      { responseStatusChecks: "status" }
    );
    if (!statusResStatusCheck) {
      fail(`Wrong res status ${res.status}`);
    }

    const queryResDataCheck = check(
      res,
      {
        'status response: fetch status is present': (r) => r.json().hasOwnProperty('status'),
      },
      { responseDataChecks: "status" }
    );
    if (!queryResDataCheck) {
      fail(`Wrong 'query' response data: ${JSON.stringify(res.json())}`);
    }

    fetchStatus = JSON.parse(res.body).status;
  }
}

function retrieveResult(promise) {
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

export default function () {
//export function request() {
  const promise = sendRequest()
  waitForOperationFinished(promise)
  retrieveResult(promise)
  sleep(0.5)
}

export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: false }),
    "/out/summary.json": JSON.stringify(data),
  };
}
