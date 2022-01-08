package weiner.noah.marty;

import android.provider.BaseColumns;

public final class BuddyListContract {
    //create buddy table
    public static final String SQL_CREATE_ENTRIES =
            "CREATE TABLE " + BuddyListEntry.TABLE_NAME + " (" +
                    BuddyListEntry._ID + " INTEGER PRIMARY KEY," +
                    BuddyListEntry.FIRST_COL_NAME + " TEXT," +
                    BuddyListEntry.SECOND_COL_NAME + " TEXT," +
                    BuddyListEntry.THIRD_COL_NAME + " INTEGER," +
                    BuddyListEntry.FOURTH_COL_NAME + " BIGINT" +
                    ")";

    //delete buddy table
    public static final String SQL_DELETE_ENTRIES = "DROP TABLE IF EXISTS " + BuddyListEntry.TABLE_NAME;

    // To prevent someone from accidentally instantiating the contract class,
    // make the constructor private.
    private BuddyListContract() {}

    // Inner class that defines the table contents
    public static class BuddyListEntry implements BaseColumns {
        public static final String TABLE_NAME = "buddy";
        public static final String FIRST_COL_NAME = "number";
        public static final String SECOND_COL_NAME = "name";
        public static final String THIRD_COL_NAME = "state";
        public static final String FOURTH_COL_NAME = "time";
    }
}
