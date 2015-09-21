# Copyright (c) 2014 Baidu.com, Inc. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file. See the AUTHORS file for names of contributors.

#-----------------------------------------------
## Sofa-pbrpc path containing `include'and `lib'.
##
## Check file exist:
##   $(SOFA_PBRPC)/include/sofa/pbrpc/pbrpc.h 
##   $(SOFA_PBRPC)/lib/libsofa-pbrpc.a 
##
SOFA_PBRPC=../sofa-pbrpc/output
#-----------------------------------------------

#-----------------------------------------------
# Uncomment exactly one of the lines labelled (A), (B), and (C) below
# to switch between compilation modes.
#
OPT ?= -O2        # (A) Production use (optimized mode)
# OPT ?= -g2      # (B) Debug mode, w/ full line-level debugging symbols
# OPT ?= -O2 -g2  # (C) Profiling mode: opt, but w/debugging symbols
#-----------------------------------------------

#-----------------------------------------------
# !!! Do not change the following lines !!!
#-----------------------------------------------

include ../sofa-pbrpc/depends.mk

CXX=g++
INCPATH=-I. -I$(SOFA_PBRPC)/include -I$(BOOST_HEADER_DIR) -I$(PROTOBUF_DIR)/include \
		-I$(SNAPPY_DIR)/include -I$(ZLIB_DIR)/include
CXXFLAGS += $(OPT) -pipe -W -Wall -fPIC -D_GNU_SOURCE -D__STDC_LIMIT_MACROS $(INCPATH)

LIBRARY=$(SOFA_PBRPC)/lib/libsofa-pbrpc.a $(PROTOBUF_DIR)/lib/libprotobuf.a $(SNAPPY_DIR)/lib/libsnappy.a
LDFLAGS += -L$(ZLIB_DIR)/lib -lpthread -lrt -lz -lpthread

PROTO_SRC=squirrel_rpc.proto
PROTO_OBJ=$(patsubst %.proto,%.pb.o,$(PROTO_SRC))
PROTO_OPTIONS=--proto_path=. --proto_path=$(SOFA_PBRPC)/include --proto_path=$(PROTOBUF_DIR)/include

BIN=squirrel_server squirrel_client

all: check_depends $(BIN)

.PHONY: check_depends clean

check_depends:
	@if [ ! -f "$(PROTOBUF_DIR)/include/google/protobuf/message.h" ]; then echo "ERROR: need protobuf header"; exit 1; fi
	@if [ ! -f "$(PROTOBUF_DIR)/lib/libprotobuf.a" ]; then echo "ERROR: need protobuf lib"; exit 1; fi
	@if [ ! -f "$(PROTOBUF_DIR)/bin/protoc" ]; then echo "ERROR: need protoc binary"; exit 1; fi
	@if [ ! -f "$(SNAPPY_DIR)/include/snappy.h" ]; then echo "ERROR: need snappy header"; exit 1; fi
	@if [ ! -f "$(SNAPPY_DIR)/lib/libsnappy.a" ]; then echo "ERROR: need snappy lib"; exit 1; fi
	@if [ ! -f "$(SOFA_PBRPC)/include/sofa/pbrpc/pbrpc.h" ]; then echo "ERROR: need sofa-pbrpc header"; exit 1; fi
	@if [ ! -f "$(SOFA_PBRPC)/lib/libsofa-pbrpc.a" ]; then echo "ERROR: need sofa-pbrpc lib"; exit 1; fi

clean:
	@rm -f $(BIN) *.o *.pb.*

rebuild: clean all

squirrel_server: $(PROTO_OBJ) squirrel_server.o dummy_db.o
	$(CXX) $^ -o $@ $(LIBRARY) $(LDFLAGS)

squirrel_client: $(PROTO_OBJ) squirrel_client.o
	$(CXX) $^ -o $@ $(LIBRARY) $(LDFLAGS)

%.pb.o: %.pb.cc
	$(CXX) $(CXXFLAGS) -c $< -o $@

%.pb.cc: %.proto
	$(PROTOBUF_DIR)/bin/protoc $(PROTO_OPTIONS) --cpp_out=. $<

%.o: %.cc $(PROTO_OBJ)
	$(CXX) $(CXXFLAGS) -c $< -o $@

