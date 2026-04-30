
// Manual extension point. This file is created once if missing.
#ifndef {{ guard }}
#define {{ guard }}

#include "{{ base_header }}"
#include <QQmlEngine>

class {{ cls }}Control : public {{ cls }}ControlBase
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit {{ cls }}Control(QObject *parent = nullptr);
};

#endif // {{ guard }}
