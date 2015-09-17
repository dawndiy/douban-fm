import QtQuick 2.4
import QtQuick.LocalStorage 2.0

Item {
    property var db: null;

    /**
     * Open database
     */
    function openDB() {
        if (db != null) return;
        db = LocalStorage.openDatabaseSync("douban-fm", "1.0", "StorageDatabase", 10000000)
        // NOTE: deal version if do some update
    }

    /**
     * Save Douban user infomation
     */
    function saveDoubanUser(user) {
        openDB();
        db.transaction(function(tx) {
            tx.executeSql("create table if not exists user(user_id text, token text, expire text, user_name text, email text)");
            tx.executeSql("delete from user");
            tx.executeSql(
                "insert into user values(?, ?, ?, ?, ?)", 
                [user.user_id, user.token, user.expire, user.user_name, user.email]);
        });
    }

    /**
     * Get Douban user
     */
    function getDoubanUser() {
        openDB();
        var user;
        db.transaction(function(tx) {
            tx.executeSql("create table if not exists user(user_id text, token text, expire text, user_name text, email text)");
            var rs = tx.executeSql("select user_id, token, expire, user_name, email from user");
            if (rs.rows.length != 0) {
                user = rs.rows.item(0);
            }
        });
        return user;
    }
    /**
     * Delete Douban user
     */
    function clearDoubanUser() {
        openDB();
        db.transaction(function(tx) {
            tx.executeSql("create table if not exists user(user_id text, token text, expire text, user_name text, email text)");
            tx.executeSql("delete from user");
        });
    }

    /**
     * Save Weibo user
     */
    function saveWeiboUser(uid, screen_name, access_token) {
        openDB()
        db.transaction(function(tx) {
            tx.executeSql("create table if not exists weibo(uid text, screen_name, access_token text)");
            tx.executeSql("delete from weibo");
            tx.executeSql("insert into weibo values(?, ?, ?)", [uid, screen_name, access_token])
        });
    }

    /**
     * Get Weibo user
     */
    function getWeiboUser() {
        openDB();
        var user;
        db.transaction(function(tx) {
            tx.executeSql("create table if not exists weibo(uid text, screen_name, access_token text)");
            var rs = tx.executeSql("select uid, screen_name, access_token from weibo");
            if (rs.rows.length != 0) {
                user = rs.rows.item(0);
            }
        });
        return user;
    }

    /**
     * Delete Weibo user
     */
    function clearWeiboUser() {
        openDB();
        db.transaction(function(tx) {
            tx.executeSql("create table if not exists weibo(uid text, screen_name, access_token text)");
            tx.executeSql("delete from weibo");
        });
    }

    /**
     * Get configuration
     */
    function getConfig(name) {
        openDB();
        var config;
        db.transaction(function(tx) {
            tx.executeSql("create table if not exists config(name text, value text)");
            var rs = tx.executeSql("select value from config where name=?", [name]);
            if (rs.rows.length != 0) {
                config = rs.rows.item(0);
            }
        });
        if (config) {
            return config.value;
        } else {
            return null;
        }
    }

    /**
     * Save configuration
     */
    function setConfig(name, value) {
        openDB();
        db.transaction(function(tx) {
            tx.executeSql("create table if not exists config(name text, value text)");
            tx.executeSql("delete from config where name=?", [name])
            tx.executeSql("insert into config values(?,?)", [name, value])
        });
    }
}
