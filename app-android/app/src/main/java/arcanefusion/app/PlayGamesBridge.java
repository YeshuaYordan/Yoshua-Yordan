package arcanefusion.app;

import android.app.Activity;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import com.google.android.gms.games.PlayGames;
import com.google.android.gms.games.PlayGamesSdk;
import com.google.android.gms.games.SnapshotsClient;
import com.google.android.gms.games.snapshot.Snapshot;
import com.google.android.gms.games.snapshot.SnapshotMetadataChange;

import org.json.JSONObject;

import java.nio.charset.StandardCharsets;

/** Google Play Games leaderboards and cloud save (Saved Games), exposed to the game as window.AndroidGames. */
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

    private static final String SAVE_NAME = "arcane_fusion_save";

    /** Uploads the game's save (JSON) to the player's Play Games account. */
    @JavascriptInterface
    public void cloudSave(final String json) {
        if (!configured() || !signedIn || json == null) return;
        act.runOnUiThread(() -> {
            SnapshotsClient sc = PlayGames.getSnapshotsClient(act);
            sc.open(SAVE_NAME, true, SnapshotsClient.RESOLUTION_POLICY_MOST_RECENTLY_MODIFIED).addOnSuccessListener(r -> {
                Snapshot snap = r.getData();
                if (snap == null) return;
                snap.getSnapshotContents().writeBytes(json.getBytes(StandardCharsets.UTF_8));
                sc.commitAndClose(snap, new SnapshotMetadataChange.Builder().setDescription("Arcane Fusion progress").build());
            });
        });
    }

    /** Loads the cloud save and hands it to the game as onCloudLoaded(json) ("" when there is none or it fails). */
    @JavascriptInterface
    public void cloudLoad() {
        if (!configured() || !signedIn) { reply(""); return; }
        act.runOnUiThread(() -> {
            SnapshotsClient sc = PlayGames.getSnapshotsClient(act);
            sc.open(SAVE_NAME, true, SnapshotsClient.RESOLUTION_POLICY_MOST_RECENTLY_MODIFIED).addOnCompleteListener(t -> {
                String json = "";
                try {
                    Snapshot snap = t.isSuccessful() ? t.getResult().getData() : null;
                    if (snap != null) { byte[] b = snap.getSnapshotContents().readFully(); if (b != null) json = new String(b, StandardCharsets.UTF_8); sc.discardAndClose(snap); }
                } catch (Exception e) { json = ""; }
                reply(json);
            });
        });
    }

    private void reply(String json) {
        final String js = "window.onCloudLoaded&&onCloudLoaded(" + JSONObject.quote(json) + ")";
        act.runOnUiThread(() -> web.evaluateJavascript(js, null));
    }
}
