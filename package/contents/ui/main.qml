// SPDX-License-Identifier: 0BSD
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "Weather.js" as Weather
import "RefreshPolicy.js" as RefreshPolicy

PlasmoidItem {
    id: root
    width: 450
    // A stable desktop layout replaces the old configuration-dependent geometry.
    // Existing desktop placements retain their saved dimensions in Plasma,
    // so they may need one manual resize after this update.
    height: 416
    implicitWidth: 450
    implicitHeight: 416
    switchWidth: 320
    switchHeight: 215
    toolTipMainText: i18n("Glance Weather")

    readonly property string cityName: Plasmoid.configuration.cityName || ""
    readonly property real latitude: Number(Plasmoid.configuration.latitude)
    readonly property real longitude: Number(Plasmoid.configuration.longitude)
    readonly property bool validLocation: cityName.length > 0 && latitude >= -90 && latitude <= 90
                                          && longitude >= -180 && longitude <= 180
    readonly property string temperatureUnit: Plasmoid.configuration.temperatureUnit || "fahrenheit"
    readonly property string windUnit: Plasmoid.configuration.windUnit || "mph"
    readonly property var forecast: weatherService.data

    WeatherService { id: weatherService }
    Plasmoid.busy: weatherService.busy

    // The forecast timestamp belongs to Open-Meteo's location-local data;
    // the fetch timestamp belongs to this computer. Don't conflate them.
    // A successful fetch is already recorded in WeatherService.lastSuccessMs.
    function timestampTooltip() {
        if (!weatherService.hasData || weatherService.lastSuccessMs <= 0)
            return "";
        return i18n("Weather data as of %1 (forecast location time)", root.forecast.current.time)
               + "\n" + i18n("Last fetched: %1 (computer time)",
                                  Qt.formatDateTime(new Date(weatherService.lastSuccessMs)));
    }

    function refreshWeather() {
        if (validLocation)
            weatherService.refresh(latitude, longitude, temperatureUnit, windUnit);
    }
    function refreshIfDue() {
        if (!validLocation) return;
        var now = Date.now();
        // If a request was suspended in-flight, the original timeout timer may
        // not have run. Release the stuck request when the watchdog wakes.
        if (RefreshPolicy.requestIsStalled(now, weatherService.lastAttemptMs, weatherService.busy))
            weatherService.cancelDueToTimeout();
        if (RefreshPolicy.shouldRefresh(now, weatherService.lastSuccessMs,
                                        weatherService.lastAttemptMs,
                                        weatherService.busy, weatherService.error.length > 0))
            refreshWeather();
    }
    Timer { id: settingsDebounce; interval: 450; onTriggered: root.refreshWeather() }
    Timer {
        id: requestTimeout
        interval: 20000
        running: weatherService.busy
        onTriggered: weatherService.cancelDueToTimeout()
    }
    Connections {
        target: weatherService
        function onRequestStarted() { requestTimeout.restart() }
    }
    // Check actual elapsed time, not the number of 30-minute timer ticks: Qt's
    // QML timer can be delayed while the computer sleeps. A failed request is
    // retried within about two minutes of the previous attempt (plus the
    // minute-level watchdog granularity), even if the network was offline.
    Timer { interval: 60000; repeat: true; running: root.validLocation; onTriggered: root.refreshIfDue() }
    onLatitudeChanged: settingsDebounce.restart()
    onLongitudeChanged: settingsDebounce.restart()
    onTemperatureUnitChanged: settingsDebounce.restart()
    onWindUnitChanged: settingsDebounce.restart()
    onValidLocationChanged: settingsDebounce.restart()
    Component.onCompleted: settingsDebounce.restart()

    compactRepresentation: Item {
        implicitWidth: 92
        implicitHeight: 36
        RowLayout {
            anchors.centerIn: parent
            spacing: 4
            Text { text: weatherService.hasData ? root.forecast.current.condition.icon : "🌤️"; font.pixelSize: 22 }
            PlasmaComponents.Label { text: weatherService.hasData ? root.forecast.current.temperature : "—"; font.bold: true }
        }
        MouseArea { anchors.fill: parent; onClicked: root.expanded = !root.expanded }
    }

    fullRepresentation: Item {
        id: panel
        Layout.minimumWidth: 310
        // Keep the approved typography and columns. Any free viewport height
        // becomes small, evenly distributed section gaps, not bottom dead space.
        // Plasma may retain an older manually chosen desktop size.
        Layout.minimumHeight: 400
        Layout.preferredWidth: 450
        Layout.preferredHeight: 416
        readonly property color foreground: Kirigami.Theme.textColor
        readonly property color muted: Kirigami.Theme.disabledTextColor
        // One step larger supporting text for easier at-a-glance reading.
        readonly property int smallSize: panel.width < 390 ? 12 : 13

        Column {
            anchors.centerIn: parent
            width: Math.max(0, parent.width - 32)
            spacing: 12
            visible: !root.validLocation || !weatherService.hasData
            Text { text: "🌤️"; font.pixelSize: 40; anchors.horizontalCenter: parent.horizontalCenter }
            Text {
                width: parent.width
                text: !root.validLocation ? i18n("Welcome to Glance Weather")
                     : weatherService.busy ? i18n("Fetching the forecast…") : i18n("Weather temporarily unavailable")
                color: panel.foreground; font.bold: true; horizontalAlignment: Text.AlignHCenter
            }
            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                color: panel.foreground
                text: !root.validLocation ? i18n("Right-click and configure Glance Weather to choose your city.")
                     : weatherService.error || i18n("Waiting for weather data.")
            }
            QQC2.Button {
                visible: root.validLocation && !weatherService.busy
                anchors.horizontalCenter: parent.horizontalCenter
                text: i18n("Retry")
                onClicked: root.refreshWeather()
            }
        }

        // The body sizes itself from its *actual* visible sections.
        // Under a manually undersized widget, scrolling is available rather
        // than silently clipping the Open-Meteo attribution and hourly button.
        Flickable {
            id: bodyViewport
            anchors.fill: parent
            visible: root.validLocation && weatherService.hasData
            clip: true
            contentWidth: width
            // Account for the real top and bottom insets, not an arbitrary
            // 16px reserve that can trigger an unnecessary scrollbar.
            contentHeight: bodyColumn.y + bodyColumn.implicitHeight + 5
            interactive: contentHeight > height + 1
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: QQC2.ScrollBar { policy: bodyViewport.interactive ? QQC2.ScrollBar.AsNeeded : QQC2.ScrollBar.AlwaysOff }

            Column {
                id: bodyColumn
                x: 9
                y: 5
                width: Math.max(0, bodyViewport.width - 18)
                // Share surplus viewport height across the existing section
                // gaps, rather than leaving it all below the attribution.
                // A bounded 2–9px gap avoids excessive spacing when a desktop
                // instance retains an old, unusually large geometry.
                // All sections, including astronomy, are permanently visible.
                readonly property int activeRowsHeight: 373
                readonly property int activeGaps: 8
                spacing: Math.max(2, Math.min(9,
                    (bodyViewport.height - y - 10 - activeRowsHeight) / activeGaps))

                // Header: the long location name yields to the update status.
                Item {
                    width: parent.width
                    height: 20
                    QQC2.ToolButton {
                        id: refreshButton
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 27; height: 21
                        text: "↻"; font.pixelSize: 17
                        enabled: !weatherService.busy
                        onClicked: root.refreshWeather()
                        QQC2.ToolTip.visible: hovered
                        QQC2.ToolTip.text: i18n("Refresh weather")
                    }
                    Text {
                        id: lastUpdate
                        anchors.right: refreshButton.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        color: weatherService.error ? Kirigami.Theme.negativeTextColor : panel.muted
                        font.pixelSize: 11
                        text: weatherService.busy ? i18n("Updating…")
                              : weatherService.error ? i18n("Stale data")
                              : i18n("As of %1", root.forecast.current.time)
                        // The header stays compact. On hover distinguish the
                        // source data time from the last successful HTTP fetch.
                        // Preserve useful diagnostics when a retry has failed.
                        QQC2.ToolTip.visible: statusHover.containsMouse && weatherService.hasData
                        QQC2.ToolTip.delay: 450
                        QQC2.ToolTip.text: weatherService.error.length > 0
                            ? root.timestampTooltip() + "\n"
                              + i18n("Error: %1", weatherService.error) + "\n"
                              + i18n("Automatic retry is enabled.")
                            : root.timestampTooltip()
                        MouseArea {
                            id: statusHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.right: lastUpdate.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "📍 " + root.cityName
                        color: panel.foreground
                        font.bold: true
                        font.pixelSize: panel.smallSize + 1
                        elide: Text.ElideRight
                    }
                }

                // Primary weather on the left, supporting readings on the right.
                // Keeping humidity and wind below the daily high/low frees a
                // complete row above the hourly forecast and balances the hero.
                Item {
                    width: parent.width
                    height: 91
                    Text {
                        id: currentWeatherIcon
                        x: 0; y: 8
                        text: root.forecast.current.condition.icon
                        font.pixelSize: panel.width < 390 ? 43 : 52
                    }
                    Text {
                        id: currentTemperature
                        // Emoji glyph widths vary across fonts and conditions.
                        // Use the actual glyph width instead of a fixed x:60.
                        x: currentWeatherIcon.x + currentWeatherIcon.implicitWidth
                           + (panel.width < 390 ? 7 : 11)
                        y: 0
                        // Prevent extreme temperatures from colliding with the
                        // right column without shrinking normal-sized text.
                        width: Math.max(1, Math.min(highLowReading.x, feelsLikeReading.x,
                            humidityReading.x, windReading.x) - x - 8)
                        height: 62
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: 25
                        wrapMode: Text.NoWrap
                        elide: Text.ElideRight
                        text: root.forecast.current.temperature
                        color: panel.foreground
                        font.pixelSize: panel.width < 390 ? 40 : 50
                        font.bold: true
                    }
                    Text {
                        x: currentTemperature.x + 1; y: 67
                        width: Math.max(1, Math.min(highLowReading.x, feelsLikeReading.x,
                            humidityReading.x, windReading.x) - x - 8)
                        elide: Text.ElideRight
                        text: root.forecast.current.condition.label
                        color: panel.foreground
                        font.pixelSize: panel.smallSize
                    }
                    // All four right-side values share the same right edge.
                    Text {
                        id: highLowReading
                        anchors.right: parent.right
                        y: 2
                        text: root.forecast.days.length ? root.forecast.days[0].high + " / " + root.forecast.days[0].low : "—"
                        color: panel.foreground
                        font.bold: true
                        font.pixelSize: 18
                    }
                    Text {
                        anchors.right: parent.right
                        id: feelsLikeReading
                        y: 29
                        text: i18n("Feels like %1", root.forecast.current.feels)
                        color: panel.muted
                        font.pixelSize: panel.smallSize
                    }
                    Text {
                        anchors.right: parent.right
                        id: humidityReading
                        y: 51
                        text: "💧 " + root.forecast.current.humidity
                        color: panel.foreground
                        font.pixelSize: panel.smallSize + 1
                    }
                    Text {
                        anchors.right: parent.right
                        id: windReading
                        y: 71
                        text: "💨 " + Weather.wind(root.forecast.current.wind, root.windUnit)
                        color: panel.foreground
                        font.pixelSize: panel.smallSize + 1
                    }
                }

                Rectangle { width: parent.width; height: 1; color: panel.foreground; opacity: 0.18 }

                // Hourly outlook is always visible; six equal-width columns.
                // Times are in the forecast location's timezone. Rain is the
                // provider's precipitation *probability*, not an amount.
                Item {
                    width: parent.width
                    height: 102
                    Text {
                        x: 0; y: 0
                        text: i18n("Next six hours")
                        color: panel.muted
                        font.pixelSize: 12
                        font.bold: true
                    }
                    Row {
                        x: 0; y: 17
                        width: parent.width
                        height: 85
                        spacing: 0
                        Repeater {
                            model: root.forecast.hourly || []
                            delegate: Item {
                                required property var modelData
                                width: Math.floor(bodyColumn.width / 6)
                                height: 85
                                // Keep unusual emoji glyph widths and 100% rain
                                // probabilities within this hour's own column.
                                clip: true
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 1
                                    text: modelData.shortTime
                                    color: panel.muted
                                    font.pixelSize: 12
                                }
                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    y: 22
                                    text: modelData.icon
                                    font.pixelSize: 21
                                    wrapMode: Text.NoWrap
                                }
                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    y: 48
                                    text: modelData.temperature
                                    color: panel.foreground
                                    font.pixelSize: 14
                                    fontSizeMode: Text.HorizontalFit
                                    minimumPixelSize: 10
                                    font.bold: true
                                }
                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    y: 71
                                    text: modelData.rain === "—" ? "" : "☔" + modelData.rain
                                    color: panel.muted
                                    font.pixelSize: 11
                                    fontSizeMode: Text.HorizontalFit
                                    minimumPixelSize: 9
                                    wrapMode: Text.NoWrap
                                }
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: panel.foreground; opacity: 0.18 }

                // Seven readable forecast columns, equally sized across the body.
                // Deliberately reserve 12px below daily lows before the astronomy divider.
                // This redistributes the previously unused default bottom space.
                Item {
                    width: parent.width
                    height: 85
                    Row {
                        anchors.fill: parent
                        spacing: 0
                        Repeater {
                            model: root.forecast.days.slice(0, 7)
                            delegate: Item {
                                required property var modelData
                                width: Math.floor(bodyColumn.width / 7)
                                height: 85
                                // Avoid overlap into neighboring days if an
                                // emoji font draws a particularly wide glyph.
                                clip: true
                                // Explain when the day's temperatures are predicted
                                // to peak, using already-downloaded hourly samples.
                                QQC2.ToolTip.visible: forecastHover.containsMouse
                                QQC2.ToolTip.delay: 450
                                QQC2.ToolTip.text:
                                    (modelData.highTime === "—"
                                        ? i18n("High %1 — time unavailable", modelData.high)
                                        : i18n("High %1 — around %2", modelData.high, modelData.highTime))
                                    + "\n" + (modelData.lowTime === "—"
                                        ? i18n("Low %1 — time unavailable", modelData.low)
                                        : i18n("Low %1 — around %2", modelData.low, modelData.lowTime))
                                    + "\n" + i18n("Approximate hourly forecast, location time")
                                MouseArea {
                                    id: forecastHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width
                                    spacing: 1
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.day; color: panel.muted; font.pixelSize: panel.smallSize }
                                    Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: modelData.icon; font.pixelSize: 22; wrapMode: Text.NoWrap }
                                    Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: modelData.high; color: panel.foreground; font.pixelSize: panel.smallSize + 1; fontSizeMode: Text.HorizontalFit; minimumPixelSize: 10; font.bold: true }
                                    Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: modelData.low; color: panel.muted; font.pixelSize: panel.smallSize; fontSizeMode: Text.HorizontalFit; minimumPixelSize: 10 }
                                }
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: panel.foreground; opacity: 0.18 }

                // Sun and Moon are true separate mini-sections: each time is
                // on its own line. This avoids the continuous text run seen in v0.1.1.
                Item {
                    width: parent.width
                    height: 52
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 4
                        width: 1; height: 44
                        color: panel.foreground; opacity: 0.18
                    }
                    Item {
                        width: Math.floor(parent.width / 2) - 10
                        height: parent.height
                        anchors.left: parent.left
                        Column {
                            width: parent.width
                            spacing: 1
                            Text { text: "🌅 " + i18n("Sun"); color: panel.foreground; font.bold: true; font.pixelSize: panel.smallSize }
                            Text { text: i18n("Rise %1", root.forecast.today.sunrise); color: panel.muted; font.pixelSize: 12 }
                            Text { text: i18n("Set %1", root.forecast.today.sunset); color: panel.muted; font.pixelSize: 12 }
                        }
                    }
                    Item {
                        width: Math.floor(parent.width / 2) - 10
                        height: parent.height
                        anchors.right: parent.right
                        Column {
                            width: parent.width
                            spacing: 1
                            Text {
                                width: parent.width; elide: Text.ElideRight
                                text: root.forecast.today.moon.icon + " " + root.forecast.today.moon.label
                                color: panel.foreground; font.bold: true; font.pixelSize: panel.smallSize
                            }
                            Text { text: i18n("Rise %1", root.forecast.today.moonrise); color: panel.muted; font.pixelSize: 12 }
                            Text { text: i18n("Set %1", root.forecast.today.moonset); color: panel.muted; font.pixelSize: 12 }
                        }
                    }
                }

                // Provider attribution centered across the full content area.
                Item {
                    width: parent.width
                    height: 20
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        text: i18n("Weather by Open-Meteo")
                        color: panel.muted; font.pixelSize: 11
                    }
                }
            }
        }

    }
}
