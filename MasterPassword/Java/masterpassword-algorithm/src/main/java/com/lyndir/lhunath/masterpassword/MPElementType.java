package com.lyndir.lhunath.masterpassword;

import com.google.common.collect.ImmutableSet;
import com.lyndir.lhunath.opal.system.logging.Logger;
import java.util.Set;


/**
 * <i>07 04, 2012</i>
 *
 * @author lhunath
 */
public enum MPElementType {

    GeneratedMaximum( "Maximum Security Password", "Maximum", "20 characters, contains symbols.", MPElementTypeClass.Generated ),
    GeneratedLong( "Long Password", "Long", "Copy-friendly, 14 characters, contains symbols.", MPElementTypeClass.Generated ),
    GeneratedMedium( "Medium Password", "Medium", "Copy-friendly, 8 characters, contains symbols.", MPElementTypeClass.Generated ),
    GeneratedShort( "Short Password", "Short", "Copy-friendly, 4 characters, no symbols.", MPElementTypeClass.Generated ),
    GeneratedBasic( "Basic Password", "Basic", "8 characters, no symbols.", MPElementTypeClass.Generated ),
    GeneratedPIN( "PIN", "PIN", "4 numbers.", MPElementTypeClass.Generated ),

    StoredPersonal( "Personal Password", "Personal", "AES-encrypted, exportable.", MPElementTypeClass.Stored, MPElementFeature.ExportContent ),
    StoredDevicePrivate( "Device Private Password", "Private", "AES-encrypted, not exported.", MPElementTypeClass.Stored, MPElementFeature.DevicePrivate );

    static final Logger logger = Logger.get( MPElementType.class );

    private final   MPElementTypeClass    typeClass;
    private final   Set<MPElementFeature> typeFeatures;
    private final   String                name;
    private final   String                shortName;
    private final String                description;

    MPElementType(final String name, final String shortName, final String description, final MPElementTypeClass typeClass, final MPElementFeature... typeFeatures) {

        this.name = name;
        this.shortName = shortName;
        this.typeClass = typeClass;
        this.description = description;

        ImmutableSet.Builder<MPElementFeature> typeFeaturesBuilder = ImmutableSet.builder();
        for (final MPElementFeature typeFeature : typeFeatures)
            typeFeaturesBuilder.add( typeFeature );
        this.typeFeatures = typeFeaturesBuilder.build();
    }

    public MPElementTypeClass getTypeClass() {

        return typeClass;
    }

    public Set<MPElementFeature> getTypeFeatures() {

        return typeFeatures;
    }

    public String getName() {

        return name;
    }

    public String getShortName() {

        return shortName;
    }

    public String getDescription() {

        return description;
    }

    public static MPElementType forName(final String name) {

        for (final MPElementType type : values())
            if (type.getName().equals( name ))
                return type;

        throw logger.bug( "Element type not known: %s", name );
    }
}
