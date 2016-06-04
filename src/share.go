package main

import (
	"bytes"
	"io/ioutil"
	"mime/multipart"
	"net/http"

	"github.com/bitly/go-simplejson"
)

// Weibo
type Weibo struct {
	Key         string
	Secret      string
	AccessToken string
	RemindIn    string
	ExpiresIn   int
	IsLogin     bool
	UID         string
	ScreenName  string
}

// Get Weibo
func getWeibo() *Weibo {

	weibo := &Weibo{}
	weibo.Key = APP_KEY
	weibo.Secret = APP_SECRET

	return weibo
}

// Login sina weibo
func (weibo *Weibo) Login(code string) bool {

	// 登录需要 POST 的数据
	data := map[string][]string{
		"client_id":     {weibo.Key},
		"client_secret": {weibo.Secret},
		"grant_type":    {"authorization_code"},
		"redirect_uri":  {"https://api.weibo.com/oauth2/default.html"},
		"code":          {code},
	}

	res, err := http.PostForm("https://api.weibo.com/oauth2/access_token", data)
	if err != nil {
		log.Println("[ERROR]: weibo login ", err)
		return false
	}
	defer res.Body.Close()
	json, err := simplejson.NewFromReader(res.Body)
	if err != nil {
		log.Println("[ERROR]: weibo login ", err)
		return false
	}

	weibo.AccessToken = json.Get("access_token").MustString()
	weibo.RemindIn = json.Get("remind_in").MustString()
	weibo.ExpiresIn = json.Get("expires_in").MustInt()
	weibo.IsLogin = true
	weibo.UID = json.Get("uid").MustString()

	// get user information
	api := "https://api.weibo.com/2/users/show.json?access_token=" + weibo.AccessToken + "&uid=" + weibo.UID
	res, err = http.Get(api)
	if err != nil {
		log.Println("[ERROR]: weibo login ", err)
		return false
	}
	defer res.Body.Close()
	json, err = simplejson.NewFromReader(res.Body)
	if err != nil {
		log.Println("[ERROR]: weibo login ", err)
		return false
	}
	weibo.ScreenName = json.Get("screen_name").MustString()

	return true
}

// Post a weibo status with picture
func (weibo *Weibo) Upload(accessToken, weiboStatus, picURL string) {

	api := "https://upload.api.weibo.com/2/statuses/upload.json"

	body_buf := bytes.NewBufferString("")
	body_writer := multipart.NewWriter(body_buf)
	contentType := body_writer.FormDataContentType()

	fw, _ := body_writer.CreateFormField("access_token")
	fw.Write([]byte(accessToken))

	fw, _ = body_writer.CreateFormField("status")
	fw.Write([]byte(weiboStatus))

	// ==============
	fw, _ = body_writer.CreateFormFile("pic", "pic.jpg")
	res, _ := http.Get(picURL)
	defer res.Body.Close()
	picData, _ := ioutil.ReadAll(res.Body)
	fw.Write(picData)
	// ==============

	body_writer.Close()
	res, err := http.Post(api, contentType, body_buf)
	if err != nil {
		log.Println("[ERROR]: weibo post ", err)
	}
	defer res.Body.Close()

	body, _ := ioutil.ReadAll(res.Body)
	log.Println("[RESPONSE]:", string(body))

}
