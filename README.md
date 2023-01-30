# pytorch_dev_env_setup

This repo can be used to setup dependencies from source, install all the possible python versions, do one pytorch install for each (including domain libs) and setup automatic environment to switch between them just by being in the right folder.

## What it will create
- HOME=~/local is the base of everything
- HOME/installs all the local installs from deps
- HOME/installs_source with some temporary source (Should be cleaned up automatically)
- HOME/pytorch/PY_VERSION contains a pytorch install for that particular python version

## How to use after setup

Just use the HOME/pytorch/PY_VERSION folder that you want to use (for example cd local/pytorch/3.8_debug_source is a good current default) for development. Once you enter that folder, you will automatically use the right environment.
If you need any of the corresponding domain libraries, you can find them at HOME/pytorch/PY_VERSIONS_{lib_name} (for example local/pytorch/3.8_debug_source_vision for torchvision).

## How to use this repo
Make sure to have all the right dependencies, these are very much dependent on your OS but if you can build CPython from source (needs sqlite3 and openssl header usually to get a fully working version), PyTorch from source (need things like BLAS) and [direnv](https://direnv.net/).
There are three main steps:
- ./deps.sh that can be used to install any dependency you need from source. By default it only installs OpenBLAS as this one is pretty safe. You can un-comment blocks in the script if you need any of the other dependency from source (but getting them from your package manager if you have one available is best).
- ./all_python.sh that will install all the python versions from source (3.7 to 3.11 as of writing) and in release, debug and debug+shared mode (debug mode is a good default as it is fast with extra asserts, the shared mode is needed if you want to work with multipy).
- ./all_new_pytorch.sh that will install a PyTorch for every python that were created above (both from source and from nightly binary). It will also pull in a from source version of the relevant domain libraries to ensure full binary compat (vision, audio, data, text, benchmark). Each of these folders will have the proper direnv setup so that everything is automatically activated once you get into the folder.