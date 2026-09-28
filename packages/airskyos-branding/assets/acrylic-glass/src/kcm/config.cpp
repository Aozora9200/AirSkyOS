/*
    SPDX-FileCopyrightText: 2010 Fredrik Höglund <fredrik@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
#include "config.h"
#include "glassconfig.h"

#include "kwineffects_interface.h"
#include <KPluginFactory>

namespace KWin {

K_PLUGIN_CLASS(AozoraGlassEffectConfig)

AozoraGlassEffectConfig::AozoraGlassEffectConfig(QObject* parent, const KPluginMetaData& data)
    : KCModule(parent, data)
{
    ui.setupUi(widget());
    BlurConfig::instance("kwinrc");
    addConfig(BlurConfig::self(), widget());

    // Keep the filtering mode deterministic even if older configs had both unset.
    if (!ui.kcfg_BlurMatching->isChecked() && !ui.kcfg_BlurNonMatching->isChecked()) {
        ui.kcfg_BlurNonMatching->setChecked(true);
    }
}

AozoraGlassEffectConfig::~AozoraGlassEffectConfig() { }

void AozoraGlassEffectConfig::save()
{
    KCModule::save();

    OrgKdeKwinEffectsInterface interface(QStringLiteral("org.kde.KWin"), QStringLiteral("/Effects"), QDBusConnection::sessionBus());

    if (QGuiApplication::platformName() == QStringLiteral("xcb")) {
        interface.reconfigureEffect(QStringLiteral("aozoraglass_x11"));
    } else {
        interface.reconfigureEffect(QStringLiteral("aozoraglass"));
    }
}

} // namespace KWin

#include "config.moc"
#include "moc_config.cpp"
