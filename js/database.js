/**
 * 获取数据库
 */
function getDatabase() {
  return LocalStorage.openDatabaseSync("douban-fm", "1.0", "StorageDatabase", 10000000)
}

/**
 * 保存登录的用户信息
 */
function saveUser(user) {
  var db = getDatabase();
  db.transaction(function(tx) {
    tx.executeSql("create table if not exists user(user_id text, token text, expire text, user_name text, email text)");
    tx.executeSql("delete from user");
    tx.executeSql("insert into user values(?, ?, ?, ?, ?)", [user.user_id, user.token, user.expire, user.user_name, user.email]);
  });
}

/**
 * 获取已经登录的用户
 */
function getUser() {
  var db = getDatabase();
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
 * 删除已经保存的用户
 */
function clearUser() {
  var db = getDatabase();
  db.transaction(function(tx) {
    tx.executeSql("create table if not exists user(user_id text, token text, expire text, user_name text, email text)");
    tx.executeSql("delete from user");
  });
}

/**
 * 保存登录的微博用户
 */
function saveWeiboAuth(uid, screen_name, access_token) {
  var db = getDatabase();
  db.transaction(function(tx) {
    tx.executeSql("create table if not exists weibo(uid text, screen_name, access_token text)");
    tx.executeSql("delete from weibo");
    tx.executeSql("insert into weibo values(?, ?, ?)", [uid, screen_name, access_token])
  });
}

/**
 * 获取登录的微博用户
 */
function getWeiboAuth() {
  var db = getDatabase();
  var auth;
  db.transaction(function(tx) {
    tx.executeSql("create table if not exists weibo(uid text, screen_name, access_token text)");
    var rs = tx.executeSql("select uid, screen_name, access_token from weibo");
    if (rs.rows.length != 0) {
      auth = rs.rows.item(0);
    }
  });
  return auth;
}

/**
 * 删除已经保存的微博授权
 */
function clearWeiboAuth() {
  var db = getDatabase();
  db.transaction(function(tx) {
    tx.executeSql("create table if not exists weibo(uid text, screen_name, access_token text)");
    tx.executeSql("delete from weibo");
  });
}

/**
 * 获取设置
 */
function getConfig(name) {
  var db = getDatabase();
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
 * 保存设置
 */
function setConfig(name, value) {
  var db = getDatabase();
  db.transaction(function(tx) {
    tx.executeSql("create table if not exists config(name text, value text)");
    tx.executeSql("delete from config where name=?", [name])
    tx.executeSql("insert into config values(?,?)", [name, value])
  });
}
