package com.lyndir.masterpassword;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableSet;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.util.List;
import java.util.Set;


/**
 * <i>07 04, 2012</i>
 *
 * @author lhunath
 */
public enum MPSiteType {

    GeneratedMaximum( "20 characters, contains symbols.", //
                      ImmutableList.of( "x", "max", "maximum" ), MPSiteTypeClass.Generated, //
                      ImmutableList.of( new MPTemplate( "anoxxxxxxxxxxxxxxxxx" ), new MPTemplate( "axxxxxxxxxxxxxxxxxno" ) ) ),

    GeneratedLong( "Copy-friendly, 14 characters, contains symbols.", //
                   ImmutableList.of( "l", "long" ), MPSiteTypeClass.Generated, //
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
                                     new MPTemplate( "CvccCvcvCvccno" ) ) ),

    GeneratedMedium( "Copy-friendly, 8 characters, contains symbols.", //
                     ImmutableList.of( "m", "med", "medium" ), MPSiteTypeClass.Generated, //
                     ImmutableList.of( new MPTemplate( "CvcnoCvc" ), new MPTemplate( "CvcCvcno" ) ) ),

    GeneratedBasic( "8 characters, no symbols.", //
                    ImmutableList.of( "b", "basic" ), MPSiteTypeClass.Generated, //
                    ImmutableList.of( new MPTemplate( "aaanaaan" ), new MPTemplate( "aannaaan" ), new MPTemplate( "aaannaaa" ) ) ),

    GeneratedShort( "Copy-friendly, 4 characters, no symbols.", //
                    ImmutableList.of( "s", "short" ), MPSiteTypeClass.Generated, //
                    ImmutableList.of( new MPTemplate( "Cvcn" ) ) ),

    GeneratedPIN( "4 numbers.", //
                  ImmutableList.of( "i", "pin" ), MPSiteTypeClass.Generated, //
                  ImmutableList.of( new MPTemplate( "nnnn" ) ) ),

    GeneratedName( "9 letter name.", //
                   ImmutableList.of( "n", "name" ), MPSiteTypeClass.Generated, //
                   ImmutableList.of( new MPTemplate( "cvccvcvcv" ) ) ),

    GeneratedPhrase( "20 character sentence.", //
                     ImmutableList.of( "p", "phrase" ), MPSiteTypeClass.Generated, //
                     ImmutableList.of( new MPTemplate( "cvcc cvc cvccvcv cvc" ), new MPTemplate( "cvc cvccvcvcv cvcv" ),
                                       new MPTemplate( "cv cvccv cvc cvcvccv" ) ) ),

    StoredPersonal( "AES-encrypted, exportable.", //
                    ImmutableList.of( "personal" ), MPSiteTypeClass.Stored, //
                    ImmutableList.<MPTemplate>of(), MPSiteFeature.ExportContent ),

    StoredDevicePrivate( "AES-encrypted, not exported.", //
                         ImmutableList.of( "device" ), MPSiteTypeClass.Stored, //
                         ImmutableList.<MPTemplate>of(), MPSiteFeature.DevicePrivate );

    static final Logger logger = Logger.get( MPSiteType.class );

    private final String             description;
    private final List<String>       options;
    private final MPSiteTypeClass    typeClass;
    private final List<MPTemplate>   templates;
    private final Set<MPSiteFeature> typeFeatures;

    MPSiteType(final String description, final List<String> options, final MPSiteTypeClass typeClass, final List<MPTemplate> templates,
               final MPSiteFeature... typeFeatures) {

        this.description = description;
        this.options = options;
        this.typeClass = typeClass;
        this.templates = templates;

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
     * @param name The name of the type to look up.  It is matched case insensitively.
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

    public MPTemplate getTemplateAtRollingIndex(final int templateIndex) {
        return templates.get( templateIndex % templates.size() );
    }
}
