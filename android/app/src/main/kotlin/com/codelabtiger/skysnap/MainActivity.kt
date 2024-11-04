package com.codelabtiger.skysnap

import android.os.Build
import io.flutter.Log
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.android.FlutterFragment
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.android.TransparencyMode
import io.flutter.embedding.engine.FlutterShellArgs

class MainActivity: FlutterFragmentActivity() {
    companion object {
        private const val TAG = "FlutterFragmentActivity"
    }

    override fun createFlutterFragment(): FlutterFragment {
        val backgroundMode = backgroundMode
        val renderMode = getRenderMode()
        val transparencyMode = 
            if (backgroundMode == BackgroundMode.opaque) TransparencyMode.opaque 
            else TransparencyMode.transparent
        val shouldDelayFirstAndroidViewDraw = renderMode == RenderMode.surface

        return when {
            // 캐시된 엔진이 있는 경우
            cachedEngineId != null -> {
                logCachedEngine()
                FlutterFragment.withCachedEngine(cachedEngineId!!)
                    .renderMode(renderMode)
                    .transparencyMode(transparencyMode)
                    .handleDeeplinking(shouldHandleDeeplinking())
                    .shouldAttachEngineToActivity(shouldAttachEngineToActivity())
                    .destroyEngineWithFragment(shouldDestroyEngineWithHost())
                    .shouldDelayFirstAndroidViewDraw(shouldDelayFirstAndroidViewDraw)
                    .shouldAutomaticallyHandleOnBackPressed(Build.VERSION.SDK_INT >= 33)
                    .build()
            }
            // 엔진 그룹이 있는 경우
            cachedEngineGroupId != null -> {
                logNewEngine()
                FlutterFragment.withNewEngineInGroup(cachedEngineGroupId!!)
                    .dartEntrypoint(dartEntrypointFunctionName)
                    .initialRoute(getInitialRoute())
                    .handleDeeplinking(shouldHandleDeeplinking())
                    .renderMode(renderMode)
                    .transparencyMode(transparencyMode)
                    .shouldAttachEngineToActivity(shouldAttachEngineToActivity())
                    .shouldDelayFirstAndroidViewDraw(shouldDelayFirstAndroidViewDraw)
                    .shouldAutomaticallyHandleOnBackPressed(Build.VERSION.SDK_INT >= 33)
                    .build()
            }
            // 새 엔진을 생성하는 경우
            else -> {
                logNewEngine()
                createNewEngineFragment(renderMode, transparencyMode, shouldDelayFirstAndroidViewDraw)
            }
        }
    }

    private fun createNewEngineFragment(
        renderMode: RenderMode,
        transparencyMode: TransparencyMode,
        shouldDelayFirstAndroidViewDraw: Boolean
    ): FlutterFragment {
        return FlutterFragment.withNewEngine().apply {
            dartEntrypoint(dartEntrypointFunctionName)
            dartEntrypointArgs(dartEntrypointArgs ?: listOf())
            initialRoute(getInitialRoute())
            appBundlePath(getAppBundlePath())
            flutterShellArgs(FlutterShellArgs.fromIntent(intent))
            handleDeeplinking(shouldHandleDeeplinking())
            renderMode(renderMode)
            transparencyMode(transparencyMode)
            shouldAttachEngineToActivity(shouldAttachEngineToActivity())
            shouldDelayFirstAndroidViewDraw(shouldDelayFirstAndroidViewDraw)
            shouldAutomaticallyHandleOnBackPressed(Build.VERSION.SDK_INT >= 33)
            
            // dartEntrypointLibraryUri가 있는 경우에만 설정
            dartEntrypointLibraryUri?.let { 
                dartLibraryUri(it)
            }
        }.build()
    }

    private fun logCachedEngine() {
        Log.v(
            TAG,
            """
            Creating FlutterFragment with cached engine:
            Cached engine ID: $cachedEngineId
            Will destroy engine when Activity is destroyed: ${shouldDestroyEngineWithHost()}
            Background transparency mode: $backgroundMode
            Will attach FlutterEngine to Activity: ${shouldAttachEngineToActivity()}
            """.trimIndent()
        )
    }

    private fun logNewEngine() {
        Log.v(
            TAG,
            """
            Creating FlutterFragment with new engine:
            Cached engine group ID: $cachedEngineGroupId
            Background transparency mode: $backgroundMode
            Dart entrypoint: $dartEntrypointFunctionName
            Dart entrypoint library uri: ${dartEntrypointLibraryUri ?: "\"\""}
            Initial route: ${getInitialRoute()}
            App bundle path: ${getAppBundlePath()}
            Will attach FlutterEngine to Activity: ${shouldAttachEngineToActivity()}
            """.trimIndent()
        )
    }
}