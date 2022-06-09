import { runRequest } from "./helpers/request-helpers.js";
import { sendRandomSliceRequest } from "./helpers/slice-helpers.js";
import { sendRandomCurtainRequest } from "./helpers/curtain-helpers.js";
import { createSummary, thresholds } from "./helpers/report-helpers.js";

export const options = {
  scenarios: {
    ilineSlice: {
      executor: "constant-vus",
      vus: 3,
      duration: "1m",
      exec: "randomIlineSliceRequest",
    },

    xlineSlice: {
      executor: "constant-vus",
      vus: 3,
      duration: "1m",
      exec: "randomXlineSliceRequest",
    },

    timeSlice: {
      executor: "constant-vus",
      vus: 3,
      duration: "1m",
      exec: "randomTimeSliceRequest",
    },

    curtain: {
      executor: "constant-vus",
      vus: 1,
      duration: "1m",
      exec: "randomCurtainRequest",
    },
  },

  thresholds: thresholds(5000, 15000),
};

export function randomIlineSliceRequest() {
  runRequest(() => sendRandomSliceRequest(0));
}

export function randomXlineSliceRequest() {
  runRequest(() => sendRandomSliceRequest(1));
}

export function randomTimeSliceRequest() {
  runRequest(() => sendRandomSliceRequest(2));
}

export function randomCurtainRequest() {
  runRequest(() => sendRandomCurtainRequest(5));
}

export function handleSummary(data) {
  return createSummary(data);
}
