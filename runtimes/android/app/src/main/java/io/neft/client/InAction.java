package io.neft.client;

public enum InAction {
    // basic
    CALL_FUNCTION,

    // renderer
    DEVICE_LOG,
    DEVICE_SHOW_KEYBOARD,
    DEVICE_HIDE_KEYBOARD,

    SET_WINDOW,

    CREATE_ITEM,
    SET_ITEM_PARENT,
    INSERT_ITEM_BEFORE,
    SET_ITEM_VISIBLE,
    SET_ITEM_CLIP,
    SET_ITEM_WIDTH,
    SET_ITEM_HEIGHT,
    SET_ITEM_X,
    SET_ITEM_Y,
    SET_ITEM_SCALE,
    SET_ITEM_ROTATION,
    SET_ITEM_OPACITY,
    SET_ITEM_BACKGROUND,
    SET_ITEM_KEYS_FOCUS,

    CREATE_IMAGE,
    SET_IMAGE_SOURCE,
    SET_IMAGE_SOURCE_WIDTH,
    SET_IMAGE_SOURCE_HEIGHT,
    SET_IMAGE_FILL_MODE,
    SET_IMAGE_OFFSET_X,
    SET_IMAGE_OFFSET_Y,

    CREATE_TEXT,
    SET_TEXT,
    SET_TEXT_WRAP,
    UPDATE_TEXT_CONTENT_SIZE,
    SET_TEXT_COLOR,
    SET_TEXT_LINE_HEIGHT,
    SET_TEXT_FONT_FAMILY,
    SET_TEXT_FONT_PIXEL_SIZE,
    SET_TEXT_FONT_WORD_SPACING,
    SET_TEXT_FONT_LETTER_SPACING,
    SET_TEXT_ALIGNMENT_HORIZONTAL,
    SET_TEXT_ALIGNMENT_VERTICAL,

    CREATE_TEXT_INPUT,
    SET_TEXT_INPUT_TEXT,
    SET_TEXT_INPUT_COLOR,
    SET_TEXT_INPUT_LINE_HEIGHT,
    SET_TEXT_INPUT_MULTI_LINE,
    SET_TEXT_INPUT_ECHO_MODE,
    SET_TEXT_INPUT_FONT_FAMILY,
    SET_TEXT_FONT_INPUT_PIXEL_SIZE,
    SET_TEXT_FONT_INPUT_WORD_SPACING,
    SET_TEXT_FONT_INPUT_LETTER_SPACING,
    SET_TEXT_INPUT_ALIGNMENT_HORIZONTAL,
    SET_TEXT_INPUT_ALIGNMENT_VERTICAL,

    CREATE_NATIVE_ITEM,
    ON_NATIVE_ITEM_POINTER_PRESS,
    ON_NATIVE_ITEM_POINTER_RELEASE,
    ON_NATIVE_ITEM_POINTER_MOVE,

    LOAD_FONT,

    CREATE_RECTANGLE,
    SET_RECTANGLE_COLOR,
    SET_RECTANGLE_RADIUS,
    SET_RECTANGLE_BORDER_COLOR,
    SET_RECTANGLE_BORDER_WIDTH
}
