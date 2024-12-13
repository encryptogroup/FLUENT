# FLUENT: A Framework for Efficient Mixed-Protocol Semi-Private Function Evaluation

This repository contains the code for our paper. Our framework consists of 4 components:

- ABY[0] (`aby/`): We use ABY for evaluating SPFE circuits. We include some modifications adding support for mixed-protocol SPFE circuits
- XLS[1] (`xls/`): We include an extended version of XLS supporting SPFE-specific constructs
- SPFE compiler (our work, `spfe/`): This is the main program which compiles C/C++ or Verilog to a SPFE file
- UC compiler[2] (included in SPFE compiler, `spfe/uc/`): The UC compiler is the reference implementation to the corresponding paper, which is open-source.

## Instructions

### Step 1: Compiling circuits

<a target="_blank" href="https://colab.research.google.com/github/encryptogroup/FLUENT/blob/main/fluent.ipynb">
  <img src="https://colab.research.google.com/assets/colab-badge.svg" alt="Open In Colab"/>
</a>

We provide a Jupyter notebook `fluent.ipynb` for easy testing of our
circuit compilation workflow. This notebook can be conveniently
executed in [Google Colab](https://colab.research.google.com).

The Jupyter notebook uses pre-built binaries in order to speed up
compilation. Information on reproducing these binaries is available in
the Appendix.

You can also run the notebook in a Docker container locally:

```bash
DOCKER_IMAGE=$(docker build . -q -f Dockerfile.notebook)
docker run --rm -p 8889:8888 -v "$(pwd):/home/jovyan/work" $DOCKER_IMAGE start-notebook.py --NotebookApp.token='my-token'
```

Then head to http://localhost:8889. The notebook also works on
Ubuntu-like host systems, but be aware that it installs various
dependencies such as Yosys[6].

### Step 2: Executing compiled circuits in multi-party settings

First, we compile the multi-party computation framework ABY from
source. On our build machine, this process took 12 minutes starting
from an empty cache.

```bash
DOCKER_IMAGE=$(docker build . -q -f Dockerfile.aby)
```

We provide two small pre-compiled circuits from the Jupyter notebook
in the `example-circuits` directory. Circuits consist of one circuit
description file (`.spfe` extension) which is known to both parties
and one programming file (`.spfe.prog` extension) describing the
functionality of private components.

Using the Docker image, circuits in `example-circuits` can be executed
with ABY on local machines...

```bash
# circuit file in example-circuit directory
F=paper_example_verilog.spfe

# programming file corresponding to this circuit
E=paper_example_verilog.spfe.prog

# create a docker network where server and client can talk to each other
docker network create fluent

# server
docker run --name server --network fluent \
       -v ./example-circuits:/root/circuits -w /root/circuits \
       --rm -it $DOCKER_IMAGE \
       uc_circuit_test -r 0 -a 0.0.0.0 -f $F -e $E

# in another terminal: client
docker run --name client --network fluent \
       -v ./example-circuits:/root/circuits -w /root/circuits \
       --rm -it $DOCKER_IMAGE \
       uc_circuit_test -r 1 -a server -f $F
```

...as well as multiple machines:

```bash
IP=<IP address of server>
PORT=<TCP listening port of server>

# server
docker run -p $PORT:$PORT \
       -v ./example-circuits:/root/circuits -w /root/circuits \
       --rm -it $DOCKER_IMAGE \
       uc_circuit_test -r 0 -a $IP -p $PORT -f $F -e $E

# client
docker run -v ./example-circuits:/root/circuits -w /root/circuits \
       --rm -it $DOCKER_IMAGE \
       uc_circuit_test -r 1 -a $IP -p $PORT -f $F
```

## Detailed instructions for manual reproducing without Docker

### Step 1: Install dependencies

#### ABY

On Linux, ABY requires the following packages (package names are from
Ubuntu 22.04 repositories, other distributions may use different
package names):

```bash
sudo apt-get install build-essential \
     cmake \
     libgmp-dev \
     libssl-dev \
     doxygen \
     ninja-build
```

`boost` version 1.66 is also required, which is not available in the
Ubuntu repositories and thus needs to be installed from source:

```bash
sudo apt-get install curl
curl -LS https://archives.boost.io/release/1.66.0/source/boost_1_66_0.tar.gz | tar xz
cd boost_1_66_0
./bootstrap.sh
./b2
sudo ./b2 install
```

#### XLS

XLS is built using the Bazel build system[3] version 5.3.0. We
recommend using Bazelisk[4] to fetch and set up the
exact version of Bazel required.

Additionally, the following packages are needed (package names are
from Ubuntu 22.04 repositories, other distributions may use different
package names):

```bash
sudo apt-get install build-essential \
     python3-distutils \
     python3-dev \
     libtinfo5 \
     libxml2-dev \
     liblapack-dev \
     libblas-dev \
     gfortran

cd xls
curl -SL -o bazelisk https://github.com/bazelbuild/bazelisk/releases/download/v1.22.0/bazelisk-linux-amd64
chmod +x bazelisk
```

#### Yosys

The SPFE compiler invokes the Yosys[6] synthesis toolchain in order to
generate Boolean circuits from Verilog. When compiling circuits, the
compiler expects the `yosys` binary to be in the current path.

```bash
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y curl \
                               build-essential \
                               libreadline-dev \
                               python3 \
                               pkg-config \
                               tcl-dev \
                               libffi-dev \
                               flex bison git
```

#### SPFE compiler

The SPFE compiler requires a 0.10.0 release of the Zig[5]
compiler. Assuming a x86_64 Linux machine, the following commands will
download and extract a Zig compiler binary. Binaries for other systems
are available under https://ziglang.org/download/.

```bash
cd spfe
wget https://ziglang.org/download/0.10.0/zig-linux-x86_64-0.10.0.tar.xz
tar xf zig-linux-x86_64-0.10.0.tar.xz
```

### Step 2: Building

#### ABY

After running the following commands, the `uc_circuit_test` executable
responsible for executing SPFE circuits will be available in the
`build/bin` directory.

```bash
cd aby
mkdir build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DABY_BUILD_EXE=On
make -j$(nproc)
```

#### XLS

After running the following command, various XLS tools will be present
in the `bazel-bin` directory. This may take multiple hours.

The SPFE compiler needs to know where the resulting binaries are
located. They can be added to `$PATH` or special environment variables
as demonstrated below. We recommend the latter, as this prevents
cluttering of `$PATH`.

```bash
cd xls
./bazelisk build -- //xls/dslx:ir_converter_main //xls/tools:opt_main //xls/tools:codegen_main //xls/contrib/xlscc:xlscc

XLSCC=$(pwd)/bazel-bin/xls/contrib/xlscc/xlscc
XLS_OPT=$(pwd)/bazel-bin/xls/tools/opt_main
XLS_CODEGEN=$(pwd)/bazel-bin/xls/tools/codegen_main
export XLSCC
export XLS_OPT
export XLS_CODEGEN
```

#### Yosys

After running the following command, Yosys binaries will be present in
the `yosys-yosys-0.37` subdirectory. The SPFE compiler expects these
binaries to be in `$PATH`, so add this subdirectory to `$PATH`.

```bash
curl -LS https://github.com/YosysHQ/yosys/archive/refs/tags/yosys-0.37.tar.gz | tar xz
cd yosys-yosys-0.37
make config-gcc
make -j$(nproc)

PATH=$PATH:$(pwd)
export PATH
```

#### SPFE compiler

The following shell command will build the SPFE compiler and the UC
compiler. Both executables will be present in the `zig-out/bin`
directory.

```bash
cd spfe
zig-linux-x86_64-0.10.0/zig build
```

### Step 3: Testing

The following command will run the entire test suite included in the
compiler subdirectory.

```bash
cd spfe
zig-linux-x86_64-0.10.0/zig build test
```

## Reproducing benchmark results

In the `benchmarks` folder, we provide all material used to calculate
the figures used in our evaluation (cf. Section 4).

### Step 1: Compiling circuits

This is the prerequisite for the next two analysis steps. The three
scripts source the lists of circuits to process using the `list.txt`,
`list_c.txt`, and `list_cnn.txt` files for SPFE Building Blocks
(cf. Section 4.1), C insurance example (cf. Section 4.2), and CNN
example respectively.

```bash
cd benchmarks

# make sure the `spfe` executable is in your $PATH
# compiles everything in list.txt
./compile.sh

# compiles everything in list_c.txt
pushd insurance_c/insurance && ../../compile_c.sh && popd

# compiles everything in list_cnn.txt
./compile_cnn.sh
```

### Alternative: Use precompiled circuits

The compilation of all circuits in all variants for parameter
comparison took multiple days on our build machines. We provide the
precompiled circuits in a GitHub release:

https://github.com/encryptogroup/FLUENT/releases/tag/v1.0.0

Download the tar archive into the `benchmarks` folder and extract it there:

```bash
cd benchmarks
tar xf circuits.tar.xz
```

### Step 2a: Analysis of circuit size

The SPFE circuits generated in the previous step can now be analyzed
w.r.t. their number of AND gates.

```bash
cd benchmarks
./make_sfe_pfe_gates.sh
./make_insurance_gates.sh
./make_cnn_gates.sh
```

### Step 2b: Runtime and communication analysis

Before running these benchmarks, replace the following items in
`run_aby.sh` to match your setup:

- `SERVER_HOSTNAME` and `CLIENT_HOSTNAME`
- `SERVER_IP` and `CLIENT_IP`

```bash
cd benchmarks

# benchmarks all circuits listed in run_list.txt
./run_all.sh

# collection of results
./extract_time_mem_stats.py $(find benchmarks/)
```

## References

[0] Daniel Demmler, Thomas Schneider, and Michael Zohner. 2015. ABY–A Framework for Efficient Mixed-Protocol Secure Two-Party Computation. In NDSS.
    Source code: https://github.com/encryptogroup/ABY

[1] https://google.github.io/xls/

[2] Yann Disser, Daniel Günther, Thomas Schneider, Maximilian Stillger, Arthur Wigandt, and Hossein Yalame. 2023. Breaking the Size Barrier: Universal Circuits meet Lookup Tables. In ASIACRYPT.
    Source code: https://github.com/encryptogroup/LUC

[3] https://bazel.build/

[4] https://github.com/bazelbuild/bazelisk

[5] https://ziglang.org/

[6] https://yosyshq.net/yosys/

## Appendix

### Pre-built binary dependencies

As the build process of XLS[1] involves compiling LLVM and Clang from
source, this process is time-consuming, even on powerful machines. For
this reason, we provide pre-compiled binaries, which are downloaded by
the Jupyter notebook. These binaries can be reproduced locally using
Docker:

```bash
docker build . -f Dockerfile.xls
```

On our build machine, this process took 21 minutes starting from an empty
cache. After completion, copy the binaries from the container image
into your local system.

### Our build machine configuration

We provide the specifications of the machine used to build our
binaries. This machine was not used to run the runtime and
communication benchmarks. The specifications for these machines is
provided in the original paper.

- Intel Core i5-10400K
- 16 GB RAM
- 500GB NVMe SSD

### Package versions

#### ABY

```
build-essential/jammy,now 12.9ubuntu3 amd64
cmake/jammy-updates,now 3.22.1-1ubuntu1.22.04.2 amd64
curl/jammy-updates,jammy-security,now 7.81.0-1ubuntu1.16 amd64
doxygen/jammy,now 1.9.1-2ubuntu2 amd64
libgmp-dev/jammy,now 2:6.2.1+dfsg-3ubuntu1 amd64
libssl-dev/jammy-updates,jammy-security,now 3.0.2-0ubuntu1.16 amd64
ninja-build/jammy,now 1.10.1-1 amd64
```

#### XLS

```
build-essential/jammy,now 12.9ubuntu3 amd64
libblas-dev/jammy,now 3.10.0-2ubuntu1 amd64
liblapack-dev/jammy,now 3.10.0-2ubuntu1 amd64
libtinfo5/jammy-updates,jammy-security,now 6.3-2ubuntu0.1 amd64
libxml2-dev/jammy-updates,jammy-security,now 2.9.13+dfsg-1ubuntu0.4 amd64
python3-dev/jammy-updates,jammy-security,now 3.10.6-1~22.04 amd64
python3-distutils/jammy-updates,jammy-security,now 3.10.8-1~22.04 all
```
