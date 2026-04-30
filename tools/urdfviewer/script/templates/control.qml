import QtQuick

QtObject {
{% for prop in props %}
    property real {{ prop }}: 0
{% endfor %}
{% if load_from_json %}
    property var jointInfos: []

    Component.onCompleted: {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", Qt.resolvedUrl("{{ joints_name }}_joints.json"));
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status >= 200 && xhr.status < 300)
                jointInfos = JSON.parse(xhr.responseText);
        }
        xhr.send();
    }
{% else %}
    readonly property list<variant> jointInfos: {{ joint_infos | tojson(indent=4) | indent(4) }}
{% endif %}
}
