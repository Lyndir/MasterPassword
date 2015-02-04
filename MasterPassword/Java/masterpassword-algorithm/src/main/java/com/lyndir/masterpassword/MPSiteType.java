package com.lyndir.masterpassword;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableSet;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.util.List;
import java.util.Set;
import javax.annotation.Nullable;


/**
 * <i>07 04, 2012</i>
 *
 * @author lhunath
 */
public enum MPSiteType {

    GeneratedMaximum( "20 characters, contains symbols.", //
                      ImmutableList.of( "x", "max", "maximum" ), //
                      ImmutableList.of( new MPTemplate( "anoxxxxxxxxxxxxxxxxx" ), new MPTemplate( "axxxxxxxxxxxxxxxxxno" ) ), //
                      MPSiteTypeClass.Generated, 0x0 ),

    GeneratedLong( "Copy-friendly, 14 characters, contains symbols.", //
                   ImmutableList.of( "l", "long" ),  //
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
                   MPSiteTypeClass.Generated, 0x1 ),

    GeneratedMedium( "Copy-friendly, 8 characters, contains symbols.", //
                     ImmutableList.of( "m", "med", "medium" ), //
                     ImmutableList.of( new MPTemplate( "CvcnoCvc" ), new MPTemplate( "CvcCvcno" ) ), //
                     MPSiteTypeClass.Generated, 0x2 ),

    GeneratedBasic( "8 characters, no symbols.", //
                    ImmutableList.of( "b", "basic" ), //
                    ImmutableList.of( new MPTemplate( "aaanaaan" ), new MPTemplate( "aannaaan" ), new MPTemplate( "aaannaaa" ) ), //
                    MPSiteTypeClass.Generated, 0x3 ),

    GeneratedShort( "Copy-friendly, 4 characters, no symbols.", //
                    ImmutableList.of( "s", "short" ), //
                    ImmutableList.of( new MPTemplate( "Cvcn" ) ), //
                    MPSiteTypeClass.Generated, 0x4 ),

    GeneratedPIN( "4 numbers.", //
                  ImmutableList.of( "i", "pin" ), //
                  ImmutableList.of( new MPTemplate( "nnnn" ) ), //
                  MPSiteTypeClass.Generated, 0x5 ),

    GeneratedName( "9 letter name.", //
                   ImmutableList.of( "n", "name" ), //
                   ImmutableList.of( new MPTemplate( "cvccvcvcv" ) ), //
                   MPSiteTypeClass.Generated, 0xE ),

    GeneratedPhrase( "20 character sentence.", //
                     ImmutableList.of( "p", "phrase" ), //
                     ImmutableList.of( new MPTemplate( "cvcc cvc cvccvcv cvc" ), new MPTemplate( "cvc cvccvcvcv cvcv" ),
                                       new MPTemplate( "cv cvccv cvc cvcvccv" ) ), //
                     MPSiteTypeClass.Generated, 0xF ),

    StoredPersonal( "AES-encrypted, exportable.", //
                    ImmutableList.of( "personal" ), //
                    ImmutableList.<MPTemplate>of(), //
                    MPSiteTypeClass.Stored, 0x0, MPSiteFeature.ExportContent ),

    StoredDevicePrivate( "AES-encrypted, not exported.", //
                         ImmutableList.of( "device" ), //
                         ImmutableList.<MPTemplate>of(), //
                         MPSiteTypeClass.Stored, 0x1, MPSiteFeature.DevicePrivate );

    static final Logger logger = Logger.get( MPSiteType.class );

    private final String             description;
    private final List<String>       options;
    private final List<MPTemplate>   templates;
    private final MPSiteTypeClass    typeClass;
    private final int                typeIndex;
    private final Set<MPSiteFeature> typeFeatures;

    MPSiteType(final String description, final List<String> options, final List<MPTemplate> templates, final MPSiteTypeClass typeClass,
               final int typeIndex, final MPSiteFeature... typeFeatures) {

        this.description = description;
        this.options = options;
        this.templates = templates;
        this.typeClass = typeClass;
        this.typeIndex = typeIndex;

        ImmutableSet.Builder<MPSiteFeature> typeFeaturesBuilder = ImmutableSet.builder();
        for (final MPSiteFeature typeFeature : typeFeatures) {
            typeFeaturesBuilder.add( typeFeature );
        }
        this.typeFeatures = typeFeaturesBuilder.build();
    }

    public String getDescription() {

        return description;
    }

    public List<String> getOptions() {
        return options;
    }

    public MPSiteTypeClass getTypeClass() {

        return typeClass;
    }

    public Set<MPSiteFeature> getTypeFeatures() {

        return typeFeatures;
    }

    public int getType() {
        int mask = typeIndex | typeClass.getMask();
        for (MPSiteFeature typeFeature : typeFeatures)
            mask |= typeFeature.getMask();

        return mask;
    }

    /**
     * @param option The option to select a type with.  It is matched case insensitively.
     *
     * @return The type registered for the given option.
     */
    public static MPSiteType forOption(final String option) {

        for (final MPSiteType type : values())
            if (type.getOptions().contains( option.toLowerCase() ))
                return type;

        throw logger.bug( "No type for option: %s", option );
    }

    /**
     * @param name The name fromInt the type to look up.  It is matched case insensitively.
     *
     * @return The type registered with the given name.
     */
    public static MPSiteType forName(final String name) {

        if (name == null)
            return null;

        for (final MPSiteType type : values())
            if (type.name().equalsIgnoreCase( name ))
                return type;

        throw logger.bug( "No type for name: %s", name );
    }

    /**
     * @param typeClass The class for which we look up types.
     *
     * @return All types that support the given class.
     */
    public static ImmutableList<MPSiteType> forClass(final MPSiteTypeClass typeClass) {

        ImmutableList.Builder<MPSiteType> types = ImmutableList.builder();
        for (final MPSiteType type : values())
            if (type.getTypeClass() == typeClass)
                types.add( type );

        return types.build();
    }

    /**
     * @param type The type for which we look up types.
     *
     * @return The type registered with the given type.
     */
    public static MPSiteType forType(final int type) {

        for (MPSiteType siteType : values())
            if (siteType.getType() == type)
                return siteType;

        throw logger.bug( "No type: %s", type );
    }

    /**
     * @param mask The mask for which we look up types.
     *
     * @return All types that support the given mask.
     */
    public static ImmutableList<MPSiteType> forMask(final int mask) {

        int typeMask = mask & ~0xF;
        ImmutableList.Builder<MPSiteType> types = ImmutableList.builder();
        for (MPSiteType siteType : values())
            if (((siteType.getType() & ~0xF) & typeMask) != 0)
                types.add( siteType );

        return types.build();
    }

    public MPTemplate getTemplateAtRollingIndex(final int templateIndex) {
        return templates.get( templateIndex % templates.size() );
    }
}
