#!/bin/bash

# !!! OBS you need to make sure you git clone manually, it seems that command
# stalls when running on Beskow compute nodes?

if [ $# -eq 0 ]
  then
    export L=/cfs/klemming/projects/snic/snic2021-5-492/$USER/local/$SNIC_RESOURCE
    echo "No argument. Using path: $L"
else
    export L="$1"
    echo "Using path: $L"
fi


# THIS LINE SHOULD BE UNCOMMENTED... DONT FORGET 2021-05-27
./Miniconda_install.sh

source activate_miniconda.sh $L
conda activate

module load snic-env
module load PDC

# --- I have tried with the gnu compiler, and also with the cray compiler

# 2021-12-10 -- Temp comment out, testin CRAY compiler
module swap PrgEnv-cray PrgEnv-gnu
module unload cray-libsci atp

export CRAYPE_LINK_TYPE=dynamic
export CRAY_ROOTFS=DSL

# # module load craype-ivybridge

echo "This assumes you have already installed miniconda3 on Tegner"
echo ""
echo "https://github.com/Hjorthmedh/Snudda/wiki/D.-Setting-up-Tegner-@%C2%A0KTH"
echo ""

# If you are low on disk space in your home folder you can instead use
# $SNIC_TMP/$SNIC_RESOURCE in the export L line below.
# e.g: export L=$SNIC_TMP/$SNIC_RESOURCE

# export L=/cfs/klemming/home/${USER:0:1}/$USER/local/$SNIC_RESOURCE
# export L=/cfs/klemming/projects/snic/snic2021-5-492/$USER/local/$SNIC_RESOURCE

export LM=$L/miniconda3
export LN=$L/neuron

#Dirty fix for NEURON compilation to work, thanks Tor Kjellson for help
export TMP0_DIR=$L/cray_libs

mkdir -pv $L

mkdir -pv $TMP0_DIR
pushd $TMP0_DIR
ln -s /lib64/libncurses.so.6 libncurses.so
ln -s /lib64/libtinfo.so.6 libtinfo.so
ln -s /lib64/libreadline.so.7 libreadline.so
ln -s $LM/lib/libpython3.10.so .
popd

# export CXX=CC
# export CC=cc
# export FC=ftn
# export MPICC=cc
# export MPICXX=CC



# neuron is also installed from requirements.txt, remove non-compatible version
pip uninstall neuron -y

# Is MINIC used?
export MINIC=$LM

export PATH=$LM/bin:$LN/bin:$PATH
# export LD_LIBRARY_PATH=$LN/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$TMP0_DIR:$MPICH_DIR/lib:$LD_LIBRARY_PATH
export PYTHONPATH=$L/lib/python3.8/site-packages:$PYTHONPATH
export PYTHONPATH=$LN/lib/python:$LM/lib/python3.8/

export NRN_INSTALL_LOC=$LN

export CXX=CC
export CC=cc
export FC=ftn
export MPICC=cc
export MPICXX=CC

# This version number might need to update in the future
module load cmake/3.22.3


# We need to recompile mpi4py to use mpich libraries of beskow
# UPDATE: This is now done in Miniconda_install.sh
# pip install mpi4py --ignore-installed

# Från MDJs gamla buildscript
# export CFLAGS="-dynamic -O3 -funroll-loops -march=corei7-avx -mavx  -ffast-math -DCACHEVEC=1" 

# Maybe git clone does not work on compute nodes?

# rm -rf $L/build
# mkdir -pv $L/build
pushd $L

  # build parallel neuron with python interface
  # mkdir neuron
  # pushd neuron
  # OLD: git clone -q https://github.com/nrnhines/nrn

  # You have to do git clone manually!!
  git clone https://github.com/neuronsimulator/nrn -b 8.2.2
  
  cd nrn
  rm -r build
  mkdir build
  cd build

  echo "About to run"
  echo `which cmake`
#   cmake .. \
#   	  -DCMAKE_BUILD_TYPE:STRING=Debug \
#	  -DNRN_ENABLE_INTERVIEWS=OFF \
#	  -DNRN_ENABLE_PYTHON=ON \
#	  -DNRN_ENABLE_MPI=ON \
#	  -DNRN_ENABLE_RX3D=OFF \
#	  -DCMAKE_INSTALL_PREFIX=$LN \
#	  -DNRN_ENABLE_BINARY_SPECIAL=ON \
#	  -DPYTHON_EXECUTABLE=`which python3` \
#	  -DCMAKE_C_COMPILER:FILEPATH=cc \
#	  -DCMAKE_CXX_COMPILER:FILEPATH=CC \

#          -DCMAKE_C_FLAGS="-DDEBUG -g" \
#          -DCMAKE_CXX_FLAGS="-DDEBUG -g" \
#	  -DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo \
	  # -DCMAKE_C_FLAGS="-mavx2" \
          # -DCMAKE_CXX_FLAGS="-mavx2" \
	  #	  -DNRN_ENABLE_CORENEURON=ON \

	  #-DCMAKE_BUILD_TYPE=Debug \
	  
  cmake .. \
	-DCMAKE_SKIP_RPATH:BOOL=YES \
	-DNRN_ENABLE_INTERVIEWS=OFF \
	-DNRN_ENABLE_PYTHON=ON \
	-DNRN_ENABLE_MPI=ON \
	-DNRN_ENABLE_RX3D=OFF \
	-DCMAKE_INSTALL_PREFIX=$NRN_INSTALL_LOC \
	-DNRN_ENABLE_BINARY_SPECIAL=ON \
	-DNRN_ENABLE_CORENEURON=OFF \
	-DCMAKE_BUILD_TYPE:STRING=Release \
	-DREADLINE_LIBRARY:FILEPATH=$TMP0_DIR/libreadline.so \
	-DCURSES_EXTRA_LIBRARY:FILEPATH=$TMP0_DIR/libtinfo.so \
	-DCURSES_CURSES_LIBRARY:FILEPATH=$TMP0_DIR/libncurses.so \
	-DCURSES_NCURSES_LIBRARY:FILEPATH=$TMP0_DIR/libncurses.so \
	-DCURSES_INCLUDE_PATH:PATH=/usr/include/curses/
  
  cmake --build . \
	--parallel 1 \
	--target install 1>$L/build_log_Release.txt 2>$L/build_error_Release.txt

CC --version
    
#    ./build.sh
#    autoreconf --force --install
#    ./configure --prefix=$LM --exec-prefix=$LM \
#      --with-mpi --with-nrnpython --with-paranrn \
#      --without-x \
#      --without-memacs --without-readline --disable-shared --without-nmodl \
#      linux_nrnmech=no always_call_mpi_init=yes java_dlopen=no \
#      --host=x86_64-unknown-linux-gnu --disable-pysetup --without-iv \
#      CC=cc CXX=CC MPICC=cc MPICXX=CC CFLAGS="$CFLAGS" CXXFLAGS="$CFLAGS" \
#      # -LLIBDIR
#
#    echo "About to run"
#    echo `which make`
#	  
#    # make -j   # -j parallel compilation
#    make -j
#    make install
#
#    pushd src/nrnpython
#      python setup.py install
#    popd
    # rm -r $L/nrn/share/{demo,examples}
  popd

  # install pypandoc
  # pip install pypandoc --install-option="--prefix=$L"
  # pip install pypandoc --prefix=$L
  pip install pypandoc --no-cache-dir

  # install ipyparallel
  # pip install ipyparallel --install-option="--prefix=$L"
  # pip install ipyparallel --prefix=$L
  pip install ipyparallel --no-cache-dir

  # install bluepyopt
  # pip install bluepyopt --install-option="--prefix=$L"
  # pip install bluepyopt --prefix=$L
  pip install bluepyopt --no-cache-dir

  pip install mpi4py --no-cache-dir

# popd
# rm -rf $L/build


  # Some dirty fixes...
  # På rad 32 har du
  # LDFLAGS = $(LINKFLAGS) $(UserLDFLAGS) ....
  # /path-to-miniconda/dardel/miniconda3/lib
  # radera den sista sökvägen - annars får du problem när nrnivmodl körs.
  
  mv $L/neuron/bin/nrnmech_makefile $L/neuron/bin/nrnmech_makefile.original
  python3 purge_ldflags.py $L/neuron/bin/nrnmech_makefile.original > $L/neuron/bin/nrnmech_makefile
  chmod u+x $L/neuron/bin/nrnmech_makefile

  

conda deactivate
