# update if change version
ARG PYTHON_VERSION="3.13"
# update if you prefer a different distribution
ARG LINUX_DIST="slim-bookworm"

FROM python:${PYTHON_VERSION}-${LINUX_DIST} AS build
ARG PYTHON_VERSION

WORKDIR /usr/src/app 

# Merge apt-get build
RUN apt-get update && apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      libnetcdf-dev libhdf5-dev \
      build-essential \
      autoconf automake gdb libffi-dev zlib1g-dev libssl-dev git wget \
      python3-dev python3-venv python3-pip \
      python3-h5py python3-h5py-mpi python3-h5py-serial python3-h5sparse \
      libudunits2-dev libeccodes-dev libproj-dev libmagics++-dev \
      unzip && \ 
    rm -rf /var/lib/apt/lists/*

### install CDO
RUN /usr/bin/mkdir cdo
WORKDIR /usr/src/app/cdo
RUN wget https://code.mpimet.mpg.de/attachments/download/29864/cdo-2.5.1.tar.gz && \
    /usr/bin/tar -xvzf cdo-2.5.1.tar.gz
WORKDIR /usr/src/app/cdo/cdo-2.5.1
RUN ./configure --enable-netcdf4  --enable-zlib --with-netcdf=/usr --with-hdf5=/usr/lib/x86_64-linux-gnu/hdf5/serial --with-proj=/usr --with-util-linux-uuid=/usr --with-threads=/usr --with-magics=/usr --with-szlib=/usr/lib --with-udunits2=/usr --with-libxml2=/usr --with-curl=/usr --with-ossp-uuid=/usr --with-dce-uuid=/usr --with-eccodes=/usr  --with-util-linux-uuid=/usr && \
    make clean && \
    make -j 4 && \
    make install


WORKDIR /usr/src/app 
RUN git clone https://github.com/fair-ease/Source.git


# Fetch & unpack PAOLO notebooks
RUN mkdir -p /root/notebooks && \
    wget -O /tmp/source-main.zip https://codeload.github.com/fair-ease/Source/zip/refs/heads/main && \
    unzip /tmp/source-main.zip -d /root && \
    mv /root/Source-main/notebooks/* /root/notebooks/ && \
    rm -rf /tmp/source-main.zip /root/Source-main   

FROM python:${PYTHON_VERSION}-${LINUX_DIST} AS final
ARG PYTHON_VERSION

WORKDIR /usr/src/app 

# Merge apt-get runtime
RUN apt-get update && apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
      libxml2 magics++ libudunits2-0 \
      build-essential \
      autoconf automake gdb libffi-dev zlib1g-dev libssl-dev && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/bin/cdo /usr/local/bin/cdo

WORKDIR /usr/src/app 

# Merge upgrade pip + setuptools + requirements
ADD requirements_jupyter_3-13.txt /usr/src/app
RUN pip install --upgrade pip setuptools && \
    pip install --no-cache-dir -r /usr/src/app/requirements_jupyter_3-13.txt && \
    rm -rf /root/.cache/pip

# Bring notebooks from BUILD stage
COPY --from=build /root/notebooks /root/notebooks     
    
RUN mkdir /usr/local/lib/python${PYTHON_VERSION}/site-packages/SOURCE
COPY --from=build /usr/src/app/Source/SOURCE /usr/local/lib/python${PYTHON_VERSION}/site-packages/SOURCE

#CMD [ "/bin/bash" ]
#ENTRYPOINT ["/usr/local/bin/jupyter-lab", "-ServerApp.max_buffer_size=4294967296", "--notebook-dir=/usr/src/app/", "--ip='*'", "--port=8888", "--no-browser", "--allow-root"]
