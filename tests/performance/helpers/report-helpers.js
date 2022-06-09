import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.1/index.js";

const basicThresholds = {
  "checks{status checks:query}": [{ threshold: "rate == 1.00" }],
  "checks{status checks:waiting for finished status}": [{ threshold: "rate == 1.00" }],
  "checks{status checks:result}": [{ threshold: "rate == 1.00" }],
  "checks{data checks:query}": [{ threshold: "rate == 1.00" }],
  "checks{data checks:waiting for finished status}": [{ threshold: "rate == 1.00" }],
  "checks{general:lost calls}": [{ threshold: "rate == 1.00" }],
};

export function thresholds(med, max) {
  let thresholds = basicThresholds
  thresholds['iteration_duration'] = [`med < ${med}`, `max < ${max}`]
  return thresholds
}

export function createSummary(data) {
  const logpath = __ENV.LOGPATH;
  if (logpath) {
    const logname = `${logpath}/summary.json`;
    return {
      stdout: textSummary(data, { indent: " ", enableColors: false }),
      [logname]: JSON.stringify(data),
    };
  } else {
    return {
      stdout: textSummary(data, { indent: " "}),
    };
  }
}
