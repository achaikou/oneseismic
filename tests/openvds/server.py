from flask import Flask, json
import openvds
from flask import request
import json
from urllib.parse import urlsplit
import os

api = Flask(__name__)

def get_slice2(sliceType,sliceIndex,url,sas):
    connection ="Suffix="+sas
    vds = openvds.open(url, connection)
    layout = openvds.getLayout(vds)
    accessManager = openvds.VolumeDataAccessManager(vds)
    sliceDimension = 2 if sliceType == 'inline' else 1 if sliceType == 'crossline' else 0 if sliceType == 'timeslice' else 0 if sliceType == 'depthslice' else -1

    min = tuple(sliceIndex + 0 if dim == sliceDimension else 0 for dim in range(6))
    
    max = tuple(sliceIndex + 1 if dim == sliceDimension else layout.getDimensionNumSamples(dim) for dim in range(6))
    req = accessManager.requestVolumeSubset(min, max,lod=0)
    height = max[0] if sliceDimension != 0 else max[1]
    width  = max[2] if sliceDimension != 2 else max[1]
    if req.data is None:
        data = None
    else:
        data = req.data.reshape(width, height).transpose()
    openvds.close(vds)
    return data

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
    sas = request.args.get('sas')
    guid = request.args.get('guid')
    index = int(request.args.get('index'))
    type = request.args.get('type')

    account_name = storage_account_name(os.environ["STORAGE_URL"])

    url = "azureSAS://{}.blob.core.windows.net/{}".format(account_name, guid)
    
    data = get_slice2(type, index, url, sas)
    return json.dumps(data.tolist())
if __name__ == '__main__':
    api.run(host="0.0.0.0", port=int("5000"), debug=True)