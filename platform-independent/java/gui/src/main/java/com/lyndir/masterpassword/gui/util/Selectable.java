package com.lyndir.masterpassword.gui.util;

import java.util.function.Consumer;
import javax.annotation.Nullable;


/**
 * @author lhunath, 2018-07-26
 */
public interface Selectable<E, T> {

    T selection(@Nullable Consumer<E> selectionConsumer);

    T selection(@Nullable E selectedItem, @Nullable Consumer<E> selectionConsumer);
}
