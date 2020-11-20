import msgpack
import numpy as np
import numpy.testing as npt
import requests
import requests_mock

from ..client import client

session = requests.Session()
adapter = requests_mock.Adapter()
session.mount('mock://', adapter)

slice_0_12 = msgpack.packb([
    {
        'shape': [3, 2],
        'tiles': [
            {
                'initial-skip': 0,
                'chunk-size': 2,
                'iterations': 3,
                'substride': 2,
                'superstride': 2,
                "v": [2.00, 2.01, 2.10, 2.11, 2.20, 2.21],
            },
        ],
    },
])

slice_1_22 = msgpack.packb([
    {
        'shape': [4, 2],
        'tiles': [
            {
                'initial-skip': 0,
                'chunk-size': 2,
                'iterations': 3,
                'substride': 2,
                'superstride': 2,
                'v': [0.20, 0.21, 1.20, 1.21, 2.20, 2.21],
            },
            {
                'initial-skip': 6,
                'chunk-size': 2,
                'iterations': 1,
                'substride': 2,
                'superstride': 2,
                'v': [3.20, 3.21],
            },
        ],
    },
])

slice_2_30 = msgpack.packb([
    {
        'shape': [4, 3],
        'tiles': [
            {
                'initial-skip': 0,
                'chunk-size': 3,
                'iterations': 3,
                'substride': 3,
                'superstride': 3,
                'v': [0.00, 0.10, 0.20, 1.00, 1.10, 1.20, 2.00, 2.10, 2.20],
            },
        ],
    },
    {
        'shape': [4, 3],
        'tiles': [
            {
                'initial-skip': 9,
                'chunk-size': 3,
                'iterations': 1,
                'substride': 3,
                'superstride': 3,
                'v': [3.00, 3.10, 3.20],
            },
        ],
    },
])

class no_auth:
    def token(self):
        return {}

client = client('http://api', auth=no_auth())
cube = client.cube('test_id')

@requests_mock.Mocker(kw='m')
def test_shape(**kwargs):
    response = '''{
        "dimensions":[
            {"dimension":0,"location":"query/test_id/slice/0","size":4},
            {"dimension":1,"location":"query/test_id/slice/1","size":3},
            {"dimension":2,"location":"query/test_id/slice/2","size":2}
        ],
        "pid":"pid-test-shape"
    }'''

    kwargs['m'].get('http://api/query/test_id', text = response)
    assert cube.shape == (4, 3, 2)

@requests_mock.Mocker(kw='m')
def test_slice(**kwargs):
    pid_0_12 = '{ "result": "result/pid-0-12", "authorization": "" }'
    pid_1_22 = '{ "result": "result/pid-1-22", "authorization": "" }'
    pid_2_30 = '{ "result": "result/pid-2-30", "authorization": "" }'

    kwargs['m'].get('http://api/query/test_id/slice/0/12', text = pid_0_12)
    kwargs['m'].get('http://api/query/test_id/slice/1/22', text = pid_1_22)
    kwargs['m'].get('http://api/query/test_id/slice/2/30', text = pid_2_30)

    status_0_12 = '{ "location": "result/pid-0-12" }'
    status_1_22 = '{ "location": "result/pid-1-22" }'
    status_2_30 = '{ "location": "result/pid-2-30" }'
    kwargs['m'].get('http://api/result/pid-0-12/status', text = status_0_12)
    kwargs['m'].get('http://api/result/pid-1-22/status', text = status_1_22)
    kwargs['m'].get('http://api/result/pid-2-30/status', text = status_2_30)

    kwargs['m'].get('http://api/result/pid-0-12', content = slice_0_12)
    kwargs['m'].get('http://api/result/pid-1-22', content = slice_1_22)
    kwargs['m'].get('http://api/result/pid-2-30', content = slice_2_30)

    expected_0_12 = np.asarray(
        [
            [2.00, 2.01],
            [2.10, 2.11],
            [2.20, 2.21]
        ]
    )

    expected_1_22 = np.asarray(
        [
            [0.20, 0.21],
            [1.20, 1.21],
            [2.20, 2.21],
            [3.20, 3.21]
        ]
    )

    expected_2_30 = np.asarray(
        [
            [0.00, 0.10, 0.20],
            [1.00, 1.10, 1.20],
            [2.00, 2.10, 2.20],
            [3.00, 3.10, 3.20],
        ]
    )

    npt.assert_array_equal(cube.slice(0, 12), expected_0_12)
    npt.assert_array_equal(cube.slice(1, 22), expected_1_22)
    npt.assert_array_equal(cube.slice(2, 30), expected_2_30)
