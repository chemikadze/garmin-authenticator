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
        var menu = new Rez.Menus.AccountsMenu();
        Ui.pushView(menu, new AccountsMenuDelegate(), Ui.SLIDE_RIGHT);
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
        nameLabel.setText(account.name);
        var codeLabel = findDrawableById("code_label");
        codeLabel.setText(account.generateToken());
        View.onUpdate(dc);
        var timeLeft = account.timeLeftPercent();
        drawBar(dc, timeLeft);
    }

    hidden function drawBar(dc, percent) {
        var xPadding = 70;
        var barY = 135;
        var barWidth = dc.getWidth() - xPadding * 2;
        dc.setPenWidth(2);
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
    function initialize(account) {
        // TODO
    }

    function onMenu() {
        var menu = new Rez.Menus.AccountsMenu();
        Ui.pushView(menu, new AccountsMenuDelegate(), Ui.SLIDE_RIGHT);
        return true;
    }
}

class AccountsMenuDelegate extends Ui.MenuInputDelegate {
    function onMenuItem(item) {
        if (item == :add_account) {
            Ui.pushView(new Ui.TextPicker("Account"), new AccountCreateDelegate(), Ui.SLIDE_LEFT);
        }
    }
}

class AccountCreateDelegate extends Ui.TextPickerDelegate {
    function onTextEntered(text) {
        Ui.pushView(new Ui.TextPicker("sxt33fkcmwsw4jds"), new AccountSetCodeDelegate(text), Ui.SLIDE_LEFT);
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
        Ui.switchToView(new AccountView(account), new AccountDelegate(account), Ui.SLIDE_LEFT);
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
            var accountData = accounts[0];
            var account = new AccountInfo(accountData["name"], accountData["secrete"]);
            return [ new AccountView(account), new AccountDelegate(account) ];
        }
    }

    function saveAccount(account) {
        accounts = [ {"name" => account.name, "secrete" => account.key} ];
        setProperty("accounts", accounts);
        saveProperties();
    }

    hidden function orElse(a, b) {
        if (a == null) {
          return b;
        } else {
          return a;
        }
    }

}