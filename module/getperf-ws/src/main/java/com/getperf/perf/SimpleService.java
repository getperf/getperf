/*
 * Getperf
 * Copyright (C) 2014-2016, Minoru Furusawa, Toshiba corporation.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements. See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package com.getperf.perf;
import com.typesafe.config.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisPool;
import redis.clients.jedis.JedisPoolConfig;

public class SimpleService {
	static final Logger LOG  = LoggerFactory.getLogger(SimpleService.class);
	static final Config CONF = ConfigFactory.load();
    
    public String  helloService(String msg){
    	LOG.info("I am file. {}", msg);
    	LOG.info("The answer is: {}", CONF.getString("GETPERF_HOME"));
        return "Hello "+ msg;
    }

    public String  helloJedis(String msg){
		JedisPool pool = new JedisPool(new JedisPoolConfig(), "localhost");
		Jedis jedis = pool.getResource();
		try {
		  jedis.set("mykey", "Hello");
		  LOG.info("keys(*)=" + jedis.keys("*"));
		  LOG.info("get(mykey)=" + jedis.get("mykey"));
		  jedis.del("mykey");
		  LOG.info("keys(*)=" + jedis.keys("*"));
		} finally {
		  pool.returnResource(jedis);
		}
		pool.destroy();
        return "HelloJedis "+ msg;
    }

	public String testGetAttachedFile() 
		throws java.rmi.RemoteException{
		// FileManageService res = new FileManageService();		
		// if (!res.writeAttachedBinaryFile("/tmp/", "test.txt")) {
		// 		return "Error";
		// }
		return "OK";
	}

}
