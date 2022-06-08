import { sleep } from "k6";

import {
  waitForOperationFinished,
  retrieveResult,
  basicThresholds,
} from "./helpers/request-helpers.js";
import { sendConstantSliceRequest } from "./helpers/slice-helpers.js";
import { createSummary } from "./helpers/report-helpers.js";

export const options = {
  scenarios: {
    constantSlice: {
      executor: "constant-vus",
      vus: 5,
      duration: "30s",
    },
  },

  thresholds: basicThresholds,
};

export default function () {
  const promise = sendConstantSliceRequest(0);
  waitForOperationFinished(promise);
  retrieveResult(promise);
  sleep(0.1);
}

export function handleSummary(data) {
  return createSummary("constant-slice", data);
}
