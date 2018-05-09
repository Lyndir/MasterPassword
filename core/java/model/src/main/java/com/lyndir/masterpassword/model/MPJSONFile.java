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

package com.lyndir.masterpassword.model;

import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.CodeUtils;
import com.lyndir.masterpassword.*;
import java.util.LinkedHashMap;
import java.util.Map;
import javax.annotation.Nullable;
import org.joda.time.Instant;


/**
 * @author lhunath, 2018-04-27
 */
public class MPJSONFile {

    public MPJSONFile(final MPFileUser user)
            throws MPKeyUnavailableException {
        // Section: "export"
        Export fileExport = this.export = new Export();
        fileExport.format = 1;
        fileExport.redacted = user.getContentMode().isRedacted();
        fileExport.date = MPConstant.dateTimeFormatter.print( new Instant() );

        // Section: "user"
        User fileUser = this.user = new User();
        fileUser.avatar = user.getAvatar();
        fileUser.full_name = user.getFullName();

        fileUser.last_used = MPConstant.dateTimeFormatter.print( user.getLastUsed() );
        fileUser.key_id = CodeUtils.encodeHex( user.getKeyID() );

        fileUser.algorithm = user.getAlgorithm().version();
        fileUser.default_type = user.getDefaultType();

        // Section "sites"
        sites = new LinkedHashMap<>();
        for (final MPFileSite site : user.getSites()) {
            Site   fileSite;
            String content = null, loginContent = null;
            if (!fileExport.redacted) {
                // Clear Text
                content = site.getResult();
                loginContent = user.getMasterKey().siteResult(
                        site.getSiteName(), site.getAlgorithm().mpw_default_counter(),
                        MPKeyPurpose.Identification, null, site.getLoginType(), site.getLoginState(), site.getAlgorithm() );
            } else {
                // Redacted
                if (site.getResultType().supportsTypeFeature( MPSiteFeature.ExportContent ))
                    content = site.getSiteState();
                if (site.getLoginType().supportsTypeFeature( MPSiteFeature.ExportContent ))
                    loginContent = site.getLoginState();
            }

            sites.put( site.getSiteName(), fileSite = new Site() );
            fileSite.type = site.getResultType();
            fileSite.counter = site.getSiteCounter().longValue();
            fileSite.algorithm = site.getAlgorithm().version();
            fileSite.password = content;
            fileSite.login_name = loginContent;
            fileSite.login_type = site.getLoginType();

            fileSite.uses = site.getUses();
            fileSite.last_used = MPConstant.dateTimeFormatter.print( site.getLastUsed() );

            fileSite._ext_mpw = new Site.Ext();
            fileSite._ext_mpw.url = site.getUrl();

            fileSite.questions = new LinkedHashMap<>();
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
    }

    public MPFileUser toUser(@Nullable final char[] masterPassword)
            throws MPIncorrectMasterPasswordException, MPKeyUnavailableException {
        MPFileUser user = new MPFileUser(
                this.user.full_name, CodeUtils.decodeHex( this.user.key_id ), this.user.algorithm.getAlgorithm(),
                this.user.avatar, this.user.default_type, MPConstant.dateTimeFormatter.parseDateTime( this.user.last_used ),
                MPMarshalFormat.JSON, export.redacted? MPMarshaller.ContentMode.PROTECTED: MPMarshaller.ContentMode.VISIBLE );
        if (masterPassword != null)
            user.authenticate( masterPassword );

        for (final Map.Entry<String, Site> siteEntry : sites.entrySet()) {
            String siteName = siteEntry.getKey();
            Site   fileSite = siteEntry.getValue();
            MPFileSite site = new MPFileSite(
                    user, siteName, export.redacted? fileSite.password: null, UnsignedInteger.valueOf( fileSite.counter ),
                    fileSite.type, fileSite.algorithm.getAlgorithm(),
                    export.redacted? fileSite.login_name: null, fileSite.login_type,
                    fileSite._ext_mpw.url, fileSite.uses, MPConstant.dateTimeFormatter.parseDateTime( fileSite.last_used ) );

            if (!export.redacted) {
                if (fileSite.password != null)
                    site.setSitePassword( fileSite.type, fileSite.password );
                if (fileSite.login_name != null)
                    site.setLoginName( fileSite.login_type, fileSite.login_name );
            }

            user.addSite( site );
        }

        return user;
    }

    // -- Data

    Export            export;
    User              user;
    Map<String, Site> sites;


    public static class Export {

        int     format;
        boolean redacted;
        String  date;
    }


    public static class User {

        int                 avatar;
        String              full_name;
        String              last_used;
        String              key_id;
        MPMasterKey.Version algorithm;
        MPResultType        default_type;
    }


    public static class Site {

        MPResultType        type;
        long                counter;
        MPMasterKey.Version algorithm;
        @Nullable
        String password;
        @Nullable
        String login_name;
        MPResultType login_type;
        int          uses;
        String       last_used;

        Map<String, Question> questions;

        Ext _ext_mpw;


        public static class Ext {

            @Nullable
            String url;
        }


        public static class Question {

            MPResultType type;
            String       answer;
        }
    }
}
