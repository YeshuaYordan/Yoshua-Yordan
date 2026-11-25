package arcanefusion.app;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

import androidx.annotation.NonNull;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.UserMessagingPlatform;

import java.util.concurrent.atomic.AtomicBoolean;

/** AdMob rewarded ads for the game, exposed as window.AndroidAds. Asks for consent first (UMP, required in the EEA/UK). */
public class AdsBridge {
    private final Activity act;
    private final WebView web;
    private final String unitId;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final ConsentInformation consent;
    private final AtomicBoolean started = new AtomicBoolean(false);
    private RewardedAd ad;
    private boolean loading = false;
    private int failures = 0;

    public AdsBridge(Activity act, WebView web) {
        this.act = act;
        this.web = web;
        this.unitId = act.getString(R.string.admob_rewarded_id);
        consent = UserMessagingPlatform.getConsentInformation(act);
        ConsentRequestParameters params = new ConsentRequestParameters.Builder().build();
        consent.requestConsentInfoUpdate(act, params,
                () -> UserMessagingPlatform.loadAndShowConsentFormIfRequired(act, err -> { if (consent.canRequestAds()) startAds(); }),
                err -> { if (consent.canRequestAds()) startAds(); });
        if (consent.canRequestAds()) startAds();
    }

    private void startAds() {
        if (!started.compareAndSet(false, true)) return;
        new Thread(() -> MobileAds.initialize(act, s -> main.post(this::load))).start();
    }

    private void load() {
        if (loading || ad != null || !consent.canRequestAds()) return;
        loading = true;
        RewardedAd.load(act, unitId, new AdRequest.Builder().build(), new RewardedAdLoadCallback() {
            @Override public void onAdLoaded(@NonNull RewardedAd a) { ad = a; loading = false; failures = 0; }
            @Override public void onAdFailedToLoad(@NonNull LoadAdError e) {
                ad = null; loading = false; failures++;
                main.postDelayed(AdsBridge.this::load, Math.min(300000, 15000L * failures)); // retry later, slower each time
            }
        });
    }

    private void done(String key, boolean ok) {
        final String js = "window.__adDone&&__adDone(" + org.json.JSONObject.quote(key) + "," + ok + ")";
        main.post(() -> web.evaluateJavascript(js, null));
    }

    /** Shows a rewarded ad; reports __adDone(key, true) only when the reward was earned. */
    @JavascriptInterface
    public void show(final String key) {
        main.post(() -> {
            if (ad == null) { done(key, false); load(); return; }
            final boolean[] earned = { false };
            final RewardedAd a = ad;
            ad = null;
            a.setFullScreenContentCallback(new FullScreenContentCallback() {
                @Override public void onAdDismissedFullScreenContent() { done(key, earned[0]); load(); }
                @Override public void onAdFailedToShowFullScreenContent(@NonNull AdError e) { done(key, false); load(); }
            });
            a.show(act, item -> earned[0] = true);
        });
    }

    /** True when the player must be able to change their ad consent (shown as "Ad privacy choices" in Settings). */
    @JavascriptInterface
    public boolean privacyRequired() {
        return consent.getPrivacyOptionsRequirementStatus() == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED;
    }

    @JavascriptInterface
    public void showPrivacy() {
        main.post(() -> UserMessagingPlatform.showPrivacyOptionsForm(act, err -> { if (consent.canRequestAds()) startAds(); }));
    }
}
