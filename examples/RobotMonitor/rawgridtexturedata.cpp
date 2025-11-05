#include "rawgridtexturedata.h"
#include <qsize.h>

RawGridTextureData::RawGridTextureData(QQuick3DObject *parent)
    : QQuick3DTextureData(parent)
{
    setFormat(QQuick3DTextureData::R8); // 1 Byte per pixel (Red channel)
    setHasTransparency(false);
}

void RawGridTextureData::setGridData(const QByteArray &data) {
    if (m_gridData == data) return;
    m_gridData = data;
    updateTexture();
    emit gridDataChanged();
}

void RawGridTextureData::setWidth(int w) {
    if (m_width == w) return;
    m_width = w;
    updateTexture();
    emit widthChanged();
}

void RawGridTextureData::setHeight(int h) {
    if (m_height == h) return;
    m_height = h;
    updateTexture();
    emit heightChanged();
}

void RawGridTextureData::updateTexture() {
    if (m_width <= 0 || m_height <= 0 || m_gridData.isEmpty()) return;

    // Safety: Ensure buffer matches dimensions
    // Note: ROS maps sometimes have padding, but usually W*H matches data.size()
    if (m_gridData.size() < (m_width * m_height)) return;

    setSize(QSize(m_width, m_height));
    setTextureData(m_gridData); // Internal copy to GPU staging buffer
    update();
}
