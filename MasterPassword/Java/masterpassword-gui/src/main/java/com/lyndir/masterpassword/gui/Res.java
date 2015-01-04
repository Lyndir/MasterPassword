package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.ifNotNullElse;
import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.base.Throwables;
import com.google.common.io.Resources;
import com.google.common.util.concurrent.*;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.awt.*;
import java.awt.event.*;
import java.awt.image.ImageObserver;
import java.io.IOException;
import java.net.URL;
import java.util.WeakHashMap;
import java.util.concurrent.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.swing.*;


/**
 * @author lhunath, 2014-06-11
 */
public abstract class Res {

    private static final WeakHashMap<Window, ExecutorService> executorByWindow = new WeakHashMap<>();
    private static final Logger                               logger           = Logger.get( Res.class );

    private static Font sourceCodeProRegular;
    private static Font sourceCodeProBlack;
    private static Font exoBold;
    private static Font exoExtraBold;
    private static Font exoRegular;
    private static Font exoThin;

    public static Future<?> execute(final Window host, final Runnable job) {
        return getExecutor( host ).submit( new Runnable() {
            @Override
            public void run() {
                try {
                    job.run();
                }
                catch (Throwable t) {
                    logger.err( t, "Unexpected: %s", t.getLocalizedMessage() );
                }
            }
        } );
    }

    public static <V> ListenableFuture<V> execute(final Window host, final Callable<V> job) {
        ExecutorService executor = getExecutor( host );
        return JdkFutureAdapters.listenInPoolThread( executor.submit( new Callable<V>() {
            @Override
            public V call()
                    throws Exception {
                try {
                    return job.call();
                }
                catch (Throwable t) {
                    logger.err( t, "Unexpected: %s", t.getLocalizedMessage() );
                    throw t;
                }
            }
        } ), executor );
    }

    private static ExecutorService getExecutor(final Window host) {
        ExecutorService executor = executorByWindow.get( host );

        if (executor == null) {
            executorByWindow.put( host, executor = Executors.newSingleThreadExecutor() );

            host.addWindowListener( new WindowAdapter() {
                @Override
                public void windowClosed(final WindowEvent e) {
                    ExecutorService executor = executorByWindow.remove( host );
                    if (executor != null)
                        executor.shutdownNow();
                }
            } );
        }

        return executor;
    }

    public static Icon iconAdd() {
        return new RetinaIcon( Resources.getResource( "media/icon_add@2x.png" ) );
    }

    public static Icon iconQuestion() {
        return new RetinaIcon( Resources.getResource( "media/icon_question@2x.png" ) );
    }

    public static Icon avatar(final int index) {
        return new RetinaIcon( Resources.getResource( strf( "media/avatar-%d@2x.png", index % avatars() ) ) );
    }

    public static int avatars() {
        return 19;
    }

    public static Font sourceCodeProRegular() {
        try {
            return sourceCodeProRegular != null? sourceCodeProRegular: (sourceCodeProRegular =
                    Font.createFont( Font.TRUETYPE_FONT, Resources.getResource( "fonts/SourceCodePro-Regular.otf" ).openStream() ));
        }
        catch (FontFormatException | IOException e) {
            throw Throwables.propagate( e );
        }
    }

    public static Font sourceCodeProBlack() {
        try {
            return sourceCodeProBlack != null? sourceCodeProBlack: (sourceCodeProBlack =
                    Font.createFont( Font.TRUETYPE_FONT, Resources.getResource( "fonts/SourceCodePro-Bold.otf" ).openStream() ));
        }
        catch (FontFormatException | IOException e) {
            throw Throwables.propagate( e );
        }
    }

    public static Font exoBold() {
        try {
            return exoBold != null? exoBold: (exoBold =
                    Font.createFont( Font.TRUETYPE_FONT, Resources.getResource( "fonts/Exo2.0-Bold.otf" ).openStream() ));
        }
        catch (FontFormatException | IOException e) {
            throw Throwables.propagate( e );
        }
    }

    public static Font exoExtraBold() {
        try {
            return exoExtraBold != null? exoExtraBold: (exoExtraBold
                    = Font.createFont( Font.TRUETYPE_FONT, Resources.getResource( "fonts/Exo2.0-ExtraBold.otf" ).openStream() ));
        }
        catch (FontFormatException | IOException e) {
            throw Throwables.propagate( e );
        }
    }

    public static Font exoRegular() {
        try {
            return exoRegular != null? exoRegular: (exoRegular =
                    Font.createFont( Font.TRUETYPE_FONT, Resources.getResource( "fonts/Exo2.0-Regular.otf" ).openStream() ));
        }
        catch (FontFormatException | IOException e) {
            throw Throwables.propagate( e );
        }
    }

    public static Font exoThin() {
        try {
            return exoThin != null? exoThin: (exoThin =
                    Font.createFont( Font.TRUETYPE_FONT, Resources.getResource( "fonts/Exo2.0-Thin.otf" ).openStream() ));
        }
        catch (FontFormatException | IOException e) {
            throw Throwables.propagate( e );
        }
    }

    private static final class RetinaIcon extends ImageIcon {

        private static final Pattern scalePattern = Pattern.compile( ".*@(\\d+)x.[^.]+$" );

        private final float scale;

        public RetinaIcon(final URL url) {
            super( url );

            Matcher scaleMatcher = scalePattern.matcher( url.getPath() );
            if (scaleMatcher.matches())
                scale = Float.parseFloat( scaleMatcher.group( 1 ) );
            else
                scale = 1;
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

        public synchronized void paintIcon(Component c, Graphics g, int x, int y) {
            ImageObserver observer = ifNotNullElse( getImageObserver(), c );

            Image image = getImage();
            int width = image.getWidth( observer );
            int height = image.getHeight( observer );
            final Graphics2D g2d = (Graphics2D) g.create( x, y, width, height );

            g2d.scale( 1 / scale, 1 / scale );
            g2d.drawImage( image, 0, 0, observer );
            g2d.scale( 1, 1 );
            g2d.dispose();
        }
    }
}
