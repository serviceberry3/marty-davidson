package weiner.noah.marty;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.telephony.TelephonyManager;
import android.util.Log;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Objects;

public class PhoneCallListener extends BroadcastReceiver {
        private static String lastState = TelephonyManager.EXTRA_STATE_IDLE;
        private static Date callStartTime;
        private static boolean isIncoming;
        private static String savedNumber;  //because the passed incoming is only valid in ringing

        private final String TAG = "PhoneCallListener";

        @Override
        public void onReceive(Context context, Intent intent) {
            if (Objects.equals(intent.getAction(), "android.intent.action.PHONE_STATE")) {
                Log.i(TAG, "onReceive() CALLED!!");

                //list to store keys in intent
                List<String> keyList = new ArrayList<>();

                //get info Bundle from incoming Intent
                Bundle bundle = intent.getExtras();

                //store incoming keys in keyList
                if (bundle != null) {
                    keyList = new ArrayList<>(bundle.keySet());
                    Log.i(TAG, "Keys are: " + keyList);
                }

                //check if caller number is found in keyList
                if (keyList.contains("incoming_number")) {
                    //get phone state and phone number data
                    String phoneState = intent.getStringExtra(TelephonyManager.EXTRA_STATE);
                    String phoneIncomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER);
                    String phoneOutgoingNumber = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER);

                    Log.i(TAG, "Phone state is " + phoneState + ", incoming number is " + phoneIncomingNumber +
                            ", outgoing number is " + phoneOutgoingNumber);

                    //get phoneNumber: either incoming or outgoing
                    String phoneNumber = phoneOutgoingNumber != null ?
                            phoneOutgoingNumber
                            : (phoneIncomingNumber != null ? phoneIncomingNumber : "");


                    if (phoneState != null) {
                        if (lastState.equals(phoneState)) {
                            //phone state has not changed, do nothing and return immediately
                            return;
                        }

                        //otherwise the phone state has changed. Print out new state
                        Log.i(TAG, "The phone state has changed, it was " + lastState + " and is now " + phoneState);

                        //there are three phone states: ringing, idle, or offhook

                        //ringing means new call arrived and is ringing or waiting. If waiting, another call is already active.
                        if (TelephonyManager.EXTRA_STATE_RINGING.equals(phoneState)) {
                            //phone is ringing, so a call is incoming
                            isIncoming = true;

                            //record the call start time
                            callStartTime = new Date();

                            //save the ringing state as last state
                            lastState = TelephonyManager.EXTRA_STATE_RINGING;

                            //save the number that's calling me
                            savedNumber = phoneNumber;

                            onIncomingCallRinging(context, savedNumber, callStartTime);
                        }

                        //if the phone state is IDLE (no activity)
                        else if (TelephonyManager.EXTRA_STATE_IDLE.equals(phoneState)) {
                            //if phone was ringing before and is now idle, we missed a call
                            if (lastState.equals(TelephonyManager.EXTRA_STATE_RINGING)) {
                                //save last state
                                lastState = TelephonyManager.EXTRA_STATE_IDLE;

                                //run missed call callback fxn
                                onMissedCall(context, savedNumber, callStartTime);
                            }

                            //if phone was offhook before and is now idle, two things are possible
                            else {
                                //1. there was an incoming call that was just ended
                                if (isIncoming) {
                                    //set lastState to idle
                                    lastState = TelephonyManager.EXTRA_STATE_IDLE;

                                    //run incoming call ended callback fxn
                                    onIncomingCallEnded(context, savedNumber, callStartTime, new Date());
                                }

                                //2. there was an outgoing call that was just ended
                                else {
                                    //set lastState to idle
                                    lastState = TelephonyManager.EXTRA_STATE_IDLE;

                                    //run outgoing call ended callback fxn
                                    onOutgoingCallEnded(context, savedNumber, callStartTime, new Date());
                                }
                            }
                        }

                        //offhook means at least one call exists that is dialing, active, or on hold, and no calls ringing or waiting
                        else if (TelephonyManager.EXTRA_STATE_OFFHOOK.equals(phoneState)) {
                            //check if this is an incoming call, which is only the case if the phone actually rang before it was taken off the hook
                            isIncoming = lastState.equals(TelephonyManager.EXTRA_STATE_RINGING);

                            //save state as offhook
                            lastState = TelephonyManager.EXTRA_STATE_OFFHOOK;

                            //if it's incoming, already have recorded caller number and starting time
                            if (isIncoming) {
                                //run incoming call callback fxn
                                onIncomingCallStarted(context, savedNumber, callStartTime);
                                return;
                            }

                            //otherwise an outgoing call is being placed

                            //save call starting time
                            callStartTime = new Date();

                            //save the caller or callee phone num
                            savedNumber = phoneNumber;

                            //run outgoing call started callback fxn
                            onOutgoingCallStarted(context, savedNumber, callStartTime);
                        }
                    }
                }
            }
        }

        protected void onIncomingCallRinging(Context ctx, String number, Date start) {
            Log.d(TAG, "An incoming call is ringing, from number " + number);
        }

        protected void onIncomingCallStarted(Context ctx, String number, Date start) {
            Log.d(TAG, "An incoming call has been picked up, from number " + number);
        }

        protected void onOutgoingCallStarted(Context ctx, String number, Date start) {
            Log.d(TAG, "An outgoing call is being placed to number " + number);
        }

        protected void onIncomingCallEnded(Context context, String number, Date start, Date end) {
            Log.d(TAG, "An incoming call has just been ended, from number " + number);
        }

        protected void onOutgoingCallEnded(Context context , String number, Date start, Date end) {
            Log.d(TAG, "An outgoing call has just been ended, from number " + number);
        }

        protected void onMissedCall(Context context, String number, Date start) {
            Log.d(TAG, "An incoming call has just rung and been missed or declined from number " + number);

            //if do not disturb is currently on, then allow sender to shut it off
            if (SettingsChanger.doNotDistIsOn((MainActivity)context)) {
                SMSCallback.sendMissedCallIntro(number);

                //change state to accepting do not disturb nudges
                ((MainActivity) context).myMarty.setState(MartyState.ACCEPTINGDNDNUDGE);
            }
        }
}
