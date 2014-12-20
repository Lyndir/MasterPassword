uint8_t *mpw_masterKeyForUser(
        const char *fullName, const char *masterPassword);

char *mpw_passwordForSite(
        const uint8_t *masterKey, const char *siteName, const MPSiteType siteType, const uint32_t siteCounter,
        const MPSiteVariant siteVariant, const char *siteContext);
