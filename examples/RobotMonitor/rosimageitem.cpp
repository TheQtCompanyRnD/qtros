#include "rosimageitem.h"

RosImageItem::RosImageItem()
{
    setFlag(ItemHasContents, true);
}

void RosImageItem::setImage(const Qtros2SensorMsgs::Image &img)
{
    // Simple check to avoid redundant updates if data hasn't changed.
    // For video streams, we usually just check if data size or timestamp differs.
    if (m_image.header().stamp() == img.header().stamp()
        && m_image.data().size() == img.data().size()) {
        return;
    }

    m_image = img;
    m_dirty = true;
    emit imageChanged();
    update(); // Schedule a repaint
}

QSGNode *RosImageItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    auto node = static_cast<QSGSimpleTextureNode *>(oldNode);

    if (m_image.data().isEmpty()) {
        return node;
    }

    if (!node) {
        node = new QSGSimpleTextureNode();
        node->setFiltering(QSGTexture::Linear);
    }

    if (m_dirty) {
        QImage::Format format = QImage::Format_Invalid;
        const QString encoding = m_image.encoding();

        // --- Corrected Mappings ---
        if (encoding == "rgb8")
            format = QImage::Format_RGB888;
        else if (encoding == "bgr8")
            format = QImage::Format_BGR888;
        else if (encoding == "rgba8")
            format = QImage::Format_RGBA8888;

        // FIX: Use ARGB32 for BGRA data on Little Endian systems
        else if (encoding == "bgra8")
            format = QImage::Format_ARGB32;

        else if (encoding == "mono8")
            format = QImage::Format_Grayscale8;

        if (format != QImage::Format_Invalid) {
            // Zero-Copy Wrapper
            QImage wrapper(reinterpret_cast<const uchar *>(m_image.data().constData()),
                           m_image.width(),
                           m_image.height(),
                           m_image.step(),
                           format);

            // If existing texture matches size, we can update it; otherwise recreate.
            if (node->texture()) {
                delete node->texture();
            }

            QSGTexture *tex = window()->createTextureFromImage(wrapper);
            node->setTexture(tex);
            node->setRect(boundingRect());
        }
        m_dirty = false;
    }

    node->setRect(boundingRect());
    return node;
}
