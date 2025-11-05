#ifndef GRIDPALETTE_H
#define GRIDPALETTE_H

#include <QQuick3DTextureData>
#include <QByteArray>
#include <QColor>
#include <QSharedPointer>

class GridPalette : public QQuick3DTextureData
{
    Q_OBJECT
    Q_PROPERTY(int scheme READ scheme WRITE setScheme NOTIFY schemeChanged)
    QML_ELEMENT

public:
    enum ColorScheme { Grayscale, CostmapHot, CostmapCool, Jet };
    Q_ENUM(ColorScheme)

    GridPalette();

    int scheme() const { return m_scheme; }
    void setScheme(int s);

signals:
    void schemeChanged();

private:
    void rebuild();

    int m_scheme = -1;
};

#endif // GRIDPALETTE_H
