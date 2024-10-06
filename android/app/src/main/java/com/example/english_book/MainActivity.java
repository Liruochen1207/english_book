package com.example.english_book;

import android.net.Uri;
import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import java.io.File;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.fileprovider";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("getFileUri")) {
                        String filePath = call.argument("filePath");
                        if (filePath != null) {
                            Uri uri = getFileUri(filePath);
                            result.success(uri.toString());
                        } else {
                            result.error("UNAVAILABLE", "File path not available.", null);
                        }
                    } else {
                        result.notImplemented();
                    }
                });
    }

    private Uri getFileUri(String filePath) {
        File file = new File(filePath);
        return FileProvider.getUriForFile(this, getApplicationContext().getPackageName() + ".fileprovider", file);
    }
}
