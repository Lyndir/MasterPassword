package com.lyndir.masterpassword;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;

import com.lyndir.lhunath.opal.system.logging.Logger;
import com.lyndir.lhunath.opal.system.util.NNSupplier;
import com.lyndir.lhunath.opal.system.util.NSupplier;
import java.util.List;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import javax.xml.bind.annotation.*;


/**
 * @author lhunath, 14-12-05
 */
@XmlRootElement(name = "tests")
public class MPWTests {

    public static final String ID_DEFAULT = "default";

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MPWTests.class );

    @XmlElement(name = "case")
    private List<Case> cases;

    public List<Case> getCases() {
        return cases;
    }

    public Case getCase(String identifier) {
        for (Case testCase : getCases())
            if (identifier.equals( testCase.getIdentifier() ))
                return testCase;

        throw new IllegalArgumentException( "No case for identifier: " + identifier );
    }

    @XmlRootElement(name = "case")
    public static class Case {

        @XmlAttribute(name = "id")
        private String  identifier;
        @XmlAttribute
        private String  parent;
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

        public void setTests(MPWTests tests) {

            if (parent != null) {
                parentCase = tests.getCase( parent );
                fullName = ifNotNullElse( fullName, new NNSupplier<String>() {
                    @Nonnull
                    @Override
                    public String get() {
                        return parentCase.getFullName();
                    }
                } );
                masterPassword = ifNotNullElse( masterPassword, new NNSupplier<String>() {
                    @Nonnull
                    @Override
                    public String get() {
                        return parentCase.getMasterPassword();
                    }
                } );
                keyID = ifNotNullElse( keyID, new NNSupplier<String>() {
                    @Nonnull
                    @Override
                    public String get() {
                        return parentCase.getKeyID();
                    }
                } );
                siteName = ifNotNullElse( siteName, new NNSupplier<String>() {
                    @Nonnull
                    @Override
                    public String get() {
                        return parentCase.getSiteName();
                    }
                } );
                siteCounter = ifNotNullElse( siteCounter, new NNSupplier<Integer>() {
                    @Nonnull
                    @Override
                    public Integer get() {
                        return parentCase.getSiteCounter();
                    }
                } );
                siteType = ifNotNullElse( siteType, new NNSupplier<String>() {
                    @Nonnull
                    @Override
                    public String get() {
                        return parentCase.getSiteType().name();
                    }
                } );
                siteVariant = ifNotNullElse( siteVariant, new NNSupplier<String>() {
                    @Nonnull
                    @Override
                    public String get() {
                        return parentCase.getSiteVariant().name();
                    }
                } );
                siteContext = ifNotNullElseNullable( siteContext, new NSupplier<String>() {
                    @Nonnull
                    @Override
                    public String get() {
                        return parentCase.getSiteContext();
                    }
                } );
                result = ifNotNullElse( result, new NNSupplier<String>() {
                    @Nonnull
                    @Override
                    public String get() {
                        return parentCase.getResult();
                    }
                } );
            }
        }

        public String getIdentifier() {
            return identifier;
        }

        @Nullable
        public Case getParentCase() {
            return parentCase;
        }

        public String getFullName() {
            return fullName;
        }

        public String getMasterPassword() {
            return masterPassword;
        }

        public String getKeyID() {
            return keyID;
        }

        public String getSiteName() {
            return siteName;
        }

        public int getSiteCounter() {
            return siteCounter;
        }

        public MPSiteType getSiteType() {
            return MPSiteType.forName( siteType );
        }

        public MPSiteVariant getSiteVariant() {
            return MPSiteVariant.forName( siteVariant );
        }

        public String getSiteContext() {
            return siteContext;
        }

        public String getResult() {
            return result;
        }

        @Override
        public String toString() {
            return identifier;
        }
    }
}
