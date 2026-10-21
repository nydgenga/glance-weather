// SPDX-License-Identifier: 0BSD
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    // KDE config dialog handles Apply/Cancel using cfg_ properties.
    property string cfg_cityName: ""
    property real cfg_latitude: 999
    property real cfg_longitude: 999
    property string cfg_temperatureUnit: "fahrenheit"
    property string cfg_windUnit: "mph"

    property var locations: []
    property string searchError: ""
    property bool searching: false
    property int searchGeneration: 0

    QQC2.Label {
        Kirigami.FormData.label: i18n("Location")
        text: page.cfg_cityName.length ? i18n("Selected: %1", page.cfg_cityName) : i18n("No location selected")
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Find a city or postal code:")
        Layout.fillWidth: true
        QQC2.TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: i18n("e.g. Waltham or 02453")
            onAccepted: page.searchCities()
        }
        QQC2.Button {
            text: i18n("Search")
            enabled: searchField.text.trim().length >= 2 && !page.searching
            onClicked: page.searchCities()
        }
    }

    QQC2.BusyIndicator {
        visible: page.searching
        running: page.searching
        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
    }
    QQC2.Label {
        visible: page.searchError !== ""
        text: page.searchError
        color: Kirigami.Theme.negativeTextColor
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    ColumnLayout {
        visible: page.locations.length > 0
        Layout.fillWidth: true
        Repeater {
            model: page.locations
            delegate: QQC2.Button {
                required property var modelData
                Layout.fillWidth: true
                text: modelData.name + (modelData.admin1 ? ", " + modelData.admin1 : "") +
                      (modelData.country ? ", " + modelData.country : "")
                onClicked: {
                    page.cfg_cityName = modelData.name + (modelData.admin1 ? ", " + modelData.admin1 : "");
                    page.cfg_latitude = modelData.latitude;
                    page.cfg_longitude = modelData.longitude;
                    page.locations = [];
                    page.searchError = "";
                }
            }
        }
    }

    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Temperature:")
        model: ["Fahrenheit (°F)", "Celsius (°C)"]
        currentIndex: page.cfg_temperatureUnit === "celsius" ? 1 : 0
        onActivated: function(index) { page.cfg_temperatureUnit = index === 1 ? "celsius" : "fahrenheit"; }
    }
    QQC2.ComboBox {
        Kirigami.FormData.label: i18n("Wind:")
        model: ["Miles per hour", "Kilometers per hour"]
        currentIndex: page.cfg_windUnit === "kmh" ? 1 : 0
        onActivated: function(index) { page.cfg_windUnit = index === 1 ? "kmh" : "mph"; }
    }

    function searchCities() {
        var term = searchField.text.trim();
        if (term.length < 2) return;
        searchGeneration++;
        var token = searchGeneration;
        searching = true;
        locations = [];
        searchError = "";
        var request = new XMLHttpRequest();
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE || token !== searchGeneration) return;
            page.searching = false;
            if (request.status !== 200) {
                page.searchError = i18n("Location search failed (HTTP %1).", request.status);
                return;
            }
            try {
                var payload = JSON.parse(request.responseText);
                page.locations = payload.results || [];
                if (!page.locations.length) page.searchError = i18n("No matching places found.");
            } catch (err) {
                page.searchError = i18n("Could not read location results.");
            }
        };
        request.onerror = function() { if (token === searchGeneration) {
            page.searching = false;
            page.searchError = i18n("Could not connect to location search.");
        }};
        request.open("GET", "https://geocoding-api.open-meteo.com/v1/search?count=5&language=en&name=" + encodeURIComponent(term));
        request.send();
    }
}
