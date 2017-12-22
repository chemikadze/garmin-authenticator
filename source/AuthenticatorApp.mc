using Toybox.Application as App;
using Toybox.Graphics;
using Toybox.WatchUi as Ui;
using Toybox.Time;
using Toybox.Communications;
using Toybox.System as Sys;

class EmptyAuthenticatorView extends Ui.View {

    function initialize() {
        Ui.View.initialize();
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.EmptyLayout(dc));
    }

    function onShow() {
    }

    function onUpdate(dc) {
        View.onUpdate(dc);
    }

    function onHide() {
    }

}

class EmptyAuthenticatorDelegate extends Ui.BehaviorDelegate {

    function initialize() {
        Ui.BehaviorDelegate.initialize();
    }

    function onMenu() {
        var menu = new Rez.Menus.EmptyMenu();
        Ui.pushView(menu, new AccountsMenuDelegate(null), Ui.SLIDE_RIGHT);
        return true;
    }
}

class AccountView extends Ui.View {

    var account;
    var timer;

    function initialize(newAccount) {
        Ui.View.initialize();

        account = newAccount;
        timer = new Toybox.Timer.Timer();
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.AccountLayout(dc));
    }

    hidden function requestUpdate() {
        Ui.requestUpdate();
    }

    function onShow() {
        timer.start(method(:requestUpdate), 1000, true);
    }

    function onUpdate(dc) {
        var nameLabel = findDrawableById("name_label");
        var codeLabel = findDrawableById("code_label");
        var token = account.generateToken();
        codeLabel.setText(token);
        var nameLabelDimensions = dc.getTextDimensions(account.name, Graphics.FONT_MEDIUM);
        var codeLabelDimensions = dc.getTextDimensions(token, Graphics.FONT_NUMBER_HOT);
        nameLabel.setText(account.name);
        nameLabel.setLocation(nameLabel.locX, codeLabel.locY - nameLabelDimensions[1]);
        var timeLeft = account.timeLeftPercent();
        View.onUpdate(dc);
        var barY = codeLabel.locY + codeLabelDimensions[1] + nameLabelDimensions[1] / 2;
        var xPadding = (dc.getWidth() - codeLabelDimensions[0]) / 2 + 15;
        drawBar(dc, timeLeft, xPadding, barY);
    }

    hidden function drawBar(dc, percent, xPadding, barY) {
        var barWidth = dc.getWidth() - xPadding * 2;
        dc.setPenWidth(3);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
        dc.drawLine(xPadding, barY, xPadding + barWidth, barY);
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_BLACK);
        dc.drawLine(xPadding, barY, xPadding + barWidth * percent / 100, barY);
    }

    function onHide() {
        timer.stop();
    }

}

class AccountDelegate extends Ui.BehaviorDelegate {
    hidden var account;

    function initialize(newAccount) {
        Ui.BehaviorDelegate.initialize();

        account = newAccount;
    }

    function onMenu() {
        var menu = new Rez.Menus.AccountsMenu();
        Ui.pushView(menu, new AccountsMenuDelegate(account), Ui.SLIDE_RIGHT);
        return true;
    }

    function onKey(key) {
        if ((key.getKey() == Ui.KEY_ENTER) and (key.getType() == Ui.PRESS_TYPE_ACTION)) {
            var account = App.getApp().getNextAccount();
            Ui.switchToView(new AccountView(account), new AccountDelegate(account), Ui.SLIDE_IMMEDIATE);
        }
    }

}

class AccountsMenuDelegate extends Ui.MenuInputDelegate {
    hidden var account;

    function initialize(newAccount) {
        MenuInputDelegate.initialize();
        account = newAccount;
    }

    function onMenuItem(item) {
        if (Ui has :TextPicker) {
            if (item == :add_account) {
                Ui.pushView(new Ui.TextPicker("Name"),
                    new AccountCreateDelegate(), Ui.SLIDE_LEFT);
            } else if (item == :rename_account) {
                Ui.pushView(new Ui.TextPicker(account.name), new AccountRenameDelegate(account), Ui.SLIDE_LEFT);
            } else if (item == :delete_account) {
                Ui.pushView(new Ui.Confirmation("Delete " + account.name + "?"), new AccountDeletionConfirmationDelegate(account), Ui.SLIDE_IMMEDIATE);
            }
        } else {
            // Vivoactive 3 has no support for TextPicker
            if (item == :add_account || item == :rename_account) {
                var picker = new StringPicker(Rez.Strings.accountNamePickerTitle, "account");
                Ui.pushView(picker, new AccountCreateFromPickerDelegate(picker), Ui.SLIDE_IMMEDIATE);
            } else if (item == :delete_account) {
                System.println("Delete account");

                Ui.pushView(new Ui.Confirmation("Delete " + account.name + "?"),
                    new AccountDeletionConfirmationDelegate(account), Ui.SLIDE_IMMEDIATE);
            }
        }
    }
}

class AccountDeletionConfirmationDelegate extends Ui.ConfirmationDelegate {
    hidden var account;

    function initialize(newAccount) {
        Ui.ConfirmationDelegate.initialize();

        account = newAccount;
    }

    function onResponse(confirmation) {
        if (confirmation == Ui.CONFIRM_YES) {
            System.println("Removing account: " + App.getApp().getCurrentAccount().name);
            App.getApp().deleteAccount(App.getApp().getCurrentAccount().name);
            var account = App.getApp().getCurrentAccount();
            if (account != null) {
                Ui.switchToView(new AccountView(account), new AccountDelegate(account), Ui.SLIDE_IMMEDIATE);
            } else {
                Ui.switchToView(new EmptyAuthenticatorView(), new EmptyAuthenticatorDelegate(), Ui.SLIDE_IMMEDIATE);
            }
        } else {
            Ui.switchToView(new AccountView(account), new AccountDelegate(account), Ui.SLIDE_IMMEDIATE);
        }

    }
}

class AccountAddConfirmationDelegate extends Ui.ConfirmationDelegate {
    hidden var account;

    function initialize(newAccount) {
        Ui.ConfirmationDelegate.initialize();

        account = newAccount;
    }

    function onResponse(confirmation) {
        if (confirmation == Ui.CONFIRM_YES) {
            App.getApp().saveAccount(account);
            Ui.switchToView(new AccountView(account), new AccountDelegate(account), Ui.SLIDE_IMMEDIATE);
        } else {
            var account = App.getApp().getCurrentAccount();
            Ui.switchToView(new AccountView(account), new AccountDelegate(account), Ui.SLIDE_IMMEDIATE);
        }

    }
}

class AccountCreateDelegate extends Ui.TextPickerDelegate {
    function initialize() {
        Ui.TextPickerDelegate.initialize();
    }

    function onTextEntered(text, changed) {
        Ui.pushView(new CodeDisclaimerView(), new CodeDisclaimerDelegate(text), Ui.SLIDE_LEFT);
    }
}

class AccountCreateFromPickerDelegate extends Ui.PickerDelegate {
    hidden var mPicker;

    function initialize(picker) {
        PickerDelegate.initialize();

        mPicker = picker;
    }

    function onCancel() {
        if(0 == mPicker.getTitleLength()) {
            Ui.popView(Ui.SLIDE_IMMEDIATE);
        }
        else {
            mPicker.removeCharacter();
        }
    }

    function onAccept(values) {
        if(!mPicker.isDone(values[0])) {
            mPicker.addCharacter(values[0]);
        }
        else {

            if(mPicker.getTitle().length() == 0) {
                App.getApp().deleteProperty("account");
            }
            else {
                var text = mPicker.getTitle();
                System.println("Data " + text);

                App.getApp().setProperty("account", text);

                Ui.popView(Ui.SLIDE_IMMEDIATE);

                Ui.pushView(new CodeDisclaimerView(),
                    new CodeDisclaimerDelegate(text),
                    Ui.SLIDE_LEFT);
            }

        }
    }
}

class AccountRenameDelegate extends Ui.TextPickerDelegate {
    hidden var account;

    function initialize(newAccount) {
        Ui.TextPickerDelegate.initialize();

        account = newAccount;
    }

    function onTextEntered(text) {
        App.getApp().renameCurrentAccount(account.name, text);
        var account = App.getApp().getCurrentAccount();
        Ui.switchToView(new AccountView(account), new AccountDelegate(account), Ui.SLIDE_IMMEDIATE);
    }
}

class CodeDisclaimerView extends Ui.View {
    function initialize() {
        Ui.View.initialize();
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.CodeDisclaimerLayout(dc));
    }

    function onShow() {
    }

    function onUpdate(dc) {
        View.onUpdate(dc);
    }

    function onHide() {
    }

}

class CodeDisclaimerDelegate extends Ui.BehaviorDelegate {
    var name;

    function initialize(newName) {
        Ui.BehaviorDelegate.initialize();

        name = newName;
    }

    function onKey(key) {
        if (Ui has :TextPicker) {
            if ((key.getKey() == Ui.KEY_ENTER) and (key.getType() == Ui.PRESS_TYPE_ACTION)) {
                Ui.pushView(new Ui.TextPicker("Code"),
                new AccountSetCodeDelegate(name, ""), Ui.SLIDE_LEFT);
            }
        }
        else {
            var picker = new StringPicker(Rez.Strings.codePickerTitle, "code");

            Ui.pushView(picker, new AccountSetCodeFromPickerDelegate(picker, name, ""), Ui.SLIDE_LEFT);
        }


    }
}

class AccountSetCodeDelegate extends Ui.TextPickerDelegate {
    var name, code;

    function initialize(newName, codeAcc) {
        Ui.TextPickerDelegate.initialize();

        name = newName;
        code = codeAcc;
    }
    function onTextEntered(text) {
        Ui.popView(Ui.SLIDE_IMMEDIATE);
        if (text.length() == 31) { // ask the rest
            Ui.pushView(new Ui.TextPicker(""), new AccountSetCodeDelegate(name, text), Ui.SLIDE_LEFT);
        } else {
            var account = new AccountInfo(name, code + text);
            App.getApp().saveAccount(account);
            Ui.switchToView(new AccountView(account), new AccountDelegate(account), Ui.SLIDE_IMMEDIATE);
        }
    }
}

class AccountSetCodeFromPickerDelegate extends Ui.PickerDelegate {
    hidden var mPicker;
    var name, code;

    function initialize(picker, newName, codeAcc) {
        PickerDelegate.initialize();
        mPicker = picker;

        name = newName;
        code = codeAcc;
    }

    function onCancel() {
        if(0 == mPicker.getTitleLength()) {
            Ui.popView(Ui.SLIDE_IMMEDIATE);
        }
        else {
            mPicker.removeCharacter();
        }
    }

    function onAccept(values) {
        if(!mPicker.isDone(values[0])) {
            mPicker.addCharacter(values[0]);
        }
        else {

            if(mPicker.getTitle().length() == 0) {
                App.getApp().deleteProperty("code");
            }
            else {
                var text = mPicker.getTitle();
                System.println("Code " + text);

                App.getApp().setProperty("code", text);

                 var account = new AccountInfo(name, code + text);
                 App.getApp().saveAccount(account);
                 Ui.switchToView(new AccountView(account),
                    new AccountDelegate(account), Ui.SLIDE_IMMEDIATE);
            }

        }
    }

}

class AccountInfo {

    var name, key, totp;

    function initialize(newName, newKey) {
        name = newName;
        key = newKey;
        totp = new Crypto.TOTP(key);
    }

    function generateToken() {
        return totp.generateToken();
    }

    function timeLeftPercent() {
        return 100.0 * totp.timeToNextUpdate() / totp.updateInterval();
    }

}


class AuthenticatorApp extends App.AppBase {
    function initialize() {
        App.AppBase.initialize();
    }


    //! onStart() is called on application start up
    function onStart(state) {
    }

    function mailboxListener(iterator) {
        var msg = iterator.next();
        while (msg != null) {
            if (msg instanceof Toybox.Lang.Dictionary && msg.hasKey("name") && msg.hasKey("code")) {
                var account = new AccountInfo(msg.get("name"), msg.get("code"));
                Ui.pushView(new Ui.Confirmation("Add " + account.name + "?"), new AccountAddConfirmationDelegate(account), Ui.SLIDE_IMMEDIATE);
            }
            msg = iterator.next();
        }
        Communications.emptyMailbox();
    }

    //! onStop() is called when your application is exiting
    function onStop(state) {
    }

    var accounts = [];

    //! Return the initial view of your application here
    function getInitialView() {
        loadProperties();
        accounts = orElse(getProperty("accounts"), []); // TODO multi-account
        Communications.setMailboxListener(method(:mailboxListener));
        if (accounts.size() == 0) {
            return [ new EmptyAuthenticatorView(), new EmptyAuthenticatorDelegate() ];
        } else {
            var account = getAccount(0);
            return [ new AccountView(account), new AccountDelegate(account) ];
        }
    }

    function saveAccount(account) {
        var id = findByName(accounts, account.name);
        var repr = {"name" => account.name, "secrete" => account.key};
        accounts = Crypto.concatArrays(accounts, [ repr ]);
        currentAccount = accounts.size() - 1;
        updateAccounts(accounts);
    }

    function renameCurrentAccount(oldName, newName) {
        if (accounts[currentAccount]["name"] == oldName) {
            accounts[currentAccount]["name"] = newName;
            updateAccounts(accounts);
        }
    }

    function findByName(accounts, name) {
        for (var i = 0; i < accounts.size(); ++i) {
            if (accounts[i]["name"] == name) {
                return i;
            }
        }
        return -1;
    }

    function deleteAccount(accountName) {
        var id = findByName(accounts, accountName);
        if (id != -1) {
            updateAccounts(removeById(accounts, id));
        }
        if (currentAccount == accounts.size()) {
            --currentAccount;
        }
    }

    function removeById(array, id) {
        var output = new[array.size() - 1];
        for (var i = 0; i < id; ++i) {
            output[i] = array[i];
        }
        for (var i = id + 1; i < array.size(); ++i) {
            output[i - 1] = array[i];
        }
        return output;
    }

    function updateAccounts(newAccounts) {
        accounts = newAccounts;
        setProperty("accounts", newAccounts);
        saveProperties();
    }

    hidden var currentAccount = 0;
    function getNextAccount() {
        currentAccount = (currentAccount + 1) % accounts.size();
        return getAccount(currentAccount);
    }

    function getAccount(id) {
        System.println("Looking for account");
        System.println("Looking for account => " + id);

        if (id == null) {
            id = currentAccount;
        }
        if (accounts.size() == 0) {
            return null;
        }
        var accountData = accounts[id];
        var account = new AccountInfo(accountData["name"], accountData["secrete"]);
        return account;
    }

    function getCurrentAccount() {
        return getAccount(null);
    }



    hidden function orElse(a, b) {
        if (a == null) {
          return b;
        } else {
          return a;
        }
    }

}