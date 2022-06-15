import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.1/index.js";

const basicThresholds = {
  "checks{status checks:query}": [{ threshold: "rate == 1.00" }],
};

export function thresholds(defaultMed, defaultMax) {
  let medTime = __ENV.MEDTIME;
  medTime = medTime ? medTime : defaultMed
  let maxTime = __ENV.MAXTIME;
  maxTime = maxTime ? maxTime : defaultMax

  // note: if med limit fails, run fails, but threshold shows green
  let thresholds = basicThresholds
  thresholds['iteration_duration'] = [`med < ${medTime}`, `max < ${maxTime}`]
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
