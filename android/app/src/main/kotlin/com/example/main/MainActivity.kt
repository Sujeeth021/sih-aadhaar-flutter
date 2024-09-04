package com.example.main

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Log
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.math.BigInteger
import java.security.KeyPairGenerator
import java.security.KeyStore
import javax.security.auth.x500.X500Principal
import java.util.concurrent.Executor

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.main/platform_channel"
    private val alias = "key_alias"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getNativeMessage" -> {
                        result.success("Hello from Android!")
                    }
                    "checkAndGenerateKeyPair" -> {
                        val message = checkAndGenerateKeyPair()
                        result.success(message)
                    }
                    "requestBiometricAuth" -> {
                        requestBiometricAuthentication { authResult ->
                            result.success(authResult)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun checkAndGenerateKeyPair(): String {
        return try {
            val keyStore = KeyStore.getInstance("AndroidKeyStore")
            keyStore.load(null)

            if (keyStore.containsAlias(alias)) {
                "Key Pair already exists with alias: $alias"
            } else {
                generateKeyPair()
                "Key Pair generated successfully with alias: $alias"
            }
        } catch (e: Exception) {
            "Error checking key pair: ${e.message}"
        }
    }

    private fun generateKeyPair() {
        val keyPairGenerator = KeyPairGenerator.getInstance("RSA", "AndroidKeyStore")
        keyPairGenerator.initialize(
            KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
            )
                .setCertificateSubject(X500Principal("CN=$alias"))
                .setCertificateSerialNumber(BigInteger.ONE)
                .setCertificateNotBefore(java.util.Date())
                .setCertificateNotAfter(java.util.Date(System.currentTimeMillis() + 365 * 24 * 60 * 60 * 1000)) // 1 year validity
                .setDigests(KeyProperties.DIGEST_SHA256)
                .setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1)
                .build()
        )
        keyPairGenerator.generateKeyPair()
    }

    private fun requestBiometricAuthentication(onResult: (String) -> Unit) {
        val executor: Executor = ContextCompat.getMainExecutor(this)
        val biometricPrompt = BiometricPrompt(this, executor, object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                val errorMsg = "Authentication error: $errString (Code: $errorCode)"
                Log.e("BiometricAuth", errorMsg)
                onResult(errorMsg)
            }

            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                onResult("Authentication succeeded!")
            }

            override fun onAuthenticationFailed() {
                onResult("Authentication failed")
            }
        })

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Biometric Authentication")
            .setSubtitle("Authenticate using your biometric credential")
            .setNegativeButtonText("Cancel")
            .build()

        biometricPrompt.authenticate(promptInfo)
    }
}
