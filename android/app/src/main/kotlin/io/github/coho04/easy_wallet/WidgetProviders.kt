package io.github.coho04.easy_wallet

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.io.File

/**
 * Shared plumbing for both widgets.
 *
 * The Flutter side used to render a picture and this only showed it. A picture
 * keeps the background it was drawn with, so a phone switching to dark mode was
 * left with a white block, and it never looked like a list. The rows are built
 * here now; only the favicons are still files, because downloading them from a
 * widget is not worth it.
 */
abstract class JsonWidgetProvider(
    private val dataKey: String,
    private val layoutId: Int
) : HomeWidgetProvider() {

    protected abstract fun bind(context: Context, views: RemoteViews, json: JSONObject)

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val raw = widgetData.getString(dataKey, null)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, layoutId)

            val json = raw?.takeIf { it.isNotEmpty() }?.let {
                runCatching { JSONObject(it) }.getOrNull()
            }

            if (json == null) {
                views.setViewVisibility(R.id.widget_message, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_message,
                    context.getString(R.string.widget_no_data)
                )
            } else {
                views.setViewVisibility(R.id.widget_message, View.GONE)
                bind(context, views, json)
            }

            openAppOnTap(context, views)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun openAppOnTap(context: Context, views: RemoteViews) {
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
    }

    /** "#RRGGBB" as the app wrote it, or null to leave the default colour. */
    protected fun parseColor(hex: String?): Int? {
        if (hex.isNullOrEmpty()) return null
        return runCatching { Color.parseColor(hex) }.getOrNull()
    }
}

/** The next billings as a list. */
class NextPaymentWidgetProvider :
    JsonWidgetProvider("upcomingData", R.layout.upcoming_widget) {

    override fun bind(context: Context, views: RemoteViews, json: JSONObject) {
        val items = json.optJSONArray("items")
        views.removeAllViews(R.id.widget_rows)

        if (items == null || items.length() == 0) {
            views.setViewVisibility(R.id.widget_message, View.VISIBLE)
            views.setTextViewText(
                R.id.widget_message,
                context.getString(R.string.widget_nothing_due)
            )
            return
        }

        for (index in 0 until items.length()) {
            val item = items.optJSONObject(index) ?: continue
            val row = RemoteViews(context.packageName, R.layout.upcoming_widget_row)

            val days = item.optInt("days")
            row.setTextViewText(
                R.id.row_days,
                if (days == 0) {
                    context.getString(R.string.widget_today)
                } else {
                    context.getString(R.string.widget_days_short, days)
                }
            )
            row.setTextViewText(R.id.row_title, item.optString("title"))
            row.setTextViewText(R.id.row_amount, item.optString("amount"))

            val iconPath = item.optString("icon")
            val bitmap = iconPath.takeIf { it.isNotEmpty() }
                ?.let { File(it) }
                ?.takeIf { it.exists() }
                ?.let { BitmapFactory.decodeFile(it.absolutePath) }

            if (bitmap == null) {
                row.setViewVisibility(R.id.row_icon, View.INVISIBLE)
            } else {
                row.setImageViewBitmap(R.id.row_icon, bitmap)
                row.setViewVisibility(R.id.row_icon, View.VISIBLE)
            }

            views.addView(R.id.widget_rows, row)
        }
    }
}

/** The current month with a dot on every day something is billed. */
class CalendarWidgetProvider :
    JsonWidgetProvider("calendarData", R.layout.calendar_widget) {

    override fun bind(context: Context, views: RemoteViews, json: JSONObject) {
        views.setTextViewText(R.id.calendar_title, json.optString("title"))
        views.setTextViewText(R.id.calendar_total, json.optString("total"))
        views.removeAllViews(R.id.calendar_weeks)

        val dayCount = json.optInt("dayCount")
        if (dayCount <= 0) return

        val leadingBlanks = json.optInt("leadingBlanks")
        val today = json.optInt("today")
        val marks = json.optJSONObject("marks")

        // A month spans at most six weeks, and every week is a full row so the
        // columns line up under each other.
        var cell = 0
        val cells = leadingBlanks + dayCount
        while (cell < cells) {
            val week = RemoteViews(context.packageName, R.layout.calendar_widget_week)

            for (column in 0 until 7) {
                val day = cell - leadingBlanks + 1
                week.addView(
                    R.id.week_root,
                    dayCell(context, day.takeIf { cell >= leadingBlanks && it <= dayCount }, today, marks)
                )
                cell++
            }

            views.addView(R.id.calendar_weeks, week)
        }
    }

    private fun dayCell(
        context: Context,
        day: Int?,
        today: Int,
        marks: JSONObject?
    ): RemoteViews {
        val cell = RemoteViews(context.packageName, R.layout.calendar_widget_day)
        cell.removeAllViews(R.id.day_marks)

        if (day == null) {
            cell.setTextViewText(R.id.day_number, "")
            return cell
        }

        cell.setTextViewText(R.id.day_number, day.toString())
        if (day == today) {
            cell.setTextColor(
                R.id.day_number,
                context.getColor(android.R.color.holo_blue_light)
            )
        }

        val colors = marks?.optJSONArray(day.toString()) ?: return cell
        // More than three dots would not be legible at this size.
        for (index in 0 until minOf(colors.length(), 3)) {
            val dot = RemoteViews(context.packageName, R.layout.calendar_widget_dot)
            parseColor(colors.optString(index))?.let { dot.setInt(R.id.dot, "setColorFilter", it) }
            cell.addView(R.id.day_marks, dot)
        }

        return cell
    }
}
