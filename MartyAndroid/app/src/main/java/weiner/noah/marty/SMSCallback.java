package weiner.noah.marty;

import android.content.ContentValues;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.net.Uri;
import android.provider.BaseColumns;
import android.provider.ContactsContract;
import android.telephony.SmsManager;
import android.util.Log;
import android.widget.Toast;

import java.util.ArrayList;

public class SMSCallback {
    //static SuccessCallback<String> onSuccess;
    //static FailureCallback onFail;

    private static final String TAG = "SMSCallback";
    private static final SmsManager smsManager = SmsManager.getDefault();


    //check if a passed buddy is already in the db
    public static boolean buddyInList(SQLiteDatabase db, String offendingBuddy) {
        //Define a projection that specifies which cols from db will actually use after query
        String[] projection = {
                BuddyListContract.BuddyListEntry.FIRST_COL_NAME,
        };

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
        } catch (Exception e) {
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

        //check if user is already in buddy list. If not, add them to the buddy list and send intro text
        switch (lowerCaseMsg) {
            case "opt in":
                Log.i(TAG, "Triggered");
                if (buddyInList(mainActivity.readDb, sender)) {
                    sendAlreadyInListMsg(sender, contactName);
                }
                else {
                    addBuddy(mainActivity.writeDb, sender, contactName);
                    sendIntroMsg(sender, contactName);
                }
                break;
            case "nudge":
                if (marty.getState() == MartyState.ACCEPTINGDNDNUDGE) {
                    if (SettingsChanger.shutOffDoNotDist(mainActivity)) {
                        marty.setState(MartyState.IDLE);
                        sendNudgeSuccessMsg(sender);
                    }
                }
                break;
            case "opt out":
                if (buddyInList(mainActivity.readDb, sender)) {
                    removeBuddy(mainActivity.readDb, sender);
                    sendGoodbyeMsg(sender, contactName);
                }
                break;
        }

        Log.i(TAG, "'" + sms + "'" +  " sent from " + sender + ", whose contact name is " + contactName);
    }

    public static void smsReceiveError(Exception err) {
    }

    public static void sendMsg(String text, String recipient) {
        ArrayList<String> messagePieces = smsManager.divideMessage(text);
        smsManager.sendMultipartTextMessage(recipient, null, messagePieces, null, null);
    }
}
