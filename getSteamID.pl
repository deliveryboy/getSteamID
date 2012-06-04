# getSteamID.pl

use Getopt::Std;
use Win32::TieRegistry (Delimiter => '/', ArrayValues => 1);
use Win32::Clipboard;
use Win32::Process;
use Win32::API;
use utf8;
use Tk;
use Tk::Checkbutton;
use Tk::Radiobutton;

#delete $ENV{'OS'};
#undef $^O;
$regexp_os = "win";
unless(((exists $ENV{'OS'}) && (defined $ENV{'OS'})) && (defined $^O))
{
	die;
}
else
{
	unless(($ENV{'OS'} =~ m/${regexp_os}/i) && ($^O =~ m/${regexp_os}/i))
	{
		die;
	}
}

getopts('hn', \%opts);

if((exists $opts{'h'}) && (defined $opts{'h'}))
{
	print q(
SteamID, a Tool 2 get ya SteamID(s).
4 Win32, ActivePerl.
 -h Info.
 -n NoGUI.
 <FILE> Path 2 "Steam.log" file.
);
	exit 1;
}

$file = 'Steam.log';
$errMsg = 'Unable to open "' . $file . '" file.';
if($#ARGV == 0)
{
	$regFilePath = shift @ARGV;
}
else
{
	$regFilePath = $Registry->{'LMachine/SOFTWARE/Valve/Steam/'}->{'/InstallPath'};
	unless($regFilePath->[0])
	{
		$regFilePath->[0] = '';
	}
	$regFilePath = $regFilePath->[0] . '\\' . $file;
}

if(-f $regFilePath)
{
	$SteamID_prefix = "STEAM_";
	open(FH, '<', $regFilePath) or die $!;
	binmode FH;
	while($line = <FH>)
	{
		if($line =~ m/CreateSession\((.*),.*,.*\)/)
		{
			$user = $1;
			while($line = <FH>)
			{
				if($line =~ m/ConnectionPool\s.*\sfor\s([0-9]+:[0-9]+:[0-9]+)/)
				{
					$id = $1;
					unless(exists $sid{$user})
					{
						$sid{$user} = $SteamID_prefix . $id;
						push @sid, $user;
					}
					last;
				}
			}
		}
	}
	close FH || die $?;
	
	if((exists $opts{'n'}) && (defined $opts{'n'}))
	{
		foreach $item (@sid)
		{
			print $item, "\t", $sid{$item}, "\n";
		}
	}
	else
	{
		steamTK(1);
	}
}
else
{
	if((exists $opts{'n'}) && (defined $opts{'n'}))
	{
		print $errMsg, "\n";
		exit 2;
	}
	else
	{
		steamTK(0);
	}
}

sub steamTK
{
	$self = shift @_;

	$mainWindow = MainWindow->new;
	$mainWindow->title('getSteamID ...by pcwf-clan.de');

	$fMain = $mainWindow->Frame()->pack(-padx => '5', -pady => '5', -fill => 'both');

	$fTop = $fMain->Frame()->pack(-padx => '5', -pady => '5', -fill => 'x');

	if($self)
	{
		$sid_index = 0;

		$fLabelL = $fTop->Frame()->pack(-side => 'left');
		$fLabelL->Label(-text => 'Steam-Account:')->pack();
		$fLabelL->Label(-text => 'Steam-ID:')->pack(-side => 'right');
		$checkbutton = $fLabelL->Checkbutton(-variable => \$cbValue, -command => \&cbSID)->pack();
		$checkbutton->select;
		
		$fEntry = $fTop->Frame()->pack(-side => 'left');
		$eTop = $fEntry->Entry(-width => '30', -text => $sid[$sid_index])->pack();
		$eBottom = $fEntry->Entry(-width => '30', -text => $sid{$sid[$sid_index]})->pack();

		$fClpBrdLabel = $fTop->Frame()->pack(-side => 'left');
		$fClpBrdLabel->Label(-text => 'ClpBrd:')->pack();

		$fRadiobutton = $fTop->Frame()->pack(-side => 'left');
		$rb[0] = $fRadiobutton->Radiobutton(-value => 'sac', -variable => \$rbValue, -command => \&clpBrd)->pack();
		$rb[1] = $fRadiobutton->Radiobutton(-value => 'sid', -variable => \$rbValue, -command => \&clpBrd)->pack();

		$fLabelR = $fTop->Frame()->pack(-side => 'left');
		$lTopR = $fLabelR->Label()->pack();
		$lBottomR = $fLabelR->Label()->pack();

		#$rb[1]->invoke;

		unless($#sid == 0)
		{
			$fMiddle = $fMain->Frame()->pack(-padx => '5', -pady => '5');
			$fLeftM = $fMiddle->Frame()->pack(-side => 'left');
			$fLeftM->Button(-text => '< BACK', -command => \&backB)->pack();
			$fRightM = $fMiddle->Frame()->pack(-side => 'left');
			$fRightM->Button(-text => 'NEXT >', -command => \&nextB)->pack();
			
			$mainWindow->minsize(qw(416 149));
			$mainWindow->maxsize(qw(416 149));
		}
		else
		{
			$mainWindow->minsize(qw(416 116));
			$mainWindow->maxsize(qw(416 116));
		}
	}
	else
	{
		$fTop->Label(-text => $errMsg)->pack();
		$mainWindow->minsize(qw(416 91));
		$mainWindow->maxsize(qw(416 91));
	}
	
	$fBottom = $fMain->Frame()->pack(-padx => '5', -pady => '5', -fill => 'x');
	$fBottom->Button(-text => 'EXIT', -command => sub{$mainWindow->destroy();})->pack();
	$lhp = $fBottom->Label(-text => 'pcwf-clan.de', -foreground => 'blue')->pack(-side => 'left');
	$lhp->bind('<ButtonRelease-1>' => \&browseURI);
	$lHelp = $fBottom->Label(-text => '?', -foreground => 'blue')->pack(-side => 'right');
	$lHelp->bind('<ButtonRelease-1>' => \&showInfo);
	
	MainLoop;
}

sub backB
{
	unless($sid_index == 0)
	{
		$sid_index--;
		$eTop->configure(-text => $sid[$sid_index]);
		$eBottom->configure(-text => $sid{$sid[$sid_index]});
		$rb[0]->deselect;
		$rb[1]->deselect;
		$lTopR->configure(-text => '');
		$lBottomR->configure(-text => '');
		cbSID();
		#$rb[1]->invoke;
	}
}

sub nextB
{
	unless($sid_index == $#sid)
	{
		$sid_index++;
		$eTop->configure(-text => $sid[$sid_index]);
		$eBottom->configure(-text => $sid{$sid[$sid_index]});
		$rb[0]->deselect;
		$rb[1]->deselect;
		$lTopR->configure(-text => '');
		$lBottomR->configure(-text => '');
		cbSID();
		#$rb[1]->invoke;
	}
}

sub clpBrd
{
	if($rbValue eq 'sac')
	{
		$CLIP = Win32::Clipboard($eTop->cget('-text'));
		$lTopR->configure(-text => '< ClipBoard');
		$lBottomR->configure(-text => '');
	}
	elsif($rbValue eq 'sid')
	{
		$CLIP = Win32::Clipboard($eBottom->cget('-text'));
		$lTopR->configure(-text => '');
		$lBottomR->configure(-text => '< ClipBoard');
	}
}

sub cbSID
{
	unless($cbValue)
	{
		$temp = $eBottom->cget('-text');
		if($temp =~ m/^${SteamID_prefix}[0-9]+:[0-9]+:[0-9]+$/)
		{
			@temp = split $SteamID_prefix, $temp;
			$eBottom->configure(-text => $temp[$#temp]);
		}
	}
	else
	{
		$temp = $eBottom->cget('-text');
		if($temp =~ m/^[0-9]+:[0-9]+:[0-9]+$/)
		{
			$eBottom->configure(-text => $SteamID_prefix . $temp);
		}
	}
}

sub browseURI
{
	$shell_exec = new Win32::API("SHELL32", "ShellExecute", "NNPNNN", "N");
	$shell_exec->Call(0, 0, "http://pcwf-clan.de/", 0, 0, 3);
}

sub showInfo
{
	Win32::Process::Create($ProcessObj, $ENV{'SYSTEMROOT'} . "\\system32\\notepad.exe", "notepad.exe getSteamID.txt", 0, NORMAL_PRIORITY_CLASS, ".") || die Win32::FormatMessage(Win32::GetLastError());
	$ProcessObj->Wait(0);
}




