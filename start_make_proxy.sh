#!/bin/bash
export PATH=$PATH:/usr/local/otp_25/bin
cd `dirname $0`
./_build/prod/rel/make_proxy/bin/make_proxy stop
./_build/prod/rel/make_proxy/bin/make_proxy daemon