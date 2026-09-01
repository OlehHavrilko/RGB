package com.oleh.chromify

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Виджет главного экрана: показывает имя/статус активного устройства и
 * позволяет одним тапом переключить питание или применить пресет — тап
 * всегда открывает приложение (`ChromifyWidgetProvider` -> `MainActivity`),
 * которое тут же выполняет запрошенное действие (см. `handleWidgetLaunch`
 * в Dart), поскольку выполнение BLE-команд в фоне, без открытия
 * приложения, не проверялось на реальном железе.
 */
class ChromifyWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.chromify_widget)
      val known = widgetData.getBoolean("device_known", false)
      val deviceId = widgetData.getString("device_id", null)

      if (!known || deviceId == null) {
        views.setTextViewText(R.id.widget_name, "Chromify")
        views.setTextViewText(R.id.widget_status, "")
        views.setInt(R.id.widget_power_dot, "setColorFilter", 0x33FFFFFF)
        views.setViewVisibility(R.id.widget_preset_0, View.GONE)
        views.setViewVisibility(R.id.widget_preset_1, View.GONE)
        val openIntent =
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
        views.setOnClickPendingIntent(R.id.widget_root, openIntent)
        appWidgetManager.updateAppWidget(widgetId, views)
        return@forEach
      }

      val name = widgetData.getString("device_name", null) ?: deviceId
      val connected = widgetData.getBoolean("device_connected", false)
      val power = widgetData.getBoolean("device_power", false)
      val color = widgetData.getInt("device_color", -0x66666667)

      views.setTextViewText(R.id.widget_name, name)
      views.setTextViewText(
          R.id.widget_status,
          if (connected) (if (power) "Включено" else "Выключено") else "Не подключено",
      )
      views.setInt(
          R.id.widget_power_dot,
          "setColorFilter",
          if (power) color else 0x33FFFFFF,
      )

      val openIntent = HomeWidgetLaunchIntent.getActivity(
          context,
          MainActivity::class.java,
          Uri.parse("chromify://widget?action=open&id=$deviceId"),
      )
      views.setOnClickPendingIntent(R.id.widget_root, openIntent)

      val toggleIntent = HomeWidgetLaunchIntent.getActivity(
          context,
          MainActivity::class.java,
          Uri.parse("chromify://widget?action=toggle&id=$deviceId"),
      )
      views.setOnClickPendingIntent(R.id.widget_power_dot, toggleIntent)

      bindPreset(context, views, widgetData, deviceId, 0, R.id.widget_preset_0)
      bindPreset(context, views, widgetData, deviceId, 1, R.id.widget_preset_1)

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private fun bindPreset(
      context: Context,
      views: RemoteViews,
      widgetData: SharedPreferences,
      deviceId: String,
      index: Int,
      viewId: Int,
  ) {
    val presetId = widgetData.getString("preset_${index}_id", null)
    if (presetId == null) {
      views.setViewVisibility(viewId, View.GONE)
      return
    }
    val color = widgetData.getInt("preset_${index}_color", -0x66666667)
    views.setViewVisibility(viewId, View.VISIBLE)
    views.setInt(viewId, "setColorFilter", color)
    val presetIntent = HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        Uri.parse("chromify://widget?action=preset&id=$deviceId&preset=$presetId"),
    )
    views.setOnClickPendingIntent(viewId, presetIntent)
  }
}
