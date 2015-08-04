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

var path string = "/home/phablet/.local/share/douban-fm.ubuntu-dawndiy/Databases/"

// var path string = "/home/dawndiy/.local/share/douban-fm.ubuntu-dawndiy/Databases/"

func main() {
	log.Println("Start")
	err := qml.Run(run)
	log.Println(err)
}

// Run QML
func run() error {
	engine := qml.NewEngine()

	context := engine.Context()

	// set custom data from go to qml
	context.SetVar("channels", GetChannels())
	// context.SetVar("song", &Song{})
	context.SetVar("song", GetSong())
	context.SetVar("doubanUser", &User{})
	context.SetVar("weibo", getWeibo())

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
// Song
// ==================================================

type Song struct {
	List          []doubanfm.Song
	Currnt        doubanfm.Song
	lastChannelID string
}

func GetSong() *Song {

	song := new(Song)
	song.lastChannelID = "0"

	fm := doubanfm.NewDoubanFM()
	songs, err := fm.Songs()
	if err != nil {
		return song
	}

	song.List = append(song.List, songs...)

	return song
}

// 下一首
func (song *Song) Next(channelID string) doubanfm.Song {

	opts := getDefaultOpts()
	opts["channel"] = channelID
	log.Println("OPTS: ", opts)

	// 频道是否改变过
	if song.lastChannelID != channelID {
		song.Clear()
		song.lastChannelID = channelID
	}

	// 重试 5 次
	for i := 0; i < 5; i++ {
		if len(song.List) != 0 {
			break
		}
		fm := doubanfm.NewDoubanFM()

		songs, err := fm.Songs(opts)
		if err != nil {
			log.Println(err)
			return doubanfm.Song{}
		}
		song.List = append(song.List, songs...)
	}

	// 重试依然获取不到
	if len(song.List) == 0 {
		return doubanfm.Song{}
	}

	next := song.List[0]
	song.Currnt = next

	// print("\n===============\n")
	// for _, i := range song.List {
	// 	print(i.Title, ", ")
	// }
	// print("\n===============\n")
	// print("\n NOW:   ", next.Title, "\n")

	song.List = song.List[1:]

	return next
}

// 下一首歌, 已登录用户
func (song *Song) NextWithUser(channelID, userID, expire, token string) doubanfm.Song {

	opts := getDefaultOpts()
	opts["channel"] = channelID
	opts["user_id"] = userID
	opts["expire"] = expire
	opts["token"] = token
	log.Println("OPTS: ", opts)

	// 频道是否改变过
	if song.lastChannelID != channelID {
		song.Clear()
		song.lastChannelID = channelID
	}

	// 重试 5 次
	for i := 0; i < 5; i++ {
		if len(song.List) != 0 {
			break
		}
		fm := doubanfm.NewDoubanFM()

		songs, err := fm.Songs(opts)
		if err != nil {
			log.Println(err)
			return doubanfm.Song{}
		}
		song.List = append(song.List, songs...)
	}

	// 重试依然获取不到
	if len(song.List) == 0 {
		return doubanfm.Song{}
	}

	next := song.List[0]
	song.Currnt = next

	// print("\n===============\n")
	// for _, i := range song.List {
	// 	print(i.Title, ", ")
	// }
	// print("\n===============\n")
	// print("\n NOW:   ", next.Title, "\n")

	song.List = song.List[1:]

	return next
}

// 下一首离线歌曲
func (song *Song) NextOffMusic() doubanfm.Song {

	log.Println("DEBUG: ", path)

	// 数据库目录
	dataDir, err := os.Open(path)
	if err != nil {
		log.Println(err)
		return doubanfm.Song{}
	}
	defer dataDir.Close()
	// 找数据库文件
	fi, _ := dataDir.Readdir(-1)
	var dbfile string
	for _, i := range fi {
		if strings.Contains(i.Name(), ".sqlite") {
			dbfile = path + i.Name()
			break
		}
	}
	if dbfile == "" {
		// 数据库文件不存在
		return doubanfm.Song{}
	}
	// 操作数据库
	db, err := sql.Open("sqlite3", dbfile)
	if err != nil {
		log.Println("DB_ERROR: ", err)
		return doubanfm.Song{}
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
			order by RANDOM()
	`

	row := db.QueryRow(execSQL)
	log.Println("==============")
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
		log.Println("GET_ERR: ", err)
		return doubanfm.Song{}
	}

	// picData, musicData 存本地
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
	log.Println(s)

	time.Sleep(time.Second)

	return s
}

func (song *Song) SyncCount() int {

	// 数据库目录
	dataDir, err := os.Open(path)
	if err != nil {
		log.Println(err)
		return 0
	}
	defer dataDir.Close()
	// 找数据库文件
	fi, _ := dataDir.Readdir(-1)
	var dbfile string
	for _, i := range fi {
		if strings.Contains(i.Name(), ".sqlite") {
			dbfile = path + i.Name()
			break
		}
	}
	if dbfile == "" {
		// 数据库文件不存在
		return 0
	}
	// 操作数据库
	db, err := sql.Open("sqlite3", dbfile)
	if err != nil {
		log.Println("DB_ERROR: ", err)
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

func (song *Song) ClearSync() {
	log.Println("-------clear")
	// 数据库目录
	dataDir, err := os.Open(path)
	if err != nil {
		log.Println(err)
		return
	}
	defer dataDir.Close()
	// 找数据库文件
	fi, _ := dataDir.Readdir(-1)
	var dbfile string
	for _, i := range fi {
		if strings.Contains(i.Name(), ".sqlite") {
			dbfile = path + i.Name()
			break
		}
	}
	if dbfile == "" {
		// 数据库文件不存在
		return
	}
	// 操作数据库
	db, err := sql.Open("sqlite3", dbfile)
	if err != nil {
		log.Println("DB_ERROR: ", err)
		return
	}
	defer db.Close()
	// 创建离线数据表
	execSQL := "drop table music"
	db.Exec(execSQL)
}

// 标记喜欢
func (song *Song) Like(userID, expire, token, songID string) {

	opts := getDefaultOpts()
	opts["user_id"] = userID
	opts["expire"] = expire
	opts["token"] = token
	opts["sid"] = songID
	opts["type"] = "r"

	fm := doubanfm.NewDoubanFM()

	songs, err := fm.Songs(opts)
	if err == nil && len(songs) != 0 {
		song.List = append(song.List, songs...)
	}
}

// 取消标记喜欢
func (song *Song) Unlike(userID, expire, token, songID string) {
	opts := getDefaultOpts()
	opts["user_id"] = userID
	opts["expire"] = expire
	opts["token"] = token
	opts["sid"] = songID
	opts["type"] = "u"

	fm := doubanfm.NewDoubanFM()

	songs, err := fm.Songs(opts)
	if err == nil && len(songs) != 0 {
		song.List = append(song.List, songs...)
	}
}

// 标记不再播放
func (song *Song) Del(userID, expire, token, songID string) {
	opts := getDefaultOpts()
	opts["user_id"] = userID
	opts["expire"] = expire
	opts["token"] = token
	opts["sid"] = songID
	opts["type"] = "b"

	fm := doubanfm.NewDoubanFM()

	songs, err := fm.Songs(opts)
	if err == nil && len(songs) != 0 {
		song.List = append(song.List, songs...)
	}
}

// 清除队列
func (song *Song) Clear() {
	song.List = []doubanfm.Song{}
}

// 同步离线歌曲
func (song *Song) SyncMusic(channelID, userID, expire, token string, count int) {

	log.Println("DEBUG: ", path)

	// 数据库目录
	dataDir, err := os.Open(path)
	if err != nil {
		log.Println(err)
		return
	}
	defer dataDir.Close()
	// 找数据库文件
	fi, _ := dataDir.Readdir(-1)
	var dbfile string
	for _, i := range fi {
		if strings.Contains(i.Name(), ".sqlite") {
			dbfile = path + i.Name()
			break
		}
	}
	if dbfile == "" {
		// 数据库文件不存在
		return
	}

	// --------------------
	// 匿名协程同步离线歌曲
	// --------------------
	go func() {
		// 操作数据库
		db, err := sql.Open("sqlite3", dbfile)
		if err != nil {
			log.Println(err)
			return
		}
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
		db.Close()

		log.Println("-- 开始离线歌曲 --")

		sameSongsRetry := 3

		for i := 0; i < count; i++ {

			// TODO:
			if song.SyncCount() >= 20 {
				return
			}

			db, err := sql.Open("sqlite3", dbfile)
			if err != nil {
				log.Println(err)
				return
			}

			// 准备离线的歌曲
			s := song.NextWithUser("-3", userID, expire, token)
			log.Println(s)
			stmt, _ := db.Prepare("select sid from music where sid=?")
			rows, err := stmt.Query(s.SID)
			log.Println(rows, err)
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

			// 获取图片数据
			log.Println("获取图片")
			res, err := http.Get(s.Picture)
			if err != nil {
				log.Println(err)
				continue
			}
			defer res.Body.Close()
			picData, _ := ioutil.ReadAll(res.Body)
			log.Println("获取图片 OK")

			// 获取音乐数据
			log.Println("获取音乐")
			res, err = http.Get(s.URL)
			if err != nil {
				log.Println(err)
				continue
			}
			defer res.Body.Close()
			musicData, _ := ioutil.ReadAll(res.Body)
			log.Println("获取音乐 OK")

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
			log.Println("EXEC: ", r, err)

			db.Close()

			time.Sleep(time.Second * 1)
		}
	}()

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

	// 从文件读取列表
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
		// 从网络读取列表
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

// ==================================================
// Login Douban
// ==================================================

type User struct {
}

func (user *User) Login(email, password string) *doubanfm.User {

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

func getWeibo() *Weibo {

	weibo := &Weibo{}
	weibo.Key = APP_KEY
	weibo.Secret = APP_SECRET

	return weibo
}

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
		log.Println(err)
		return false
	}
	defer res.Body.Close()
	json, err := simplejson.NewFromReader(res.Body)
	if err != nil {
		log.Println(err)
		return false
	}

	weibo.AccessToken = json.Get("access_token").MustString()
	weibo.RemindIn = json.Get("remind_in").MustString()
	weibo.ExpiresIn = json.Get("expires_in").MustInt()
	weibo.IsLogin = true
	weibo.UID = json.Get("uid").MustString()

	// 获取用户信息
	api := "https://api.weibo.com/2/users/show.json?access_token=" + weibo.AccessToken + "&uid=" + weibo.UID
	res, err = http.Get(api)
	if err != nil {
		log.Println(err)
		return false
	}
	defer res.Body.Close()
	json, err = simplejson.NewFromReader(res.Body)
	if err != nil {
		log.Println(err)
		return false
	}
	weibo.ScreenName = json.Get("screen_name").MustString()

	return true
}

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
		log.Println(err)
	}
	defer res.Body.Close()

	body, _ := ioutil.ReadAll(res.Body)
	log.Println(string(body))

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
