package com.lyndir.masterpassword.gui.util;

import com.lyndir.masterpassword.MPIdenticon.Color;

import java.util.HashMap;
import java.util.Map;

/**
 * @author deekay, 2015-04-30
 */
public class MPIdenticonColorUtil {

    private static Map<Color, BackgroundModeAwareColorCode> colors;

    static {
        colors = new HashMap<>();
        colors.put(Color.RED, new BackgroundModeAwareColorCode("#dc322f", "#dc322f"));
        colors.put(Color.GREEN, new BackgroundModeAwareColorCode("#859900", "#859900"));
        colors.put(Color.YELLOW, new BackgroundModeAwareColorCode("#b58900", "#b58900"));
        colors.put(Color.BLUE, new BackgroundModeAwareColorCode("#268bd2", "#268bd2"));
        colors.put(Color.MAGENTA, new BackgroundModeAwareColorCode("#d33682", "#d33682"));
        colors.put(Color.CYAN, new BackgroundModeAwareColorCode("#2aa198", "#2aa198"));
        colors.put(Color.MONO, new BackgroundModeAwareColorCode("#93a1a1", "#586e75"));
    }

    public static BackgroundModeAwareColorCode fromMPIdenticonColor(Color color) {
        return colors.get(color);
    }

    public enum BackgroundMode {
        DARK, LIGHT
    }

    public static class BackgroundModeAwareColorCode {
        private final String rgbDark;
        private final String rgbLight;

        BackgroundModeAwareColorCode(final String rgbDark, final String rgbLight) {
            this.rgbDark = rgbDark;
            this.rgbLight = rgbLight;
        }

        public java.awt.Color getAWTColor(BackgroundMode backgroundMode) {
            switch (backgroundMode) {
                case DARK:
                    return new java.awt.Color(Integer.decode(rgbDark));
                case LIGHT:
                    return new java.awt.Color(Integer.decode(rgbLight));
            }

            throw new UnsupportedOperationException("Unsupported background mode: " + backgroundMode);
        }
    }


}
