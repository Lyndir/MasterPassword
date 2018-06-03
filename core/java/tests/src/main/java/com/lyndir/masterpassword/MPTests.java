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

import static com.google.common.base.Preconditions.*;
import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;
import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.NNSupplier;
import java.util.*;
import java.util.stream.Collectors;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import javax.xml.bind.annotation.XmlTransient;


/**
 * @author lhunath, 14-12-05
 */
public class MPTests {

    private static final String ID_DEFAULT = "default";

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MPTests.class );

    private final Set<String> filters = new HashSet<>();

    List<Case> cases;

    @Nonnull
    public List<Case> getCases() {
        if (filters.isEmpty())
            return checkNotNull( cases );

        return checkNotNull( cases ).stream().filter( testCase -> {
            for (final String filter : filters)
                if (testCase.getIdentifier().startsWith( filter ))
                    return true;
            return false;
        } ).collect( Collectors.toList() );
    }

    public Case getCase(final String identifier) {
        for (final Case testCase : cases)
            if (identifier.equals( testCase.getIdentifier() ))
                return testCase;

        throw new IllegalArgumentException( strf( "No case for identifier: %s", identifier ) );
    }

    public Case getDefaultCase() {
        try {
            return getCase( ID_DEFAULT );
        }
        catch (final IllegalArgumentException e) {
            throw new IllegalStateException( strf( "Missing default case in test suite.  Add a case with id: %s", ID_DEFAULT ), e );
        }
    }

    public boolean addFilters(final String... filters) {
        return this.filters.addAll( Arrays.asList( filters ) );
    }

    public static class Case {

        String identifier;
        String parent;
        @Nullable
        Integer algorithm;
        String fullName;
        String masterPassword;
        String keyID;
        String siteName;
        @Nullable
        UnsignedInteger siteCounter;
        String resultType;
        String keyPurpose;
        String keyContext;
        String result;

        @XmlTransient
        private Case parentCase;

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
            resultType = ifNotNullElse( resultType, new NNSupplier<String>() {
                @Nonnull
                @Override
                public String get() {
                    return checkNotNull( parentCase.resultType );
                }
            } );
            keyPurpose = ifNotNullElse( keyPurpose, new NNSupplier<String>() {
                @Nonnull
                @Override
                public String get() {
                    return checkNotNull( parentCase.keyPurpose );
                }
            } );
            keyContext = ifNotNullElse( keyContext, new NNSupplier<String>() {
                @Nonnull
                @Override
                public String get() {
                    return (parentCase == null)? "": checkNotNull( parentCase.keyContext );
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
        public MPAlgorithm getAlgorithm() {
            return MPAlgorithm.Version.fromInt( checkNotNull( algorithm ) ).getAlgorithm();
        }

        @Nonnull
        public String getFullName() {
            return checkNotNull( fullName );
        }

        @Nonnull
        public String getMasterPassword() {
            return checkNotNull( masterPassword );
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
        public MPResultType getResultType() {
            return MPResultType.forName( checkNotNull( resultType ) );
        }

        @Nonnull
        public MPKeyPurpose getKeyPurpose() {
            return MPKeyPurpose.forName( checkNotNull( keyPurpose ) );
        }

        @Nonnull
        public String getKeyContext() {
            return checkNotNull( keyContext );
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
