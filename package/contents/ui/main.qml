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
    height: 326
    implicitWidth: 450
    implicitHeight: 326
    switchWidth: 320
    switchHeight: 215
    toolTipMainText: i18n("Glance Weather")
    readonly property string cityName: Plasmoid.configuration.cityName || ""
    readonly property real latitude: Number(Plasmoid.configuration.latitude)
    readonly property real longitude: Number(Plasmoid.configuration.longitude)
    readonly property bool validLocation: cityName.length > 0 && latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
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
        if (validLocation) weatherService.refresh(latitude, longitude, temperatureUnit, windUnit, forecastDays)
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
        Layout.minimumWidth: 315
        Layout.minimumHeight: root.showAstronomy ? 300 : 250
        Layout.preferredWidth: 450
        Layout.preferredHeight: 326
        clip: true
        readonly property int smallSize: Math.max(10, Math.min(13, Math.floor(width / 34)))
        readonly property bool narrow: width < 390
        readonly property color muted: Kirigami.Theme.disabledTextColor

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 26
            visible: !root.validLocation || !weatherService.hasData
            spacing: 12
            PlasmaComponents.Label { Layout.alignment: Qt.AlignHCenter; text: "🌤️"; font.pixelSize: 40 }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: !root.validLocation ? i18n("Welcome to Glance Weather") : weatherService.busy ? i18n("Fetching the forecast…") : i18n("Weather temporarily unavailable")
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                text: !root.validLocation ? i18n("Right-click this widget and select Configure Glance Weather to choose your city.") : weatherService.error || i18n("Waiting for weather data.")
            }
            QQC2.Button {
                visible: root.validLocation && !weatherService.busy
                Layout.alignment: Qt.AlignHCenter
                text: i18n("Retry")
                onClicked: root.refreshWeather()
            }
        }
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: panel.narrow ? 8 : 10
            spacing: 4
            visible: root.validLocation && weatherService.hasData
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: "📍 " + root.cityName
                    font.bold: true
                    font.pixelSize: panel.smallSize + 1
                    elide: Text.ElideRight
                }
                PlasmaComponents.Label {
                    text: weatherService.busy ? i18n("Updating…") : weatherService.error ? i18n("Stale data") : i18n("Updated %1", root.forecast.current.time)
                    font.pixelSize: 10
                    color: weatherService.error ? Kirigami.Theme.negativeTextColor : panel.muted
                }
                QQC2.ToolButton {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 21
                    text: "↻"
                    enabled: !weatherService.busy
                    onClicked: root.refreshWeather()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: root.forecast.current.condition.icon; font.pixelSize: panel.narrow ? 36 : 40 }
                ColumnLayout {
                    spacing: 0
                    PlasmaComponents.Label { text: root.forecast.current.temperature; font.pixelSize: panel.narrow ? 33 : 36; font.bold: true }
                    PlasmaComponents.Label { text: root.forecast.current.condition.label; font.pixelSize: panel.smallSize }
                }
                Item { Layout.fillWidth: true }
                ColumnLayout {
                    spacing: 2
                    PlasmaComponents.Label {
                        Layout.alignment: Qt.AlignRight
                        text: root.forecast.days.length ? root.forecast.days[0].high + " / " + root.forecast.days[0].low : "—"
                        font.pixelSize: panel.smallSize + 1
                        font.bold: true
                    }
                    PlasmaComponents.Label {
                        Layout.alignment: Qt.AlignRight
                        text: i18n("Feels like %1", root.forecast.current.feels)
                        font.pixelSize: panel.smallSize
                        color: panel.muted
                    }
                }
            }
            RowLayout {
                visible: root.showHumidity || root.showWind
                Layout.fillWidth: true
                spacing: 12
                PlasmaComponents.Label { visible: root.showHumidity; text: "💧 " + root.forecast.current.humidity; font.pixelSize: panel.smallSize + 1 }
                PlasmaComponents.Label { visible: root.showWind; text: "💨 " + Weather.wind(root.forecast.current.wind, root.windUnit); font.pixelSize: panel.smallSize + 1 }
                Item { Layout.fillWidth: true }
            }
            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Kirigami.Theme.textColor; opacity: 0.14 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 2
                Repeater {
                    model: root.forecast.days.slice(0, root.forecastDays)
                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.minimumWidth: 37
                        spacing: 2
                        PlasmaComponents.Label { Layout.alignment: Qt.AlignHCenter; text: modelData.day; font.pixelSize: panel.smallSize; color: panel.muted }
                        Text { Layout.alignment: Qt.AlignHCenter; text: modelData.icon; font.pixelSize: panel.narrow ? 20 : 22 }
                        PlasmaComponents.Label { Layout.alignment: Qt.AlignHCenter; text: modelData.high; font.pixelSize: panel.smallSize + 1; font.bold: true }
                        PlasmaComponents.Label { Layout.alignment: Qt.AlignHCenter; text: modelData.low; font.pixelSize: panel.smallSize; color: panel.muted }
                    }
                }
            }
            Rectangle {
                visible: root.showAstronomy
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Kirigami.Theme.textColor
                opacity: 0.14
            }
            RowLayout {
                visible: root.showAstronomy
                Layout.fillWidth: true
                spacing: 10
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    spacing: 1
                    PlasmaComponents.Label { Layout.fillWidth: true; text: "🌅 " + i18n("Sun"); font.bold: true; font.pixelSize: panel.smallSize; elide: Text.ElideRight }
                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: "↑ " + root.forecast.today.sunrise + "  ↓ " + root.forecast.today.sunset
                        font.pixelSize: 11
                        color: panel.muted
                        elide: Text.ElideRight
                    }
                }
                Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; Layout.topMargin: 2; Layout.bottomMargin: 2; color: Kirigami.Theme.textColor; opacity: 0.14 }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    spacing: 1
                    PlasmaComponents.Label { Layout.fillWidth: true; text: root.forecast.today.moon.icon + " " + root.forecast.today.moon.label; font.bold: true; font.pixelSize: panel.smallSize; elide: Text.ElideRight }
                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: "↑ " + root.forecast.today.moonrise + "  ↓ " + root.forecast.today.moonset
                        font.pixelSize: 11
                        color: panel.muted
                        elide: Text.ElideRight
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                PlasmaComponents.Label { text: i18n("Weather by Open-Meteo"); color: panel.muted; font.pixelSize: 10; Layout.fillWidth: true }
                QQC2.ToolButton { text: i18n("Hourly ▴"); font.pixelSize: 10; Layout.preferredHeight: 20; onClicked: hourlyPopup.open() }
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
            background: Rectangle { color: Kirigami.Theme.backgroundColor; border.color: Kirigami.Theme.textColor; border.width: 1; radius: 8 }
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
