//==============================================
// Project: UScript-MultiHack - RVS
// Version: 6.5 PRIVATE
//==============================================

Class MultiHack Extends Engine.Interaction Config (RavenShield);

#exec Texture Import File=Textures\Menubar.bmp Name=Menu
#exec Font Import File=Textures\SmallFont.bmp Name=OrigFont
#exec Texture Import File=Textures\WhiteSquareTexture.pcx Name=WhiteTexture
#exec Texture Import File=Textures\Dot.bmp Name=Dot
#Exec Texture Import File=Textures/Pointer.BMP Name=Mouse

// Structs

struct MenuItem_structure
{
	var string MenuName;
	var bool MenuValue;
	var bool SubMenu;
};

// Variables

var config bool bActive;
var config bool bPower;
var config bool bWallhack;
var config bool bNoRecoil;
var config bool bRetlock;
var config bool bESP;
var config bool bIntelliquipment;
var config bool bMenu;
var config bool bAutoFire;
var config bool bAutoAim;
var config bool bFragGlow;
var config bool bRadar;
var config bool bGodMode;
var config bool bCharge;
var config bool bAutoReload;
var config bool bSafePlay;
var config bool bTKBot;
var config bool bZoombot;
var config bool bNotification;
var config bool bVisuals;
var config bool bSpeedHack;
var config bool bAntiIdle;
var config bool bAntiVoteKick;
var config bool bBypass;
var config bool bDoorBreacher;
var config bool bNoEffects;
var config bool bNoFog;
var config bool bShowCharacterInfo, bShowWaypointInfo, bShowActionIcon;
var config int VStyle, vFire, Zoom, Speed;
var config float RadarX, RadarY, Radius, fPredict;
var bool bBotIsShooting;
var bool bFP1;
var bool bFP2;
var bool bRetWatcher;
var int I;
var int MenuX, MenuY;
var R6Pawn R6Pawn;
var Pawn Me;
var Actor MyActor, Actor;
var Rotator MyRotation;
var PlayerController MyController;
var R6PlayerController R6Controller;
var Canvas MyCanvas;
var R6EngineWeapon R6EngineWeapon;
var R6Weapons R6Weapons;
var R6Terrorist Terrorist;
var PlayerReplicationInfo PRI;
var R6GameOptions R6GameOptions;
var Vector Velocity;
var vector NullVector;
var vector MyLocation;
var vector AimLocation;
var vector BoneLocation;
var vector TargetLocation;
var name BestBone;

// Secondary Menu

var int		MenuSelected[30];
var string	MenuTitle;
var MenuItem_structure MenuItems[30];
var bool	Moving;
var float	MouseStartX;
var float	MouseStartY;
var int		CurrentMenu;
var int		MenuItemsNum;
var bool	LeftMousePressed;
var config bool	bMouse;

// Bot Functions

event Tick(float Delta)
{	
	// Check If Playing
	if (MyController == None || Me == None || MyController.Pawn.PlayerReplicationInfo == None)
	{
		return;
	}
	
	// Aiming Functions (Foreach Target on Map)
	if ( MyController != None && MyController.Pawn.PlayerReplicationInfo != None  && Me !=None)
	{
		Aiming();
	}
}

function PostRender (Canvas Canvas)
{
	local pawn Target;
	local pawn BestTarget;
	local pawn OldTarget;
	local name Bone;
	local string NewName;

	MyCanvas = Canvas;
	Canvas.Font=Font'OrigFont';
	MyController = ViewportOwner.Actor;
	// MyController = Canvas.Viewport.Actor;
	R6Controller = R6PlayerController(MyController);
	MyController.PlayerCalcView(MyActor, MyLocation, MyRotation);
	Me = Pawn(MyActor);
	R6Pawn = R6Pawn(Me);

	// AVK
	NewName = GetRandomTag() $ GetRandomName();

	if ( bPower )
	{
		if ( Me != None)
		{
			MyLocation = Me.GetBoneCoords('R6 Head').Origin;

			if (bMenu)
			{
				if (bMouse)
				{
					DrawMouse(Canvas);
				}
				MyMenuShow(Canvas);
				if (LeftMousePressed) LeftMousePressed = false;
			}
			if (Me.PressingFire())
			{
				MyController.bFire=1;
				MyController.Fire();
				R6Controller.ServerExecFire();
			}
			if (bSafePlay)
			{
				SafePlay(Canvas);
			}
			if ( bIntelliquipment )
			{
				TargetIntelliquipment();
			}
			if ( bVisuals )
			{
				foreach MyController.AllActors(Class'Actor',Actor)
				{
					if ( ValidActor(Actor) )
					{
						if ((Actor.IsA('R6Grenade')) || (Actor.IsA('Pawn')) || (Actor.IsA('R6ioBomb')))
						{
							if ( bRadar )
							{
								Draw2DRadar(Actor);
							}
						}
						if ( bNoEffects )
						{
							if (Actor.IsA('R6SFX'))
							{
								R6SFX(Actor).bHidden = True;
								R6SFX(Actor).Destroy();
							}
						}
						if ( bNoFog )
						{
							if (Actor.IsA('ZoneInfo'))
							{
								ZoneInfo( Actor ).DistanceFogStart = 100000;
								ZoneInfo( Actor ).DistanceFogEnd = 100001;
							}
						}
						if ( Actor.IsA('R6Grenade') )
						{
							if ( bESP )
							{
								DrawWeaponESP(Actor);
								if (bFragGlow)
								{
									FragLite();
								}
							}
						}
						if ( Actor.IsA('Pawn') )
						{
							if ( ValidTarget(Pawn(Actor)) )
							{
								if (bWallhack)
								{
									MyCanvas.DrawActor(Pawn(Actor),False,True );
									Actor.bHidden = False;
								}
								if ( bESP )
								{
									DrawESP(Pawn(Actor));
								}
							}
						}
					}
				}
				if ( bRadar )
				{
					MyCanvas.Style = 3;
					MyCanvas.SetDrawColor(33,33,33,100);
					MyCanvas.SetPos(RadarX - Radius - 1, RadarY - Radius - 1);
					MyCanvas.DrawRect(Texture'WhiteTexture', Radius * 2 + 2, Radius * 2 + 2);
					MyCanvas.Style = 3;
					MyCanvas.SetDrawColor(61,61,61);
					MyCanvas.SetPos(RadarX - Radius, RadarY - Radius);
					MyCanvas.DrawRect(Texture'WhiteTexture', Radius * 2, Radius * 2); 
					MyCanvas.Style = 3;             
					MyCanvas.SetPos(RadarX, RadarY);
					MyCanvas.SetDrawColor(33,33,33);
					MyCanvas.DrawIcon(Texture'Dot',1.30);
				}
			}
			// Fire Rate Modification
			FireRate();

			if ( bAutoReload )
			{
				if (R6Weapons(MyController.Pawn.EngineWeapon).m_InbBulletsInWeapon <= 5)
				{
					StopMyWeapon();
					R6Weapons(MyController.Pawn.EngineWeapon).AddClips(1);
					R6Weapons(MyController.Pawn.EngineWeapon).ChangeClip();
					R6Weapons(MyController.Pawn.EngineWeapon).PlayReloading();
					R6Weapons(MyController.Pawn.EngineWeapon).AddClips(1);
					StopMyWeapon();
				}
			}
			if ( bGodMode )
			{
				R6Pawn(Me).ServerForceStunResult(10000);
				R6Pawn(Me).ServerForceKillResult(10000);
			}
			else if ( !bGodMode )
			{
				R6Pawn(Me).ServerForceStunResult(0);
				R6Pawn(Me).ServerForceKillResult(0);
			}
			if ( bSpeedhack )
			{
				R6Controller.SetCrouchBlend(Speed);
				R6Controller.ServerSetCrouchBlend(Speed);
				R6Pawn(Me).SetCrouchBlend(Speed);
			}
			else if ( !bSpeedHack )
			{
				R6Controller.SetCrouchBlend(0.0);
         			R6Controller.ServerSetCrouchBlend(0.0);
         			R6Pawn(Me).SetCrouchBlend(0.0);
			}
			if ( bNoRecoil )
			{
				R6PlayerController(MyController).m_bShakeactive=false;
			}
			else if ( !bNoRecoil )
			{
				R6PlayerController(MyController).m_bShakeactive=true;
			}
			if ( bRetlock )
			{
				MyController.Pawn.EngineWeapon.PerfectAim();
			}
			if ( bZoombot )
			{
				Zooming();
			}
			if ( bAntiVoteKick )
			{
				MyController.ClientChangeName(NewName);
				MyController.ClientChangeName(NewName);
				MyController.ClientChangeName(NewName);
				bAntiVoteKick = !bAntiVoteKick;
			}
			if ( bAntiIdle )
			{
				if ( Me != None )
				{
					MyRotation.Yaw += Me.Location.X;
                                        Me.ClientSetRotation(MyRotation);
                                        if ( Me.bIsCrouched )
					{
						MyController.ConsoleCommand("RaisePosture");
					}
                                        else
					{
						MyController.ConsoleCommand("LowerPosture");
					}
				}
			}
			// HUD Edits
			if ( bShowCharacterInfo )
			{
				 R6GameOptions.HUDShowCharacterInfo = True;
			}
			else if ( !bShowCharacterInfo )
			{
				R6GameOptions.HUDShowCharacterInfo = False;
			}
			if ( bShowWayPointInfo )
			{
				 R6GameOptions.HUDShowWaypointInfo = True;
			}
			else if ( !bShowCharacterInfo )
			{
				R6GameOptions.HUDShowWaypointInfo = False;
			}
			if ( bShowActionIcon )
			{
				 R6GameOptions.HUDShowActionIcon = True;
			}
			else if ( !bShowActionIcon )
			{
				R6GameOptions.HUDShowActionIcon = False;
			}
		}
	}
}

// Target Intelliquipment

function TargetIntelliquipment ()
{

	MyController.m_bHeatVisionActive = True;
	MyController.ServerToggleHeatVision(True);

	// Weapon Mods
	R6Weapons(MyController.Pawn.EngineWeapon).m_fMaxZoom = 4;
	R6Weapons(MyController.Pawn.EngineWeapon).m_fRateOfFire = 0.1;
	R6Weapons(MyController.Pawn.EngineWeapon).m_fFireAnimRate = 0.1;
	R6Weapons(MyController.Pawn.EngineWeapon).m_bIsSilenced = True;
	R6Weapons(MyController.Pawn.EngineWeapon).m_bUnlimitedClip = True;
	MyController.Pawn.EngineWeapon.m_fMaxZoom = 4.0;
	MyController.Pawn.Level.m_pScopeMaskTexture = None;
	MyController.Pawn.Level.m_pScopeAddTexture = None;
	R6Weapons.m_fRateOfFire = 0.0;
	R6Weapons.m_fFireAnimRate = 0.0;
	R6Weapons.m_pBulletClass.Default.m_fRange = 30000.0;

	Me.EngineWeapon.TurnOffEmitters(True);
	Me.m_bHBJammerOn = True;

	Me.EngineWeapon.m_fTimeDisplayParticule = 0.000000000001;
	Me.EngineWeapon.m_inbParticlesToCreate = 0.000000001;

	MyController.Pawn.EngineWeapon.m_fReloadEmptyTime = 0.0;
	MyController.Pawn.EngineWeapon.m_fReloadTime = 0.0;

	R6Weapons(MyController.Pawn.EngineWeapon).m_fReloadEmptyTime = 0.00000000000000001;
	R6Weapons(MyController.Pawn.EngineWeapon).m_fReloadTime = 0.00000000000000001;

	if ( R6Controller.Pawn != None )
	{
		R6Pawn(Me).m_fDecrementalBlurValue = 0.00;
		R6Pawn(Me).m_bHaveGasMask = true;
		R6Pawn(Me).m_fBlurValue = 0.00;
		R6Pawn(Me).m_fRepDecrementalBlurValue = 0.00;
		R6Pawn(Me).m_bFlashBangVisualEffectRequested = false;
		R6Pawn(Me).m_fFlashBangVisualEffectTime = 0.0;
	}
}

// Fire Rates

function FireRate ()
{
	if ( vFire == 0 )
	{
		me.EngineWeapon.StopFire(True);
		me.EngineWeapon.ClientStopFire(True);
		me.EngineWeapon.LocalStopFire(True);
		me.EngineWeapon.ServerStopFire(True);
	}
	if ( vFire == 1 )
	{
		me.EngineWeapon.StopFire(False);
		me.EngineWeapon.ClientStopFire(True);
		me.EngineWeapon.LocalStopFire(True);
		me.EngineWeapon.ServerStopFire(True);
	}
	if ( vFire == 2 )
	{
		me.EngineWeapon.StopFire(False);
		me.EngineWeapon.ClientStopFire(False);
		me.EngineWeapon.LocalStopFire(True);
		me.EngineWeapon.ServerStopFire(True);
	}
	if ( vFire == 3 )
	{
		me.EngineWeapon.StopFire(False);
		me.EngineWeapon.ClientStopFire(False);
		me.EngineWeapon.LocalStopFire(False);
		me.EngineWeapon.ServerStopFire(True);
	}
	if ( vFire == 4 )
	{
		me.EngineWeapon.StopFire(False);
		me.EngineWeapon.ClientStopFire(False);
		me.EngineWeapon.LocalStopFire(False);
		me.EngineWeapon.ServerStopFire(False);
	}
}

// Zoombot

function Zooming ()
{
	if ( Me.PressingFire() )
	{
		MyController.SetFOV(Zoom);
	}
	else if ( !Me.PressingFire() )
	{
		MyController.SetFOV(MyController.DefaultFOV);
	}
}

// Safe Play
function SafePlay(Canvas Canvas)
{
	Local Actor SP;
	local int NotifY;

	NotifY = 50;

	ForEach MyController.AllActors(Class 'Actor',SP)
	{
		// Operation Feed The Piranhas Mod 1
		If( SP.IsA('FPLauncher') || SP.IsA('FPExaminer') )
		{
			// MyController.ClientMessage("Safe Play Notice: ");
			// MyController.ClientMessage("FeedPiranhas Mod 1 Detected");
			// MyController.ConsoleCommand("Disconnect");
			bFP1 = True;
			if ( bBypass )
			{
				SP.Destroy();
			}
		}
		// Operation Feed The Piranhas Mod 2
		If( SP.IsA('FPChecker') || SP.IsA('FPPBInterface') || SP.IsA('FPDecider') || SP.IsA('FPReporter') || SP.IsA('FPStarter') )
		{
			// MyController.ClientMessage("Safe Play Notice: ");
			// MyController.ClientMessage("FeedPiranhas Mod 2 Detected");
			// MyController.ConsoleCommand("Disconnect");
			bFP2 = True;
			if ( bBypass )
			{
				SP.Destroy();
			}
		}
		// RetWatcher Beta 1.10
		If ( SP.IsA('RetWatcher') || SP.IsA('RWScanner') || SP.IsA('RWLauncher') || SP.IsA('RWRecovery') )
		{
			// MyController.ClientMessage("SafePlay Notice: ");
			// MyController.ClientMessage("RetWatcher Detected");
			// MyController.ConsoleCommand("Disconnect");
			bRetWatcher = True;
			if ( bBypass )
			{
				SP.Destroy();
			}
		}
        }
	if ( bNotification )
	{
		if ( bFP1 )
		{
			MyCanvas.bCenter = True;
			MyCanvas.SetDrawColor(255,0,0);
			MyDrawText(MyCanvas.HalfClipX, NotifY, "Safe Play Notice: Feed Piranhas Mod 1 Detected", Canvas.DrawColor);
			MyCanvas.bCenter = False;
			NotifY += 10;
		}
		if ( bFP2 )
		{
			MyCanvas.bCenter = True;
			MyCanvas.SetDrawColor(255,0,0);
			MyDrawText(MyCanvas.HalfClipX, NotifY, "Safe Play Notice: Feed Piranhas Mod 2 Detected", Canvas.DrawColor);
			MyCanvas.bCenter = False;
			NotifY += 10;
		}
		if ( bRetWatcher )
		{
			MyCanvas.bCenter = True;
			MyCanvas.SetDrawColor(255,0,0);
			MyDrawText(MyCanvas.HalfClipX, NotifY, "Safe Play Notice: RetWatcher Detected", Canvas.DrawColor);
			MyCanvas.bCenter = False;
			NotifY += 10;
		}
	}
}

// Charge Hack (C4)

function Charge (Pawn Target)
{
	R6Pawn(MyController.Pawn).EngineWeapon.ServerPlaceCharge(Target.Location);
        R6Pawn(MyController.Pawn).EngineWeapon.ServerDetonate();
	StopMyWeapon();
	bCharge = !bCharge;
}

// Black Bordered Text

function MyDrawText (float XPos, float YPos, coerce String Text, Color TColor)
{
	local float PosX, PosY, X, Y;
        MyCanvas.TextSize(Text, X, Y);
	PosX = XPos;
        PosY = YPos;
	MyCanvas.SetDrawColor(0,0,0);
	MyCanvas.SetPos(PosX, PosY -1);
	MyCanvas.DrawTextClipped(Text);
	MyCanvas.SetPos(PosX, PosY +1);
	MyCanvas.DrawTextClipped(Text);
	MyCanvas.SetPos(PosX -1, PosY);
	MyCanvas.DrawTextClipped(Text);
	MyCanvas.SetPos(PosX +1, PosY);
	MyCanvas.DrawTextClipped(Text);
	MyCanvas.SetDrawColor(TColor.R, TColor.G, TColor.B, TColor.A);
	MyCanvas.SetPos(PosX, PosY);
	MyCanvas.DrawTextClipped(Text);
}

// Menu

function DrawMouse (Canvas Canvas)
{
	Canvas.SetPos(MyController.Player.WindowsMouseX,MyController.Player.WindowsMouseY);
	Canvas.SetDrawColor(58-30,95-30,205-30);
	Canvas.Style=3;
	// Canvas.DrawRect(Texture'WhiteTexture', 3, 3);
	Canvas.DrawIcon(Texture'Mouse' ,1.0);
	Canvas.Style=1;
}

function UpdateMenuItem(string MyMenuName, bool MyMenuValue, bool MySubMenu, int MyID)
{
	MenuItems[MyID].MenuName = MyMenuName;
	MenuItems[MyID].MenuValue = MyMenuValue;
	MenuItems[MyID].SubMenu = MySubMenu;
} 

function DeleteAllItems()
{
	local int DeleteAllItemsTempInt;
	for(DeleteAllItemsTempInt=0; DeleteAllItemsTempInt<ArrayCount(MenuItems); DeleteAllItemsTempInt++ )
	{
		MenuItems[DeleteAllItemsTempInt].MenuName = "";
		MenuItems[DeleteAllItemsTempInt].MenuValue = false;
		MenuItems[DeleteAllItemsTempInt].SubMenu = false;
	}
	MenuItemsNum = 0;
}

function DrawMenu (Canvas Canvas)
{
	local int DrawMenuTempInt;
	local int MouseX;
	local int MouseY;
	local int TempDrawLoop;

	for(DrawMenuTempInt=0; DrawMenuTempInt<MenuItemsNum; DrawMenuTempInt++ )
	{
		DrawMenuItem(Canvas, DrawMenuTempInt);
	}

	if (bMouse)
	{
		MouseX = MyController.Player.WindowsMouseX;
		MouseY = MyController.Player.WindowsMouseY;
		
		if (LeftMousePressed)
		{	
			if (!Moving)
			{

				if (MouseX > MenuX && MouseX < MenuX + 180 && MouseY > MenuY && MouseY < MenuY + 21)
				{
						if (MouseX > MenuX+180-19 && MouseX < MenuX+180-19+15)
						{
							CurrentMenu = -1;
						}
						else if (MouseX > MenuX+180-35 && MouseX < MenuX+180-35+11)
						{
							MenuUp();
						}
						else
						{
							Moving = true;
							MouseStartX = MouseX - MenuX;
							MouseStartY = MouseY - MenuY;
						}
				}
				else 
				{
					if (MenuItemsNum > 0)
					{
						for(TempDrawLoop=0; TempDrawLoop<MenuItemsNum; TempDrawLoop++ )
						{
							if (MouseX > MenuX+5 && MouseX < MenuX+5+169 && MouseY >= MenuY+21+(16 * TempDrawLoop) && MouseY <= MenuY+21+(16 * TempDrawLoop)+16)
								ToggleMenuItem(CurrentMenu, MenuSelected[CurrentMenu]);
						}
					} 
				}
			}
			else
			{
				Moving = false;
			}
		}
		
		if (Moving) 
		{
			MenuX = MouseX - MouseStartX;
			MenuY = MouseY - MouseStartY;
		}
		else
		{
			for(TempDrawLoop=0; TempDrawLoop<MenuItemsNum; TempDrawLoop++ )
			{
				if (MouseX > MenuX+5 && MouseX < MenuX+5+169 && MouseY >= MenuY+21+(16 * TempDrawLoop) && MouseY <= MenuY+21+(16 * TempDrawLoop)+16)
					MenuSelected[CurrentMenu] = TempDrawLoop;
			}
		}
	}
	

	Canvas.SetPos(MenuX,MenuY);
	MyCanvas.SetDrawColor(61,61,61);
	//Canvas.DrawTile (Texture'WhiteTexture', 172, 17, 0.0, 0.0, 172, 17);
	Canvas.DrawRect(Texture'Menu', 180, 20);
	Canvas.Style = 1;
	
	// Canvas.SetPos(MenuX+29, MenuY+7 );
	// GetThemeColor(Canvas, 230);
	MyCanvas.SetDrawColor(255,255,255);
	// Canvas.DrawText(MenuTitle);
	MyDrawText( MenuX+29, MenuY+7, MenuTitle, MyCanvas.DrawColor);

	Canvas.SetPos(MenuX+11, MenuY+9);
	//GetThemeColor(Canvas, 230);
	MyCanvas.SetDrawColor(61,61,61);
	Canvas.DrawText(string(CurrentMenu));
	

	//Left Border
	Canvas.SetPos(MenuX,MenuY);
	Canvas.DrawVertical(MenuX,21+(16 * MenuItemsNum));
	
	
	//Right Border
	Canvas.SetPos(MenuX+180,MenuY);
	Canvas.DrawVertical(MenuX+180,21+(16 * MenuItemsNum));

	//Top Border
	Canvas.SetPos(MenuX,MenuY);
	Canvas.DrawHorizontal(MenuY,180);
	
	//Bottom Border

	Canvas.SetPos(MenuX,MenuY+19+(16 * MenuItemsNum));
	Canvas.DrawHorizontal(MenuY+19+(16 * MenuItemsNum),180);
}

function GetMenuItemColor(Canvas Canvas, int ItemNum, bool bText)
{
	if (bText)
	{
		if (MenuSelected[CurrentMenu] == ItemNum)
		{
			Canvas.SetDrawColor(255,255,255);
			return;
		}
		else
		{
			MyCanvas.SetDrawColor(33,33,33);
			return;
		}
	}
	if (MenuItems[ItemNum].SubMenu == true)
	{
		if (MenuSelected[CurrentMenu] == ItemNum)
		{
			Canvas.SetDrawColor(0,0,255);
			return;
		}
		else
		{
			Canvas.SetDrawColor(0,0,120);
			return;
		}
	}
	if (MenuItems[ItemNum].MenuValue == true)
	{
		if (MenuSelected[CurrentMenu] == ItemNum)
		{
			Canvas.SetDrawColor(0,255,0);
			return;
		}
		else
		{
			Canvas.SetDrawColor(0,120,0);
			return;
		}
	}
	else
	{
		if (MenuSelected[CurrentMenu] == ItemNum)
		{
			Canvas.SetDrawColor(255,0,0);
			return;
		}
		else
		{
			Canvas.SetDrawColor(120,0,0);
			return;
		}
	}
}

function DrawMenuItem(Canvas Canvas, int ItemNum)
{
	Canvas.SetPos(MenuX,MenuY+19+(16 * ItemNum));
	MyCanvas.SetDrawColor(61,61,61);
	Canvas.Style=3;
	Canvas.DrawRect (Texture'WhiteTexture', 180, 16);

	Canvas.Style=1;

	//MyCanvas.SetDrawColor(44,44,44);
	GetMenuItemColor(Canvas, ItemNum, false);
	
	Canvas.SetPos(MenuX+4+Canvas.SizeX-Canvas.SizeX,MenuY+21+(16 * ItemNum));
	Canvas.DrawHorizontal(MenuY+21+(16 * ItemNum),180-4-4);


	/*	
	Canvas.SetPos(MenuX+4, MenuY+22+(16 * ItemNum));
	Canvas.Style = 3;
	GetMenuItemColor(Canvas, ItemNum, false);
	Canvas.DrawIcon(Texture'Selection',1.0);
	Canvas.Style = 1;
	*/

	Canvas.SetPos(MenuX+4+25, MenuY+22+3+(16 * ItemNum));
	GetMenuItemColor(Canvas, ItemNum, true);
	Canvas.DrawText(MenuItems[ItemNum].MenuName);

	Canvas.SetPos(MenuX+5+169-16, MenuY+22+3+(16 * ItemNum));
	GetMenuItemColor(Canvas, ItemNum, true);
	Canvas.DrawText(ItemNum);
}

function MenuUp ()
{
	switch (CurrentMenu)
	{
		case 0:
			DeleteAllItems();
			CurrentMenu = -1;
			bMenu = false;
		break;
		default:
			DeleteAllItems();
			CurrentMenu = 0;
		break;
	}
}

function ToggleMenuItem (int myCurrentMenu, int myMenuSelected)
{
	switch (myCurrentMenu)
	{
		case -1:
			CurrentMenu = 0;
			bMenu = true;
			DeleteAllItems();
		break;
		case 0:
			switch (myMenuSelected)
			{
				case 0:
					bPower = !bPower;
				break;
				case 1:
					bMenu = !bMenu;
				break;
				case 2:
					bMouse = !bMouse;
				break;
				case 3: // Aiming
					DeleteAllItems();
					CurrentMenu = 1;
				break;
				case 4: // Visuals
					DeleteAllItems();
					CurrentMenu = 2;
				break;
				case 5: // Player
					DeleteAllItems();
					CurrentMenu = 3;
				break;
				case 6: // Weapon
					DeleteAllItems();
					CurrentMenu = 4;
				break;
				case 7: // Safe Play
					DeleteAllItems();
					CurrentMenu = 5;
				break;
				/* case 8: // HUD Options
					DeleteAllItems();
					CurrentMenu = 11;
				break; */
			}
		break;
		case 1:
			switch (myMenuSelected)
			{
				case 0:
					bAutoAim = !bAutoAim;
				break;
				case 1:
					bAutoFire = !bAutoFire;
				break;
				case 2:
					bDoorBreacher = !bDoorBreacher;
				break;
				case 3:
					bCharge = !bCharge;
				break;
				case 4:
					bTKBot = !bTKBot;
				break;
				case 5: // Fire Rate
					DeleteAllItems();
					CurrentMenu = 6;
				break;
				case 6: // Prediction Settings
					DeleteAllItems();
					CurrentMenu = 7;
				break;
				case 7:
					DeleteAllItems();
					CurrentMenu = 0;
				break;
			}
		break;
		case 2:
			switch (myMenuSelected)
			{
				case 0:
					bVisuals = !bVisuals;
				break;
				case 1:
					bESP = !bESP;
				break;
				case 2:
					DeleteAllItems();
					CurrentMenu = 10;
				break;
				case 3:
					bWallhack = !bWallhack;
				break;
				case 4:
					bRadar = !bRadar;
				break;
				case 5:
					bFragGlow = !bFragGlow;
				break;
				case 6:
					bNoEffects = !bNoEffects;
				break;
				case 7:
					bNoFog = !bNoFog;
				break;
				case 8:
					DeleteAllItems();
					CurrentMenu = 0;
				break;
			}
		break;
		case 3:
			switch (myMenuSelected)
			{
				/* case 0:
					R6GameOptions.AlwaysRun = !R6GameOptions.AlwaysRun;
				break; */
				case 0:
					bGodMode = !bGodMode;
				break;
				case 1:
					bSpeedHack = !bSpeedHack;
				break;
				case 2: // SpeedHack Settings
					DeleteAllItems();
					CurrentMenu = 8;
				break;
				case 3:
					bAntiVoteKick = !bAntiVoteKick;
				break;
				case 4:
					bAntiIdle = !bAntiIdle;
				break;
				case 5:
					DeleteAllItems();
					CurrentMenu = 0;
				break;
			}
		break;
		case 4:
			switch (myMenuSelected)
			{
				case 0:
					bIntelliquipment = !bIntelliquipment;
				break;
				case 1:
					bAutoReload = !bAutoReload;
				break;
				case 2:
					bRetlock = !bRetlock;
				break;
				case 3:
					bZoombot = !bZoombot;
				break;
				case 4: // Zoom Seltings
					DeleteAllItems();
					CurrentMenu = 9;
				break;
				case 5:
					DeleteAllItems();
					CurrentMenu = 0;
				break;
			}
		break;
		case 5:
			switch (myMenuSelected)
			{
				case 0:
					bSafePlay = !bSafePlay;
				break;
				/* case 1:
					R6GameOptions.ActivePunkBuster = !R6GameOptions.ActivePunkBuster;
				break; */
				case 1:
					bBypass = !bBypass;
				break;
				case 2:
					bNotification = !bNotification;
				break;
				case 3:
					DeleteAllItems();
					CurrentMenu = 0;
				break;
			}
		break;
		case 6:
			switch (myMenuSelected)
			{
				case 0:
					if ( vFire < 4 )
					{
						vFire++;
					}
				break;
				case 1:
					if ( vFire > 0 )
					{
						vFire--;
					}
				break;
				case 3:
					DeleteAllItems();
					CurrentMenu = 1;
				break;
			}
		break;
		case 7:
			switch (myMenuSelected)
			{
				case 0:
					if ( fPredict < 1 )
					{
						fPredict = fPredict + 0.01;
					}
				break;
				case 1:
					if ( fPredict > 0 )
					{
						fPredict = fPredict - 0.01;
					}
				break;
				case 3:
					DeleteAllItems();
					CurrentMenu = 1;
				break;
			}
		break;
		case 8:
			switch (myMenuSelected)
			{
				case 0:
					if ( Speed < 100 )
					{
						Speed++;
					}
				break;
				case 1:
					if ( Speed > 0 )
					{
						Speed--;
					}
				break;
				case 3:
					DeleteAllItems();
					CurrentMenu = 3;
				break;
			}
		break;
		case 9:
			switch (myMenuSelected)
			{
				case 0:
					if ( Zoom < 180 )
					{
						Zoom++;
					}
				break;
				case 1:
					if ( Zoom > 0 )
					{
						Zoom--;
					}
				break;
				case 3:
					DeleteAllItems();
					CurrentMenu = 4;
				break;
			}
		break;
		case 10:
			switch (myMenuSelected)
			{
				case 0:
					if ( vStyle < 4 )
					{
						vStyle++;
					}
				break;
				case 1:
					if ( vStyle > 0 )
					{
						vStyle--;
					}
				break;
				case 3:
					DeleteAllItems();
					CurrentMenu = 2;
				break;
			}
		break;
		/* case 11:
			switch (myMenuSelected)
			{
				case 0: // PLAYER
					DeleteAllItems();
					CurrentMenu = 12;
				break;				
				case 1: // TEAM
					DeleteAllItems();
					CurrentMenu = 13;
				break;
				case 2: // WEAPON
					DeleteAllItems();
					CurrentMenu = 14;
				break;
				case 3: // MISC
					DeleteAllItems();
					CurrentMenu = 15;
				break;
				case 4:
					DeleteAllItems();
					CurrentMenu = 0;
				break;
			}
		break;
		case 12:
			switch (myMenuSelected)
			{
				case 0:
					bShowCharacterInfo = !bShowCharacterInfo;
				break;
				case 1:
					bShowWaypointInfo = !bShowWaypointInfo;
				break;
				case 2:
					bShowActionIcon = !bShowActionIcon;
				break;				
				case 3:
					R6GameOptions.HUDShowPlayersName = !R6GameOptions.HUDShowPlayersName;
				break;
				case 4:
					R6GameOptions.ShowRadar = !R6GameOptions.ShowRadar;
				break;
				case 5:
					DeleteAllItems();
					CurrentMenu = 11;
				break;
			}
		break;
		case 13:
			switch (myMenuSelected)
			{
				case 1:
					R6GameOptions.HUDShowCurrentTeamInfo = !R6GameOptions.HUDShowCurrentTeamInfo;
				break;
				case 2:
					R6GameOptions.HUDShowOtherTeamInfo = !R6GameOptions.HUDShowOtherTeamInfo;
				break;
				case 3:
					DeleteAllItems();
					CurrentMenu = 11;
				break;
			}
		break;
		case 14:
			switch (myMenuSelected)
			{
				case 0:
					R6GameOptions.HUDShowWeaponInfo = !R6GameOptions.HUDShowWeaponInfo;
				break;
				case 1:
					R6GameOptions.HUDShowFPWeapon = !R6GameOptions.HUDShowFPWeapon;
				break;
				case 2:
					R6GameOptions.HUDShowReticule = !R6GameOptions.HUDShowReticule;
				break;
				case 3:
					DeleteAllItems();
					CurrentMenu = 11;
				break;
			}
		break;
		case 15:
			switch (myMenuSelected)
			{
				case 0:
					R6GameOptions.AnimatedGeometry = !R6GameOptions.AnimatedGeometry;
				break;
				case 1:
					R6GameOptions.HideDeadBodies = !R6GameOptions.HideDeadBodies;
				break;
				case 2:
					R6GameOptions.ShowRefreshRates = !R6GameOptions.ShowRefreshRates;
				break;
				case 3:
					R6GameOptions.LowDetailSmoke = !R6GameOptions.LowDetailSmoke;
				break;
				case 4:
					DeleteAllItems();
					CurrentMenu = 11;
				break;
			}
		break; */
	}
}

function MyMenuShow (Canvas Canvas)
{
	MenuItemsNum=0;

	switch (CurrentMenu)
	{
		case 0:
			MenuTitle = "MultiHack v6.5 Menu";

			UpdateMenuItem("Power", bPower,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Menu", bMenu,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Mouse", bMouse,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Aiming >", false,true,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Visuals >", false,true,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Player >", false,true,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Weapon >", false,true,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Safe Play >", false,true,MenuItemsNum);
			MenuItemsNum++;

			/* UpdateMenuItem("HUD Options >", false,true,MenuItemsNum);
			MenuItemsNum++; */
		break;
		case 1:
			MenuTitle = "Aiming";

			UpdateMenuItem("AutoAim", bAutoAim,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("AutoFire", bAutoFire,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Door Breacher", bDoorBreacher,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Charge Hack", bCharge,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("TK Bot", bTKBot,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Fire Rate: "$ string(vFire),false,true,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Prediction: "$ string(fPredict * 10),false,true,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("< Back", false,true,MenuItemsNum);
			MenuItemsNum++;
		break;
		case 2:
			MenuTitle = "Visuals";
	
			UpdateMenuItem("Visuals", bVisuals,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("ESP", bESP,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("ESP Style: "$ string(vStyle),false,true,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Wallhack", bWallhack,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Radar", bRadar,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Frag Glow", bFragGlow,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("No Effects", bNoEffects,false,MenuItemsNum);
			MenuItemsNum++;			
			
			UpdateMenuItem("No Fog", bNoFog,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("< Back", false,true,MenuItemsNum);
			MenuItemsNum++;
		break;
		case 3:
			MenuTitle = "Player";
	
			/* UpdateMenuItem("Always Run", R6GameOptions.AlwaysRun,false,MenuItemsNum);
			MenuItemsNum++; */

			UpdateMenuItem("God Mode", bGodMode,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Speed Hack", bSpeedHack,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Speed Amount: "$ string(Speed),false,true,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Anti Votekick", bAntiVoteKick,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Anti Idle", bAntiIdle,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("< Back", false,true,MenuItemsNum);
			MenuItemsNum++;
		break;
		case 4:
			MenuTitle = "Weapon";

			UpdateMenuItem("Intelliquipment", bIntelliquipment,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Auto Reload", bAutoReload,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Retlock", bRetlock,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Zoombot", bZoombot,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("FOV Angle: "$ string(Zoom),false,true,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("< Back", false,true,MenuItemsNum);
			MenuItemsNum++;
		break;
		case 5:
			MenuTitle = "Safe Play";

			UpdateMenuItem("Safe Play", bSafePlay,false,MenuItemsNum);
			MenuItemsNum++;

			/* UpdateMenuItem("Active PB", R6GameOptions.ActivePunkBuster,false,MenuItemsNum);
			MenuItemsNum++; */

			UpdateMenuItem("Bypass", bBypass,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Notification", bNotification,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("< Back", false,true,MenuItemsNum);
			MenuItemsNum++;
		break;
		case 6:
			MenuTitle = "Fire Rate";
		
			UpdateMenuItem("FireRate +",vFire < 4,False,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("FireRate -",vFire > 0,False,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("FireRate: " $ string(vFire),False,True,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("< Back", false,true,MenuItemsNum);
			MenuItemsNum++;
		break;
		case 7:
			MenuTitle = "Prediction Settings";

			UpdateMenuItem("Predict +",fPredict < 1,False,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Predict -",fPredict > 0,False,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Predict Amount: " $ string(fPredict * 10),False,True,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("< Back", false,true,MenuItemsNum);
			MenuItemsNum++;
		break;
		case 8:
			MenuTitle = "Speed Hack Settings";

			UpdateMenuItem("Speed +",Speed < 100,False,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Speed -",Speed > 0,False,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Speed Amount: " $ string(Speed),False,True,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("< Back", false,true,MenuItemsNum);
			MenuItemsNum++;
		break;
		case 9:
			MenuTitle = "Auto Zoom Settings";

			UpdateMenuItem("FOV +",Zoom < 180,False,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("FOV -",Zoom > 0,False,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("FOV Angle: " $ string(Zoom),False,True,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("< Back", false,true,MenuItemsNum);
			MenuItemsNum++;
		break;
		case 10:
			MenuTitle = "ESP Style";

			UpdateMenuItem("Style +",vStyle < 4,False,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Style -",vStyle > 0,False,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Style: " $ string(vStyle),False,True,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("< Back", false,true,MenuItemsNum);
			MenuItemsNum++;
		break;
		/* case 11:
			MenuTitle = "HUD Options";

			UpdateMenuItem("Player >", false,true,MenuItemsNum);
			MenuItemsNum++;
			
			UpdateMenuItem("Team >", false,true,MenuItemsNum);
			MenuItemsNum++;
			
			UpdateMenuItem("Weapon >", false,true,MenuItemsNum);
			MenuItemsNum++;
			
			UpdateMenuItem("Misc >", false,true,MenuItemsNum);
			MenuItemsNum++;
			
			UpdateMenuItem("< Back", false,true,MenuItemsNum);
			MenuItemsNum++;
		break;
		case 12:
			MenuTitle = "Player";
			
			UpdateMenuItem("Character Info", bShowCharacterInfo,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Waypoint Info", bShowWaypointInfo,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Action Icons", bShowActionIcon,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Player Name", R6GameOptions.HUDShowPlayersName,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Player Radar", R6GameOptions.ShowRadar,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("< Back", false,true,MenuItemsNum);
			MenuItemsNum++;
		break;
		case 13:
			MenuTitle = "Team";

			UpdateMenuItem("Current Team Info", R6GameOptions.HUDShowCurrentTeamInfo,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Other Team Info", R6GameOptions.HUDShowOtherTeamInfo,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("< Back", false,true,MenuItemsNum);
			MenuItemsNum++;
		break;
		case 14:
			MenuTitle = "Weapon";
			
			UpdateMenuItem("Weapon Info", R6GameOptions.HUDShowWeaponInfo,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("FP Weapon", R6GameOptions.HUDShowFPWeapon,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Crosshair", R6GameOptions.HUDShowReticule,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("< Back", false,true,MenuItemsNum);
			MenuItemsNum++;
		break;
		case 15:
			MenuTitle = "Misc";
			
			UpdateMenuItem("Animated Geometry", R6GameOptions.AnimatedGeometry,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Hide Dead Bodies", R6GameOptions.HideDeadBodies,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Show Refresh Rates", R6GameOptions.ShowRefreshRates,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("Low Detail Smoke", R6GameOptions.LowDetailSmoke,false,MenuItemsNum);
			MenuItemsNum++;

			UpdateMenuItem("< Back", false,true,MenuItemsNum);
			MenuItemsNum++;
		break; */
	}
	DrawMenu(Canvas);
}

// Valid Weapon

function bool ValidWeapon()
{
	if( (Me != None) && (Me.EngineWeapon != None) && (!Me.EngineWeapon.IsA('R6Grenade')) && (Me.EngineWeapon.m_InbBulletsInWeapon > 0) && ((Me.EngineWeapon.m_eWeaponType != 7) || (Me.EngineWeapon.m_eWeaponType != 6)) )
	{
		return True;
	}
	else
	{
		return False;
	}
}

// Is Enemy

function bool IsEnemy (Pawn Target)
{
	if ( bTKBot )
	{
		return True;
	}
	else
	{
		if ( Target.m_iTeam != MyController.Pawn.m_iTeam && (Target.m_iTeam != 0))
		{
			return True;
		}
		else
		{
			return False;
		}
	}
}

function bool IsPRIEnemy (PlayerReplicationInfo Target)
{
	if ((Target.Team != None) && (Target.Team.TeamIndex != Me.PlayerReplicationInfo.Team.TeamIndex))
	{
		return True;
	}
	else
	{
		return False;
	}
}

// Valid Targets

function bool ValidTarget (Pawn Target)
{
	if (( Target != None ) && ( Target != MyController.Pawn ) && Target.IsAlive())
	{
		return True;
	}
	else
	{
		return False;
	}
}

function bool ValidActor (Actor Target)
{
	if (( Target != None ) && !Target.bHidden)
	{
		return True;
	}
	else
	{
		return False;
	}
}

// Get Team Color

function GetTeamColor (Pawn Target)
{
	if ( !IsEnemy(Target) )
	{
		MyCanvas.SetDrawColor(255,0,0);
	}
	else
	{
		MyCanvas.SetDrawColor(0,0,255);
	}
}

// Is Using God Mode

function bool IsUsingGod( Pawn Target )
{
    return( R6Pawn(Target).m_iForceKill != 0 || R6Pawn(Target).m_iForceStun != 0 );
}

// Is Using Speed Hack

function bool IsUsingSpeed( Pawn Target )
{
    return( R6Pawn(Target).m_fCrouchBlendRate != 0 );
}

// Aiming Function

function Aiming()
{	
	local Actor Actor;
	local name Bone;
	local name BestBone;
	local Pawn Target;
	local Pawn BestTarget;
	local Pawn OldTarget;

	foreach MyController.AllActors(Class'Pawn',Target)
	{
		if ( bPower )
		{
			if (ValidTarget(Target))
			{
				if ( bCharge )
				{
					if( IsEnemy(Target) )
					{
						if( VSize(Target.Location - MyController.Pawn.Location) / 48 >= 15 )
						{
							Charge(Target);
						}
					}
				}
				if (bAutoAim)
				{
					if (IsEnemy(Target) &&  IsVisible(Target)) // MyController.CanSee(Target)
					{
						BestTarget = GetBestTarget(BestTarget, Target);
					}
					if (BestTarget != None)
					{
						Bone = CheckVisibility(Target);
						if(Bone != 'NotVisible')
						{
							BestBone = Bone;
						}
						BoneAim(BestTarget, BestBone);
						if (bAutoFire && ValidWeapon())
						{
							FireMyWeapon();
							StopMyWeapon();
						}
					}
					else
					{
						StopMyWeapon();
					}
				}
			}
		}	
	}
}

// Check Visibility

function name CheckVisibility(Pawn Target)
{
	local vector MyLocation;
	local vector Bone1, Bone2, Bone3, Bone4, Bone5, Bone6, Bone7, Bone8, Bone9, Bone10, Bone11;

	// Velocity = Target.Velocity * FClamp(Me.PlayerReplicationInfo.Ping * 1000,20.0,250.0) / 740;
	MyLocation = Me.GetBoneCoords('R6 Head').Origin;

	Bone1 = Target.GetBoneCoords('R6 Head').Origin;
	Bone2 = Target.GetBoneCoords('R6 L UpperArm').Origin;
	Bone3 = Target.GetBoneCoords('R6 L ForeArm').Origin;
	Bone4 = Target.GetBoneCoords('R6 L Hand').Origin;
	Bone5 = Target.GetBoneCoords('R6 R UpperArm').Origin;
	Bone6 = Target.GetBoneCoords('R6 R ForeArm').Origin;
	Bone7 = Target.GetBoneCoords('R6 R Hand').Origin;
	Bone8 = Target.GetBoneCoords('R6 L Calf').Origin;
	Bone9 = Target.GetBoneCoords('R6 R Calf').Origin;
	Bone10 = Target.GetBoneCoords('R6 L Foot').Origin;
	Bone11 = Target.GetBoneCoords('R6 R Foot').Origin;

	if (IsTraceable(Bone1, MyLocation))
	{
		return 'R6 Head';
	}
	else if (IsTraceable(Bone2, MyLocation))
	{
		return 'R6 L UpperArm';
	}
	else if (IsTraceable(Bone3, MyLocation))
	{
		return 'R6 L ForeArm';
	}
	else if (IsTraceable(Bone4, MyLocation))
	{
		return 'R6 L Hand';
	}
	else if (IsTraceable(Bone5, MyLocation))
	{
		return 'R6 R UpperArm';
	}
	else if (IsTraceable(Bone6, MyLocation))
	{
		return 'R6 R ForeArm';
	}
	else if (IsTraceable(Bone7, MyLocation))
	{
		return 'R6 R Hand';
	}
	else if (IsTraceable(Bone8, MyLocation))
	{
		return 'R6 L Calf';
	}
	else if (IsTraceable(Bone9, MyLocation))
	{
		return 'R6 R Calf';
	}
	else if (IsTraceable(Bone10, MyLocation))
	{
		return 'R6 L Foot';
	}
	else if (IsTraceable(Bone11, MyLocation))
	{
		return 'R6 R Foot';
	}
	else
	{
		return 'NotVisible';
	}
}

// IsTraceable (Aiming)

function bool IsTraceable (vector vEnd, vector vStart)
{
	if (bDoorBreacher)
	{
		if (BulletTrace(vEnd, vStart))
		{
			return true;
		}
		else if (Me.FastTrace(vEnd, vStart))
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	else if (!bDoorBreacher)
	{
		if (Me.FastTrace(vEnd, vStart))
		{
			return True;
		}
		else
		{
			return False;
		}
	}
}

// Bullet Trace

function bool BulletTrace (Vector vEnd, Vector vStart)
{
	local Vector HitLocation;
	local Vector HitNormal;
	local Actor A;

	foreach Me.Level.TraceActors(Class'Actor', A, HitLocation, HitNormal, vEnd, vStart)
	{
		if (!A.IsA('R6ioRotatingDoor') || !A.IsA('Pawn') &&  !IsPRIEnemy(Pawn(A).PlayerReplicationInfo) && A.IsInState('Dying'))
		{
			return False;
		}
	}
	return True;
}

// Is Visible

function bool IsVisible (Pawn Target)
{
	local name Bone;
	local vector MyLocation;

	MyLocation = Me.GetBoneCoords('R6 Head').Origin;
	Bone = CheckVisibility(Target);

	if ( MyController.CanSee(Target) )
	{
		return true;
	}
	if ( MyController.FastTrace( Target.GetBoneCoords('Bone').Origin, MyLocation ) )
	{
		return true;
	}
	else
	{
		return false;
	}
}

// Fire Weapon

function FireMyWeapon ()
{
	bBotIsShooting = True;

	MyController.bFire=1;
	MyController.bAltFire=0;
	MyController.Fire();
}

// Stop Weapon

function StopMyWeapon ()
{
	if (bBotIsShooting)
	{
		bBotIsShooting = False;
		MyController.bFire=0;
		MyController.bAltFire=0;
	}
}

// Closest Target

function Pawn GetBestTarget (Pawn BestTarget, Pawn Target)
{
	local float BestDistance;
	local float CurrentDistance;

	BestDistance = VSize(BestTarget.Location - Me.Location);
	CurrentDistance = VSize(Target.Location - Me.Location);

	if (BestTarget == None)
	{
		Return Target;
	}
	else
	{
		if (CurrentDistance < BestDistance)
		{
			Return Target;
		}
		else
		{
			Return BestTarget;
		}
	}
}

// Ping Correction

function Vector PingCorrection (Pawn BestTarget)
{
          local Vector vPing;
          local float ExactPing;

          vPing = BestTarget.Velocity;
          ExactPing = MyController.PlayerReplicationInfo.Ping / 1000;
          ExactPing *= rand(5) * 0.1;
          vPing *= ExactPing;
          vPing += BestTarget.Velocity * 0.01;
          vPing -= Me.Velocity * 0.01;

          return vPing;
}

// Predict Location

function vector PredictLocation (Pawn Target, float PredictedTime, Optional Int CheckWalls)
{
  	local vector StartLocation, PredictedLocation, ErrorDiff, PredictedBone;
	local name PredictBone;
 	local vector HitLocation, HitNormal;
	
	if (Me != None)
	{
		PredictBone = CheckVisibility(Target);
		PredictedBone = (Target.GetBoneCoords('PredictBone').origin) + (Target.GetBoneCoords('PredictBone').xaxis * 0.5) + (Target.GetBoneCoords('PredictBone').yaxis * 0.5) + (Target.GetBoneCoords('PredictBone').zaxis * 0.5);

		if ( Target.Physics == PHYS_Falling || Target.Physics == PHYS_Karma )
		{
			PredictedLocation = Square(PredictedTime) * Target.PhysicsVolume.Gravity / 4 + PredictedTime * Target.Velocity + Target.Location;
		}
		
		else
		{
			PredictedLocation = PredictedBone + Target.Velocity * PredictedTime;
		}

		if ( Target.Physics == PHYS_Walking && Target.Trace(HitLocation, HitNormal,PredictedLocation - vect(0,0,1) * VSize(Target.Velocity),PredictedLocation, False,vect(0,0,1) * PredictedBone) != None )
		{
			PredictedLocation = HitLocation;
		}
		
		StartLocation = PredictedBone; 
		ErrorDiff = PredictedLocation - StartLocation;
		
		if ( CheckWalls > 0 && Target.Trace(HitLocation, HitNormal, ErrorDiff + StartLocation, StartLocation, False, vect(0,0,1) * Target.CollisionHeight + vect(1,1,0) * Target.CollisionRadius) != None ) 
		{
			ErrorDiff = PredictedLocation - HitLocation;
		}
		
		if ( HitNormal.Z < -0.7 )
		{
			PredictedLocation -= 2 * (ErrorDiff dot HitNormal) * HitNormal;
		}
		
		else
		{
			PredictedLocation -= (ErrorDiff dot HitNormal) * HitNormal; 
		}

		if ( HitNormal.Z > 0.7 && Target.Physics == PHYS_Falling )
		{
			PredictedLocation = 0.3 * PredictedLocation + 0.7 * HitLocation;
			StartLocation = HitLocation;
			CheckWalls--;
		}

		return PredictedLocation;
	}
}

// Rotate Towards Target

function BoneAim (Pawn BestTarget, name BestBone)
{
	local vector AimLocation;
	local rotator AimRotation;
	local vector MyLocation;

	// PingCorrection = BestTarget.Velocity * FClamp(Me.PlayerReplicationInfo.Ping,20.00,200.00) / 980;
	MyLocation = Me.GetBoneCoords('R6 Head').Origin + Velocity;
	// AimLocation = BestTarget.GetBoneCoords(BestBone).Origin;
	AimLocation = PredictLocation(BestTarget,fPredict,0);
	Aimlocation += PingCorrection(BestTarget);
	AimRotation = Normalize(rotator(AimLocation - MyLocation));
	R6Pawn(Me).PawnLookAbsolute(AimRotation,False,False);
}

// 2D Radar

function Draw2DRadar (Actor Target)
{
	local float PosX,PosY;
	local Vector X,Y,Z,D;
	local Vector MyLocation;
	local vector TargetLocation;

	MyLocation = Me.GetBoneCoords('R6 Head').Origin + Velocity;
	TargetLocation = Target.Location;

	GetAxes(Normalize(MyRotation) + rot(0,16384,0),X,Y,Z);
	if ((Target.IsA('Pawn')) && (ValidTarget(Pawn(Target))))
		GetTeamColor(Pawn(Target));
	else if ((Target.IsA('R6Grenade')) || (Target.IsA('R6ioBomb')))
		MyCanvas.SetDrawColor(255,255,255);  
	else
		return; 
              
	D = TargetLocation - MyLocation;
	D.Z = 0.0;
	PosX = D Dot X / 60;
	PosY = D Dot Y / 60;

	PosX = FClamp(PosX, -(Radius - 4), (Radius - 4));
	PosY = FClamp(PosY, -(Radius - 4), (Radius - 4));
	PosX += RadarX - 2;
	PosY += RadarY - 2;
	MyCanvas.Style = 3;
	MyCanvas.SetPos(PosX,PosY);
	MyCanvas.DrawIcon(Texture'Dot' ,1.25);
}

// ESP

final function DrawESP (Pawn Target)
{

	local float ScreenPosX,ScreenPosY;
	local float DrawPosY;

	if ( MyCanvas.GetScreenCoordinate(ScreenPosX,ScreenPosY,Target.Location,MyController.Pawn.Location,MyController.Pawn.GetViewRotation()) )
	{
		GetTeamColor(Target);
		DrawPosY=ScreenPosY - 10;
		if ( VStyle >= 0)
		{
			if ( IsUsingGod(Target))
			{
				MyDrawText(ScreenPosX + 10,DrawPosY,"GOD MODE ON", MyCanvas.DrawColor);
				DrawPosY += 10;
			}
			if ( IsUsingSpeed(Target))
			{
				MyDrawText(ScreenPosX + 10,DrawPosY,"SPEED HACK ON", MyCanvas.DrawColor);
				DrawPosY += 10;
			}
		}
		if ( VStyle > 0)
		{
			MyDrawText(ScreenPosX + 10,DrawPosY, Target.PlayerReplicationInfo.PlayerName, MyCanvas.DrawColor);
			DrawPosY += 10;
		}
		if ( VStyle > 1)
		{
			MyDrawText(ScreenPosX + 10,DrawPosY, "D: " @ VSize(Target.Location - MyController.Pawn.Location) / 48, MyCanvas.DrawColor);
			DrawPosY += 10;
		}
		if ( VStyle > 2)
		{
			MyDrawText(ScreenPosX + 10,DrawPosY, "W: " @ Target.engineweapon.m_weaponshortname, MyCanvas.DrawColor);
			DrawPosY += 10;
		}
		if ( VStyle > 3)
		{
			MyDrawText(ScreenPosX + 10,DrawPosY, "U: " @ Target.PlayerReplicationInfo.m_szUbiUserID, MyCanvas.DrawColor);
			DrawPosY += 10;
		}
	}
}

function DrawWeaponESP (Actor Target)
{
	local float ScreenPosX, ScreenPosY;

	MyCanvas.SetDrawColor(255,255,255);
	if ( MyCanvas.GetScreenCoordinate(ScreenPosX,ScreenPosY,Target.Location,MyController.Pawn.Location,MyController.Pawn.GetViewRotation()) )
	{
		if ( VStyle > 0 )
		{
			MyDrawText(ScreenPosX + 10,ScreenPosY - 10, Target.GetStateName(), MyCanvas.DrawColor);
		}
		if ( VStyle > 1 )
		{
			MyDrawText(ScreenPosX + 10,ScreenPosY, "D: " @ VSize(Target.Location - MyController.Pawn.Location) / 48, MyCanvas.DrawColor);
		}
	}
}

// Frag Glow

Function FragLite ()
{
	local R6Grenade Target;

	foreach MyController.Level.DynamicActors(Class'R6Grenade',Target)
	{
		if ( Target.IsA('R6FragGrenade') || Target.IsA('R6ClaymoreUnit') || Target.IsA('R6RemoteChargeUnit') || Target.IsA('R6BreachingChargeUnit'))
		{
			Target.bDynamicLight=True;
			Target.LightType=LT_Steady;
			Target.LightEffect=LE_NonIncidence;
			Target.AmbientGlow=150;
			Target.LightSaturation=100;
			Target.LightBrightness=255;
			Target.LightRadius=009;
			Target.LightHue = 255;
		}

		if ( Target.IsA('R6TearGasGrenade') || Target.IsA('R6GasGrenade') || Target.IsA('R6Flashbang'))
		{
			Target.bDynamicLight=True;
			Target.LightType=LT_Steady;
			Target.LightEffect=LE_NonIncidence;
			Target.AmbientGlow=150;
			Target.LightSaturation=100;
			Target.LightBrightness=255;
			Target.LightRadius=009;
			Target.LightHue = 031;
		}

		if ( Target.IsA('R6SmokeGrenade'))
		{
			Target.bDynamicLight=True;
			Target.LightType=LT_Steady;
			Target.LightEffect=LE_NonIncidence;
			Target.AmbientGlow=150;
			Target.LightSaturation=100;
			Target.LightBrightness=255;
			Target.LightRadius=009;
			Target.LightHue = 081;
		}
	}
}

// Door Hack

// 1 = Open
// 5 = Close
// 13 = Unlock

function DoorAction(byte Action)
{
	local Actor ActionActor;

	foreach MyController.Level.AllActors(Class'Actor', ActionActor)
	{ 
		if ( ValidActor ( ActionActor ) )
		{ 
			if (ActionActor.IsA('R6ioRotatingDoor'))
			{
				R6Pawn(MyController.Pawn).ServerPerformDoorAction(R6ioRotatingDoor(ActionActor), Action);
			}
		}
	}
}

// Key Events

function bool KeyEvent( EInputKey Key, EInputAction Action, FLOAT Delta )
{
	if( Action != IST_Press )
	{
		return false;
	}
	else if ( Key==IK_Numpad1 )
	{
		bMenu = !bMenu;
	}
	else if ( Key==IK_Numpad2 )
	{
		bAutoAim = !bAutoAim;
	}
	else if ( Key==IK_Numpad3 )
	{
		bAutoFire = !bAutoFire;
	}
	else if ( Key==IK_Numpad4 )
	{
		bCharge = !bCharge;
	}
	else if ( Key==IK_Numpad5 )
	{
		bAutoReload = !bAutoReload;
	}
	else if ( Key==IK_Numpad6 )
	{
		bESP = !bESP;
	}
	else if ( Key==IK_Numpad7 )
	{
		bWallHack = !bWallhack;
	}
	else if ( Key==IK_Numpad8 )
	{
		bRadar = !bRadar;
	}
	else if ( Key==IK_Numpad9 )
	{
		bSafePlay = !bSafePlay;
	}
	else if ( Key==IK_GreyStar )
	{
		bRetlock = !bRetlock;
	}
	else if ( Key==IK_NumpadPeriod )
	{
		bGodMode = !bGodMode;
	}
	else if ( Key==IK_MouseWheelUp )
	{
		if ( Me != None )
		{
			DoorAction(1);
		}
	}
	else if ( Key==IK_MiddleMouse )
	{
		if ( Me != None )
		{
			DoorAction(13);
		}
	}
	else if ( Key==IK_MouseWheelDown )
	{
		if ( Me != None )
		{
			DoorAction(5);
		}
	}
	else if ( Key==IK_Numpad0 )
	{
		bPower = !bPower;
	}
	else if ( Key==IK_GreyPlus )
	{
		if ( VStyle < 4 )
		{
			VStyle++;
		}
		else
		{
			VStyle = 0;
		}
	}
	else if ( Key==IK_GreyMinus )
	{
		if ( VFire < 4 )
		{
			VFire++;
		}
		else
		{
			VFire = 0;
		}
	}
	else if (Key==IK_Up && Action==IST_Press)
	{
		if (bMenu)
		{
			MenuSelected[CurrentMenu]--; 
			if (MenuSelected[CurrentMenu] < 0) MenuSelected[CurrentMenu] = MenuItemsNum - 1;
			return true;
		}
	}
	else if (Key==IK_Down && Action==IST_Press)
	{
		if (bMenu)
		{
			MenuSelected[CurrentMenu]++; 
			if (MenuSelected[CurrentMenu] >= MenuItemsNum) MenuSelected[CurrentMenu] = 0;
			return true;
		}
	}
	else if (Key==IK_Left && Action==IST_Press)
	{
		if (bMenu)
		{
			MenuUp();
			return true;
		}
	}
	else if (Key==IK_Right && Action==IST_Press)
	{
		ToggleMenuItem(CurrentMenu, MenuSelected[CurrentMenu]);
		return true;
	}
	else if (Key==IK_LeftMouse && Action==IST_Press)
	{
		LeftMousePressed=True;
	}
	else if ( Key==IK_Insert )
	{
		Save();
	}
	else if ( Key==IK_Delete )
	{
		bAntiVoteKick = !bAntiVoteKick;
	}
}

// Get Random Tag ( AVK )

function string GetRandomTag ()
{
	local int CurrentTag;

	CurrentTag = Rand(16);
	if ( CurrentTag == 1 )
	{
		return "[ODG]";
	}
	else if ( CurrentTag == 2 )
	{
		return "GOTCHA";
	}
	else if ( CurrentTag == 3 )
	{
		return "-)R(-";
	}
	else if ( CurrentTag == 4 )
	{
		return "=UDS=";
	}
	else if ( CurrentTag == 5 )
	{
		return "-S-Co.";
	}
	else if ( CurrentTag == 6 )
	{
		return "[:FI:]";
	}
	else if ( CurrentTag == 7 )
	{
		return "|RH|";
	}
	else if ( CurrentTag == 8 )
	{
		return "FWF";
	}
	else if ( CurrentTag == 9 )
	{
		return "ZS";
	}
	else if ( CurrentTag == 10 )
	{
		return "|619|";
	}
	else if ( CurrentTag == 11 )
	{
		return "ATF_";
	}
	else if ( CurrentTag == 12 )
	{
		return "=AO=";
	}
	else if ( CurrentTag == 13 )
	{
		return "|RA|";
	}
	else if ( CurrentTag == 14 )
	{
		return "TWL";
	}
	else if ( CurrentTag == 15 )
	{
		return "=[WE]=";
	}
	else if ( CurrentTag == 16 )
	{
		return "CWar";
	}
}

// Get Random Name ( AVK )

function string GetRandomName ()
{
	local int CurrentName;

	CurrentName = Rand(16);
	if ( CurrentName == 1 )
	{
		return "MâcGÿver";
	}
	else if ( CurrentName == 2 )
	{
		return "PêTêR";
	}
	else if ( CurrentName == 3 )
	{
		return "Mïrâl";
	}
	else if ( CurrentName == 4 )
	{
		return "KâCØ";
	}
	else if ( CurrentName == 5 )
	{
		return "ÎchêBân";
	}
	else if ( CurrentName == 6 )
	{
		return "RêVïN";
	}
	else if ( CurrentName == 7 )
	{
		return "Nêmêsïs";
	}
	else if ( CurrentName == 8 )
	{
		return "Lâwlêss";
	}
	else if ( CurrentName == 9 )
	{
		return "Ønë";
	}
	else if ( CurrentName == 10 )
	{
		return "Ømnïx";
	}
	else if ( CurrentName == 11 )
	{
		return "êxpoZêd";
	}
	else if ( CurrentName == 12 )
	{
		return "RêdBêta";
	}
	else if ( CurrentName == 13 )
	{
		return "Kïzzâmp";
	}
	else if ( CurrentName == 14 )
	{
		return "GlØgg";
	}
	else if ( CurrentName == 15 )
	{
		return "RuffiânSØldiêr";
	}
	else if ( CurrentName == 16 )
	{
		return "Lucïfêr";
	}
}

// Cmd Function

function Cmd (coerce string Command)
{
	if ( MyController != None )
	{
		MyController.ConsoleCommand(Command);
	}
}

// Save Function

exec function Save ()
{
	SaveConfig();
	StaticSaveConfig();
	MyController.ClientMessage("Settings Saved");
}

// Default Properties
defaultproperties
{
	bActive=True
	bVisible=True
	bRequiresTick=True
	bPower=True
	bAutoAim=True
	bAutoFire=True
	bMenu=True
	bWallhack=True
	bESP=True
	bNoRecoil=True
	bRetlock=True
	bFragGlow=True
	bIntelliquipment=True;
	MenuX=10
	MenuY=150
	bGodMode=True
	bCharge=False
	bRadar=True
	Radius=79.0
	RadarX=95.0
	RadarY=475.0
	VStyle=3
	vFire=1
	fPredict=0.12
	bAutoReload=True
	bSafePlay=True
	bTKBot=False
	Zoom=20.0
	bZoombot=True
	bNotification=True
	bVisuals=True
	bAntiVoteKick=False
	bAntiIdle=False
	bBypass=True
	bDoorBreacher=True
	bNoEffects=False
	bNoFog=False
	bShowCharacterInfo=True
	bShowWayPointInfo=True
	bShowActionIcon=True
}
