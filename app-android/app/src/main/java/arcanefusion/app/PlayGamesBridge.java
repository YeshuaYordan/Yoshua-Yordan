package arcanefusion.app;

import android.app.Activity;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import com.google.android.gms.games.PlayGames;
import com.google.android.gms.games.PlayGamesSdk;

/** Google Play Games leaderboards, exposed to the game as window.AndroidGames. */
public class PlayGamesBridge {
    private static final int RC_BOARDS = 9004;
    private final Activity act;
    private final WebView web;
    private boolean signedIn = false;

    public PlayGamesBridge(Activity act, WebView web) {
        this.act = act;
        this.web = web;
        if (configured()) PlayGamesSdk.initialize(act);
        checkSignIn();
    }

    private boolean configured() {
        return !act.getString(R.string.game_services_project_id).isEmpty();
    }

    private String boardId(String key) {
        int res = "boss".equals(key) ? R.string.leaderboard_boss_break_out : R.string.leaderboard_best_wave;
        return act.getString(res);
    }

    private void checkSignIn() {
        if (!configured()) return;
        PlayGames.getGamesSignInClient(act).isAuthenticated().addOnCompleteListener(t -> {
            signedIn = t.isSuccessful() && t.getResult().isAuthenticated();
            notifyPage();
        });
    }

    /** Tell the page whether leaderboards can be used (it then submits its saved bests). */
    public void notifyPage() {
        final String js = "window.onGamesReady&&onGamesReady(" + (configured() && signedIn) + ")";
        act.runOnUiThread(() -> web.evaluateJavascript(js, null));
    }

    @JavascriptInterface
    public boolean available() { return configured(); }

    @JavascriptInterface
    public void submit(final String key, final double score) {
        if (!configured() || !signedIn) return;
        final String id = boardId(key);
        if (id.isEmpty()) return;
        act.runOnUiThread(() -> PlayGames.getLeaderboardsClient(act).submitScore(id, (long) score));
    }

    /** Opens Google's leaderboard screen (signs in first if needed). */
    @JavascriptInterface
    public void show() {
        if (!configured()) return;
        act.runOnUiThread(() -> {
            if (signedIn) { openBoards(); return; }
            PlayGames.getGamesSignInClient(act).signIn().addOnCompleteListener(t -> {
                signedIn = t.isSuccessful() && t.getResult().isAuthenticated();
                notifyPage();
                if (signedIn) openBoards();
                else web.evaluateJavascript("window.onGamesFail&&onGamesFail()", null);
            });
        });
    }

    private void openBoards() {
        PlayGames.getLeaderboardsClient(act).getAllLeaderboardsIntent()
                .addOnSuccessListener(i -> act.startActivityForResult(i, RC_BOARDS))
                .addOnFailureListener(e -> web.evaluateJavascript("window.onGamesFail&&onGamesFail()", null));
    }
}
