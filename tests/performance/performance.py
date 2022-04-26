import os
import subprocess
from data.azure import generate_container_signature, storage_account_name

def runPerformanceTests():
    account_name = storage_account_name(os.getenv("STORAGE_LOCATION"))
    guid = os.environ["GUID"]
    key = os.environ["AZURE_STORAGE_ACCOUNT_KEY"]
    sas = generate_container_signature(account_name=account_name, container_name=guid, account_key=key)
    os.environ["SAS"] = sas

    performance = subprocess.run(["k6", "run", "script.js"], encoding="utf-8", capture_output=True)

    with open("stdout.txt", "w") as text_file:
        text_file.write(performance.stdout)
    with open("stderr.txt", "w") as text_file:
        text_file.write(performance.stderr)

    if performance.returncode:
        performance.check_returncode()

if __name__ == "__main__":
    runPerformanceTests()
