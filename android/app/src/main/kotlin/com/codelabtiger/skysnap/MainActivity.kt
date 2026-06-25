package com.codelabtiger.skysnap

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity()
// class MainActivity: FlutterFragmentActivity() {
//     private val TAG = "FlutterFragmentActivity"

//     // This is same as FlutterFragmentActivity.createFlutterFragment(), but only difference is shouldAutomaticallyHandleOnBackPressed(Build.VERSION.SDK_INT >= 33) added.
//     // See the https://github.com/flutter/flutter/issues/117061
//     override fun createFlutterFragment(): FlutterFragment {
//         val backgroundMode = backgroundMode
//         val renderMode = getRenderMode()
//         val transparencyMode =
//             if (backgroundMode == BackgroundMode.opaque) TransparencyMode.opaque else TransparencyMode.transparent
//         val shouldDelayFirstAndroidViewDraw = renderMode == RenderMode.surface
//         if (cachedEngineId != null) {
//             Log.v(
//                 TAG,
//                 "Creating FlutterFragment with cached engine:\n"
//                         + "Cached engine ID: "
//                         + cachedEngineId
//                         + "\n"
//                         + "Will destroy engine when Activity is destroyed: "
//                         + shouldDestroyEngineWithHost()
//                         + "\n"
//                         + "Background transparency mode: "
//                         + backgroundMode
//                         + "\n"
//                         + "Will attach FlutterEngine to Activity: "
//                         + shouldAttachEngineToActivity()
//             )
//             return FlutterFragment.withCachedEngine((cachedEngineId)!!)
//                 .renderMode(renderMode)
//                 .transparencyMode(transparencyMode)
//                 .handleDeeplinking(shouldHandleDeeplinking())
//                 .shouldAttachEngineToActivity(shouldAttachEngineToActivity())
//                 .destroyEngineWithFragment(shouldDestroyEngineWithHost())
//                 .shouldDelayFirstAndroidViewDraw(shouldDelayFirstAndroidViewDraw)
//                 .shouldAutomaticallyHandleOnBackPressed(Build.VERSION.SDK_INT >= 33)
//                 .build()
//         } else {
//             Log.v(
//                 TAG,
//                 ("Creating FlutterFragment with new engine:\n"
//                         + "Cached engine group ID: "
//                         + cachedEngineGroupId
//                         + "\n"
//                         + "Background transparency mode: "
//                         + backgroundMode
//                         + "\n"
//                         + "Dart entrypoint: "
//                         + dartEntrypointFunctionName
//                         + "\n"
//                         + "Dart entrypoint library uri: "
//                         + (if (dartEntrypointLibraryUri != null) dartEntrypointLibraryUri else "\"\"")
//                         + "\n"
//                         + "Initial route: "
//                         + getInitialRoute()
//                         + "\n"
//                         + "App bundle path: "
//                         + getAppBundlePath()
//                         + "\n"
//                         + "Will attach FlutterEngine to Activity: "
//                         + shouldAttachEngineToActivity())
//             )
//             return if (cachedEngineGroupId != null) {
//                 FlutterFragment.withNewEngineInGroup((cachedEngineGroupId)!!)
//                     .dartEntrypoint(dartEntrypointFunctionName)
//                     .initialRoute(getInitialRoute())
//                     .handleDeeplinking(shouldHandleDeeplinking())
//                     .renderMode(renderMode)
//                     .transparencyMode(transparencyMode)
//                     .shouldAttachEngineToActivity(shouldAttachEngineToActivity())
//                     .shouldDelayFirstAndroidViewDraw(shouldDelayFirstAndroidViewDraw)
//                     .shouldAutomaticallyHandleOnBackPressed(Build.VERSION.SDK_INT >= 33)
//                     .build()
//             } else {
//                return if (dartEntrypointLibraryUri == null) {
//                     FlutterFragment.withNewEngine()
//                         .dartEntrypoint(dartEntrypointFunctionName)
//                         .dartEntrypointArgs((dartEntrypointArgs) ?: listOf<String>())
//                         .initialRoute(getInitialRoute())
//                         .appBundlePath(getAppBundlePath())
//                         .flutterShellArgs(FlutterShellArgs.fromIntent(intent))
//                         .handleDeeplinking(shouldHandleDeeplinking())
//                         .renderMode(renderMode)
//                         .transparencyMode(transparencyMode)
//                         .shouldAttachEngineToActivity(shouldAttachEngineToActivity())
//                         .shouldDelayFirstAndroidViewDraw(shouldDelayFirstAndroidViewDraw)
//                         .shouldAutomaticallyHandleOnBackPressed(Build.VERSION.SDK_INT >= 33)
//                         .build()
//                 } else
//                 FlutterFragment.withNewEngine()
//                     .dartEntrypoint(dartEntrypointFunctionName)
//                     .dartLibraryUri((dartEntrypointLibraryUri)!!)
//                     .dartEntrypointArgs((dartEntrypointArgs) ?: listOf<String>())
//                     .initialRoute(getInitialRoute())
//                     .appBundlePath(getAppBundlePath())
//                     .flutterShellArgs(FlutterShellArgs.fromIntent(intent))
//                     .handleDeeplinking(shouldHandleDeeplinking())
//                     .renderMode(renderMode)
//                     .transparencyMode(transparencyMode)
//                     .shouldAttachEngineToActivity(shouldAttachEngineToActivity())
//                     .shouldDelayFirstAndroidViewDraw(shouldDelayFirstAndroidViewDraw)
//                     .shouldAutomaticallyHandleOnBackPressed(Build.VERSION.SDK_INT >= 33)
//                     .build()
//             }
//         }
//     }
// }

// import android.os.Build
// import io.flutter.Log
// import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
// import io.flutter.embedding.android.FlutterFragment
// import io.flutter.embedding.android.FlutterFragmentActivity
// import io.flutter.embedding.android.RenderMode
// import io.flutter.embedding.android.TransparencyMode
// import io.flutter.embedding.engine.FlutterShellArgs

// class MainActivity: FlutterFragmentActivity() {
//     companion object {
//         private const val TAG = "FlutterFragmentActivity"
//     }

//     override fun createFlutterFragment(): FlutterFragment {
//         val backgroundMode = backgroundMode
//         val renderMode = getRenderMode()
//         val transparencyMode = 
//             if (backgroundMode == BackgroundMode.opaque) TransparencyMode.opaque 
//             else TransparencyMode.transparent
//         val shouldDelayFirstAndroidViewDraw = renderMode == RenderMode.surface

//         return when {
//             // 캐시된 엔진이 있는 경우
//             cachedEngineId != null -> {
//                 // logCachedEngine()
//                 FlutterFragment.withCachedEngine(cachedEngineId!!)
//                     .renderMode(renderMode)
//                     .transparencyMode(transparencyMode)
//                     .handleDeeplinking(shouldHandleDeeplinking())
//                     .shouldAttachEngineToActivity(shouldAttachEngineToActivity())
//                     .destroyEngineWithFragment(shouldDestroyEngineWithHost())
//                     .shouldDelayFirstAndroidViewDraw(shouldDelayFirstAndroidViewDraw)
//                     .shouldAutomaticallyHandleOnBackPressed(Build.VERSION.SDK_INT >= 33)
//                     .build()
//             }
//             // 엔진 그룹이 있는 경우
//             cachedEngineGroupId != null -> {
//                // logNewEngine()
//                 FlutterFragment.withNewEngineInGroup(cachedEngineGroupId!!)
//                     .dartEntrypoint(dartEntrypointFunctionName)
//                     .initialRoute(getInitialRoute())
//                     .handleDeeplinking(shouldHandleDeeplinking())
//                     .renderMode(renderMode)
//                     .transparencyMode(transparencyMode)
//                     .shouldAttachEngineToActivity(shouldAttachEngineToActivity())
//                     .shouldDelayFirstAndroidViewDraw(shouldDelayFirstAndroidViewDraw)
//                     .shouldAutomaticallyHandleOnBackPressed(Build.VERSION.SDK_INT >= 33)
//                     .build()
//             }
//             // 새 엔진을 생성하는 경우
//             else -> {
//                // logNewEngine()
//                 createNewEngineFragment(renderMode, transparencyMode, shouldDelayFirstAndroidViewDraw)
//             }
//         }
//     }

//     private fun createNewEngineFragment(
//         renderMode: RenderMode,
//         transparencyMode: TransparencyMode,
//         shouldDelayFirstAndroidViewDraw: Boolean
//     ): FlutterFragment {
//         return FlutterFragment.withNewEngine().apply {
//             dartEntrypoint(dartEntrypointFunctionName)
//             dartEntrypointArgs(dartEntrypointArgs ?: listOf())
//             initialRoute(getInitialRoute())
//             appBundlePath(getAppBundlePath())
//             flutterShellArgs(FlutterShellArgs.fromIntent(intent))
//             handleDeeplinking(shouldHandleDeeplinking())
//             renderMode(renderMode)
//             transparencyMode(transparencyMode)
//             shouldAttachEngineToActivity(shouldAttachEngineToActivity())
//             shouldDelayFirstAndroidViewDraw(shouldDelayFirstAndroidViewDraw)
//             shouldAutomaticallyHandleOnBackPressed(Build.VERSION.SDK_INT >= 33)
            
//             // dartEntrypointLibraryUri가 있는 경우에만 설정
//             dartEntrypointLibraryUri?.let { 
//                 dartLibraryUri(it)
//             }
//         }.build()
//     }

//     private fun logCachedEngine() {
//         Log.v(
//             TAG,
//             """
//             Creating FlutterFragment with cached engine:
//             Cached engine ID: $cachedEngineId
//             Will destroy engine when Activity is destroyed: ${shouldDestroyEngineWithHost()}
//             Background transparency mode: $backgroundMode
//             Will attach FlutterEngine to Activity: ${shouldAttachEngineToActivity()}
//             """.trimIndent()
//         )
//     }

//     private fun logNewEngine() {
//         Log.v(
//             TAG,
//             """
//             Creating FlutterFragment with new engine:
//             Cached engine group ID: $cachedEngineGroupId
//             Background transparency mode: $backgroundMode
//             Dart entrypoint: $dartEntrypointFunctionName
//             Dart entrypoint library uri: ${dartEntrypointLibraryUri ?: "\"\""}
//             Initial route: ${getInitialRoute()}
//             App bundle path: ${getAppBundlePath()}
//             Will attach FlutterEngine to Activity: ${shouldAttachEngineToActivity()}
//             """.trimIndent()
//         )
//     }
// }