/*
 * Copyright (C) 2015, 2016  DawnDIY <dawndiy.dev@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

package main

import (
	"errors"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/dawndiy/douban-sdk"
)

// Music is a struct to save playlist, current channel and other information.
type Music struct {
	CurrentChannelID string
	List             []doubanfm.Song
	OfflineList      []doubanfm.Song
}

// NewList get new play list
func (m *Music) NewList() error {
	songs, err := doubanfm.PlayListNew(m.CurrentChannelID)
	if checkLogout(err) != nil || len(songs) == 0 {
		return errors.New("can't get more songs")
	}
	m.List = append(m.List, songs...)
	return nil
}

// SkipMusic to skip current playint music
func (m *Music) SkipMusic(sid, position string) {

	ch := make(chan doubanfm.Song)

	go func(ch chan doubanfm.Song) {
		// clear current play list
		m.Clear()
		// get a new play list
		var err error
		var songs []doubanfm.Song
		if sid == "" {
			songs, err = doubanfm.PlayListNew(m.CurrentChannelID)
		} else {
			songs, err = doubanfm.PlayListSkip(sid, position, m.CurrentChannelID)
		}
		if checkLogout(err) != nil || len(songs) == 0 {
			checkLogout(err)
			log.Println("[ERROR]: network error ", err)
			ch <- doubanfm.Song{}
			return
		}
		m.List = append(m.List, songs...)
		next := m.List[0]
		m.List = m.List[1:]
		// get more songs to play list
		m.More(next.SID)
		//time.Sleep(time.Second * 2)
		ch <- next
	}(ch)

	go func(ch chan doubanfm.Song) {
		song := <-ch
		handler := root.ObjectByName("doubanAPIHandler")
		handler.Call("emitSignalWithObj", "musicLoaded", song)
	}(ch)

}

// More get more music
func (m *Music) More(sid string) error {
	for i := 0; i < 3; i++ {
		songs, err := doubanfm.PlayListPlaying(sid, m.CurrentChannelID)
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
	go doubanfm.PlayListEnd(sid, position, m.CurrentChannelID)
}

// Next music
func (m *Music) Next() {
	ch := make(chan doubanfm.Song)

	go func(ch chan doubanfm.Song) {
		next := doubanfm.Song{}

		if len(m.List) == 0 {
			err := m.NewList()
			if err != nil {
				log.Println("[ERROR]: network error ", err)
				ch <- next
				return
			}
		}
		next = m.List[0]
		m.List = m.List[1:]
		m.More(next.SID)
		//time.Sleep(time.Second * 2)
		ch <- next
	}(ch)

	go func(ch chan doubanfm.Song) {
		song := <-ch
		handler := root.ObjectByName("doubanAPIHandler")
		handler.Call("emitSignalWithObj", "musicLoaded", song)
	}(ch)
}

// ChangeChannel to new channel
func (m *Music) ChangeChannel(channelID string) {
	ch := make(chan doubanfm.Song)

	go func(chan doubanfm.Song) {
		m.Clear()
		err := doubanfm.ChannelChange(m.CurrentChannelID, channelID, "recent_chls")
		checkLogout(err)
		m.CurrentChannelID = channelID

		err = m.NewList()
		if err != nil {
			log.Println("[ERROR]: network error ", err)
			ch <- doubanfm.Song{}
			return
		}
		next := m.List[0]
		m.List = m.List[1:]
		m.More(next.SID)
		ch <- next
	}(ch)

	go func(chan doubanfm.Song) {
		song := <-ch
		handler := root.ObjectByName("doubanAPIHandler")
		handler.Call("emitSignalWithObj", "channelChanged", song)
	}(ch)
}

// Ban this music
func (m *Music) BanMusic(sid, position, channelID string) {
	ch := make(chan doubanfm.Song)

	go func(chan doubanfm.Song) {
		m.Clear()
		songs, err := doubanfm.PlayListBan(sid, position, channelID)
		if checkLogout(err) != nil || len(songs) == 0 {
			log.Println("[ERROR]: network error ", err)
			ch <- doubanfm.Song{}
			return
		}
		m.List = append(m.List, songs...)
		next := m.List[0]
		m.List = m.List[1:]
		m.More(next.SID)
		ch <- next
	}(ch)

	go func(chan doubanfm.Song) {
		song := <-ch
		handler := root.ObjectByName("doubanAPIHandler")
		handler.Call("emitSignalWithObj", "musicBanned", song)
	}(ch)
}

// Rate this music
func (m *Music) RateMusic(sid, position, channelID string) {

	go func(sid, position, channelID string) {
		songs, err := doubanfm.PlayListRate(sid, position, channelID)
		if checkLogout(err) != nil || len(songs) == 0 {
			log.Println("[ERROR]: network error ", err)
			return
		}
		m.List = append(m.List, songs...)
	}(sid, position, channelID)
}

// Unrate this music
func (m *Music) UnrateMusic(sid, position, channelID string) {
	go func(sid, position, channelID string) {
		songs, err := doubanfm.PlayListUnrate(sid, position, channelID)
		if checkLogout(err) != nil || len(songs) == 0 {
			log.Println("[ERROR]: network error ", err)
			return
		}
		m.List = append(m.List, songs...)
	}(sid, position, channelID)
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
					musicFilePath := MUSIC_PATH + strings.Split(_sFName, ".")[0] + ".mp3"
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
