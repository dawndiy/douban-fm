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
            db.changeVersion("0.2.0", "0.2.1", function(tx) {
                tx.executeSql("drop table if exists user");
                tx.executeSql("create table if not exists user(id text, uid text, name text, expires text, dbcl2 text)");
                tx.executeSql("drop table if exists music");
                tx.executeSql("create table if not exists music(picture text, albumTitle text, like integer, album text, ssid text, title text, url text, artist text, subType text, length integer, sid text, aid text, company text, publicTime text, sha256 text, kbps text)");
                console.log("[DATABASE]: Database upgraded to v0.2.1");
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
            tx.executeSql("create table if not exists user(id text, uid text, name text, expires text, dbcl2 text)");
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
            tx.executeSql("create table if not exists user(id text, uid text, name text, expires text, dbcl2 text)");
            var rs = tx.executeSql("select uid, id, name, expires, dbcl2 from user");
            if (rs.rows.length != 0) {
                user = rs.rows.item(0);
            }
        });
        return user;
    }

    function getDoubanUser2(cb) {
        openDB();
        db.transaction(function(tx) {
            tx.executeSql("create table if not exists user(id text, uid text, name text, expires text, dbcl2 text)");
            var user;
            var rs = tx.executeSql("select uid, id, name, expires, dbcl2 from user");
            if (rs.rows.length != 0) {
                user = rs.rows.item(0);
                cb(user)
            } else {
                cb(null)
            }
        });
    }

    /**
     * Delete Douban user
     */
    function clearDoubanUser() {
        openDB();
        db.transaction(function(tx) {
            tx.executeSql("create table if not exists user(id text, uid text, name text, expires text, dbcl2 text)");
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

    /**
     * Get saved music
     */
    function getMusic() {
        openDB();
        var music;
        db.transaction(function(tx) {
            tx.executeSql("create table if not exists music(picture text, albumTitle text, like integer, album text, ssid text, title text, url text, artist text, subType text, length integer, sid text, aid text, company text, publicTime text, sha256 text, kbps text)");
            var rs = tx.executeSql("select picture, albumTitle, like, album, ssid, title, url, artist, subType, length, sid, aid, company, publicTime, sha256, kbps from music order by RANDOM()");
            if (rs.rows.length != 0) {
                music = rs.rows.item(0);
            }
        });
        if (music) {
            return music;
        } else {
            return null;
        }
    }

    function getMusicList() {
        openDB();
        var musicList = new Array();
        db.transaction(function(tx) {
            tx.executeSql("create table if not exists music(picture text, albumTitle text, like integer, album text, ssid text, title text, url text, artist text, subType text, length integer, sid text, aid text, company text, publicTime text, sha256 text, kbps text)");
            var rs = tx.executeSql("select picture, albumTitle, like, album, ssid, title, url, artist, subType, length, sid, aid, company, publicTime, sha256, kbps from music order by RANDOM()");
            for (var i = 0; i < rs.rows.length; i++) {
                musicList.push(rs.rows.item(i))
            }
        });
        return musicList;
    }
}
