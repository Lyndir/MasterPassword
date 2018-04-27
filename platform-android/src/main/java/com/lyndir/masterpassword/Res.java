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

package com.lyndir.masterpassword;

import android.content.Context;
import android.graphics.Typeface;


/**
 * @author lhunath, 2014-08-25
 */
@SuppressWarnings("NewMethodNamingConvention")
public final class Res {

    private final Typeface sourceCodePro_Black;
    private final Typeface sourceCodePro_ExtraLight;
    private final Typeface exo_Bold;
    private final Typeface exo_ExtraBold;
    private final Typeface exo_Regular;
    private final Typeface exo_Thin;

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

    public Typeface sourceCodePro_Black() {
        return sourceCodePro_Black;
    }

    public Typeface sourceCodePro_ExtraLight() {
        return sourceCodePro_ExtraLight;
    }

    public Typeface exo_Bold() {
        return exo_Bold;
    }

    public Typeface exo_ExtraBold() {
        return exo_ExtraBold;
    }

    public Typeface exo_Regular() {
        return exo_Regular;
    }

    public Typeface exo_Thin() {
        return exo_Thin;
    }
}
