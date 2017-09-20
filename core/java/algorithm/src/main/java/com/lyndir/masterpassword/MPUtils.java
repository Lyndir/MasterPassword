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

import com.google.common.primitives.UnsignedInteger;
import java.nio.ByteBuffer;


/**
 * @author lhunath, 2017-09-20
 */
public final class MPUtils {

    public static byte[] bytesForInt(final int number) {
        return ByteBuffer.allocate( Integer.SIZE / Byte.SIZE ).order( MasterKeyV0.mpw_byteOrder ).putInt( number ).array();
    }

    public static byte[] bytesForInt(final UnsignedInteger number) {
        return ByteBuffer.allocate( Integer.SIZE / Byte.SIZE ).order( MasterKeyV0.mpw_byteOrder ).putInt( number.intValue() ).array();
    }

    public static byte[] idForBytes(final byte[] bytes) {
        return MasterKeyV0.mpw_hash.of( bytes );
    }
}
