package com.lyndir.lhunath.masterpassword;

import com.lyndir.lhunath.masterpassword.entity.*;


/**
 * <i>07 04, 2012</i>
 *
 * @author lhunath
 */
public enum MPElementTypeClass {

    Generated(MPElementGeneratedEntity.class),
    Stored(MPElementStoredEntity.class);

    private final Class<? extends MPElementEntity> entityClass;

    MPElementTypeClass(final Class<? extends MPElementEntity> entityClass) {

        this.entityClass = entityClass;
    }

    public Class<? extends MPElementEntity> getEntityClass() {

        return entityClass;
    }
}
