import exec from "k6/execution";

import { sendRequest, getRandomInt } from "./request-helpers.js";

export function sendCurtainRequest(guid, coords) {
  coords = JSON.stringify(coords);
  const query = `
    query getCurtain{
      cube (id: "${guid}") {
          curtainByIndex(coords: ${coords})
      }
    }`;

  console.log(`Requesting curtain ${coords}`);

  const queryRes = sendRequest(query);
  const promise = queryRes.data.cube.curtainByIndex;
  if (!promise) {
    exec.test.abort("Empty promise returned");
  }
  return promise;
}

export function sendConstantCurtainRequest(length) {
  const guid = __ENV.GUID;

  let coords = [];

  for (let i = 0; i < length; i++) {
    coords.push([i, i]);
  }

  return sendCurtainRequest(guid, coords);
}

export function sendRandomCurtainRequest(maxLength) {
  const guid = __ENV.GUID;
  const ilines = __ENV.ILINES;
  const xlines = __ENV.XLINES;

  let coords = [];

  // Fun Fact: length 0 murders server
  const curtainLength = getRandomInt(maxLength - 1) + 1;
  for (let i = 0; i < curtainLength; i++) {
    const ilineIndex = getRandomInt(ilines);
    const xlineIndex = getRandomInt(xlines);
    coords.push([ilineIndex, xlineIndex]);
  }

  return sendCurtainRequest(guid, coords);
}
