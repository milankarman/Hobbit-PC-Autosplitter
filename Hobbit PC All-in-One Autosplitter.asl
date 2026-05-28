/*
	An Autosplitter for The Hobbit PC (2003) on patch 1.3
	ASL originally made by MD_PI, revamped by Shockster_ as an all-in-one autosplitter!
	Worked on by:
		- Shockster_
		- MD_PI
*/

state("meridian")
{
	// Not sure what runLevel is exactly, but needed for kill bilbo (need to ask md_pi)
	float stamina : 0x35BA3C, 0xA04;
	float longjumpCount : 0x35C050;
	float loadSaveInstruction : 0x3641EC;
	bool runLevel : 0x360354;
	bool onCinema : 0x35CCE4;
	int cinemaID : 0x35CD00;
	float health : 0x35BDBC;
	bool onCutscene : 0x35CCE4;
	int cutsceneID : 0x35CD00; 
	bool loadScreen : 0x35F8C8;
	int levelQueued : 0x3631EC;
	int oolState : 0x362B58;
	int levelID : 0x362B5C;
	int menusOpen : 0x413038, 0x5C8;
}

startup
{
/*
	Autosplitter Settings.
*/
	settings.Add("ilseg", false, " ILs or Segment Practice");
	settings.SetToolTip("ilseg", " Choose Starting Level Only! If multiple checked, priority is first level as appears in order below.");
	settings.Add("desc", false, " Choose Starting Level Only!", "ilseg");
	settings.Add("desc2", false, " If multiple checked, priority is first level as appears in order below.", "ilseg");
	settings.Add("dw", false, " Dream World", "ilseg");
	settings.Add("aup", false, " An Unexpected Party", "ilseg");
	settings.Add("rm", false, " Roast Mutton", "ilseg");
	settings.Add("th", false, " Troll-Hole", "ilseg");
	settings.Add("oh", false, " Over Hill and Under Hill", "ilseg");
	settings.Add("ritd", false, " Riddles in the Dark", "ilseg");
	settings.Add("fas", false, " Flies and Spiders", "ilseg");
	settings.Add("boob", false, " Barrels out of Bond", "ilseg");
	settings.Add("aww", false, " A Warm Welcome", "ilseg");
	settings.Add("ii", false, " Inside Information", "ilseg");
	settings.Add("gotc", false, " Gathering of the Clouds", "ilseg");
	settings.Add("tcb", false, " The Clouds Burst", "ilseg");

	settings.Add("extraHeader", false, "                    ------------- Extra Settings -------------");
	settings.Add("signs", false, " Automatically Reset Riddles in the Dark Minecart Signs (Experimental)");
	settings.Add("resets", false, " Automatically Disable Resets When the Game Crashes");

	refreshRate = 120;
	vars.levelSplitID = -1;
	vars.levelStartID = -1;
	vars.resetSigns = false;

	vars.crashed = false;
	vars.noStartLevelMB = false;
	vars.mainMenuReached = false;
	vars.messageBoxTitle = "The Hobbit PC | LiveSplit";

	vars.timerModel = new TimerModel { CurrentState = timer };

	if(timer.CurrentTimingMethod == TimingMethod.RealTime){	
		var timingMessage = MessageBox.Show(
			"This game uses Game Time (time without loads) as the main timing method.\n"+
			"LiveSplit is currently set to show Real Time (time INCLUDING loads).\n"+
			"Would you like the timing method to be set to Game Time for you?",
			vars.messageBoxTitle, MessageBoxButtons.YesNo, MessageBoxIcon.Question, MessageBoxDefaultButton.Button1, MessageBoxOptions.DefaultDesktopOnly
		);
		if (timingMessage == DialogResult.Yes) timer.CurrentTimingMethod = TimingMethod.GameTime;
	}
}

init
{
	// All common reset actions are done here to avoid redundancy
	vars.resetAction = (Action)(() => 
	{
		// Set Switches back to normal.
		if (settings["signs"] && vars.resetSigns) 
		{
			memory.WriteBytes((System.IntPtr)(0x75B548), new byte[] {0x01,0,0,0,0,0,0,0,0,0,0,0,0x01,0,0,0,0,0,0,0});
			vars.resetSigns = false;
		}
		
		vars.levelSplitID = vars.levelStartID; 
	});

	// All common start actions are done here to avoid redundancy
	vars.startAction = (Action)(() => 
	{	
		if(settings["ilseg"]) vars.levelSplitID = vars.levelStartID;
		else
		{
			vars.levelSplitID = 0;
		}
		vars.noStartLevelMB = false; 
	});

	// Create eventhandlers to bind
	vars.resetEventHandler = (LiveSplit.Model.Input.EventHandlerT<TimerPhase>)((s, e) => vars.resetAction());
	vars.startEventHandler = (EventHandler)((s, e) => vars.startAction());

	// Bind event handlers
	timer.OnReset += vars.resetEventHandler;
	timer.OnStart += vars.startEventHandler;

/*
	Set AWW crash to true to disable resetting function when back in game
	Very Useful for categories like AQ where save jump is present.
*/
	if(vars.crashed) System.Threading.Tasks.Task.Factory.StartNew(() => { 
		while(vars.crashed)
		{
			if(vars.mainMenuReached && current.levelID > -1) vars.crashed = false;
		}
	});
}

update
{
	if(current.oolState == 6 && !vars.mainMenuReached) vars.mainMenuReached = true;
	if(current.levelQueued != -1 && current.levelQueued < vars.levelSplitID)
	{
		if(vars.levelSplitID > current.levelID)
		{
			vars.timerModel.UndoSplit();
			vars.levelSplitID--;
		}
	}
	
	if(settings["ilseg"])
	{	
		if(settings["dw"]) vars.levelStartID = 0;
		else if(settings["aup"]) vars.levelStartID = 1;
		else if(settings["rm"]) vars.levelStartID = 2;
		else if(settings["th"]) vars.levelStartID = 3;
		else if(settings["oh"]) vars.levelStartID = 4;
		else if(settings["ritd"]) vars.levelStartID = 5;
		else if(settings["fas"]) vars.levelStartID = 6;
		else if(settings["boob"]) vars.levelStartID = 7;
		else if(settings["aww"]) vars.levelStartID = 8;
		else if(settings["ii"]) vars.levelStartID = 9;
		else if(settings["gotc"]) vars.levelStartID = 10;
		else if(settings["tcb"]) vars.levelStartID = 11;
	}
	else vars.levelStartID = -1;
}

start
{
	// If timer is running or not at main menu, we don't need to check for start conditions.
	if(timer.CurrentPhase != TimerPhase.NotRunning && !vars.mainMenuReached && !settings["ilseg"]) return false;

	// IL and Segment runs start conditions.
	if(settings["ilseg"])
	{
		// If we have a start level selected, get ready to start.
		if(current.levelID == vars.levelStartID)
		{
			// Start condition for dreamworld ILs or segments starting from there.
			if(vars.levelStartID == 0 && current.oolState != 19) return true;

			// Start condition for other levels.
			if(current.oolState == 19)	return true;
		}
		// If we don't have a start level selected, don't start.
		else if(vars.levelStartID == -1 && !vars.noStartLevelMB)
		{
			System.Threading.Thread.Sleep(1000);
			vars.noStartLevelMB = true;
			MessageBox.Show(
				"Please select starting level for IL or Segment timing!", 
				vars.messageBoxTitle, MessageBoxButtons.OK, MessageBoxIcon.Error, MessageBoxDefaultButton.Button1, MessageBoxOptions.DefaultDesktopOnly
			);
			return false;
		}
	}
	else
	{
		// Default start conditions for non practice.
		if (current.oolState == 17 && (old.oolState == 9 || old.oolState == 6) && current.menusOpen < 2) 
		{
			// If running menu glitches and not enough splits are present, give warning.
			if(timer.Run.CategoryName == "Major Glitches" && timer.Run.Count != 4) MessageBox.Show(
				"Please include splits for Dream World, OHaUH, AWW and Final split to work correctly!", 
				vars.messageBoxTitle, MessageBoxButtons.OK, MessageBoxIcon.Warning, MessageBoxDefaultButton.Button1, MessageBoxOptions.DefaultDesktopOnly);
			return true;
		}
	}
}

split
{
	// If timer isn't running, we don't need to check split conditions.
	if(timer.CurrentPhase != TimerPhase.Running) return false;
	
	// Reset Sign check to see if Riddles was Reached
	if(current.levelID == 5) vars.resetSigns = true;

	// Only need different final split condition for kill bilbo.
	// Split if health is 0 during gameplay
	if(timer.Run.CategoryName == "Kill Bilbo" && current.health == 0 && current.runLevel && !current.loadScreen) return true;
	// Split conditions for menu glitches, since its the only category that skips around.
	// We put all conditions out here and even the final condition because of how unique it is.
	else if(timer.Run.CategoryName == "Major Glitches" && timer.CurrentSplitIndex > 0) 
	{
		if (current.levelID == 4) return true;
		else if(current.levelID == 8) return true;
		// Split if playing the storybook cinema for The Clouds Burst, which is necessary for major glitches.
		else if(current.levelID > 11 && current.oolState == 17) return true;
	}
	// If full game run, we need to check for those split conditions.
	else
	{
		// End of run check first. If not, check for other levels.		
		if (current.levelID > 10 && current.onCinema && current.cinemaID == 0x3853B400)
    	{
			if(settings["ilseg"]) vars.levelSplitID = vars.levelStartID;
			else vars.levelSplitID = -1; 
    	    return true;
		}
		
		// Normal split condition for everything else thats a full game run and ILs/Segments
		if (current.oolState == 19 && current.levelID > vars.levelSplitID)
    	{
    		vars.levelSplitID += 1;
    		return true;
    	}
	}
}

reset
{
	// Don't reset if we crashed
	if(vars.crashed) return false;

	// Otherwise if we didn't crash during that, reset the timer on game start. Still resets for crash%(since no split happens anyway), might change.
	if(!vars.mainMenuReached && timer.CurrentPhase == TimerPhase.Running && !settings["ilseg"]) return true;

	// If the timer isn't started, then we don't need to check for reset conditions.
	if(timer.CurrentPhase != TimerPhase.Running) return false;

	// If doing menu glitches and we have menus open, dont reset when we go back to the main menu.
	if(timer.Run.CategoryName == "Major Glitches" && current.menusOpen > 1) return false;

	// If we load a save and it's not for the current level we are on, reset.
	// This was mainly for the annoying situations where you were on a level like AUP and accidentally loaded a practice save on inside info and your timer would spam split until inside info.
	// I don't see a logical reason to load a save on a level other than the one your currently on for any reason unless by mistake, so I think this is fine?
	if(current.levelQueued != -1 && current.levelQueued > vars.levelSplitID) return true;

	// Check if attack is used while running NJA.
	if(current.stamina < 10 && current.stamina > 0 && timer.Run.CategoryName == "No Jump-Attacks") return true;

	// Check if long-jump used while running NLJ.
	if(current.longjumpCount > 0 && timer.Run.CategoryName == "No Long-Jumps") return true;

	// IL and segment reset conditions
	if(settings["ilseg"])
	{
		if(current.levelID == vars.levelStartID)
		{
			// Reset condition for dream world.
			if(vars.levelStartID == 0 && current.oolState == 20 && timer.CurrentTime.GameTime.Value.TotalSeconds >= 0.05d) return true;

			// Reset condition for AUP.
			if(vars.levelStartID == 1 && current.oolState == 17) return true;

			// Reset condition for all other level segments.
			if(current.oolState == 12) return true;
		}

		// If for some reason we load a save thats passed the levels or before the start level in the segment or IL, we reset.
		if(current.levelID > vars.levelStartID + timer.Run.Count || current.levelID < vars.levelStartID) return true;
	}

	// Generic reset check; if we get to main menu. Already check for menu glitches.
	if (current.levelID == -1 && current.oolState == 6) return true;
}

isLoading
{
	return current.loadScreen;
}

exit
{
	// All quests AWW crash check.
	if(settings["resets"]) vars.crashed = true;

	// Crash% display time as checkbox since split action doesn't run after the game has crashed. Most likely inaccurate, but better than nothing I guess?
	if(timer.Run.CategoryName.IndexOf("crash", StringComparison.OrdinalIgnoreCase) > -1 && timer.CurrentPhase == TimerPhase.Running) MessageBox.Show(
		"Crash% Time Recorded at " + ((TimeSpan)timer.CurrentTime.GameTime).ToString(@"mm\:ss\.fff") + 
		"\nMay not be accurate due to limitations.", 
		vars.messageBoxTitle, MessageBoxButtons.OK, MessageBoxIcon.Information, MessageBoxDefaultButton.Button1, MessageBoxOptions.DefaultDesktopOnly);
	
	// Reset bools for when we lose process handle.
	vars.noStartLevelMB = false;
	vars.mainMenuReached = false;

	//Remove event handlers. Since we add on init, just remove here to avoid problems.
	timer.OnReset -= vars.resetEventHandler;
	timer.OnStart -= vars.startEventHandler;
}

shutdown
{
	//Remove event handlers to avoid any problems.
	timer.OnReset -= vars.resetEventHandler;
	timer.OnStart -= vars.startEventHandler;
}
	
