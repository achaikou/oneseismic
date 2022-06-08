import { sleep } from "k6";

import {
  waitForOperationFinished,
  retrieveResult,
  basicThresholds,
} from "./helpers/request-helpers.js";
import { sendRandomCurtainRequest } from "./helpers/curtain-helpers.js";
import { createSummary } from "./helpers/report-helpers.js";

export const options = {
  scenarios: {
    curtain: {
      executor: "constant-vus",
      vus: 10,
      duration: "1m",
      exec: "randomCurtainRequest",
    },
  },
  thresholds: basicThresholds,
};

function request(promise) {
  waitForOperationFinished(promise);
  retrieveResult(promise);
  sleep(0.1);
}

export function randomCurtainRequest() {
  request(sendRandomCurtainRequest(20));
}

export function handleSummary(data) {
  return createSummary("simple", data);
}

// it might also good to have some files with missing lines
