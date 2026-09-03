package io.github.coho04.easy_wallet

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

/**
 * Base for the widgets that show a picture rendered by the Flutter side.
 *
 * Rendering in Flutter keeps one drawing of the list and the calendar for both
 * platforms, and puts the subscription icons on the widget without downloading
 * them here. The provider runs in the app's own process, so it may read the
 * file and hand the bitmap over.
 */
abstract class ImageWidgetProvider(private val imageKey: String) : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val path = widgetData.getString(imageKey, null)
        val bitmap = path?.let {
            val file = File(it)
            if (file.exists()) BitmapFactory.decodeFile(file.absolutePath) else null
        }

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.image_widget)

            if (bitmap == null) {
                // Nothing rendered yet, for instance before the first launch.
                views.setViewVisibility(R.id.widget_image, android.view.View.GONE)
                views.setViewVisibility(R.id.widget_placeholder, android.view.View.VISIBLE)
            } else {
                views.setImageViewBitmap(R.id.widget_image, bitmap)
                views.setViewVisibility(R.id.widget_image, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.widget_placeholder, android.view.View.GONE)
            }

            context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { intent ->
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent.apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

/** The next ten billings as a list. */
class NextPaymentWidgetProvider : ImageWidgetProvider("upcomingImage")

/** The current month with a dot on every day something is billed. */
class CalendarWidgetProvider : ImageWidgetProvider("calendarImage")
