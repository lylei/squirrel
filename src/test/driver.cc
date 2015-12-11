// Copyright (c) 2015, squirreldb. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <iostream>

#include <thread.h>
#include <boost/bind.hpp>
#include <boost/lexical_cast.hpp>

#include "src/sdk/client.h"

namespace baidu {
namespace squirrel {

void test_put_callback(const std::string&, const std::string&, StatusCode*) {
  // dummy function
}

void test_put(sdk::Client* client) {
  uint64_t key_int = 0;
  uint64_t value_int = 0;
  StatusCode status;
  while (true) {
    int thread_pool_pending;
    client->GetStat(NULL, NULL, NULL, &thread_pool_pending, NULL);
    while (thread_pool_pending > 100) {
      usleep(500);
      client->GetStat(NULL, NULL, NULL, &thread_pool_pending, NULL);
    }
    std::string key = boost::lexical_cast<std::string>(key_int);
    std::string value = boost::lexical_cast<std::string>(value_int);
    sdk::UserPutCallback* put_callback = new sdk::UserPutCallback(boost::bind(&test_put_callback, _1, _2, _3));
    client->Put(key, value, &status, put_callback);
    ++key_int;
    ++value_int;
  }
}

} // namespace sdk
} // namespace squirrel

int main() {
  struct timeval tv_start, tv_end;
  gettimeofday(&tv_start, NULL);

  baidu::squirrel::sdk::Client client;

  baidu::common::Thread thread;
  thread.Start(boost::bind(&baidu::squirrel::test_put, &client));

  while (true) {
    gettimeofday(&tv_end, NULL);
    long start = tv_start.tv_sec * 1000000 + tv_start.tv_usec;
    long end = tv_end.tv_sec * 1000000 + tv_end.tv_usec;
    double interval = (end - start) / double(1000000);

    int count, failed, pending, thread_pool_pending;
    std::string profile_str;
    client.GetStat(&count, &failed, &pending, &thread_pool_pending, &profile_str);
    std::cout << "Qps=" << int(count / interval)
              << "\tfailed=" << int(failed / interval)
              << "\tpending=" << int(pending / interval)
              << "\tinterval=" << interval
              << "\tthreadpool_pending=" << thread_pool_pending
              << "\ttp=" << profile_str
              << std::endl;
    client.ResetStat();

    tv_start = tv_end;
    sleep(1);
  }

  thread.Join();
  return EXIT_SUCCESS;
}
