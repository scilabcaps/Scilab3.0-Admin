package com.example.scalib.service;

public class AuthService {
    private final SupabaseAuthClient supabaseAuthClient;
    private String lastErrorMessage;

    public AuthService() {
        this.supabaseAuthClient = SupabaseAuthClient.fromEnvironment();
        this.lastErrorMessage = null;
    }

    public boolean authenticate(String email, String rawPassword) {
        lastErrorMessage = null;

        if (supabaseAuthClient == null) {
            lastErrorMessage = "Supabase is not configured. Check SUPABASE_URL and SUPABASE_ANON_KEY.";
            return false;
        }

        SupabaseAuthClient.AuthResult authResult = supabaseAuthClient.authenticate(email, rawPassword);
        if (!authResult.success()) {
            lastErrorMessage = authResult.message();
        }
        return authResult.success();
    }

    public String getLastErrorMessage() {
        return lastErrorMessage;
    }
}
