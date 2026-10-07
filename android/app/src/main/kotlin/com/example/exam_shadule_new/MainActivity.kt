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

    // SGCreateTemplate max output buffer (ISO 19794-2 templates are larger than SG400's 400 bytes)
    private val ISO_TEMPLATE_MAX_SIZE = 2048

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
                        captureWithSecuGenSDK(call, result)
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

                    // ── Flutter se fingerprint template match request ──
                    "matchFingerprint" -> {
                        matchWithSecuGenSDK(call, result)
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

    private fun captureWithSecuGenSDK(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        // scanType decides the finger position stamped into the ISO fallback template
        val scanType = call.argument<String>("scanType") ?: "right"

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
                    // Turn on LED immediately so sensor lights up
                    sgfpLib!!.SetLedOn(true)

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

                    // 1. Wait for finger and capture using SecuGen GetImageEx (10-second timeout, quality threshold 30)
                    Log.i("SecuGenBiometric", "Waiting for finger on sensor (GetImageEx 10s timeout)...")
                    var captureError = sgfpLib!!.GetImageEx(imageBuffer, 10000L, 30L)

                    // 2. Fallback polling loop if GetImageEx did not succeed
                    if (captureError != SGFDxErrorCode.SGFDX_ERROR_NONE) {
                        Log.w("SecuGenBiometric", "GetImageEx returned $captureError, trying polling loop fallback...")
                        val startTime = System.currentTimeMillis()
                        val fingerPresent = BooleanArray(1)
                        while (System.currentTimeMillis() - startTime < 10000L) {
                            val fpErr = sgfpLib!!.FingerPresent(fingerPresent)
                            if (fpErr == SGFDxErrorCode.SGFDX_ERROR_NONE && fingerPresent[0]) {
                                val getImgErr = sgfpLib!!.GetImage(imageBuffer)
                                if (getImgErr == SGFDxErrorCode.SGFDX_ERROR_NONE) {
                                    captureError = SGFDxErrorCode.SGFDX_ERROR_NONE
                                    break
                                }
                            }
                            Thread.sleep(150)
                        }
                    }

                    if (captureError != SGFDxErrorCode.SGFDX_ERROR_NONE) {
                        runOnUiThread { result.error("CAPTURE_FAILED", "Fingerprint capture failed ($captureError). Please place your finger firmly on the sensor.", null) }
                        return@Thread
                    }

                    // Get Image Quality
                    val qualityArray = IntArray(1)
                    sgfpLib!!.GetImageQuality(width.toLong(), height.toLong(), imageBuffer, qualityArray)
                    val quality = qualityArray[0]

                    if (quality < 30) {
                        runOnUiThread { result.error("LOW_QUALITY", "Fingerprint quality is too low ($quality%). Please scan again.", null) }
                        return@Thread
                    }

                    // ── Template extraction: SG400 (enrolled format) with default SGFingerInfo, ISO only as fallback ──
                    val sgFingerInfo = SecuGen.FDxSDKPro.SGFingerInfo()
                    sgfpLib!!.SetTemplateFormat(SecuGen.FDxSDKPro.SGFDxTemplateFormat.TEMPLATE_FORMAT_SG400)
                    val templateBuffer = ByteArray(400)
                    val extractError = sgfpLib!!.CreateTemplate(sgFingerInfo, imageBuffer, templateBuffer)

                    val isoFingerInfo = SecuGen.FDxSDKPro.SGFingerInfo().apply {
                        // ISO 19794-2 position codes: 1 = right thumb, 2 = left thumb
                        FingerNumber = if (scanType == "left") 2 else 1
                        ViewNumber = 1
                        ImpressionType = 0 // live scan
                        ImageQuality = quality
                    }

                    var isoBuffer = ByteArray(ISO_TEMPLATE_MAX_SIZE)
                    var isoExtractError: Long = -1L
                    try {
                        val fmtErr = sgfpLib!!.SetTemplateFormat(SecuGen.FDxSDKPro.SGFDxTemplateFormat.TEMPLATE_FORMAT_ISO19794)
                        if (fmtErr == SGFDxErrorCode.SGFDX_ERROR_NONE) {
                            val maxSize = IntArray(1)
                            if (sgfpLib!!.GetMaxTemplateSize(maxSize) == SGFDxErrorCode.SGFDX_ERROR_NONE &&
                                maxSize[0] > isoBuffer.size
                            ) {
                                isoBuffer = ByteArray(maxSize[0])
                            }
                            isoExtractError = sgfpLib!!.CreateTemplate(isoFingerInfo, imageBuffer, isoBuffer)
                        } else {
                            isoExtractError = fmtErr
                        }
                    } catch (e: Exception) {
                        isoExtractError = -2L
                        Log.w("SecuGenBiometric", "ISO 19794-2 template creation failed: ${e.message}")
                    }
                    val isoTemplateBytes =
                        if (isoExtractError == SGFDxErrorCode.SGFDX_ERROR_NONE) trimToTemplateSize(isoBuffer) else ByteArray(0)

                    if (extractError == SGFDxErrorCode.SGFDX_ERROR_NONE) {
                        val serialNumber = try { String(deviceInfo.deviceSN()).trim { it <= ' ' } } catch (_: Exception) { "SG-HU20" }
                        val imageDpi = try { deviceInfo.imageDPI } catch (_: Exception) { 500 }
                        val fwVersion = try { deviceInfo.FWVersion.toString() } catch (_: Exception) { "V1.0" }
                        val brightness = try { deviceInfo.brightness } catch (_: Exception) { 100 }
                        val contrast = try { deviceInfo.contrast } catch (_: Exception) { 100 }
                        val gain = try { deviceInfo.gain } catch (_: Exception) { 2 }

                        Log.i("SecuGenBiometric", "=======================================================")
                        Log.i("SecuGenBiometric", "✅ [NATIVE] SECUGEN FINGERPRINT CAPTURED CLEAR DATA")
                        Log.i("SecuGenBiometric", "Status: SUCCESS | Quality: $quality%")
                        Log.i("SecuGenBiometric", "Dimensions: ${width}x${height} px | DPI: $imageDpi")
                        Log.i("SecuGenBiometric", "Template Length: ${templateBuffer.size} bytes (SG400) | ${isoTemplateBytes.size} bytes (ISO 19794-2, err=$isoExtractError) | Raw Image: ${imageBuffer.size} bytes")
                        Log.i("SecuGenBiometric", "Serial Number: $serialNumber | FW: $fwVersion | ScanType: $scanType")
                        Log.i("SecuGenBiometric", "=======================================================")

                        runOnUiThread {
                            result.success(mapOf(
                                "success"      to true,
                                "image"        to imageBuffer,
                                "template"     to templateBuffer,
                                "isoTemplate"  to isoTemplateBytes,
                                "scanType"     to scanType,
                                "width"        to width,
                                "height"       to height,
                                "quality"      to quality,
                                "serialNumber" to serialNumber,
                                "imageDPI"     to imageDpi,
                                "fwVersion"    to fwVersion,
                                "brightness"   to brightness,
                                "contrast"     to contrast,
                                "gain"         to gain,
                                "deviceName"   to (secugenDevice?.deviceName ?: "SecuGen HU20"),
                                "vendorId"     to (secugenDevice?.vendorId?.toString() ?: "4450"),
                                "productId"    to (secugenDevice?.productId?.toString() ?: "")
                            ))
                        }
                    } else {
                        runOnUiThread { result.error("TEMPLATE_FAILED", "Template creation failed: $extractError", null) }
                    }
                } catch (e: Exception) {
                    runOnUiThread { result.error("EXCEPTION", "SecuGen capture error: ${e.message}", null) }
                } finally {
                    try {
                        sgfpLib?.SetLedOn(false)
                        sgfpLib?.CloseDevice()
                    } catch (_: Exception) {}
                }
            } catch (e: Exception) {
                runOnUiThread { result.error("EXCEPTION", "SecuGen thread error: ${e.message}", null) }
            }
        }.start()
    }

    // ── Template format helpers ─────────────────────────────────────────
    // SecuGen match APIs format-specific hain (SG400 vs ISO vs ANSI), isliye blob ka format pehchanta hai
    private fun templateFormatName(t: ByteArray): String {
        if (t.size >= 4) {
            val b0 = t[0].toInt() and 0xFF
            val b1 = t[1].toInt() and 0xFF
            val b2 = t[2].toInt() and 0xFF
            val b3 = t[3].toInt() and 0xFF
            val sourceIdOk = (b0 == 0x49 && b1 == 0x49) || (b0 == 0x4D && b1 == 0x4D) // "II" / "MM"
            if (sourceIdOk && b2 == 0x52) { // 'R'
                // Version id "RO"/"IR" = ISO/IEC 19794-2, NUL terminated = ANSI INCITS 381
                return if (b3 == 0x4F || b3 == 0x49) "ISO" else "ANSI"
            }
            if (b0 == 0x53 && b1 == 0x47) return "SG400" // "SG"
        }
        if (t.size == 400) return "SG400"
        return "UNKNOWN"
    }

    private fun formatCode(name: String): Short = when (name) {
        "ISO" -> SecuGen.FDxSDKPro.SGFDxTemplateFormat.TEMPLATE_FORMAT_ISO19794
        "ANSI" -> SecuGen.FDxSDKPro.SGFDxTemplateFormat.TEMPLATE_FORMAT_ANSI378
        "SG400" -> SecuGen.FDxSDKPro.SGFDxTemplateFormat.TEMPLATE_FORMAT_SG400
        else -> SecuGen.FDxSDKPro.SGFDxTemplateFormat.TEMPLATE_FORMAT_ISO19794
    }

    /** Enrolment systems often pad the stored blob; ask the SDK for the real template length. */
    private fun trimToTemplateSize(t: ByteArray): ByteArray {
        // SG400 templates are exactly 400 bytes — trimming one would corrupt it
        if (templateFormatName(t) == "SG400") return t
        return try {
            val sizeArr = IntArray(1)
            val err = sgfpLib!!.GetTemplateSize(t, sizeArr)
            val s = sizeArr[0]
            if (err == SGFDxErrorCode.SGFDX_ERROR_NONE && s in 32 until t.size) t.copyOf(s) else t
        } catch (_: Exception) {
            t
        }
    }

    private fun hexPrefix(t: ByteArray, n: Int = 8): String =
        t.take(minOf(n, t.size)).joinToString("") { (it.toInt() and 0xFF).toString(16).padStart(2, '0') }

    /** Match one live/enrolled pair, trying SL_NORMAL then the more lenient SL_BELOW_NORMAL. */
    private fun matchPair(
        live: ByteArray,
        liveFmt: Short,
        enrolled: ByteArray,
        enrolledFmt: Short,
        matchedOut: BooleanArray
    ): Long {
        var lastErr = SGFDxErrorCode.SGFDX_ERROR_NONE
        for (sl in longArrayOf(
            SecuGen.FDxSDKPro.SGFDxSecurityLevel.SL_NORMAL,
            SecuGen.FDxSDKPro.SGFDxSecurityLevel.SL_BELOW_NORMAL
        )) {
            val matched = BooleanArray(1)
            val err = if (liveFmt == enrolledFmt) {
                when (liveFmt) {
                    SecuGen.FDxSDKPro.SGFDxTemplateFormat.TEMPLATE_FORMAT_SG400 ->
                        sgfpLib!!.MatchTemplate(live, enrolled, sl, matched)
                    SecuGen.FDxSDKPro.SGFDxTemplateFormat.TEMPLATE_FORMAT_ANSI378 ->
                        sgfpLib!!.MatchAnsiTemplate(live, live.size.toLong(), enrolled, enrolled.size.toLong(), sl, matched)
                    else ->
                        sgfpLib!!.MatchIsoTemplate(live, live.size.toLong(), enrolled, enrolled.size.toLong(), sl, matched)
                }
            } else {
                sgfpLib!!.MatchTemplateEx(
                    live, liveFmt, live.size.toLong(),
                    enrolled, enrolledFmt, enrolled.size.toLong(),
                    sl, matched
                )
            }
            lastErr = err
            if (matched[0]) {
                matchedOut[0] = true
                return SGFDxErrorCode.SGFDX_ERROR_NONE
            }
            // Non-zero error = format/API rejection, retrying at another security level is pointless
            if (err != SGFDxErrorCode.SGFDX_ERROR_NONE) return err
        }
        return lastErr
    }

    private fun matchingScore(
        live: ByteArray,
        liveFmt: Short,
        enrolled: ByteArray,
        enrolledFmt: Short
    ): Int {
        val arr = IntArray(1)
        val err = if (liveFmt == enrolledFmt) {
            when (liveFmt) {
                SecuGen.FDxSDKPro.SGFDxTemplateFormat.TEMPLATE_FORMAT_SG400 ->
                    sgfpLib!!.GetMatchingScore(live, enrolled, arr)
                SecuGen.FDxSDKPro.SGFDxTemplateFormat.TEMPLATE_FORMAT_ANSI378 ->
                    sgfpLib!!.GetAnsiMatchingScore(live, live.size.toLong(), enrolled, enrolled.size.toLong(), arr)
                else ->
                    sgfpLib!!.GetIsoMatchingScore(live, live.size.toLong(), enrolled, enrolled.size.toLong(), arr)
            }
        } else {
            sgfpLib!!.GetMatchingScoreEx(
                live, liveFmt, live.size.toLong(),
                enrolled, enrolledFmt, enrolled.size.toLong(), arr
            )
        }
        val raw = arr[0]
        return if (err == SGFDxErrorCode.SGFDX_ERROR_NONE && raw in 1..200) minOf(raw, 100) else 85
    }

    private fun matchWithSecuGenSDK(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        val liveSg400 = call.argument<ByteArray>("template1")
        val liveIso = call.argument<ByteArray>("isoTemplate1")
        val enrolled = call.argument<ByteArray>("template2")

        if (enrolled == null || enrolled.isEmpty()) {
            result.error("NO_ENROLLED_TEMPLATE", "Enrolled biometric template is empty.", null)
            return
        }
        val hasLive = (liveSg400 != null && liveSg400.isNotEmpty()) || (liveIso != null && liveIso.isNotEmpty())
        if (!hasLive) {
            result.error("NO_LIVE_TEMPLATE", "Live scan produced no template. Please scan the finger again.", null)
            return
        }

        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        if (sgfpLib == null) {
            sgfpLib = JSGFPLib(this, usbManager)
        }

        Thread {
            try {
                val initErr = sgfpLib!!.Init(SGFDxDeviceName.SG_DEV_AUTO)
                if (initErr != SGFDxErrorCode.SGFDX_ERROR_NONE) {
                    runOnUiThread { result.error("SDK_INIT_FAILED", "SecuGen Init failed: $initErr", null) }
                    return@Thread
                }
                // Matcher default SG400 par rakho; ISO/ANSI wale explicit-format APIs use hote hain
                sgfpLib!!.SetTemplateFormat(SecuGen.FDxSDKPro.SGFDxTemplateFormat.TEMPLATE_FORMAT_SG400)

                val enrolledTrimmed = trimToTemplateSize(enrolled)
                val enrolledName = templateFormatName(enrolledTrimmed)
                // Header se format na mila ho tab hi ANSI/SG400 guesses try karo
                val enrolledGuesses =
                    if (enrolledName != "UNKNOWN") listOf(enrolledName) else listOf("ISO", "ANSI", "SG400")

                val liveIsoTrimmed = liveIso?.takeIf { it.isNotEmpty() }?.let { trimToTemplateSize(it) }
                val liveSgTrimmed = liveSg400?.takeIf { it.isNotEmpty() }
                val livePairs = ArrayList<Pair<ByteArray, String>>()
                // Same-format candidate pehle try hota hai — usi ka error result me report hota hai
                if (enrolledName == "SG400") {
                    liveSgTrimmed?.let { livePairs.add(Pair(it, "LIVE_SG400")) }
                    liveIsoTrimmed?.let { livePairs.add(Pair(it, "LIVE_ISO")) }
                } else {
                    liveIsoTrimmed?.let { livePairs.add(Pair(it, "LIVE_ISO")) }
                    liveSgTrimmed?.let { livePairs.add(Pair(it, "LIVE_SG400")) }
                }

                var matched = false
                var finalScore = 0
                var primaryErr: Long? = null
                var usedMethod = "none"
                val matchedFlag = BooleanArray(1)

                outer@ for (enrolledGuess in enrolledGuesses) {
                    val eFmt = formatCode(enrolledGuess)
                    for ((live, liveLabel) in livePairs) {
                        val lFmt = formatCode(if (liveLabel == "LIVE_SG400") "SG400" else "ISO")
                        matchedFlag[0] = false
                        val err = matchPair(live, lFmt, enrolledTrimmed, eFmt, matchedFlag)
                        // Pehla attempt (detected format wala) authoritative hai — uska hi error report karo
                        if (primaryErr == null) primaryErr = err
                        if (usedMethod == "none") usedMethod = "$liveLabel/$enrolledGuess"
                        if (matchedFlag[0]) {
                            matched = true
                            finalScore = matchingScore(live, lFmt, enrolledTrimmed, eFmt)
                            usedMethod = "$liveLabel/$enrolledGuess"
                            break@outer
                        }
                    }
                }

                val lastErr = primaryErr ?: SGFDxErrorCode.SGFDX_ERROR_NONE
                val technicalError = !matched && lastErr != SGFDxErrorCode.SGFDX_ERROR_NONE
                Log.i(
                    "SecuGenBiometric",
                    "Match -> matched=$matched score=$finalScore err=$lastErr method=$usedMethod " +
                        "enrolledFormat=$enrolledName enrolledSize=${enrolledTrimmed.size} " +
                        "enrolledHeader=${hexPrefix(enrolledTrimmed)} liveIsoSize=${liveIso?.size ?: 0} " +
                        "liveSg400Size=${liveSg400?.size ?: 0}"
                )

                runOnUiThread {
                    result.success(mapOf(
                        "matched" to matched,
                        "score" to finalScore,
                        "errorCode" to lastErr,
                        "technicalError" to technicalError,
                        "enrolledFormat" to enrolledName,
                        "enrolledSize" to enrolledTrimmed.size,
                        "liveIsoSize" to (liveIso?.size ?: 0),
                        "method" to usedMethod
                    ))
                }
            } catch (e: Exception) {
                Log.e("SecuGenBiometric", "Template match exception: ${e.message}")
                runOnUiThread {
                    result.error("MATCH_EXCEPTION", e.message, null)
                }
            }
        }.start()
    }
}
