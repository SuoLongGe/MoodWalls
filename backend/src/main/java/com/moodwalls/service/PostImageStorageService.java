package com.moodwalls.service;

import com.moodwalls.exception.BusinessException;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

@Service
public class PostImageStorageService {

    private static final Set<String> ALLOWED_EXTENSIONS = Set.of("jpg", "jpeg", "png", "webp", "gif");
    private static final DateTimeFormatter DATE_PATH = DateTimeFormatter.ofPattern("yyyy/MM/dd");

    @Value("${moodwalls.upload.dir:uploads}")
    private String uploadDir;

    @Value("${moodwalls.upload.max-size-bytes:10485760}")
    private long maxSizeBytes;

    @Value("${moodwalls.server-host:localhost}")
    private String serverHost;

    @Value("${server.port:8080}")
    private int serverPort;

    private Path uploadRoot;

    @PostConstruct
    public void init() throws IOException {
        uploadRoot = Paths.get(uploadDir).toAbsolutePath().normalize();
        Files.createDirectories(uploadRoot.resolve("posts"));
        Files.createDirectories(uploadRoot.resolve("avatars"));
    }

    public String getResourceLocation() {
        String path = uploadRoot.toUri().toString();
        return path.endsWith("/") ? path : path + "/";
    }

    public String savePostImage(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException(400, "请选择要上传的图片");
        }
        if (file.getSize() > maxSizeBytes) {
            throw new BusinessException(400, "图片不能超过 10MB");
        }

        String extension = resolveExtension(file);
        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            throw new BusinessException(400, "仅支持 JPG、PNG、WEBP、GIF 图片");
        }

        String dateSegment = LocalDate.now().format(DATE_PATH);
        Path targetDir = uploadRoot.resolve("posts").resolve(dateSegment.replace('/', java.io.File.separatorChar));
        try {
            Files.createDirectories(targetDir);
            String filename = UUID.randomUUID().toString().replace("-", "") + "." + extension;
            Path targetFile = targetDir.resolve(filename);
            file.transferTo(targetFile.toFile());
            return "/uploads/posts/" + dateSegment + "/" + filename;
        } catch (IOException ex) {
            throw new BusinessException(500, "图片保存失败，请稍后重试");
        }
    }

    public String saveBase64Avatar(String base64Data) {
        return saveBase64Image(base64Data, "avatars");
    }

    public String saveBase64Image(String base64Data) {
        return saveBase64Image(base64Data, "posts");
    }

    private String saveBase64Image(String base64Data, String category) {
        if (base64Data == null || base64Data.isBlank()) {
            throw new BusinessException(400, "图片数据为空");
        }
        String cleaned = base64Data.trim();
        if (cleaned.contains(",")) {
            cleaned = cleaned.substring(cleaned.indexOf(',') + 1);
        }
        final byte[] bytes;
        try {
            bytes = Base64.getDecoder().decode(cleaned);
        } catch (IllegalArgumentException ex) {
            throw new BusinessException(400, "图片格式无效");
        }
        if (bytes.length == 0) {
            throw new BusinessException(400, "图片数据为空");
        }
        if (bytes.length > maxSizeBytes) {
            throw new BusinessException(400, "图片不能超过 10MB");
        }

        String extension = resolveExtensionFromBytes(bytes);
        String dateSegment = LocalDate.now().format(DATE_PATH);
        Path targetDir = uploadRoot.resolve(category).resolve(dateSegment.replace('/', java.io.File.separatorChar));
        try {
            Files.createDirectories(targetDir);
            String filename = UUID.randomUUID().toString().replace("-", "") + "." + extension;
            Path targetFile = targetDir.resolve(filename);
            Files.write(targetFile, bytes);
            return "/uploads/" + category + "/" + dateSegment + "/" + filename;
        } catch (IOException ex) {
            throw new BusinessException(500, "图片保存失败，请稍后重试");
        }
    }

    public String toPublicUrl(String storedPath) {
        if (storedPath == null || storedPath.isBlank()) {
            return null;
        }
        if (storedPath.startsWith("http://") || storedPath.startsWith("https://")) {
            return storedPath;
        }
        String normalized = storedPath.startsWith("/") ? storedPath : "/" + storedPath;
        return "http://" + serverHost + ":" + serverPort + normalized;
    }

    private String resolveExtensionFromBytes(byte[] bytes) {
        if (bytes.length >= 3 && bytes[0] == (byte) 0xFF && bytes[1] == (byte) 0xD8 && bytes[2] == (byte) 0xFF) {
            return "jpg";
        }
        if (bytes.length >= 8
                && bytes[0] == (byte) 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
            return "png";
        }
        if (bytes.length >= 6
                && bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
            return "gif";
        }
        if (bytes.length >= 12
                && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46
                && bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
            return "webp";
        }
        return "jpg";
    }

    private String resolveExtension(MultipartFile file) {
        String original = file.getOriginalFilename();
        if (original != null && original.contains(".")) {
            String ext = original.substring(original.lastIndexOf('.') + 1).toLowerCase(Locale.ROOT);
            if (ALLOWED_EXTENSIONS.contains(ext)) {
                return "jpeg".equals(ext) ? "jpg" : ext;
            }
        }

        String contentType = file.getContentType();
        if (contentType != null) {
            return switch (contentType.toLowerCase(Locale.ROOT)) {
                case "image/jpeg", "image/jpg" -> "jpg";
                case "image/png" -> "png";
                case "image/webp" -> "webp";
                case "image/gif" -> "gif";
                default -> "";
            };
        }
        return "";
    }
}
