package com.example.main

import android.content.ClipboardManager
import android.content.Context
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
import java.security.Signature
import javax.security.auth.x500.X500Principal
import java.util.concurrent.Executor

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.main/platform_channel"
    private val alias = "key_alias"
    private var signedData: ByteArray? = null // To store signed data

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
                        createBiometricPromptForSignature { authResult ->
                            result.success(authResult)
                        }
                    }
                    "verifySignature" -> {
                        val signedKeyInput = call.argument<String>("signedKeyInput") ?: ""
                        verifySignature(signedKeyInput) { verificationResult ->
                            result.success(verificationResult)
                        }
                    }
                    "copySignedKeyToClipboard" -> {
                        copySignedKeyToClipboard()
                        result.success("Signed key copied to clipboard.")
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

    private fun createBiometricPromptForSignature(onResult: (String) -> Unit) {
        val executor: Executor = ContextCompat.getMainExecutor(this)
        val biometricPrompt = BiometricPrompt(this, executor, object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                val errorMsg = "Authentication error: $errString (Code: $errorCode)"
                Log.e("BiometricAuth", errorMsg)
                onResult(errorMsg)
            }

            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                val cryptoObject = result.cryptoObject
                performKeyAccess(cryptoObject) { accessResult ->
                    onResult(accessResult)
                }
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

        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val key = keyStore.getKey(alias, null) as? java.security.PrivateKey
        val signature = Signature.getInstance("SHA256withRSA").apply {
            initSign(key)
        }

        biometricPrompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(signature))
    }

    private fun performKeyAccess(cryptoObject: BiometricPrompt.CryptoObject?, onResult: (String) -> Unit) {
        if (cryptoObject == null) {
            val errorMsg = "Error: CryptoObject is null, unable to sign data."
            Log.e("KeyAccess", errorMsg)
            onResult(errorMsg)
            return
        }

        val accessMessage = try {
            val data = "Data to be signed".toByteArray()
            val signature = cryptoObject.signature ?: throw IllegalStateException("No signature available")
            signature.update(data)
            signedData = signature.sign() // Save the signed data

            // Convert signed data to a hex string for display
            "Key Accessed Successfully. Signed Data: ${signedData!!.joinToString("") { "%02x".format(it) }}"
        } catch (e: Exception) {
            val errorMsg = "Error accessing key: ${e.message}"
            Log.e("KeyAccess", errorMsg, e)
            errorMsg
        }
        onResult(accessMessage)
    }

    private fun verifySignature(signedKeyInput: String, onResult: (String) -> Unit) {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)

        if (!keyStore.containsAlias(alias)) {
            onResult("Error: Key does not exist.")
            return
        }

        try {
            val publicKeyEntry = keyStore.getEntry(alias, null) as KeyStore.PrivateKeyEntry
            val publicKey = publicKeyEntry.certificate.publicKey
            val signature = Signature.getInstance("SHA256withRSA")
            signature.initVerify(publicKey)

            val signedDataFromInput = signedKeyInput.chunked(2)
                .map { it.toInt(16).toByte() }
                .toByteArray()

            // For verification, you need to match against the actual signed data
            signature.update("Data to be signed".toByteArray())
            val isVerified = signature.verify(signedDataFromInput)

            if (isVerified) {
                onResult("Signature verification succeeded. The data is valid.")
            } else {
                onResult("Signature verification failed.")
            }
        } catch (e: Exception) {
            val errorMsg = "Error verifying signature: ${e.message}"
            Log.e("VerifySignature", errorMsg, e)
            onResult(errorMsg)
        }
    }

    private fun copySignedKeyToClipboard() {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = signedData?.let {
            val signedKeyHex = it.joinToString("") { "%02x".format(it) }
            android.content.ClipData.newPlainText("Signed Key", signedKeyHex)
        }
        if (clip != null) {
            clipboard.setPrimaryClip(clip)
            Log.d("Clipboard", "Signed Key copied to clipboard.")
        } else {
            Log.e("Clipboard", "No signed key available to copy.")
        }
    }
}
