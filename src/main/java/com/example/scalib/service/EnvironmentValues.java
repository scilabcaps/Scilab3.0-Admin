package com.example.scalib.service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;

public final class EnvironmentValues {
    private static final Properties DOT_ENV = loadDotEnv();
    private static final Properties BUILT_IN = loadBuiltIn();

    private EnvironmentValues() {
    }

    public static String get(String key) {
        // 1. Check system environment variables
        String fromSystem = System.getenv(key);
        if (fromSystem != null && !fromSystem.isBlank()) {
            return fromSystem.trim();
        }

        // 2. Check .env file in runtime directories
        String fromDotEnv = DOT_ENV.getProperty(key);
        if (fromDotEnv != null && !fromDotEnv.isBlank()) {
            return fromDotEnv.trim();
        }

        // 3. Check built-in properties (injected at build time)
        String fromBuiltIn = BUILT_IN.getProperty(key);
        if (fromBuiltIn == null || fromBuiltIn.isBlank()) {
            return null;
        }
        return fromBuiltIn.trim();
    }

    private static Properties loadDotEnv() {
        Properties properties = new Properties();
        Path envPath = findDotEnv();
        if (!Files.exists(envPath)) {
            return properties;
        }

        try {
            for (String line : Files.readAllLines(envPath)) {
                String trimmed = line.trim();
                if (trimmed.isEmpty() || trimmed.startsWith("#")) {
                    continue;
                }

                int separatorIndex = trimmed.indexOf('=');
                if (separatorIndex <= 0) {
                    continue;
                }

                String key = trimmed.substring(0, separatorIndex).trim();
                String value = trimmed.substring(separatorIndex + 1).trim();
                properties.setProperty(key, value);
            }
        } catch (IOException ignored) {
            return properties;
        }

        return properties;
    }

    private static Path findDotEnv() {
        for (Path directory : AppPaths.runtimeDirectories()) {
            Path envPath = directory.resolve(".env");
            if (Files.exists(envPath)) {
                return envPath;
            }
        }

        return AppPaths.runtimeDirectories().get(0).resolve(".env");
    }

    private static Properties loadBuiltIn() {
        Properties properties = new Properties();
        try (InputStream is = EnvironmentValues.class.getResourceAsStream("/application.properties")) {
            if (is != null) {
                properties.load(is);
            }
        } catch (IOException ignored) {
            // Properties file not found or error loading
        }
        return properties;
    }
}
