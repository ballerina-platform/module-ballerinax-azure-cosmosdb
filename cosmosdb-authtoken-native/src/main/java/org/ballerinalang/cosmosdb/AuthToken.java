package org.ballerinalang.cosmosdb;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;
import java.text.SimpleDateFormat;
import java.util.Base64;
import java.util.Calendar;
import java.util.Locale;
import java.util.TimeZone;

public class AuthToken {
    public static String generateToken(String verb, String resourceType, String resourceId, String key, String keyType,
                                  String tokenVersion) {
        String authorization = null;
        String date = getServerTime();
        String payload=verb.toLowerCase()+"\n"
                +resourceType.toLowerCase()+"\n"
                +resourceId+"\n"
                +date.toLowerCase()+"\n"
                +""+"\n";
        Mac sha256_HMAC;
        try {
            sha256_HMAC = Mac.getInstance("HmacSHA256");
            SecretKeySpec secret_key = new SecretKeySpec(Base64.getDecoder().decode(key), "HmacSHA256");
            sha256_HMAC.init(secret_key);
            String signature = Base64.getEncoder().encodeToString(sha256_HMAC.doFinal(payload.getBytes("UTF-8")));
            authorization=URLEncoder.encode("type="+keyType+"&ver="+tokenVersion+"&sig="+signature, "utf-8");
        }catch (InvalidKeyException e) {
            e.printStackTrace();
        }
        catch (NoSuchAlgorithmException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        catch (IllegalStateException e) {
            e.printStackTrace();
        }
        catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return authorization;
    }

    public static String getServerTime() {
        Calendar calendar = Calendar.getInstance();
        SimpleDateFormat dateFormat = new SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss z", Locale.US);
        dateFormat.setTimeZone(TimeZone.getTimeZone("GMT"));
        return dateFormat.format(calendar.getTime());
    }

}

