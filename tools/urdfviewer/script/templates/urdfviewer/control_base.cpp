
#include "{{ header }}"
#include <QVariantMap>
#include <QVariantList>
{% if load_from_json %}
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
{% endif %}

{{ cls }}ControlBase::{{ cls }}ControlBase(QObject *parent)
    : QObject(parent)
    , m_values({{ joints|length }})
{
{% if load_from_json %}
    QFile f(QStringLiteral(":/qt/qml/{{ qml_uri_path }}/{{ name }}_joints.json"));
    if (f.open(QIODevice::ReadOnly)) {
        const QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
        if (doc.isArray())
            m_jointInfos = doc.array().toVariantList();
    }
{% else %}
{% for info in joint_infos %}
    {
        QVariantMap map;
        map.insert(QStringLiteral("name"), QStringLiteral("{{ info.name }}"));
        map.insert(QStringLiteral("type"), QStringLiteral("{{ info.type }}"));
        QVariantList axis;
        axis << {{ info.axis[0] }} << {{ info.axis[1] }} << {{ info.axis[2] }};
        map.insert(QStringLiteral("axis"), axis);
        map.insert(QStringLiteral("lower"), {{ info.lower if info.lower is not none else 'QVariant()' }});
        map.insert(QStringLiteral("upper"), {{ info.upper if info.upper is not none else 'QVariant()' }});
        m_jointInfos.append(map);
    }
{% endfor %}
{% endif %}
}

{% for j in joints_enumerated %}
double {{ cls }}ControlBase::{{ j[2] }}() const
{
    return m_values[{{ j[0] }}];
}

void {{ cls }}ControlBase::set{{ j[2]|capitalize_first }}(double v)
{
    if (qFuzzyCompare(m_values[{{ j[0] }}], v))
        return;
    m_values[{{ j[0] }}] = v;
    emit {{ j[2] }}Changed();
}

{% endfor %}

QVariantList {{ cls }}ControlBase::jointInfos() const
{
    return m_jointInfos;
}

bool {{ cls }}ControlBase::isKinematic() const
{
    return m_isKinematic;
}

void {{ cls }}ControlBase::setIsKinematic(bool v)
{
    if (m_isKinematic == v)
        return;
    m_isKinematic = v;
    emit isKinematicChanged();
}

bool {{ cls }}ControlBase::sendTriggerReports() const
{
    return m_sendTriggerReports;
}

void {{ cls }}ControlBase::setSendTriggerReports(bool v)
{
    if (m_sendTriggerReports == v)
        return;
    m_sendTriggerReports = v;
    emit sendTriggerReportsChanged();
}
