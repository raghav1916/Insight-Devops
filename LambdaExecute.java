package com.test.Lambda;
import java.io.IOException;

import org.slf4j.Logger;
import com.test.S3.App;
import com.test.S3.Three;
import org.slf4j.LoggerFactory;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.s3.event.S3EventNotification;

public class LambdaExecute implements RequestHandler<S3EventNotification, String> {
	
	static final Logger log = LoggerFactory.getLogger(LambdaExecute.class);

	@Override
	public String handleRequest(S3EventNotification s3EventNotification, Context context) {
		log.info("Lambda function is invoked:" + s3EventNotification.toJson());
		String key=s3EventNotification.getRecords().get(0).getS3().getObject().getKey();
		log.info(key);
		
		App.copyFile(key);
		try {
			Three.copyToDynamo();
		} catch (IOException e) {
			e.printStackTrace();
		}
		return null;
	}

}
 


