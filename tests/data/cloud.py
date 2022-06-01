import sys
from azure.storage import blob
import datetime
from urllib.parse import urlsplit
import os
import datetime

from data.upload import *
from data.create import create_dimensional

def generate_account_signature(
    account_name,
    account_key,
    resource_types=None,
    permission=None,
    expiry=None,
):
    """
    Create account signature for azure request
    """
    if not expiry:
        # Token should be valid for all the time it takes to upload data
        expiry = datetime.datetime.utcnow() + datetime.timedelta(hours=5)
    if not permission:
        permission = blob.AccountSasPermissions(
            read=True, write=True, list=True)
    if not resource_types:
        resource_types = blob.ResourceTypes(container=True, object=True)

    return blob.generate_account_sas(
        account_name=account_name,
        account_key=account_key,
        resource_types=resource_types,
        permission=permission,
        expiry=expiry)


def generate_container_signature(
    account_name,
    container_name,
    account_key,
    permission=None,
    expiry=None,
):
    """
    Create container signature for azure request
    """
    if not expiry:
        expiry = datetime.datetime.utcnow() + datetime.timedelta(seconds=300)
    if not permission:
        permission = blob.ContainerSasPermissions(
            read=True, list=True)

    return blob.generate_container_sas(
        account_name=account_name,
        container_name=container_name,
        account_key=account_key,
        permission=permission,
        expiry=expiry)


def storage_account_name(storage_url):
    """
    Retrieve account name from storage url
    """
    return urlsplit(storage_url).netloc.split('.')[0]


def upload_container(upload_with_python, filepath, storage_url, storage_account_key, scan_meta=None):
    """
    Upload file to storage url
    """
    upload_token = generate_account_signature(storage_account_name(storage_url), storage_account_key)
    storage_location = storage_url + "?" +upload_token
    return upload(upload_with_python, filepath, storage_location=storage_location, scan_meta=scan_meta)


def delete_container(guid, storage_url, storage_account_key):
    token = generate_account_signature(storage_account_name(storage_url), storage_account_key, permission=blob.AccountSasPermissions(delete=True))
    container_client = blob.ContainerClient(
        storage_url, guid, token)
    container_client.delete_container()


if __name__ == "__main__":
    """
    Simple helper for test. Args for each function to be interfered from code
    """
    if len(sys.argv) < 1:
        raise ValueError("Expected function name")
    function = sys.argv[1]
    if function == "upload_container":
        upload_with_python = os.getenv("UPLOAD_WITH_PYTHON")
        storage_account_key = os.getenv("AZURE_STORAGE_ACCOUNT_KEY")
        storage_url = os.getenv("STORAGE_LOCATION")
        #filepath = os.getenv("FILE_PATH")
        filepath = sys.argv[2]
        before = datetime.datetime.now()
        guid = upload_container(upload_with_python, filepath, storage_url, storage_account_key)
        after = datetime.datetime.now()
        print(guid)
        print(before)
        print(after)
    elif function == "delete_container":
        storage_account_key = os.getenv("AZURE_STORAGE_ACCOUNT_KEY")
        storage_url = os.getenv("STORAGE_LOCATION")
        guid = sys.argv[2]
        print(datetime.datetime.now())
        delete_container(guid, storage_url, storage_account_key)
        print(datetime.datetime.now())
    elif function == "full":
        upload_with_python = os.getenv("UPLOAD_WITH_PYTHON")
        storage_account_key = os.getenv("AZURE_STORAGE_ACCOUNT_KEY")
        storage_url = os.getenv("STORAGE_LOCATION")
        filepath = sys.argv[2]
        ilines = sys.argv[3]
        xlines = sys.argv[4]
        samples = sys.argv[5]

        print(datetime.datetime.now())
        create_dimensional(filepath, ilines, xlines, samples)
        print(datetime.datetime.now())

        before = datetime.datetime.now()
        guid = upload_container(upload_with_python, filepath, storage_url, storage_account_key)
        after = datetime.datetime.now()

        print(guid)
        print(before)
        print(after)
    else:
        raise ValueError("Unknown function")
