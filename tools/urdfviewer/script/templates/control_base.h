
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

public:
    explicit {{ cls }}ControlBase(QObject *parent = nullptr);

    QVariantList jointInfos() const;

{% for j in joints_enumerated %}
    double {{ j[2] }}() const;
    void set{{ j[2]|capitalize_first }}(double v);
{% endfor %}

signals:
{% for j in joints_enumerated %}
    void {{ j[2] }}Changed();
{% endfor %}

private:
    QVector<double> m_values;
    QVariantList m_jointInfos;
};

#endif // {{ guard }}
