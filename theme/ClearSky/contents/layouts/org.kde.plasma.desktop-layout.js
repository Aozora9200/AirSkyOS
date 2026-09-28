var plasma = getApiVersion(1);

var layout = {
    "desktops": [
        {
            "applets": [
                {
                    "config": {
                    },
                    "geometry.height": 0,
                    "geometry.width": 0,
                    "geometry.x": 0,
                    "geometry.y": 0,
                    "plugin": "org.kde.plasma.brightness",
                    "title": "Brightness & Color"
                },
                {
                    "config": {
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        }
                    },
                    "geometry.height": 0,
                    "geometry.width": 0,
                    "geometry.x": 0,
                    "geometry.y": 0,
                    "plugin": "material.clock",
                    "title": "Material Clock"
                }
            ],
            "config": {
                "/": {
                    "ItemGeometries-1520x1013": "Applet-313:32,112,368,304,0;Applet-312:32,416,368,272,0;",
                    "ItemGeometriesHorizontal": "Applet-313:32,112,368,304,0;Applet-312:32,416,368,272,0;",
                    "formfactor": "0",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                },
                "/ConfigDialog": {
                    "DialogHeight": "630",
                    "DialogWidth": "810"
                },
                "/Wallpaper/org.kde.image/General": {
                    "Image": "file:///usr/share/wallpapers/ClearSky/",
                    "SlidePaths": "/home/galanos/.local/share/wallpapers/,/usr/share/wallpapers/"
                }
            },
            "wallpaperPlugin": "org.kde.image"
        }
    ],
    "panels": [
        {
            "alignment": "center",
            "applets": [
                {
                    "config": {
                        "/": {
                            "popupHeight": "798",
                            "popupWidth": "722"
                        },
                        "/ConfigDialog": {
                            "DialogHeight": "630",
                            "DialogWidth": "810"
                        },
                        "/General": {
                            "alphaSort": "true",
                            "compactMode": "true",
                            "favoritesPortedToKAstats": "true",
                            "icon": "/etc/skel/aozora1.png",
                            "paneSwap": "true",
                            "primaryActions": "3",
                            "showActionButtonCaptions": "false",
                            "systemFavorites": "lock-screen\\,logout\\,save-session\\,switch-user\\,suspend\\,hibernate\\,reboot\\,shutdown"
                        }
                    },
                    "plugin": "org.kde.plasma.kickoff"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.pager"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.marginsseparator"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.kimpanel"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.systemtray"
                },
                {
                    "config": {
                        "/": {
                            "popupHeight": "450",
                            "popupWidth": "525"
                        }
                    },
                    "plugin": "org.kde.plasma.digitalclock"
                },
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.showdesktop"
                }
            ],
            "config": {
                "/": {
                    "formfactor": "3",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                },
                "/Shortcuts": {
                    "global": "Meta+Z"
                }
            },
            "height": 3.5555555555555554,
            "hiding": "dodgewindows",
            "lengthMode": "fit",
            "location": "right",
            "maximumLength": 56.27777777777778,
            "minimumLength": 56.27777777777778,
            "offset": 0,
            "opacity": "translucent"
        },
        {
            "alignment": "center",
            "applets": [
                {
                    "config": {
                        "/General": {
                            "launchers": "applications:chromium.desktop,applications:org.kde.dolphin.desktop,applications:org.kde.konsole.desktop"
                        }
                    },
                    "plugin": "org.kde.plasma.icontasks"
                }
            ],
            "config": {
                "/": {
                    "formfactor": "2",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                },
                "/Shortcuts": {
                    "global": "Meta+X"
                }
            },
            "height": 3.7777777777777777,
            "hiding": "dodgewindows",
            "lengthMode": "fit",
            "location": "top",
            "maximumLength": 84.44444444444444,
            "minimumLength": 84.44444444444444,
            "offset": 0,
            "opacity": "translucent"
        },
        {
            "alignment": "center",
            "applets": [
                {
                    "config": {
                    },
                    "plugin": "org.kde.plasma.appmenu"
                }
            ],
            "config": {
                "/": {
                    "formfactor": "2",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.image"
                },
                "/Shortcuts": {
                    "global": "Meta+M"
                }
            },
            "height": 3.7777777777777777,
            "hiding": "dodgewindows",
            "lengthMode": "fit",
            "location": "bottom",
            "maximumLength": 84.44444444444444,
            "minimumLength": 84.44444444444444,
            "offset": 0,
            "opacity": "translucent"
        }
    ],
    "serializationFormatVersion": "1"
}
;

plasma.loadSerializedLayout(layout);
