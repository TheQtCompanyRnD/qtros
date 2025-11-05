#include "gridpalette.h"
#include <qsize.h>


GridPalette::GridPalette() {
    setSize(QSize(256, 1));
    setFormat(QQuick3DTextureData::RGBA8);
    setHasTransparency(true);
    setScheme(Grayscale);
}

void GridPalette::setScheme(int s) {
    if (m_scheme == s) return;
    m_scheme = s;
    rebuild();
    emit schemeChanged();
}

void GridPalette::rebuild() {
    QByteArray lut(256 * 4, 0); // 256 pixels, RGBA8888
    uchar* p = reinterpret_cast<uchar*>(lut.data());

    auto setPixel = [&](int i, uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
        p[i*4+0] = r;
        p[i*4+1] = g;
        p[i*4+2] = b;
        p[i*4+3] = a;
    };

    // Standard ROS "Unknown" color from your old code
    // : QColor(128, 128, 128, 204) (approx 0.8 alpha)
    const uint8_t unkR = 128, unkG = 128, unkB = 128, unkA = 204;

    for (int i = 0; i < 256; ++i) {
        // ROS -1 (Unknown) becomes 255 (0xFF) in unsigned byte texture
        if (i == 255) {
            setPixel(i, unkR, unkG, unkB, unkA);
            continue;
        }

        // ROS values are 0 to 100.
        // Values 101-254 are technically undefined/unused in standard ROS maps.
        // We treat them as unknown or clamp them to 100.
        // Let's treat them as Unknown to be safe.
        if (i > 100) {
            setPixel(i, unkR, unkG, unkB, unkA);
            continue;
        }

        // --- Your Logic Ported from mapOccupancyToColor [cite: 90-118] ---

        float normalized = static_cast<float>(i) / 100.0f; // 0.0 to 1.0

        if (m_scheme == Grayscale) {
            // : 255 * (1.0 - normalized) -> White to Black
            uint8_t val = static_cast<uint8_t>(255.0f * (1.0f - normalized));
            setPixel(i, val, val, val, 255);
        }
        else if (m_scheme == CostmapHot) {
            //[cite: 97]: 0 is transparent
            if (i == 0) {
                setPixel(i, 0, 0, 0, 0);
            } else if (i < 50) {
                // : Fade from Black to Yellow
                float t = normalized * 2.0f;
                uint8_t val = static_cast<uint8_t>(255.0f * t);
                setPixel(i, val, val, 0, 255);
            } else {
                // : Fade from Yellow to Red
                float t = (normalized - 0.5f) * 2.0f;
                uint8_t g = static_cast<uint8_t>(255.0f * (1.0f - t));
                setPixel(i, 255, g, 0, 255);
            }
        }
        else if (m_scheme == CostmapCool) {
            //[cite: 112]: 0 is transparent
            if (i == 0) {
                setPixel(i, 0, 0, 0, 0);
            } else {
                //: Fade from Black to Cyan
                uint8_t val = static_cast<uint8_t>(255.0f * normalized);
                setPixel(i, 0, val, val, 255);
            }
        } else if (m_scheme == Jet) {
            // 0 = Safe (Blue) -> 100 = Lethal (Red)
            // We strictly use 255 Alpha to ensure the floor is visible against the black background.

            float n = normalized; // 0.0 to 1.0
            uint8_t r = 0, g = 0, b = 0;

            // Divide the spectrum into 4 regions to transition:
            // Blue -> Cyan -> Green -> Yellow -> Red
            if (n < 0.25f) {
                // Region 1: Blue (0,0,255) to Cyan (0,255,255)
                // (Increase Green)
                float t = n / 0.25f;
                r = 0;
                g = static_cast<uint8_t>(255.0f * t);
                b = 255;
            } else if (n < 0.5f) {
                // Region 2: Cyan (0,255,255) to Green (0,255,0)
                // (Decrease Blue)
                float t = (n - 0.25f) / 0.25f;
                r = 0;
                g = 255;
                b = static_cast<uint8_t>(255.0f * (1.0f - t));
            } else if (n < 0.75f) {
                // Region 3: Green (0,255,0) to Yellow (255,255,0)
                // (Increase Red)
                float t = (n - 0.5f) / 0.25f;
                r = static_cast<uint8_t>(255.0f * t);
                g = 255;
                b = 0;
            } else {
                // Region 4: Yellow (255,255,0) to Red (255,0,0)
                // (Decrease Green)
                float t = (n - 0.75f) / 0.25f;
                r = 255;
                g = static_cast<uint8_t>(255.0f * (1.0f - t));
                b = 0;
            }

            setPixel(i, r, g, b, 255);
        } else {
            // Default / Fallback
            uint8_t val = static_cast<uint8_t>(255.0f * (1.0f - normalized));
            setPixel(i, val, val, val, 255);
        }
    }

    markAllDirty();
    setTextureData(lut);
}
