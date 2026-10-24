package com.mibu.mibu

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "snapshot" -> {
                        createKey()
                        result.success(null)
                    }
                    "enrollmentChanged" -> result.success(enrollmentChanged())
                    "secure" -> {
                        setSecure(call.arguments as? Boolean ?: false)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Kunci app (99.10): blur in the app list, and no screenshots, while the
    // lock and its blur setting are on.
    private fun setSecure(on: Boolean) {
        if (on) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    // Kunci app (99.10s): a Keystore key that Android invalidates for good once
    // a new fingerprint / face is enrolled. Made when biometrics are switched
    // on, tried whenever the lock screen shows.
    private fun createKey() {
        try {
            val generator =
                KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE)
            generator.init(
                KeyGenParameterSpec.Builder(
                        KEY_ALIAS,
                        KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
                    )
                    .setBlockModes(KeyProperties.BLOCK_MODE_CBC)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_PKCS7)
                    .setUserAuthenticationRequired(true)
                    .setInvalidatedByBiometricEnrollment(true)
                    .build(),
            )
            generator.generateKey()
        } catch (e: Exception) {
            // no secure lock screen on the phone: nothing to compare with later
        }
    }

    private fun enrollmentChanged(): Boolean {
        return try {
            val store = KeyStore.getInstance(KEYSTORE).apply { load(null) }
            val key = store.getKey(KEY_ALIAS, null) as? SecretKey ?: return false
            Cipher.getInstance("AES/CBC/PKCS7Padding").init(Cipher.ENCRYPT_MODE, key)
            false
        } catch (e: KeyPermanentlyInvalidatedException) {
            true
        } catch (e: Exception) {
            false
        }
    }

    private companion object {
        const val CHANNEL = "com.mibu/lock"
        const val KEYSTORE = "AndroidKeyStore"
        const val KEY_ALIAS = "mibu_biometric_enrollment"
    }
}
