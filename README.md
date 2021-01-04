# bbot

## Install

```
sudo dnf group install "Development Tools"
sudo dnf install -y libffi-devel openssl-devel bubblewrap
sh <(curl -sL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)
opam switch create bbot 4.11.1
eval $(opam env)
opam install core async async_ssl yojson uri textwrap cohttp-async atdgen-runtime atdgen-codec-runtime ppx_let
```
