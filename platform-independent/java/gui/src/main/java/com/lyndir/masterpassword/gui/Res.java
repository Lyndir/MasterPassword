//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;
import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.collect.Maps;
import com.google.common.io.Resources;
import com.google.common.util.concurrent.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.MPIdenticon;
import java.awt.*;
import java.awt.image.ImageObserver;
import java.io.IOException;
import java.lang.ref.SoftReference;
import java.net.URL;
import java.util.Map;
import java.util.concurrent.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.swing.*;
import org.jetbrains.annotations.NonNls;


/**
 * @author lhunath, 2014-06-11
 */
@SuppressWarnings({ "HardcodedFileSeparator", "MethodReturnAlwaysConstant", "SpellCheckingInspection" })
public abstract class Res {

    private static final int                               AVATAR_COUNT        = 19;
    private static final ListeningScheduledExecutorService jobExecutor         = MoreExecutors.listeningDecorator(
            Executors.newSingleThreadScheduledExecutor() );
    private static final Executor                          immediateUiExecutor = new SwingExecutorService( true );
    private static final Executor                          laterUiExecutor     = new SwingExecutorService( false );
    private static final Logger                            logger              = Logger.get( Res.class );
    private static final Fonts                             fonts               = new Fonts();
    private static final Colors                            colors              = new Colors();

    public static Future<?> job(final Runnable job) {
        return job( job, 0, TimeUnit.MILLISECONDS );
    }

    public static Future<?> job(final Runnable job, final long delay, final TimeUnit timeUnit) {
        return jobExecutor.schedule( () -> {
            try {
                job.run();
            }
            catch (final Throwable t) {
                logger.err( t, "Unexpected: %s", t.getLocalizedMessage() );
            }
        }, delay, timeUnit );
    }

    public static <V> ListenableFuture<V> job(final Callable<V> job) {
        return job( job, 0, TimeUnit.MILLISECONDS );
    }

    public static <V> ListenableFuture<V> job(final Callable<V> job, final long delay, final TimeUnit timeUnit) {
        return jobExecutor.schedule( job, delay, timeUnit );
    }

    public static void ui(final Runnable job) {
        ui( true, job );
    }

    public static void ui(final boolean immediate, final Runnable job) {
        uiExecutor( immediate ).execute( job );
    }

    public static Executor uiExecutor() {
        return uiExecutor( true );
    }

    public static Executor uiExecutor(final boolean immediate) {
        return immediate? immediateUiExecutor: laterUiExecutor;
    }

    public static Icon iconAdd() {
        return new RetinaIcon( Resources.getResource( "media/icon_add@2x.png" ) );
    }

    public static Icon iconDelete() {
        return new RetinaIcon( Resources.getResource( "media/icon_delete@2x.png" ) );
    }

    public static Icon iconQuestion() {
        return new RetinaIcon( Resources.getResource( "media/icon_question@2x.png" ) );
    }

    public static Icon avatar(final int index) {
        return new RetinaIcon( Resources.getResource( strf( "media/avatar-%d@2x.png", index % avatars() ) ) );
    }

    public static int avatars() {
        return AVATAR_COUNT;
    }

    public static Fonts fonts() {
        return fonts;
    }

    public static Colors colors() {
        return colors;
    }

    private static final class RetinaIcon extends ImageIcon {

        private static final Pattern scalePattern     = Pattern.compile( ".*@(\\d+)x.[^.]+$" );
        private static final long    serialVersionUID = 1L;

        private final float scale;

        private RetinaIcon(final URL url) {
            super( url );

            Matcher scaleMatcher = scalePattern.matcher( url.getPath() );
            scale = scaleMatcher.matches()? Float.parseFloat( scaleMatcher.group( 1 ) ): 1;
        }

        //private static URL retinaURL(final URL url) {
        //    try {
        //        final boolean[] isRetina = new boolean[1];
        //        new apple.awt.CImage.HiDPIScaledImage(1,1, BufferedImage.TYPE_INT_ARGB) {
        //            @Override
        //            public void drawIntoImage(BufferedImage image, float v) {
        //                isRetina[0] = v > 1;
        //            }
        //        };
        //        return isRetina[0];
        //    } catch (Throwable e) {
        //        e.printStackTrace();
        //        return url;
        //    }
        //}

        @Override
        public int getIconWidth() {
            return (int) (super.getIconWidth() / scale);
        }

        @Override
        public int getIconHeight() {
            return (int) (super.getIconHeight() / scale);
        }

        @Override
        public synchronized void paintIcon(final Component c, final Graphics g, final int x, final int y) {
            ImageObserver observer = ifNotNullElse( getImageObserver(), c );

            Image      image  = getImage();
            int        width  = image.getWidth( observer );
            int        height = image.getHeight( observer );
            Graphics2D g2d    = (Graphics2D) g.create( x, y, width, height );

            g2d.scale( 1 / scale, 1 / scale );
            g2d.drawImage( image, 0, 0, observer );
            g2d.scale( 1, 1 );
            g2d.dispose();
        }
    }


    public static class Fonts {

        public Font emoticonsFont(final float size) {
            return emoticonsRegular().deriveFont( size );
        }

        public Font controlFont(final float size) {
            return exoRegular().deriveFont( size );
        }

        public Font valueFont(final float size) {
            return sourceSansProRegular().deriveFont( size );
        }

        public Font bigValueFont(final float size) {
            return sourceSansProBlack().deriveFont( size );
        }

        public Font emoticonsRegular() {
            return font( "fonts/Emoticons-Regular.otf" );
        }

        public Font sourceCodeProRegular() {
            return font( "fonts/SourceCodePro-Regular.otf" );
        }

        public Font sourceCodeProBlack() {
            return font( "fonts/SourceCodePro-Bold.otf" );
        }

        public Font sourceSansProRegular() {
            return font( "fonts/SourceSansPro-Regular.otf" );
        }

        public Font sourceSansProBlack() {
            return font( "fonts/SourceSansPro-Bold.otf" );
        }

        public Font exoBold() {
            return font( "fonts/Exo2.0-Bold.otf" );
        }

        public Font exoExtraBold() {
            return font( "fonts/Exo2.0-ExtraBold.otf" );
        }

        public Font exoRegular() {
            return font( "fonts/Exo2.0-Regular.otf" );
        }

        public Font exoThin() {
            return font( "fonts/Exo2.0-Thin.otf" );
        }

        public Font arimoBold() {
            return font( "fonts/Arimo-Bold.ttf" );
        }

        public Font arimoBoldItalic() {
            return font( "fonts/Arimo-BoldItalic.ttf" );
        }

        public Font arimoItalic() {
            return font( "fonts/Arimo-Italic.ttf" );
        }

        public Font arimoRegular() {
            return font( "fonts/Arimo-Regular.ttf" );
        }

        private static Font font(@NonNls final String fontResourceName) {
            Map<String, SoftReference<Font>> fontsByResourceName = Maps.newHashMap();
            SoftReference<Font>              fontRef             = fontsByResourceName.get( fontResourceName );
            Font                             font                = (fontRef == null)? null: fontRef.get();
            if (font == null)
                try {
                    fontsByResourceName.put( fontResourceName, new SoftReference<>(
                            font = Font.createFont( Font.TRUETYPE_FONT, Resources.getResource( fontResourceName ).openStream() ) ) );
                }
                catch (final FontFormatException | IOException e) {
                    throw logger.bug( e );
                }

            return font;
        }
    }


    public static class Colors {

        private final Color transparent   = new Color( 0, 0, 0, 0 );
        private final Color frameBg       = Color.decode( "#5A5D6B" );
        private final Color controlBg     = SystemColor.window;
        private final Color controlBorder = Color.decode( "#BFBFBF" );
        private final Color highlightFg   = SystemColor.controlHighlight;
        private final Color errorFg       = Color.decode( "#FF3333" );

        public Color transparent() {
            return transparent;
        }

        public Color frameBg() {
            return frameBg;
        }

        public Color controlBg() {
            return controlBg;
        }

        public Color controlBorder() {
            return controlBorder;
        }

        public Color highlightFg() {
            return highlightFg;
        }

        public Color errorFg() {
            return errorFg;
        }

        public Color fromIdenticonColor(final MPIdenticon.Color identiconColor, final BackgroundMode backgroundMode) {
            switch (identiconColor) {
                case RED:
                    switch (backgroundMode) {
                        case DARK:
                            return Color.decode( "#dc322f" );
                        case LIGHT:
                            return Color.decode( "#dc322f" );
                    }
                    break;
                case GREEN:
                    switch (backgroundMode) {
                        case DARK:
                            return Color.decode( "#859900" );
                        case LIGHT:
                            return Color.decode( "#859900" );
                    }
                    break;
                case YELLOW:
                    switch (backgroundMode) {
                        case DARK:
                            return Color.decode( "#b58900" );
                        case LIGHT:
                            return Color.decode( "#b58900" );
                    }
                    break;
                case BLUE:
                    switch (backgroundMode) {
                        case DARK:
                            return Color.decode( "#268bd2" );
                        case LIGHT:
                            return Color.decode( "#268bd2" );
                    }
                    break;
                case MAGENTA:
                    switch (backgroundMode) {
                        case DARK:
                            return Color.decode( "#d33682" );
                        case LIGHT:
                            return Color.decode( "#d33682" );
                    }
                    break;
                case CYAN:
                    switch (backgroundMode) {
                        case DARK:
                            return Color.decode( "#2aa198" );
                        case LIGHT:
                            return Color.decode( "#2aa198" );
                    }
                    break;
                case MONO:
                    switch (backgroundMode) {
                        case DARK:
                            return Color.decode( "#93a1a1" );
                        case LIGHT:
                            return Color.decode( "#586e75" );
                    }
                    break;
            }

            throw new IllegalArgumentException( strf( "Color: %s or mode: %s not supported: ", identiconColor, backgroundMode ) );
        }

        public enum BackgroundMode {
            DARK, LIGHT
        }
    }
}
