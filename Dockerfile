# update if change version
ARG PYTHON_VERSION="3.13"
# update if you prefer a different distribution
ARG LINUX_DIST="slim-bookworm"

FROM python:${PYTHON_VERSION}-${LINUX_DIST} AS build
ARG PYTHON_VERSION

WORKDIR /usr/src/app 

RUN apt-get update
RUN apt-get upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libnetcdf-dev libhdf5-dev 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y autoconf automake gdb libffi-dev zlib1g-dev libssl-dev git wget
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python3-dev python3-venv python3-pip
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python3-h5py python3-h5py-mpi python3-h5py-serial python3-h5sparse 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libudunits2-dev libeccodes-dev libproj-dev libmagics++-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git wget

### install CDO
RUN /usr/bin/mkdir cdo
WORKDIR /usr/src/app/cdo
RUN wget https://code.mpimet.mpg.de/attachments/download/29864/cdo-2.5.1.tar.gz
RUN /usr/bin/tar -xvzf cdo-2.5.1.tar.gz
WORKDIR /usr/src/app/cdo/cdo-2.5.1
RUN ./configure --enable-netcdf4  --enable-zlib --with-netcdf=/usr --with-hdf5=/usr/lib/x86_64-linux-gnu/hdf5/serial --with-proj=/usr --with-util-linux-uuid=/usr --with-threads=/usr --with-magics=/usr --with-szlib=/usr/lib --with-udunits2=/usr --with-libxml2=/usr --with-curl=/usr --with-ossp-uuid=/usr --with-dce-uuid=/usr --with-eccodes=/usr  --with-util-linux-uuid=/usr

RUN make clean;
RUN make -j 4
RUN make install
###

WORKDIR /usr/src/app 

RUN git clone https://github.com/fair-ease/Source.git


FROM python:${PYTHON_VERSION}-${LINUX_DIST} AS final
ARG PYTHON_VERSION

WORKDIR /usr/src/app 

RUN apt-get update
RUN apt-get upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libxml2 magics++ libudunits2-0 
#RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libblosc-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y autoconf automake gdb libffi-dev zlib1g-dev libssl-dev

COPY --from=build /usr/local/bin/cdo /usr/local/bin/cdo

WORKDIR /usr/src/app 

RUN pip install --upgrade pip
RUN pip install --upgrade setuptools
ADD requirements_jupyter_3-13.txt /usr/src/app
#ADD docker/constraints.txt /usr/src/app
#RUN pip install -r requirements_jupyter.txt -c constraints.txt
RUN pip install -r requirements_jupyter_3-13.txt 

# Download and extract notebooks directly
ADD https://github.com/fair-ease/Source/archive/refs/heads/PAOLO.zip /tmp/PAOLO.zip
RUN apt-get update && apt-get install -y unzip && \
    unzip /tmp/PAOLO.zip -d /root && \
    mv /root/Source-PAOLO/notebooks /root/notebooks && \
    rm -rf /tmp/PAOLO.zip /root/Source-PAOLO

RUN mkdir /usr/local/lib/python${PYTHON_VERSION}/site-packages/SOURCE
#ADD SOURCE /usr/local/lib/python${PYTHON_VERSION}/site-packages/SOURCE
COPY --from=build /usr/src/app/Source/SOURCE /usr/local/lib/python${PYTHON_VERSION}/site-packages/SOURCE


#CMD [ "/bin/bash" ]
#ENTRYPOINT ["/usr/local/bin/jupyter-lab", "-ServerApp.max_buffer_size=4294967296", "--notebook-dir=/usr/src/app/", "--ip='*'", "--port=8888", "--no-browser", "--allow-root"]
#ENTRYPOINT ["/usr/local/bin/jupyter-lab", "-ServerApp.max_buffer_size=4294967296", "--notebook-dir=/usr/src/app/", "--ip='*'", "--port=8888", "--no-browser", "--allow-root", "-Application.log_level='DEBUG'", "-JupyterApp.log_level='DEBUG'", "-NotebookApp.log_level='DEBUG'", "-Session.debug=True"]
