package com.bluebillywig.channelexample

const val DEV_MODE = false
const val CDN_DEV_BUNDLE_URL = "https://cdn.bluebillywig.com/apps/channel/latest/channel-native.js"

fun getBundleUrl(env: String, customUrl: String?): String {
    if (!customUrl.isNullOrBlank()) return customUrl
    if (DEV_MODE) return "https://cdn.bluebillywig.com/apps/channel/latest/channel-native.js" // Android emulator → host
    if (env == "dev") return CDN_DEV_BUNDLE_URL
    val host = if (env == "prod") "cdn.bluebillywig.com" else "cdn-$env.bluebillywig.com"
    return "https://$host/apps/channel/latest/channel-native.js"
}

fun getChannelUrl(host: String, id: String): String = "https://$host/ch/$id.json"
