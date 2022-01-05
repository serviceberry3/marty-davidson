package weiner.noah.marty;

public class MartyDavidson {
    private MartyState currState = MartyState.IDLE;

    public MartyDavidson() {

    }

    public void setState(MartyState state) {
        currState = state;
    }

    public MartyState getState() {
        return currState;
    }
}
