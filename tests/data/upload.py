import subprocess
import json
import tempfile

def scan(scan_with_python, path):
    scan = subprocess.run([scan_with_python, "-m", "oneseismic",
                          "scan", path], encoding="utf-8", capture_output=True,
                          check=True)
    return json.loads(scan.stdout)


def upload(upload_with_python, path, storage_location, scan_meta=None):
    if not scan_meta:
        scan_meta = scan(upload_with_python, path)
    scan_insights = tempfile.mktemp('scan_insights.json')
    with open(scan_insights, "w") as f:
        f.write(json.dumps(scan_meta))

    res = subprocess.run([upload_with_python, "-m", "oneseismic", "upload",
                   scan_insights, path, storage_location], encoding="utf-8",
                   capture_output=True, check=False)
    if res.returncode:
        print(res.stderr)
        print(res.stdout)
    res.check_returncode()

    return scan_meta["guid"]
