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
