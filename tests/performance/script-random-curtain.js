import { runRequest } from "./helpers/request-helpers.js";
import { sendRandomCurtainRequest } from "./helpers/curtain-helpers.js";
import { createSummary, thresholds } from "./helpers/report-helpers.js";

export const options = {
  scenarios: {
    curtain: {
      executor: "constant-vus",
      vus: 10,
      duration: "1m",
      exec: "randomCurtainRequest",
    },
  },
  thresholds: thresholds(1500, 3000),
};

export function randomCurtainRequest() {
  runRequest(() => sendRandomCurtainRequest(20));
}

export function handleSummary(data) {
  return createSummary(data);
}
