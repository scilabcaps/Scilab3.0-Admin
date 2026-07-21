module com.example.scalib {
    requires javafx.controls;
    requires javafx.fxml;
    requires java.net.http;
    requires java.sql;
    requires org.xerial.sqlitejdbc;


    opens com.example.scalib to javafx.fxml;
    opens com.example.scalib.controller to javafx.fxml;
    exports com.example.scalib;
    exports com.example.scalib.controller;
    exports com.example.scalib.service;
    exports com.example.scalib.model;
}