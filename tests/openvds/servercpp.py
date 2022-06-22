from flask import Flask, json
import openvds
from flask import request
import json
from urllib.parse import urlsplit
import os
import sys
import logging

api = Flask(__name__)

def storage_account_name(storage_url):
    """
    Retrieve account name from storage url
    """
    return urlsplit(storage_url).netloc.split('.')[0]

@api.route('/', methods=['GET'])
def get_root():
    return "I am alive!"

@api.route('/slice', methods=['GET'])
def get_slice():
    api.logger.info('slice received logger')
    print("slice received print", file=sys.stderr, flush=True)
    sas = request.args.get('sas')
    guid = request.args.get('guid')
    index = int(request.args.get('index'))
    type = request.args.get('type')

    account_name = storage_account_name(os.environ["STORAGE_URL"])

    url = "azureSAS://{}.blob.core.windows.net/{}".format(account_name, guid)
    connection_string="suffix={}".format(sas)

    if type == "inline":
        dimension = 0
    elif type == "crossline":
        dimension = 1
    elif type == "timeslice":
        dimension = 2

    os.environ["URL"] = url
    os.environ["CONNECTION_STRING"] = connection_string
    os.environ["DIMENSION"] = dimension
    os.environ["INDEX"] = index
    
    data = get_slice2(type, index, url, sas)
    api.logger.info('jsonize')
    print("So it's not fond of json?", file=sys.stderr, flush=True)
    return json.dumps(data.tolist())
if __name__ == '__main__':
    from waitress import serve
    serve(api, host="0.0.0.0", port=5000)
    #api.run(host="0.0.0.0", port=int("5000"), debug=True)