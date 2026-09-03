package io.github.coho04.easy_wallet

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.app.PendingIntent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Shows the next upcoming payment on the home screen.
 *
 * The values are written by the Flutter side, which owns the formatting: a
 * widget has no access to the database or the app's locale.
 */
class NextPaymentWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.next_payment_widget)

            val isEmpty = widgetData.getBoolean("nextPaymentEmpty", true)
            if (isEmpty) {
                views.setTextViewText(R.id.widget_title, context.getString(R.string.widget_nothing_due))
                views.setTextViewText(R.id.widget_amount, "")
                views.setTextViewText(R.id.widget_date, "")
            } else {
                views.setTextViewText(R.id.widget_title, widgetData.getString("nextPaymentTitle", "") ?: "")
                views.setTextViewText(R.id.widget_amount, widgetData.getString("nextPaymentAmount", "") ?: "")
                views.setTextViewText(R.id.widget_date, widgetData.getString("nextPaymentDate", "") ?: "")
            }

            // Tapping the widget opens the app.
            context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { intent ->
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
