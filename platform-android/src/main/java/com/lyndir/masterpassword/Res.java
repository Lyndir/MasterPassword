package com.lyndir.masterpassword;

import android.content.Context;
import android.content.res.Resources;
import android.graphics.Typeface;


/**
 * @author lhunath, 2014-08-25
 */
public final class Res {

    public final Typeface sourceCodePro_Black;
    public final Typeface sourceCodePro_ExtraLight;
    public final Typeface exo_Bold;
    public final Typeface exo_ExtraBold;
    public final Typeface exo_Regular;
    public final Typeface exo_Thin;

    private static Res res;

    public static synchronized Res get(final Context context) {
        if (res == null)
            res = new Res( context );

        return res;
    }

    @SuppressWarnings("HardCodedStringLiteral")
    private Res(final Context context) {

        sourceCodePro_Black = Typeface.createFromAsset( context.getResources().getAssets(), "SourceCodePro-Black.otf" );
        sourceCodePro_ExtraLight = Typeface.createFromAsset( context.getResources().getAssets(), "SourceCodePro-ExtraLight.otf" );
        exo_Bold = Typeface.createFromAsset( context.getResources().getAssets(), "Exo2.0-Bold.otf" );
        exo_ExtraBold = Typeface.createFromAsset( context.getResources().getAssets(), "Exo2.0-ExtraBold.otf" );
        exo_Regular = Typeface.createFromAsset( context.getResources().getAssets(), "Exo2.0-Regular.otf" );
        exo_Thin = Typeface.createFromAsset( context.getResources().getAssets(), "Exo2.0-Thin.otf" );
    }
}
