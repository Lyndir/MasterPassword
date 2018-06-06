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

import com.fasterxml.jackson.annotation.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.masterpassword.*;
import com.lyndir.masterpassword.model.MPConstant;
import com.lyndir.masterpassword.model.MPIncorrectMasterPasswordException;
import edu.umd.cs.findbugs.annotations.SuppressFBWarnings;
import java.util.LinkedHashMap;
import java.util.Map;
import javax.annotation.Nullable;
import org.joda.time.Instant;


/**
 * @author lhunath, 2018-04-27
 */
@SuppressFBWarnings( "URF_UNREAD_FIELD" )
public class MPJSONFile extends MPJSONAnyObject {

    protected static final ObjectMapper objectMapper = new ObjectMapper();

    static {
        objectMapper.setSerializationInclusion( JsonInclude.Include.NON_EMPTY );
        objectMapper.setVisibility( PropertyAccessor.FIELD, JsonAutoDetect.Visibility.NON_PRIVATE );
    }

    public MPJSONFile write(final MPFileUser modelUser)
            throws MPKeyUnavailableException, MPAlgorithmException {
        // Section: "export"
        if (export == null)
            export = new Export();
        export.format = 1;
        export.redacted = modelUser.getContentMode().isRedacted();
        export.date = MPConstant.dateTimeFormatter.print( new Instant() );

        // Section: "user"
        if (user == null)
            user = new User();
        user.avatar = modelUser.getAvatar();
        user.full_name = modelUser.getFullName();
        user.last_used = MPConstant.dateTimeFormatter.print( modelUser.getLastUsed() );
        user.key_id = modelUser.exportKeyID();
        user.algorithm = modelUser.getAlgorithm().version();
        user.default_type = modelUser.getDefaultType();

        // Section "sites"
        if (sites == null)
            sites = new LinkedHashMap<>();
        for (final MPFileSite modelSite : modelUser.getSites()) {
            String content = null, loginContent = null;
            if (!export.redacted) {
                // Clear Text
                content = modelSite.getResult();
                loginContent = modelUser.getMasterKey().siteResult(
                        modelSite.getName(), modelSite.getAlgorithm(), modelSite.getAlgorithm().mpw_default_counter(),
                        MPKeyPurpose.Identification, null, modelSite.getLoginType(), modelSite.getLoginState() );
            } else {
                // Redacted
                if (modelSite.getResultType().supportsTypeFeature( MPSiteFeature.ExportContent ))
                    content = modelSite.getResultState();
                if (modelSite.getLoginType().supportsTypeFeature( MPSiteFeature.ExportContent ))
                    loginContent = modelSite.getLoginState();
            }

            Site site = sites.get( modelSite.getName() );
            if (site == null)
                sites.put( modelSite.getName(), site = new Site() );
            site.type = modelSite.getResultType();
            site.counter = modelSite.getCounter().longValue();
            site.algorithm = modelSite.getAlgorithm().version();
            site.password = content;
            site.login_name = loginContent;
            site.login_type = modelSite.getLoginType();

            site.uses = modelSite.getUses();
            site.last_used = MPConstant.dateTimeFormatter.print( modelSite.getLastUsed() );

            if (site._ext_mpw == null)
                site._ext_mpw = new Site.Ext();
            site._ext_mpw.url = modelSite.getUrl();

            if (site.questions == null)
                site.questions = new LinkedHashMap<>();
            //                for (size_t q = 0; q < site.questions_count; ++q) {
            //                    MPMarshalledQuestion *question = &site.questions[q];
            //                    if (!question.keyword)
            //                        continue;
            //
            //                    json_object *json_site_question = json_object_new_object();
            //                    json_object_object_add( json_site_questions, question.keyword, json_site_question );
            //                    json_object_object_add( json_site_question, "type = question.type;
            //
            //                    if (!user.redacted) {
            //                        // Clear Text
            //                const char *answerContent = mpw_siteResult( masterKey, site.name, MPCounterValueInitial,
            //                                                            MPKeyPurposeRecovery, question.keyword, question.type, question.content, site.algorithm );
            //                        json_object_object_add( json_site_question, "answer = answerContent;
            //                    }
            //                    else {
            //                        // Redacted
            //                        if (site.type & MPSiteFeatureExportContent && question.content && strlen( question.content ))
            //                            json_object_object_add( json_site_question, "answer = question.content;
            //                    }
            //                }

            //                json_object *json_site_mpw = json_object_new_object();
            //                fileSite._ext_mpw = json_site_mpw;
            //                if (site.url)
            //                    json_object_object_add( json_site_mpw, "url", site.url );
        }

        return this;
    }

    public MPFileUser read(@Nullable final char[] masterPassword)
            throws MPIncorrectMasterPasswordException, MPKeyUnavailableException, MPAlgorithmException {
        MPAlgorithm algorithm = ifNotNullElse( user.algorithm, MPAlgorithm.Version.CURRENT ).getAlgorithm();
        MPFileUser model = new MPFileUser(
                user.full_name, CodeUtils.decodeHex( user.key_id ), algorithm, user.avatar,
                (user.default_type != null)? user.default_type: algorithm.mpw_default_result_type(),
                (user.last_used != null)? MPConstant.dateTimeFormatter.parseDateTime( user.last_used ): new Instant(),
                MPMarshalFormat.JSON, export.redacted? MPMarshaller.ContentMode.PROTECTED: MPMarshaller.ContentMode.VISIBLE );
        model.setJSON( this );
        if (masterPassword != null)
            model.authenticate( masterPassword );

        for (final Map.Entry<String, Site> siteEntry : sites.entrySet()) {
            String siteName = siteEntry.getKey();
            Site   fileSite = siteEntry.getValue();
            MPFileSite site = new MPFileSite(
                    model, siteName, fileSite.algorithm.getAlgorithm(), UnsignedInteger.valueOf( fileSite.counter ), fileSite.type,
                    export.redacted? fileSite.password: null,
                    fileSite.login_type, export.redacted? fileSite.login_name: null,
                    (fileSite._ext_mpw != null)? fileSite._ext_mpw.url: null, fileSite.uses,
                    (fileSite.last_used != null)? MPConstant.dateTimeFormatter.parseDateTime( fileSite.last_used ): new Instant() );

            if (!export.redacted) {
                if (fileSite.password != null)
                    site.setSitePassword( (fileSite.type != null)? fileSite.type: MPResultType.StoredPersonal, fileSite.password );
                if (fileSite.login_name != null)
                    site.setLoginName( (fileSite.login_type != null)? fileSite.login_type: MPResultType.StoredPersonal,
                                       fileSite.login_name );
            }

            model.addSite( site );
        }

        return model;
    }

    // -- Data

    Export            export;
    User              user;
    Map<String, Site> sites;


    public static class Export extends MPJSONAnyObject {

        int     format;
        boolean redacted;
        @Nullable
        String date;
    }


    public static class User extends MPJSONAnyObject {

        int    avatar;
        String full_name;
        String last_used;
        @Nullable
        MPAlgorithm.Version algorithm;
        @Nullable
        String              key_id;
        @Nullable
        MPResultType        default_type;
    }


    public static class Site extends MPJSONAnyObject {

        long                counter;
        MPAlgorithm.Version algorithm;
        @Nullable
        MPResultType type;
        @Nullable
        String       password;
        @Nullable
        MPResultType login_type;
        @Nullable
        String       login_name;

        int uses;
        @Nullable
        String last_used;

        @Nullable
        Map<String, Question> questions;

        @Nullable
        Ext _ext_mpw;


        public static class Ext extends MPJSONAnyObject {

            @Nullable
            String url;
        }


        public static class Question extends MPJSONAnyObject {

            @Nullable
            MPResultType type;
            @Nullable
            String       answer;
        }
    }
}

