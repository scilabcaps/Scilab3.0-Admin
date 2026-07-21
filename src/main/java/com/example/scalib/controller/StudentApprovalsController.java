package com.example.scalib.controller;

import javafx.fxml.FXML;
import javafx.scene.control.Label;

public class StudentApprovalsController implements SectionUserAware {

    @FXML
    private Label userLabel;

    @Override
    public void setCurrentUser(String user) {
        userLabel.setText("User: " + user);
    }
}
