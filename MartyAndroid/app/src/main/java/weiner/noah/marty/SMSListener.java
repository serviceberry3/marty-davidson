package weiner.noah.marty;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.telephony.SmsManager;
import android.telephony.SmsMessage;
import android.util.Log;

import java.util.Objects;

public class SMSListener extends BroadcastReceiver {
    private final String TAG = "SMSListener";


    @Override
    public void onReceive(Context context, Intent intent) {
        if (Objects.equals(intent.getAction(), "android.provider.Telephony.SMS_RECEIVED")) {
            //extract the info Bundle from the incoming Intent
            Bundle bundle = intent.getExtras();

            //initialize msgs array to null
            SmsMessage[] msgs = null;

            if (bundle != null) {
                try {
                    //get the raw PDUs
                    Object[] pdus = (Object[])bundle.get("pdus");

                    //instantiate array of SMS msgs based on length of PDUs received
                    msgs = new SmsMessage[pdus.length];

                    //iterate over each SmsMessage
                    for (int i = 0; i < msgs.length; i++) {
                        //reconstruct the SMS text from the raw PDU
                        msgs[i] = SmsMessage.createFromPdu((byte[])pdus[i]);
                        String msgBody = msgs[i].getMessageBody(); //get actual text

                        String sender = msgs[i].getDisplayOriginatingAddress();


                        //run callback fxn for message received
                        SMSCallback.smsReceived(msgBody, sender);
                    }
                }
                catch(Exception e) {
                    Log.e(TAG, e.toString());
                    SMSCallback.smsReceiveError(e);
                }
            }
        }
    }
}
