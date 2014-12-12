package com.lyndir.masterpassword.gui;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.ifNotNullElse;
import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.base.Throwables;
import com.google.common.io.Resources;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.awt.*;
import java.awt.image.ImageObserver;
import java.io.IOException;
import java.net.URL;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.swing.*;


/**
 * @author lhunath, 2014-06-11
 */
public abstract class Res {

    private static final ExecutorService executor = Executors.newSingleThreadExecutor();
    private static final Logger          logger   = Logger.get( Res.class );

    private static Font sourceCodeProBlack;
    private static Font exoBold;
    private static Font exoExtraBold;
    private static Font exoRegular;
    private static Font exoThin;

    public static void execute(final Runnable job) {
        executor.submit( new Runnable() {
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

    public static Font sourceCodeProBlack() {
        try {
            URL resource = Resources.getResource( "fonts/SourceCodePro-Bold.otf" );
            Font font = Font.createFont( Font.TRUETYPE_FONT, resource.openStream() );
            return sourceCodeProBlack != null? sourceCodeProBlack: //
                    (sourceCodeProBlack = font);
        }
        catch (FontFormatException | IOException e) {
            throw Throwables.propagate( e );
        }
    }

    public static Font exoBold() {
        try {
            URL resource = Resources.getResource( "fonts/Exo2.0-Bold.otf" );
            Font font = Font.createFont( Font.TRUETYPE_FONT, resource.openStream() );
            return exoBold != null? exoBold: //
                    (exoBold = font);
        }
        catch (FontFormatException | IOException e) {
            throw Throwables.propagate( e );
        }
    }

    public static Font exoExtraBold() {
        try {
            URL resource = Resources.getResource( "fonts/Exo2.0-ExtraBold.otf" );
            Font font = Font.createFont( Font.TRUETYPE_FONT, resource.openStream() );
            return exoExtraBold != null? exoExtraBold: //
                    (exoExtraBold = font);
        }
        catch (FontFormatException | IOException e) {
            throw Throwables.propagate( e );
        }
    }

    public static Font exoRegular() {
        try {
            URL resource = Resources.getResource( "fonts/Exo2.0-Regular.otf" );
            Font font = Font.createFont( Font.TRUETYPE_FONT, resource.openStream() );
            return exoRegular != null? exoRegular: //
                    (exoRegular = font);
        }
        catch (FontFormatException | IOException e) {
            throw Throwables.propagate( e );
        }
    }

    public static Font exoThin() {
        try {
            URL resource = Resources.getResource( "fonts/Exo2.0-Thin.otf" );
            Font font = Font.createFont( Font.TRUETYPE_FONT, resource.openStream() );
            return exoThin != null? exoThin: //
                    (exoThin = font);
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
