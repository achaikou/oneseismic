import {  sendRandomSliceRequest } from "./helpers/slice-helpers.js";
import { createSummary, thresholds } from "./helpers/report-helpers.js";

export const options = {
  scenarios: {
    constantSlice: {
      executor: "constant-vus",
      vus: 1,
      duration: "3m",
    },
  },
  thresholds: thresholds(3000, 12000),
};

export default function () {
  sendRandomSliceRequest("inline");
}

export function handleSummary(data) {
  return createSummary(data);
}
