// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only WITH Qt-GPL-exception-1.0
#pragma once

#include <QMainWindow>
#include <QStringList>
#include <QTemporaryDir>
#include <memory>

class QCheckBox;
class QComboBox;
class QDoubleSpinBox;
class QJsonObject;
class QLineEdit;
class QPlainTextEdit;
class QPushButton;
class QQuickWidget;
class QSpinBox;

class ImporterWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit ImporterWindow(QWidget *parent = nullptr);
    void setUrdfPath(const QString &path);
    void setOutputPath(const QString &path);
    void setExportAssets(bool v);
    void setRosBridge(bool v);
    void setUnitsPerMeter(double v);
    void setTopicPrefix(const QString &pfx);

private slots:
    void browseUrdf();
    void browseOutputDirectory();
    void runPreview();
    void runExport();

private:
    enum class RunMode {
        Preview,
        Export
    };

    void buildUi();
    void attachPreviewErrorLogger(QQuickWidget *widget);
    void recreatePreviewWidget();
    void setUiBusy(bool busy);
    bool clearDirectoryContents(const QString &dirPath, QString *errorMessage) const;
    void appendLog(const QString &text);
    QStringList splitSettingLines(const QString &text) const;
    bool validateCommonInput(bool requireOutputDir, QString *errorMessage) const;
    QString pythonExecutable() const;
    QString exporterScriptPath() const;
    QStringList buildExporterArguments(
        const QString &destDir,
        const QString &manifestPath,
        QString *validationError) const;
    bool runExporter(const QString &destDir, const QString &manifestPath, RunMode mode);
    bool readManifest(const QString &manifestPath, QString *errorMessage, QJsonObject *manifest) const;
    void handleManifestResult(const QJsonObject &manifest, RunMode mode);
    void reloadPreview(const QJsonObject &manifest);

    QLineEdit *m_urdfPathEdit = nullptr;
    QLineEdit *m_outputDirEdit = nullptr;
    QDoubleSpinBox *m_sceneUnitsPerMeterSpin = nullptr;
    QDoubleSpinBox *m_instanceScaleSpin = nullptr;
    QComboBox *m_meshUnitCombo = nullptr;
    QDoubleSpinBox *m_meshUnitCustomToMeterSpin = nullptr;
    QDoubleSpinBox *m_meshRollSpin = nullptr;
    QDoubleSpinBox *m_meshPitchSpin = nullptr;
    QDoubleSpinBox *m_meshYawSpin = nullptr;
    QCheckBox *m_axisTransformCheck = nullptr;
    QCheckBox *m_useJointsJsonCheck = nullptr;
    QCheckBox *m_generateAssetsCheck = nullptr;
    QLineEdit *m_balsamBinEdit = nullptr;
    QSpinBox *m_balsamTimeoutSpin = nullptr;
    QPlainTextEdit *m_packageMapEdit = nullptr;
    QPlainTextEdit *m_balsamOptionsEdit = nullptr;
    QPlainTextEdit *m_logsEdit = nullptr;
    QPushButton *m_runPreviewButton = nullptr;
    QPushButton *m_runExportButton = nullptr;
    QQuickWidget *m_previewWidget = nullptr;

    // ROS Bridge
    QCheckBox *m_rosBridgeCheck = nullptr;
    QLineEdit *m_jointStatesTopicEdit = nullptr;

    // Physics
    QCheckBox *m_physicsCheck = nullptr;

    std::unique_ptr<QTemporaryDir> m_previewTempDir;
    bool m_isRunning = false;
};
