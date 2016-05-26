/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.apache.flink.runtime.io.network.partition;

import org.apache.flink.runtime.execution.CancelTaskException;
import org.apache.flink.util.ExceptionUtils;

/**
 * Network-stack level Exception to notify remote receiver about a failed
 * partition producer.
 */
public class ProducerFailedException extends CancelTaskException {

	private static final long serialVersionUID = -1555492656299526395L;

	private final String causeAsString;

	/**
	 * The cause of the producer failure.
	 *
	 * Note: The cause will be stringified, because it might be an instance of
	 * a user level Exception, which can not be deserialized by the remote
	 * receiver's system class loader.
	 */
	public ProducerFailedException(Throwable cause) {
		this.causeAsString = cause != null ? ExceptionUtils.stringifyException(cause) : null;
	}

	/**
	 * Returns the stringified cause of the producer failure.
	 */
	public String getCauseAsString() {
		return causeAsString;
	}
}
