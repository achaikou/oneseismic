import { sendRandomSliceRequest } from "./helpers/slice-helpers.js";
import { createSummary, thresholds } from "./helpers/report-helpers.js";

export const options = {
  scenarios: {
    ilineSlice: {
      exec: "randomIlineSliceRequest",
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 3 },
        { duration: '5m', target: 3 },
      ],
    },

    xlineSlice: {
      exec: "randomXlineSliceRequest",
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '50s', target: 3 },
        { duration: '5m', target: 3 },
      ],
      startTime: '10s',
    },

    timeSlice: {
      exec: "randomTimeSliceRequest",
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 3 },
        { duration: '5m', target: 3 },
      ],
      startTime: '30s',
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
