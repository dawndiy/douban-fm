import QtQuick 2.4
import QtMultimedia 5.0
import Ubuntu.Components 1.2
import Ubuntu.Connectivity 1.0
import UserMetrics 0.1
import QtQuick.LocalStorage 2.0
import "js/database.js" as Database
import "js/weibo.js" as WeiboAPI

// import QtSystemInfo 5.0

import "ui"


MainView {

    id: root

    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "douban-fm.ubuntu-dawndiy"

    /*
     This property enables the application to change orientation
     when the device is rotated. The default is false.
    */
    //automaticOrientation: true

    width: units.gu(50)
    height: units.gu(75)

    // Connections {  
    //     target: NetworkingStatus  
    //     // full status can be retrieved from the base C++ class  
    //     // status property  
    //     onStatusChanged: {
    //     //onOnlineChanged: {
    //         console.log("name: " + value );  
  
    //         if (value === NetworkingStatus.Offline)  
    //             console.log("Status: Offline")  
    //         if (value === NetworkingStatus.Connecting)  
    //             console.log("Status: Connecting")  
    //         if (value === NetworkingStatus.Online)  
    //             console.log("Status: Online")  
    //     }  
    // } 


    Metric {
        id: playedMetric
        name: "douban-fm-metrics"
        format:  i18n.tr("Douban-FM played <b>%1</b> songs today")
        emptyFormat: i18n.tr("No songs Douban-FM played today")
        domain: "douban-fm.ubuntu-dawndiy"
        minimum: 0.0
    }


    // 页面栈
    PageStack {
        id: pageStack
        Component.onCompleted: {
            push(doubanPage)
            // push(test)
        }

        // 主页面
        DoubanPage {
            id: doubanPage
            visible: false
            title: i18n.tr("Douban FM")
        }

        // 频道页面
        ChannelPage {
            id: channelPage
            title: i18n.tr("Channels")
            visible: false
        }

        // 设置页面
        SettingsPage {
            id: settingsPage
            title: i18n.tr("Settings")
            visible: false
        }

        SharePage {
            id: sharePage
            title: i18n.tr("Share")
            visible: false
        }

        WeiboLoginPage {
            id: weiboLoginPage
            title: i18n.tr("Login Weibo")
            visible: false
        }

        EggsPage {
            id: eggsPage
            title: "eggs"
            visible: false
        }

        // =============================================================
        //
        //  TEST
        //
        // =============================================================

        Page {
            id: test
            visible: false
            title: i18n.tr("TEST")
            Text {
                text: NetworkingStatus.online
            }
            Column {  
                anchors.centerIn: parent  
                Label {  
                    // use the online property  
                    text: NetworkingStatus.online ? "Online" : "Not online"  
                    fontSize: "large"  
                }  
                Label {  
                    // use the limitedBandwith property  
                    text: NetworkingStatus.limitedBandwith ? "Bandwith limited" : "Bandwith not limited"  
                    fontSize: "large"  
                }  
                Label {
                    id: debugText
                    text: "Normal"
                }
            }


            // Component.onCompleted: {
            //     var keys = Object.keys(sysinfo)
            //     for (var i = 1; i < keys.length; i++) {
            //         var key = keys[i];
            //         console.log(key + " : " + sysinfo[key]);
            //     }
            // }
        }

        // NetworkInfo {
        //     id: sysinfo
        // }
    }
}
