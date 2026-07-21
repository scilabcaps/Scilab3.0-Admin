package com.example.scalib.controller;

import com.example.scalib.HelloApplication;
import com.example.scalib.service.AuthService;
import com.example.scalib.service.PasswordHasher;
import com.example.scalib.ui.loading.LoadingOverlay;
import javafx.application.Platform;
import javafx.concurrent.Task;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.CheckBox;
import javafx.scene.control.Label;
import javafx.scene.control.PasswordField;
import javafx.scene.control.TextField;
import javafx.scene.layout.StackPane;
import javafx.stage.Stage;

import java.io.IOException;
import java.sql.SQLException;

public class LoginController {

    @FXML
    private TextField emailField;

    @FXML
    private PasswordField passwordField;

    @FXML
    private CheckBox rememberMeCheckBox;

    @FXML
    private Label feedbackLabel;

    @FXML
    private Button signInButton;

    @FXML
    private StackPane loadingContainer;

    private final AuthService authService;
    private LoadingOverlay loadingOverlay;

    public LoginController() {
        this.authService = new AuthService();
    }

    @FXML
    protected void initialize() {
        loadingOverlay = new LoadingOverlay();
        loadingContainer.getChildren().add(loadingOverlay);
    }

    @FXML
    protected void onLoginClick() {
        String email = emailField.getText();
        String password = passwordField.getText();

        if (email == null || email.trim().isEmpty()) {
            feedbackLabel.setText("Please enter your email address.");
            return;
        }

        if (password == null || password.trim().isEmpty()) {
            feedbackLabel.setText("Please enter your password.");
            return;
        }

//        String email = "admin@admin.com";
//        String password = "admin";

        setLoading(true);
        feedbackLabel.setText("");
        String sanitizedEmail = email.trim();

        Task<Boolean> loginTask = new Task<>() {
            @Override
            protected Boolean call() throws Exception {
                return authService.authenticate(sanitizedEmail, password);
            }
        };

        loginTask.setOnSucceeded(event -> {
            System.out.println("Login succeeded");
            setLoading(false);
            boolean success = loginTask.getValue();
            if (!success) {
                System.out.println("Login failed: " + authService.getLastErrorMessage());
                String authError = authService.getLastErrorMessage();
                feedbackLabel.setText(authError != null ? authError : "Invalid email or password.");
                return;
            }

            openDashboard(sanitizedEmail);
        });

        loginTask.setOnFailed(event -> {
            System.out.println("Login failed: " + loginTask.getException());
            setLoading(false);
            Throwable error = loginTask.getException();
            if (error instanceof SQLException) {
                System.out.println("Database error: " + error.getMessage());
                feedbackLabel.setText("Login failed due to a database error.");
                return;
            }
            feedbackLabel.setText("Login failed. Please try again.");
        });

        Thread loginThread = new Thread(loginTask, "login-auth-thread");
        loginThread.setDaemon(true);
        loginThread.start();
    }

    private void setLoading(boolean loading) {
        Platform.runLater(() -> {
            emailField.setDisable(loading);
            passwordField.setDisable(loading);
            signInButton.setDisable(loading);
            if (loading) {
                loadingOverlay.show("Signing in...");
            } else {
                loadingOverlay.hide();
            }
        });
    }

    private void openDashboard(String email) {
        try {
            FXMLLoader loader = new FXMLLoader(HelloApplication.class.getResource("dashboard-view.fxml"));
            Parent dashboardRoot = loader.load();

            DashboardController dashboardController = loader.getController();
            dashboardController.setUser(email);

            Stage stage = (Stage) signInButton.getScene().getWindow();
            Scene dashboardScene = new Scene(dashboardRoot, stage.getScene().getWidth(), stage.getScene().getHeight());
            dashboardScene.getStylesheets().add(HelloApplication.class.getResource("login.css").toExternalForm());
            stage.setTitle("Scalib - Dashboard");
            stage.setScene(dashboardScene);
        } catch (IOException ex) {
            feedbackLabel.setText("Login succeeded but dashboard failed to load.");
        }
    }
}
