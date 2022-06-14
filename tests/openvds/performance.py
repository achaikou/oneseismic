import os
import sys
import subprocess
from data.cloud import generate_container_signature, storage_account_name

def runPerformanceTests(filepath):
    account_name = storage_account_name(os.getenv("STORAGE_LOCATION"))
    container= os.environ["CONTAINER"]
    key = os.environ["AZURE_STORAGE_ACCOUNT_KEY"]
    sas = generate_container_signature(account_name=account_name, container_name=container, account_key=key)
    os.environ["SAS"] = sas
    logpath = os.environ["LOGPATH"]
    logname = "{}/loadtest.log".format(logpath)
    stdoutname = "{}/stdout.txt".format(logpath)
    stderrname = "{}/stderr.txt".format(logpath)

    print("running")

    # "--env scenario=contacts, "
    #performance = subprocess.run(["k6", "run", "/tests/performance/script.js", "--vus", vus, "--duration", duration], encoding="utf-8", capture_output=True)
    performance = subprocess.run(["k6", "run", "--console-output", logname, filepath], encoding="utf-8", capture_output=True)

    with open(stdoutname, "w") as text_file:
        text_file.write(performance.stdout)
    with open(stderrname, "w") as text_file:
        text_file.write(performance.stderr)

    if performance.returncode:
        performance.check_returncode()

if __name__ == "__main__":
    #vus = sys.argv[1]
    #duration = sys.argv[2]
    filepath = sys.argv[1]
    runPerformanceTests(filepath)
