import http from "k6/http";
import { check, fail, sleep } from "k6";

export function getRandomInt(max) {
  return Math.floor(Math.random() * max);
}


export function sendRequest(kind, dimension, index) {
  const guid = __ENV.GUID;
  const container= __ENV.CONTAINER;
  const path = encodeURIComponent(`${container}/${guid}`)
  const server = __ENV.SERVER_URL;
  const auth = encodeURIComponent(__ENV.SAS);

  const queryUrl = `${server}/${kind}?type=${dimension}&index=${index}&guid=${path}&sas=${auth}`;
  console.log(`Requesting slice by index ${index} in dimension ${dimension}`);
  const options = {
    responseType: "none",
  };
  const res = http.get(queryUrl, options);

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
  sleep(0.1);
}

