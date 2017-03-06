package com.lyndir.masterpassword;

import android.content.res.Resources;
import android.graphics.Typeface;


/**
 * @author lhunath, 2014-08-25
 */
public class Res {

    public static Typeface sourceCodePro_Black;
    public static Typeface sourceCodePro_ExtraLight;
    public static Typeface exo_Bold;
    public static Typeface exo_ExtraBold;
    public static Typeface exo_Regular;
    public static Typeface exo_Thin;

    private static boolean initialized;

    public static void init(Resources resources) {

        if (initialized)
            return;
        initialized = true;

        sourceCodePro_Black = Typeface.createFromAsset( resources.getAssets(), "SourceCodePro-Black.otf" );
        sourceCodePro_ExtraLight = Typeface.createFromAsset( resources.getAssets(), "SourceCodePro-ExtraLight.otf" );
        exo_Bold = Typeface.createFromAsset( resources.getAssets(), "Exo2.0-Bold.otf" );
        exo_ExtraBold = Typeface.createFromAsset( resources.getAssets(), "Exo2.0-ExtraBold.otf" );
        exo_Regular = Typeface.createFromAsset( resources.getAssets(), "Exo2.0-Regular.otf" );
        exo_Thin = Typeface.createFromAsset( resources.getAssets(), "Exo2.0-Thin.otf" );
    }
}
