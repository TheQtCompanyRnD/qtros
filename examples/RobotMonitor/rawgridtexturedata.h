#ifndef RAWGRIDTEXTUREDATA_H
#define RAWGRIDTEXTUREDATA_H

#include <QQuick3DTextureData>
#include <QByteArray>
#include <QColor>
#include <QSharedPointer>

class RawGridTextureData : public QQuick3DTextureData
{
    Q_OBJECT
    Q_PROPERTY(QByteArray gridData READ gridData WRITE setGridData NOTIFY gridDataChanged)
    Q_PROPERTY(int width READ width WRITE setWidth NOTIFY widthChanged)
    Q_PROPERTY(int height READ height WRITE setHeight NOTIFY heightChanged)
    QML_ELEMENT

public:
    RawGridTextureData(QQuick3DObject *parent = nullptr);

    QByteArray gridData() const { return m_gridData; }
    int width() const { return m_width; }
    int height() const { return m_height; }

    void setGridData(const QByteArray &data);

    void setWidth(int w);

    void setHeight(int h);

signals:
    void gridDataChanged();
    void widthChanged();
    void heightChanged();

private:
    void updateTexture();

    QByteArray m_gridData;
    int m_width = 0;
    int m_height = 0;
};

#endif // RAWGRIDTEXTUREDATA_H
