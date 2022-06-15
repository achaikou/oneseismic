import { runRequest } from "./helpers/request-helpers.js";
import { sendRandomSliceRequest } from "./helpers/slice-helpers.js";
import { createSummary, thresholds } from "./helpers/report-helpers.js";

export const options = {
  scenarios: {
    ilineSlice: {
      executor: "constant-vus",
      vus: 3,
      duration: "5m",
      exec: "randomIlineSliceRequest",
    },

    xlineSlice: {
      executor: "constant-vus",
      vus: 3,
      duration: "5m",
      exec: "randomXlineSliceRequest",
    },

    timeSlice: {
      executor: "constant-vus",
      vus: 3,
      duration: "5m",
      exec: "randomTimeSliceRequest",
    },
  },

  thresholds: thresholds(30000, 60000),
};

export function randomIlineSliceRequest() {
  sendRandomSliceRequest("inline");
}

export function randomXlineSliceRequest() {
  sendRandomSliceRequest("crossline");
}

export function randomTimeSliceRequest() {
  sendRandomSliceRequest("timeslice");
}

export function handleSummary(data) {
  return createSummary(data);
}
