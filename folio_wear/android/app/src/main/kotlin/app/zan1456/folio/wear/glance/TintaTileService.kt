package app.zan1456.folio.wear.glance

import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DimensionBuilders.degrees
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.DimensionBuilders.expand
import androidx.wear.protolayout.DimensionBuilders.sp
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.LayoutElementBuilders.Arc
import androidx.wear.protolayout.LayoutElementBuilders.ArcLine
import androidx.wear.protolayout.LayoutElementBuilders.Box
import androidx.wear.protolayout.LayoutElementBuilders.Column
import androidx.wear.protolayout.LayoutElementBuilders.FontStyle
import androidx.wear.protolayout.LayoutElementBuilders.LayoutElement
import androidx.wear.protolayout.LayoutElementBuilders.Spacer
import androidx.wear.protolayout.LayoutElementBuilders.Text
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture

/** The start page's ring as a tile, drawn from the saved timetable. */
class TintaTileService : TileService() {

    override fun onTileRequest(
        request: RequestBuilders.TileRequest,
    ): ListenableFuture<TileBuilders.Tile> {
        val root = if (GlanceData.isPaired(this)) {
            val now = System.currentTimeMillis()
            val state = GlanceData.stateNow(this, now)
            ringLayout(state, glanceText(state, now))
        } else {
            messageLayout("Nyisd meg a Tintát")
        }
        return Futures.immediateFuture(
            TileBuilders.Tile.Builder()
                .setResourcesVersion(RESOURCES_VERSION)
                .setFreshnessIntervalMillis(FRESHNESS_MS)
                .setTileTimeline(TimelineBuilders.Timeline.fromLayoutElement(root))
                .build(),
        )
    }

    override fun onTileResourcesRequest(
        request: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> = Futures.immediateFuture(
        ResourceBuilders.Resources.Builder().setVersion(RESOURCES_VERSION).build(),
    )

    private fun ringLayout(state: GlanceState, text: GlanceText): LayoutElement {
        val ringColor = when (state.phase) {
            GlancePhase.LESSON, GlancePhase.FIRST -> INK
            GlancePhase.BREAK -> BREAK_TEAL
            else -> null
        }
        val rows = Column.Builder()
        if (text.top.isNotEmpty()) rows.addContent(label(text.top, 12f, MUTED))
        rows.addContent(label(text.main, 19f, WHITE, bold = true, maxLines = 2))
        if (text.value.isNotEmpty()) {
            rows.addContent(gap())
            rows.addContent(
                label(text.value, if (ringColor == null) 13f else 24f, INK_LIGHT, maxLines = 2),
            )
        }
        if (text.room.isNotEmpty()) {
            rows.addContent(gap())
            rows.addContent(label(text.room, 13f, WHITE, bold = true))
        }
        val box = screen().addContent(rows.build())
        if (ringColor != null) {
            box.addContent(arc(TRACK, 360f))
            if (state.progress > 0f) box.addContent(arc(ringColor, 360f * state.progress))
        }
        return box.build()
    }

    private fun messageLayout(text: String): LayoutElement =
        screen().addContent(label(text, 15f, WHITE, maxLines = 2)).build()

    private fun screen() = Box.Builder()
        .setWidth(expand())
        .setHeight(expand())
        .setModifiers(
            ModifiersBuilders.Modifiers.Builder()
                .setClickable(
                    ModifiersBuilders.Clickable.Builder()
                        .setId("open")
                        .setOnClick(
                            ActionBuilders.LaunchAction.Builder()
                                .setAndroidActivity(
                                    ActionBuilders.AndroidActivity.Builder()
                                        .setPackageName(packageName)
                                        .setClassName("app.zan1456.folio.wear.MainActivity")
                                        .build(),
                                )
                                .build(),
                        )
                        .build(),
                )
                .build(),
        )

    private fun arc(color: Int, length: Float): LayoutElement = Arc.Builder()
        .setAnchorAngle(degrees(0f))
        .setAnchorType(LayoutElementBuilders.ARC_ANCHOR_START)
        .addContent(
            ArcLine.Builder()
                .setLength(degrees(length))
                .setThickness(dp(RING_DP))
                .setColor(argb(color))
                .build(),
        )
        .build()

    private fun gap(): LayoutElement = Spacer.Builder().setHeight(dp(3f)).build()

    private fun label(
        text: String,
        size: Float,
        color: Int,
        bold: Boolean = false,
        maxLines: Int = 1,
    ): LayoutElement = Text.Builder()
        .setText(text)
        .setMaxLines(maxLines)
        .setOverflow(LayoutElementBuilders.TEXT_OVERFLOW_ELLIPSIZE)
        .setMultilineAlignment(LayoutElementBuilders.TEXT_ALIGN_CENTER)
        .setFontStyle(
            FontStyle.Builder()
                .setSize(sp(size))
                .setColor(argb(color))
                .setWeight(
                    if (bold) LayoutElementBuilders.FONT_WEIGHT_BOLD
                    else LayoutElementBuilders.FONT_WEIGHT_NORMAL,
                )
                .build(),
        )
        .build()

    private companion object {
        const val RESOURCES_VERSION = "1"
        const val FRESHNESS_MS = 60_000L
        const val RING_DP = 6f

        const val INK = 0xFF7C93FF.toInt()
        const val INK_LIGHT = 0xFFA9B8FF.toInt()
        const val BREAK_TEAL = 0xFF6FD6C0.toInt()
        const val MUTED = 0xFFAAB0C4.toInt()
        const val WHITE = 0xFFFFFFFF.toInt()
        const val TRACK = 0xFF1D2233.toInt()
    }
}
