package com.lyndir.masterpassword;

import static com.google.common.base.Preconditions.checkNotNull;
import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;

import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.*;
import java.util.List;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import javax.xml.bind.annotation.*;


/**
 * @author lhunath, 14-12-05
 */
@XmlRootElement(name = "tests")
public class MPTests {

    private static final String ID_DEFAULT = "default";

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MPTests.class );

    @XmlElement(name = "case")
    private List<Case> cases;

    @Nonnull
    public List<Case> getCases() {
        return checkNotNull( cases );
    }

    public Case getCase(String identifier) {
        for (Case testCase : getCases())
            if (identifier.equals( testCase.getIdentifier() ))
                return testCase;

        throw new IllegalArgumentException( "No case for identifier: " + identifier );
    }

    public Case getDefaultCase() {
        try {
            return getCase( ID_DEFAULT );
        }
        catch (IllegalArgumentException e) {
            throw new IllegalStateException( "Missing default case in test suite.  Add a case with id: " + ID_DEFAULT, e );
        }
    }

    @XmlRootElement(name = "case")
    public static class Case {

        @XmlAttribute(name = "id")
        private String  identifier;
        @XmlAttribute
        private String  parent;
        @XmlElement
        private String  algorithm;
        @XmlElement
        private String  fullName;
        @XmlElement
        private String  masterPassword;
        @XmlElement
        private String  keyID;
        @XmlElement
        private String  siteName;
        @XmlElement
        private Integer siteCounter;
        @XmlElement
        private String  siteType;
        @XmlElement
        private String  siteVariant;
        @XmlElement
        private String  siteContext;
        @XmlElement
        private String  result;

        private transient Case parentCase;

        public void initializeParentHierarchy(MPTests tests) {

            if (parent != null) {
                parentCase = tests.getCase( parent );
                parentCase.initializeParentHierarchy( tests );
            }

            algorithm = ifNotNullElse( algorithm, new NNSupplier<String>() {
                @Nonnull
                @Override
                public String get() {
                    return checkNotNull( parentCase.algorithm );
                }
            } );
            fullName = ifNotNullElse( fullName, new NNSupplier<String>() {
                @Nonnull
                @Override
                public String get() {
                    return checkNotNull( parentCase.fullName );
                }
            } );
            masterPassword = ifNotNullElse( masterPassword, new NNSupplier<String>() {
                @Nonnull
                @Override
                public String get() {
                    return checkNotNull( parentCase.masterPassword );
                }
            } );
            keyID = ifNotNullElse( keyID, new NNSupplier<String>() {
                @Nonnull
                @Override
                public String get() {
                    return checkNotNull( parentCase.keyID );
                }
            } );
            siteName = ifNotNullElse( siteName, new NNSupplier<String>() {
                @Nonnull
                @Override
                public String get() {
                    return checkNotNull( parentCase.siteName );
                }
            } );
            siteCounter = ifNotNullElse( siteCounter, new NNSupplier<Integer>() {
                @Nonnull
                @Override
                public Integer get() {
                    return checkNotNull( parentCase.siteCounter );
                }
            } );
            siteType = ifNotNullElse( siteType, new NNSupplier<String>() {
                @Nonnull
                @Override
                public String get() {
                    return checkNotNull( parentCase.siteType );
                }
            } );
            siteVariant = ifNotNullElse( siteVariant, new NNSupplier<String>() {
                @Nonnull
                @Override
                public String get() {
                    return checkNotNull( parentCase.siteVariant );
                }
            } );
            siteContext = ifNotNullElse( siteContext, new NNSupplier<String>() {
                @Nonnull
                @Override
                public String get() {
                    return parentCase == null? "": checkNotNull( parentCase.siteContext );
                }
            } );
            result = ifNotNullElse( result, new NNSupplier<String>() {
                @Nonnull
                @Override
                public String get() {
                    return parentCase == null? "": checkNotNull( parentCase.result );
                }
            } );
        }

        @Nonnull
        public String getIdentifier() {
            return identifier;
        }

        @Nullable
        public Case getParentCase() {
            return parentCase;
        }

        @Nonnull
        public MasterKey.Version getAlgorithm() {
            return MasterKey.Version.fromInt( ConversionUtils.toIntegerNN( algorithm ) );
        }

        @Nonnull
        public String getFullName() {
            return checkNotNull( fullName );
        }

        @Nonnull
        public char[] getMasterPassword() {
            return checkNotNull( masterPassword ).toCharArray();
        }

        @Nonnull
        public String getKeyID() {
            return checkNotNull( keyID );
        }

        @Nonnull
        public String getSiteName() {
            return checkNotNull( siteName );
        }

        public int getSiteCounter() {
            return ifNotNullElse( siteCounter, 1 );
        }

        @Nonnull
        public MPSiteType getSiteType() {
            return MPSiteType.forName( checkNotNull( siteType ) );
        }

        @Nonnull
        public MPSiteVariant getSiteVariant() {
            return MPSiteVariant.forName( checkNotNull( siteVariant ) );
        }

        @Nonnull
        public String getSiteContext() {
            return checkNotNull( siteContext );
        }

        @Nonnull
        public String getResult() {
            return checkNotNull( result );
        }

        @Override
        public String toString() {
            return identifier;
        }
    }
}
