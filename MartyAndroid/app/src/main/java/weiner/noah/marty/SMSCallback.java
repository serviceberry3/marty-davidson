package weiner.noah.marty;

import android.content.Context;
import android.telephony.SmsManager;
import android.util.Log;

import java.util.ArrayList;

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
        sendMsg(StockMsgStrings.introText, offendingBuddy);
    }

    public static void sendMissedCallIntro(String offendingBuddy) {
        sendMsg(StockMsgStrings.missedCallIntro, offendingBuddy);
    }

    public static void sendNudgeSuccessMsg(String offendingBuddy) {
        sendMsg(StockMsgStrings.nudgeSuccess, offendingBuddy);
    }

    //main entry point
    public static void smsReceived(MainActivity mainActivity, String sms, String sender) {
        MartyDavidson marty = mainActivity.myMarty;

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
            case "nudge":
                if (marty.getState() == MartyState.ACCEPTINGDNDNUDGE) {
                    if (SettingsChanger.shutOffDoNotDist(mainActivity)) {
                        marty.setState(MartyState.IDLE);
                        sendNudgeSuccessMsg(sender);
                    }
                }
                break;
        }

        Log.i(TAG, "'" + sms + "'" +  " sent from " + sender);
    }

    public static void smsReceiveError(Exception err) {
    }

    public static void sendMsg(String text, String recipient) {
        ArrayList<String> messagePieces = smsManager.divideMessage(text);
        smsManager.sendMultipartTextMessage(recipient, null, messagePieces, null, null);
    }
}
