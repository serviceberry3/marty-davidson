package weiner.noah.marty;

import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Intent;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.net.Uri;
import android.provider.BaseColumns;
import android.provider.CalendarContract;
import android.provider.ContactsContract;
import android.telephony.SmsManager;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import java.sql.Time;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.TimeZone;

public class SMSCallback {
    //static SuccessCallback<String> onSuccess;
    //static FailureCallback onFail;

    private static final String TAG = "SMSCallback";
    private static final SmsManager smsManager = SmsManager.getDefault();

    private static Calendar dateHolder = Calendar.getInstance();
    private static int yearHolder;
    private static int monthHolder;
    private static int dayHolder;
    private static int hourHolder;
    private static int minuteHolder;
    private static long dateHolderMillis;

    private static final int calendarID = 10;

    //check if a passed buddy is already in the db
    public static boolean buddyInList(SQLiteDatabase db, String offendingBuddy) {
        //Define a projection that specifies which cols from db will actually use after query
        String[] projection = {
                BuddyListContract.BuddyListEntry.FIRST_COL_NAME,
        };;

        //Filter results WHERE number = offendingBuddy
        String selection = BuddyListContract.BuddyListEntry.FIRST_COL_NAME + " = ?";
        String[] selectionArgs = {offendingBuddy};

        //how want the results sorted in the resulting Cursor
        String sortOrder = BuddyListContract.BuddyListEntry.FIRST_COL_NAME + " DESC";

        Cursor cursor = db.query(
                BuddyListContract.BuddyListEntry.TABLE_NAME,   //table to query
                projection,             //array of columns to return (pass null to get all)
                selection,              //columns for the WHERE clause
                selectionArgs,          //values for the WHERE clause
                null,                   //don't group the rows
                null,                   //don't filter by row groups
                sortOrder               //sort order
        );

        //return true if the number was found in db (buddy is in db already), else return false
        return (cursor.getCount() != 0);
    }

    //add a new buddy to the buddy list
    public static void addBuddy(SQLiteDatabase db, String offendingBuddyNumber, String offendingBuddyName) {
        //Create a new map of values, where column names are the keys
        ContentValues values = new ContentValues();
        values.put(BuddyListContract.BuddyListEntry.FIRST_COL_NAME, offendingBuddyNumber);
        values.put(BuddyListContract.BuddyListEntry.SECOND_COL_NAME, offendingBuddyName);
        values.put(BuddyListContract.BuddyListEntry.THIRD_COL_NAME, MartyState.IDLE.ordinal());

        Log.i(TAG, "Adding new buddy to db with number " + offendingBuddyNumber + ", name " + offendingBuddyName + ", and state ID " +
                values.get(BuddyListContract.BuddyListEntry.THIRD_COL_NAME));

        //insert the new row, returning the primary key value of the new row
        long newRowId = db.insert(BuddyListContract.BuddyListEntry.TABLE_NAME, null, values);
    }

    //remove buddy from list
    public static void removeBuddy(SQLiteDatabase db, String offendingBuddyNumber) {
        //define column to match with WHERE
        String selection = BuddyListContract.BuddyListEntry.FIRST_COL_NAME + " LIKE ?";

        //specify buddy number to match
        String[] selectionArgs = {offendingBuddyNumber};

        //issue the actual sql statement: DELETE from BUDDY where number LIKE [offendingBuddyNumber]
        int deletedRows = db.delete(BuddyListContract.BuddyListEntry.TABLE_NAME, selection, selectionArgs);
    }

    public static void setBuddyInfo(SQLiteDatabase db, String offendingBuddyNumber, String colToSet, Object newInfo) {
        if (!buddyInList(db, offendingBuddyNumber)) {
            Log.e(TAG, "setBuddyState(): passed buddy not even in list!!");
            return;
        }

        String newPhoneNum;
        String newName;
        int newState;
        long newTime;

        //create ContentValues and put entry with key "state" and value of the new state number
        ContentValues values = new ContentValues();

        //select row: WHERE number LIKE [offendingBuddyNumber]
        String selection = BuddyListContract.BuddyListEntry.FIRST_COL_NAME + " LIKE ?";
        String[] selectionArgs = {offendingBuddyNumber};

        //decide cast for the info
        switch (colToSet) {
            case BuddyListContract.BuddyListEntry.FIRST_COL_NAME:
                newPhoneNum = (String) newInfo;
                values.put(colToSet, newPhoneNum);
                break;
            case BuddyListContract.BuddyListEntry.SECOND_COL_NAME:
                newName = (String) newInfo;
                values.put(colToSet, newName);
                break;
            case BuddyListContract.BuddyListEntry.THIRD_COL_NAME:
                newState = (int) newInfo;
                values.put(colToSet, newState);
                break;
            case BuddyListContract.BuddyListEntry.FOURTH_COL_NAME:
                newTime = (long) newInfo;
                values.put(colToSet, newTime);
                break;
        }

        //issue the actual sql statement: UPDATE buddy SET state = [new state num] WHERE number LIKE [buddy's phone num]
        int count = db.update(
                BuddyListContract.BuddyListEntry.TABLE_NAME,
                values,
                selection,
                selectionArgs);
    }

    public static Object getBuddyInfo(SQLiteDatabase db, String offendingBuddyNumber, String colToGet) {
        if (!buddyInList(db, offendingBuddyNumber)) {
            Log.e(TAG, "getBuddyState(): passed buddy not even in list!!");
            return -1;
        }

        //Define a projection that specifies which cols from db will actually use after query
        String[] projection = {
                colToGet,
        };;

        //Filter results WHERE number = offendingBuddy
        String selection = BuddyListContract.BuddyListEntry.FIRST_COL_NAME + " = ?";
        String[] selectionArgs = {offendingBuddyNumber};

        //how want the results sorted in the resulting Cursor
        String sortOrder = BuddyListContract.BuddyListEntry.FIRST_COL_NAME + " DESC";

        Cursor cursor = db.query(
                BuddyListContract.BuddyListEntry.TABLE_NAME,   //table to query
                projection,             //array of columns to return (pass null to get all)
                selection,              //columns for the WHERE clause
                selectionArgs,          //values for the WHERE clause
                null,                   //don't group the rows
                null,                   //don't filter by row groups
                sortOrder               //sort order
        );

        cursor.moveToFirst();
        switch (colToGet) {
            case BuddyListContract.BuddyListEntry.FIRST_COL_NAME:
            case BuddyListContract.BuddyListEntry.SECOND_COL_NAME:
                return cursor.getString(0);
            case BuddyListContract.BuddyListEntry.THIRD_COL_NAME:
                return cursor.getInt(0);
            case BuddyListContract.BuddyListEntry.FOURTH_COL_NAME:
                return cursor.getLong(0);
        }
        return null;
    }

    //let buddy know they've already opted in
    public static void sendAlreadyInListMsg(String offendingBuddy, String contactName) {
        String endearment = (contactName != null) ? ("Hey, " + contactName + "! ") : "Hey! ";

        sendMsg(endearment + StockMsgStrings.alreadyOptedInMsg, offendingBuddy);
    }

    public static void sendIntroMsg(String offendingBuddy, String contactName) {
        Log.i(TAG, "Sending intro msg... to " + offendingBuddy);

        String endearment = (contactName != null) ? ("Hi, " + contactName + "! ") : "Hi! ";

        sendMsg(endearment + StockMsgStrings.introText, offendingBuddy);
    }

    public static void sendMissedCallIntro(String offendingBuddy) {
        sendMsg(StockMsgStrings.missedCallIntro, offendingBuddy);
    }

    public static void sendNudgeSuccessMsg(String offendingBuddy) {
        sendMsg(StockMsgStrings.nudgeSuccess, offendingBuddy);
    }

    public static void sendGoodbyeMsg(String offendingBuddy, String contactName) {
        String endearment = (contactName != null) ? ("Thanks, " + contactName + "! ") : "Thanks! ";

        sendMsg(endearment + StockMsgStrings.goodByeMsg, offendingBuddy);
    }

    public static void sendMainMenu(String offendingBuddy, String contactName) {
        sendMsg(StockMsgStrings.currentRelease, offendingBuddy);
    }

    public static void addEventToCalendar(MainActivity mainActivity, String contactName, String emailAddress) {
        Log.i(TAG, "addEventToCalendar() called!");

        Uri uri1 = CalendarContract.Calendars.CONTENT_URI;
        String[] projection = new String[] {
                CalendarContract.Calendars._ID,
                CalendarContract.Calendars.ACCOUNT_NAME,
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                CalendarContract.Calendars.NAME,
                CalendarContract.Calendars.CALENDAR_COLOR
        };

        Cursor calendarCursor = mainActivity.managedQuery(uri1, projection, null, null, null);

        calendarCursor.moveToFirst();

        int count = calendarCursor.getCount();

        for (int j = 0; j < count; j++) {
            Log.i(TAG, "Calendar found: ID " + calendarCursor.getString(calendarCursor.getColumnIndex(CalendarContract.Calendars._ID)) +
                    ", ACCT_NAME " + calendarCursor.getString(calendarCursor.getColumnIndex(CalendarContract.Calendars.ACCOUNT_NAME)) +
                    ", CAL_DISPLAY_NAME " + calendarCursor.getString(calendarCursor.getColumnIndex(CalendarContract.Calendars.ACCOUNT_NAME)) +
                    ", CAL_NAME " + calendarCursor.getString(calendarCursor.getColumnIndex(CalendarContract.Calendars.NAME)));
            calendarCursor.moveToNext();
        }

        ContentResolver cr = mainActivity.getContentResolver();
        ContentValues values = new ContentValues();

        //Calendar class is abstr class that provides methods for converting between specific instant in time
        //and set of calendar fields like YEAR, MONTH, DAY_OF_MONTH, HOUR, etc,
        //and for manipulating calendar fields, like getting the date of the next week

        Long dtStart = dateHolderMillis;
        Long dtEnd = dtStart + 1000 * 60 * 60; //set meeting length to be 1 hour

        values.put(CalendarContract.Events.DTSTART, dtStart);
        values.put(CalendarContract.Events.DTEND, dtEnd);
        values.put(CalendarContract.Events.TITLE, "Meeting with Noah Weiner, courtesy of Marty Davidson");
        values.put(CalendarContract.Events.DESCRIPTION, "A one-hour meeting with Noah");
        TimeZone timeZone = TimeZone.getDefault();
        values.put(CalendarContract.Events.EVENT_TIMEZONE, timeZone.getID());

        //select appropriate calendar
        values.put(CalendarContract.Events.CALENDAR_ID, calendarID);

        //values.put(CalendarContract.Events.RRULE, "FREQ=DAILY;UNTIL=" + dtUntil);

        //event duration for 1 hour, and give it an alarm
        //values.put(CalendarContract.Events.DURATION, "+P1H");
        //values.put(CalendarContract.Events.HAS_ALARM, 1);

        //add event to the calendar (insert row into table at given URI)
        //return: URL of newly created row. May return null if the underlying content provider returns null, or if it crashes
        Uri uri = cr.insert(CalendarContract.Events.CONTENT_URI, values);

        Log.i(TAG, "cr return val was " + uri);

        long eventId = Long.parseLong(uri.getLastPathSegment());
        Log.i(TAG, "CREATED EVENT ID IS " + eventId);

        //get URI for event attendees table
        String attendeesUriString = "content://com.android.calendar/attendees";

        //To add multiple attendees need to insert ContentValues multiple times
        ContentValues attendeesValues = new ContentValues();

        attendeesValues.put("event_id", eventId);
        attendeesValues.put("attendeeName", contactName); //name of attendee
        attendeesValues.put("attendeeEmail", emailAddress); //Attendee
        attendeesValues.put("attendeeRelationship", 0); // Relationship_Attendee(1), Relationship_None(0), Organizer(2), Performer(3), Speaker(4)
        attendeesValues.put("attendeeType", 0); // None(0), Optional(1), Required(2), Resource(3)
        attendeesValues.put("attendeeStatus", 0); // NOne(0), Accepted(1), Decline(2), Invited(3), Tentative(4)

        //insert attendees into the table
        Uri attendeePutUri = cr.insert(Uri.parse(attendeesUriString), attendeesValues);

        /*
        eventValues.put("allDay", 1); //If it is bithday alarm or such kind (which should remind me for whole day) 0 for false, 1 for true
        eventValues.put("eventStatus", 0); // This information is sufficient for most entries tentative (0), confirmed (1) or canceled (2):
        eventValues.put("eventTimezone", "UTC/GMT +2:00");

        //Comment below visibility and transparency  column to avoid java.lang.IllegalArgumentException column visibility is invalid error
        //visibility to default (0), confidential (1), private (2), or public (3):
        //You can control whether an event consumes time opaque (0) or transparent (1).

        eventValues.put("hasAlarm", 1); // 0 for false, 1 for true

        //run insert
        Uri eventUri = mainActivity.getApplicationContext().getContentResolver().insert(Uri.parse(eventUriString), eventValues);
        long eventID = Long.parseLong(eventUri.getLastPathSegment());

        if (wantReminder) {
            //Event: Reminder(with alert) Adding reminder to event
            String reminderUriString = "content://com.android.calendar/reminders";

            ContentValues reminderValues = new ContentValues();

            reminderValues.put("event_id", eventID);
            reminderValues.put("minutes", 5); // Default value of the system. Minutes is integer
            reminderValues.put("method", 1); // Alert Methods: Default(0), Alert(1), Email(2), SMS(3)

            Uri reminderUri = mainActivity.getApplicationContext().getContentResolver().insert(Uri.parse(reminderUriString), reminderValues);
        }*/
    }

    public static void enterScheduler(SQLiteDatabase db, String offendingBuddy) {
        sendMsg(StockMsgStrings.scheduleInstr, offendingBuddy);
        setBuddyInfo(db, offendingBuddy, BuddyListContract.BuddyListEntry.THIRD_COL_NAME, MartyState.AWAITINGDATEENTRY.ordinal());
    }

    public static int checkCitaDate(String dateString) {
        //first, make sure date string is of correct length
        if (dateString.length() == 12) {
            //make sure every character in date is a digit
            for (int i = 0; i < 12; i++) {
                if (!Character.isDigit(dateString.charAt(i))) {
                    return -1;
                }
            }

            dateHolder.setLenient(false);

            yearHolder = Integer.parseInt(dateString.substring(0, 4));
            monthHolder = Integer.parseInt(dateString.substring(4, 6));
            dayHolder = Integer.parseInt(dateString.substring(6, 8));
            hourHolder = Integer.parseInt(dateString.substring(8, 10));
            minuteHolder = Integer.parseInt(dateString.substring(10, 12));

            Log.i(TAG, "User is requesting appointment with year " + yearHolder + ", month " + monthHolder +
                    ", day " + dayHolder + ", hour " + hourHolder + ", and minute " + minuteHolder);

            //next, test values of year, month, day, hour, minute to make sure they make sense
            dateHolder.set(yearHolder, monthHolder - 1, dayHolder, hourHolder, minuteHolder); //**Calendar defines month January as 0

            //get the date in milliseconds after epoch. If this throws exception, we know there's a problem with the values of the date
            try {
                dateHolderMillis = dateHolder.getTimeInMillis();
            }
            catch (IllegalArgumentException e) {
                Log.i(TAG, String.valueOf(e.getCause()));
                return -1;
            }

            return 0;
        }
        return -1;
    }

    public static void citaDateReceived(SQLiteDatabase db, String dateString, String offendingBuddy) {
        if (checkCitaDate(dateString) == 0) {
            sendMsg(StockMsgStrings.dateFormatAccepted, offendingBuddy);
            setBuddyInfo(db, offendingBuddy, BuddyListContract.BuddyListEntry.THIRD_COL_NAME, MartyState.DATEFORMATACCEPTED_AWAITINGEMAIL.ordinal());
        }
        else {
            sendMsg(StockMsgStrings.invalidDateMsg, offendingBuddy);
            //don't change state from AWAITINGDATEENTRY
        }
    }

    public static boolean isValidEmail(String email) {
        //check that the string isn't empty and that it matches an email address pattern
        return !TextUtils.isEmpty(email) && android.util.Patterns.EMAIL_ADDRESS.matcher(email).matches();
    }

    public static String getDate()
    {
        //Create a DateFormatter object for displaying date in specified format.
        SimpleDateFormat formatter = new SimpleDateFormat("EEE, MMM dd, yyyy, 'at' HH:mm");

        //Create a calendar object that will convert the date and time value in milliseconds to date.
        return formatter.format(dateHolder.getTime());
    }


    //the email address has been received. validate it and then add the calendar event and send confirmation text
    public static void terminarCita(MainActivity mainActivity, SQLiteDatabase db, String email, String offendingBuddyNumber, String contactName) {
        if (isValidEmail(email)) {
            sendMsg("Great, " + contactName + ". I've scheduled a one-hour appointment with you for " + getDate() + ". You should receive an" +
                    " email about it shortly. Seeya then! You should dress in formal attire and be punctual.", offendingBuddyNumber);
            addEventToCalendar(mainActivity, contactName, email);

            //reinitialize Marty state
            setBuddyInfo(db, offendingBuddyNumber, BuddyListContract.BuddyListEntry.THIRD_COL_NAME, MartyState.MARTY.ordinal());
        }
        else {
            sendMsg(StockMsgStrings.invalidEmailMsg, offendingBuddyNumber);
            //don't change state from DATERECEIVED
        }
    }

    public static void sendValentine(String offendingBuddyNumber, String contactName) {
        sendMsg("I " + StockMsgStrings.valenText + " " + contactName, offendingBuddyNumber);
    }

    public static void listMinions(SQLiteDatabase db, String offendingBuddyNumber) {
        //Define a projection that specifies which cols from db will actually use after query
        String[] projection = {
                BuddyListContract.BuddyListEntry.FIRST_COL_NAME, //phone number
                BuddyListContract.BuddyListEntry.SECOND_COL_NAME //name
        };

        //how want the results sorted in the resulting Cursor
        String sortOrder = BuddyListContract.BuddyListEntry.FIRST_COL_NAME + " DESC";

        Cursor cursor = db.query(
                BuddyListContract.BuddyListEntry.TABLE_NAME,   //table to query
                projection,             //array of columns to return (pass null to get all)
                null,              //columns for the WHERE clause
                null,          //values for the WHERE clause
                null,                   //don't group the rows
                null,                   //don't filter by row groups
                sortOrder               //sort order
        );

        cursor.moveToFirst();
        int count = cursor.getCount();

        sendMsg("I currently have " + count + " user(s) in my list:", offendingBuddyNumber);

        for (int i = 0; i < count; i++) {
            //send the buddy's name and number
            sendMsg(cursor.getString(cursor.getColumnIndex(BuddyListContract.BuddyListEntry.SECOND_COL_NAME)) +
                    " (" + cursor.getString(cursor.getColumnIndex(BuddyListContract.BuddyListEntry.FIRST_COL_NAME)) + ")",
                    offendingBuddyNumber);

            //move to next query result entry
            cursor.moveToNext();
        }
    }

    public static void urgentHandle(SQLiteDatabase db, String offendingBuddyNumber, String contactName) {
        if (System.currentTimeMillis() <= (long)getBuddyInfo(db, offendingBuddyNumber, BuddyListContract.BuddyListEntry.FOURTH_COL_NAME) + (1000 * 60)) {
            sendMsg("You have angered me, " + contactName + "!", offendingBuddyNumber);
        }
        else {
            sendMsg("My patience for your urgency has run out, " + contactName + ".", offendingBuddyNumber);
        }
    }

    public static String resolveContactName(MainActivity mainActivity, String number) {
        //create a URI by appending the phone num (as string) to the base URI for contacts
        Uri lookupUri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(number));

        //Cursor provides random read-write access to the result set returned by a database query
        //this queries the URI and returns a cursor over the result set.
        //second arg is list of which columns to return
        try (Cursor c = mainActivity.getContentResolver().query(lookupUri, new String[]{ContactsContract.Data.DISPLAY_NAME},
                null, null, null)) {
            //make sure cursor was created successfully
            assert c != null;

            //move cursor to beginning of content and get the string which corresponds to the contact name
            c.moveToFirst();
            return c.getString(0);
        }
        catch (Exception e) {
            //TODO: handle exception
            return null;
        }
    }

    //main entry point
    public static void smsReceived(MainActivity mainActivity, String sms, String sender) {
        MartyDavidson marty = mainActivity.myMarty;

        String lowerCaseMsg = sms.toLowerCase();

        //attempt to resolve the contact name corresponding to the sender number
        String contactName = resolveContactName(mainActivity, sender);

        //check if user is already in buddy list.
        boolean buddyInList = buddyInList(mainActivity.readDb, sender);

        Log.i(TAG, "'" + sms + "'" +  " sent from " + sender + ", whose contact name is " + contactName);

        switch (lowerCaseMsg) {
            case "opt in":
                //If user already in buddy list and wants to opt in, send error msg
                if (buddyInList) {
                    sendAlreadyInListMsg(sender, contactName);
                }
                //If user not in buddy list and wants to opt in, add them to the buddy list and send intro text
                else {
                    addBuddy(mainActivity.writeDb, sender, contactName);
                    sendIntroMsg(sender, contactName);
                }
                break;
            case "nudge":
                //if a call has been missed and the user wants to nudge, perform appropriate actions
                if (marty.getState() == MartyState.ACCEPTINGDNDNUDGE) {
                    //shut off do not disturb, and if successful, send success message to let them know to call again
                    if (SettingsChanger.shutOffDoNotDist(mainActivity)) {
                        marty.setState(MartyState.IDLE);
                        sendNudgeSuccessMsg(sender);
                    }
                }
                break;
            case "opt out":
                //if user is in buddy list and wants out, remove them
                if (buddyInList(mainActivity.readDb, sender)) {
                    removeBuddy(mainActivity.readDb, sender);
                    sendGoodbyeMsg(sender, contactName);
                }
                break;
        }

        //if the buddy is indeed in the list, check if they're trying to perform some marty actions
        if (buddyInList) {
            switch (lowerCaseMsg) {
                //no matter what, if the user invokes "marty" and is in the user list, reinitialize the FSM
                case "marty":
                    //set buddy's new state
                    setBuddyInfo(mainActivity.readDb, sender, BuddyListContract.BuddyListEntry.THIRD_COL_NAME, MartyState.MARTY.ordinal());
                    setBuddyInfo(mainActivity.readDb, sender, BuddyListContract.BuddyListEntry.FOURTH_COL_NAME, System.currentTimeMillis());

                    //send main Marty menu
                    sendMainMenu(sender, contactName);
                    break;
                case "cita":
                    //make sure user is currently in state MARTY, otherwise do nothing
                    if ((int)getBuddyInfo(mainActivity.readDb, sender, BuddyListContract.BuddyListEntry.THIRD_COL_NAME) == MartyState.MARTY.ordinal()) {
                        enterScheduler(mainActivity.readDb, sender);
                    }
                    break;
                case "valentine":
                    //make sure user is currently in state MARTY, otherwise do nothing
                    if ((int)getBuddyInfo(mainActivity.readDb, sender, BuddyListContract.BuddyListEntry.THIRD_COL_NAME) == MartyState.MARTY.ordinal()) {
                        sendValentine(sender, contactName);
                    }
                    break;
                case "minions":
                    //make sure user is currently in state MARTY, otherwise do nothing
                    if ((int)getBuddyInfo(mainActivity.readDb, sender, BuddyListContract.BuddyListEntry.THIRD_COL_NAME) == MartyState.MARTY.ordinal())  {
                        listMinions(mainActivity.readDb, sender);
                    }
                    break;
                case "urgent":
                    //make sure user is currently in state MARTY, otherwise do nothing
                    if ((int)getBuddyInfo(mainActivity.readDb, sender, BuddyListContract.BuddyListEntry.THIRD_COL_NAME) == MartyState.MARTY.ordinal())  {
                        urgentHandle(mainActivity.readDb, sender, contactName);
                    }
                    break;
                //if message text is something else, maybe it's a date string or email string for cita scheduler
                default:
                    //let's see if the Marty is indeed in the AWAITINGDATEENTRY state
                    if ((int)getBuddyInfo(mainActivity.readDb, sender, BuddyListContract.BuddyListEntry.THIRD_COL_NAME) ==
                            MartyState.AWAITINGDATEENTRY.ordinal())  {
                        //check format of date string and do processing
                        citaDateReceived(mainActivity.readDb, lowerCaseMsg, sender);
                    }
                    else if ((int)getBuddyInfo(mainActivity.readDb, sender, BuddyListContract.BuddyListEntry.THIRD_COL_NAME) ==
                            MartyState.DATEFORMATACCEPTED_AWAITINGEMAIL.ordinal())  {
                        //check format of email address and do processing
                        terminarCita(mainActivity, mainActivity.readDb, lowerCaseMsg, sender, contactName);
                    }
                    break;
                }
        }
    }

    public static void smsReceiveError(Exception err) {
    }

    public static void sendMsg(String text, String recipient) {
        ArrayList<String> messagePieces = smsManager.divideMessage(text);
        smsManager.sendMultipartTextMessage(recipient, null, messagePieces, null, null);
    }
}
