FROM grafana/k6 AS performancetest
RUN apt-get update && apt-get install --no-install-recommends -y \
    python
RUN python -m pip install --upgrade pip

# we need only scan and upload modules in the newest version, so no build needed
COPY ./python /python
RUN python -m pip install -r /python/requirements-dev.txt
ENV UPLOAD_WITH_PYTHON python
ENV PYTHONPATH "${PYTHONPATH}:/python"

COPY ./tests /tests
WORKDIR /tests/performance
