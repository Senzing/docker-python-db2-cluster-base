FROM centos:7

ENV REFRESHED_AT=2018-11-04

# Install prerequisites.

RUN yum -y update; yum clean all
RUN yum -y install epel-release; yum clean all
RUN yum -y install \
    gcc-c++ \
    ksh \
    libstdc++ \
    mysql-connector-odbc \
    pam \
    python-devel \
    python-pip \
    unixODBC \
    unixODBC-devel \
    unzip \
    wget; \
    yum clean all

RUN pip install \
    psutil \
    pyodbc

# Copy the DB2 ODBC client code.
# The tar.gz file must be independently downloaded before the docker build.

ADD ./downloads/ibm_data_server_driver_for_odbc_cli_linuxx64_v11.1.tar.gz /opt/IBM/db2

# Copy files from repository.

COPY ./root /

# Environment variables.

ENV SENZING_ROOT=/opt/senzing
ENV PYTHONPATH=${SENZING_ROOT}/g2/python
ENV LD_LIBRARY_PATH=${SENZING_ROOT}/g2/lib:/opt/IBM/db2/clidriver/lib
ENV DB2_CLI_DRIVER_INSTALL_PATH=/opt/IBM/db2/clidriver
ENV PATH=$PATH:/opt/IBM/db2/clidriver/adm:/opt/IBM/db2/clidriver/bin

# Run-time command.

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["python"]
