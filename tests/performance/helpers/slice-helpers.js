import exec from "k6/execution";

import { sendRequest, getRandomInt } from "./request-helpers.js";

export function sendSliceRequest(guid, dimension, index) {
  const query = `
    query getSlice{
      cube (id: "${guid}") {
          sliceByIndex(dim: ${dimension}, index: ${index})
      }
    }`;
  console.log(`Requesting slice by index ${index} in dimension ${dimension}`);

  const queryRes = sendRequest(query);
  const promise = queryRes.data.cube.sliceByIndex;
  if (!promise) {
    exec.test.abort("Empty promise returned");
  }
  return promise;
}

export function sendConstantSliceRequest(dimension) {
  const guid = __ENV.GUID;
  return sendSliceRequest(guid, dimension, 0);
}

export function sendRandomSliceRequest(dimension) {
  const guid = __ENV.GUID;
  let limit;
  switch (dimension) {
    case 0:
      limit = __ENV.ILINES;
      break;
    case 1:
      limit = __ENV.XLINES;
      break;
    case 2:
      limit = __ENV.SAMPLES;
      break;
    default:
      throw `Dimension ${dimension} is not in {0, 1, 2}`;
  }
  const index = getRandomInt(limit);
  return sendSliceRequest(guid, dimension, index);
}
