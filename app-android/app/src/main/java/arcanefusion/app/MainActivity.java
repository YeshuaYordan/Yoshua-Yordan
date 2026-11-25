package arcanefusion.app;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import androidx.webkit.WebViewAssetLoader;

public class MainActivity extends Activity {
    private WebView web;
    private PlayBilling billing;
    private PlayGamesBridge games;
    private AdsBridge ads;
    private float safeTop = 0;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        final WebViewAssetLoader loader = new WebViewAssetLoader.Builder()
                .addPathHandler("/assets/", new WebViewAssetLoader.AssetsPathHandler(this))
                .build();
        web = new WebView(this);
        web.setBackgroundColor(0xff000000);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setTextZoom(100);
        s.setAllowFileAccess(false);
        s.setAllowContentAccess(false);
        web.setWebViewClient(new WebViewClient() {
            @Override
            public WebResourceResponse shouldInterceptRequest(WebView v, WebResourceRequest r) {
                return loader.shouldInterceptRequest(r.getUrl());
            }
            @Override
            public void onPageFinished(WebView v, String url) { sendSafeTop(); if (billing != null) billing.onPageReady(); if (games != null) games.notifyPage(); }
            @Override
            public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest r) {
                return !"appassets.androidplatform.net".equals(r.getUrl().getHost());
            }
        });
        billing = new PlayBilling(this, web);
        web.addJavascriptInterface(billing, "AndroidBilling");
        games = new PlayGamesBridge(this, web);
        web.addJavascriptInterface(games, "AndroidGames");
        ads = new AdsBridge(this, web);
        web.addJavascriptInterface(ads, "AndroidAds");
        // Android 13+ back gesture (predictive back is on by default when targeting Android 16): send the game to the background
        if (android.os.Build.VERSION.SDK_INT >= 33)
            getOnBackInvokedDispatcher().registerOnBackInvokedCallback(android.window.OnBackInvokedDispatcher.PRIORITY_DEFAULT, () -> moveTaskToBack(true));
        web.setOnApplyWindowInsetsListener((v, insets) -> {
            int top = 0;
            if (android.os.Build.VERSION.SDK_INT >= 28 && insets.getDisplayCutout() != null) top = insets.getDisplayCutout().getSafeInsetTop();
            safeTop = top / getResources().getDisplayMetrics().density;
            sendSafeTop();
            return v.onApplyWindowInsets(insets);
        });
        setContentView(web);
        hideBars();
        if (state != null) web.restoreState(state);
        else web.loadUrl("https://appassets.androidplatform.net/assets/game/index.html");
    }

    private void hideBars() {
        if (android.os.Build.VERSION.SDK_INT >= 30) {
            WindowInsetsController c = getWindow().getInsetsController();
            if (c != null) {
                c.hide(WindowInsets.Type.systemBars());
                c.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
            }
        } else {
            getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    | View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    | View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
        }
    }

    private void sendSafeTop() { web.evaluateJavascript("window.setSafeTop&&setSafeTop(" + safeTop + ")", null); }

    @Override public void onWindowFocusChanged(boolean has) { super.onWindowFocusChanged(has); if (has) hideBars(); }
    @Override protected void onPause() { super.onPause(); web.evaluateJavascript("window.setAway&&setAway(true)", null); web.onPause(); }
    @Override protected void onResume() { super.onResume(); web.onResume(); web.evaluateJavascript("window.setAway&&setAway(false)", null); hideBars(); }
    @Override protected void onSaveInstanceState(Bundle out) { super.onSaveInstanceState(out); web.saveState(out); }
    @Override public void onBackPressed() { moveTaskToBack(true); }
    @Override protected void onDestroy() { if (billing != null) billing.destroy(); web.destroy(); super.onDestroy(); }
}
