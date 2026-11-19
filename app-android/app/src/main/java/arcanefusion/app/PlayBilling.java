package arcanefusion.app;

import android.app.Activity;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;

import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.ConsumeParams;
import com.android.billingclient.api.PendingPurchasesParams;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.QueryProductDetailsParams;
import com.android.billingclient.api.QueryPurchasesParams;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

// Google Play Billing for the game. The page calls AndroidBilling.buy(productId, key); when Play confirms the
// payment the game is told through window.__purchaseDone(key, true). Gem packs are consumed (they can be bought
// again); Specials, 2x Speed and the Beginner Deal are one-time items (acknowledged, kept for good).
// At start-up, purchases Play still holds are handed to window.__grantOwned(productId): one that finished while
// the game was closed, or one-time items after a reinstall (the game skips anything it already owns).
public class PlayBilling implements PurchasesUpdatedListener {
    private final Activity act;
    private final WebView web;
    private final BillingClient client;
    private final Map<String, String> waiting = new ConcurrentHashMap<>();   // productId -> the page's callback key
    private volatile boolean pageReady = false;

    PlayBilling(Activity act, WebView web) {
        this.act = act;
        this.web = web;
        client = BillingClient.newBuilder(act)
                .setListener(this)
                .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
                .build();
        connect();
    }

    private static boolean oneTime(String id) {
        return id.startsWith("special_") || id.equals("speed_2x") || id.equals("starter_deal") || id.equals("no_ads");
    }

    private void connect() {
        client.startConnection(new BillingClientStateListener() {
            @Override public void onBillingSetupFinished(BillingResult r) {
                if (r.getResponseCode() == BillingClient.BillingResponseCode.OK && pageReady) restore();
            }
            @Override public void onBillingServiceDisconnected() { /* reconnects on the next purchase */ }
        });
    }

    // Called when the game page has loaded.
    void onPageReady() {
        pageReady = true;
        if (client.isReady()) restore();
    }

    @JavascriptInterface
    public void buy(final String productId, final String key) {
        act.runOnUiThread(() -> launch(productId, key));
    }

    private void launch(String productId, String key) {
        if (!client.isReady()) { connect(); done(key, false); return; }
        QueryProductDetailsParams params = QueryProductDetailsParams.newBuilder()
                .setProductList(Collections.singletonList(QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(productId).setProductType(BillingClient.ProductType.INAPP).build()))
                .build();
        client.queryProductDetailsAsync(params, (r, list) -> act.runOnUiThread(() -> {
            if (r.getResponseCode() != BillingClient.BillingResponseCode.OK || list == null || list.isEmpty()) { done(key, false); return; }
            ProductDetails pd = list.get(0);
            BillingFlowParams flow = BillingFlowParams.newBuilder()
                    .setProductDetailsParamsList(Collections.singletonList(
                            BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(pd).build()))
                    .build();
            waiting.put(productId, key);
            BillingResult res = client.launchBillingFlow(act, flow);
            if (res.getResponseCode() != BillingClient.BillingResponseCode.OK) { waiting.remove(productId); done(key, false); }
        }));
    }

    @Override
    public void onPurchasesUpdated(BillingResult r, List<Purchase> purchases) {
        if (r.getResponseCode() == BillingClient.BillingResponseCode.OK && purchases != null) {
            for (Purchase p : purchases) handle(p);
        } else {
            // Cancelled or failed: every open request answers "no".
            for (String key : waiting.values()) done(key, false);
            waiting.clear();
        }
    }

    private void handle(Purchase p) {
        if (p.getProducts().isEmpty()) return;
        final String id = p.getProducts().get(0);
        final String key = waiting.remove(id);
        if (p.getPurchaseState() != Purchase.PurchaseState.PURCHASED) {   // pending (e.g. cash payment): delivered on a later start-up
            if (key != null) done(key, false);
            return;
        }
        final Runnable grant = () -> { if (key != null) done(key, true); else js("window.__grantOwned&&__grantOwned('" + id + "')"); };
        if (oneTime(id)) {
            if (p.isAcknowledged()) { grant.run(); return; }
            client.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(p.getPurchaseToken()).build(), res -> {
                if (res.getResponseCode() == BillingClient.BillingResponseCode.OK) grant.run();
                else if (key != null) done(key, false);
            });
        } else {
            // Consume first, then grant, so a gem pack is never handed out twice.
            client.consumeAsync(ConsumeParams.newBuilder().setPurchaseToken(p.getPurchaseToken()).build(), (res, token) -> {
                if (res.getResponseCode() == BillingClient.BillingResponseCode.OK) grant.run();
                else if (key != null) done(key, false);
            });
        }
    }

    // Purchases Play still holds: unconsumed gem packs and owned one-time items.
    private void restore() {
        client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build(),
                (r, list) -> { if (r.getResponseCode() == BillingClient.BillingResponseCode.OK && list != null) for (Purchase p : list) handle(p); });
    }

    private void done(String key, boolean ok) {
        js("window.__purchaseDone&&__purchaseDone('" + key + "'," + ok + ")");
    }

    private void js(final String code) {
        act.runOnUiThread(() -> web.evaluateJavascript(code, null));
    }

    void destroy() { client.endConnection(); }
}
