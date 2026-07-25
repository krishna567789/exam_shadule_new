package com.example.exam_shadule_new

import android.content.Context
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// ============================================================
// SecuGen FDx SDK Integration
// HU20 (Hamster IV) ke liye — koi RD Service, koi certificate nahi chahiye
// SDK download: https://www.secugen.com/products/sdk_android.htm
// ============================================================

// NOTE: Ye imports SDK add karne ke baad uncomment karo:
import SecuGen.FDxSDKPro.JSGFPLib
import SecuGen.FDxSDKPro.SGFDxDeviceName
import SecuGen.FDxSDKPro.SGFDxErrorCode
import SecuGen.FDxSDKPro.SGDeviceInfoParam

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "com.example.exam_shadule_new/rd_service"
    private val ACTION_USB_PERMISSION = "com.example.exam_shadule_new.USB_PERMISSION"

    // SecuGen SDK object
    private var sgfpLib: JSGFPLib? = null

    // USB image dimensions for HU20
    private val IMAGE_WIDTH  = 260
    private val IMAGE_HEIGHT = 300

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize JSGFPLib ONCE on Main UI Thread (as required by Android & SecuGen SDK)
        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        if (sgfpLib == null) {
            sgfpLib = JSGFPLib(this, usbManager)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── Flutter se fingerprint capture request ──
                    "captureFingerprint" -> {
                        captureWithSecuGenSDK(result)
                    }

                    // ── Flutter se capture cancel request ──
                    "cancelCapture" -> {
                        try {
                            sgfpLib?.CloseDevice()
                        } catch (_: Exception) {}
                        result.success(true)
                    }

                    // ── Connected USB devices ki list ──
                    "checkUsbDevices" -> {
                        val mgr = getSystemService(Context.USB_SERVICE) as UsbManager
                        val devices = mgr.deviceList
                        val deviceNames = devices.values.map {
                            "VID:${it.vendorId.toString(16).uppercase()} PID:${it.productId.toString(16).uppercase()} — ${it.deviceName}"
                        }
                        result.success(mapOf(
                            "count" to devices.size,
                            "devices" to deviceNames
                        ))
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            sgfpLib?.CloseDevice()
        } catch (_: Exception) {}
    }

    private fun captureWithSecuGenSDK(result: MethodChannel.Result) {
        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager

        // Ensure JSGFPLib is initialized on Main Thread
        if (sgfpLib == null) {
            sgfpLib = JSGFPLib(this, usbManager)
        }

        // 1. First find any connected SecuGen USB scanner (HU20 / HU20AP / Hamster IV)
        val secugenDevice = usbManager.deviceList.values.find { it.vendorId == 0x1162 || it.vendorId == 4450 }

        if (secugenDevice == null) {
            result.error("DEVICE_NOT_FOUND", "SecuGen device not found by Android USB Manager.", null)
            return
        }

        // 2. Request OTG permission on Main Thread BEFORE opening
        if (!usbManager.hasPermission(secugenDevice)) {
            val flag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val intent = Intent(ACTION_USB_PERMISSION).apply {
                setPackage(packageName)
            }
            val permissionIntent = PendingIntent.getBroadcast(this, 0, intent, flag)
            usbManager.requestPermission(secugenDevice, permissionIntent)
            result.error("PERMISSION_REQUIRED", "OTG permission required. Prompting user...", null)
            return
        }

        // 3. Perform capture on Background Thread using exact logic from SecuGenBiometric BiometricManager
        Thread {
            try {
                // Exact Init & OpenDevice sequence from BiometricManager.kt
                var error = sgfpLib!!.Init(SGFDxDeviceName.SG_DEV_AUTO)
                if (error != SGFDxErrorCode.SGFDX_ERROR_NONE) {
                    runOnUiThread { result.error("SDK_INIT_FAILED", "SecuGen Init failed: $error", null) }
                    return@Thread
                }

                error = sgfpLib!!.OpenDevice(SGFDxDeviceName.SG_DEV_AUTO)
                if (error != SGFDxErrorCode.SGFDX_ERROR_NONE) {
                    runOnUiThread { result.error("DEVICE_OPEN_FAILED", "SecuGen OpenDevice failed: $error", null) }
                    return@Thread
                }

                try {
                    val deviceInfo = SGDeviceInfoParam()
                    sgfpLib!!.GetDeviceInfo(deviceInfo)
                    var width = if (deviceInfo.imageWidth > 0) deviceInfo.imageWidth else IMAGE_WIDTH
                    var height = if (deviceInfo.imageHeight > 0) deviceInfo.imageHeight else IMAGE_HEIGHT

                    // Ensure buffer safety for AP models
                    if (width < 260 || height < 300) {
                        width = IMAGE_WIDTH
                        height = IMAGE_HEIGHT
                    }

                    // Image capture with exact dimension buffer
                    val imageBuffer = ByteArray(width * height)
                    error = sgfpLib!!.GetImage(imageBuffer)

                    if (error != SGFDxErrorCode.SGFDX_ERROR_NONE) {
                        runOnUiThread { result.error("CAPTURE_FAILED", "Fingerprint capture failed: $error. Please place your finger on the sensor.", null) }
                        return@Thread
                    }

                    // Get Image Quality
                    val qualityArray = IntArray(1)
                    sgfpLib!!.GetImageQuality(width.toLong(), height.toLong(), imageBuffer, qualityArray)
                    val quality = qualityArray[0]

                    if (quality < 35) {
                        runOnUiThread { result.error("LOW_QUALITY", "Fingerprint quality is too low ($quality%). Please scan again.", null) }
                        return@Thread
                    }

                    // Extract Template (exact 400 bytes or dynamic buffer as used in BiometricManager)
                    val templateBuffer = ByteArray(400)
                    val fingerInfo = SecuGen.FDxSDKPro.SGFingerInfo()
                    val extractError = sgfpLib!!.CreateTemplate(fingerInfo, imageBuffer, templateBuffer)

                    if (extractError == SGFDxErrorCode.SGFDX_ERROR_NONE) {
                        runOnUiThread {
                            result.success(mapOf(
                                "success"  to true,
                                "image"    to imageBuffer,
                                "template" to templateBuffer,
                                "width"    to width,
                                "height"   to height,
                                "quality"  to quality
                            ))
                        }
                    } else {
                        runOnUiThread { result.error("TEMPLATE_FAILED", "Template creation failed: $extractError", null) }
                    }
                } catch (e: Exception) {
                    runOnUiThread { result.error("EXCEPTION", "SecuGen capture error: ${e.message}", null) }
                }
            } catch (e: Exception) {
                runOnUiThread { result.error("EXCEPTION", "SecuGen thread error: ${e.message}", null) }
            }
        }.start()
    }
}
