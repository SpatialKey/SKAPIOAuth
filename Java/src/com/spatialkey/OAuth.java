package com.spatialkey;

import java.security.Key;
import java.text.MessageFormat;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import org.apache.commons.codec.binary.Base64;

public class OAuth {
	private static final String HASH_ALGORITHM = "HmacSHA256";
	
	/**
	 * This method will return a JWT OAuth token for the passed user, org, and secret keys.  Defaults to 60 second timeout.
	 * 
	 * @param userAPIKey
	 * @param orgAPIKey
	 * @param orgSecretKey
	 * @return
	 * @throws Exception
	 */
	public static String getOAuthToken(String userAPIKey, String orgAPIKey, String orgSecretKey) throws Exception
	{
		return getOAuthToken(userAPIKey, orgAPIKey, orgSecretKey, 60);
	}
	
	/**
	 * This method will return a JWT OAuth token for the passed user, org, and secret keys along with a time to live value (in seconds).
	 * 
	 * @param userAPIKey
	 * @param orgAPIKey
	 * @param orgSecretKey
	 * @param ttl
	 * @return
	 * @throws Exception
	 */
	public static String getOAuthToken(String userAPIKey, String orgAPIKey, String orgSecretKey, int ttl) throws Exception 
	{
		String header = "{\"alg\":\"HS256\"}";
        String claimTemplate = "'{'\"iss\": \"{0}\", \"prn\": \"{1}\", \"aud\": \"{2}\", \"exp\": \"{3}\", \"iat\": \"{4}\"'}'";

        // create JWT Token
        StringBuffer token = new StringBuffer();

        // add header
        token.append(Base64.encodeBase64URLSafeString(header
                .getBytes("UTF-8")));
        token.append(".");
        
        // add JWT Claims Object
        String[] claimArray = new String[5];
        claimArray[0] = orgAPIKey; // org
        claimArray[1] = userAPIKey; // user
        claimArray[2] = "https://www.spatialkey.com";
        claimArray[3] = Long
                .toString((System.currentTimeMillis() / 1000) + ttl);
        claimArray[4] = Long.toString(System.currentTimeMillis() / 1000);
        MessageFormat claims = new MessageFormat(claimTemplate);
        String payload = claims.format(claimArray);
        token.append(Base64.encodeBase64URLSafeString(new String(payload)
                .getBytes("UTF-8")));
        
        String encryptedPayload = hashMac(token.toString(),
                orgSecretKey);

        token.append(".").append(encryptedPayload);
        
        return token.toString();
	}
	
	protected static String hashMac(String text, String secretKey) throws Exception
    {
        Key sk = new SecretKeySpec(secretKey.getBytes(), HASH_ALGORITHM);
        Mac mac = Mac.getInstance(sk.getAlgorithm());
        mac.init(sk);
        final byte[] hmac = mac.doFinal(text.getBytes("UTF-8"));
        return Base64.encodeBase64URLSafeString(hmac);
    }
}
