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

#ifndef _MPW_ALGORITHM_V1_H
#define _MPW_ALGORITHM_V1_H

#include "mpw-algorithm_v0.h"

const char *mpw_type_template_v1(
        MPResultType type, uint16_t templateIndex);
const char mpw_class_character_v1(
        char characterClass, uint16_t classIndex);
MPMasterKey mpw_master_key_v1(
        const char *fullName, const char *masterPassword);
MPSiteKey mpw_site_key_v1(
        MPMasterKey masterKey, const char *siteName, MPCounterValue siteCounter,
        MPKeyPurpose keyPurpose, const char *keyContext);
const char *mpw_site_template_password_v1(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *resultParam);
const char *mpw_site_crypted_password_v1(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *cipherText);
const char *mpw_site_derived_password_v1(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *resultParam);
const char *mpw_site_state_v1(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *plainText);

#endif // _MPW_ALGORITHM_V1_H
