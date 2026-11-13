import java.io.File
import java.security.KeyStore
import java.security.PrivateKey
import java.security.cert.X509Certificate
import java.util.Properties
import javax.naming.ldap.LdapName

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// Local, ignored key.properties or an external file; never a checked-in secret.
val signingPropertiesPath = providers.environmentVariable("MENNYIMENT_RELEASE_PROPERTIES").orNull
val signingPropertiesFile = signingPropertiesPath?.let { file(it) }
    ?: rootProject.file("key.properties")
val releaseProperties = Properties()
var signingPropertiesUnreadable = false
if (signingPropertiesFile.exists()) {
    try {
        signingPropertiesFile.inputStream().use { releaseProperties.load(it) }
    } catch (_: Exception) {
        signingPropertiesUnreadable = true
    }
}
val signingFields = mapOf(
    "storeFile" to "MENNYIMENT_STORE_FILE",
    "storePassword" to "MENNYIMENT_STORE_PASSWORD",
    "keyAlias" to "MENNYIMENT_KEY_ALIAS",
    "keyPassword" to "MENNYIMENT_KEY_PASSWORD",
)
val releaseValues = signingFields.mapValues { (field, variable) ->
    providers.environmentVariable(variable).orNull ?: releaseProperties.getProperty(field)
}
val releaseStoreFile = releaseValues["storeFile"]?.takeIf { it.isNotBlank() }?.let {
    val candidate = File(it)
    if (candidate.isAbsolute) candidate else File(signingPropertiesFile.parentFile, it)
}
val releaseStoreType = releaseProperties.getProperty("storeType", KeyStore.getDefaultType())
val releaseInputsPresent = releaseValues.values.all { !it.isNullOrBlank() } &&
    releaseStoreFile?.isFile == true && !signingPropertiesUnreadable

android {
    namespace = "com.example.mennyiment"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Preserve the current application ID; changing it needs an owner decision.
        applicationId = "com.example.mennyiment"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (releaseInputsPresent) {
                storeFile = releaseStoreFile
                storePassword = releaseValues["storePassword"]
                keyAlias = releaseValues["keyAlias"]
                keyPassword = releaseValues["keyPassword"]
                storeType = releaseStoreType
            }
        }
    }
    buildTypes {
        release {
            // No debug fallback, even when release credentials are missing.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

val validateMennyiMentReleaseSigning = tasks.register("validateMennyiMentReleaseSigning") {
    group = "verification"
    description = "Rejects missing or debug release signing without logging credentials."
    doLast {
        fun reject(code: String, help: String): Nothing =
            throw GradleException("MENNYIMENT_RELEASE_SIGNING[$code]: $help")
        if (signingPropertiesUnreadable ||
            (signingPropertiesPath != null && !signingPropertiesFile.isFile)) {
            reject("CONFIG", "Cannot read external signing properties. Check MENNYIMENT_RELEASE_PROPERTIES.")
        }
        val missing = releaseValues.filterValues { it.isNullOrBlank() }.keys
        if (missing.isNotEmpty()) {
            reject("MISSING", "Release signing is required. Configure external key.properties or " +
                "MENNYIMENT_RELEASE_PROPERTIES and signing environment variables. Missing fields: " +
                missing.joinToString() + ". Debug signing will not be used.")
        }
        if (releaseValues["keyAlias"].equals("androiddebugkey", ignoreCase = true) ||
            releaseStoreFile?.name.equals("debug.keystore", ignoreCase = true)) {
            reject("DEBUG", "Android debug signing material is not accepted for a release build.")
        }
        val keystoreFile = releaseStoreFile
            ?: reject("FILE", "Release keystore file is missing. Check storeFile or MENNYIMENT_STORE_FILE.")
        if (!keystoreFile.isFile) {
            reject("FILE", "Release keystore file is missing. Check storeFile or MENNYIMENT_STORE_FILE.")
        }
        val storePasswordChars = releaseValues.getValue("storePassword")!!.toCharArray()
        val keyPasswordChars = releaseValues.getValue("keyPassword")!!.toCharArray()
        try {
            val store = KeyStore.getInstance(releaseStoreType)
            keystoreFile.inputStream().use { store.load(it, storePasswordChars) }
            val alias = releaseValues.getValue("keyAlias")!!
            val certificate = store.getCertificate(alias) as? X509Certificate
                ?: reject("CERTIFICATE", "The configured alias has no X.509 signing certificate.")
            val debugSubject = LdapName(certificate.subjectX500Principal.name).rdns.any {
                it.type.equals("CN", ignoreCase = true) &&
                    it.value.toString().trim().equals("Android Debug", ignoreCase = true)
            }
            if (debugSubject) reject("DEBUG", "An Android Debug certificate cannot sign a release build.")
            certificate.checkValidity()
            if (!store.isKeyEntry(alias) || store.getKey(alias, keyPasswordChars) !is PrivateKey) {
                reject("KEY", "The configured alias does not contain a usable private key.")
            }
        } catch (failure: GradleException) {
            throw failure
        } catch (_: Exception) {
            // Never forward provider exceptions: they can contain paths or values.
            reject("CREDENTIALS", "Release signing could not be verified. Check the external keystore, " +
                "store type, alias and passwords. Details are intentionally not logged.")
        } finally {
            storePasswordChars.fill('\u0000')
            keyPasswordChars.fill('\u0000')
        }
    }
}
// Guard every release variant task, including Flutter compilation and bundles.
// Debug tasks remain independent and work without a release properties file.
tasks.configureEach {
    if (name.contains("Release") && name != "validateMennyiMentReleaseSigning") {
        dependsOn(validateMennyiMentReleaseSigning)
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}
flutter { source = "../.." }
