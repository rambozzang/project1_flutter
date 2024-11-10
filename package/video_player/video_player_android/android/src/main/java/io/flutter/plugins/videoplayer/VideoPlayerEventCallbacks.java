package io.flutter.plugins.videoplayer;

import io.flutter.plugin.common.EventChannel;

public class VideoPlayerEventCallbacks {
    public static EventChannel.StreamHandler bindTo(final EventChannel eventChannel) {
        return new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                // 이벤트 리스너 설정
            }

            @Override
            public void onCancel(Object arguments) {
                // 이벤트 리스너 해제
            }
        };
    }
}
