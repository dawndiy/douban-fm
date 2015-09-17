function _get(url, func) {
  var req = new XMLHttpRequest();
  req.onreadystatechange = function() {
    if (req.readyState === XMLHttpRequest.DONE) {
      console.log("<<<<<<<<<<", req.responseText.toString());
      var object = JSON.parse(req.responseText.toString());
      func(object)
    }
  }
  req.open("GET", url);
  req.send();
}

function _post(url, data, func, type) {
  var req = new XMLHttpRequest();
  req.onreadystatechange = function() {
    if (req.readyState === XMLHttpRequest.DONE) {
      console.log("<<<<<<<<<<", req.responseText.toString());
      var object = JSON.parse(req.responseText.toString());
      func(object)
    }
  }
  req.open("POST", url);
  type = type || "application/x-www-form-urlencoded";
  req.setRequestHeader("Content-Type", type);
  req.send(data);
}

/**
 * 获取用户信息
 */
function user_show(access_token, uid) {
  var url = "https://api.weibo.com/2/users/show.json?access_token=" + access_token + "&uid=" + uid;
  _get(url, function(json) {
    console.log("_________", json);
  });
}

/**
 * 发送一条微博
 */
function statuses_update(access_token, weibo_status, func) {
  var url = "https://api.weibo.com/2/statuses/update.json";
  var data = "access_token=" + access_token + "&status=" + weibo_status;
  _post(url, data, func);
}

/**
 * 上传图片并发布一条微博
 */
function statuses_upload(access_token, weibo_status, pic_url, func) {

  weibo.upload(access_token, weibo_status, pic_url);
  func();
}
