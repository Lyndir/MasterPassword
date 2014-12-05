package com.lyndir.masterpassword;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableSet;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.util.List;
import java.util.Set;
import javax.annotation.Generated;


/**
 * <i>07 04, 2012</i>
 *
 * @author lhunath
 */
public enum MPElementType {

    GeneratedMaximum( "20 characters, contains symbols.", //
                      ImmutableList.of( "x", "max", "maximum" ), MPElementTypeClass.Generated, //
                      ImmutableList.of( new MPTemplate( "anoxxxxxxxxxxxxxxxxx" ), new MPTemplate( "axxxxxxxxxxxxxxxxxno" ) ) ),

    GeneratedLong( "Copy-friendly, 14 characters, contains symbols.", //
                   ImmutableList.of( "l", "long" ), MPElementTypeClass.Generated, //
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
                     ImmutableList.of( "m", "med", "medium" ), MPElementTypeClass.Generated, //
                     ImmutableList.of( new MPTemplate( "CvcnoCvc" ), new MPTemplate( "CvcCvcno" ) ) ),

    GeneratedBasic( "8 characters, no symbols.", //
                    ImmutableList.of( "b", "basic" ), MPElementTypeClass.Generated, //
                    ImmutableList.of( new MPTemplate( "aaanaaan" ), new MPTemplate( "aannaaan" ), new MPTemplate( "aaannaaa" ) ) ),

    GeneratedShort( "Copy-friendly, 4 characters, no symbols.", //
                    ImmutableList.of( "s", "short" ), MPElementTypeClass.Generated, //
                    ImmutableList.of( new MPTemplate( "Cvcn" ) ) ),

    GeneratedPIN( "4 numbers.", //
                  ImmutableList.of( "i", "pin" ), MPElementTypeClass.Generated, //
                  ImmutableList.of( new MPTemplate( "nnnn" ) ) ),

    GeneratedName( "9 letter name.", //
                   ImmutableList.of( "n", "name" ), MPElementTypeClass.Generated, //
                   ImmutableList.of( new MPTemplate( "cvccvcvcv" ) ) ),

    GeneratedPhrase( "20 character sentence.", //
                     ImmutableList.of( "p", "phrase" ), MPElementTypeClass.Generated, //
                     ImmutableList.of( new MPTemplate( "cvcc cvc cvccvcv cvc" ), new MPTemplate( "cvc cvccvcvcv cvcv" ),
                                       new MPTemplate( "cv cvccv cvc cvcvccv" ) ) ),

    StoredPersonal( "AES-encrypted, exportable.", //
                    ImmutableList.of( "personal" ), MPElementTypeClass.Stored, //
                    ImmutableList.<MPTemplate>of(), MPElementFeature.ExportContent ),

    StoredDevicePrivate( "AES-encrypted, not exported.", //
                         ImmutableList.of( "device" ), MPElementTypeClass.Stored, //
                         ImmutableList.<MPTemplate>of(), MPElementFeature.DevicePrivate );

    static final Logger logger = Logger.get( MPElementType.class );

    private final String                description;
    private final List<String>          options;
    private final MPElementTypeClass    typeClass;
    private final List<MPTemplate>      templates;
    private final Set<MPElementFeature> typeFeatures;

    MPElementType(final String description, final List<String> options, final MPElementTypeClass typeClass,
                  final List<MPTemplate> templates, final MPElementFeature... typeFeatures) {

        this.description = description;
        this.options = options;
        this.typeClass = typeClass;
        this.templates = templates;

        ImmutableSet.Builder<MPElementFeature> typeFeaturesBuilder = ImmutableSet.builder();
        for (final MPElementFeature typeFeature : typeFeatures) {
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

    public MPElementTypeClass getTypeClass() {

        return typeClass;
    }

    public Set<MPElementFeature> getTypeFeatures() {

        return typeFeatures;
    }

    /**
     * @param option The option to select a type with.  It is matched case insensitively.
     *
     * @return The type registered for the given option.
     */
    public static MPElementType forOption(final String option) {

        for (final MPElementType type : values())
            if (type.getOptions().contains( option.toLowerCase() ))
                return type;

        throw logger.bug( "No type for option: %s", option );
    }

    /**
     * @param name The name of the type to look up.  It is matched case insensitively.
     *
     * @return The type registered with the given name.
     */
    public static MPElementType forName(final String name) {

        if (name == null)
            return null;

        for (final MPElementType type : values())
            if (type.name().equalsIgnoreCase( name ))
                return type;

        throw logger.bug( "No type for name: %s", name );
    }

    /**
     * @param typeClass The class for which we look up types.
     *
     * @return All types that support the given class.
     */
    public static ImmutableList<MPElementType> forClass(final MPElementTypeClass typeClass) {

        ImmutableList.Builder<MPElementType> types = ImmutableList.builder();
        for (final MPElementType type : values())
            if (type.getTypeClass() == typeClass)
                types.add( type );

        return types.build();
    }

    public MPTemplate getTemplateAtRollingIndex(final int templateIndex) {
        return templates.get( templateIndex % templates.size() );
    }
}
