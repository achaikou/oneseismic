import http from "k6/http";
import { check, fail, sleep } from "k6";

export function getRandomInt(max) {
  return Math.floor(Math.random() * max);
}

export function runRequest(request) {
  const promise = request();
  waitForOperationFinished(promise);
  retrieveResult(promise);
  sleep(0.1);
}

export function sendRequest(query) {
  const server = __ENV.SERVER_URL;
  const auth = __ENV.SAS;

  const queryUrl = `${server}/graphql?${auth}`;
  const body = JSON.stringify({ query: query });
  const options = {
    responseType: "text",
  };
  const res = http.post(queryUrl, body, options);

  const queryResStatusCheck = check(
    res,
    {
      "query response: status must be 200": (r) => r.status === 200,
    },
    { "status checks": "query" }
  );
  if (!queryResStatusCheck) {
    fail(`Wrong 'query' response status: ${res.status}`);
  }

  const data = res.json().data;
  if (!data) {
    fail(`Wrong 'query' response: ${JSON.stringify(res.json())}`);
  }

  const queryResDataCheck = check(
    data,
    {
      "query response: no errors returned": (d) => !d.hasOwnProperty("errors"),
      "query response: there is cube data": (d) => d.hasOwnProperty("cube"),
    },
    { "data checks": "query" }
  );
  if (!queryResDataCheck) {
    fail(`Wrong 'query' response data: ${JSON.stringify(data)}`);
  }

  return data;
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
    responseType: "text",
  };

  const SLEEP_TIME = 0.5; // seconds
  const CONSIDER_LOST_AFTER = 40; // seconds
  const MAX_ATTEMPTS = Math.ceil(CONSIDER_LOST_AFTER / SLEEP_TIME);

  let attempts = 0;

  while (attempts != MAX_ATTEMPTS) {
    const res = http.get(statusURL, options);

    const statusResStatusCheck = check(
      res,
      {
        "status response: status must be 200/202": (r) =>
          r.status === 200 || r.status === 202,
      },
      { "status checks": "waiting for finished status" }
    );
    if (!statusResStatusCheck) {
      fail(`Wrong res status ${res.status}`);
    }

    const data = res.json();

    const queryResDataCheck = check(
      data,
      {
        "status response: fetch status is present": (d) =>
          d.hasOwnProperty("status"),
      },
      { "data checks": "waiting for finished status" }
    );
    if (!queryResDataCheck) {
      fail(`Wrong 'query' response data: ${JSON.stringify(data)}`);
    }

    console.log(`Current progress is ${data.progress}`);

    if (data.status === "finished") {
      break;
    } else {
      // Result.Status (code in go) indicates there is a bug in status if we first ask for result too early?
      // unclear. Real error is due to pod restart
      sleep(SLEEP_TIME);
      ++attempts;
    }
  }

  const lostCallCheck = check(
    attempts,
    {
      "status response: call must not be stuck in 'working' state": (a) => a != MAX_ATTEMPTS,
    },
    { general: "lost calls" }
  );
  if (!lostCallCheck) {
    fail(`Call is not completed in ${CONSIDER_LOST_AFTER}`);
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
    responseType: "none",
  };

  const dataURL = `${server}/${requestURL}`;
  const res = http.get(dataURL, options);
  const dataResStatusCheck = check(
    res,
    {
      "result response: status must be 200": (r) => r.status === 200,
    },
    { "status checks": "result" }
  );
  if (!dataResStatusCheck) {
    fail(`Wrong 'result' response status: ${res.status}`);
  }
}
