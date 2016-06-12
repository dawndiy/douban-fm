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
	"strings"

	"github.com/dawndiy/douban-sdk"
)

type DoubanUser struct {
}

type LoginResult struct {
	Result  bool
	Message string
	User    doubanfm.User
}

func (user *DoubanUser) LoginOld(name, password, captcha, captchaID string) LoginResult {
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

func (user *DoubanUser) GetVerificationCode() {
	ch := make(chan Captcha)

	go func(ch chan Captcha) {
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
		ch <- captchaData
	}(ch)

	go func(ch chan Captcha) {
		captcha := <-ch
		handler := root.ObjectByName("doubanAPIHandler")
		argString := strings.Join([]string{captcha.CaptchaID, captcha.CaptchaImage}, ",")
		handler.Call("emitSignal", "captchaImageLoaded", argString)
	}(ch)
}

func (user *DoubanUser) Login(name, password, vCode, vCodeID string) {
	ch := make(chan LoginResult)

	go func(ch chan LoginResult) {
		result := LoginResult{}
		account, err := doubanfm.Login(name, password, vCode, vCodeID)
		log.Println("----------------", result)
		if err != nil {
			result.Result = false
			result.Message = err.Error()
		} else {
			result.Result = true
			result.User = account
			doubanfm.SetUser(account)
		}

		ch <- result
	}(ch)

	go func(ch chan LoginResult) {
		result := <-ch
		handler := root.ObjectByName("doubanAPIHandler")
		handler.Call("emitSignalWithObj", "loginCompleted", result)
	}(ch)
}
