FROM apache/spark-py@sha256:bec1fed7818dd775c8a88224d5b2550c9a85ff81860f76b44e5357abdd849bb5

USER root
COPY requirements.txt /tmp/requirements.txt
RUN grep -v '^pyspark==' /tmp/requirements.txt > /tmp/docker-requirements.txt \
    && python3 -m pip install --no-cache-dir -r /tmp/docker-requirements.txt

WORKDIR /app
ENV PYTHONPATH=/app/src
ENV MPLCONFIGDIR=/tmp/matplotlib

USER root
