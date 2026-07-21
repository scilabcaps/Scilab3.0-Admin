package com.example.scalib.controller;

import com.example.scalib.HelloApplication;
import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.layout.StackPane;
import javafx.stage.Stage;

import java.io.IOException;
import java.util.List;

public class DashboardController {

    @FXML
    private Label welcomeLabel;

    @FXML
    private Label userNameLabel;

    @FXML
    private Label topbarUserLabel;

    @FXML
    private Label topbarTitleLabel;

    @FXML
    private StackPane contentContainer;

    @FXML
    private Button dashboardNavButton;

    @FXML
    private Button reservationHistoryNavButton;

    @FXML
    private Button professorApprovalsNavButton;

    @FXML
    private Button studentApprovalsNavButton;

//    @FXML
//    private Button ongoingReservationsNavButton;

    @FXML
    private Button roomMonitorNavButton;

    @FXML
    private Button inventoryNavButton;

    @FXML
    private Button manageProfessorsNavButton;

    @FXML
    private Button unreturnedItemsNavButton;

    private List<Button> navigationButtons;
    private Node dashboardHomeNode;
    private String currentUser = "Administrator";

    @FXML
    private void initialize() {
        navigationButtons = List.of(
                dashboardNavButton,
                reservationHistoryNavButton,
                professorApprovalsNavButton,
                studentApprovalsNavButton,
//                ongoingReservationsNavButton, ::DO NOT USE
                roomMonitorNavButton,
                inventoryNavButton,
                manageProfessorsNavButton,
                unreturnedItemsNavButton
        );
        dashboardHomeNode = contentContainer.getChildren().isEmpty() ? null : contentContainer.getChildren().get(0);
        dashboardNavButton.getStyleClass().add("sidebar-nav-button-active");
    }

    public void setUser(String email) {
        currentUser = email == null || email.isBlank() ? "Administrator" : email.trim();
        welcomeLabel.setText("Welcome, " + currentUser + "!");
        userNameLabel.setText(currentUser);
    }

    @FXML
    private void onNavClick(ActionEvent event) {
        Object source = event.getSource();
        if (!(source instanceof Button clickedButton)) {
            return;
        }

        navigationButtons.forEach(button -> button.getStyleClass().remove("sidebar-nav-button-active"));
        clickedButton.getStyleClass().add("sidebar-nav-button-active");

        String key = clickedButton.getUserData() == null ? "DASHBOARD" : clickedButton.getUserData().toString();
        loadSectionContent(key);
    }

    private void loadSectionContent(String sectionKey) {
        if ("DASHBOARD".equals(sectionKey)) {
            topbarTitleLabel.setText("Admin Dashboard");
            showDashboardHome();
            return;
        }

        String fxmlFile = switch (sectionKey) {
            case "RESERVATION_HISTORY" -> "reservation-history-view.fxml";
            case "PROFESSOR_APPROVALS" -> "professor-approvals-view.fxml";
            case "STUDENT_APPROVALS" -> "student-approvals-view.fxml";
            case "ONGOING_RESERVATIONS" -> "ongoing-reservations-view.fxml";
            case "ROOM_MONITOR" -> "room-monitor-view.fxml";
            case "INVENTORY" -> "inventory-view.fxml";
            case "MANAGE_PROFESSORS" -> "manage-professors-view.fxml";
            case "UNRETURNED_ITEMS" -> "unreturned-items-view.fxml";
            default -> null;
        };

        if (fxmlFile == null) {
            return;
        }

        String title = navigationButtons.stream()
                .filter(button -> sectionKey.equals(String.valueOf(button.getUserData())))
                .map(Button::getText)
                .findFirst()
                .orElse("Admin Dashboard");
        topbarTitleLabel.setText(title);

        try {
            FXMLLoader loader = new FXMLLoader(HelloApplication.class.getResource(fxmlFile));
            Node sectionRoot = loader.load();
            Object controller = loader.getController();
            if (controller instanceof SectionUserAware userAwareController) {
                userAwareController.setCurrentUser(currentUser);
            }

            contentContainer.getChildren().setAll(sectionRoot);
        } catch (IOException ex) {
            throw new IllegalStateException("Unable to load section view: " + fxmlFile, ex);
        }
    }

    private void showDashboardHome() {
        if (dashboardHomeNode != null) {
            contentContainer.getChildren().setAll(dashboardHomeNode);
        }
    }

    @FXML
    private void onLogoutClick() {
        Stage stage = (Stage) welcomeLabel.getScene().getWindow();
        try {
            FXMLLoader loader = new FXMLLoader(HelloApplication.class.getResource("login-view.fxml"));
            Parent loginRoot = loader.load();
            Scene scene = new Scene(loginRoot, 980, 620);
            scene.getStylesheets().add(HelloApplication.class.getResource("login.css").toExternalForm());
            stage.setTitle("Scalib - Login");
            stage.setScene(scene);
        } catch (IOException ex) {
            throw new IllegalStateException("Unable to return to the login screen.", ex);
        }
    }
}
