package main

import (
	"crypto/md5"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
)

type Room struct {
	Exits   map[string]string
	Writing string
	Order   int
}

type Labyrinth struct {
	Rooms       map[string]*Room
	StartRoomId string
	BrokenRooms []string
	Challenge   string
}

type ReportRequest struct {
	RoomIds   []string `json:"roomIds"`
	Challenge string   `json:"challenge"`
}

type RoomIdResponse struct {
	RoomId string `json:"roomId"`
}

type WallResponse struct {
	Writing string `json:"writing"`
	Order   int    `json:"order"`
}

type ExitsResponse struct {
	Exits []string `json:"exits"`
}

func randString(n int) string {
	const alphanum = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	var bytes = make([]byte, n)
	for i, _ := range bytes {
		bytes[i] = alphanum[rand.Intn(len(alphanum))]
	}
	return string(bytes)
}

func createLabyrinth(email string) *Labyrinth {
	data := md5.Sum([]byte("ATDEVCHALLENGE|" + email))
	emailSeed, _ := binary.Varint(data[:8])
	fmt.Printf("%x %d", data, emailSeed)
	rand.Seed(emailSeed)

	emptyRooms := 5 + rand.Intn(10)
	validRooms := 40 + rand.Intn(10)
	totalRooms := emptyRooms + validRooms

	lab := new(Labyrinth)
	lab.Rooms = make(map[string]*Room)
	lab.Challenge = randString(validRooms)
	lab.BrokenRooms = make([]string, emptyRooms)

	allRoomIds := make([]string, totalRooms)
	perm := rand.Perm(totalRooms)
	for i, v := range perm {
		room := new(Room)
		roomId := randString(20)
		if v < emptyRooms {
			room.Writing = "xx"
			room.Order = -1
			lab.BrokenRooms[v] = roomId
		} else {
			room.Writing = string(lab.Challenge[v-emptyRooms])
			room.Order = v
		}
		lab.Rooms[roomId] = room
		if lab.StartRoomId == "" {
			lab.StartRoomId = roomId
		} else {
			for true {
				parentRoom := lab.Rooms[allRoomIds[rand.Intn(i)]]
				// add exit to parent room
				if parentRoom.Exits == nil {
					parentRoom.Exits = make(map[string]string)
				}
				possible_dirs := []string{"north", "west", "east", "south"}
				candidate_dir := possible_dirs[rand.Intn(len(possible_dirs))]
				if parentRoom.Exits[candidate_dir] != "" {
					continue
				} else {
					parentRoom.Exits[candidate_dir] = roomId
					break
				}
			}
		}
		allRoomIds[i] = roomId
	}
	return lab
}

func labyrinthFromRequest(r *http.Request) *Labyrinth {
	email := r.Header.Get("X-Labyrinth-Email")
	fmt.Println(email)
	if email == "" {
		return nil
	}
	lab := createLabyrinth(email)
	return lab
}

func roomFromRequestOrNotFound(lab *Labyrinth, w http.ResponseWriter, r *http.Request) *Room {
	queryParams := r.URL.Query()
	roomIds := queryParams["roomId"]
	if len(roomIds) == 0 {
		return nil
	}
	roomId := roomIds[0]
	room := lab.Rooms[roomId]
	return room
}

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		resp := `You are a maintenance worker of a cyberspace labyrinth, tasked with creating a report of all the rooms in the labyrinth where the lights are no longer functional.  The labyrinth has the following HTTP Interface:

(all requests must contain the header X-Labyrinth-Email: <your email address>)

GET /start
// This tells you the room that you start in.
returns {
  roomId: '<roomId of first room>'
};

GET /exits?roomId=<roomId>
// This allows you to see which exits are available for this current room.
returns {
  exits: ['north', 'south', 'east', 'west']
}

GET /move?roomId=<roomId>&exit=<exit>
// This allows you to see what the roomId is through an exit.
returns {
  roomId: '<roomId of room connected by exit>'
}

GET /wall?roomId=<roomId>
// This allows you to see what the writing is on the wall for a particular room if the lights are working.
returns {
   writing: '<string>'
   order: <number>
}

// If the lights aren't working
returns {
  writing: 'xx'
  order: -1
}

POST /report
// Submit your maintenance report to the mothership. Because the mothership knows that some workers are lazy and untruthful, the mothership requires a challenge code that is made by concatenating all the 'writing' on the walls in lit rooms, in the order designated by 'order' from lowest to greatest.

body {
  roomIds: [array of room ids whose lights were broken],
  challenge: 'challenge code'
}

Note the /report expects a JSON-formatted post body.

The next steps will be apparent once the mothership approves your maintenance report.

Hint: If you get a 404, you probably are doing something wrong.
`

		fmt.Fprintf(w, resp)

	})

	http.HandleFunc("/start", func(w http.ResponseWriter, r *http.Request) {
		lab := labyrinthFromRequest(r)
		if lab == nil {
			http.NotFound(w, r)
			return
		}

		resp := &RoomIdResponse{
			RoomId: lab.StartRoomId,
		}
		mars, _ := json.Marshal(resp)
		fmt.Fprintf(w, string(mars))
	})

	http.HandleFunc("/wall", func(w http.ResponseWriter, r *http.Request) {
		lab := labyrinthFromRequest(r)
		if lab == nil {
			http.NotFound(w, r)
			return
		}

		room := roomFromRequestOrNotFound(lab, w, r)

		if room == nil {
			http.NotFound(w, r)
			return
		}

		resp := &WallResponse{
			Writing: room.Writing,
			Order:   room.Order,
		}
		mars, _ := json.Marshal(resp)
		fmt.Fprintf(w, string(mars))
	})

	http.HandleFunc("/exits", func(w http.ResponseWriter, r *http.Request) {
		lab := labyrinthFromRequest(r)
		if lab == nil {
			http.NotFound(w, r)
			return
		}

		room := roomFromRequestOrNotFound(lab, w, r)

		if room == nil {
			http.NotFound(w, r)
			return
		}
		var exits []string
		for dir := range room.Exits {
			exits = append(exits, dir)
		}
		resp := &ExitsResponse{
			Exits: exits,
		}
		mars, _ := json.Marshal(resp)
		fmt.Fprintf(w, string(mars))
	})

	http.HandleFunc("/move", func(w http.ResponseWriter, r *http.Request) {
		lab := labyrinthFromRequest(r)
		if lab == nil {
			http.NotFound(w, r)
			return
		}

		room := roomFromRequestOrNotFound(lab, w, r)

		if room == nil {
			http.NotFound(w, r)
			return
		}

		// check for exit
		exits := r.URL.Query()["exit"]
		if len(exits) == 0 {
			http.NotFound(w, r)
			return
		}
		exit := exits[0]
		exitRoomId := room.Exits[exit]
		if exitRoomId == "" {
			http.NotFound(w, r)
			return
		}
		resp := &RoomIdResponse{
			RoomId: exitRoomId,
		}
		mars, _ := json.Marshal(resp)
		fmt.Fprintf(w, string(mars))
	})

	http.HandleFunc("/report", func(w http.ResponseWriter, r *http.Request) {
		lab := labyrinthFromRequest(r)
		if lab == nil {
			http.NotFound(w, r)
			return
		}
		decoder := json.NewDecoder(r.Body)
		var req ReportRequest
		err := decoder.Decode(&req)
		if err != nil {
			fmt.Fprintf(w, "Mothership could not understand your report.")
			return
		}

		if req.Challenge != lab.Challenge {
			fmt.Fprintf(w, "Mothership deems your report inaccurate.")
			return

		}
		brokenRoomMap := make(map[string]bool)
		for k := range lab.BrokenRooms {
			brokenRoomMap[lab.BrokenRooms[k]] = true
		}

		for i := range req.RoomIds {
			roomId := req.RoomIds[i]
			_, ok := brokenRoomMap[roomId]
			if ok {
				delete(brokenRoomMap, roomId)
			} else {
				fmt.Fprintf(w, "Mothership deems your report inaccurate.")
				return
			}
		}

		left := 0
		for v, k := range brokenRoomMap {
			fmt.Println(v, k)
			left = left + 1
		}
		if left > 0 {
			fmt.Fprintf(w, "Mothership deems your report incomplete.")
			return
		}

		fmt.Fprintf(w, "Congratulations!  Your work is complete.  Please send your code to cesar@poa.nyc")
		return
	})

	log.Fatal(http.ListenAndServe(":7182", nil))
}
