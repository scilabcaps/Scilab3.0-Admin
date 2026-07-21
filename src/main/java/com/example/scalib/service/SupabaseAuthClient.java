package com.example.scalib.service;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class SupabaseAuthClient {
    private static final Pattern JSON_ERROR_DESCRIPTION = Pattern.compile("\"error_description\"\\s*:\\s*\"([^\"]+)\"");
    private static final Pattern JSON_MESSAGE = Pattern.compile("\"message\"\\s*:\\s*\"([^\"]+)\"");

    private final HttpClient httpClient;
    private final String supabaseUrl;
    private final String anonKey;

    public SupabaseAuthClient(String supabaseUrl, String anonKey) {
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
        this.supabaseUrl = supabaseUrl;
        this.anonKey = anonKey;
    }

    public static SupabaseAuthClient fromEnvironment() {
        // Check both env var format and properties file format
        String supabaseUrl = EnvironmentValues.get("SUPABASE_URL");
        if (supabaseUrl == null) {
            supabaseUrl = EnvironmentValues.get("supabase.url");
        }

        String anonKey = EnvironmentValues.get("SUPABASE_ANON_KEY");
        if (anonKey == null) {
            anonKey = EnvironmentValues.get("supabase.anon.key");
        }

        if (supabaseUrl == null || anonKey == null) {
            return null;
        }

        return new SupabaseAuthClient(supabaseUrl, anonKey);
    }

    public AuthResult authenticate(String email, String password) {
        String endpoint = supabaseUrl + "/auth/v1/token?grant_type=password";
        String requestBody = "{\"email\":\"" + escapeJson(email) + "\",\"password\":\"" + escapeJson(password) + "\"}";

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(endpoint))
                .timeout(Duration.ofSeconds(15))
                .header("Content-Type", "application/json")
                .header("apikey", anonKey)
                .header("Authorization", "Bearer " + anonKey)
                .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                .build();

        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() >= 200 && response.statusCode() < 300) {
                return AuthResult.successResult();
            }
            return AuthResult.failureResult(extractErrorMessage(response.body()));
        } catch (IOException | InterruptedException e) {
            if (e instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            return AuthResult.failureResult("Unable to reach authentication service.");
        }
    }

    private static String extractErrorMessage(String responseBody) {
        if (responseBody == null || responseBody.isBlank()) {
            return "Invalid email or password.";
        }

        Matcher descriptionMatch = JSON_ERROR_DESCRIPTION.matcher(responseBody);
        if (descriptionMatch.find()) {
            return descriptionMatch.group(1);
        }

        Matcher messageMatch = JSON_MESSAGE.matcher(responseBody);
        if (messageMatch.find()) {
            return messageMatch.group(1);
        }

        return "Invalid email or password.";
    }

    private static String escapeJson(String value) {
        return value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"");
    }

    public record AuthResult(boolean success, String message) {
        public static AuthResult successResult() {
            return new AuthResult(true, null);
        }

        public static AuthResult failureResult(String message) {
            return new AuthResult(false, message);
        }
    }
}
