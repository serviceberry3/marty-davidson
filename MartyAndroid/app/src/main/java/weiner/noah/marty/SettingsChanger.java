package weiner.noah.marty;

import android.app.NotificationManager;
import android.content.Context;
import android.util.Log;

public class SettingsChanger {
    private static final String TAG = "SettingsChanger";

    public static boolean shutOffDoNotDist(MainActivity mainActivity) {
        NotificationManager mNotificationManager = (NotificationManager) mainActivity.getSystemService(Context.NOTIFICATION_SERVICE);

        //turn dnd OFF
        mNotificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL);

        return true;
    }

    public static boolean doNotDistIsOn(MainActivity mainActivity) {
        NotificationManager mNotificationManager = (NotificationManager) mainActivity.getSystemService(Context.NOTIFICATION_SERVICE);
        int currInterruptionFilter = mNotificationManager.getCurrentInterruptionFilter();

        Log.i(TAG, "doNotDistIsOn(): The current interruption filter is " + currInterruptionFilter);

        //return bool: true if do not disturb is currently ON
        return (currInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_NONE || currInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_PRIORITY);
    }
}
