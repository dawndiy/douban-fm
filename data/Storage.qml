import QtQuick 2.4
import QtQuick.LocalStorage 2.0

Item {
    property var db: null;

    /**
     * Open database
     */
    function openDB() {
        if (db != null) return;
        db = LocalStorage.openDatabaseSync("douban-fm", "", "StorageDatabase", 10000000)
        // NOTE: deal version if do some update
        console.debug("[DATABASE]:", db.version)

        if (db.version === "") {
            db.changeVersion("", "1.0", function(tx) {
                console.log('Database created');
            });
            // reopen database with new version number
            db = LocalStorage.openDatabaseSync("douban-fm", "", "StorageDatabase", 100000);
        }

        // from this version, change db version to app version
        if (db.version === "1.0") {
            db.changeVersion("1.0", "0.2.0", function(tx) {
                tx.executeSql("drop table if exists weibo");
                tx.executeSql("create table if not exists weibo(uid text, screen_name text, access_token text, expire integer, updated integer)")
                console.log("[DATABASE]: Database upgraded to v0.2.0");
            });
            // reopen database with new version number
            db = LocalStorage.openDatabaseSync("douban-fm", "", "StorageDatabase", 100000);
        }

        if (db.version === "0.2.0") {
            db.changeVersion("0.2.0", "0.2.2", function(tx) {
                tx.executeSql("drop table if exists user");
                tx.executeSql("create table if not exists user(id text, uid text, name text, expires text, dbcl2 text)");
                console.log("[DATABASE]: Database upgraded to v0.2.2");
            });
            // reopen database with new version number
            db = LocalStorage.openDatabaseSync("douban-fm", "", "StorageDatabase", 100000);
        }
    }

    /**
     * Save Douban user infomation
     */
    function saveDoubanUser(user) {
        openDB();
        db.transaction(function(tx) {
            //tx.executeSql("create table if not exists user(user_id text, token text, expire text, user_name text, email text)");
            tx.executeSql("delete from user");
            tx.executeSql(
                "insert into user values(?, ?, ?, ?, ?)", 
                [user.uid, user.id, user.name, user.expires, user.dbcl2]);
        });
    }

    /**
     * Get Douban user
     */
    function getDoubanUser() {
        openDB();
        var user;
        db.transaction(function(tx) {
            //tx.executeSql("create table if not exists user(user_id text, token text, expire text, user_name text, email text)");
            //var rs = tx.executeSql("select user_id, token, expire, user_name, email from user");
            var rs = tx.executeSql("select uid, id, name, expires, dbcl2 from user");
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
            //tx.executeSql("create table if not exists user(user_id text, token text, expire text, user_name text, email text)");
            tx.executeSql("delete from user");
        });
    }

    /**
     * Save Weibo user
     */
    function saveWeiboUser(uid, screen_name, access_token, expire, updated) {
        openDB()
        db.transaction(function(tx) {
            tx.executeSql("create table if not exists weibo(uid text, screen_name text, access_token text, expire integer, updated integer)")
            tx.executeSql("delete from weibo");
            tx.executeSql("insert into weibo values(?, ?, ?, ?, ?)", [uid, screen_name, access_token, expire, updated])
        });
    }

    /**
     * Get Weibo user
     */
    function getWeiboUser() {
        openDB();
        var user;
        db.transaction(function(tx) {
            tx.executeSql("create table if not exists weibo(uid text, screen_name text, access_token text, expire integer, updated integer)")
            var rs = tx.executeSql("select uid, screen_name, access_token, expire, updated from weibo");
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
            tx.executeSql("create table if not exists weibo(uid text, screen_name text, access_token text, expire integer, updated integer)")
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
