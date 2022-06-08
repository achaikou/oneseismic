import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.1/index.js";

export function createSummary(name, data) {
  const logpath = __ENV.LOGPATH;
  if (logpath) {
    const logname = `${logpath}/${name}-summary.json`;
    return {
      stdout: textSummary(data, { indent: " ", enableColors: false }),
      [logname]: JSON.stringify(data),
    };
  } else {
    return {
      stdout: textSummary(data),
    };
  }
}
