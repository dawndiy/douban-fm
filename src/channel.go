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
	"fmt"
	"os"
	"strconv"

	"github.com/bitly/go-simplejson"
	"github.com/dawndiy/douban-sdk"
)

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
