package com.lyndir.masterpassword;

import static com.google.common.base.Preconditions.checkNotNull;
import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;
import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.*;
import java.util.List;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * @author lhunath, 14-12-05
 */
public class MPTests {

    private static final String ID_DEFAULT = "default";

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MPTests.class );

    List<Case> cases;

    @Nonnull
    public List<Case> getCases() {
        return checkNotNull( cases );
    }

    public Case getCase(final String identifier) {
        for (final Case testCase : getCases())
            if (identifier.equals( testCase.getIdentifier() ))
                return testCase;

        throw new IllegalArgumentException( strf( "No case for identifier: %s", identifier ) );
    }

    public Case getDefaultCase() {
        try {
            return getCase( ID_DEFAULT );
        }
        catch (final IllegalArgumentException e) {
            throw new IllegalStateException( strf( "Missing default case in test suite.  Add a case with id: %d", ID_DEFAULT ), e );
        }
    }

    public static class Case {

        String  identifier;
        String  parent;
        Integer algorithm;
        String  fullName;
        String  masterPassword;
        String  keyID;
        String  siteName;
        UnsignedInteger siteCounter;
        String  siteType;
        String  siteVariant;
        String  siteContext;
        String  result;

        private transient Case parentCase;

        public void initializeParentHierarchy(final MPTests tests) {

            if (parent != null) {
                parentCase = tests.getCase( parent );
                parentCase.initializeParentHierarchy( tests );
            }

            algorithm = ifNotNullElse( algorithm, new NNSupplier<Integer>() {
                @Nonnull
                @Override
                public Integer get() {
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
            siteCounter = ifNotNullElse( siteCounter, new NNSupplier<UnsignedInteger>() {
                @Nonnull
                @Override
                public UnsignedInteger get() {
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
                    return (parentCase == null)? "": checkNotNull( parentCase.siteContext );
                }
            } );
            result = ifNotNullElse( result, new NNSupplier<String>() {
                @Nonnull
                @Override
                public String get() {
                    return (parentCase == null)? "": checkNotNull( parentCase.result );
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
            return MasterKey.Version.fromInt( checkNotNull( algorithm ) );
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

        public UnsignedInteger getSiteCounter() {
            return ifNotNullElse( siteCounter, UnsignedInteger.valueOf( 1 ) );
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
