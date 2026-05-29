// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only WITH Qt-GPL-exception-1.0
#include "ImporterWindow.h"

#include "importer_config.h"

#include <QCheckBox>
#include <QComboBox>
#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QDoubleSpinBox>
#include <QEventLoop>
#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
#include <QFormLayout>
#include <QGridLayout>
#include <QGroupBox>
#include <QHBoxLayout>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QLabel>
#include <QLibraryInfo>
#include <QLineEdit>
#include <QMessageBox>
#include <QPlainTextEdit>
#include <QProcess>
#include <QPushButton>
#include <QQuickWidget>
#include <QQmlEngine>
#include <QQmlError>
#include <QRegularExpression>
#include <QtCore/qscopeguard.h>
#include <QSpinBox>
#include <QSplitter>
#include <QStandardPaths>
#include <QStatusBar>
#include <QTemporaryDir>
#include <QTextCursor>
#include <QUrl>
#include <QVBoxLayout>
#include <QWidget>

ImporterWindow::ImporterWindow(QWidget *parent)
    : QMainWindow(parent)
{
    buildUi();
    setWindowTitle(QStringLiteral("URDF Asset Importer (MVP)"));
}

void ImporterWindow::buildUi()
{
    auto *central = new QWidget(this);
    auto *rootLayout = new QVBoxLayout(central);
    rootLayout->setContentsMargins(6, 6, 6, 6);

    auto *splitter = new QSplitter(Qt::Horizontal, central);
    rootLayout->addWidget(splitter, 1);
    setCentralWidget(central);

    auto *leftPanel = new QWidget(splitter);
    auto *leftLayout = new QVBoxLayout(leftPanel);
    leftLayout->setContentsMargins(0, 0, 0, 0);
    leftLayout->setSpacing(8);

    auto *inputGroup = new QGroupBox(QStringLiteral("Input"), leftPanel);
    auto *inputLayout = new QGridLayout(inputGroup);
    m_urdfPathEdit = new QLineEdit(inputGroup);
    m_outputDirEdit = new QLineEdit(inputGroup);
    auto *browseUrdfButton = new QPushButton(QStringLiteral("Browse..."), inputGroup);
    auto *browseOutputButton = new QPushButton(QStringLiteral("Browse..."), inputGroup);
    inputLayout->addWidget(new QLabel(QStringLiteral("URDF / Xacro")), 0, 0);
    inputLayout->addWidget(m_urdfPathEdit, 0, 1);
    inputLayout->addWidget(browseUrdfButton, 0, 2);
    inputLayout->addWidget(new QLabel(QStringLiteral("Export Directory")), 1, 0);
    inputLayout->addWidget(m_outputDirEdit, 1, 1);
    inputLayout->addWidget(browseOutputButton, 1, 2);

    auto *actionRow = new QWidget(inputGroup);
    auto *actionLayout = new QHBoxLayout(actionRow);
    actionLayout->setContentsMargins(0, 0, 0, 0);
    m_runPreviewButton = new QPushButton(QStringLiteral("Run Preview"), actionRow);
    m_runExportButton = new QPushButton(QStringLiteral("Run Export"), actionRow);
    actionLayout->addWidget(m_runPreviewButton);
    actionLayout->addWidget(m_runExportButton);
    inputLayout->addWidget(actionRow, 2, 1, 1, 2);

    auto *settingsGroup = new QGroupBox(QStringLiteral("Settings"), leftPanel);
    auto *settingsLayout = new QVBoxLayout(settingsGroup);
    auto *form = new QFormLayout();

    m_sceneUnitsPerMeterSpin = new QDoubleSpinBox(settingsGroup);
    m_sceneUnitsPerMeterSpin->setDecimals(6);
    m_sceneUnitsPerMeterSpin->setRange(0.000001, 1000000.0);
    m_sceneUnitsPerMeterSpin->setValue(100.0);

    m_instanceScaleSpin = new QDoubleSpinBox(settingsGroup);
    m_instanceScaleSpin->setDecimals(6);
    m_instanceScaleSpin->setRange(0.000001, 1000000.0);
    m_instanceScaleSpin->setValue(1.0);

    m_meshUnitCombo = new QComboBox(settingsGroup);
    m_meshUnitCombo->addItem(QStringLiteral("Auto"), QStringLiteral("auto"));
    m_meshUnitCombo->addItem(QStringLiteral("Meter"), QStringLiteral("meter"));
    m_meshUnitCombo->addItem(QStringLiteral("Centimeter"), QStringLiteral("centimeter"));
    m_meshUnitCombo->addItem(QStringLiteral("Millimeter"), QStringLiteral("millimeter"));
    m_meshUnitCombo->addItem(QStringLiteral("Custom"), QStringLiteral("custom"));
    m_meshUnitCombo->setCurrentIndex(0);

    m_meshUnitCustomToMeterSpin = new QDoubleSpinBox(settingsGroup);
    m_meshUnitCustomToMeterSpin->setDecimals(9);
    m_meshUnitCustomToMeterSpin->setRange(0.000000001, 1000000.0);
    m_meshUnitCustomToMeterSpin->setValue(1.0);
    m_meshUnitCustomToMeterSpin->setEnabled(false);

    m_meshRollSpin = new QDoubleSpinBox(settingsGroup);
    m_meshPitchSpin = new QDoubleSpinBox(settingsGroup);
    m_meshYawSpin = new QDoubleSpinBox(settingsGroup);
    for (QDoubleSpinBox *spin : {m_meshRollSpin, m_meshPitchSpin, m_meshYawSpin}) {
        spin->setDecimals(3);
        spin->setRange(-3600.0, 3600.0);
        spin->setSingleStep(1.0);
        spin->setSuffix(QStringLiteral(" deg"));
        spin->setValue(0.0);
    }

    m_axisTransformCheck = new QCheckBox(QStringLiteral("Enable Axis Transform (Z-up -> Y-up)"), settingsGroup);
    m_axisTransformCheck->setChecked(true);
    m_useJointsJsonCheck = new QCheckBox(QStringLiteral("Use joints JSON at runtime"), settingsGroup);

    m_balsamBinEdit = new QLineEdit(settingsGroup);
    m_balsamBinEdit->setPlaceholderText(QStringLiteral("Auto-detect from Qt install"));
    m_balsamTimeoutSpin = new QSpinBox(settingsGroup);
    m_balsamTimeoutSpin->setRange(1, 36000);
    m_balsamTimeoutSpin->setValue(300);

    form->addRow(QStringLiteral("Scene Units Per Meter"), m_sceneUnitsPerMeterSpin);
    form->addRow(QStringLiteral("Instance Scale"), m_instanceScaleSpin);
    form->addRow(QStringLiteral("Mesh Unit"), m_meshUnitCombo);
    form->addRow(QStringLiteral("Mesh Unit Custom->Meter"), m_meshUnitCustomToMeterSpin);
    auto *meshRotationRow = new QWidget(settingsGroup);
    auto *meshRotationLayout = new QHBoxLayout(meshRotationRow);
    meshRotationLayout->setContentsMargins(0, 0, 0, 0);
    meshRotationLayout->setSpacing(6);
    meshRotationLayout->addWidget(new QLabel(QStringLiteral("R"), meshRotationRow));
    meshRotationLayout->addWidget(m_meshRollSpin);
    meshRotationLayout->addWidget(new QLabel(QStringLiteral("P"), meshRotationRow));
    meshRotationLayout->addWidget(m_meshPitchSpin);
    meshRotationLayout->addWidget(new QLabel(QStringLiteral("Y"), meshRotationRow));
    meshRotationLayout->addWidget(m_meshYawSpin);
    form->addRow(QStringLiteral("Mesh Rotation"), meshRotationRow);
    form->addRow(QString(), m_axisTransformCheck);
    form->addRow(QString(), m_useJointsJsonCheck);
    form->addRow(QStringLiteral("Balsam Binary Override"), m_balsamBinEdit);
    form->addRow(QStringLiteral("Balsam Timeout (sec)"), m_balsamTimeoutSpin);
    settingsLayout->addLayout(form);

    settingsLayout->addWidget(new QLabel(QStringLiteral("Package Map (NAME:=PATH, one per line)"), settingsGroup));
    m_packageMapEdit = new QPlainTextEdit(settingsGroup);
    m_packageMapEdit->setPlaceholderText(QStringLiteral("my_pkg:=/path/to/package"));
    m_packageMapEdit->setMaximumBlockCount(200);
    settingsLayout->addWidget(m_packageMapEdit);

    settingsLayout->addWidget(new QLabel(QStringLiteral("Balsam Options (one arg per line)"), settingsGroup));
    m_balsamOptionsEdit = new QPlainTextEdit(settingsGroup);
    m_balsamOptionsEdit->setPlaceholderText(QStringLiteral("--importOption=value"));
    m_balsamOptionsEdit->setMaximumBlockCount(200);
    settingsLayout->addWidget(m_balsamOptionsEdit);

    // ROS Bridge group
    auto *rosGroup = new QGroupBox(QStringLiteral("ROS Bridge"), leftPanel);
    auto *rosLayout = new QFormLayout(rosGroup);
    m_rosBridgeCheck = new QCheckBox(
        QStringLiteral("Enable ROS Bridge preview"), rosGroup);
    m_jointStatesTopicEdit = new QLineEdit(QStringLiteral("/joint_states"), rosGroup);
    m_jointStatesTopicEdit->setEnabled(false);
    rosLayout->addRow(QString(), m_rosBridgeCheck);
    rosLayout->addRow(QStringLiteral("Joint States Topic"), m_jointStatesTopicEdit);

    // Physics group
    auto *physicsGroup = new QGroupBox(QStringLiteral("Physics"), leftPanel);
    auto *physicsLayout = new QFormLayout(physicsGroup);
    m_physicsCheck = new QCheckBox(
        QStringLiteral("Integrate physics bodies (QtQuick3DPhysics)"), physicsGroup);
    m_physicsCheck->setChecked(true);
    physicsLayout->addRow(QString(), m_physicsCheck);

    auto *logsGroup = new QGroupBox(QStringLiteral("Logs"), leftPanel);
    auto *logsLayout = new QVBoxLayout(logsGroup);
    m_logsEdit = new QPlainTextEdit(logsGroup);
    m_logsEdit->setReadOnly(true);
    m_logsEdit->setMaximumBlockCount(8000);
    logsLayout->addWidget(m_logsEdit);

    leftLayout->addWidget(inputGroup);
    leftLayout->addWidget(settingsGroup, 1);
    leftLayout->addWidget(rosGroup);
    leftLayout->addWidget(physicsGroup);
    leftLayout->addWidget(logsGroup, 1);

    auto *previewGroup = new QGroupBox(QStringLiteral("Preview"), splitter);
    auto *previewLayout = new QVBoxLayout(previewGroup);
    m_previewWidget = new QQuickWidget(previewGroup);
    m_previewWidget->setResizeMode(QQuickWidget::SizeRootObjectToView);
    attachPreviewErrorLogger(m_previewWidget);
    previewLayout->addWidget(m_previewWidget);

    splitter->addWidget(leftPanel);
    splitter->addWidget(previewGroup);
    splitter->setStretchFactor(0, 0);
    splitter->setStretchFactor(1, 1);
    splitter->setSizes({520, 1080});

    connect(browseUrdfButton, &QPushButton::clicked, this, &ImporterWindow::browseUrdf);
    connect(browseOutputButton, &QPushButton::clicked, this, &ImporterWindow::browseOutputDirectory);
    connect(m_runPreviewButton, &QPushButton::clicked, this, &ImporterWindow::runPreview);
    connect(m_runExportButton, &QPushButton::clicked, this, &ImporterWindow::runExport);
    connect(m_meshUnitCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, [this](int) {
        const bool isCustom = m_meshUnitCombo->currentData().toString() == QStringLiteral("custom");
        m_meshUnitCustomToMeterSpin->setEnabled(isCustom);
    });
    connect(m_rosBridgeCheck, &QCheckBox::toggled, this, [this](bool checked) {
        m_jointStatesTopicEdit->setEnabled(checked);
    });

}

void ImporterWindow::attachPreviewErrorLogger(QQuickWidget *widget)
{
    connect(widget, &QQuickWidget::statusChanged, this, [this, widget](QQuickWidget::Status status) {
        if (status != QQuickWidget::Error) {
            return;
        }
        const QList<QQmlError> qmlErrors = widget->errors();
        for (const QQmlError &error : qmlErrors) {
            appendLog(QStringLiteral("[QML] %1").arg(error.toString()));
        }
    });
}

void ImporterWindow::recreatePreviewWidget()
{
    if (!m_previewWidget) {
        return;
    }

    QWidget *container = m_previewWidget->parentWidget();
    auto *layout = container ? qobject_cast<QVBoxLayout *>(container->layout()) : nullptr;

    auto *newPreviewWidget = new QQuickWidget(container);
    newPreviewWidget->setResizeMode(QQuickWidget::SizeRootObjectToView);
    attachPreviewErrorLogger(newPreviewWidget);

    if (layout) {
        layout->removeWidget(m_previewWidget);
    }
    m_previewWidget->setSource(QUrl());
    delete m_previewWidget;
    m_previewWidget = newPreviewWidget;
    if (layout) {
        layout->addWidget(m_previewWidget);
    }
}

void ImporterWindow::setUiBusy(bool busy)
{
    if (m_runPreviewButton) {
        m_runPreviewButton->setEnabled(!busy);
    }
    if (m_runExportButton) {
        m_runExportButton->setEnabled(!busy);
    }
}

bool ImporterWindow::clearDirectoryContents(const QString &dirPath, QString *errorMessage) const
{
    QDir dir(dirPath);
    if (!dir.exists()) {
        if (errorMessage) {
            *errorMessage = QStringLiteral("Directory does not exist: %1").arg(dirPath);
        }
        return false;
    }

    const QFileInfoList entries = dir.entryInfoList(
        QDir::NoDotAndDotDot | QDir::AllEntries,
        QDir::DirsFirst | QDir::Name);

    for (const QFileInfo &entry : entries) {
        if (entry.isDir()) {
            QDir subDir(entry.absoluteFilePath());
            if (!subDir.removeRecursively()) {
                if (errorMessage) {
                    *errorMessage = QStringLiteral("Failed to clear preview directory: %1")
                                        .arg(entry.absoluteFilePath());
                }
                return false;
            }
            continue;
        }

        if (!QFile::remove(entry.absoluteFilePath())) {
            if (errorMessage) {
                *errorMessage = QStringLiteral("Failed to remove file in preview directory: %1")
                                    .arg(entry.absoluteFilePath());
            }
            return false;
        }
    }
    return true;
}

void ImporterWindow::browseUrdf()
{
    const QString filePath = QFileDialog::getOpenFileName(
        this,
        QStringLiteral("Select URDF or Xacro"),
        m_urdfPathEdit->text(),
        QStringLiteral("URDF/Xacro (*.urdf *.URDF *.xacro *.xml);;All Files (*)"));
    if (!filePath.isEmpty()) {
        m_urdfPathEdit->setText(QDir::toNativeSeparators(filePath));
    }
}

void ImporterWindow::browseOutputDirectory()
{
    const QString dirPath = QFileDialog::getExistingDirectory(
        this,
        QStringLiteral("Select Export Directory"),
        m_outputDirEdit->text());
    if (!dirPath.isEmpty()) {
        m_outputDirEdit->setText(QDir::toNativeSeparators(dirPath));
    }
}

void ImporterWindow::setUrdfPath(const QString &path)
{
    m_urdfPathEdit->setText(QDir::toNativeSeparators(path));
}

void ImporterWindow::setOutputPath(const QString &path)
{
    m_outputDirEdit->setText(QDir::toNativeSeparators(path));
}

void ImporterWindow::setRosBridge(bool v)
{
    m_rosBridgeCheck->setChecked(v);
}

void ImporterWindow::setUnitsPerMeter(double v)
{
    m_sceneUnitsPerMeterSpin->setValue(v);
}

void ImporterWindow::setTopicPrefix(const QString &pfx)
{
    m_jointStatesTopicEdit->setText((pfx.startsWith('/') ? pfx : '/' + pfx) +
                                    m_jointStatesTopicEdit->text());
}

void ImporterWindow::runPreview()
{
    if (m_isRunning) {
        appendLog(QStringLiteral("[preview] Exporter is already running."));
        return;
    }

    QString error;
    if (!validateCommonInput(false, &error)) {
        QMessageBox::warning(this, QStringLiteral("Invalid Input"), error);
        return;
    }

    if (!m_previewTempDir || !m_previewTempDir->isValid()) {
        const QString previewTemplate =
            QDir::temp().absoluteFilePath(QStringLiteral("urdf_asset_importer_preview_XXXXXX"));
        m_previewTempDir = std::make_unique<QTemporaryDir>(previewTemplate);
        if (!m_previewTempDir || !m_previewTempDir->isValid()) {
            QMessageBox::critical(this, QStringLiteral("Preview Error"), QStringLiteral("Failed to create temporary preview directory."));
            return;
        }
    }

    const QString destDir = QDir(m_previewTempDir->path()).absolutePath();
    QString clearError;
    if (!clearDirectoryContents(destDir, &clearError)) {
        QMessageBox::critical(this, QStringLiteral("Preview Error"), clearError);
        return;
    }
    const QString manifestPath = QDir(destDir).absoluteFilePath(QStringLiteral("manifest.json"));
    appendLog(QStringLiteral("[preview] temp dir: %1").arg(destDir));
    runExporter(destDir, manifestPath, RunMode::Preview);
}

void ImporterWindow::runExport()
{
    if (m_isRunning) {
        appendLog(QStringLiteral("[export] Exporter is already running."));
        return;
    }

    QString error;
    if (!validateCommonInput(true, &error)) {
        QMessageBox::warning(this, QStringLiteral("Invalid Input"), error);
        return;
    }

    const QString exportDirPath = QDir(m_outputDirEdit->text().trimmed()).absolutePath();
    if (!QDir(exportDirPath).exists() && !QDir().mkpath(exportDirPath)) {
        QMessageBox::critical(this, QStringLiteral("Export Error"), QStringLiteral("Failed to create export directory."));
        return;
    }

    QTemporaryDir manifestDir(QStringLiteral("urdf_asset_importer_manifest_XXXXXX"));
    if (!manifestDir.isValid()) {
        QMessageBox::critical(this, QStringLiteral("Export Error"), QStringLiteral("Failed to create temporary manifest directory."));
        return;
    }

    const QString manifestBaseDir = QDir(manifestDir.path()).absolutePath();
    const QString manifestPath = QDir(manifestBaseDir).absoluteFilePath(QStringLiteral("manifest.json"));
    runExporter(exportDirPath, manifestPath, RunMode::Export);
}

void ImporterWindow::appendLog(const QString &text)
{
    if (text.isEmpty()) {
        return;
    }
    m_logsEdit->moveCursor(QTextCursor::End);
    m_logsEdit->insertPlainText(text);
    if (!text.endsWith(QLatin1Char('\n'))) {
        m_logsEdit->insertPlainText(QStringLiteral("\n"));
    }
    m_logsEdit->moveCursor(QTextCursor::End);
}

QStringList ImporterWindow::splitSettingLines(const QString &text) const
{
    QStringList result;
    const QStringList lines = text.split(QRegularExpression(QStringLiteral("[\r\n]+")), Qt::SkipEmptyParts);
    for (const QString &rawLine : lines) {
        const QString line = rawLine.trimmed();
        if (line.isEmpty() || line.startsWith(QLatin1Char('#'))) {
            continue;
        }
        result.push_back(line);
    }
    return result;
}

bool ImporterWindow::validateCommonInput(bool requireOutputDir, QString *errorMessage) const
{
    const QString urdfPath = m_urdfPathEdit->text().trimmed();
    if (urdfPath.isEmpty()) {
        *errorMessage = QStringLiteral("URDF/Xacro file path is required.");
        return false;
    }
    if (!QFileInfo::exists(urdfPath) || !QFileInfo(urdfPath).isFile()) {
        *errorMessage = QStringLiteral("URDF/Xacro file does not exist.");
        return false;
    }

    const QString scriptPath = exporterScriptPath();
    if (!QFileInfo::exists(scriptPath)) {
        *errorMessage = QStringLiteral("Could not find exporter script: %1").arg(scriptPath);
        return false;
    }

    if (requireOutputDir && m_outputDirEdit->text().trimmed().isEmpty()) {
        *errorMessage = QStringLiteral("Export directory is required.");
        return false;
    }
    return true;
}

QString ImporterWindow::pythonExecutable() const
{
    const QString configured = QString::fromUtf8(URDF2Q3D_PYTHON_EXECUTABLE);
    if (!configured.isEmpty() && QFileInfo::exists(configured)) {
        return configured;
    }

    const QStringList candidates = {
        QStringLiteral("python3"),
        QStringLiteral("python")
    };
    for (const QString &candidate : candidates) {
        const QString resolved = QStandardPaths::findExecutable(candidate);
        if (!resolved.isEmpty()) {
            return resolved;
        }
    }
    return configured.isEmpty() ? QStringLiteral("python3") : configured;
}

QString ImporterWindow::exporterScriptPath() const
{
    const QString libexecDir = QLibraryInfo::path(QLibraryInfo::LibraryExecutablesPath);
    return QDir::cleanPath(QDir(libexecDir).filePath(QStringLiteral("urdf2quickexporter.py")));
}

QStringList ImporterWindow::buildExporterArguments(
    const QString &destDir,
    const QString &manifestPath,
    QString *validationError) const
{
    const QString absoluteUrdfPath = QFileInfo(m_urdfPathEdit->text().trimmed()).absoluteFilePath();
    const QString absoluteDestDir = QDir(destDir).absolutePath();
    const QString absoluteManifestPath = QFileInfo(manifestPath).absoluteFilePath();

    QStringList args;
    args << exporterScriptPath();
    args << absoluteUrdfPath;
    args << absoluteDestDir;

    if (m_axisTransformCheck->isChecked()) {
        args << QStringLiteral("--axis-transform");
    } else {
        args << QStringLiteral("--no-axis-transform");
    }
    args << QStringLiteral("--scene-units-per-meter")
         << QString::number(m_sceneUnitsPerMeterSpin->value(), 'g', 15);
    args << QStringLiteral("--instance-scale")
         << QString::number(m_instanceScaleSpin->value(), 'g', 15);
    const QString meshUnit = m_meshUnitCombo->currentData().toString();
    args << QStringLiteral("--mesh-unit") << meshUnit;
    if (meshUnit == QStringLiteral("custom")) {
        args << QStringLiteral("--mesh-unit-custom-to-meter")
             << QString::number(m_meshUnitCustomToMeterSpin->value(), 'g', 15);
    }
    args << QStringLiteral("--mesh-rotation")
         << QString::number(m_meshRollSpin->value(), 'g', 15)
         << QString::number(m_meshPitchSpin->value(), 'g', 15)
         << QString::number(m_meshYawSpin->value(), 'g', 15);

    if (m_useJointsJsonCheck->isChecked()) {
        args << QStringLiteral("--use-joints-json");
    }

    const QString balsamBin = m_balsamBinEdit->text().trimmed();
    if (!balsamBin.isEmpty()) {
        args << QStringLiteral("--balsam-bin") << balsamBin;
    }
    args << QStringLiteral("--balsam-timeout") << QString::number(m_balsamTimeoutSpin->value());

    const QStringList packageMapLines = splitSettingLines(m_packageMapEdit->toPlainText());
    for (const QString &line : packageMapLines) {
        const int separator = line.indexOf(QStringLiteral(":="));
        if (separator <= 0 || separator >= line.size() - 2) {
            *validationError = QStringLiteral("Invalid package-map entry: %1").arg(line);
            return {};
        }
        const QString packageName = line.left(separator).trimmed();
        const QString packagePath = line.mid(separator + 2).trimmed();
        if (packageName.isEmpty() || packagePath.isEmpty()) {
            *validationError = QStringLiteral("Invalid package-map entry: %1").arg(line);
            return {};
        }
        const QString absolutePackagePath = QFileInfo(packagePath).absoluteFilePath();
        args << QStringLiteral("--package-map")
             << QStringLiteral("%1:=%2").arg(packageName, absolutePackagePath);
    }

    const QStringList balsamOptionLines = splitSettingLines(m_balsamOptionsEdit->toPlainText());
    for (const QString &line : balsamOptionLines) {
        args << QStringLiteral("--balsam-option") << line;
    }

    args << QStringLiteral("--manifest-out") << absoluteManifestPath;

    if (m_rosBridgeCheck && m_rosBridgeCheck->isChecked()) {
        args << QStringLiteral("--ros-bridge");
        const QString topic = m_jointStatesTopicEdit->text().trimmed();
        if (!topic.isEmpty()) {
            args << QStringLiteral("--joint-states-topic") << topic;
        }
    }

    if (m_physicsCheck && m_physicsCheck->isChecked())
        args << QStringLiteral("--physics");

    return args;
}

bool ImporterWindow::runExporter(const QString &destDir, const QString &manifestPath, RunMode mode)
{
    const QString modeName = mode == RunMode::Preview ? QStringLiteral("Preview") : QStringLiteral("Export");
    if (m_isRunning) {
        appendLog(QStringLiteral("[%1] Already running; request ignored.").arg(modeName));
        return false;
    }

    m_isRunning = true;
    setUiBusy(true);
    auto busyGuard = qScopeGuard([this]() {
        setUiBusy(false);
        m_isRunning = false;
    });

    const QString absoluteManifestPath = QFileInfo(manifestPath).absoluteFilePath();
    const QString manifestDir = QFileInfo(absoluteManifestPath).absolutePath();
    if (!manifestDir.isEmpty()) {
        QDir().mkpath(manifestDir);
    }
    if (QFileInfo::exists(absoluteManifestPath)) {
        QFile::remove(absoluteManifestPath);
    }

    QString validationError;
    const QStringList arguments = buildExporterArguments(destDir, absoluteManifestPath, &validationError);
    if (arguments.isEmpty()) {
        QMessageBox::warning(this, QStringLiteral("Invalid Settings"), validationError);
        return false;
    }

    const QString pythonExe = pythonExecutable();
    appendLog(QStringLiteral("\n[%1] %2")
                  .arg(QDateTime::currentDateTime().toString(Qt::ISODate), modeName));
    appendLog(QStringLiteral("Program: %1").arg(pythonExe));
    appendLog(QStringLiteral("Arguments: %1").arg(arguments.join(QStringLiteral(" | "))));

    QProcess process(this);
    process.setProgram(pythonExe);
    process.setArguments(arguments);
    process.setProcessChannelMode(QProcess::SeparateChannels);
    process.start();

    if (!process.waitForStarted(5000)) {
        const QString message = QStringLiteral("Failed to start exporter process.");
        appendLog(message);
        QMessageBox::critical(this, QStringLiteral("Process Error"), message);
        return false;
    }

    auto drainProcessOutput = [this, &process]() {
        const QByteArray out = process.readAllStandardOutput();
        if (!out.isEmpty()) {
            appendLog(QString::fromUtf8(out));
        }
        const QByteArray err = process.readAllStandardError();
        if (!err.isEmpty()) {
            appendLog(QString::fromUtf8(err));
        }
    };

    while (!process.waitForFinished(100)) {
        drainProcessOutput();
        QCoreApplication::processEvents(QEventLoop::ExcludeUserInputEvents);
    }
    drainProcessOutput();

    QJsonObject manifest;
    QString manifestError;
    const bool hasManifest = readManifest(absoluteManifestPath, &manifestError, &manifest);
    if (!hasManifest) {
        appendLog(QStringLiteral("[manifest] %1").arg(manifestError));
    }

    if (hasManifest) {
        handleManifestResult(manifest, mode);
    }

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        QString errorText = QStringLiteral("Exporter failed.");
        if (hasManifest) {
            const QString manifestErrorText = manifest.value(QStringLiteral("error")).toString();
            if (!manifestErrorText.isEmpty()) {
                errorText = manifestErrorText;
            }
        }
        QMessageBox::critical(this, QStringLiteral("%1 Failed").arg(modeName), errorText);
        statusBar()->showMessage(QStringLiteral("%1 failed").arg(modeName), 5000);
        return false;
    }

    if (!hasManifest) {
        QMessageBox::critical(this, QStringLiteral("Manifest Error"), QStringLiteral("Exporter completed but manifest is missing or invalid."));
        statusBar()->showMessage(QStringLiteral("Missing manifest"), 5000);
        return false;
    }

    const QString status = manifest.value(QStringLiteral("status")).toString();
    if (status != QStringLiteral("ok")) {
        const QString errorText = manifest.value(QStringLiteral("error")).toString(QStringLiteral("Unknown exporter error."));
        QMessageBox::critical(this, QStringLiteral("%1 Failed").arg(modeName), errorText);
        statusBar()->showMessage(QStringLiteral("%1 failed").arg(modeName), 5000);
        return false;
    }

    statusBar()->showMessage(QStringLiteral("%1 completed").arg(modeName), 5000);
    return true;
}

bool ImporterWindow::readManifest(const QString &manifestPath, QString *errorMessage, QJsonObject *manifest) const
{
    QFile file(manifestPath);
    if (!file.exists()) {
        *errorMessage = QStringLiteral("Manifest file not found: %1").arg(manifestPath);
        return false;
    }
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        *errorMessage = QStringLiteral("Failed to open manifest: %1").arg(manifestPath);
        return false;
    }

    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        *errorMessage = QStringLiteral("Invalid manifest JSON: %1").arg(parseError.errorString());
        return false;
    }

    *manifest = doc.object();
    return true;
}

void ImporterWindow::handleManifestResult(const QJsonObject &manifest, RunMode mode)
{
    const QJsonArray warnings = manifest.value(QStringLiteral("warnings")).toArray();
    bool meshAssetsMissing = false;
    for (const QJsonValue &value : warnings) {
        const QString warningText = value.toString();
        appendLog(QStringLiteral("[warning] %1").arg(warningText));
        if (warningText.contains(QStringLiteral("mesh visuals"), Qt::CaseInsensitive)
            || warningText.contains(QStringLiteral("balsam not found"), Qt::CaseInsensitive)) {
            meshAssetsMissing = true;
        }
    }

    if (manifest.value(QStringLiteral("status")).toString() != QStringLiteral("ok")) {
        const QString errorText = manifest.value(QStringLiteral("error")).toString();
        if (!errorText.isEmpty()) {
            appendLog(QStringLiteral("[error] %1").arg(errorText));
        }
        return;
    }

    if (mode == RunMode::Preview) {
        if (meshAssetsMissing) {
            const QString message =
                QStringLiteral("Mesh visuals were detected, but Balsam could not be found or "
                               "did not generate assets for the preview.\n\n"
                               "Install Balsam or provide its path via the "
                               "'Balsam Binary Override' field in Settings, then run Preview again.");
            appendLog(QStringLiteral("[preview] %1").arg(message));
            QMessageBox::warning(this, QStringLiteral("Preview Assets Missing"), message);
            return;
        }
        reloadPreview(manifest);
        return;
    }

    const QString robotDir = manifest.value(QStringLiteral("robot_dir")).toString();
    appendLog(QStringLiteral("[export] robot_dir=%1").arg(robotDir));
    QMessageBox::information(this, QStringLiteral("Export Complete"), QStringLiteral("Exported to:\n%1").arg(QDir::toNativeSeparators(robotDir)));
}

void ImporterWindow::reloadPreview(const QJsonObject &manifest)
{
    const QString robotDir = manifest.value(QStringLiteral("robot_dir")).toString();
    const QJsonObject files = manifest.value(QStringLiteral("files")).toObject();

    // Use the ROS bridge scene when the checkbox is checked and the file was generated.
    const bool wantRosBridge = m_rosBridgeCheck && m_rosBridgeCheck->isChecked();
    const QString rosPreviewScenePath = files.value(QStringLiteral("ros_preview_scene_qml")).toString();
    const bool hasRosScene = !rosPreviewScenePath.isEmpty();

    QString previewScenePath;
    if (wantRosBridge && hasRosScene) {
        previewScenePath = rosPreviewScenePath;
        appendLog(QStringLiteral("[preview] Using ROS Bridge scene: %1").arg(previewScenePath));
    } else {
        previewScenePath = files.value(QStringLiteral("preview_scene_qml")).toString();
        if (wantRosBridge && !hasRosScene) {
            appendLog(QStringLiteral("[preview] Warning: ROS Bridge was requested but ros_preview_scene_qml is absent in manifest; falling back to static preview."));
        }
    }

    if (previewScenePath.isEmpty()) {
        QMessageBox::critical(this, QStringLiteral("Preview Error"), QStringLiteral("Manifest missing files.preview_scene_qml."));
        return;
    }

    const QFileInfo previewInfo(previewScenePath);
    if (!previewInfo.exists()) {
        QMessageBox::critical(this, QStringLiteral("Preview Error"), QStringLiteral("Preview scene does not exist:\n%1").arg(previewScenePath));
        return;
    }

    recreatePreviewWidget();

    QQmlEngine *engine = m_previewWidget->engine();
    if (!robotDir.isEmpty()) {
        const QString absoluteRobotDir = QDir(robotDir).absolutePath();
        engine->addImportPath(absoluteRobotDir);
        appendLog(QStringLiteral("[preview] importPath += %1").arg(absoluteRobotDir));
        const QString generatedDir = QDir(absoluteRobotDir).absoluteFilePath(QStringLiteral("Generated"));
        if (QFileInfo(generatedDir).isDir()) {
            engine->addImportPath(generatedDir);
            appendLog(QStringLiteral("[preview] importPath += %1").arg(generatedDir));
        }
    }
    m_previewWidget->setSource(QUrl());
    m_previewWidget->setSource(QUrl::fromLocalFile(previewInfo.absoluteFilePath()));
    appendLog(QStringLiteral("[preview] loaded %1").arg(previewInfo.absoluteFilePath()));
}
