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
package com.getperf.perf;

import com.typesafe.config.*;
import org.slf4j.*;

/**
 * Logging message from agent.
 */

public class EventManager {
    static final Logger LOG  = LoggerFactory.getLogger(EventManager.class);
    static final Config CONF = ConfigFactory.load();

    /**
     * Logging message from agent. the serverity level is in 1-4.
     */

    public String sendMessage(String siteKey, String hostname, int severity, String message) {
        if (severity == 1) {
            LOG.info("[{},{}] {}", siteKey, hostname, message);
        } else if (severity == 2) {
            LOG.warn("[{},{}] {}", siteKey, hostname, message);
        } else if (severity == 3) {
            LOG.error("[{},{}] {}", siteKey, hostname, message);
        } else if (severity == 4) {
            LOG.error("FATAL [{},{}] {}", siteKey, hostname, message);
        } else {
            return "invarid severity";
        }
        return "OK";
    }

}
