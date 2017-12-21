// This code was taken from the Picker sample in the
// Garmin's SDK. The SDK sample license, as stated in
// the SDK version 2.4.1 applies:
//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;

class CharacterFactory extends Ui.PickerFactory {
    hidden var mCharacterSet;
    hidden var mAddOk;
    const DONE = -1;

    function initialize(characterSet, options) {
        PickerFactory.initialize();
        mCharacterSet = characterSet;
        mAddOk = (null != options) and (options.get(:addOk) == true);
    }

    function getIndex(value) {
        var index = mCharacterSet.find(value);
        return index;
    }

    function getSize() {
        return mCharacterSet.length() + ( mAddOk ? 1 : 0 );
    }

    function getValue(index) {
        if(index == mCharacterSet.length()) {
            return DONE;
        }

        return mCharacterSet.substring(index, index+1);
    }

    function getDrawable(index, selected) {
        if(index == mCharacterSet.length()) {
            return new Ui.Text( {:text=>Rez.Strings.characterPickerOk, :color=>Gfx.COLOR_WHITE, :font=>Gfx.FONT_LARGE, :locX =>Ui.LAYOUT_HALIGN_CENTER, :locY=>Ui.LAYOUT_VALIGN_CENTER } );
        }

        return new Ui.Text( { :text=>getValue(index), :color=>Gfx.COLOR_WHITE, :font=> Gfx.FONT_LARGE, :locX =>Ui.LAYOUT_HALIGN_CENTER, :locY=>Ui.LAYOUT_VALIGN_CENTER } );
    }

    function isDone(value) {
        return mAddOk and (value == DONE);
    }
}
