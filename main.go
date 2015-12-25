package main

import (
	"bytes"
	"database/sql"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"mime/multipart"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/bitly/go-simplejson"
	"github.com/dawndiy/douban-sdk"
	_ "github.com/mattn/go-sqlite3"
	"gopkg.in/qml.v1"
)

const (
	ApplicationName    = "douban-fm.ubuntu-dawndiy"
	ApplicationVersion = "0.2.1"
)

var (
	XDG_DATA_HOME string = os.Getenv("XDG_DATA_HOME")
	DB_PATH       string
	MUSIC_PATH    string
	PICTURE_PATH  string
)

func init() {
	// check env
	if XDG_DATA_HOME == "" {
		HOME := os.Getenv("HOME")
		XDG_DATA_HOME = HOME + "/.local/share"
	}
	DB_PATH = XDG_DATA_HOME + "/" + ApplicationName + "/Databases/"
	MUSIC_PATH = XDG_DATA_HOME + "/" + ApplicationName + "/Musics/"
	PICTURE_PATH = XDG_DATA_HOME + "/" + ApplicationName + "/Pictures/"
	if _, err := os.Stat(MUSIC_PATH); os.IsNotExist(err) {
		os.Mkdir(MUSIC_PATH, os.ModePerm)
	}
	if _, err := os.Stat(PICTURE_PATH); os.IsNotExist(err) {
		os.Mkdir(PICTURE_PATH, os.ModePerm)
	}
}

func main() {

	log.Println("==Start==")
	log.Println("Database Path: ", DB_PATH)
	err := qml.Run(run)
	log.Println(err)
}

// Run QML
func run() error {
	engine := qml.NewEngine()

	context := engine.Context()

	// set custom data from go to qml
	music := &Music{CurrentChannenID: "0"}
	context.SetVar("DoubanMusic", music)
	context.SetVar("DoubanChannels", GetChannels())
	context.SetVar("DoubanUser", &DoubanUser{})
	context.SetVar("Weibo", getWeibo())
	context.SetVar("ApplicationVersion", ApplicationVersion)

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
}

// NewList get new play list
func (m *Music) NewList() error {
	songs, err := doubanfm.PlayListNew(m.CurrentChannenID)
	if checkLogout(err) != nil || len(songs) == 0 {
		return errors.New("can't get more songs")
	}
	m.List = append(m.List, songs...)
	return nil
}

// Skip to skip current playing music
func (m *Music) SkipMusic(sid, position string) doubanfm.Song {
	// clear current play list
	m.Clear()
	// get a new play list
	songs, err := doubanfm.PlayListSkip(sid, position, m.CurrentChannenID)
	if checkLogout(err) != nil || len(songs) == 0 {
		checkLogout(err)
		log.Println("[ERROR]: network error ", err)
		return doubanfm.Song{}
	}
	m.List = append(m.List, songs...)
	next := m.List[0]
	m.List = m.List[1:]
	// get more songs to play list
	m.More(next.SID)
	return next
}

// More get more music
func (m *Music) More(sid string) error {
	for i := 0; i < 3; i++ {
		songs, err := doubanfm.PlayListPlaying(sid, m.CurrentChannenID)
		if checkLogout(err) != nil || len(songs) == 0 {
			continue
		}
		m.List = append(m.List, songs...)
		return nil
	}
	return errors.New("can't get more songs")
}

// ReportEnd report when finished the music
func (m *Music) ReportEnd(sid, position string) {
	doubanfm.PlayListEnd(sid, position, m.CurrentChannenID)
}

// Next get next music
func (m *Music) Next() doubanfm.Song {

	next := doubanfm.Song{}

	if len(m.List) == 0 {
		err := m.NewList()
		if err != nil {
			log.Println("[ERROR]: network error ", err)
			return doubanfm.Song{}
		}
	}
	next = m.List[0]
	m.List = m.List[1:]
	m.More(next.SID)

	return next
}

// ChangeChannel
func (m *Music) ChangeChannel(channelID string) doubanfm.Song {
	m.Clear()
	err := doubanfm.ChannelChange(m.CurrentChannenID, channelID, "recent_chls")
	checkLogout(err)
	m.CurrentChannenID = channelID

	err = m.NewList()
	if err != nil {
		log.Println("[ERROR]: network error ", err)
		return doubanfm.Song{}
	}
	next := m.List[0]
	m.List = m.List[1:]
	m.More(next.SID)
	return next
}

// Ban this music
func (m *Music) BanMusic(sid, position, channelID string) doubanfm.Song {
	m.Clear()
	songs, err := doubanfm.PlayListBan(sid, position, channelID)
	if checkLogout(err) != nil || len(songs) == 0 {
		log.Println("[ERROR]: network error ", err)
		return doubanfm.Song{}
	}
	m.List = append(m.List, songs...)
	next := m.List[0]
	m.List = m.List[1:]
	m.More(next.SID)
	return next
}

// Rate this music
func (m *Music) RateMusic(sid, position, channelID string) {
	songs, err := doubanfm.PlayListRate(sid, position, channelID)
	if checkLogout(err) != nil || len(songs) == 0 {
		log.Println("[ERROR]: network error ", err)
		return
	}
	m.List = append(m.List, songs...)
}

// Unrate this music
func (m *Music) UnrateMusic(sid, position, channelID string) {
	songs, err := doubanfm.PlayListUnrate(sid, position, channelID)
	if checkLogout(err) != nil || len(songs) == 0 {
		log.Println("[ERROR]: network error ", err)
		return
	}
	m.List = append(m.List, songs...)
}

// SetDBCL2 set user auth
func (m *Music) SetDBCL2(dbcl2 string) {
	user := doubanfm.User{
		DBCL2: dbcl2,
	}
	doubanfm.SetUser(user)
}

// SyncMusic from douban fm
func (m *Music) SyncMusic(channelID string, count int) {
	checkTableMusic()
	go func(count int) {
		db, err := openDB()
		if err != nil {
			log.Println("[ERROR]: db", err)
			return
		}
		defer db.Close()

		musicCount := 0
		sameSongsRetry := 3
		for {
			songs, err := doubanfm.PlayListNew(channelID)
			if err != nil || len(songs) == 0 {
				time.Sleep(time.Second)
				continue
			}
			for _, s := range songs {
				stmt, _ := db.Prepare("select sid from music where sid=?")
				rows, _ := stmt.Query(s.SID)
				if !rows.Next() {
					rows.Close()
					stmt.Close()

					log.Println("[SYNC WORKER]:", s.SID, s.Artist, s.Title)
					log.Println("[SYNC WORKER]: loading album picture")
					res, err := http.Get(s.Picture)
					if err != nil {
						log.Println("[ERROR]:", err)
						continue
					}
					picData, _ := ioutil.ReadAll(res.Body)
					res.Body.Close()
					log.Println("[SYNC WORKER]: album picture OK")

					log.Println("[SYNC WORKER]: loading music")
					res, err = http.Get(s.URL)
					if err != nil {
						log.Println("[ERROR]:", err)
						continue
					}
					musicData, _ := ioutil.ReadAll(res.Body)
					res.Body.Close()
					log.Println("[SYNC WORKER]: music OK")

					// get music and pic file name
					_surl := strings.Split(s.URL, "/")
					_sFName := _surl[len(_surl)-1]
					musicFilePath := MUSIC_PATH + strings.Split(_sFName, ".")[0]
					_purl := strings.Split(s.Picture, "/")
					_pFName := _purl[len(_purl)-1]
					picFilePath := PICTURE_PATH + strings.Split(_pFName, ".")[0]

					// save music file
					f, _ := os.Create(musicFilePath)
					f.Write(musicData)
					f.Close()

					// save picture file
					f, _ = os.Create(picFilePath)
					f.Write(picData)
					f.Close()

					// save info in database
					s.Picture = picFilePath
					s.URL = musicFilePath

					stmt, _ = db.Prepare("insert into music values(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)")
					r, err := stmt.Exec(
						s.Picture,
						s.AlbumTitle,
						s.Like,
						s.Album,
						s.SSID,
						s.Title,
						s.URL,
						s.Artist,
						s.SubType,
						s.Length,
						s.SID,
						s.AID,
						s.Company,
						s.PublicTime,
						s.SHA256,
						s.Kbps,
					)
					stmt.Close()
					log.Println("[Save]:", r, err)

					musicCount++
					time.Sleep(time.Second)
				} else {
					rows.Close()
					stmt.Close()
					sameSongsRetry--
				}
			}
			if musicCount >= count || sameSongsRetry < 0 {
				break
			}
		}
	}(count)
}

// Offline music count
func (m *Music) SyncCount() int {

	checkTableMusic()
	// open database
	db, err := openDB()
	if err != nil {
		log.Println("[ERROR]: db", err)
		return 0
	}
	defer db.Close()

	execSQL := "select count(sid) from music"
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
	execSQL := "delete from music"
	db.Exec(execSQL)
	os.RemoveAll(MUSIC_PATH)
	os.RemoveAll(PICTURE_PATH)
	os.Mkdir(MUSIC_PATH, os.ModePerm)
	os.Mkdir(PICTURE_PATH, os.ModePerm)
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
		// fm := doubanfm.NewDoubanFM()
		// chs, err := fm.Channels()
		// if err != nil {
		// 	return channels
		// }

		// channels.List = chs
		// channels.Len = len(chs)
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

type LoginResult struct {
	Result  bool
	Message string
	User    doubanfm.User
}

func (user *DoubanUser) Login(name, password, captcha, captchaID string) LoginResult {
	result := LoginResult{}
	account, err := doubanfm.Login(name, password, captcha, captchaID)
	if err != nil {
		result.Result = false
		result.Message = err.Error()
		return result
	}
	result.Result = true
	result.User = account

	doubanfm.SetUser(account)

	return result
}

func (user *DoubanUser) Logout() {
	doubanfm.Logout()
}

type Captcha struct {
	Result       bool
	CaptchaImage string
	CaptchaID    string
}

func (user *DoubanUser) GetCaptcha() Captcha {
	captcha, captchaID, err := doubanfm.Captcha()
	result := true
	if err != nil {
		result = false
	}
	captchaData := Captcha{
		result,
		captcha,
		captchaID,
	}
	return captchaData
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

// Open database
func openDB() (*sql.DB, error) {

	// get directory of database
	dataDir, err := os.Open(DB_PATH)
	if err != nil {
		log.Println(err)
		return nil, err
	}
	defer dataDir.Close()

	// get database file
	fi, _ := dataDir.Readdir(-1)
	var dbfile string
	for _, i := range fi {
		if strings.HasSuffix(i.Name(), ".sqlite") {
			dbfile = DB_PATH + i.Name()
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

// check if douban account logout
func checkLogout(err error) error {

	if err == nil {
		return nil
	}

	// User logged out from web side
	if err.Error() == "logged out" {
		log.Println("[WARNING]: DoubanUser logout from web sid", err)
		// open database
		db, e := openDB()
		if e != nil {
			log.Println("[ERROR]: db", err)
			return err
		}
		defer db.Close()

		execSQL := "delete from user"
		db.Exec(execSQL)
		return nil
	}
	return err
}

// create table music if not exists
func checkTableMusic() {
	// open database
	db, err := openDB()
	if err != nil {
		log.Println("[ERROR]: db", err)
		return
	}
	defer db.Close()
	// create table music
	execSQL := `create table if not exists
				music(
					picture		text,
					albumTitle  text,
					like        integer,
					album		text,
					ssid		text,
					title       text,
					url         text,
					artist      text,
					subType     text,
					length      integer,
					sid         text,
					aid         text,
					company     text,
					publicTime text,
					sha256      text,
					kbps        text
				)`
	db.Exec(execSQL)
}
