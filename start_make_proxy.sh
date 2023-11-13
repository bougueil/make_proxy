#!/bin/bash

# Add path to erl
#export PATH=$PATH:/home/k/.asdf/shims
export PATH=$PATH:/usr/local/otp/bin

cd `dirname $0`
./_build/prod/rel/make_proxy/bin/make_proxy stop || true
./_build/prod/rel/make_proxy/bin/make_proxy daemon
