package weiner.noah.marty;

public class StockMsgStrings {
    public static final String introText = "I'm Marty, Noah's auto-reply bot. " +
            "It appears as though either we've never met, or my software has been updated since we last talked. " +
            "I've just added you to my list of users. To remove yourself from my list at any time, text me " +
            "\"opt out\". To opt back in after opting out, text me \"opt in\". " +
            "Try texting me \"marty\" to get started! And if I ever seem idle, just send " +
            "any message containing \"marty\" to wake me back up!";

    public static final String missedCallIntro = "Hi! It's Marty, Noah's auto-reply bot. It looks like you just tried calling Noah. " +
            "His phone is currently in Do Not Disturb mode. To disable Do Not Disturb and turn on the ringer, just text me \"nudge\".";

    public static final String nudgeSuccess = "I have disabled Do Not Disturb. The ringer is now on. Please try calling again.";

    public static final String alreadyOptedInMsg = "It's Marty. It looks like you already opted in. Many more features are coming soon!" +
            " For now, try texting me a message containing \"urgent\" within the next 60 seconds to really agitate me! Or text me a " +
            "message containing \"minions\" to fetch a list of all of the contacts on my list, along with their phone numbers.";

    public static final String goodByeMsg = "I have removed you from my list. Remember, to opt back in at any time, just text me any message containing \"opt in\". Seeya around!";
}
