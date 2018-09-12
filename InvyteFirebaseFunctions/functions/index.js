const functions = require('firebase-functions');
const admin = require('firebase-admin')
admin.initializeApp(functions.config().firebase)
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });
console.log("it works!")

// https://us-east1-codedayle-b3030.cloudfunctions.net/cleanData
// https://us-central1-codedayle-b3030.cloudfunctions.net/cleanTheData
//exports.cleanData = functions.database.ref("/").onWrite (event => {

exports.cleanTheData = functions.https.onRequest((request, response) => {   
    let ref = admin.database().ref('/') 
    console.log("CLEANING DATA")
    let today = new Date()

    /*

    let cleanDataRef = event.data.ref.parent.ref()
    data.lastCall = today.getTime()
    */
    let defer = new Promise((resolve,reject) => {
        ref.once('value', (snap) => {
            resolve(snap.val(), snap)
        }, (err) => {
            response.send("Failed")
            reject(err, err)
        })
    })
    
    return defer.then((data,event) => {
        return useData(data,event,response)
    })
    //response.send("Cleaning Data")
})

function isDateHourPastCurrentDate(day,month,year,hour,minute,millisecondsFromEST) {
    if (day < 10) {
        day = '0' + day
    }
    if (month < 10) {
        month = '0' + month
    }
    if (minute < 10) {
        minute = '0' + minute
    }
    if (hour < 10) {
        hour = '0' + hour
    }
    let hourInMilliseconds = 3600000
    var today = new Date()
    var eventDate = new Date(year + '-' + month + '-' + day + 'T' + hour + ':' + minute + ':00')
    let difference = today.getTime() - (eventDate.getTime() + hourInMilliseconds - millisecondsFromEST)
    //console.log(difference)
    return difference > hourInMilliseconds
}

function useData(data,event,response) {
    //console.log(event.data)
    var counter = 0
    var keysForEventsToBeDeleted = []
    for (var key in data["Events"]) {
        const eventRef = data["Events"]
        const event = eventRef[key]
        if (isDateHourPastCurrentDate(event.day,event.month,event.year,event.hour,event.minute,event.millisecondsFromEST)) {
            keysForEventsToBeDeleted.push(key)
        }
        //console.log("New Event --------------------")
    }
    console.log(keysForEventsToBeDeleted)
    if (keysForEventsToBeDeleted.length == 0) {
        response.send("Nothing needs to be deleted!")
    }
    else {
        for (let key in keysForEventsToBeDeleted) {
            //let ref = functions.database().ref("Events/" + key)
            
            admin.database().ref("Events/" + keysForEventsToBeDeleted[key]).on("value", function(snapshot) {
                const eventRef = data["Events"]
                const event = eventRef[keysForEventsToBeDeleted[key]]
                const isPublic = event.isPublic
                if (snapshot.exists()) {
                    if (!isPublic) {
                        return removeEvent(snapshot,event,data,keysForEventsToBeDeleted[key],keysForEventsToBeDeleted,response)
                    }
                    else {
                        return removePublicEvent(snapshot,event,data,keysForEventsToBeDeleted[key],keysForEventsToBeDeleted,response)
                    }
                }
                else {
                    console.log(keysForEventsToBeDeleted[key], " does not exist!")
                }
            })
        }
    }
}

function removeEvent(snap,selectedEvent,data,eventID,keysForEventsToBeDeleted,response) {
    console.log("REMOVING PRIVATE EVENT-------------------------------------------")
    console.log(selectedEvent)
    console.log(eventID)
    let createdByUID = selectedEvent.createdByUID
    let eID = eventID
    console.log(createdByUID)
    console.log("Deleting event:")
    snap.ref.remove()
    
    let creatorRef = admin.database().ref("Users/User: " + createdByUID)
    creatorRef.once("value").then(function(snapshot) {
        let usersRef = data["Users"]
        console.log(snapshot.val())
        console.log("SnapVal:")
        console.log(usersRef)
        console.log(usersRef[createdByUID])
        console.log("User:")
        let userRef = usersRef["User: " + createdByUID]
        console.log(userRef["createdEvents"])
        console.log("Before deleting from createdEvents:")
        let createdEventsData = data["Users"]["User: " + createdByUID].createdEvents//userRef["createdEvents"]
        console.log(createdEventsData)
        let createdEventsArr = createdEventsData.split(",")
        let index = createdEventsArr.indexOf(eID)
        if (index != -1) {
            createdEventsArr.splice(index,1)
        }
        let createdEvents = createdEventsArr.join()
        console.log(createdEvents)
        console.log("After deleting from createdEvents:")
        //userRef["createdEvents"] = createdEvents
        if (createdEventsData === createdEvents) {
            console.log("No change in createdEvents")
            //return
        }
        else {
            console.log("Change in createdEvents")
            //return creatorRef.child("createdEvents").set(createdEvents)
            admin.database().ref("Users/User: " + createdByUID + "/createdEvents").set(createdEvents)
        }
    //})

    let invitedFriendsArr = selectedEvent.invitedFriends.split(",")
    console.log(selectedEvent.invitedFriends)
    console.log("INVITED FRIENDS")

    /*
    for (var uid of invitedFriendsArr) {
        let invitedEventsRef = admin.database().ref("Users/User: " + uid + "/invitedEvents/" + eID)
        return invitedEventsRef.on("value", function(snapshot) {
            if (snapshot.exists()) {
                return removeSnapshot(snapshot,data,keysForEventsToBeDeleted,eID,response)
            }
            else {
                console.log("invalid reference")
                return 
            }
        })
    }
    */
    console.log("------------------------------")
    console.log("Array Length: " + invitedFriendsArr.length)
    console.log(invitedFriendsArr)
    var x = 0
    //var invitedEventsRef = admin.database().ref("Users/User: " + invitedFriendsArr[x] + "/invitedEvents/" + eID)
    /*
    var loopArray = function(uidArr) {
        console.log(x)
        console.log("OUTSIDE ASYNC")
        let invitedEventsRef = admin.database().ref("Users/User: " + uidArr[x] + "/invitedEvents/" + eID)
        return invitedEventsRef.on("value", function(snapshot) {
            console.log(invitedEventsRef.toString())
            console.log("Users/User: " + uidArr[x] + "/invitedEvents/" + eID)
            console.log(snapshot.val())
            console.log(x)
            console.log("INSIDE ASYNC")
            x++
            if (snapshot.exists()) {
                console.log("Valid reference")
                removeSnapshot(snapshot,data,keysForEventsToBeDeleted,eID,response)
            }
            else {
                console.log("invalid reference") 
            }
            
            if (x < uidArr.length) {
                invitedEventsRef = admin.database().ref("Users/User: " + uidArr[x] + "/invitedEvents/" + eID)
                loopArray(uidArr)
            }
            
        })
    }
    */

    var loopArray = function(uidArr) {
        console.log(x)
        console.log("OUTSIDE ASYNC")
        let invitedEventsRef = admin.database().ref("Users/User: " + uidArr[0] + "/invitedEvents/" + eID)
        return invitedEventsRef.on("value", function(snapshot) {
            console.log(invitedEventsRef.toString())
            console.log("Users/User: " + uidArr[0] + "/invitedEvents/" + eID)
            console.log(snapshot.val())
            console.log(x)
            console.log("INSIDE ASYNC")
            //x++
            if (snapshot.exists()) {
                console.log("Valid reference")
                removeSnapshot(snapshot,data,keysForEventsToBeDeleted,eID,response)
            }
            else {
                console.log("invalid reference") 
            }
            return uidArr
            /*
            if (uidArr.length > 1) {
                uidArr.splice(0,1)
                //invitedEventsRef = admin.database().ref("Users/User: " + uidArr[0] + "/invitedEvents/" + eID)
                loopArray(uidArr)
            }
            */
            
        }).then(uidArr => {
            if (uidArr.length > 1) {
                uidArr.splice(0,1)
                //invitedEventsRef = admin.database().ref("Users/User: " + uidArr[0] + "/invitedEvents/" + eID)
                loopArray(uidArr)
            }
        })
    }

    loopArray(invitedFriendsArr)

}).then(respondIfDataIsCleaned(keysForEventsToBeDeleted,eventID,response))
    
}

function respondIfDataIsCleaned(keysForEventsToBeDeleted,eventID,response) {
    let i = keysForEventsToBeDeleted.indexOf(eventID)
                if (i > -1) {
                    keysForEventsToBeDeleted.splice(i,1)
                }
                else {
                    console.log("This event was not in the list of keys to be deleted")
                }

                if (keysForEventsToBeDeleted.length == 0) {
                    response.send("Data Cleaned 1")
                }
}

function removeSnapshot(snapshot,data,keysForEventsToBeDeleted,eventID,response) {
    console.log("DATA CLEANED IN A FRIEND'S INVITED FRIENDS PATH")
    //console.log(snapshot.val())
    //console.log(snapshot.ref.toString())

    if (snapshot.exists()) {
        //console.log("INVITED EVENTS SNAPSHOT EXISTS")
        snapshot.ref.remove()

        /*
        let i = keysForEventsToBeDeleted.indexOf(eventID)
        if (i > -1) {
            keysForEventsToBeDeleted.splice(i,1)
        }
        else {
            console.log("This event was not in the list of keys to be deleted")
        }

        if (keysForEventsToBeDeleted.length == 0) {
            response.send("Data Cleaned 1")
        }
        */
        //return
    }
    else {
        //return
    }
}

function removePublicEvent(snap,selectedEvent,data,eventID,keysForEventsToBeDeleted,response) {
    let createdByUID = selectedEvent.createdByUID
    let eID = eventID
    snap.ref.remove()
    let creatorRef = admin.database().ref("Users/User: " + createdByUID)
    return creatorRef.once("value").then(function(snapshot) {
        let usersRef = data["Users"]
        console.log(usersRef[createdByUID])
        console.log("User:")
        let userRef = usersRef["User: " + createdByUID]
        console.log(userRef["createdEvents"] + "\nCreated Events:")
        console.log("Before deleting from createdEvents:")
        let createdEventsData = userRef["createdEvents"]
        let createdEventsArr = createdEventsData.split(",")
        let index = createdEventsArr.indexOf(eID)
        if (index != -1) {
            createdEventsArr.splice(index,1)
        }
        let createdEvents = createdEventsArr.join()
        console.log(createdEvents)
        console.log("After deleting from createdEvents:")
        //userRef["createdEvents"] = createdEvents
        if (createdEvents === createdEventsData) {
            
            
            let i = keysForEventsToBeDeleted.indexOf(eventID)
            if (i > -1) {
                keysForEventsToBeDeleted.splice(i,1)
            }
            else {
                console.log("This event was not in the list of keys to be deleted")
            }

            //no more events to delete
            if (keysForEventsToBeDeleted.length == 0) {
                response.send("Data Cleaned 1")
            }
            
            return
        }
        else {
            creatorRef.child("createdEvents").set(createdEvents)//.then({
                
                let i = keysForEventsToBeDeleted.indexOf(eventID)
                if (i > -1) {
                    keysForEventsToBeDeleted.splice(i,1)
                }
                else {
                    console.log("This event was not in the list of keys to be deleted")
                }

                //no more events to delete
                if (keysForEventsToBeDeleted.length == 0) {
                    response.send("Data Cleaned 1")
                }
                
                return
            //})

        }
    })
}


exports.sendNewFriendPush = functions.database.ref('/Users/{userID}/addedYouFriends').onWrite(event => {
    let data = event.data.val()
    let prevData = event.data.previous.val()
    let prevDataExists = event.data.previous.exists
    
    //userID is User: {uid}
    let userID = event.params.userID
    
    if (!(prevDataExists)) {
        let newFriendID = Object.keys(data)[0]

        return getTokens(userID).then(pushTokens => {
            return getUsername(newFriendID).then(newFriendUsername => {

                if (pushTokens !== null) {
                    let tokens = []
                    let badgeNums = []
                    for (var token in pushTokens) {
                        let badgeNum = pushTokens[token]
                        tokens.push(token)
                        badgeNums.push(badgeNum)

                        //userID is 'User: {uid}'
                        let ref = admin.database().ref('/Users/' + userID + '/pushTokens')
                        ref.child(token).set(badgeNum + 1)
                    }
                    let badge = (badgeNums[0] + 1) + ''
                    let payload = {
                        notification: {
                            title: 'New Friend',
                            body: newFriendUsername + ' just added you',
                            sound: 'default',
                            badge: badge
                        }
                    };
                    return admin.messaging().sendToDevice(tokens, payload);
                }
                else {
                    return
                }
            })
        })
    }
    else if (Object.keys(prevData).length < Object.keys(data).length) {
        let newFriendID = getNewData(data,prevData)

        return getTokens(userID).then(pushTokens => {
            return getUsername(newFriendID).then(newFriendUsername => {

                if (pushTokens !== null) {
                    let tokens = []
                    let badgeNums = []
                    for (var token in pushTokens) {
                        let badgeNum = pushTokens[token]
                        tokens.push(token)
                        badgeNums.push(badgeNum)

                        //userID is 'User: {uid}'
                        let ref = admin.database().ref('/Users/' + userID + '/pushTokens')
                        ref.child(token).set(badgeNum + 1)
                    }
                    let badge = (badgeNums[0] + 1) + ''
                    let payload = {
                        notification: {
                            title: 'New Friend',
                            body: newFriendUsername + ' just added you',
                            sound: 'default',
                            badge: badge
                        }
                    };
                    return admin.messaging().sendToDevice(tokens, payload);
                }
                else {
                    return
                }

            })
        })
    }

});

function getTokens(userID) {
    let uid = userID.split(" ")[1]
    let ref = admin.database().ref('/Users/User: ' + uid + '/pushTokens')
    console.log(ref)
    let defer = new Promise((resolve, reject) => {
        ref.once('value', (snap) => {
            let data = snap.val();
            let pushTokens = data
            console.log("RESOLVED")
            resolve(data);
        }, (err) => {
            console.log("ERROR")
            console.log(err)
            reject(err);
        });
    });
    return defer;
}

exports.sendEventPush = functions.database.ref("/Users/{userID}/invitedEvents").onWrite(event => {
    let userID = event.params.userID
    console.log("Sending push notification to the devices of User " + userID)
    let data = event.data.val()
    let prevData = event.data.previous.val()
    let prevDataExists = event.data.previous.exists()
    console.log(prevData)
    console.log(prevDataExists)
    if (!(prevDataExists)) {
        let eventID = Object.keys(data)[0]
        return getEventInfo(userID,eventID).then(data => {
            if (data[1] !== null) {
                let creatorUsername = data[0]
                let pushTokens = data[1]
                let tokens = []
                let badgeNums = []
                for (var token in pushTokens) {
                    let badgeNum = pushTokens[token]
                    tokens.push(token)
                    badgeNums.push(badgeNum)

                    //userID is 'User: {uid}'
                    let ref = admin.database().ref('/Users/' + userID + '/pushTokens')
                    ref.child(token).set(badgeNum + 1)
                }
                let badge = (badgeNums[0] + 1) + ''

                let payload = {
                    notification: {
                        title: 'New Event',
                        body: creatorUsername + ' just invited you to an event!',
                        sound: 'default',
                        badge: badge
                    }
                };
                return admin.messaging().sendToDevice(tokens, payload);
            }
            else {
                return
            }
        })
        
    }
    else if (Object.keys(prevData).length < Object.keys(data).length) {
        let eventID = getNewData(data,prevData)
        
        return getEventInfo(userID,eventID).then(data => {

            if (data[1] !== null) {
                let creatorUsername = data[0]
                let pushTokens = data[1]
                let badgeNums = []
                let tokens = []
                for (var token in pushTokens) {
                    let badgeNum = pushTokens[token]
                    tokens.push(token)
                    badgeNums.push(badgeNum)

                    //userID is 'User: {uid}'
                    let ref = admin.database().ref('/Users/' + userID + '/pushTokens')
                    ref.child(token).set(badgeNum + 1)
                }

                let badge = (badgeNums[0] + 1) + ''

                let payload = {
                    notification: {
                        title: 'New Event',
                        body: creatorUsername + ' just invited you to an event!',
                        sound: 'default',
                        badge: badge
                    }
                };
                return admin.messaging().sendToDevice(tokens, payload);
            }
            else {
                console.log("No devices associated with this account: (" + userID + ")")
                return
            }
        })
    }
})

function getEventInfo(userID,eventID) {
    let uidRef = admin.database().ref('/Events/' + eventID + '/createdByUID')
    //let ref = admin.database().ref('/Events/' + eventID + '/invitedFriends')
    /*
    let allPushTokens = {}
    return ref.once('value', (snap) => {
        console.log('/Events/' + eventID + '/invitedFriends')
        console.log(snap.val())
        
        let friendsArr = snap.val().split(',')
        var countArr = snap.val().split(',')
        console.log(friendsArr)
        for (var friendIndex in friendsArr) {
            let friendUID = friendsArr[friendIndex]
            console.log(friendUID)
            console.log("FRIEND:")
            */
            return getTokens(userID).then(pushTokens => {
                /*
                console.log("DNEIRF")
                console.log(pushTokens)
                console.log(allPushTokens)
                console.log()
                let index = countArr.indexOf(friendUID)
                if (index > -1) {
                    countArr.splice(index,1)
                }
                //moves all pushTokens into allPushTokens
                console.log("Length    ||    " + countArr.length)
                console.log(countArr)
                Object.assign(allPushTokens,pushTokens)
                */
                    let defer = new Promise((resolve,reject) => {
                        uidRef.once('value', (snap) => {
                            let creatorID = snap.val()
                            return getUsername(creatorID).then(username => {
                                console.log('--------------------')
                                console.log(uidRef)
                                console.log("Ref: ")
                                console.log(snap.val())
                                console.log("SnapVal: ")
                                console.log(creatorID)
                                console.log("CreatorID: ")
                                console.log(pushTokens)
                                console.log("Push Tokens: ")
                                console.log('--------------------')
                                console.log(username)
                                //return [username,pushTokens]
                                resolve([username,pushTokens])
                            })

                        }, (err) => {
                            //return [username,pushTokens]
                            reject([err,pushTokens])
                        })
                    })

                    return defer
            })
        /*
        }
    })
    */
}

function getUsername(creatorID) {
    let ref = admin.database().ref('Users/User: ' + creatorID + '/username')
    let defer = new Promise((resolve,reject) => {
        ref.once('value', (snap) => {
            let creatorUsername = snap.val()

            resolve(creatorUsername)
        }, (err) => {
            reject(err)
        })
    })

    return defer
}

function getNewData(data,prevData) {
    let eventID = ""
    let oldEvents = Object.keys(prevData)
    let newEvents = Object.keys(data)
    let isOldEvent = false
    for (var newEvent of newEvents) {
        for (var oldEvent of oldEvents) {
            if (newEvent == oldEvent) {
                isOldEvent = true
            }
            isOldEvent = false
        }
        if (!isOldEvent) {
            eventID = newEvent
        }
    }

    return eventID

}
//-KqBg7xPI6W8LCeCD112

//User: Bz5A8yKSD1VUqxFmnJrGP3MPLyp2
//"-KqBg7xPI6W8LCeCD112,-KoyneHWfiCnde9cyjJ_,-KqENu9nx8Y7nrEP7lR0,-KqE_INNrqwKJdJ-dNN5"
//"enC0k4HTkdRdCo84WibQO8VVyMt2,0fxE1gNA81f9GhIVWX0aYrcQz4h1,Bus2fOpC6LcFXiQ26GIVsE7ASeH3,QNI7QmTy0XZYS1CfEzMjOEUzWus2,GOAjbyKgQUh0XMq8w9nHroMkqtC3,79XDuAFHzuUjiJfABRVxmspEsAf1,l43jmFqVtPRC977d5NQriSsxdR93,OmFGJhBlZdSJNB5xossx16Itaq13,9G403tnS4OSAg94TAxcxi4EU6tv2,fKfdnoxvt1cASKJMbTDoXXgexld2,2NQ6o8XQRDTdp4tHlDSKg9vxqDz1"
//-KpMuEl646kxsl9chlm4
//"https://firebasestorage.googleapis.com/v0/b/codedayle-b3030.appspot.com/o/Users%2FUser%3A%20Bz5A8yKSD1VUqxFmnJrGP3MPLyp2%2FprofilePicture?alt=media&token=b4e77218-c958-4cc8-9ca1-8f581767bc43"

