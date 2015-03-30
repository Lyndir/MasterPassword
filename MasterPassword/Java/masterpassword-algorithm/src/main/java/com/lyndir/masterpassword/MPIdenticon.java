package com.lyndir.masterpassword;

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import com.google.common.collect.ImmutableMap;
import com.lyndir.lhunath.opal.system.MessageAuthenticationDigests;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.awt.*;
import java.nio.*;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Map;


/**
 * @author lhunath, 15-03-29
 */
public class MPIdenticon {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MPIdenticon.class );

    private static final Charset charset = StandardCharsets.UTF_8;
    private static final Color[] colors  = new Color[]{
            Color.RED, Color.GREEN, Color.YELLOW, Color.BLUE, Color.MAGENTA, Color.CYAN, Color.MONO };
    private static final char[] leftArm   = new char[]{ '╔', '╚', '╰', '═' };
    private static final char[] rightArm  = new char[]{ '╗', '╝', '╯', '═' };
    private static final char[] body      = new char[]{ '█', '░', '▒', '▓', '☺', '☻' };
    private static final char[] accessory = new char[]{
            '◈', '◎', '◐', '◑', '◒', '◓', '☀', '☁', '☂', '☃', '☄', '★', '☆', '☎', '☏', '⎈', '⌂', '☘', '☢', '☣', '☕', '⌚', '⌛', '⏰', '⚡',
            '⛄', '⛅', '☔', '♔', '♕', '♖', '♗', '♘', '♙', '♚', '♛', '♜', '♝', '♞', '♟', '♨', '♩', '♪', '♫', '⚐', '⚑', '⚔', '⚖', '⚙', '⚠',
            '⌘', '⏎', '✄', '✆', '✈', '✉', '✌' };

    private final String         fullName;
    private final Color          color;
    private final String         text;

    public MPIdenticon(String fullName, String masterPassword) {
        this( fullName, masterPassword.toCharArray() );
    }

    public MPIdenticon(String fullName, char[] masterPassword) {
        this.fullName = fullName;

        byte[] masterPasswordBytes = charset.encode( CharBuffer.wrap( masterPassword ) ).array();
        ByteBuffer identiconSeedBytes = ByteBuffer.wrap(
                MessageAuthenticationDigests.HmacSHA256.of( masterPasswordBytes, fullName.getBytes( charset ) ) );
        Arrays.fill( masterPasswordBytes, (byte) 0 );

        IntBuffer identiconSeedBuffer = IntBuffer.allocate( identiconSeedBytes.capacity() );
        while (identiconSeedBytes.hasRemaining())
            identiconSeedBuffer.put( identiconSeedBytes.get() & 0xFF );
        int[] identiconSeed = identiconSeedBuffer.array();

        color = colors[identiconSeed[4] % colors.length];
        text = strf( "%c%c%c%c", leftArm[identiconSeed[0] % leftArm.length], body[identiconSeed[1] % body.length],
                     rightArm[identiconSeed[2] % rightArm.length], accessory[identiconSeed[3] % accessory.length] );
    }

    public String getFullName() {
        return fullName;
    }

    public String getText() {
        return text;
    }

    public Color getColor() {
        return color;
    }

    public enum BackgroundMode {
        DARK, LIGHT
    }


    public enum Color {
        RED( "#dc322f", "#dc322f" ),
        GREEN( "#859900", "#859900" ),
        YELLOW( "#b58900", "#b58900" ),
        BLUE( "#268bd2", "#268bd2" ),
        MAGENTA( "#d33682", "#d33682" ),
        CYAN( "#2aa198", "#2aa198" ),
        MONO( "#93a1a1", "#586e75" );

        private final String rgbDark;
        private final String rgbLight;

        Color(final String rgbDark, final String rgbLight) {
            this.rgbDark = rgbDark;
            this.rgbLight = rgbLight;
        }

        public java.awt.Color getAWTColor(BackgroundMode backgroundMode) {
            switch (backgroundMode) {
                case DARK:
                    return new java.awt.Color( Integer.decode( rgbDark ) );
                case LIGHT:
                    return new java.awt.Color( Integer.decode( rgbLight ) );
            }

            throw new UnsupportedOperationException( "Unsupported background mode: " + backgroundMode );
        }
    }
}
