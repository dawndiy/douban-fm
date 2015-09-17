package main

import (
	"bytes"
	"database/sql"
	"fmt"
	"github.com/bitly/go-simplejson"
	"github.com/dawndiy/douban-sdk"
	_ "github.com/mattn/go-sqlite3"
	"gopkg.in/qml.v1"
	"io/ioutil"
	"log"
	"mime/multipart"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

/* Go-qml 没有 offlineStoragePath 方法 */

// var path string = "/home/phablet/.local/share/douban-fm.ubuntu-dawndiy/Databases/"

var path string = "/home/dawndiy/.local/share/douban-fm.ubuntu-dawndiy/Databases/"

func main() {
	log.Println("==Start==")
	log.Println("Database Path: ", path)
	err := qml.Run(run)
	log.Println(err)
}

// Run QML
func run() error {
	engine := qml.NewEngine()

	context := engine.Context()

	// set custom data from go to qml
	music := &Music{CurrentChannenID: "0"}
	music.getMusic()
	context.SetVar("DoubanMusic", music)
	context.SetVar("DoubanChannels", GetChannels())
	context.SetVar("DoubanUser", &DoubanUser{})
	context.SetVar("Weibo", getWeibo())

	component, err := engine.LoadFile("douban-fm.qml")
	if err != nil {
		return err
	}
	win := component.CreateWindow(nil)
	win.Show()
	win.Wait()
	return nil
}

// ==================================================
// Douban Music
// ==================================================

type Music struct {
	List             []doubanfm.Song
	CurrentChannenID string
	isLogin          bool
	userID           string
	expire           string
	token            string
}

// Cache music list
// start a goroutine to speed up loading music list
func (m *Music) getMusic() {
	go func(m *Music) {
		fm := doubanfm.NewDoubanFM()
		for {
			if len(m.List) < 8 {
				if m.isLogin {
					log.Println("[Worker]: get songs with userinfo to list", len(m.List))
				} else {
					log.Println("[Worker]: get songs to list", len(m.List))
				}
				opts := getDefaultOpts()
				opts["channel"] = m.CurrentChannenID
				if m.isLogin {
					opts["user_id"] = m.userID
					opts["expire"] = m.expire
					opts["token"] = m.token
				}
				songs, err := fm.Songs(opts)
				if err != nil {
					log.Println("[ERROR]: goroutine", err)
					time.Sleep(time.Second * 15)
					continue
				}
				m.List = append(m.List, songs...)
			}
			time.Sleep(time.Second * 1)
		}
	}(m)
}

// Next get next music
func (m *Music) Next(channelID string) doubanfm.Song {
	opts := getDefaultOpts()
	opts["channel"] = channelID

	m.isLogin = false

	if channelID != m.CurrentChannenID {
		m.Clear()
		m.CurrentChannenID = channelID
	}

	if len(m.List) == 0 {
		fm := doubanfm.NewDoubanFM()
		songs, err := fm.Songs(opts)
		if err != nil || len(songs) == 0 {
			log.Println("[ERROR]: network error ", err)
			return doubanfm.Song{}
		}
		m.List = append(m.List, songs...)
	}

	next := m.List[0]
	m.List = m.List[1:]
	return next
}

// NextWithUser  Get next music by userinfo
func (m *Music) NextWithUser(channelID, userID, expire, token string) doubanfm.Song {
	opts := getDefaultOpts()
	opts["channel"] = channelID
	opts["user_id"] = userID
	opts["expire"] = expire
	opts["token"] = token

	m.isLogin = true
	m.userID = userID
	m.expire = expire
	m.token = token

	if channelID != m.CurrentChannenID {
		m.Clear()
		m.CurrentChannenID = channelID
	}

	if len(m.List) == 0 {
		fm := doubanfm.NewDoubanFM()
		songs, err := fm.Songs(opts)
		if err != nil || len(songs) == 0 {
			log.Println("[ERROR]: network error ", err)
			return doubanfm.Song{}
		}
		m.List = append(m.List, songs...)
	}

	next := m.List[0]
	m.List = m.List[1:]
	return next
}

// NextOffLineMusic get offline music
func (m *Music) NextOfflineMusic() doubanfm.Song {

	// open database
	db, err := openDB()
	if err != nil {
		log.Println("[ERROR]: db", err)
		return doubanfm.Song{}
	}
	defer db.Close()

	// create table for music
	execSQL := `create table if not exists 
			music(
				album		text,
				picture		text,
				ssid		text,
				artist      text,
				url         text,
				company     text,
				title       text,
				ratingavg   text,
				length      integer,
				subtype     text,
				publictime  text,
				sid         text,
				aid         text,
				sha256      text,
				kbps        text,
				albumtitle  text,
				like        integer,
				picdata     blob,
				musicdata   blob
			)`
	db.Exec(execSQL)

	// random query a music
	execSQL = `select album,
				  picture,
				  ssid,
				  artist,
				  url,
				  company,
				  title,
				  ratingavg,
				  length,
				  subtype,
				  publictime,
				  sid,
				  aid,
				  sha256,
				  kbps,
				  albumtitle,
				  like,
				  picdata,
				  musicdata
			from music
			order by RANDOM()`

	row := db.QueryRow(execSQL)

	s := doubanfm.Song{}
	var picData []byte
	var musicData []byte
	err = row.Scan(&s.Album,
		&s.Picture,
		&s.SSID,
		&s.Artist,
		&s.URL,
		&s.Company,
		&s.Title,
		&s.RatingAvg,
		&s.Length,
		&s.SubType,
		&s.PublicTime,
		&s.SID,
		&s.AID,
		&s.SHA256,
		&s.Kbps,
		&s.AlbumTitle,
		&s.Like,
		&picData,
		&musicData,
	)
	if err != nil {
		log.Println("[ERROR]: scan music", err)
		return doubanfm.Song{}
	}

	// save picData and musicData to local path
	surl := strings.Split(s.URL, ".")
	ftype := surl[len(surl)-1]
	f, _ := os.Create(path + "music." + ftype)
	f.Write(musicData)
	f.Close()
	s.URL = path + "music." + ftype

	purl := strings.Split(s.Picture, ".")
	ftype = purl[len(purl)-1]
	f, _ = os.Create(path + "pic." + ftype)
	f.Write(picData)
	f.Close()
	s.Picture = path + "pic." + ftype

	log.Println("[INFO]:", s.Title)

	time.Sleep(time.Second)
	return s
}

// Sync music
func (m *Music) SyncMusic(channelID, userID, expire, token string, count int) {

	// start a goroutine to sync music to database
	go func() {
		// open database
		db, err := openDB()
		if err != nil {
			log.Println("[ERROR]: db", err)
			return
		}
		// create table for music
		execSQL := `create table if not exists 
				music(
					album		text,
					picture		text,
					ssid		text,
					artist      text,
					url         text,
					company     text,
					title       text,
					ratingavg   text,
					length      integer,
					subtype     text,
					publictime  text,
					sid         text,
					aid         text,
					sha256      text,
					kbps        text,
					albumtitle  text,
					like        integer,
					picdata     blob,
					musicdata   blob
				)`
		db.Exec(execSQL)
		db.Close()

		log.Println("-- 开始离线歌曲 --")

		sameSongsRetry := 3

		for i := 0; i < count; i++ {

			// TODO: change count
			if m.SyncCount() >= 20 {
				return
			}

			db, err := openDB()
			if err != nil {
				log.Println("[ERROR]: db", err)
				return
			}

			// get songs from star channel
			s := m.NextWithUser("-3", userID, expire, token)
			log.Println("[Loading]:", s.Artist, s.Title)

			// check if this song already in database
			stmt, _ := db.Prepare("select sid from music where sid=?")
			rows, _ := stmt.Query(s.SID)
			if rows.Next() {
				// 已经同步过
				i--
				sameSongsRetry--
				if sameSongsRetry < 0 {
					rows.Close()
					stmt.Close()
					break
				}
				time.Sleep(time.Second * 5)
				rows.Close()
				stmt.Close()
				continue
			}
			rows.Close()
			stmt.Close()

			// get album picture
			log.Println("[WORKER]: loading album picture")
			res, err := http.Get(s.Picture)
			if err != nil {
				log.Println("[ERROR]:", err)
				continue
			}
			picData, _ := ioutil.ReadAll(res.Body)
			res.Body.Close()
			log.Println("[WORKER]: album picture OK")

			// get music
			log.Println("[WORKER]: loading music")
			res, err = http.Get(s.URL)
			if err != nil {
				log.Println("[ERROR]: network error ", err)
				continue
			}
			musicData, _ := ioutil.ReadAll(res.Body)
			res.Body.Close()
			log.Println("[WORKER]: music OK")

			// 存储离线音乐
			stmt, _ = db.Prepare("insert into music values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
			r, err := stmt.Exec(
				s.Album,
				s.Picture,
				s.SSID,
				s.Artist,
				s.URL,
				s.Company,
				s.Title,
				s.RatingAvg,
				s.Length,
				s.SubType,
				s.PublicTime,
				s.SID,
				s.AID,
				s.SHA256,
				s.Kbps,
				s.AlbumTitle,
				s.Like,
				picData,
				musicData)

			stmt.Close()
			log.Println("[Save]:", r, err)

			db.Close()

			time.Sleep(time.Second * 1)
		}
	}()
}

// Offline music count
func (m *Music) SyncCount() int {

	// open database
	db, err := openDB()
	if err != nil {
		log.Println("[ERROR]: db", err)
		return 0
	}
	defer db.Close()

	// 创建离线数据表
	execSQL := `create table if not exists 
			music(
				album		text,
				picture		text,
				ssid		text,
				artist      text,
				url         text,
				company     text,
				title       text,
				ratingavg   text,
				length      integer,
				subtype     text,
				publictime  text,
				sid         text,
				aid         text,
				sha256      text,
				kbps        text,
				albumtitle  text,
				like        integer,
				picdata     blob,
				musicdata   blob
			)`
	db.Exec(execSQL)

	execSQL = "select count(sid) from music"
	row := db.QueryRow(execSQL)
	var count int
	row.Scan(&count)

	return count
}

// Clear music list
func (m *Music) Clear() {
	m.List = []doubanfm.Song{}
}

// Clear offline music
func (m *Music) ClearSync() {
	db, err := openDB()
	if err != nil {
		log.Println("[ERROR]: db", err)
		return
	}
	defer db.Close()
	// 创建离线数据表
	execSQL := "drop table music"
	db.Exec(execSQL)
}

// Mark like this music
func (m *Music) Like(userID, expire, token, musicID string) {

	opts := getDefaultOpts()
	opts["user_id"] = userID
	opts["expire"] = expire
	opts["token"] = token
	opts["sid"] = musicID
	opts["type"] = "r"

	fm := doubanfm.NewDoubanFM()

	songs, err := fm.Songs(opts)
	if err == nil && len(songs) != 0 {
		m.List = append(m.List, songs...)
	}
}

// Mark dislike this music
func (m *Music) Dislike(userID, expire, token, musicID string) {

	opts := getDefaultOpts()
	opts["user_id"] = userID
	opts["expire"] = expire
	opts["token"] = token
	opts["sid"] = musicID
	opts["type"] = "u"

	fm := doubanfm.NewDoubanFM()

	songs, err := fm.Songs(opts)
	if err == nil && len(songs) != 0 {
		m.List = append(m.List, songs...)
	}
}

// Mark ban this music
func (m *Music) Ban(userID, expire, token, musicID string) {

	opts := getDefaultOpts()
	opts["user_id"] = userID
	opts["expire"] = expire
	opts["token"] = token
	opts["sid"] = musicID
	opts["type"] = "b"

	fm := doubanfm.NewDoubanFM()

	songs, err := fm.Songs(opts)
	if err == nil && len(songs) != 0 {
		m.List = append(m.List, songs...)
	}
}

// ==================================================
// Channels
// ==================================================

type Channels struct {
	List []doubanfm.Channel
	Len  int
}

func GetChannels() *Channels {

	channels := new(Channels)

	// get list from json file
	file, err := os.Open("channels.json")
	if err == nil {

		defer file.Close()
		chs := []doubanfm.Channel{}
		jsonData, _ := simplejson.NewFromReader(file)
		channelData := jsonData.MustArray()
		for _, v := range channelData {
			v := v.(map[string]interface{})
			channel := doubanfm.Channel{}
			c_id, _ := strconv.Atoi(fmt.Sprint(v["channel_id"]))
			channel.ID = c_id
			channel.AbbrEN = v["abbr_en"].(string)
			channel.Name = v["name"].(string)
			channel.NameEN = v["name_en"].(string)
			chs = append(chs, channel)
		}
		channels.List = chs
		channels.Len = len(chs)

	} else {
		// get list from internet
		fm := doubanfm.NewDoubanFM()
		chs, err := fm.Channels()
		if err != nil {
			return channels
		}

		channels.List = chs
		channels.Len = len(chs)
	}

	return channels
}

func (ch *Channels) Channel(index int) doubanfm.Channel {
	return ch.List[index]
}

func (ch *Channels) ChannelByID(id int) doubanfm.Channel {
	for _, channel := range ch.List {
		if channel.ID == id {
			return channel
		}
	}
	return doubanfm.Channel{}
}

// ==================================================
// Login Douban
// ==================================================

type DoubanUser struct {
}

func (user *DoubanUser) Login(email, password string) *doubanfm.User {

	fm := doubanfm.NewDoubanFM()
	u, err := fm.Login(email, password)

	if err != nil {
		return &doubanfm.User{
			ERR:    err.Error(),
			Result: 1,
		}
	}
	return u
}

// ==================================================
// Weibo
// ==================================================

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

// ==================================================
// Other
// ==================================================

func getDefaultOpts() map[string]string {
	opts := map[string]string{}
	for key, value := range doubanfm.DefaultOptions {
		opts[key] = value
	}
	return opts
}

// Open database
func openDB() (*sql.DB, error) {

	// get directory of database
	dataDir, err := os.Open(path)
	if err != nil {
		log.Println(err)
		return nil, err
	}
	defer dataDir.Close()

	// get database file
	fi, _ := dataDir.Readdir(-1)
	var dbfile string
	for _, i := range fi {
		if strings.Contains(i.Name(), ".sqlite") {
			dbfile = path + i.Name()
			break
		}
	}
	if dbfile == "" {
		// if dbfile not find, return an empty song
		return nil, err
	}

	// open database
	db, err := sql.Open("sqlite3", dbfile)
	return db, err
}
