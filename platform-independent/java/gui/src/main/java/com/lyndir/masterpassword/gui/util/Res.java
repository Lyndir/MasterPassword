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

package com.lyndir.masterpassword.gui.util;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.io.Resources;
import com.google.common.util.concurrent.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.masterpassword.MPIdenticon;
import edu.umd.cs.findbugs.annotations.SuppressFBWarnings;
import java.awt.*;
import java.io.IOException;
import java.util.concurrent.*;
import java.util.function.Consumer;
import javax.annotation.Nullable;
import javax.swing.*;
import org.jetbrains.annotations.NonNls;
import org.joda.time.*;
import org.joda.time.format.DateTimeFormat;


/**
 * @author lhunath, 2014-06-11
 */
@SuppressWarnings({ "HardcodedFileSeparator", "MethodReturnAlwaysConstant", "SpellCheckingInspection", "serial" })
public abstract class Res {

    private static final int                               AVATAR_COUNT        = 19;
    private static final ListeningScheduledExecutorService jobExecutor         = MoreExecutors.listeningDecorator(
            Executors.newSingleThreadScheduledExecutor() );
    private static final Executor                          immediateUiExecutor = new SwingExecutorService( true );
    private static final Executor                          laterUiExecutor     = new SwingExecutorService( false );
    private static final Logger                            logger              = Logger.get( Res.class );
    private static final Icons                             icons               = new Icons();
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

    public static <V> void ui(final ListenableFuture<V> future, final Consumer<V> job) {
        Futures.addCallback( future, new FailableCallback<V>( logger ) {
            @Override
            public void onSuccess(@Nullable final V result) {
                job.accept( result );
            }
        }, uiExecutor() );
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

    public static Icons icons() {
        return icons;
    }

    public static Fonts fonts() {
        return fonts;
    }

    public static Colors colors() {
        return colors;
    }

    public static String format(final ReadableInstant instant) {
        return DateTimeFormat.mediumDateTime().print( new DateTime( instant, DateTimeZone.getDefault() ) );
    }

    public static final class Icons {

        public Icon add() {
            return icon( "media/icon_add.png" );
        }

        public Icon delete() {
            return icon( "media/icon_delete.png" );
        }

        public Icon question() {
            return icon( "media/icon_question.png" );
        }

        public Icon user() {
            return icon( "media/icon_user.png" );
        }

        public Icon lock() {
            return icon( "media/icon_lock.png" );
        }

        public Icon reset() {
            return icon( "media/icon_reset.png" );
        }

        public Icon import_() {
            return icon( "media/icon_import.png" );
        }

        public Icon help() {
            return icon( "media/icon_help.png" );
        }

        public Icon export() {
            return icon( "media/icon_export.png" );
        }

        public Icon settings() {
            return icon( "media/icon_settings.png" );
        }

        public Icon edit() {
            return icon( "media/icon_edit.png" );
        }

        public Icon key() {
            return icon( "media/icon_key.png" );
        }

        public Icon avatar(final int index) {
            return icon( strf( "media/avatar-%d.png", index % avatars() ) );
        }

        public int avatars() {
            return AVATAR_COUNT;
        }

        private static Icon icon(@NonNls final String resourceName) {
            return new ImageIcon( Toolkit.getDefaultToolkit().getImage( Res.class.getClassLoader().getResource( resourceName ) ) );
        }
    }


    public static final class Fonts {

        public Font identiconFont(final int size) {
            return MPFont.emoticonsRegular.get( size );
        }

        public Font controlFont(final int size) {
            return MPFont.exoRegular.get( size );
        }

        public Font valueFont(final int size) {
            return MPFont.sourceSansProRegular.get( size );
        }

        public Font bigValueFont(final int size) {
            return MPFont.sourceSansProBlack.get( size );
        }

        private enum MPFont {
            emoticonsRegular( "Emoticons", "fonts/Emoticons-Regular.otf" ),
            sourceCodeProRegular( "Source Code Pro", "fonts/SourceCodePro-Regular.otf" ),
            sourceCodeProBlack( "Source Code Pro Bold", "fonts/SourceCodePro-Bold.otf" ),
            sourceSansProRegular( "Source Sans Pro", "fonts/SourceSansPro-Regular.otf" ),
            sourceSansProBlack( "Source Sans Pro Bold", "fonts/SourceSansPro-Bold.otf" ),
            exoBold( "Exo 2.0 Bold", "fonts/Exo2.0-Bold.otf" ),
            exoExtraBold( "Exo 2.0 Extra Bold", "fonts/Exo2.0-ExtraBold.otf" ),
            exoRegular( "Exo 2.0", "fonts/Exo2.0-Regular.otf" ),
            exoThin( "Exo 2.0 Thin", "fonts/Exo2.0-Thin.otf" ),
            arimoBold( "Arimo Bold", "fonts/Arimo-Bold.ttf" ),
            arimoBoldItalic( "Arimo Bold Italic", "fonts/Arimo-BoldItalic.ttf" ),
            arimoItalic( "Arimo Italic", "fonts/Arimo-Italic.ttf" ),
            arimoRegular( "Arimo", "fonts/Arimo-Regular.ttf" );

            private final String  fontName;
            private final String  resourceName;
            private       boolean registered;

            MPFont(final String fontName, final String resourceName) {
                this.fontName = fontName;
                this.resourceName = resourceName;
            }

            Font get(final int size) {
                return get( Font.PLAIN, size );
            }

            synchronized Font get(final int style, final int size) {
                if (!registered)
                    register();

                return new Font( fontName, style, size );
            }

            @SuppressFBWarnings("URLCONNECTION_SSRF_FD")
            private synchronized void register() {
                try {
                    Font font = Font.createFont( Font.TRUETYPE_FONT, Resources.getResource( resourceName ).openStream() );
                    GraphicsEnvironment.getLocalGraphicsEnvironment().registerFont( font );
                    registered = true;
                }
                catch (final FontFormatException | IOException e) {
                    throw logger.bug( e );
                }
            }
        }
    }


    public static final class Colors {

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
