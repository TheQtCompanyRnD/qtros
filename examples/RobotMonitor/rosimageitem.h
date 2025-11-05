#ifndef ROSIMAGEITEM_H
#define ROSIMAGEITEM_H

#include <QQuickItem>
#include <QQuickWindow>
#include <QSGSimpleTextureNode>
#include <qtros2_sensor_msgs/msg/image.hpp>

class RosImageItem : public QQuickItem
{
    Q_OBJECT
    Q_PROPERTY(Qtros2SensorMsgs::Image image READ image WRITE setImage NOTIFY imageChanged)
    QML_ELEMENT

public:
    RosImageItem();

    Qtros2SensorMsgs::Image image() const { return m_image; }

    void setImage(const Qtros2SensorMsgs::Image &img);

signals:
    void imageChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;

private:
    Qtros2SensorMsgs::Image m_image;
    bool m_dirty = false;
};

#endif // ROSIMAGEITEM_H
