using Toybox.Application as App;
using Toybox.Graphics;
using Toybox.WatchUi as Ui;
using Toybox.Time;

class EmptyAuthenticatorView extends Ui.View {

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
        account = newAccount;
    }

    function onMenuItem(item) {
        if (item == :add_account) {
            Ui.pushView(new Ui.TextPicker("Name"), new AccountCreateDelegate(), Ui.SLIDE_LEFT);
        } else if (item == :delete_account) {
            Ui.pushView(new Ui.Confirmation("Delete account?"), new AccountDeletionConfirmationDelegate(account), Ui.SLIDE_IMMEDIATE);
        }
    }
}

class AccountDeletionConfirmationDelegate {
    hidden var account;

    function initialize(newAccount) {
        account = newAccount;
    }

    function onResponse(confirmation) {
        if (confirmation == Ui.CONFIRM_YES) {
            App.getApp().deleteAccount(App.getApp().getAccount().name);
            var account = App.getApp().getAccount();
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

class AccountCreateDelegate extends Ui.TextPickerDelegate {
    function onTextEntered(text) {
        Ui.pushView(new Ui.TextPicker("Code"), new AccountSetCodeDelegate(text), Ui.SLIDE_LEFT);
    }
}

class AccountSetCodeDelegate extends Ui.TextPickerDelegate {
    var name;
    function initialize(newName) {
        name = newName;
    }
    function onTextEntered(text) {
        Ui.popView(Ui.SLIDE_IMMEDIATE);
        var account = new AccountInfo(name, text);
        App.getApp().saveAccount(account);
        Ui.switchToView(new AccountView(account), new AccountDelegate(account), Ui.SLIDE_IMMEDIATE);
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

    //! onStart() is called on application start up
    function onStart() {
    }

    //! onStop() is called when your application is exiting
    function onStop() {
    }

    var accounts = [];

    //! Return the initial view of your application here
    function getInitialView() {
        loadProperties();
        accounts = orElse(getProperty("accounts"), []); // TODO multi-account
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
        if (id == -1) {
            accounts = Crypto.concatArrays(accounts, [ repr ]);
            currentAccount = accounts.size() - 1;
        } else {
            accounts[i] = repr;
        }
        updateAccounts(accounts);
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

    hidden function orElse(a, b) {
        if (a == null) {
          return b;
        } else {
          return a;
        }
    }

}