# pytorch_dev_env_setup

This repo can be used to setup dependencies from source, install all the possible python versions, do one pytorch install for each (including domain libs) and setup automatic environment to switch between them just by being in the right folder.

## What it will create
- `HOME=~/local` is the base of everything
- `HOME/installs` all the local installs from deps and cpython
- `HOME/pytorch/PY_VERSION` contains a pytorch install for that particular python version

## How to use after setup

Just move to the `HOME/pytorch/PY_VERSION` folder that you want to use (for example `cd local/pytorch/3.11_debug_source` is a good current default) for development. Once you enter that folder, the right environment will automatically be enabled.
You can then use this PyTorch clone as your main dev folder as a usual git clone.
If you need any of the corresponding domain libraries, you can find them at `HOME/pytorch/PY_VERSIONS_{lib_name}` (for example `local/pytorch/3.8_debug_source_vision` for torchvision). Domains are disabled by default and should be uncommented in the new_pytorch script if needed.

## How to use this repo
Make sure to have all the right dependencies, these are very much dependent on your OS but if you can build CPython from source (as of writing, `dnf install bzip2-devel readline-devel libffi-devel zlib-devel sqlite-delve` is a good set of dependencies for Fedora).
There are three main steps:
- `./deps.sh` that can be used to install any dependency you need from source. By default it only installs OpenBLAS as this one is pretty safe. You can un-comment blocks in the script if you need any of the other dependency from source (but getting them from your package manager is best if it is available there).
- `./all_python.sh` that will install all the python versions (that PyTorch current supports) from source and in release, debug and debug+shared mode (debug mode is a good default as it is fast with extra asserts, the shared mode is needed if you want to work with multipy). With multipy going away, the shared build is disabled by default now.
- `./all_new_pytorch.sh` that will install a PyTorch for every python that were created above (both from source and from nightly binary). It can also pull in a from source version of the relevant domain libraries to ensure full binary compat (vision, audio, data, text, benchmark) if you uncomment that in the code. Each of these folders will have the proper direnv setup so that everything is automatically activated once you get into the folder.