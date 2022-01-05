package weiner.noah.marty;

import android.telephony.SmsManager;
import android.util.Log;

public class SMSCallback {
    //static SuccessCallback<String> onSuccess;
    //static FailureCallback onFail;

    private static final String TAG = "SMSCallback";
    private static final SmsManager smsManager = SmsManager.getDefault();


    //check if a passed buddy is already in the db
    public static boolean buddyInList(String offendingBuddy) {
        return false;
    }

    //add a new buddy to the buddy list
    public static void addBuddy(String offendingBuddy) {

    }

    //let buddy know they've already opted in
    public static void sendAlreadyInListMsg(String offendingBuddy) {

    }

    public static void sendIntroMsg(String offendingBuddy) {
        Log.i(TAG, "Sending intro msg... to " + offendingBuddy);
        sendMsg(StockMsgStrings.introText2, offendingBuddy);
    }


    public static void smsReceived(String sms, String sender) {
        //Log.i(TAG, "smsReceived() firing!!");
        /*
        if (onSuccess != null) {
            SuccessCallback<String> s = onSuccess;
            onSuccess = null;
            onFail = null;
            SMSInterceptor.unbindListener();
            callSerially(() -> s.onSucess(sms)); (2)
        }
         */

        String lowerCaseMsg = sms.toLowerCase();

        //do something with db to get current buddy list

        //check if user is already in buddy list. If not, add them to the buddy list and send intro text
        switch(lowerCaseMsg) {
            case "opt in":
                Log.i(TAG, "Triggered");
                if (buddyInList(sender)) {
                    sendAlreadyInListMsg(sender);
                }
                else {
                    addBuddy(sender);
                    sendIntroMsg(sender);
                }
                break;
        }



        Log.i(TAG, "'" + sms + "'" +  " sent from " + sender);
        //smsManager.sendTextMessage(sender, null, sms, null, null);
    }

    public static void smsReceiveError(Exception err) {
        /*
        if (onFail != null) {
            FailureCallback f = onFail;
            onFail = null;
            SMSInterceptor.unbindListener();
            onSuccess = null;
            callSerially(() -> f.onError(null, err, 1, err.toString()));
        } else {
            if(onSuccess != null) {
                SMSInterceptor.unbindListener();
                onSuccess = null;
            }
        }
         */
    }

    public static void sendMsg(String text, String recipient) {
        smsManager.sendTextMessage(recipient, null, text, null, null);
    }
}
