package weiner.noah.marty;

import android.content.IntentFilter;

public class SMSInterceptorImpl implements SMSInterceptor {
    private SMSListener smsListener;
    private MainActivity mainActivity;

    public SMSInterceptorImpl(MainActivity mainActivity) {
        this.mainActivity = mainActivity;
    }

    public void bindSMSListener() {
        smsListener = new SMSListener();
        IntentFilter filter = new IntentFilter();
        filter.addAction("android.provider.Telephony.SMS_RECEIVED");
        mainActivity.registerReceiver(smsListener, filter);
    }

    public void unbindSMSListener() {
        mainActivity.unregisterReceiver(smsListener);
    }

    public boolean isSupported() {
        return true;
    }
}
