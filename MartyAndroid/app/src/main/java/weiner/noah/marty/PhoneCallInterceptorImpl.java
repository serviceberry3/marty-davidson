package weiner.noah.marty;

import android.content.IntentFilter;

public class PhoneCallInterceptorImpl {
    private PhoneCallListener phoneCallListener;
    private MainActivity mainActivity;

    public PhoneCallInterceptorImpl(MainActivity mainActivity) {
        this.mainActivity = mainActivity;
    }

    public void bindPhoneCallListener() {
        phoneCallListener = new PhoneCallListener();
        IntentFilter filter = new IntentFilter();
        filter.addAction("android.intent.action.PHONE_STATE");
        mainActivity.registerReceiver(phoneCallListener, filter);
    }

    public void unbindPhoneCallListener() {
        mainActivity.unregisterReceiver(phoneCallListener);
    }

    public boolean isSupported() {
        return true;
    }
}
