package io.neft.Utils;

public class StringUtils {
    static public String capitalize(String str) {
        return str.substring(0, 1).toUpperCase() + str.substring(1);
    }
}
