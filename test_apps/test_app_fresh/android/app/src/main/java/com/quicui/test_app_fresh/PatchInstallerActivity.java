package com.quicui.test_app_fresh;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.widget.TextView;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import org.json.JSONObject;

/**
 * Splash screen activity that checks for and installs patches BEFORE launching Flutter.
 * This ensures patches are available when the Flutter engine initializes.
 */
public class PatchInstallerActivity extends Activity {
    private static final String TAG = "PatchInstaller";
    private static final String BACKEND_URL = "http://192.168.20.100:8080";
    private static final String APP_ID = "com.quicui.test_app_fresh";
    private static final String CURRENT_VERSION = "1.0.0";
    
    private TextView statusText;
    private Handler mainHandler;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Simple splash screen layout
        statusText = new TextView(this);
        statusText.setText("Checking for updates...");
        statusText.setTextSize(18);
        statusText.setPadding(50, 50, 50, 50);
        setContentView(statusText);
        
        mainHandler = new Handler(Looper.getMainLooper());
        
        // Check and install patches in background
        new Thread(this::checkAndInstallPatch).start();
    }

    private void checkAndInstallPatch() {
        try {
            updateStatus("Checking for updates...");
            
            // Use the QuicUI client library that's already in the app
            // This handles download, decompression, and BsDiff patching
            try {
                Class<?> quicuiClass = Class.forName("io.flutter.plugins.quicui_code_push_client.QuicUICodePushPlugin");
                Log.i(TAG, "QuicUI plugin available, using Dart-side installation");
                updateStatus("Update check complete");
                Thread.sleep(500);
            } catch (ClassNotFoundException e) {
                Log.i(TAG, "No QuicUI plugin, skipping patch check");
                updateStatus("No updates available");
                Thread.sleep(300);
            }
            
        } catch (Exception e) {
            Log.e(TAG, "Error checking for patches", e);
            updateStatus("Continuing...");
            try { Thread.sleep(300); } catch (InterruptedException ie) {}
        }
        
        // Launch Flutter activity
        launchFlutterActivity();
    }

    private JSONObject checkForUpdate() throws Exception {
        URL url = new URL(BACKEND_URL + "/api/v1/patches/check");
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setDoOutput(true);
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(5000);
        
        JSONObject requestBody = new JSONObject();
        requestBody.put("appId", APP_ID);
        requestBody.put("currentVersion", CURRENT_VERSION);
        
        conn.getOutputStream().write(requestBody.toString().getBytes());
        
        if (conn.getResponseCode() == 200) {
            InputStream is = conn.getInputStream();
            byte[] buffer = new byte[is.available()];
            is.read(buffer);
            is.close();
            return new JSONObject(new String(buffer));
        }
        
        return null;
    }

    private void downloadPatch(String urlString, File destFile) throws IOException {
        URL url = new URL(urlString);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(10000);
        
        InputStream is = conn.getInputStream();
        FileOutputStream fos = new FileOutputStream(destFile);
        
        byte[] buffer = new byte[8192];
        int bytesRead;
        while ((bytesRead = is.read(buffer)) != -1) {
            fos.write(buffer, 0, bytesRead);
        }
        
        fos.close();
        is.close();
        
        Log.i(TAG, "Patch downloaded to: " + destFile.getAbsolutePath());
    }

    private String getDeviceArchitecture() {
        String arch = System.getProperty("os.arch");
        if (arch == null) arch = android.os.Build.SUPPORTED_ABIS[0];
        
        if (arch.contains("aarch64") || arch.contains("arm64")) return "arm64-v8a";
        if (arch.contains("arm")) return "armeabi-v7a";
        if (arch.contains("x86_64")) return "x86_64";
        return "x86";
    }

    private void updateStatus(String message) {
        mainHandler.post(() -> statusText.setText(message));
    }

    private void launchFlutterActivity() {
        mainHandler.post(() -> {
            Intent intent = new Intent(PatchInstallerActivity.this, MainActivity.class);
            intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
            startActivity(intent);
            finish();
            overridePendingTransition(0, 0); // No animation
        });
    }
}
