import { sendRequest, getRandomInt } from "./request-helpers.js";


export function sendConstantSliceRequest(dimension) {
  return sendRequest("slice", dimension, 0);
}

export function sendRandomSliceRequest(dimension) {
  let limit;
  switch (dimension) {
    case "inline":
      limit = __ENV.ILINES;
      break;
    case "crossline":
      limit = __ENV.XLINES;
      break;
    case "timeslice":
      limit = __ENV.SAMPLES;
      break;
    default:
      throw `Dimension ${dimension} is not in {0, 1, 2}`;
  }
  const index = getRandomInt(limit);
  return sendRequest("slice", dimension, index);
}
