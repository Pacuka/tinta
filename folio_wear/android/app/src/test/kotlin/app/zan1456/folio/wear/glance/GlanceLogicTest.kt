package app.zan1456.folio.wear.glance

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar

class GlanceLogicTest {
    private fun t(hour: Int, minute: Int, second: Int = 0, day: Int = 9): Long =
        Calendar.getInstance().apply {
            clear()
            set(2026, Calendar.NOVEMBER, day, hour, minute, second)
        }.timeInMillis

    private fun lesson(
        startMs: Long,
        subject: String = "Tárgy",
        room: String = "101",
        index: Int = 1,
        cancelled: Boolean = false,
    ) = GlanceLesson(subject, room, startMs, startMs + 45 * 60_000, index, cancelled)

    private val first = lesson(t(8, 0), "Történelem", "12", 3)
    private val second = lesson(t(9, 0), "Angol", "305", 4)
    private val today = listOf(first, second)

    @Test fun duringLesson() {
        val s = glanceStateAt(today, t(8, 21))
        assertEquals(GlancePhase.LESSON, s.phase)
        assertEquals(first, s.current)
        assertEquals(second, s.next)
        assertEquals(24, s.minutesLeft)
        assertEquals(21f / 45, s.progress, 0.001f)
    }

    @Test fun exactlyAtStartIsLesson() {
        assertEquals(GlancePhase.LESSON, glanceStateAt(today, t(8, 0)).phase)
    }

    @Test fun exactlyAtEndIsBreak() {
        val s = glanceStateAt(today, t(8, 45))
        assertEquals(GlancePhase.BREAK, s.phase)
        assertEquals(15, s.minutesLeft)
        assertEquals(0f, s.progress, 0f)
    }

    @Test fun partialMinuteRoundsUp() {
        assertEquals(24, glanceStateAt(today, t(8, 21, 30)).minutesLeft)
    }

    @Test fun beforeFirst() {
        val s = glanceStateAt(today, t(7, 10))
        assertEquals(GlancePhase.FIRST, s.phase)
        assertEquals(first, s.next)
        assertEquals(50, s.minutesLeft)
    }

    @Test fun doneWithUpcoming() {
        val tomorrow = lesson(t(8, 0, day = 10))
        val s = glanceStateAt(today + tomorrow, t(15, 0))
        assertEquals(GlancePhase.DONE, s.phase)
        assertEquals(tomorrow, s.upcoming)
    }

    @Test fun cancelledIsSkipped() {
        val s = glanceStateAt(listOf(lesson(t(8, 0), cancelled = true), second), t(8, 10))
        assertEquals(GlancePhase.FIRST, s.phase)
        assertEquals(second, s.next)
    }

    @Test fun allCancelledToday() {
        assertEquals(
            GlancePhase.NONE,
            glanceStateAt(listOf(lesson(t(8, 0), cancelled = true)), t(8, 10)).phase,
        )
    }

    @Test fun staleData() {
        val s = glanceStateAt(listOf(lesson(t(8, 0, day = 2))), t(10, 0))
        assertEquals(GlancePhase.NONE, s.phase)
        assertNull(s.upcoming)
    }

    @Test fun noLessonsAtAll() {
        assertEquals(GlancePhase.NONE, glanceStateAt(emptyList(), t(10, 0)).phase)
    }

    private fun text(lessons: List<GlanceLesson>, now: Long) =
        glanceText(glanceStateAt(lessons, now), now)

    @Test fun lessonText() {
        val g = text(today, t(8, 21))
        assertEquals("3. óra", g.top)
        assertEquals("Történelem", g.main)
        assertEquals("24 perc", g.value)
        assertEquals("12", g.room)
        assertEquals(t(8, 45), g.countdownTo)
    }

    @Test fun breakText() {
        val g = text(today, t(8, 50))
        assertEquals("Szünet", g.top)
        assertEquals("Angol", g.main)
        assertEquals("10 perc", g.value)
        assertEquals("305", g.room)
    }

    @Test fun firstFarAwayShowsTime() {
        val g = text(today, t(6, 0))
        assertEquals("Első óra", g.top)
        assertEquals("8:00", g.value)
    }

    @Test fun firstWithinHourShowsMinutes() {
        assertEquals("30 perc", text(today, t(7, 30)).value)
    }

    @Test fun doneTomorrowText() {
        val tomorrow = lesson(t(8, 0, day = 10), "Matematika")
        val g = text(today + tomorrow, t(15, 0))
        assertEquals("Mára végeztél", g.main)
        assertEquals("Holnap első óra", g.top)
        assertEquals("8:00 · Matematika", g.value)
    }

    @Test fun noLessonsLaterText() {
        val later = lesson(t(8, 0, day = 12), "Matematika")
        val g = text(listOf(later), t(15, 0))
        assertEquals("Ma nincs órád", g.main)
        assertEquals("Következő óra", g.top)
        assertEquals("csütörtök 8:00 · Matematika", g.value)
    }

    @Test fun doneWithoutUpcomingHasNoLine() {
        val g = text(today, t(15, 0))
        assertEquals("", g.top)
        assertEquals("", g.value)
        assertNull(g.countdownTo)
    }

    @Test fun parsesPhoneJson() {
        val json = """[{"id":"l","subject":"Matek","room":"12","teacher":"T",
            "start":1000,"end":2000,"lessonIndex":3,"status":"cancelled","online":false}]"""
        assertEquals(
            listOf(GlanceLesson("Matek", "12", 1000, 2000, 3, true)),
            parseGlanceLessons(json),
        )
    }

    @Test fun brokenJsonGivesEmptyList() {
        assertTrue(parseGlanceLessons("nem json").isEmpty())
        assertTrue(parseGlanceLessons(null).isEmpty())
    }
}
