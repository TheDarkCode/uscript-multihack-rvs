// Menu Extension

class RA extends R6MenuMainWidget;

var Interaction Screw;

function Created ()
{
	Super.Created();
	if(Screw == None)
	{
		Screw = Root.Console.ViewportOwner.Actor.Player.InteractionMaster.AddInteraction("ForgetAboutIt.Screw",Root.Console.ViewPortOwner.Actor.Player);
	}
}
