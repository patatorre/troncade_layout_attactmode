//////////////////////////////////////////////////////////
// Musical Tron-cade
// Vertical layout for attract-mode front end https://attractmode.org/
//
// This is a basic layout that plays period-appropriate tunes.
// Left running, it will act as a jukebox. Songs are organized in a looping playlist.
// The songs names are hard-coded below, since there is no way to read directories
//
// Patrick Dumais
// Sep 2024
///////////////////////////////////////////////////////// 

// Layout User Options
class UserConfig {
 </ label="Jukebox", help="Play period-appropriate music according to current selection", options="Yes,No" /> enable_jukebox="Yes";
 </ label="Active highlight", help="Actively highlight current selection", options="Yes,No" /> enable_active_highlight="Yes";
 </ label="Active highlight speed", help="Higher the number, faster it goes", options="1,2,4,10,20,50" /> user_glow_step="10";
}
local my_config = fe.get_config();

// Layout Constants
local lh = 640;
local lw = 480;
fe.layout.width=lw;
fe.layout.height=lh;
//local lw=fe.layout.width;
//local lh=fe.layout.height;

local current_playlist_index = null;
local current_song = null;
local tick_timer = 0;
local highlight_active = 0;
local current_selectbg = 255;
local glow_step = -1  * my_config["user_glow_step"].tofloat();
local trig_play_song = 0;

/////////////////////////
// songs lists

local music_late_70s = ["01 Call Me.m4a",
						"01 Main Title.m4a",
						"06 Le Freak.m4a",
						"06 Stayin' Alive.m4a",
						"26 Just What I Needed.m4a"];

local music_early_80s = [   "01 Call Me.m4a",
							"1-02 Rock The Casbah.m4a",
							"1-04 Blue Monday.m4a",
							"1-05 Super Freak.m4a",
							"02 Sweet Dreams.m4a",
							"02 Tainted Love.m4a",
							"02 This Is the Day.m4a",
							"2-09 Don't Stop Believin'.m4a",
							//"06 One Night In Bangkok.m4p",
							//"06 Talking In Your Sleep.m4p",
							"07 You Shook Me All Night Long.m4a",
							"13 Jump.m4a",
							"Laura Branigan - Self Control.mp3",
							"Sunday Bloody Sunday.mp3"];
							
local music_mid_80s = [ "1-03 Fall On Me (Remastered).m4a",
						"1-06 Smalltown Boy (Remastered).m4a",
						"1-09 Summer Of '69.m4a",
						"02 Major Tom (Völlig Losgelöst).m4a",
						//"02 Self Control.m4p",
						"03 Livin' On a Prayer.m4a",
						"03 The Power of Love.m4a",
						"04 Fade to Black.m4a",
						"07 Fight for Your Right.m4a",
						"Bronski Beat - Smalltown Boy.mp3", 
						"07 How Soon Is Now_.m4a"];
						
local music_late_80s = ["01 Its A Sin.mp3",
						"01 She Drives Me Crazy.m4a",
						"06 It's the End of the World As We K.m4a",
						"01 Welcome to the Jungle.m4a",
						"04 Love Shack.m4a",
						"01 Like a Prayer.m4a",
						"02 Wild Thing.m4a"
						];
local music_early_90s = ["04 The Sign (Remastered).m4a"];

function make_playlist(fileList) {
	local n_items = fileList.len();
	// first, make an ordered list of the appropriate size
	local ordered_list = [];
	local playlist = [];
	
	for (local index = 0 ; index < n_items ; index = index + 1) {
		ordered_list.append(index);
	}
	local current_length = n_items;
	for (local index = 0 ; index < n_items ; index = index + 1) {
		local randomIndex = rand() % current_length;
		current_length = current_length - 1;
		playlist.append(ordered_list[randomIndex]);
		ordered_list.remove(randomIndex);
		//print(playlist[index] + " ")
	}
	//print("\n");
	return(playlist);
}

local music_dir = "C:\\Users\\patrick\\attract\\sounds\\musik\\"

local all_music = [ {"directory":music_dir + "1977_1979\\", "list": music_late_70s, "playlist":make_playlist(music_late_70s)},
					{"directory":music_dir + "1980_1983\\", "list": music_early_80s, "playlist":make_playlist(music_early_80s)},
					{"directory":music_dir + "1984_1986\\", "list": music_mid_80s, "playlist":make_playlist(music_mid_80s)},
					{"directory":music_dir + "1987_1989\\", "list": music_late_80s, "playlist":make_playlist(music_late_80s)},
					{"directory":music_dir + "1990_1994\\", "list": music_early_90s, "playlist":make_playlist(music_early_90s)} ];

local playlist_index_by_year  = {
		"1977": 0, "1978": 0, "1979": 0,
		"1980": 1, "1981": 1, "1982": 1, "1983": 1,
		"1984": 2, "1985": 2, "1986": 2,
		"1987": 3, "1988": 3, "1989": 3,
		"1990": 4, "1991":4, "1992": 4, "1993": 4};

//		
// Plays a period-appropriate song for the game currently selected
//
function play_me_a_tune() {

    if (my_config["enable_jukebox"] == "No") return(false);

    // Get the year of the currently highlighted game
    local gameYear = fe.game_info(Info.Year).tointeger();
	if (gameYear > 1993) gameYear = 1993;
	local yearString = gameYear.tostring();
	//print(yearString);
	
	//Figure out which playlist that falls into
    local this_playlist = playlist_index_by_year[yearString] != null ? playlist_index_by_year[yearString] : null;
	
    // Check if the current selection has the same year as the song playing
    if (current_playlist_index != null && this_playlist == current_playlist_index) {
		if (current_song.playing == true) {
			// The song for this year is already playing, do nothing
			//print("Same year as current song. No new song will be played.\n");
			return;
		}
    }

    // Play the song for the current game year

    // Update the currently playing year
    current_playlist_index = this_playlist;
    //print("Now playing song for the year: " + gameYear + "\n");
	
	// get the music files list for the right year
	
	local which_set = all_music[current_playlist_index]
	local which_list = which_set["list"];
	local which_dir = which_set["directory"];
	local which_playlist = which_set["playlist"]
	
	// local filename = choose_random_from_list(which_list);
	local filename = which_list[which_playlist[0]];
	// rotate playlist
	which_playlist.append(which_playlist[0]);
	which_playlist.remove(0);
	all_music[current_playlist_index]["playlist"] = which_playlist;

	if (filename != null) {
		print("Randomly selected file: " + filename + "\n");
	} else {
		print("No files found in the directory.\n");
	}

	local filename_fullpath = which_dir + filename;
	if (current_song != null) {
		current_song.playing = false; // stop it ? works ? 
	}
	current_song = fe.add_sound(filename_fullpath);
	current_song.playing = true;
}

/////////////////////////////////////////////////////////
// On Screen Objects

local t = fe.add_artwork( "snap", 257, 171 , 192, 262 );
t.trigger = Transition.EndNavigation;

t = fe.add_artwork( "marquee", 33, 74, 418, 72 );
t.trigger = Transition.EndNavigation;

local lb = fe.add_listbox( 33, 171, 194, 396 );
lb.charsize = 16;
lb.set_selbg_rgb( 255, 255, 255 );
lb.set_sel_rgb( 0, 0, 0 );
lb.sel_style = Style.Bold;

fe.add_image( "bg.png", 0, 0 );

local l = fe.add_text( "[Year]", 260, 475, 230, 60 );
l.set_rgb( 200, 200, 70 );
l.align = Align.Left;
l.style = Style.Bold;

l = fe.add_text( "[Manufacturer]", 255, 540, 200, 16 );
l.set_rgb( 200, 200, 70 );
//l.align = Align.Left;

l = fe.add_text( "[ListEntry]/[ListSize]", 320, 424, 290, 16 );
l.set_rgb( 200, 200, 70 );
l.align = Align.Right;


// Ticks
fe.add_ticks_callback("highlight_title");
function highlight_title( ttime ) {
	// animation
	tick_timer = tick_timer + 1;
	if (tick_timer > 100) {
		tick_timer = 0;
		highlight_active = 1;
	}
	if ((highlight_active > 0) && (my_config["enable_active_highlight"] == "Yes")) {
		current_selectbg = current_selectbg + glow_step;
		if (current_selectbg > 255) {
			current_selectbg = 255;
			glow_step = -10;
		}
		if (current_selectbg < 0) {
			current_selectbg = 0;
			glow_step = 10;
		}
				
		lb.set_selbg_rgb( current_selectbg, current_selectbg, current_selectbg );
		lb.set_sel_rgb( 255-current_selectbg, 255-current_selectbg, 255-current_selectbg );
	}
	
	// audio: if song stopped playing, get a new one going

	if ( (current_song != null) && (my_config["enable_jukebox"] == "Yes") ){
		if (current_song.playing == false) play_me_a_tune(); //fe.signal("reload");
	}
		
}


// Transitions
fe.add_transition_callback( "audio_transitions" );
function audio_transitions( ttype, var, ttime ) {
	switch ( ttype ) {
		case Transition.ToNewList:
			var = 0;
		case Transition.ToNewSelection:
			print("Transition.ToNewSelection\n");

			// reset animation
			tick_timer = 0; 
			highlight_active = 0;
			current_selectbg = 255;
			lb.set_selbg_rgb( 255, 255, 255 );
			lb.set_sel_rgb( 0, 0, 0 );

			play_me_a_tune();

			break;

  }
 return false;
}
