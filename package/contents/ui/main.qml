// SPDX-License-Identifier: 0BSD
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import "Weather.js" as Weather

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
    readonly property bool showAstronomy: Plasmoid.configuration.showAstronomy !== false
    readonly property var forecast: weatherService.data

    WeatherService { id: weatherService }
    Plasmoid.busy: weatherService.busy

    function refreshWeather() {
        if (validLocation)
            weatherService.refresh(latitude, longitude, temperatureUnit, windUnit);
    }
    Timer { id: settingsDebounce; interval: 450; onTriggered: root.refreshWeather() }
    Timer { interval: 20000; running: weatherService.busy; onTriggered: weatherService.cancelDueToTimeout() }
    Timer { interval: 1800000; repeat: true; running: root.validLocation; onTriggered: root.refreshWeather() }
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
        // Keep the approved typography and columns, but remove unused vertical
        // allocations so the whole view fits the previously used 450×416 frame.
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
                spacing: 2

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
                              : i18n("Updated %1", root.forecast.current.time)
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
                        x: 0; y: 8
                        text: root.forecast.current.condition.icon
                        font.pixelSize: panel.width < 390 ? 43 : 52
                    }
                    Text {
                        x: 60; y: 0
                        text: root.forecast.current.temperature
                        color: panel.foreground
                        font.pixelSize: panel.width < 390 ? 40 : 50
                        font.bold: true
                    }
                    Text {
                        x: 61; y: 67
                        text: root.forecast.current.condition.label
                        color: panel.foreground
                        font.pixelSize: panel.smallSize
                    }
                    // All four right-side values share the same right edge.
                    Text {
                        anchors.right: parent.right
                        y: 2
                        text: root.forecast.days.length ? root.forecast.days[0].high + " / " + root.forecast.days[0].low : "—"
                        color: panel.foreground
                        font.bold: true
                        font.pixelSize: 18
                    }
                    Text {
                        anchors.right: parent.right
                        y: 29
                        text: i18n("Feels like %1", root.forecast.current.feels)
                        color: panel.muted
                        font.pixelSize: panel.smallSize
                    }
                    Text {
                        anchors.right: parent.right
                        y: 51
                        text: "💧 " + root.forecast.current.humidity
                        color: panel.foreground
                        font.pixelSize: panel.smallSize + 1
                    }
                    Text {
                        anchors.right: parent.right
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
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 1
                                    text: modelData.shortTime
                                    color: panel.muted
                                    font.pixelSize: 12
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 22
                                    text: modelData.icon
                                    font.pixelSize: 21
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 48
                                    text: modelData.temperature
                                    color: panel.foreground
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 71
                                    text: modelData.rain === "—" ? "" : "💧" + modelData.rain
                                    color: panel.muted
                                    font.pixelSize: 11
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
                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 1
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.day; color: panel.muted; font.pixelSize: panel.smallSize }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; font.pixelSize: 22 }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.high; color: panel.foreground; font.pixelSize: panel.smallSize + 1; font.bold: true }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.low; color: panel.muted; font.pixelSize: panel.smallSize }
                                }
                            }
                        }
                    }
                }

                Rectangle { visible: root.showAstronomy; width: parent.width; height: root.showAstronomy ? 1 : 0; color: panel.foreground; opacity: 0.18 }

                // Sun and Moon are true separate mini-sections: each time is
                // on its own line. This avoids the continuous text run seen in v0.1.1.
                Item {
                    visible: root.showAstronomy
                    width: parent.width
                    height: root.showAstronomy ? 52 : 0
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

                // Provider attribution; the old hourly popup has moved inline.
                Item {
                    width: parent.width
                    height: 20
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: i18n("Weather by Open-Meteo")
                        color: panel.muted; font.pixelSize: 11
                    }
                }
            }
        }

    }
}
