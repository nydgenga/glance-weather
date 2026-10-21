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
    height: 320
    implicitWidth: 450
    implicitHeight: showAstronomy ? 320 : 260
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
    readonly property int forecastDays: Math.max(3, Math.min(7, Plasmoid.configuration.forecastDays || 5))
    readonly property bool showHumidity: Plasmoid.configuration.showHumidity !== false
    readonly property bool showWind: Plasmoid.configuration.showWind !== false
    readonly property bool showAstronomy: Plasmoid.configuration.showAstronomy !== false
    readonly property var forecast: weatherService.data

    WeatherService { id: weatherService }
    Plasmoid.busy: weatherService.busy

    function refreshWeather() {
        if (validLocation)
            weatherService.refresh(latitude, longitude, temperatureUnit, windUnit, forecastDays);
    }
    Timer { id: settingsDebounce; interval: 450; onTriggered: root.refreshWeather() }
    Timer { interval: 20000; running: weatherService.busy; onTriggered: weatherService.cancelDueToTimeout() }
    Timer { interval: 1800000; repeat: true; running: root.validLocation; onTriggered: root.refreshWeather() }
    onLatitudeChanged: settingsDebounce.restart()
    onLongitudeChanged: settingsDebounce.restart()
    onTemperatureUnitChanged: settingsDebounce.restart()
    onWindUnitChanged: settingsDebounce.restart()
    onForecastDaysChanged: settingsDebounce.restart()
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
        // Keep the default compact. Content rows sum to about 277 logical px
        // with 16px viewport insets, leaving room for Plasma frame padding.
        // Smaller custom sizes may scroll, but 450×320 should never need to.
        Layout.minimumHeight: Math.min(285, bodyColumn.implicitHeight + 16)
        Layout.preferredWidth: 450
        Layout.preferredHeight: Math.max(320, bodyColumn.implicitHeight + 28)
        readonly property color foreground: Kirigami.Theme.textColor
        readonly property color muted: Kirigami.Theme.disabledTextColor
        readonly property int smallSize: panel.width < 390 ? 11 : 12

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
            contentHeight: bodyColumn.implicitHeight + 16
            interactive: contentHeight > height + 1
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: QQC2.ScrollBar { policy: bodyViewport.interactive ? QQC2.ScrollBar.AsNeeded : QQC2.ScrollBar.AlwaysOff }

            Column {
                id: bodyColumn
                x: 9
                y: 8
                width: Math.max(0, bodyViewport.width - 18)
                spacing: 3

                // Header: the long location name yields to the update status.
                Item {
                    width: parent.width
                    height: 21
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
                        font.pixelSize: 10
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

                // Hero: constrained to content, not an unnecessarily tall reserved row.
                Item {
                    width: parent.width
                    height: 64
                    Text {
                        x: 0; y: 4
                        text: root.forecast.current.condition.icon
                        font.pixelSize: panel.width < 390 ? 36 : 40
                    }
                    Text {
                        x: 58; y: 1
                        text: root.forecast.current.temperature
                        color: panel.foreground
                        font.pixelSize: panel.width < 390 ? 32 : 37
                        font.bold: true
                    }
                    Text {
                        x: 58; y: 46
                        text: root.forecast.current.condition.label
                        color: panel.foreground
                        font.pixelSize: panel.smallSize
                    }
                    Text {
                        anchors.right: parent.right
                        y: 10
                        text: root.forecast.days.length ? root.forecast.days[0].high + " / " + root.forecast.days[0].low : "—"
                        color: panel.foreground; font.bold: true; font.pixelSize: panel.smallSize + 1
                    }
                    Text {
                        anchors.right: parent.right
                        y: 31
                        text: i18n("Feels like %1", root.forecast.current.feels)
                        color: panel.muted; font.pixelSize: panel.smallSize
                    }
                }

                Item {
                    width: parent.width
                    height: root.showHumidity || root.showWind ? 18 : 0
                    visible: height > 0
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16
                        Text { visible: root.showHumidity; text: "💧 " + root.forecast.current.humidity; color: panel.foreground; font.pixelSize: panel.smallSize + 1 }
                        Text { visible: root.showWind; text: "💨 " + Weather.wind(root.forecast.current.wind, root.windUnit); color: panel.foreground; font.pixelSize: panel.smallSize + 1 }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: panel.foreground; opacity: 0.18 }

                // Five readable forecast columns, equally sized across the body.
                Item {
                    width: parent.width
                    height: 73
                    Row {
                        anchors.fill: parent
                        spacing: 0
                        Repeater {
                            model: root.forecast.days.slice(0, root.forecastDays)
                            delegate: Item {
                                required property var modelData
                                width: Math.floor(bodyColumn.width / root.forecastDays)
                                height: 73
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
                    height: root.showAstronomy ? 56 : 0
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 4
                        width: 1; height: 48
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
                            Text { text: i18n("Rise %1", root.forecast.today.sunrise); color: panel.muted; font.pixelSize: 11 }
                            Text { text: i18n("Set %1", root.forecast.today.sunset); color: panel.muted; font.pixelSize: 11 }
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
                            Text { text: i18n("Rise %1", root.forecast.today.moonrise); color: panel.muted; font.pixelSize: 11 }
                            Text { text: i18n("Set %1", root.forecast.today.moonset); color: panel.muted; font.pixelSize: 11 }
                        }
                    }
                }

                // Footer follows astronomy without occupying a phantom row.
                // At the normal widget size, it fits with slack below it.
                Item {
                    width: parent.width
                    height: 22
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: i18n("Weather by Open-Meteo")
                        color: panel.muted; font.pixelSize: 10
                    }
                    QQC2.ToolButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 90; height: 22
                        text: i18n("Hourly ▴")
                        font.pixelSize: 11
                        onClicked: hourlyPopup.open()
                    }
                }
            }
        }

        QQC2.Popup {
            id: hourlyPopup
            parent: panel
            x: Math.round((panel.width - width) / 2)
            y: Math.max(0, panel.height - height - 8)
            width: Math.min(320, panel.width - 16)
            height: Math.min(280, 56 + root.forecast.hourly.length * 31)
            padding: 10
            closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
            background: Rectangle {
                color: Kirigami.Theme.backgroundColor
                border.color: Kirigami.Theme.textColor
                border.width: 1
                radius: 8
            }
            ColumnLayout {
                anchors.fill: parent
                spacing: 4
                PlasmaComponents.Label { text: i18n("Next six hours · rain chance"); font.bold: true; font.pixelSize: 12 }
                Repeater {
                    model: root.forecast.hourly || []
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        PlasmaComponents.Label { text: modelData.time; font.pixelSize: 12; Layout.preferredWidth: 85 }
                        PlasmaComponents.Label { text: modelData.icon; font.pixelSize: 18; Layout.fillWidth: true }
                        PlasmaComponents.Label { text: modelData.temperature; font.pixelSize: 12; Layout.preferredWidth: 48 }
                        PlasmaComponents.Label { text: "🌧 " + modelData.rain; font.pixelSize: 12 }
                    }
                }
            }
        }
    }
}
