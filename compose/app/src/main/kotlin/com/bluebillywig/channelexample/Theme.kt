package com.bluebillywig.channelexample

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// Matches RN theme.ts and SwiftUI Theme.swift
object Colors {
    val background = Color.White
    val surface = Color(0xFFF8F9FA)
    val dark = Color(0xFF32373C)
    val accent = Color(0xFF0693E3)
    val accentSecondary = Color(0xFF9B51E0)
    val text = Color(0xFF1A1A1A)
    val textMuted = Color(0xFF666666)
    val textLight = Color.White
    val border = Color(0xFFE0E0E0)
    val error = Color(0xFFE74C3C)
    val success = Color(0xFF27AE60)
}

val PUBLICATION_COLORS = mutableMapOf(
    "demo" to Color(0xFF00B894),
)

private val AD_HOC_COLORS = listOf(
    Color(0xFF74B9FF), Color(0xFFA29BFE), Color(0xFF55EFC4), Color(0xFFFAB1A0), Color(0xFFDFE6E9)
)
private var adHocIdx = 0
fun getAdHocColor(): Color = AD_HOC_COLORS[adHocIdx++ % AD_HOC_COLORS.size]

fun publicationColor(key: String): Color = PUBLICATION_COLORS[key] ?: Colors.accent

object Spacing {
    val xs = 4.dp
    val sm = 8.dp
    val md = 12.dp
    val lg = 16.dp
    val xl = 24.dp
    val xxl = 32.dp
}

object FontSize {
    val xs = 10.sp
    val sm = 12.sp
    val md = 14.sp
    val lg = 16.sp
    val xl = 20.sp
    val xxl = 24.sp
    val title = 36.sp
}
