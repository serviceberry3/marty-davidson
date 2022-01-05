package weiner.noah.marty;

import androidx.appcompat.app.AppCompatActivity;

import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;

public class MainActivity extends AppCompatActivity {
    private NativeSMSInterceptorImpl nativeSMSInterceptor = new NativeSMSInterceptorImpl(this);
    private NativePhoneCallInterceptorImpl nativePhoneCallInterceptor = new NativePhoneCallInterceptorImpl(this);

    private static final int PERMISSION_REQUEST_CODE = 1;

    public MartyDavidson myMarty;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);


        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            if (checkSelfPermission(Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_DENIED) {

                Log.d("PERMISSIONS", "Permission DENIED to SEND_SMS - requesting it NOW...");
                String[] permissions = {Manifest.permission.SEND_SMS};

                requestPermissions(permissions, PERMISSION_REQUEST_CODE);
            }
        }

        //instantiate the Marty
        myMarty = new MartyDavidson();

        //set up the listeners
        nativeSMSInterceptor.bindSMSListener();
        nativePhoneCallInterceptor.bindPhoneCallListener();
    }
}