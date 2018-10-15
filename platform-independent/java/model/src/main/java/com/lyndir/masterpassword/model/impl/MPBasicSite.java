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

package com.lyndir.masterpassword.model.impl;

import static com.lyndir.lhunath.opal.system.util.ObjectUtils.*;
import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.model.*;
import java.util.*;
import javax.annotation.Nonnull;
import javax.annotation.Nullable;


/**
 * @author lhunath, 14-12-16
 */
public abstract class MPBasicSite<U extends MPUser<?>, Q extends MPQuestion> extends Changeable
        implements MPSite<Q> {

    private final U             user;
    private final String        siteName;
    private final Collection<Q> questions = new TreeSet<>();

    private MPAlgorithm     algorithm;
    private UnsignedInteger counter;
    private MPResultType    resultType;
    private MPResultType    loginType;

    protected MPBasicSite(final U user, final String siteName) {
        this( user, siteName, null, null, null, null );
    }

    protected MPBasicSite(final U user, final String siteName,
                          @Nullable final MPAlgorithm algorithm, @Nullable final UnsignedInteger counter,
                          @Nullable final MPResultType resultType, @Nullable final MPResultType loginType) {
        this.user = user;
        this.siteName = siteName;
        this.algorithm = (algorithm != null)? algorithm: this.user.getAlgorithm();
        this.counter = (counter != null)? counter: this.algorithm.mpw_default_counter();
        this.resultType = (resultType != null)? resultType: this.user.getPreferences().getDefaultType();
        this.loginType = (loginType != null)? loginType: this.algorithm.mpw_default_login_type();
    }

    // - Meta

    @Nonnull
    @Override
    public String getSiteName() {
        return siteName;
    }

    // - Algorithm

    @Nonnull
    @Override
    public MPAlgorithm getAlgorithm() {
        return algorithm;
    }

    @Override
    public void setAlgorithm(final MPAlgorithm algorithm) {
        if (Objects.equals( this.algorithm, algorithm ))
            return;

        this.algorithm = algorithm;
        setChanged();
    }

    @Nonnull
    @Override
    public UnsignedInteger getCounter() {
        return counter;
    }

    @Override
    public void setCounter(final UnsignedInteger counter) {
        if (Objects.equals( this.counter, counter ))
            return;

        this.counter = counter;
        setChanged();
    }

    @Nonnull
    @Override
    public MPResultType getResultType() {
        return resultType;
    }

    @Override
    public void setResultType(final MPResultType resultType) {
        if (this.resultType == resultType)
            return;

        this.resultType = resultType;
        setChanged();
    }

    @Nonnull
    @Override
    public MPResultType getLoginType() {
        return loginType;
    }

    @Override
    public void setLoginType(@Nullable final MPResultType loginType) {
        if (this.loginType == loginType)
            return;

        this.loginType = ifNotNullElse( loginType, getAlgorithm().mpw_default_login_type() );
        setChanged();
    }

    @Nullable
    @Override
    public String getResult(final MPKeyPurpose keyPurpose, @Nullable final String keyContext, @Nullable final String state)
            throws MPKeyUnavailableException, MPAlgorithmException {

        return getResult( keyPurpose, keyContext, getCounter(), getResultType(), state );
    }

    @Nullable
    @Override
    public String getResult(final MPKeyPurpose keyPurpose, @Nullable final String keyContext,
                            @Nullable final UnsignedInteger counter, final MPResultType type, @Nullable final String state)
            throws MPKeyUnavailableException, MPAlgorithmException {

        return getUser().getMasterKey().siteResult(
                getSiteName(), getAlgorithm(), ifNotNullElse( counter, getAlgorithm().mpw_default_counter() ),
                keyPurpose, keyContext, type, state );
    }

    @Nonnull
    @Override
    public String getState(final MPKeyPurpose keyPurpose, @Nullable final String keyContext,
                           @Nullable final UnsignedInteger counter, final MPResultType type, final String state)
            throws MPKeyUnavailableException, MPAlgorithmException {

        return getUser().getMasterKey().siteState(
                getSiteName(), getAlgorithm(), ifNotNullElse( counter, getAlgorithm().mpw_default_counter() ),
                keyPurpose, keyContext, type, state );
    }

    @Nullable
    @Override
    public String getLogin(@Nullable final String state)
            throws MPKeyUnavailableException, MPAlgorithmException {

        return getResult( MPKeyPurpose.Identification, null, null, getLoginType(), state );
    }

    // - Relations

    @Nonnull
    @Override
    public U getUser() {
        return user;
    }

    @Nonnull
    @Override
    public Q addQuestion(final Q question) {
        questions.add( question );

        setChanged();
        return question;
    }

    @Override
    public boolean deleteQuestion(final Q question) {
        if (!questions.remove( question ))
            return false;

        setChanged();
        return true;
    }

    @Nonnull
    @Override
    public Collection<Q> getQuestions() {
        return Collections.unmodifiableCollection( questions );
    }

    @Override
    protected void onChanged() {
        if (user instanceof Changeable)
            ((Changeable) user).setChanged();
    }

    @Override
    public int hashCode() {
        return Objects.hashCode( getSiteName() );
    }

    @Override
    public boolean equals(final Object obj) {
        return obj == this;
    }

    @Override
    public int compareTo(@Nonnull final MPSite<?> o) {
        return getSiteName().compareTo( o.getSiteName() );
    }

    @Override
    public String toString() {
        return strf( "{%s: %s}", getClass().getSimpleName(), getSiteName() );
    }
}
