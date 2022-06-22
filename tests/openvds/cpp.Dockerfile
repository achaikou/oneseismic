FROM ubuntu:20.04 as builder

ENV DEBIAN_FRONTEND="noninteractive"
RUN apt-get update
RUN apt-get install -y build-essential  git curl  libboost-dev  libcurl4-openssl-dev libuv1-dev libboost-all-dev  libxml2-dev libfmt-dev libssl-dev uuid-dev libpng-dev 

RUN curl -OL https://github.com/Kitware/CMake/releases/download/v3.22.0/cmake-3.22.0-linux-x86_64.tar.gz
RUN tar xzvf cmake-3.22.0-linux-x86_64.tar.gz -C /opt
RUN ln -s /opt/cmake-3.22.0-linux-x86_64/bin/* /usr/bin/

RUN mkdir /install
WORKDIR /install


COPY ./tests/openvds/patches /tests/openvds/patches


RUN git clone https://community.opengroup.org/osdu/platform/domain-data-mgmt-services/seismic/open-vds.git

WORKDIR /install/open-vds
RUN git apply /tests/openvds/patches/0001-Add-missing-Close-method-to-IOManagerAzureSdkForCpp.patch
RUN git apply /tests/openvds/patches/0001-Append-azure-sdk-for-cpp-so-s-to-correct-list.patch

RUN mkdir /install/build
WORKDIR /install/build

ENV OPENVDS_AZURESDKFORCPP 1
RUN cmake -DCMAKE_BUILD_TYPE=Release -DDISABLE_AZURESDKFORCPP_IOMANAGER=OFF -DDISABLE_AWS_IOMANAGER=ON -DDISABLE_GCP_IOMANAGER=ON -DBUILD_PYTHON=OFF -DBUILD_JAVA=OFF -DBUILD_DOCS=OFF -DBUILD_TESTS=OFF -DBUILD_EXAMPLES=OFF ../open-vds
RUN make install


COPY ./tests/openvds /tests/openvds
COPY ./tests/data /tests/data



RUN mkdir /tests/openvds/build
WORKDIR /tests/openvds/build

RUN cmake  -DCMAKE_PREFIX_PATH=/install/open-vds/Dist/OpenVDS/ ..
RUN make -j8 -d cppserver

RUN ls /install/open-vds/Dist/OpenVDS/lib






ENV version 0.38.0
RUN mkdir k6
RUN curl \
    -L https://github.com/grafana/k6/releases/download/v$version/k6-v$version-linux-amd64.tar.gz \
    -o k6-$version.tar.gz
RUN tar xf k6-$version.tar.gz -C k6 --strip-components=1

ENV PATH "$PATH:k6"


RUN apt-get install -y python3-pip
RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install -r /tests/openvds/requirements-dev.txt
#ENV UPLOAD_WITH_PYTHON python
ENV PYTHONPATH "${PYTHONPATH}:/tests"
