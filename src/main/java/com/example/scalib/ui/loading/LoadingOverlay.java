package com.example.scalib.ui.loading;

import javafx.geometry.Pos;
import javafx.scene.control.Label;
import javafx.scene.control.ProgressIndicator;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.StackPane;
import javafx.scene.layout.VBox;

public class LoadingOverlay extends StackPane {
    private static final String LOADER_GIF_RESOURCE = "/com/example/scalib/animation/green_loading.gif";
    private final Label messageLabel;

    public LoadingOverlay() {
        getStyleClass().add("loading-overlay");
        setVisible(false);
        setManaged(false);
        setMouseTransparent(true);

        VBox content = new VBox(12);
        content.setAlignment(Pos.CENTER);
        content.getStyleClass().add("loading-content");

        ImageView gifLoader = createGifLoader();
        if (gifLoader != null) {
            content.getChildren().add(gifLoader);
        } else {
            ProgressIndicator indicator = new ProgressIndicator();
            indicator.getStyleClass().add("loading-spinner");
            indicator.setMaxSize(58, 58);
            content.getChildren().add(indicator);
        }

        messageLabel = new Label("Signing in...");
        messageLabel.getStyleClass().add("loading-text");
        content.getChildren().add(messageLabel);

        setAlignment(Pos.CENTER);
        getChildren().add(content);
    }

    private ImageView createGifLoader() {
        try {
            var resource = getClass().getResource(LOADER_GIF_RESOURCE);
            if (resource == null) {
                return null;
            }

            Image image = new Image(resource.toExternalForm(), true);
            ImageView imageView = new ImageView(image);
            imageView.getStyleClass().add("loading-gif");
            imageView.setPreserveRatio(true);
            imageView.setFitWidth(72);
            return imageView;
        } catch (RuntimeException ignored) {
            return null;
        }
    }

    public void show(String message) {
        messageLabel.setText(message == null || message.isBlank() ? "Loading..." : message);
        setManaged(true);
        setVisible(true);
        setMouseTransparent(false);
    }

    public void hide() {
        setMouseTransparent(true);
        setVisible(false);
        setManaged(false);
    }
}
