package weiner.noah.marty;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import android.Manifest;
import android.accounts.AccountManager;
import android.app.Dialog;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.database.sqlite.SQLiteDatabase;
import android.graphics.Typeface;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Bundle;
import android.text.TextUtils;
import android.text.method.ScrollingMovementMethod;
import android.util.Log;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.api.client.extensions.android.http.AndroidHttp;
import com.google.api.client.googleapis.extensions.android.gms.auth.GoogleAccountCredential;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.calendar.CalendarScopes;

import java.util.Arrays;
import java.util.List;

public class MainActivity extends AppCompatActivity {
    private SMSInterceptorImpl nativeSMSInterceptor = new SMSInterceptorImpl(this);
    private PhoneCallInterceptorImpl nativePhoneCallInterceptor = new PhoneCallInterceptorImpl(this);

    private static final int PERMISSION_REQUEST_CODE = 1;

    public MartyDavidson myMarty;

    public BuddyDbHelper dbHelper;
    public SQLiteDatabase writeDb;
    public SQLiteDatabase readDb;

    private final int MY_PERMISSIONS_REQUEST_SMS_RECEIVE = 10;

    private final String TAG = "MainActivity";

    /**
     * A Google Calendar API service object used to access the API.
     * Note: Do not confuse this class with API library's model classes, which
     * represent specific data structures.
     */
    com.google.api.services.calendar.Calendar mService;

    GoogleAccountCredential credential;
    private TextView mStatusText;
    private TextView mResultsText;
    private TextView mErrorText;
    final HttpTransport transport = AndroidHttp.newCompatibleTransport();
    final GsonFactory jsonFactory = GsonFactory.getDefaultInstance();

    static final int REQUEST_ACCOUNT_PICKER = 1000;
    static final int REQUEST_AUTHORIZATION = 1001;
    static final int REQUEST_GOOGLE_PLAY_SERVICES = 1002;
    private static final String PREF_ACCOUNT_NAME = "martyishuge@gmail.com";
    private static final String[] SCOPES = {CalendarScopes.CALENDAR};

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        if (checkSelfPermission(Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_DENIED ||
        checkSelfPermission(Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_DENIED ||
        checkSelfPermission(Manifest.permission.ACCESS_NOTIFICATION_POLICY) == PackageManager.PERMISSION_DENIED) {

            Log.d("PERMISSIONS", "Permission DENIED to SEND_SMS - requesting it NOW...");
            String[] permissions = {Manifest.permission.SEND_SMS, Manifest.permission.RECEIVE_SMS,
                    Manifest.permission.ACCESS_NOTIFICATION_POLICY};

            requestPermissions(permissions, PERMISSION_REQUEST_CODE);
        }
        else {
            Log.i(TAG, "Already have send and receive SMS perms");
        }

        //instantiate the Marty
        myMarty = new MartyDavidson();

        dbHelper = new BuddyDbHelper(this);
        writeDb = dbHelper.getWritableDatabase();
        readDb = dbHelper.getReadableDatabase();

        //UNCOMMENT THIS LINE TO UPDATE THE DB SCHEMA ON STARTUP. THIS WILL DELETE ALL ENTRIES.
        //dbHelper.onUpgrade(writeDb, 0, 1);

        //set up the listeners
        nativeSMSInterceptor.bindSMSListener();
        nativePhoneCallInterceptor.bindPhoneCallListener();

        //set up new LinearLayout for visual formatting
        LinearLayout activityLayout = new LinearLayout(this);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT);
        activityLayout.setLayoutParams(lp);
        activityLayout.setOrientation(LinearLayout.VERTICAL);
        activityLayout.setPadding(16, 16, 16, 16);

        //create new LayoutParams object
        ViewGroup.LayoutParams tlp = new ViewGroup.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);

        //create text element in the view to give the current status of app
        mStatusText = new TextView(this);
        mStatusText.setLayoutParams(tlp);
        mStatusText.setTypeface(null, Typeface.BOLD);
        mStatusText.setText("Retrieving data...");
        activityLayout.addView(mStatusText);

        mErrorText = new TextView(this);
        mErrorText.setLayoutParams(tlp);
        mErrorText.setTypeface(null, Typeface.BOLD);
        mErrorText.setText("Errors messages: N/A");
        activityLayout.addView(mErrorText);

        //create text element in the view to give the results of calendar data retrieval
        mResultsText = new TextView(this);
        mResultsText.setLayoutParams(tlp);
        mResultsText.setPadding(16, 16, 16, 16);
        mResultsText.setVerticalScrollBarEnabled(true);
        mResultsText.setMovementMethod(new ScrollingMovementMethod());
        activityLayout.addView(mResultsText);

        //set the LinearLayout as the View for the app screen
        setContentView(activityLayout);

        //initialize credentials and service object.

        SharedPreferences settings = getPreferences(Context.MODE_PRIVATE);

        //get new instance of Google account credential using OAuth 2.0 scopes
        credential = GoogleAccountCredential.usingOAuth2(getApplicationContext(), Arrays.asList(SCOPES));

        //sets back-off policy, used when I/O exception is thrown inside getToken() or null for none
        //credential.setBackOff(new ExponentialBackOff())
        credential.setSelectedAccountName(settings.getString(PREF_ACCOUNT_NAME, null));

        //create a new Calendar.Builder object
        mService = new com.google.api.services.calendar.Calendar.Builder(
                transport, jsonFactory, credential)
                .setApplicationName("Google Calendar API Android Quickstart")
                .build();

        startActivityForResult(credential.newChooseAccountIntent(), REQUEST_ACCOUNT_PICKER);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        if (requestCode == MY_PERMISSIONS_REQUEST_SMS_RECEIVE) {
            // YES!!
            Log.i(TAG,"MY_PERMISSIONS_REQUEST_SMS_RECEIVE --> YES");
        }
    }

    /**
     * Called whenever this activity is pushed to the foreground, such as after
     * a call to onCreate().
     */
    @Override
    protected void onResume() {
        Log.i(TAG, "onResume() called!");

        super.onResume();

        //make sure Google Play Services are installed on device
        if (isGooglePlayServicesAvailable()) {
            refreshResults();
        }
        else {
            mStatusText.setText("Google Play Services required. After installing them on the device, close and relaunch this app.");
        }
    }

    /**
     * Called when an activity launched here (specifically, AccountPicker
     * and authorization) exits, giving you the requestCode you started it with,
     * the resultCode it returned, and any additional data from it.
     * @param requestCode code indicating which activity result is incoming.
     * @param resultCode code indicating the result of the incoming
     *     activity result.
     * @param data Intent (containing result data) returned by incoming
     *     activity result.
     */
    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.i(TAG, "onActivityResult() called!");
        super.onActivityResult(requestCode, resultCode, data);
        switch (requestCode) {
            case REQUEST_GOOGLE_PLAY_SERVICES:
                if (resultCode == RESULT_OK) {
                    refreshResults();
                } else {
                    isGooglePlayServicesAvailable();
                }
                break;
            case REQUEST_ACCOUNT_PICKER:
                if (resultCode == RESULT_OK && data != null && data.getExtras() != null) {
                    String accountName = data.getStringExtra(AccountManager.KEY_ACCOUNT_NAME);
                    if (accountName != null) {
                        credential.setSelectedAccountName(accountName);
                        SharedPreferences settings = getPreferences(Context.MODE_PRIVATE);
                        SharedPreferences.Editor editor = settings.edit();
                        editor.putString(PREF_ACCOUNT_NAME, accountName);
                        editor.commit();
                        refreshResults();
                    }
                } else if (resultCode == RESULT_CANCELED) {
                    mStatusText.setText("Google account unspecified.");
                }
                break;
            case REQUEST_AUTHORIZATION:
                Log.i(TAG, "onActivityResult(): requestCode was REQUEST_AUTHORIZATION");
                if (resultCode == RESULT_OK) {
                    refreshResults();
                }
                else {
                    chooseAccount();
                }
                break;
        }

        super.onActivityResult(requestCode, resultCode, data);
    }

    /**
     * Attempt to get a set of data from the Google Calendar API to display. If the
     * email address isn't known yet, then call chooseAccount() method so the
     * user can pick an account.
     */
    private void refreshResults() {
        //if there is no google acct selected, have user pick one now
        if (credential.getSelectedAccountName() == null) {
            chooseAccount();
        }

        //run the ApiAsyncTask
        else {
            if (isDeviceOnline()) {
                new ApiAsyncTask(this).execute();
            } else {
                mStatusText.setText("No network connection available.");
            }
        }
    }

    /**
     * Clear any existing Google Calendar API data from the TextView and update
     * the header message; called from background threads and async tasks
     * that need to update the UI (in the UI thread).
     */
    public void clearResultsText() {
        //clear the text fields to initial values
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mStatusText.setText("Retrieving calendar event data…");
                mResultsText.setText("");
            }
        });
    }

    /**
     * Fill the data TextView with the given List of Strings; called from
     * background threads and async tasks that need to update the UI (in the
     * UI thread).
     * @param dataStrings a List of Strings to populate the main TextView with.
     */
    public void updateResultsText(final List<String> dataStrings) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                //if string data found from checking calendar API for events came back null, something's wrong
                if (dataStrings == null) {
                    mStatusText.setText("There was an error retrieving the Google Calendar event data. Check the API authorization.");
                }

                //no events found
                else if (dataStrings.size() == 0) {
                    mStatusText.setText("No Calendar events found.");
                }

                //otherwise list all calendar events found, each on a new line
                else {
                    mStatusText.setText("Data retrieved using the Google Calendar API: ");
                    mResultsText.setText(TextUtils.join("\n\n", dataStrings));
                }
            }
        });
    }

    /**
     * Show a status message in the list header TextView; called from background
     * threads and async tasks that need to update the UI (in the UI thread).
     * @param message a String to display in the UI header TextView.
     */
    public void updateStatus(final String message) {
        runOnUiThread(new Runnable() {
            //update the status TextView with new status
            @Override
            public void run() {
                mStatusText.setText(message);
            }
        });
    }

    public void updateError(final String message) {
        runOnUiThread(new Runnable() {
            //update the status TextView with new status
            @Override
            public void run() {
                mErrorText.setText(message);
            }
        });
    }

    /**
     * Starts an activity in Google Play Services so the user can pick an
     * account.
     */
    private void chooseAccount() {
        startActivityForResult(credential.newChooseAccountIntent(), REQUEST_ACCOUNT_PICKER);
    }

    /**
     * Checks whether the device currently has a network connection.
     * @return true if the device has a network connection, false otherwise.
     */
    private boolean isDeviceOnline() {
        ConnectivityManager connMgr = (ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo networkInfo = connMgr.getActiveNetworkInfo();
        return (networkInfo != null && networkInfo.isConnected());
    }

    /**
     * Check that Google Play services APK is installed and up to date. Will
     * launch an error dialog for the user to update Google Play Services if
     * possible.
     * @return true if Google Play Services is available and up to
     *     date on this device; false otherwise.
     */
    private boolean isGooglePlayServicesAvailable() {
        final int connectionStatusCode =
                GooglePlayServicesUtil.isGooglePlayServicesAvailable(this);
        if (GooglePlayServicesUtil.isUserRecoverableError(connectionStatusCode)) {
            showGooglePlayServicesAvailabilityErrorDialog(connectionStatusCode);
            return false;
        } else if (connectionStatusCode != ConnectionResult.SUCCESS ) {
            return false;
        }
        return true;
    }

    /**
     * Display an error dialog showing that Google Play Services is missing
     * or out of date.
     * @param connectionStatusCode code describing the presence (or lack of)
     *     Google Play Services on this device.
     */
    void showGooglePlayServicesAvailabilityErrorDialog(
            final int connectionStatusCode) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Dialog dialog = GooglePlayServicesUtil.getErrorDialog(
                        connectionStatusCode,
                        MainActivity.this,
                        REQUEST_GOOGLE_PLAY_SERVICES);
                dialog.show();
            }
        });
    }
}