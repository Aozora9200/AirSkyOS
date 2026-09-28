/*
    SPDX-FileCopyrightText: 2010 Fredrik Höglund <fredrik@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include "ui_config.h"
#include <KCModule>
#include <QWidget>

namespace KWin {

class AozoraGlassEffectConfig : public KCModule
{
    Q_OBJECT

public:
    explicit AozoraGlassEffectConfig(QObject* parent, const KPluginMetaData& data);
    ~AozoraGlassEffectConfig() override;

    void save() override;

private:
    ::Ui::GlassEffectConfig ui;
};

} // namespace KWin
