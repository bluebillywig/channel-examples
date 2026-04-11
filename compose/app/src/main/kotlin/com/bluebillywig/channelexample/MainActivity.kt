package com.bluebillywig.channelexample

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            var screen by remember { mutableStateOf<Screen>(Screen.Browser) }

            BackHandler(screen !is Screen.Browser) {
                screen = Screen.Browser
            }

            when (val s = screen) {
                is Screen.Browser -> ChannelBrowserScreen(
                    onSelectChannel = { url, name, host ->
                        screen = Screen.Viewer(url, name, host)
                    },
                    onOpenSettings = { screen = Screen.Settings },
                )
                is Screen.Viewer -> ChannelViewerScreen(
                    channelUrl = s.channelUrl,
                    channelName = s.channelName,
                    onBack = { screen = Screen.Browser },
                )
                is Screen.Settings -> SettingsScreen(
                    onBack = { screen = Screen.Browser },
                )
            }
        }
    }
}
