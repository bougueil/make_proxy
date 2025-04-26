#!/bin/bash

# Add path to erl
export PATH=$HOME/.elixir-install/installs/otp/27.2.3/bin:$PATH
export PATH=$HOME/.elixir-install/installs/elixir/1.18.3-otp-27/bin:$PATH

cd `dirname $0`
./_build/prod/rel/make_proxy/bin/make_proxy stop
sleep 1
./_build/prod/rel/make_proxy/bin/make_proxy daemon
