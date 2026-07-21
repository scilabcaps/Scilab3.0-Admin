package com.example.scalib.service;

import com.example.scalib.Launcher;

import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

public final class AppPaths {
    private AppPaths() {
    }

    public static List<Path> runtimeDirectories() {
        List<Path> directories = new ArrayList<>();
        addIfMissing(directories, Paths.get(System.getProperty("user.dir")).toAbsolutePath().normalize());
        addIfMissing(directories, applicationDirectory());
        return directories;
    }

    public static Path writableRuntimeFile(String fileName) {
        for (Path directory : runtimeDirectories()) {
            Path filePath = directory.resolve(fileName);
            if (filePath.toFile().exists()) {
                return filePath;
            }
        }

        return runtimeDirectories().get(0).resolve(fileName);
    }

    private static Path applicationDirectory() {
        try {
            URI location = Launcher.class.getProtectionDomain()
                    .getCodeSource()
                    .getLocation()
                    .toURI();
            Path path = Paths.get(location).toAbsolutePath().normalize();
            return path.toFile().isFile() ? path.getParent() : path;
        } catch (URISyntaxException | RuntimeException ex) {
            return Paths.get(System.getProperty("user.dir")).toAbsolutePath().normalize();
        }
    }

    private static void addIfMissing(List<Path> directories, Path directory) {
        if (directory != null && !directories.contains(directory)) {
            directories.add(directory);
        }
    }
}
