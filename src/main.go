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
	"database/sql"
	"errors"
	Log "log"
	"os"
	"strings"

	_ "github.com/mattn/go-sqlite3"
	"gopkg.in/qml.v1"
)

const (
	ApplicationName    = "douban-fm.ubuntu-dawndiy"
	ApplicationVersion = "0.2.3"
)

var (
	XDG_DATA_HOME string = os.Getenv("XDG_DATA_HOME")
	DB_PATH       string
	MUSIC_PATH    string
	PICTURE_PATH  string
	root          qml.Object
	log           *Log.Logger = Log.New(os.Stdout, "", Log.LstdFlags|Log.Lshortfile)
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
	music := &Music{CurrentChannelID: "0"}
	context.SetVar("DoubanMusic", music)
	context.SetVar("DoubanChannels", GetChannels())
	context.SetVar("DoubanUser", &DoubanUser{})
	context.SetVar("Weibo", getWeibo())
	context.SetVar("ApplicationVersion", ApplicationVersion)
	isDesktop := false
	if os.Getenv("XDG_DATA_HOME") == "" {
		isDesktop = true
	}
	context.SetVar("IsDesktop", isDesktop)

	component, err := engine.LoadFile("app/douban-fm.qml")
	if err != nil {
		return err
	}
	win := component.CreateWindow(nil)
	root = win.Root()
	win.Show()
	win.Wait()
	return nil
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
		return nil, errors.New("db file not found")
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
