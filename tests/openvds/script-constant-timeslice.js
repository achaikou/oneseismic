import { sendConstantSliceRequest } from "./helpers/slice-helpers.js";
import { createSummary, thresholds } from "./helpers/report-helpers.js";

export const options = {
  scenarios: {
    constantSlice: {
      executor: "constant-vus",
      vus: 1,
      duration: "1m",
    },
  },
  thresholds: thresholds(4000, 15000),
};

export default function () {
  sendConstantSliceRequest("timeslice");
}

export function handleSummary(data) {
  return createSummary(data);
}
