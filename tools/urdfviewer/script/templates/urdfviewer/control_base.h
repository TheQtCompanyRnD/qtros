
#ifndef {{ guard }}
#define {{ guard }}

#include <QObject>
#include <QVector>
#include <QVariantList>

class {{ cls }}ControlBase : public QObject
{
    Q_OBJECT

#define DEFINE_JOINT_PROPERTY(IDX, NAME, NAME_CAP) \
    Q_PROPERTY(double NAME READ NAME WRITE set##NAME_CAP NOTIFY NAME##Changed)

{% for j in joints_enumerated %}
    DEFINE_JOINT_PROPERTY({{ j[0] }}, {{ j[2] }}, {{ j[3] }})
{% endfor %}

    Q_PROPERTY(QVariantList jointInfos READ jointInfos CONSTANT)

    // Toggles DynamicRigidBody.isKinematic on every generated link; default true
    // (links follow their joint transforms). Set false to let the PhysicsWorld simulate.
    Q_PROPERTY(bool isKinematic READ isKinematic WRITE setIsKinematic NOTIFY isKinematicChanged)

    // When true, each link DynamicRigidBody sends trigger reports so a TriggerBody
    // can detect the robot overlapping it. Default false.
    Q_PROPERTY(bool sendTriggerReports READ sendTriggerReports WRITE setSendTriggerReports NOTIFY sendTriggerReportsChanged)

public:
    explicit {{ cls }}ControlBase(QObject *parent = nullptr);

    QVariantList jointInfos() const;

    bool isKinematic() const;
    void setIsKinematic(bool v);

    bool sendTriggerReports() const;
    void setSendTriggerReports(bool v);

{% for j in joints_enumerated %}
    double {{ j[2] }}() const;
    void set{{ j[2]|capitalize_first }}(double v);
{% endfor %}

signals:
    void isKinematicChanged();
    void sendTriggerReportsChanged();
{% for j in joints_enumerated %}
    void {{ j[2] }}Changed();
{% endfor %}

private:
    QVector<double> m_values;
    QVariantList m_jointInfos;
    bool m_isKinematic = true;
    bool m_sendTriggerReports = false;
};

#endif // {{ guard }}
