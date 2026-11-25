// Run with JDK 21 in source-file mode. This verifier needs only public fingerprints.
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.DigestInputStream;
import java.security.MessageDigest;
import java.util.HashMap;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.Locale;
import java.util.Map;
import java.util.jar.JarFile;
import java.util.regex.Pattern;

public class VerifyPlayAab {
    private static final Pattern SIGNATURE_METADATA = Pattern.compile(
        "META-INF/(MANIFEST\\.MF|[^/]+\\.(SF|RSA|DSA|EC)|SIG-[^/]+)",
        Pattern.CASE_INSENSITIVE
    );

    public static void main(String[] args) {
        if (args.length != 4) {
            System.err.println("Usage: java tool/VerifyPlayAab.java UNSIGNED.aab SIGNED.aab UNSIGNED_SHA256 PLAY_UPLOAD_CERT_SHA256");
            System.exit(2);
        }

        try {
            Path unsigned = Path.of(args[0]);
            Path signed = Path.of(args[1]);
            String expectedCandidateHash = fingerprint(args[2]);
            String expectedCertificate = fingerprint(args[3]);
            require(expectedCandidateHash.equals(sha256(unsigned)), "Unsigned candidate SHA-256 mismatch.");

            Map<String, String> candidateEntries = readPayload(unsigned, null);
            Map<String, String> signedEntries = readPayload(signed, expectedCertificate);
            require(candidateEntries.equals(signedEntries), "Signed AAB payload differs from the verified candidate.");
            System.out.printf("Verified %d AAB entries against the candidate.%n", signedEntries.size());
            System.out.println("Upload certificate SHA-256: " + expectedCertificate);
            System.out.println("Signed AAB SHA-256: " + sha256(signed));
        } catch (Exception error) {
            System.err.println("AAB verification failed: " + error.getMessage());
            System.exit(1);
        }
    }

    private static Map<String, String> readPayload(Path file, String expectedCertificate)
            throws Exception {
        var payload = new HashMap<String, String>();
        var names = new HashSet<String>();
        try (var jar = new JarFile(file.toFile(), expectedCertificate != null)) {
            var entries = jar.entries();
            while (entries.hasMoreElements()) {
                var entry = entries.nextElement();
                String name = entry.getName();
                require(names.add(name), "Duplicate ZIP entry: " + name);
                if (entry.isDirectory()) {
                    continue;
                }
                if (SIGNATURE_METADATA.matcher(name).matches()) {
                    require(expectedCertificate != null, "Candidate contains JAR signing metadata: " + name);
                    continue;
                }
                var digest = MessageDigest.getInstance("SHA-256");
                try (var stream = new DigestInputStream(jar.getInputStream(entry), digest)) {
                    stream.transferTo(OutputStream.nullOutputStream());
                }
                if (expectedCertificate != null) {
                    // JarFile exposes the verified signers only after consuming the full entry.
                    var signers = entry.getCodeSigners();
                    require(signers != null && signers.length == 1, "Expected one verified signer for " + name);
                    var leaf = signers[0].getSignerCertPath().getCertificates().getFirst();
                    String certificate = HexFormat.of().formatHex(
                        MessageDigest.getInstance("SHA-256").digest(leaf.getEncoded())
                    );
                    require(expectedCertificate.equals(certificate), "Unexpected upload certificate for " + name);
                }
                payload.put(name, HexFormat.of().formatHex(digest.digest()));
            }
        }
        require(payload.containsKey("BundleConfig.pb") && payload.containsKey("base/manifest/AndroidManifest.xml"),
            "Required Android App Bundle entries are missing.");
        return payload;
    }

    private static String sha256(Path file) throws Exception {
        var digest = MessageDigest.getInstance("SHA-256");
        try (var stream = new DigestInputStream(Files.newInputStream(file), digest)) {
            stream.transferTo(OutputStream.nullOutputStream());
        }
        return HexFormat.of().formatHex(digest.digest());
    }

    private static String fingerprint(String value) {
        String hex = value.replace(":", "").strip().toLowerCase(Locale.ROOT);
        require(hex.matches("[0-9a-f]{64}"), "Expected a 64-digit SHA-256 fingerprint.");
        return hex;
    }

    private static void require(boolean condition, String message) {
        if (!condition) {
            throw new IllegalArgumentException(message);
        }
    }
}
