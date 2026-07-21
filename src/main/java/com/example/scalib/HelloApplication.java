package com.example.scalib;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.stage.Stage;

import java.io.IOException;

public class HelloApplication extends Application {
    @Override
    public void start(Stage stage) throws IOException {
        FXMLLoader fxmlLoader = new FXMLLoader(HelloApplication.class.getResource("login-view.fxml"));
        Scene scene = new Scene(fxmlLoader.load(), 980, 620);
        scene.getStylesheets().add(HelloApplication.class.getResource("login.css").toExternalForm());
        stage.setTitle("Scalib - Login");
        stage.setMinWidth(900);
        stage.setMinHeight(580);
        stage.setMaximized(true);
        stage.setScene(scene);
        stage.show();
    }
}
