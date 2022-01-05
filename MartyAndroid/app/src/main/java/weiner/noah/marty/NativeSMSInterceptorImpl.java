package weiner.noah.marty;

import android.Manifest;
import android.content.IntentFilter;

public class NativeSMSInterceptorImpl implements NativeSMSInterceptor {
    private SMSListener smsListener;
    private MainActivity mainActivity;

    public NativeSMSInterceptorImpl(MainActivity mainActivity) {
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
