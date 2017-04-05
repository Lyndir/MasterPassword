package com.lyndir.masterpassword.model;

import static com.lyndir.lhunath.opal.system.util.StringUtils.strf;

import java.util.Objects;


/**
 * @author lhunath, 14-12-07
 */
public class MPSiteResult {

    private final MPSite site;

    public MPSiteResult(final MPSite site) {
        this.site = site;
    }

    public MPSite getSite() {
        return site;
    }

    @Override
    public boolean equals(final Object obj) {
        return (this == obj) || ((obj instanceof MPSiteResult) && Objects.equals( site, ((MPSiteResult) obj).site ));
    }

    @Override
    public int hashCode() {
        return Objects.hashCode( site );
    }

    @Override
    public String toString() {
        return strf( "{MPSiteResult: %s}", site );
    }
}
