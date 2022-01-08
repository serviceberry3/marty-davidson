package weiner.noah.marty;

import android.os.AsyncTask;
import android.util.Log;

import com.google.api.client.googleapis.extensions.android.gms.auth.GooglePlayServicesAvailabilityIOException;
import com.google.api.client.googleapis.extensions.android.gms.auth.UserRecoverableAuthIOException;
import com.google.api.client.util.DateTime;
import com.google.api.services.calendar.model.Event;
import com.google.api.services.calendar.model.Events;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class ApiAsyncTask extends AsyncTask {
    private final MainActivity mActivity;
    private final String TAG = "ApiAsyncTask";

    /**
     * Constructor.
     * @param activity MainActivity that spawned this task.
     */
    ApiAsyncTask(MainActivity activity) {
        this.mActivity = activity;
    }

    /**
     * Background task to call Google Calendar API.
     * @param objects no parameters needed for this task.
     */
    @Override
    protected Object doInBackground(Object[] objects) {

        //clear out the current results TextView to prepare for updated text
        mActivity.clearResultsText();

        //update the results with the Calendar Event data retrieved via the API
        mActivity.updateResultsText(getDataFromApi());

        return null;
    }

    /**
     * Fetch a list of the next 10 events from the primary calendar.
     * @return List of Strings describing returned events.
     */
    private List<String> getDataFromApi() {
        //List the next 10 events from the primary calendar

        //record current date and time
        DateTime now = new DateTime(System.currentTimeMillis());
        Log.i(TAG, "Current DateTime when retrieving Calendar event data is: " + now);

        //create new ArrayList to hold the retrieved Events
        List<String> eventStrings = new ArrayList<>();

        Events events = null;

        try {
            events = mActivity.mService.events().list("Birthdays")
                    .setMaxResults(10) //get 10 next Calendar events, max
                    .setTimeMin(now) //set earliest datetime desired to filter events
                    .setOrderBy("startTime") //order events by starting time
                    .setSingleEvents(true)
                    .execute(); //execute API query request
        }

        //Google Play services unavailable on the device, display error msg
        catch (final GooglePlayServicesAvailabilityIOException availabilityException) {
            mActivity.showGooglePlayServicesAvailabilityErrorDialog(availabilityException.getConnectionStatusCode());
        }

        //need authorization, restart MainActivity and ask for it
        catch (UserRecoverableAuthIOException userRecoverableException) {
            mActivity.startActivityForResult(userRecoverableException.getIntent(), MainActivity.REQUEST_AUTHORIZATION);
        }

        //catch IO exception
        catch (IOException e) {
            mActivity.updateError("The following IOException error occurred: " + e.getCause());
            e.printStackTrace();
            //mActivity.startActivityForResult(new Intent(), MainActivity.REQUEST_AUTHORIZATION);
        }

        if (events == null) {
            //mActivity.updateStatus("The calendar events list came back null. There's a problem.");
            return null;
        }
        List<Event> items = events.getItems();

        for (Event event : items) {
            DateTime start = event.getStart().getDateTime();
            if (start == null) {
                //all-day events don't have start times, so just use the start date.
                start = event.getStart().getDate();
            }
            eventStrings.add(String.format("%s (%s)", event.getSummary(), start));
        }

        return eventStrings;
    }
}
