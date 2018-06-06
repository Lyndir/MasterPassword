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

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableSet;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.util.List;
import java.util.Locale;
import javax.annotation.Nullable;
import org.jetbrains.annotations.Contract;


/**
 * <i>07 04, 2012</i>
 *
 * @author lhunath
 */
@SuppressWarnings({ "RedundantTypeArguments", "SpellCheckingInspection" })
public enum MPResultType {
    // bit 0-3 | MPResultTypeClass | MPSiteFeature

    /**
     * 16: pg^VMAUBk5x3p%HP%i4=
     */
    GeneratedMaximum( "maximum", "20 characters, contains symbols.", //
                      ImmutableList.of( new MPTemplate( "anoxxxxxxxxxxxxxxxxx" ),
                                        new MPTemplate( "axxxxxxxxxxxxxxxxxno" ) ), //
                      MPResultTypeClass.Template, 0x0 ),

    /**
     * 17: BiroYena8:Kixa
     */
    GeneratedLong( "long", "Copy-friendly, 14 characters, contains symbols.", //
                   ImmutableList.of( new MPTemplate( "CvcvnoCvcvCvcv" ), new MPTemplate( "CvcvCvcvnoCvcv" ),
                                     new MPTemplate( "CvcvCvcvCvcvno" ), new MPTemplate( "CvccnoCvcvCvcv" ),
                                     new MPTemplate( "CvccCvcvnoCvcv" ), new MPTemplate( "CvccCvcvCvcvno" ),
                                     new MPTemplate( "CvcvnoCvccCvcv" ), new MPTemplate( "CvcvCvccnoCvcv" ),
                                     new MPTemplate( "CvcvCvccCvcvno" ), new MPTemplate( "CvcvnoCvcvCvcc" ),
                                     new MPTemplate( "CvcvCvcvnoCvcc" ), new MPTemplate( "CvcvCvcvCvccno" ),
                                     new MPTemplate( "CvccnoCvccCvcv" ), new MPTemplate( "CvccCvccnoCvcv" ),
                                     new MPTemplate( "CvccCvccCvcvno" ), new MPTemplate( "CvcvnoCvccCvcc" ),
                                     new MPTemplate( "CvcvCvccnoCvcc" ), new MPTemplate( "CvcvCvccCvccno" ),
                                     new MPTemplate( "CvccnoCvcvCvcc" ), new MPTemplate( "CvccCvcvnoCvcc" ),
                                     new MPTemplate( "CvccCvcvCvccno" ) ), //
                   MPResultTypeClass.Template, 0x1 ),

    /**
     * 18: BirSuj0-
     */
    GeneratedMedium( "medium", "Copy-friendly, 8 characters, contains symbols.", //
                     ImmutableList.of( new MPTemplate( "CvcnoCvc" ),
                                       new MPTemplate( "CvcCvcno" ) ), //
                     MPResultTypeClass.Template, 0x2 ),

    /**
     * 19: Bir8
     */
    GeneratedShort( "short", "Copy-friendly, 4 characters, no symbols.", //
                    ImmutableList.of( new MPTemplate( "Cvcn" ) ), //
                    MPResultTypeClass.Template, 0x3 ),

    /**
     * 20: pO98MoD0
     */
    GeneratedBasic( "basic", "8 characters, no symbols.", //
                    ImmutableList.of( new MPTemplate( "aaanaaan" ),
                                      new MPTemplate( "aannaaan" ),
                                      new MPTemplate( "aaannaaa" ) ), //
                    MPResultTypeClass.Template, 0x4 ),

    /**
     * 21: 2798
     */
    GeneratedPIN( "pin", "4 numbers.", //
                  ImmutableList.of( new MPTemplate( "nnnn" ) ), //
                  MPResultTypeClass.Template, 0x5 ),

    /**
     * 30: birsujano
     */
    GeneratedName( "name", "9 letter name.", //
                   ImmutableList.of( new MPTemplate( "cvccvcvcv" ) ), //
                   MPResultTypeClass.Template, 0xE ),

    /**
     * 31: bir yennoquce fefi
     */
    GeneratedPhrase( "phrase", "20 character sentence.", //
                     ImmutableList.of( new MPTemplate( "cvcc cvc cvccvcv cvc" ),
                                       new MPTemplate( "cvc cvccvcvcv cvcv" ),
                                       new MPTemplate( "cv cvccv cvc cvcvccv" ) ), //
                     MPResultTypeClass.Template, 0xF ),

    /**
     * 1056: Custom saved password.
     */
    StoredPersonal( "personal", "AES-encrypted, exportable.", //
                    ImmutableList.<MPTemplate>of(), //
                    MPResultTypeClass.Stateful, 0x0, MPSiteFeature.ExportContent ),

    /**
     * 2081: Custom saved password that should not be exported from the device.
     */
    StoredDevicePrivate( "device", "AES-encrypted, not exported.", //
                         ImmutableList.<MPTemplate>of(), //
                         MPResultTypeClass.Stateful, 0x1, MPSiteFeature.DevicePrivate ),

    /**
     * 4160: Derive a unique binary key.
     */
    DeriveKey( "key", "Encryption key.", //
               ImmutableList.<MPTemplate>of(), //
               MPResultTypeClass.Derive, 0x0, MPSiteFeature.Alternative );

    static final Logger logger = Logger.get( MPResultType.class );

    private final String                      shortName;
    private final String                      description;
    private final List<MPTemplate>            templates;
    private final MPResultTypeClass           typeClass;
    private final int                         typeIndex;
    private final ImmutableSet<MPSiteFeature> typeFeatures;

    MPResultType(final String shortName, final String description, final List<MPTemplate> templates,
                 final MPResultTypeClass typeClass, final int typeIndex, final MPSiteFeature... typeFeatures) {

        this.shortName = shortName;
        this.description = description;
        this.templates = templates;
        this.typeClass = typeClass;
        this.typeIndex = typeIndex;

        ImmutableSet.Builder<MPSiteFeature> typeFeaturesBuilder = ImmutableSet.builder();
        for (final MPSiteFeature typeFeature : typeFeatures) {
            typeFeaturesBuilder.add( typeFeature );
        }
        this.typeFeatures = typeFeaturesBuilder.build();
    }

    public String getShortName() {
        return shortName;
    }

    public String getDescription() {

        return description;
    }

    public MPResultTypeClass getTypeClass() {

        return typeClass;
    }

    @SuppressWarnings("AssignmentOrReturnOfFieldWithMutableType" /* IDEA-191042 */)
    public ImmutableSet<MPSiteFeature> getTypeFeatures() {

        return typeFeatures;
    }

    public boolean supportsTypeFeature(final MPSiteFeature feature) {

        return typeFeatures.contains( feature );
    }

    @JsonValue
    public int getType() {
        int mask = typeIndex | typeClass.getMask();
        for (final MPSiteFeature typeFeature : typeFeatures)
            mask |= typeFeature.getMask();

        return mask;
    }

    /**
     * @param shortNamePrefix The name for the type to look up.  It is a case insensitive prefix of the type's short name.
     *
     * @return The type registered with the given name.
     */
    @Nullable
    @Contract("!null -> !null")
    public static MPResultType forName(@Nullable final String shortNamePrefix) {

        if (shortNamePrefix == null)
            return null;

        for (final MPResultType type : values())
            if (type.getShortName().toLowerCase( Locale.ROOT ).startsWith( shortNamePrefix.toLowerCase( Locale.ROOT ) ))
                return type;

        throw logger.bug( "No type for name: %s", shortNamePrefix );
    }

    /**
     * @param typeClass The class for which we look up types.
     *
     * @return All types that support the given class.
     */
    public static ImmutableList<MPResultType> forClass(final MPResultTypeClass typeClass) {

        ImmutableList.Builder<MPResultType> types = ImmutableList.builder();
        for (final MPResultType type : values())
            if (type.getTypeClass() == typeClass)
                types.add( type );

        return types.build();
    }

    /**
     * @param type The type for which we look up types.
     *
     * @return The type registered with the given type.
     */
    @JsonCreator
    public static MPResultType forType(final int type) {

        for (final MPResultType resultType : values())
            if (resultType.getType() == type)
                return resultType;

        throw logger.bug( "No type: %s", type );
    }

    /**
     * @param mask The type mask for which we look up types.
     *
     * @return All types that support the given mask's class & features.
     */
    @SuppressWarnings({ "MagicNumber", "UnnecessaryParentheses" /* IDEA-191040 */ })
    public static ImmutableList<MPResultType> forMask(final int mask) {

        int typeMask = mask & ~0xF; // Ignore resultType bit 0-3

        ImmutableList.Builder<MPResultType> types = ImmutableList.builder();
        for (final MPResultType resultType : values())
            if (((resultType.getType() & ~0xF) & typeMask) != 0)
                types.add( resultType );

        return types.build();
    }

    public MPTemplate getTemplateAtRollingIndex(final int templateIndex) {
        return templates.get( templateIndex % templates.size() );
    }
}
